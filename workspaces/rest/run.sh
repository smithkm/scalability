#!/bin/bash
# an empty workspace that can be populated and tested

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "rest" ]; then
  jmeter -p ../jmeter.properties -t wms_wfs.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles -Jserver=http://scale.dev.opengeo.org
else
  echo "Unknown test"
  exit 1
fi
