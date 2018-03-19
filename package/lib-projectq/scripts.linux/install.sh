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

    # This is the link that *will* be pointing at the directory with modules.
    # However, because we want to use asterisk expansion, we will create
    # the link itself *after* PY_DEPS_TREE has been already populated.
    #
export PROJECTQ_LIB_DIR=${INSTALL_DIR}/build

######################################################################################
echo ""
echo "Removing '${PY_DEPS_TREE}' ..."
rm -rf ${PY_DEPS_TREE} ${PROJECTQ_LIB_DIR}

######################################################################################
# Print info about possible issues
echo ""
echo "Note that you sometimes need to upgrade your pip to the latest version"
echo "to avoid well-known issues with user/system space installation:"

######################################################################################

cd ${INSTALL_DIR}/src

if [ "$USE_PYTHON_SIM" -eq "1" ]; then
    echo "Using Python simulator (slower)"

    ${CK_PYTHON_BIN} -m pip install -r requirements.txt --prefix=${PY_DEPS_TREE} --no-cache-dir
    ${CK_PYTHON_BIN} -m pip install projectq . --no-deps --prefix=${PY_DEPS_TREE} --global-option=--without-cppsimulator --no-cache-dir

else 
    echo "Using C++ Simulator (faster)"

        # FIXME: Currently installs pybind11 into user's directory (to make sure it is visible for the next pip command).
        #        A better way would be to put it into ${PROJECTQ_LIB_DIR} and make pip see it there
        #        (by default it doesn't happen).
    ${CK_PYTHON_BIN} -m pip install --user pybind11 --no-cache-dir
    env CC="${CK_CXX} ${CK_EXTRA_MISC_CXX_FLAGS}"  ${CK_PYTHON_BIN} -m pip install . --prefix=${PY_DEPS_TREE} --no-cache-dir
fi

    # In order for the asterisk to expand properly,
    # we have to do it AFTER the directory tree has been populated:
    #
ln -s $PY_DEPS_TREE/lib/python*/site-packages $PROJECTQ_LIB_DIR

