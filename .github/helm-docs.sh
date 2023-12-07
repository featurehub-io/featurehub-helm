#!/bin/bash
set -euo pipefail

HELM_DOCS_VERSION="1.11.3"

# install helm-docs
curl --silent --show-error --fail --location --output /tmp/helm-docs.tar.gz https://github.com/norwoodj/helm-docs/releases/download/v"${HELM_DOCS_VERSION}"/helm-docs_"${HELM_DOCS_VERSION}"_Linux_x86_64.tar.gz
tar -xf /tmp/helm-docs.tar.gz helm-docs

# validate docs
./helm-docs
echo "Checking to ensure PR has updated the helm docs before attempting to merge to master as pipeline does not generate them. Next step will fail if helm-docs are not up to date"
git diff --exit-code
