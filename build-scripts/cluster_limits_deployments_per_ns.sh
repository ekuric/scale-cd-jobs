#!/bin/bash

SETUP_PBENCH=$1
CONTAINERIZED=$2
CLEAR_RESULTS=$3
MOVE_RESULTS=$4
TOOLING_INVENTORY=$5
DEPLOYMENTS=$6

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
    	docker images | grep -w "pbench-controller"
    	if [[ $? != 0 ]]; then
    		docker pull ravielluri/image:controller
        	docker tag ravielluri/image:controller pbench-controller:latest
    	fi
else
    	echo "Not setting up pbench"
fi
    
# clear results
if [[ "${CLEAR_RESULTS}" == "true" ]]; then
	pbench-clear-results
fi

# Backup config
cp /root/svt/openshift_scalability/config/golang/cluster-limits-deployments-per-namespace.yaml /root/svt/openshift_scalability/config/golang/cluster-limits-deployments-per-namespace.yaml.bak

# create namespace
oc new-project clusterproject0

# Run tests	
if [[ "${CONTAINERIZED}" != "true" ]] && [[ "${CONTAINERIZED}" != "TRUE" ]]; then
	# Run deployments per ns
	export KUBECONFIG
	cd /root/svt/openshift_scalability
    	chmod +x /root/svt/openshift_scalability/deployments_per_ns.sh
	sed -i "/num: 2000/c \ \ \ \ \ \ \ \ \ \ num: $DEPLOYMENTS" /root/svt/openshift_scalability/config/golang/cluster-limits-deployments-per-namespace.yaml
	pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vvv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e new_file=$benchmark_results_dir/out.json -e git_test_branch='"deployments_per_ns_$DEPLOYMENTS"'' -- /root/svt/openshift_scalability/deployments_per_ns.sh golang
        # Move results
	if [[ "${MOVE_RESULTS}" == "true" ]]; then
		pbench-move-results --prefix=deployments_per_ns_"$DEPLOYMENTS"
	fi
else
    	# clone scale-testing repo
    	if [[ -d "/root/scale-testing" ]]; then
    		rm -rf /root/scale-testing
    	fi
    	git clone https://github.com/chaitanyaenr/scale-testing /root/scale-testing
    	cd /root/scale-testing

    	# copy perf and pbench keys, tooling inventory
    	cp /root/.ssh/id_rsa keys/id_rsa_perf
    	chmod 600 keys/id_rsa_perf
    	cp /root/.ssh/authorized_keys keys/
    	cp /opt/pbench-agent/id_rsa keys/
    	chmod 600 keys/id_rsa
    	cp ${TOOLING_INVENTORY} /root/scale-testing/inventory
    
    	# vars file
    	sed -i "/^benchmark_type/c benchmark_type=deployments_per_ns" /root/scale-testing/vars
    
   	# run pbench-controller container
    	./run.sh
fi

# Restore config
cp /root/svt/openshift_scalability/config/golang/cluster-limits-deployments-per-namespace.yaml.bak /root/svt/openshift_scalability/config/golang/cluster-limits-deployments-per-namespace.yaml

# Cleanup namespace
oc delete project clusterproject0
# we won't need this for 3.11 as we can use the --wait option which is going to be introduced
sleep 20m
