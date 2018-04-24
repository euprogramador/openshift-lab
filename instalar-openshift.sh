#!/bin/bash

source functions.sh




print 100 
print 100 "Receita para instalação do openshift"
print 100 "===================================================================================================="
print 100 ""
print 100 "Selecione uma receita para instalação:"
print 100 ""

select INVENTORY in $(ls -h inventories/*)
do

if [ -f "$INVENTORY" ]
then
    break;
else
    echo "Selecione corretamente!"
fi
done



print 100 "Instalando a receita: ${INVENTORY}"
print 100 ""

print 100
print 100 "validando instalação..."
print 100

# valida acesso a internet
http_proxy=socks5://192.168.99.1:11000 timeout 10 curl www.google.com.br -s -f -o /dev/null 
if [ $? -eq 0 ]; then
    print 100 "   [OK] - conexão com a internet verificada"
else
    print 100 "   [ERRO] - conexão com a internet verificada"
    error 100
    error 100 "   Sem conexão com a internet!";
    error 100 
    error 100 "   É necessário uma conexão socks ativa para o ip 192.168.99.1 para porta 11000"
    error 100
    error 100 "   Execute: ssh <usuario>@<servidor_com_acesso_a_internet> -D 192.168.99.1:11000"
    error 100
    exit 1
fi

# valida rotas 
ip route | grep 192.168.1.0/24 | grep 192.168.99.5 > /dev/null 
if [ $? -eq 0 ]; then
    print 100 "   [OK] - rota para máquinas virtuais"
else
    error 100 "   [ERRO] - rota para máquinas virtuais"
    error 100
    error 100 "   Não há rotas para acesso a rede interna de máquinas virtuais! ";
    error 100 
    error 100 "   É necessário adicionar uma rota para acesso as máquinas virtuais do openshift."
    error 100
    error 100 "   Execute: sudo ip route add 192.168.1.0/24 via 192.168.99.5 dev vboxnet0"
    error 100
    exit 1
fi

# valida dns
SAIDA=$(ansible nodes -i $INVENTORY -c local -m shell -a 'if [[ $(dig {{inventory_hostname}} +short | wc -l) -eq 1 ]]; then exit 0; else exit 1; fi')
if [ $? -eq 0 ]; then
    print 100 "   [OK] - DNS devidamente configurado"
else
    error 100 "   [ERRO] - DNS devidamente configurado"
    error 100
    error 100 "   É necessário uma configuração válida de dns para todas as máquinas listadas!";
    error 100
    error 100 "   Verifique suas configurações de dns";
    error 100
    echo "$SAIDA"
    exit 1
fi


# valida reverso
SAIDA=$(ansible nodes -i $INVENTORY -c local -m shell -a 'if [[ $(host $(dig {{inventory_hostname}} +short) | grep {{inventory_hostname}} | wc -l) -eq 1 ]]; then exit 0; else exit 1; fi')
if [ $? -eq 0 ]; then
    print 100 "   [OK] - DNS reverso devidamente configurado"
else
    error 100 "   [ERRO] - DNS reverso devidamente configurado"
    error 100
    error 100 "   É necessário uma configuração válida de dns reverso para todas as máquinas listadas!";
    error 100
    error 100 "   Verifique suas configurações de dns";
    error 100
    echo "$SAIDA"
    exit 1
fi

print 100 
print 100 
print 100 "Iniciando preparação do ambiente..."


case "$1" in 
    --retry)
        print 100 "   [SKIP] - Iniciando preparação do ambiente..."
        print 100 
        print 100 
        ;;
    *) 

        print 100 "   Efetuando a limpeza do ssh-keygen..."
        ansible nodes -i $INVENTORY -c local -m shell -a 'ssh-keygen -R {{inventory_hostname}}' > /dev/null
            print 100 "      [OK] - chaves ssh limpas."

        print 100 "   Criando imagens de base..."
        cd packer
        file="$(pwd)/output-iso-base/centos-7-x86_64-base.ovf"
        if [ -f "$file" ]
        then
            print 100 "      [OK] - máquina centos-7-base já existe."
        else
            print 100 "      [OK] - máquina centos-7-base não existe, criando máquina, log do processo em: logs/centos-7-base.build.log"
            packer build --force centos-7-base.json >  ../logs/centos-7-base.build.log
        fi

        file="$(pwd)/output-iso-gateway/centos-7-x86_64-gateway.ovf"
        if [ -f "$file" ]
        then
            print 100 "      [OK] - máquina centos-7-gateway já existe."
        else
            print 100 "      [OK] - máquina centos-7-gateway não existe, criando máquina, log do processo em: logs/centos-7-gateway.build.log"
            packer build --force centos-7-gateway.json >  ../logs/centos-7-gateway.build.log
        fi
        cd ..


        print 
        print 100 "   Removendo máquinas virtuais..."

        SAIDA=$(vboxmanage controlvm gateway poweroff 2>&1 > logs/destroy-vms.log)
        for((i=1;i<=60;i+=1)); do if [[ $(VBoxManage list runningvms | sed -r 's/^"(.*)".*$/\1/' | grep gateway | wc -l) -eq 0 ]]; then break; fi; sleep 1; done
        SAIDA=$(vboxmanage unregistervm gateway --delete 2>&1 >> logs/destroy-vms.log)
        print 100 "      [OK] - removido máquina gateway"

        ansible-playbook -c local -i $INVENTORY playbooks/destroi-vms.yml 2>&1 >> logs/destroy-vms.log
        if [ $? -eq 0 ]; then
            print 100 "      [OK] - máquinas virtuais removidas"
        else
            error 100 "      [ERRO] - máquinas virtuais removidas"
            error 100
            error 100 "      Não foi possível excluir uma ou mais máquinas virtuais. ";
            error 100
            error 100 "      Verifique o logs/destroy-vms.log para maiores detalhes.";
            error 100
            exit 1
        fi


        print 
        print 100 "   Criando máquinas virtuais..."


        SAIDA=$(vboxmanage import packer/output-iso-gateway/centos-7-x86_64-gateway.ovf 2>&1 > logs/cria-vms.log)
        sleep 1

        vboxmanage modifyvm "centos-7-x86_64-gateway" --name=gateway \
            --nic1=intnet --intnet1=openshift \
            --nic2=hostonly --hostonlyadapter2=vboxnet0 --intnet2=none 2>&1 >> logs/cria-vms.log

        SAIDA=$(vboxmanage startvm gateway --type headless 2>&1 >> logs/cria-vms.log)
        print 100 "      Aguardando conectividade com gateway..."

        for ((i=1;i<=10;i+=1)); 
        do 
            nc -z 192.168.1.1 22  > /dev/null
            if [ $? -eq 0 ]
            then
                break
            fi
            sleep 1
        done

        if [ "$i" -eq 10 ]; then
            error 100 "         [ERRO] - Nã foi possível obter conectividade com o gateway"
            error 100
            error 100 "         Verifique há conectividade com o gateway 192.168.1.1.";
            error 100
            exit 1
        fi
        print 100 "         [OK] - Conectividade com gateway estabelecida."
        print 100 "      Criando máquinas virtuais..."


        SAIDA=$(ansible-playbook -c local -i $INVENTORY playbooks/cria-vms.yml 2>&1 >> logs/cria-vms.log)
        if [ $? -eq 0 ]; then
            print 100 "      [OK] - máquinas virtuais criadas"
        else
            error 100 "      [ERRO] - máquinas virtuais criadas"
            error 100
            error 100 "      Não foi possível criar uma ou mais máquinas virtuais. ";
            error 100
            error 100 "      Verifique o logs/cria-vms.log para maiores detalhes.";
            error 100
            exit 1
        fi


        print 
        print 100 "   Verificando connectividade com as máquinas..."
        sleep  30
        ansible nodes -i $INVENTORY -c local -m shell -a "timeout 3 sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  root@{{ inventory_hostname }} 'echo success'" 2>&1 > logs/verifica-conectividade.log
        if [ $? -eq 0 ]; then
            print 100 "   [OK] - máquinas virtuais acessíveis"
        else
            error 100 "   [ERRO] -  máquinas virtuais acessíveis"
            error 100
            error 100 "   Não foi possível conectar a uma ou mais máquinas virtuais. ";
            error 100
            error 100 "   Verifique o logs/verifica-conectividade.log para maiores detalhes.";
            error 100
            exit 1
        fi
esac


print 100
print 100 "Iniciando a instalação..."

print 100
print 100 "   Executando playbook..."

SAIDA=$(ansible nodes -i $INVENTORY -c local -m shell -a "if [[ {{ groups['masters'] | length }} -eq 1 ]]; then exit 0; else exit 1; fi" 2>&1 > /dev/null)
if [ $? -eq 0 ]; then
    print 100
    print 100 "      [SKIP] - há apenas um servidor master."
    print 100 "               não será configurado HA (High Avaliability) para servidores masters"
else
    print 100 "      Configurando servidores masters em modo HA, acompanhe no logs/install-ha-masters.log"
    SAIDA=$(ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i $INVENTORY playbooks/openshift-ha-playbook/site-ha-masters.yml -u root --ask-pass 2>&1 > logs/install-ha-masters.log)
    if [ $? -eq 0 ]; then
        print 100 "      [OK] - Servidores masters em modo HA"
    else
        error 100 "      [ERRO] - Servidores masters em modo HA"
        error 100
        error 100 "      Ocorreu um erro na execução da playbook de configuração do modo ha" 
        error 100 "      verifique o log em logs/install-ha-masters.log para maiores detalhes.";
        error 100
        exit 1
    fi
fi



SAIDA=$(ansible nodes -i $INVENTORY -c local -m shell -a "if [[ {{ groups['lb-app-nodes'] | length }} -eq 1 ]]; then exit 0; else exit 1; fi" 2>&1 > /dev/null)
if [ $? -eq 0 ]; then
    print 100
    print 100 "      [SKIP] - há apenas um servidor infra."
    print 100 "               não será configurado HA (High Avaliability) para servidores infra"
else
    print 100 "      Configurando servidores infra em modo HA, acompanhe no logs/install-ha-infra.log"
    SAIDA=$(ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i $INVENTORY playbooks/openshift-ha-playbook/site-ha-infra.yml -u root --ask-pass 2>&1 >logs/install-ha-infra.log)
    if [ $? -eq 0 ]; then
        print 100 "      [OK] - Servidores infra em modo HA"
    else
        error 100 "      [ERRO] - Servidores infra em modo HA"
        error 100
        error 100 "      Ocorreu um erro na execução da playbook de configuração do modo ha. "
        error 100 "      verifique o log em logs/install-ha-infra.log para maiores detalhes.";
        error 100
        exit 1
    fi
fi

print 100 "      Validando Pré requisitos para instalação, acompanhe no logs/install-prerequisites.log"
SAIDA=$(ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i $INVENTORY tmp/openshift-ansible/playbooks/prerequisites.yml -u root --ask-pass 2>&1 >logs/install-prerequisites.log)
RET=$?
if [ $RET -eq 0 ]; then
    print 100 "      [OK] - Pré requisitos para instalação do openshift"
else
    error 100 "      [ERRO] - Pré requisitos para instalação do openshift"
    error 100
    error 100 "      Ocorreu um erro na execução da playbook de verificação de pré requisitos para instalação do openshift. "
    error 100 "      verifique o log em logs/install-prerequisites.log para maiores detalhes.";
    error 100
    exit 1
fi



print 100 "      Instalando openshift, acompanhe no logs/install-deploy_cluster.log"
SAIDA=$(ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i $INVENTORY tmp/openshift-ansible/playbooks/deploy_cluster.yml -u root --ask-pass 2>&1 >logs/install-deploy_cluster.log)
RET=$?
if [ $RET -eq 0 ]; then
    print 100 "      [OK] - Instalando openshift"
    print 100 
    print 100 
    print 100 
    print 100 
    success 100
    success 100
    success 100 "Openshift instalado com sucesso."
    success 100
    success 100

else
    error 100 "      [ERRO] - Instalando openshift"
    error 100
    error 100 "      Ocorreu um erro na execução da playbook de instalação do openshift. "
    error 100 "      verifique o log em logs/install-deploy_cluster.log para maiores detalhes.";
    error 100
    exit 1
fi


