#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "wms_tiled" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256
elif [ "${TEST}" = "wms_untiled" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=bboxes -Jheight=1024 -Jwidth=1024
elif [[ "${TEST}" = wms_tiled_* ]]; then
  # the test name specifies a layer
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jheight=256 -Jwidth=256 -Jlayer=${TEST:10}
else
  echo "Unknown test"
  exit 1
fi
