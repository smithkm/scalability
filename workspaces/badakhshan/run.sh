#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4
SERVER=$5
PORT=$6

# test format is 01_wms_nitf
ZOOM=${TEST::2}
SERVICE=${TEST:3:3}
TEST=${TEST:7}

if [[ "${TEST}" = geotiff* ]]; then
  SRS=32642
elif [[ "${TEST}" = mrsid* ]]; then
  SRS=32642
elif [[ "${TEST}" = nitf* ]]; then
  SRS=32642
else
  echo "Unknown test"
  exit 1
fi

jmeter -p ../jmeter.properties -t ${SERVICE}.jmx -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=${SRS}_${ZOOM} -Jsrs=${SRS} -Jheight=256 -Jwidth=256 -Jlayer=${TEST} -Jserver=$5 -Jport=$6
