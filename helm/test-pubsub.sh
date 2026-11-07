#!/bin/sh
rm -rf gen_templates
helm template --debug pubsub-emulator ../unreleased-helm/pubsub-emulator --output-dir gen_templates --namespace test-namespace