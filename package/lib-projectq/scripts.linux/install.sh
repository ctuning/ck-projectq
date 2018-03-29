#!/bin/bash

#
# Installation script for Caffe.
#
# See CK LICENSE for licensing details.
# See CK COPYRIGHT for copyright details.
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
# Print info about possible issues
echo ""
echo "Note that you sometimes need to upgrade your pip to the latest version"
echo "to avoid well-known issues with user/system space installation:"

######################################################################################

cd ${INSTALL_DIR}/src

    # First we install the dependencies and provide a path to them:
    #
${CK_PYTHON_BIN} -m pip install -r requirements.txt --prefix=${PY_DEPS_TREE} --no-cache-dir

ls -ld $PROJECTQ_LIB_DIR    # debug to find out why <pybind11/pybind11.h> is not found
echo
find $PY_DEPS_TREE          # debug to find out why <pybind11/pybind11.h> is not found

if [ "${?}" != "0" ] ; then
    echo "Error: installation of the dependencies failed!"
    exit 1
fi

if [ "$USE_PYTHON_SIM" -eq "1" ]; then
    echo "Using Python simulator (slower)"

    ${CK_PYTHON_BIN} -m pip install . --no-deps --prefix=${PY_DEPS_TREE} --global-option=--without-cppsimulator --no-cache-dir
else 
    echo "Using C++ Simulator (faster)"

    env CC="${CK_CC} ${CK_CXX_COMPILER_STDLIB} ${CK_COMPILER_OWN_LIB_LOC}" CXX="${CK_CXX} ${CK_CXX_COMPILER_STDLIB} ${CK_COMPILER_OWN_LIB_LOC}"  ${CK_PYTHON_BIN} -m pip install . --no-deps --prefix=${PY_DEPS_TREE} --no-cache-dir
fi

if [ "${?}" != "0" ] ; then
    echo "Error: installation of the main projectq package failed!"
    exit 1
fi

