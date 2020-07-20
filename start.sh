#!/bin/bash

source utils.sh

printf "Setup connect to OpenShift Cluster"
oc login -s $OCP_API -u $OCP_USERNAME -p $OCP_PASSWORD --insecure-skip-tls-verify=true
oc cluster-info

NS=$(NS:-open-cluster-management}

if oc get namespace | grep $NS ; then
  oc get pods -n $NS
fi
