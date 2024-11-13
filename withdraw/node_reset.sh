#!/bin/bash

kubeadm reset --force
test -f /etc/default/kubelet && rm /etc/default/kubelet
iptables -F && iptables -t nat -F && iptables -t mangle -F && \
iptables -X && iptables -t nat -X && iptables -t mangle -X
rm -r /etc/cni/net.d/
systemctl restart containerd
