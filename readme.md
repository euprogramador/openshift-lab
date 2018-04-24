# openshift in vm

Este projeto efetua a instalação do openshift em uma vm ou mais vms. O objetivo é testar a conectividade de rede, storage, e outros serviços. 

Para isso precisamos emular uma rede completamente isolada, entretanto com controle de saida.

passo 1 => iniciar um servidor dns, e configurar corretamente o dns reverso para os ips do cluster.
  docker run --name bind -d --restart=always   --publish 192.168.99.1:53:53/tcp --publish 192.168.99.1:53:53/udp --publish 10000:10000/tcp   --volume /srv/docker/bind:/data   sameersbn/bind:9.10.3-20180127
  esta imagem docker executa um bind que pode ser configurado via webmin https://192.168.99.1:10000

docker run -d --name nfs --net=host --privileged -v /home/carlosr/Documentos/storage:/nfsshare -e SYNC=true -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest

passo 2 => adicionar rota para gateway da rede interna (openshift)
  sudo ip route add 192.168.1.0/24 via 192.168.99.5 dev vboxnet0

passo 3 => dar acesso a internet para maquinas
  ssh <usuario>@<ip> -D 192.168.99.1:11000 -nNT
  este comando inicia um servidor socks no endereço remoto via ssh, este endereço é usado internamente na rede para prover acesso a internet.

passo 4 => criar receitas de base
  ./build-base-image.sh

passo 5 => criar máquinas do ambiente
  ./criar-vms.sh

passo 6 => rodar receita de instalação do openshift
  ./rodar-receita.sh
  
## Packer

Esta receita usa o packer o mesmo pode ser instalado assim:

wget https://releases.hashicorp.com/packer/1.2.1/packer_1.2.1_linux_amd64.zip?_ga=2.93272664.491092165.1522075135-1074735371.1522075135 -O packer.zip

unzip packer.zip
mv packer /usr/local/bin/packer
referencia: https://marclop.svbtle.com/creating-an-automated-centos-7-install-via-kickstart-file
