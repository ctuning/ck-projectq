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

SUDO="sudo "
if [[ ${CK_PYTHON_PIP_BIN_FULL} == /home/* ]] ; then
  SUDO=""
fi

# Check if has --system option
${CK_PYTHON_PIP_BIN_FULL} install --help > tmp-pip-help.tmp
if grep -q "\-\-system" tmp-pip-help.tmp ; then
 SYS=" --system"
fi
rm -f tmp-pip-help.tmp

######################################################################################

cd ${INSTALL_DIR}/src

if [ "$USE_PYTHON_SIM" -eq "0" ]; then
   echo "Using CPP Simulator";
   env CC=${CK_CXX} ${CK_PYTHON_BIN} -m pip install . -t ${PROJECTQ_LIB_DIR} --no-cache-dir 

else 
   echo "Using (slow) Python simulator"
   ${CK_PYTHON_BIN} -m pip install . -t ${PROJECTQ_LIB_DIR} --global-option=--without-cppsimulator
fi

return 0
