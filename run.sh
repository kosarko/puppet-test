#!/bin/bash
puppet apply manifests/first.pp --config $(dirname $0)/puppet.conf "$@"
