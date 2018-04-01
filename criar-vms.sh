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

echo "removidas."

echo "criando ambientes..."

create_gateway

create_vm etcd-01 1024 192.168.1.51
create_vm etcd-02 1024 192.168.1.52
create_vm etcd-03 1024 192.168.1.53

create_vm master-01 1024 192.168.1.101
create_vm master-02 1024 192.168.1.102
create_vm master-03 1024 192.168.1.103

create_vm worker-01 10240 192.168.1.91
create_vm worker-02 10240 192.168.1.92

