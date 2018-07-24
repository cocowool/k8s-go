#!/bin/bash
docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/kube-proxy-amd64:v1.11.0
docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1 k8s.gcr.io/pause-amd64:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/kube-proxy-amd64:v1.11.0 k8s.gcr.io/kube-proxy-amd64:v1.11.0
docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1 k8s.gcr.io/pause:3.1
