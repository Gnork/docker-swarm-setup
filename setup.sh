#!/usr/bin/env bash

NUM_AGENTS=1
AGENT_RAM=2048
AGENT_CPUS=2
AGENT_DISK=20000

echo "--------------------------------------"
echo "DELETE EXISTING MACHINES"
echo "--------------------------------------"

for i in $(docker-machine ls -q); do
    docker-machine rm ${i}
done

echo "--------------------------------------"
echo "CREATE MACHINE: cc-consul"
echo "--------------------------------------"

docker-machine create -d virtualbox cc-consul

echo "--------------------------------------"
echo "SET ENVIRONMENT: cc-consul"
echo "--------------------------------------"

docker-machine env cc-consul

eval $(docker-machine env cc-consul)

echo "--------------------------------------"
echo "RUN CONTAINER: cc-consul"
echo "--------------------------------------"

docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

echo "--------------------------------------"
echo "CREATE MACHINE: cc-manager"
echo "--------------------------------------"

docker-machine create -d virtualbox \
--virtualbox-memory ${AGENT_RAM} \
--virtualbox-cpu-count ${AGENT_CPUS} \
--virtualbox-disk-size ${AGENT_DISK} \
--swarm --swarm-master \
--swarm-discovery="consul://$(docker-machine ip cc-consul):8500" \
--engine-opt="cluster-store=consul://$(docker-machine ip cc-consul):8500" \
--engine-opt="cluster-advertise=eth1:2376" \
cc-manager

echo "--------------------------------------"
echo "SET ENVIRONMENT: OVERRIDE DOCKER_HOST"
echo "--------------------------------------"

export DOCKER_HOST=$(docker-machine ip cc-manager):3376
echo $(docker-machine ip cc-manager):3376

echo "--------------------------------------"
echo "CREATE OVERLAY NETWORK"
echo "--------------------------------------"

network_id=$(docker network create --driver overlay cc-overlay-network)
docker network inspect ${network_id}

for i in $(seq 1 ${NUM_AGENTS}); do
    echo "--------------------------------------"
    echo "CREATE MACHINE: cc-agent${i}"
    echo "--------------------------------------"

    docker-machine create -d virtualbox \
    --virtualbox-memory ${AGENT_RAM} \
    --virtualbox-cpu-count ${AGENT_CPUS} \
    --virtualbox-disk-size ${AGENT_DISK} \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cc-consul):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cc-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cc-agent${i}
done

echo "--------------------------------------"
echo "SWARM SETUP COMPLETE"
echo "--------------------------------------"

echo $(docker-machine ip cc-manager):3376
