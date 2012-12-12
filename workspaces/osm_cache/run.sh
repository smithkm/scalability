#!/bin/bash

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

# cache tests have four steps 1) pre-seeding 2) removing generated jmeter results 3) testing 4) clearing cache
if [ "${TEST}" = "wms_100" ]; then
  # pre-seed all tiles
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles 
  rm -r summary.csv
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles
  ssh -p 7777 tomcat@scale.dev.opengeo.org "rm -r /var/lib/geoserver_data/osm/gwc"
if [ "${TEST}" = "wms_50" ]; then
  # pre-seed half of the tiles
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles_50 
  rm -r summary.csv
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles 
  ssh -p 7777 tomcat@scale.dev.opengeo.org "rm -r /var/lib/geoserver_data/osm/gwc"
if [ "${TEST}" = "wms_25" ]; then
  # pre-seed a quarter of the tiles
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} -Jbboxes=tiles_25 
  rm -r summary.csv
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS} 
  ssh -p 7777 tomcat@scale.dev.opengeo.org "rm -r /var/lib/geoserver_data/osm/gwc"
if [ "${TEST}" = "wms_0" ]; then
  # do not pre-seed any tiles
  jmeter -p ../jmeter.properties -t wms.jmx -n -Jnodes=${NODES} -Jthreads=${THREADS} -Jloops=${LOOPS}
  ssh -p 7777 tomcat@scale.dev.opengeo.org "rm -r /var/lib/geoserver_data/osm/gwc"
else
  echo "Unknown test"
  exit 1
fi
