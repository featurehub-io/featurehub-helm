#!/bin/bash
docker run -it  --workdir=/data  --volume $PWD:/data quay.io/helmpack/chart-testing:v3.7.1 /bin/bash