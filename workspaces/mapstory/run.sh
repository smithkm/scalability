#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4
SERVER=$5
PORT=$6

jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jlayer=${TEST} -Jheight=512 -Jwidth=512 -Jserver=$5 -Jport=$6
