#!/bin/bash

SETUP_PBENCH=$1
CONTAINERIZED=$2
CLEAR_RESULTS=$3
MOVE_RESULTS=$4
TOOLING_INVENTORY=$5
FIRST_RUN_PROJECTS=$6
SECOND_RUN_PROJECTS=$7
THIRD_RUN_PROJECTS=$8

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

# Run tests	
if [[ "${CONTAINERIZED}" != "true" ]] && [[ "${CONTAINERIZED}" != "TRUE" ]]; then
	# Run nodevertical
	export KUBECONFIG
	cd /root/svt/openshift_scalability
	if [[ -n $FIRST_RUN_PROJECTS ]]; then
		# replace number of projects for the first run
		echo "RUNNING FIRST ITERATION OF MASTERVERTICAL WITH $FIRST_RUN_PROJECTS PROJECTS"
		echo "---------------------------------------------------------------------------"
		sed -i "/- num/c  \ \ \ \ - num: $FIRST_RUN_PROJECTS" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
		sed -i "/basename/c  \ \ \ \   basename: clusterp" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
		pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e \'new_file='$benchmark_results_dir/out.json''' -- /root/svt/openshift_scalability/masterVertical.sh golang
		# Move results
        	if [[ "${MOVE_RESULTS}" == "true" ]]; then
                	pbench-move-results --prefix=mastervert_"$FIRST_RUN_PROJECTS"_projects
        	fi
	fi
	#echo "Deleting the namespaces created"
	#for ((n=0;n<$FIRST_RUN_PROJECTS;n++)); do
        #	oc delete project c$n
	#done
	#echo "sleeping for 5 min for the cluster to settle"
	#sleep 10m
	if [[ -n "$SECOND_RUN_PROJECTS ]]; then
		# replace number of projects for the second  run
        	echo "RUNNING SECOND ITERATION OF MASTERVERTICAL WITH $SECOND_RUN_PROJECTS PROJECTS"
		echo "-----------------------------------------------------------------------------"
		sed -i "/- num/c  \ \ \ \ - num: $SECOND_RUN_PROJECTS" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
		sed -i "/basename/c  \ \ \ \   basename: p" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
        	pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e \'new_file='$benchmark_results_dir/out.json''' -- /root/svt/openshift_scalability/masterVertical.sh golang
		# Move results
        	if [[ "${MOVE_RESULTS}" == "true" ]]; then
                	pbench-move-results --prefix=mastervert_"$SECOND_RUN_PROJECTS"_projects
        	fi
	fi
	#echo "Deleting the namespaces created"
        #for ((n=0;n<$SECOND_RUN_PROJECTS;n++)); do
        #        oc delete project c$n
        #done
        #echo "sleeping for 5 min for the cluster to settle"
        #sleep 10m
	if [[ -n "$THIRD_RUN_PROJECTS" ]]; then
		# replace number of projects for the third run
        	echo "RUNNING THIRD ITERATION OF MASTERVERTICAL WITH $THIRD_RUN_PROJECTS PROJECTS"
		echo "---------------------------------------------------------------------------"
		sed -i "/- num/c  \ \ \ \ - num: $THIRD_RUN_PROJECTS" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
		sed -i "/basename/c  \ \ \ \   basename: loadp" /root/svt/openshift_scalability/config/golang/pyconfigMasterVertScalePause.yaml
        	pbench-user-benchmark --pbench-post='/usr/local/bin/pbscraper -i $benchmark_results_dir/tools-default -o $benchmark_results_dir; ansible-playbook -vv -i /root/svt/utils/pbwedge/hosts /root/svt/utils/pbwedge/main.yml -e \'new_file='$benchmark_results_dir/out.json''' -- /root/svt/openshift_scalability/masterVertical.sh golang
		if [[ $? != 0 ]]; then
                	echo "1" > /tmp/test_status
        	else
                	echo "0" > /tmp/test_status
        	fi
		# Move results
        	if [[ "${MOVE_RESULTS}" == "true" ]]; then
                	pbench-move-results --prefix=mastervert_"$THIRD_RUN_PROJECTS"_projects
        	fi
	fi
	#echo "Deleting the namespaces created"
        #for ((n=0;n<$THIRD_RUN_PROJECTS;n++)); do
        #        oc delete project c$n
        #done
        #echo "sleeping for 5 min for the cluster to settle"
        #sleep 10m

        # Move results
#	if [[ "${MOVE_RESULTS}" == "true" ]]; then
#		pbench-move-results --prefix=mastervert_1000_projects
#	fi
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
    	sed -i "/^benchmark_type/c benchmark_type=mastervertical" /root/scale-testing/vars
    
   	# run pbench-controller container
    	./run.sh
        if [[ $? != 0 ]]; then
		echo "1" > /tmp/test_status
	else
		echo "0" > /tmp/test_status
        fi
fi
