#!/bin/bash
images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
for imageName in ${images[@]} ; do
  docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
  docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName k8s.gcr.io/$imageName
  docker rmi registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
done
# 个人新加的一句，V 1.11.0 必加
docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1

docker pull docker.io/mirrorgooglecontainers/k8s-dns-sidecar-amd64:1.14.9
docker tag docker.io/mirrorgooglecontainers/k8s-dns-sidecar-amd64:1.14.9 k8s.gcr.io/k8s-dns-sidecar-amd64:1.14.9
docker rmi docker.io/mirrorgooglecontainers/k8s-dns-sidecar-amd64:1.14.9
docker pull docker.io/mirrorgooglecontainers/k8s-dns-kube-dns-amd64:1.14.9 
docker tag docker.io/mirrorgooglecontainers/k8s-dns-kube-dns-amd64:1.14.9 k8s.gcr.io/k8s-dns-kube-dns-amd64:1.14.9
docker rmi docker.io/mirrorgooglecontainers/k8s-dns-kube-dns-amd64:1.14.9 
docker pull docker.io/mirrorgooglecontainers/k8s-dns-dnsmasq-nanny-amd64:1.14.9
docker tag docker.io/mirrorgooglecontainers/k8s-dns-dnsmasq-nanny-amd64:1.14.9 k8s.gcr.io/k8s-dns-dnsmasq-nanny-amd64:1.14.9
docker rmi docker.io/mirrorgooglecontainers/k8s-dns-dnsmasq-nanny-amd64:1.14.9

docker pull registry.cn-shenzhen.aliyuncs.com/cp_m/flannel:v0.10.0-amd64
docker tag registry.cn-shenzhen.aliyuncs.com/cp_m/flannel:v0.10.0-amd64 quay.io/coreos/flannel:v0.10.0-amd64
