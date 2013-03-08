#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4
SERVER=$5
PORT=$6

if [[ "${TEST}" = geotiff* ]]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=geotiff -Jsrs=32642 -Jheight=256 -Jwidth=256 -Jlayer=${TEST} -Jserver=$5 -Jport=$6
elif [ "${TEST}" = "nitf" ]; then
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=nitf    -Jsrs=4326  -Jheight=256 -Jwidth=256 -Jlayer=${TEST} -Jserver=$5 -Jport=$6
else
  echo "Unknown test"
  exit 1
fi
