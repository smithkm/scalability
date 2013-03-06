#!/bin/bash
# an empty workspace that can be populated and tested

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "rest" ]; then
  ./populate.py
  sleep 5
  jmeter -p ../jmeter.properties -t wms_wfs.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} 
elif [ "${TEST}" = "test" ]; then
  jmeter -p ../jmeter.properties -t wms_wfs.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} 
else
  echo "Unknown test"
  exit 1
fi
