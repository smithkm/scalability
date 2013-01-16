#!/bin/bash
# an empty workspace that can be populated and tested

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

jmeter -p ../jmeter.properties -t dbsetup.jmx -n

if [ "${TEST}" = "wfs_t" ]; then
  jmeter -p ../jmeter.properties -t wfs_t.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jserver=scale.dev.opengeo.org -Jport=80 -Jdbserver=scale-db.dev.opengeo.org
else
  echo "Unknown test"
  exit 1
fi
