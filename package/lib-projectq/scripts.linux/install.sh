#! /bin/bash

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


# Check extra stuff
export PROJECTQ_LIB_DIR=${INSTALL_DIR}/build

######################################################################################
echo ""
echo "Removing '${PROJECTQ_LIB_DIR}' ..."
rm -rf ${PROJECTQ_LIB_DIR}

######################################################################################
# Print info about possible issues
echo ""
echo "Note that you sometimes need to upgrade your pip to the latest version"
echo "to avoid well-known issues with user/system space installation:"

######################################################################################

cd ${INSTALL_DIR}/src

if [ "$USE_PYTHON_SIM" -eq "1" ]; then
    echo "Using Python simulator (slower)"

    ${CK_PYTHON_BIN} -m pip install numpy -t ${PROJECTQ_LIB_DIR} --no-cache-dir
    ${CK_PYTHON_BIN} -m pip install projectq . --no-deps -t ${PROJECTQ_LIB_DIR} --global-option=--without-cppsimulator --no-cache-dir

else 
    echo "Using C++ Simulator (faster)"

        # FIXME: Currently installs pybind11 into user's directory (to make sure it is visible for the next pip command).
        #        A better way would be to put it into ${PROJECTQ_LIB_DIR} and make pip see it there
        #        (by default it doesn't happen).
    ${CK_PYTHON_BIN} -m pip install --user pybind11 --no-cache-dir
    env CC=${CK_CXX} ${CK_PYTHON_BIN} -m pip install . -t ${PROJECTQ_LIB_DIR} --no-cache-dir
fi

