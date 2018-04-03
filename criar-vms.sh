#!/bin/bash

source functions.sh

echo "removendo maquinas antigas..."
destroy_vm gateway

destroy_vm etcd-01
destroy_vm etcd-02
destroy_vm etcd-03

destroy_vm master-01
destroy_vm master-02
destroy_vm master-03

destroy_vm worker-01
destroy_vm worker-02

destroy_vm infra-01
destroy_vm infra-02

echo "removidas."

echo "criando ambientes..."

create_gateway

create_vm master-01 4096 192.168.1.101
create_vm master-02 4096 192.168.1.102
create_vm master-03 4096 192.168.1.103

create_vm worker-01 6144 192.168.1.91
create_vm worker-02 6144 192.168.1.92

create_vm infra-01 4096 192.168.1.93
create_vm infra-02 4096 192.168.1.94

