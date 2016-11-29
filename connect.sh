#!/usr/bin/env bash

eval $(docker-machine env cc-manager)
export DOCKER_HOST=$(docker-machine ip cc-manager):3376

echo $(docker-machine ip cc-manager):3376