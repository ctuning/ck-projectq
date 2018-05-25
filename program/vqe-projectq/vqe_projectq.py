#!/usr/bin/env python

# Adapted from http://fermilib.readthedocs.io/en/latest/examples.html#simulating-a-variational-quantum-eigensolver-using-projectq

import sys
import os
import json
import time

from numpy import ndarray, array, concatenate, zeros, bool_
from numpy.random import randn
from scipy.optimize import minimize

from fermilib.config import *
from fermilib.utils import *
from fermilib.transforms import jordan_wigner

from projectq.ops import X, All, Measure
from projectq.backends import CommandPrinter, CircuitDrawer

# See https://stackoverflow.com/questions/26646362/numpy-array-is-not-json-serializable
#
class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, ndarray):
            return obj.tolist()
        elif isinstance(obj, bool_):
            return bool(obj)
        return json.JSONEncoder.default(self, obj)


def projectq_vqe(start_params, minimizer_method, minimizer_options):

    def energy_objective(packed_amplitudes, report):
        """Evaluate the energy of a UCCSD singlet wavefunction with packed_amplitudes
        Args:
            packed_amplitudes(ndarray): Compact array that stores the unique
                amplitudes for a UCCSD singlet wavefunction.

        Returns:
            energy(float): Energy corresponding to the given amplitudes
        """

        timestamp_before_ee = time.time()

        report_this_iteration = { 'total_q_seconds_per_c_iteration' : 0.0, 'seconds_per_individual_q_run' : [] }

        # Set Jordan-Wigner initial state with correct number of electrons
        wavefunction = compiler_engine.allocate_qureg(molecule.n_qubits)
        for i in range(molecule.n_electrons):
            X | wavefunction[i]

        # Build the circuit and act it on the wavefunction
        evolution_operator = uccsd_singlet_evolution(packed_amplitudes,
                                                     molecule.n_qubits,
                                                     molecule.n_electrons)
        evolution_operator | wavefunction

        # Evaluate the energy and reset wavefunction:
        #
        timestamp_before_qsim = time.time()
        compiler_engine.flush()
        energy = compiler_engine.backend.get_expectation_value(qubit_hamiltonian, wavefunction)     # "cheating"
        q_run_seconds = time.time() - timestamp_before_qsim

        report_this_iteration['total_q_seconds_per_c_iteration'] += q_run_seconds                   # total_q_time_per_iteration
        report_this_iteration['seconds_per_individual_q_run'].append( q_run_seconds )               # q_time_per_iteration

        All(Measure) | wavefunction
        compiler_engine.flush()

        report_this_iteration['energy'] = energy

        report['iterations'].append( report_this_iteration )
        report['total_q_seconds'] += report_this_iteration['total_q_seconds_per_c_iteration']  # total_q_time += total

        report_this_iteration['total_seconds_per_c_iteration'] = time.time() - timestamp_before_ee

        print(str(report_this_iteration) + "\n")

        return energy

    report = { 'total_q_seconds': 0, 'iterations' : [] }

    # Use a Jordan-Wigner encoding, and compress to remove 0 imaginary components
    qubit_hamiltonian = jordan_wigner(molecule.get_molecular_hamiltonian())
    qubit_hamiltonian.compress()
    compiler_engine = uccsd_trotter_engine()

    timestamp_before_optimizer = time.time()
    optimizer_output = minimize(energy_objective, start_params, args=(report), method=minimizer_method, options=minimizer_options)
    total_optimization_seconds = time.time() - timestamp_before_optimizer

    report['total_seconds'] = total_optimization_seconds

    return (optimizer_output, report)


if __name__ == '__main__':

    if len(sys.argv)!=3:
        print("Usage: "+sys.argv[0]+" <minimizer_method> <max_function_evaluations>")
        exit(1)

    minimizer_method            = sys.argv[1]
    max_function_evaluations    = int( sys.argv[2] )

    print("Using minimizer_method='"+minimizer_method+"'")
    print("Using max_function_evaluations="+str(max_function_evaluations))

    # Load the molecule:
    #
    filename                    = os.path.join(DATA_DIRECTORY, 'H2_sto-3g_singlet_0.7414')
    molecule                    = MolecularData(filename=filename)
    #initial_amplitudes          = [0, 0.05677]
    initial_amplitudes          = [1, 1]

    minimizer_options =  {
        'Nelder-Mead':  {'maxfev':  max_function_evaluations, 'disp': True},
        'COBYLA':       {'maxiter': max_function_evaluations, 'disp': True},
        'CG':           {'disp': True}                                          # this method ignores iteration thresholds anyway
            }[minimizer_method]

    # Run VQE Optimization to find new CCSD parameters
    (vqe_output, report) = projectq_vqe(initial_amplitudes, minimizer_method, minimizer_options)

    opt_energy, opt_amplitudes = vqe_output.fun, vqe_output.x
    print("\nOptimal UCCSD Singlet Energy: {}".format(opt_energy))
    print("Optimal UCCSD Singlet Amplitudes: {}".format(opt_amplitudes))
    print("Classical CCSD Energy: {} Hartrees".format(molecule.ccsd_energy))
    print("Exact FCI Energy: {} Hartrees".format(molecule.fci_energy))
    #initial_energy = energy_objective(initial_amplitudes, { 'total_q_seconds': 0, 'iterations' : [] })
    #print("Initial Energy of UCCSD with CCSD amplitudes: {} Hartrees".format(initial_energy))

    vqe_input       = { "minimizer_method" : minimizer_method, "minimizer_options": minimizer_options }
    output_dict     = { "vqe_input" : vqe_input, "vqe_output" : vqe_output, "report" : report }
    formatted_json  = json.dumps(output_dict, cls=NumpyEncoder, sort_keys = True, indent = 4)

#    print(formatted_json)

    with open('vqe_report.json', 'w') as json_file:
        json_file.write( formatted_json )

