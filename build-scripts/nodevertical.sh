#!/bin/bash

SETUP_PBENCH=$1
CONTAINERIZED=$2
CLEAR_RESULTS=$3
MOVE_RESULTS=$4
TOOLING_INVENTORY=$5
ENVIRONMENT=$6

if [[ -z ${SETUP_PBENCH} ]]; then
	SETUP_PBENCH=false
fi

## Setup pbench
if [[ "${CONTAINERIZED}" != "true" ]] && [[ "${SETUP_PBENCH}" == "true" ]]; then
	set -e
	# register tools
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
elif [[ "${CONTAINERIZED}" == "true" ]] && [[ "${SETUP_PBENCH}" == "true" ]]; then
	# check if the jump node has pbench-controller image
    	docker images | grep -w "docker.io/ravielluri/image:controller"
    	if [[ $? != 0 ]]; then
    		docker pull ravielluri/image:controller
    	fi
	cd /root/svt/openshift_tooling/pbench
        ./setup_pbench_pods.sh
else
    	echo "Not setting up pbench"
fi
    
# clear results
if [[ "${CLEAR_RESULTS}" == "true" ]]; then
	pbench-clear-results
fi

# Run nodevertical
export KUBECONFIG
oc project default
cd /root/svt/openshift_scalability
cp /root/svt/openshift_scalability/config/golang/nodeVertical-labeled-nodes.yaml /root/svt/openshift_scalability/config/golang/nodeVertical-labeled-nodes.yaml.bak
#pbench-user-benchmark -- /root/svt/openshift_scalability/nodeVertical.sh test golang "$ENVIRONMENT"
pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vvv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e new_file=$benchmark_results_dir/out.json -e git_test_branch=nodevert' -- /root/svt/openshift_scalability/nodeVertical.sh test golang "$ENVIRONMENT"
#/root/svt/openshift_scalability/nodeVertical.sh test golang "$ENVIRONMENT"
# Move results
if [[ "${MOVE_RESULTS}" == "true" ]]; then
	pbench-move-results --prefix=nodevertical
fi
# Replace the config file with the original one
cp /root/svt/openshift_scalability/config/golang/nodeVertical-labeled-nodes.yaml.bak /root/svt/openshift_scalability/config/golang/nodeVertical-labeled-nodes.yaml

# cleanup
#oc project clusterproject0 &>/dev/null
#if [[ $? !=0 ]]; then
#	oc delete project clusterproject0
#fi
