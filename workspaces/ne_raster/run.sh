#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "wms_tiled" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=worldtiles -Jheight=256 -Jwidth=256
elif [ "${TEST}" = "wms_tiled_pyramid" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=worldtiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_pyramid
else
  echo "Unknown test"
  exit 1
fi
