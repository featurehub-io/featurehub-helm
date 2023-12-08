#!/bin/sh
cd helm/featurehub
helm repo add bitnami https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
ct lint --config ../../.github/ct.yaml --chart-dirs . --charts . --target-branch main