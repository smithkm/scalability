#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

# default test is on ne raster
if [ "${TEST}" = "ne_wms" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=NE2_HR_LC_SR_W_DR -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_256
elif [ "${TEST}" = "ne_wms_noover" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=NE2_HR_LC_SR_W_DR -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_noover
elif [ "${TEST}" = "ne_wms_pyramid" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=NE2_HR_LC_SR_W_DR -Jheight=256 -Jwidth=256 -Jlayer=NE2_HR_LC_SR_W_DR_pyramid
elif [ "${TEST}" = "af_wms_nitf" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=afghanistan -Jheight=256 -Jwidth=256 -Jlayer=10JAN25060751-M1BS-052302793010_01_P001
elif [ "${TEST}" = "af_wms_tiff" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=afghanistan -Jheight=256 -Jwidth=256 -Jlayer=10JAN25060751-M1BS-052302793010_01_P001_tiff
elif [ "${TEST}" = "af_wms_tiff_noover" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=afghanistan -Jheight=256 -Jwidth=256 -Jlayer=10JAN25060751-M1BS-052302793010_01_P001_noover
else
  echo "Unknown test"
  exit 1
fi
