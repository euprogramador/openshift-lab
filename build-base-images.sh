#!/bin/bash

echo "criando a imagem de base para o ambiente...."
cd packer
packer build --force centos-7-base.json &
P1=$!
packer build --force centos-7-gateway.json &
P2=$!
wait $P1 $P2

echo "imagens de base criadas."