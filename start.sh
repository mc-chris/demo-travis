#!/bin/bash

source utils.sh

printf "Setup connect to OpenShift Cluster"
oc login -s $OCP_API -u $OCP_USERNAME -p $OCP_PASSWORD
oc cluster-info