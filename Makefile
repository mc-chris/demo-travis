init:
	@echo "Setup cli ..."
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.0/openshift-client-linux.tar.gz || wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.0-rc.13/openshift-client-linux.tar.gz
    tar -xf openshift-client-linux.tar.gz
    chmod 755 oc
    chmod 755 kubectl
    cp oc /home/travis/bin
    cp kubectl /home/travis/bin	

start:
	echo "Starting ..."