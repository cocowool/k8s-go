#!/bin/bash
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 

systemctl stop firewalld
   54  systemctl disable firewalld
   55  swapoff -a 
   56  sed -i 's/.*swap.*/#&/' /etc/fstab
   57  cat <<EOF >  /etc/sysctl.d/k8s.conf
> net.bridge.bridge-nf-call-ip6tables = 1
> net.bridge.bridge-nf-call-iptables = 1
> EOF



   58  cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

   59  sysctl --system
   60  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

   61  yum -y epel-release 
   62  yum install -y net-tools wget vim  ntpdate
   63  yum install -y docker
   64  systemctl enable docker && systemctl start docker
   65  systemctl enable docker.service
   66  yum install -y kubelet kubeadm kubectl kubernetes-cni
   67  systemctl enable kubelet && systemctl start kubelet
