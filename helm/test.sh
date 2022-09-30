#!/bin/sh
helm template --debug featurehub featurehub --output-dir gen_templates --namespace test-namespace -f test-values.yaml