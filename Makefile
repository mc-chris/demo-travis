init:
	@echo "Setup cli ...\n"
	wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.4/openshift-client-linux.tar.gz
	tar -xf openshift-client-linux.tar.gz
	chmod 755 oc
	chmod 755 kubectl
	@if [ -d /home/travis/bin ]; then \
	cp oc /home/travis/bin; \
	cp kubectl /home/travis/bin; \
	fi
	rm -rf openshift-client-linux.tar.gz
	@echo "\n"

start:
	@echo "Starting ..."
	@./start.sh
