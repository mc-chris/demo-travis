#!/bin/bash

BEER="\xF0\x9F\x8D\xBA - "

disable_default_olm_catalog() {
  # https://docs.openshift.com/container-platform/4.4/operators/olm-restricted-networks.html#olm-restricted-networks-operatorhub_olm-restricted-networks
  oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
}

enable_default_olm_catalog() {
  oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": false}]'
}

create_operatorsource() {
  # oc get secret marketplacesecret-rhvo -n openshift-marketplace && return
  cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: marketplacesecret-rhvo
  namespace: openshift-marketplace
type: Opaque
stringData:
    token: "basic ${OLM_AUTH_KEY}"
---
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: rhvoo
  namespace: openshift-marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: ${registryNamespace}
  authorizationToken:
    secretName: marketplacesecret-rhvo
EOF
}

create_downstream_icsp() {
  # if not disconnected, you can get the icsp from github
  # oc apply -f https://gist.githubusercontent.com/cdoan1/527c46ac3db7d0aa4cd7e59e064ee05f/raw/downstream-icsp.yaml
  oc get imagecontentsourcepolicy rhacm-repo && return
  printf "expected icsp not found, apply it now ..."
  cat <<EOF | oc apply -f -
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: rhacm-repo
spec:
  repositoryDigestMirrors:
  - mirrors:
    - quay.io:443/acm-d
    source: registry.redhat.io/rhacm2
  - mirrors:
    - registry.redhat.io/openshift4/ose-oauth-proxy
    source: registry.access.redhat.com/openshfit4/ose-oauth-proxy
EOF
}

create_global_pull_secret() {
  if [[ ! -f .global-pull-secret-updated.lock ]]; then
    cat > downstream-pull-secret.json <<EOF
${GLOBAL_PULL_SECRET}
EOF
    oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=downstream-pull-secret.json
    touch .global-pull-secret-updated.lock
    rm -rf downstream-pull-secret.json
  fi
}


subscribe_acm_imageset() {
  if [[ ! -d ./acm-hive-openshift-releases ]]; then
    git clone git@github.com:open-cluster-management/acm-hive-openshift-releases.git
    oc apply -k ./acm-hive-openshift-releases/subscription
    rm -rf ./acm-hive-openshift-releases
    printf "\n"
  fi
}

enable_baremetal_ui() {
  export NS=${NS:=open-cluster-management}
  oc -n $NS patch deploy console-header -p '{"spec":{"template":{"spec":{"containers":[{"name":"console-header","env":
[{"name": "featureFlags_baremetal","value":"true"}]}]}}}}'
  oc -n $NS patch $(oc -n $NS get deploy -o name | grep consoleui) -p '{"spec":{"template":{"spec":{"containers":[{"name":"hcm-ui","env":
[{"name": "featureFlags_baremetal","value":"true"}]}]}}}}'
}

subscribe_guestbook() {
  # TODO: if the user does not have access and clone fails?
  if [[ ! -d ./deploy ]]; then
    git clone git@github.com:cdoan1/deploy.git -b update-demo-content-2.x
    # oc new-project demo-guestbook
    # git clone git@github.com:open-cluster-management/deploy.git 
    # oc apply -k ./deploy/demo/app/guestbook
    # rm -rf ./deploy
  fi
  printf "\n"
}

subscribe_policies() {
  if [[ ! -d ./deploy ]]; then
    git clone git@github.com:open-cluster-management/deploy.git
    oc apply -k ./deploy/demo/policies
    rm -rf ./deploy
  fi
  printf "\n"
}

unsubscribe_guestbook() {
  if [[ ! -d ./deploy ]]; then
    git clone git@github.com:cdoan1/deploy.git -b update-demo-content-2.x
    # git clone git@github.com:open-cluster-management/deploy.git
    oc delete -k ./deploy/demo/app/guestbook
    rm -rf ./deploy
  fi
}

uninstall() {
  if [[ ! -d ./deploy ]]; then
    git clone git@github.com:open-cluster-management/deploy.git
    oc delete -k ./deploy/demo/app/guestbook
    oc delete -k ./deploy/demo/policies
    rm -rf ./deploy
  fi
}

# installPlanApproval: Automatic | Manual
#
subscribe_rhacm() {
  # oc get subscription advance-cluster-management-subscription -n $NS && return
  cat <<EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhacm-og
spec:
  targetNamespaces:
  - ${NS}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: advance-cluster-management-subscription
  namespace: ${NS}
spec:
  channel: release-2.0
  installPlanApproval: Automatic
  name: advanced-cluster-management
  source: rhvoo
  sourceNamespace: openshift-marketplace
  startingCSV: advanced-cluster-management.v2.0.0
EOF
}

# metadata:
#   annotations:
#     "mch-imageRepository": "quay.io/open-cluster-management"
#
instance_mch() {
  # oc get mch multiclusterhub -n $NS && return
  cat <<EOF | oc apply -f -
---
apiVersion: v1
data:
  .dockerconfigjson: ${PULL_SECRET}
kind: Secret
metadata:
  name: quay-secret
  namespace: ${NS}
type: kubernetes.io/dockerconfigjson
---
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: ${NS}
spec:
  imagePullSecret: quay-secret
EOF
}

fail_require_rhacm() {
  printf "multiclusterhub operator instance was not found. Please install RHACM! ...\n"
  exit 1
}
