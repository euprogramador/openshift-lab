#!/bin/bash

ssh-keygen -R master-01.cluster.nodes
ssh-keygen -R master-02.cluster.nodes
ssh-keygen -R master-03.cluster.nodes
ssh-keygen -R worker-01.cluster.nodes
ssh-keygen -R worker-02.cluster.nodes


ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i openshift-ansible-ovs/inventory.erb openshift-custom-ansible/site-ha-masters.yml -u root --ask-pass

ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i openshift-ansible-ovs/inventory.erb openshift-custom-ansible/site-ha-infra.yml -u root --ask-pass

ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i openshift-ansible-ovs/inventory.erb openshift-ansible/playbooks/prerequisites.yml -u root --ask-pass

ANSIBLE_HOST_KEY_CHECKING=False sshpass -p root ansible-playbook -i openshift-ansible-ovs/inventory.erb openshift-ansible/playbooks/byo/config.yml -u root --ask-pass


