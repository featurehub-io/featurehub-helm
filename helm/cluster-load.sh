#!/bin/sh
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit -1
fi
CLUSTER_NAME=$(kind get clusters)
VERSION=$1
kind --name $CLUSTER_NAME load docker-image featurehub/mr:$VERSION
kind --name $CLUSTER_NAME load docker-image featurehub/edge:$VERSION
kind --name $CLUSTER_NAME load docker-image featurehub/dacha:$VERSION
