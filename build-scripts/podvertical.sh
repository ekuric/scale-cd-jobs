#!/bin/bash

SETUP_PBENCH=$1
CONTAINERIZED=$2
CLEAR_RESULTS=$3
MOVE_RESULTS=$4
TOOLING_INVENTORY=$5
PODS=$6
ITERATIONS=$7
INITIAL_BASENAME=pausepods
BASENAME=pausepods-iter

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
cp /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml.bak

# create namespace
oc new-project clusterproject0

# Switch to default ns
oc project default

# Run podvertical
export KUBECONFIG
cd /root/svt/openshift_scalability
chmod +x /root/svt/openshift_scalability/podVertical.sh
sed -i "/- num: 15000/c \ \ \ \ \ \ \ \ \- num: $PODS" /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml
for i in $(seq 1 $ITERATIONS); do
	sed -i "/basename: $INITIAL_BASENAME/c \ \ \ \ \ \ \ \ \ \ \basename: $BASENAME-$i" /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml
	pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vvv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e new_file=$benchmark_results_dir/out.json -e git_test_branch='"podvertical_$PODS"'; /root/svt/openshift_tooling/prometheus_db_dump/prometheus_dump.sh $benchmark_results_dir/tools-default' -- /root/svt/openshift_scalability/podVertical.sh golang ./config/golang/cluster-limits-pods-per-namespace
#	pbench-user-benchmark -- /root/svt/openshift_scalability/podVertical.sh golang ./config/golang/cluster-limits-pods-per-namespace
	# Move results
	if [[ "${MOVE_RESULTS}" == "true" ]]; then
		pbench-move-results --prefix=podvertical_"$PODS"
	fi
	INTIAL_BASENAME=$BASENAME-$i
done

# Replace the config
cp /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml.bak /root/svt/openshift_scalability/config/golang/cluster-limits-pods-per-namespace.yaml

# Delete the namespace
oc delete project clusterproject0

