#!/bin/bash

TOOLING_INVENTORY=$1
OPENSHIFT_INVENTORY="$2"
CONTAINERIZED=$3
REGISTER_ALL_NODES=$4

# label openshift nodes, generate an inventory
cd /root/svt/openshift_tooling/openshift_labeler
echo "ansible-playbook -vvv -i "${OPENSHIFT_INVENTORY}" openshift_label.yml"
ansible-playbook -vvv --extra-vars "register_all_nodes=${REGISTER_ALL_NODES}" -i "${OPENSHIFT_INVENTORY}" openshift_label.yml

# setup pbench pods in case of containerized pbench, run pbench-ansible in case of non containerized pbench
if [[ "${CONTAINERIZED}" == "true" ]] || [[ "${CONTAINERIZED}" == "TRUE" ]]; then
	cd /root/svt/openshift_tooling/pbench
	./setup_pbench_pods.sh
else
	echo "Running pbench ansible"
	echo "----------------------------------------------------------"
	#### use a local pbench copy till the pprof fix is merged
	if [[ -d "/root/pbench" ]]; then
		rm -rf /root/pbench
	fi
	git clone https://github.com/distributed-system-analysis/pbench.git /root/pbench
	cd /root/pbench/contrib/ansible/openshift/
	pbench-clear-tools
	ansible-playbook -vv -i ${TOOLING_INVENTORY} pbench_register.yml
	echo "Finshed registering tools, labeling nodes"
	echo "----------------------------------------------------------"
	echo "List of tools registered:"
	echo "----------------------------------------------------------"
	pbench-list-tools
	echo "----------------------------------------------------------"
fi
