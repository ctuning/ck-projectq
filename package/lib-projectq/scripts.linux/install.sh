#!/bin/bash

#
# Installation script for ProjectQ.
#
# See CK LICENSE.txt for licensing details.
# See CK COPYRIGHT.txt for copyright details.
#
# Developer(s):
# - Flavio Vella, 2018;
#

# PACKAGE_DIR
# INSTALL_DIR

echo "**************************************************************"
echo "Installing ProjectQ ..."

    # This is where pip2/pip3 will install the modules.
    # It has its own funny structure we don't control :
    #
PY_DEPS_TREE=${INSTALL_DIR}/py_deps

######################################################################################
echo ""
echo "Removing '${PY_DEPS_TREE}' ..."
rm -rf ${PY_DEPS_TREE}

    # This is the "end" directory that will contain dependencies and projectq module itself:
    #
export PROJECTQ_LIB_DIR=${INSTALL_DIR}/build
SHORT_PYTHON_VERSION=`${CK_ENV_COMPILER_PYTHON_FILE} -c 'import sys;print(sys.version[:3])'`
ln -s "${PY_DEPS_TREE}/lib/python${SHORT_PYTHON_VERSION}/site-packages" $PROJECTQ_LIB_DIR
export PYTHONPATH=$PROJECTQ_LIB_DIR:$PYTHONPATH

######################################################################################

cd ${INSTALL_DIR}/src

    # First we install the dependencies and provide a path to them:
    #
${CK_ENV_COMPILER_PYTHON_FILE} -m pip install -r requirements.txt --prefix=${PY_DEPS_TREE} --no-cache-dir

if [ "${?}" != "0" ] ; then
    echo "Error: installation of the dependencies failed!"
    exit 1
fi

if [ "$USE_PYTHON_SIM" -eq "1" ]; then
    echo "Using Python simulator (slower)"

    ${CK_ENV_COMPILER_PYTHON_FILE} -m pip install . --no-deps --prefix=${PY_DEPS_TREE} --global-option=--without-cppsimulator --no-cache-dir
else 
    echo "Using C++ simulator (faster)"

    PYBIND11_INSTALL_LOCATION=`${CK_ENV_COMPILER_PYTHON_FILE} -m pip show pybind11 | grep Location: | cut -d ' ' -f 2`
    PYBIND11_H_RELATIVE_PATH=`${CK_ENV_COMPILER_PYTHON_FILE} -m pip show -f pybind11 | grep pybind11/pybind11.h | awk '{print $1}'`
    PYBIND11_H_DIRECTORY=`dirname $PYBIND11_INSTALL_LOCATION/$PYBIND11_H_RELATIVE_PATH`
    PROJECTQ_INC_DIR=`dirname $PYBIND11_H_DIRECTORY`

    echo "Pybind11's include files are located here: $PROJECTQ_INC_DIR"

    export COMMON_FLAGS="-I${PROJECTQ_INC_DIR} ${CK_CXX_COMPILER_STDLIB} ${CK_COMPILER_OWN_LIB_LOC}"
    env CC="${CK_CC} ${COMMON_FLAGS}" CXX="${CK_CXX} ${COMMON_FLAGS}"  ${CK_ENV_COMPILER_PYTHON_FILE} -m pip install . --no-deps --prefix=${PY_DEPS_TREE} --no-cache-dir
fi

if [ "${?}" != "0" ] ; then
    echo "Error: installation of the main projectq package failed!"
    exit 1
fi

