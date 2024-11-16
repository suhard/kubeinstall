#!/bin/bash

# Setting all parameters
NODE_TYPE=$1
INTERNAL=!$2
MASTER_IP=$3

## Parameters for master node installation
if [ "$NODE_TYPE" == "master" ]
then
	if [ "$#" -lt 4 ]; then
		POD_NETWORK_ARG=""
	else
		POD_NETWORK_ARG="--pod-network-cidr=$4"
	fi
# Parameters for worker node installation
elif [ "$NODE_TYPE" == "worker" ]
then
	TOKEN=$4
	HASH=$5
fi

echo "*** Avoid annoying kernel upgrades ***"
# Disable Auto Upgrade :)
apt purge -y needrestart
# Hold Kernel update from apt upgrade
apt-mark hold $(uname -r) linux-generic linux-headers-generic linux-image-generic

echo "*** Install needed packages ***"
apt update
apt install -y --no-install-recommends curl ebtables bash-completion

# https://www.howtoforge.com/how-to-install-containerd-container-runtime-on-ubuntu-22-04/
echo "*** Install containerd and runC ***"
apt install -y --no-install-recommends apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y --no-install-recommends containerd.io
systemctl start containerd
systemctl enable containerd
# If kubeadm does not find the runtime
mv etc/containerd/config.toml etc/containerd/config.toml.orig
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd

echo "*** Misc hosuekeeping before proceeding to the install ****"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
modprobe br_netfilter
sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

echo "*** Install kube* packages ***"
# We use the new k8s.io repositories
# https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/
# pinned to rel. v1.30

KUBERNETES_INSTALLED=$(which kubeadm)
if [ "$KUBERNETES_INSTALLED" = "" ]
then
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
	apt update
	apt install -y kubeadm kubelet kubectl kubernetes-cni
fi

# Initialize Kubernetes as Master node
if [ "$NODE_TYPE" == "master" ]
then
	## Set master node for internal network
	if [ $INTERNAL ]; then
		touch /etc/default/kubelet
		echo "KUBELET_EXTRA_ARGS=--node-ip=$MASTER_IP" > /etc/default/kubelet
	fi
	## Init Kubernetes
	kubeadm init --ignore-preflight-errors=SystemVerification \
			--apiserver-advertise-address=$MASTER_IP $POD_NETWORK_ARG \
                  	--apiserver-cert-extra-sans="$MASTER_IP" \
		  	--apiserver-bind-port 8443 \
                        --kubernetes-version="stable-1"
   	## Configuring kubectl access 
	mkdir -p $HOME/.kube
	sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/*
	export KUBECONFIG=$HOME/.kube/config
	echo "export KUBECONFIG=$HOME/.kube/config" | tee -a ~/.bashrc

	echo "[master:$(hostname -s)] Node is up and running on $MASTER_IP"

	echo "*** Waiting 120 secs for the API server to initialize...  ***"
	sleep 120

	echo "*** Install kubectl tab completion ***"
	mkdir -p /etc/bash_completion.d
	bash -c 'source /etc/bash_completion'
	bash -c 'echo "source <(kubectl completion bash)" > /etc/bash_completion.d/kubectl'

# Initialize Kubernetes as Worker node
elif [ "$NODE_TYPE" = "worker" ]
then
	## Set worker node for internal network
	if [ $INTERNAL ]; then
		IP=$(grep -oP \
				'(?<=src )[^ ]*' \
				<(grep  -f <(ls -l /sys/class/net | grep pci | awk '{print $9}') \
					<(ip ro sh) |
				grep -v $(ip ro sh | grep default | awk '{print $5}')) |
			head -1)
		touch /etc/default/kubelet
		echo "KUBELET_EXTRA_ARGS=--node-ip=$IP" > /etc/default/kubelet
	else
		IP=$(grep -oP '(?<=src )[^ ]*' <(ip ro sh | grep default))
	fi
	## Join to Kubernetes Master node
	kubeadm join $MASTER_IP --token $TOKEN --discovery-token-ca-cert-hash $HASH \
		--ignore-preflight-errors=SystemVerification

	echo "[worker:$(hostname -s)] Client ($IP) joined to Master ($MASTER_IP)"
else
	echo "Invalid argument"
fi

