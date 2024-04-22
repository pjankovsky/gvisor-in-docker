#!/usr/bin/env bash

docker buildx build --platform linux/amd64 --load -t us-docker.pkg.dev/build-286712/non-prod-docker-us/peterj/gvisor:amd-v1 . && \
  docker push us-docker.pkg.dev/build-286712/non-prod-docker-us/peterj/gvisor:amd-v1
