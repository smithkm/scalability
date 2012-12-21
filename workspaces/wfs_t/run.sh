#!/bin/bash
# an empty workspace that can be populated and tested

TEST=$1
NODES=$2
THREADS=$3
LOOPS=$4

if [ "${TEST}" = "wfs-t" ]; then
  exit 1
else
  echo "Unknown test"
  exit 1
fi
