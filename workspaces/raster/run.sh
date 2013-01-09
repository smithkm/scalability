#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

# default test is on ne raster
if [ "${TEST}" = "wms_tiled" ]; then
  # suggested tile size 128
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR
elif [ "${TEST}" = "wms_tiled_256" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_256
elif [ "${TEST}" = "wms_tiled_512" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_512
elif [ "${TEST}" = "wms_tiled_noover" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_noover
elif [ "${TEST}" = "wms_tiled_pyramid" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_pyramid
else
  echo "Unknown test"
  exit 1
fi
