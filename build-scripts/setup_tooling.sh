#!/bin/bash

TOOLING_INVENTORY=$1

# label openshift nodes, generate an inventory
cd /root/svt/openshift_tooling/openshift_labeler
ansible-playbook -vvv -i ${TOOLING_INVENTORY} openshift_label.yml

# setup pbench pods in case of containerized pbench, run pbench-ansible in case of non containerized pbench
if [[ "${CONTAINERIZED}" == "true" ]]; then
	cd /root/svt/openshift_tooling/pbench
	./setup_pbench_pods.sh
else
	echo "Running pbench ansible"
	echo "----------------------------------------------------------"
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
