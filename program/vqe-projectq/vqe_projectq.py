#!/usr/bin/env python

# Adapted from http://fermilib.readthedocs.io/en/latest/examples.html#simulating-a-variational-quantum-eigensolver-using-projectq

from numpy import array, concatenate, zeros
from numpy.random import randn
from scipy.optimize import minimize

from fermilib.config import *
from fermilib.utils import *
from fermilib.transforms import jordan_wigner

from projectq.ops import X, All, Measure
from projectq.backends import CommandPrinter, CircuitDrawer

# Load the molecule.
import os
filename = os.path.join(DATA_DIRECTORY, 'H2_sto-3g_singlet_0.7414')
molecule = MolecularData(filename=filename)

# Use a Jordan-Wigner encoding, and compress to remove 0 imaginary components
qubit_hamiltonian = jordan_wigner(molecule.get_molecular_hamiltonian())
qubit_hamiltonian.compress()
compiler_engine = uccsd_trotter_engine()

def energy_objective(packed_amplitudes):
    """Evaluate the energy of a UCCSD singlet wavefunction with packed_amplitudes
    Args:
        packed_amplitudes(ndarray): Compact array that stores the unique
            amplitudes for a UCCSD singlet wavefunction.

    Returns:
        energy(float): Energy corresponding to the given amplitudes
    """
    # Set Jordan-Wigner initial state with correct number of electrons
    wavefunction = compiler_engine.allocate_qureg(molecule.n_qubits)
    for i in range(molecule.n_electrons):
        X | wavefunction[i]

    # Build the circuit and act it on the wavefunction
    evolution_operator = uccsd_singlet_evolution(packed_amplitudes,
                                                 molecule.n_qubits,
                                                 molecule.n_electrons)
    evolution_operator | wavefunction
    compiler_engine.flush()

    # Evaluate the energy and reset wavefunction
    energy = compiler_engine.backend.get_expectation_value(qubit_hamiltonian, wavefunction)
    All(Measure) | wavefunction
    compiler_engine.flush()
    return energy


n_amplitudes = uccsd_singlet_paramsize(molecule.n_qubits, molecule.n_electrons)
#initial_amplitudes = [0, 0.05677]
initial_amplitudes = [1, 1]
initial_energy = energy_objective(initial_amplitudes)

# Run VQE Optimization to find new CCSD parameters
opt_result = minimize(energy_objective, initial_amplitudes,
                      method="CG", options={'disp':True})

opt_energy, opt_amplitudes = opt_result.fun, opt_result.x
print("\nOptimal UCCSD Singlet Energy: {}".format(opt_energy))
print("Optimal UCCSD Singlet Amplitudes: {}".format(opt_amplitudes))
print("Classical CCSD Energy: {} Hartrees".format(molecule.ccsd_energy))
print("Exact FCI Energy: {} Hartrees".format(molecule.fci_energy))
print("Initial Energy of UCCSD with CCSD amplitudes: {} Hartrees".format(initial_energy))
