# ck-projectq


[ProjectQ](https://projectq.ch/)


## Installation 

### Install global prerequisites (Ubuntu)

```
$ sudo apt-get install build-essential
```


### Install Python 3 
(Python 2 is also supported)

```
$ sudo apt-get install python3 python3-pip
$ sudo pip3 install scipy
$ sudo pip3 install pybind11
```

### Install Collective Knowledge

```
$ sudo pip3 install ck
```




### Install this CK repository with all its dependencies (other CK repos to reuse artifacts)
```
$ ck pull repo --url=git@github.com:dividiti/ck-projectq
```


## Packages installation

List all the packages available 

```
$ ck list ck-projecq:package:*
```

### ProjectQ

```
$ ck install package:lib-projectq
```

By default CK tries to compile ProjectQ and C++-Simulator. In order to use the (slow) Python simulator:

```
 $ ck install package:lib-projectq --env.USE_PYTHON_SIM=1
```

## Run Programs 

List all programs available 
```
$ ck list ck-projectq:program:*
```


### ProjectQ Demo/example client

```
$ ck run program:projectq-demo
```

How to specify a specific bechmark

``` 
$ ck run program:projectq-demo --cmd_key=teleport
```

How to set-up a CK variable for a given command

```
$ ck run program:projectq-demo --cmd_key=shor --env.CK_SHOR_INPUT=7
```
### Other options 

Simulator is a compiler engine which simulates a quantum computer using C++-based kernels.
OpenMP is enabled and the number of threads can be controlled using the OMP_NUM_THREADS environment variable.


```
$ ck run program:projectq-demo --cmd_key=shor --env.CK_SHOR_INPUT=101 --env.OMP_NUM_THREADS=16
```

```
$ ck run program:projectq-shor --cmd_key=shor --env.CK_SHOR_INPUT=101 --env.CK_PROJECTQ_IBM_DEVICE=ibmqx4
```

## FAQ

### Where does CK store my program and its output?

A program can be located on disk by its name as follows:
```
$ ck find program:projectq-shor
/home/flavio/CK-REPOS/ck-quantum-private/program/projectq-shor
$ ls `ck find program:projectq-shor`
quantum_random_numbers.py  shor.py
```

Temporary files (including the executable, `stderr` and `stdout`) are in the `tmp` directory:
```
$ cd `ck find program:projectq-shor`/tmp
```

## Troubleshooting
