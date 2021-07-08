#!/bin/bash
set -e

echo 1 > /proc/sys/vm/overcommit_memory

exec "$@"
