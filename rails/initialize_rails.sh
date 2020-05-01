#!/bin/sh
set -e
cd /usr/src/app
rm -f tmp/pids/server.pid
bin/rails s -b 0.0.0.0
