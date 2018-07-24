#!/bin/bash
#关闭Selinu
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭Swapp
swapoff -a 
sed -i 's/.*swap.*/#&/' /etc/fstab

#修改转发配置
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

#添加yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum -y epel-release 
yum install -y net-tools wget vim  ntpdate
yum install -y docker
systemctl enable docker && systemctl start docker
systemctl enable docker.service
yum install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet && systemctl start kubelet
