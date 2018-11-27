#!/bin/bash

TOOLING_INVENTORY=$1
OPENSHIFT_INVENTORY="$2"
CONTAINERIZED=$3
REGISTER_ALL_NODES=$4

if [[ ! -d "/root/svt" ]]; then
	git clone https://github.com/chaitanyaenr/svt.git /root/svt
	cd /root/svt
	git checkout containerozed_tooling
fi
# label openshift nodes, generate an inventory
cd /root/svt/openshift_tooling/openshift_labeler
echo "ansible-playbook -vvv -i "${OPENSHIFT_INVENTORY}" openshift_label.yml"
ansible-playbook -vvv --extra-vars "register_all_nodes=${REGISTER_ALL_NODES} tooling_inv=${TOOLING_INVENTORY}" -i "${OPENSHIFT_INVENTORY}" openshift_label.yml

# setup pbench pods in case of containerized pbench, run pbench-ansible in case of non containerized pbench
if [[ "${CONTAINERIZED}" == "true" ]] || [[ "${CONTAINERIZED}" == "TRUE" ]]; then
	cd /root/svt/openshift_tooling/pbench
	./setup_pbench_pods.sh
fi
echo "Running pbench ansible"
echo "----------------------------------------------------------"
if [[ -d "/root/pbench" ]]; then
	rm -rf /root/pbench
fi
git clone https://github.com/chaitanyaenr/pbench.git /root/pbench
cd /root/pbench/contrib/ansible/openshift/
git checkout ports
pbench-clear-tools
ansible-playbook -vvv --extra-vars "inventory_file_path=${TOOLING_INVENTORY}" -i ${TOOLING_INVENTORY} pbench_register.yml
echo "Finshed registering tools, labeling nodes"
echo "----------------------------------------------------------"
echo "List of tools registered:"
echo "----------------------------------------------------------"
pbench-list-tools
echo "----------------------------------------------------------"
