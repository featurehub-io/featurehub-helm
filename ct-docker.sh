#!/bin/bash
docker run --workdir=/data  --volume $PWD:/data quay.io/helmpack/chart-testing:latest sh -c ./ct-test.sh