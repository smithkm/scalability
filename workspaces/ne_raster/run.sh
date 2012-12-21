#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "wms_tiled" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256
elif [ "${TEST}" = "wms_tiled_im" ]; then
  exit 1
  #jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_imagemosaic
else
  echo "Unknown test"
  exit 1
fi
