#!/usr/bin/env bash

containerd &

sleep 1

crictl pull nginx

exec "$@"
