#!/bin/bash

svt_repo_location=/root
controller_namespace=default
counter_time=5
wait_time=25
set -x
# Cleanup
function cleanup() {
	oc delete -f $svt_repo_location/svt/openshift_templates/performance_monitoring/pbench/pbench-controller-job.yml -n $controller_namespace
	#oc delete -f $svt_repo_location/svt/openshift_templates/performance_monitoring/pbench/scale-config.yml -n $controller_namespace
	oc delete cm tooling-config
	sleep $wait_time
}

# Ensure that the host has svt repo cloned
if [[ ! -d $svt_repo_location/svt ]]; then
	 git clone https://github.com/chaitanyaenr/svt.git
fi

# Check if the controller job and configmap exists
oc get jobs -n $controller_namespace | grep -w "controller" &>/dev/null
if [[ $? == 0 ]]; then
	cleanup
fi 
oc get cm -n $controller_namespace | grep -w "tooling-config" &>/dev/null
if [[ $? == 0 ]]; then
	cleanup
fi

# Create configmap and job
oc create configmap tooling-config --from-env-file=/root/properties -n $controller_namespace
#oc create -f $svt_repo_location/svt/openshift_templates/performance_monitoring/pbench/scale-config.yml -n $controller_namespace
oc create -f $svt_repo_location/svt/openshift_templates/performance_monitoring/pbench/pbench-controller-job.yml -n $controller_namespace
sleep $wait_time
controller_pod=$(oc get pods -n $controller_namespace | grep "controller" | awk '{print $1}')
counter=0
while [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") != "Running" ]]; do
	sleep $counter_time
	counter=$((counter+1))
	if [[ $counter -ge 120 ]]; then
		echo "Looks like the $controller_pod is not up after 120 sec, please check"
		exit 1
	fi
done
oc logs -f $controller_pod -n $controller_namespace
while [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") != "Succeeded" ]]; do
	if [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") == "Failed" ]]; then
   		echo "JOB FAILED"
		echo "CLEANING UP"
   		cleanup
   		exit 1
   	else        
    		sleep $wait_time
        	fi
done
	echo "JOB SUCCEEDED"

echo "CLEANING UP"
cleanup
