# 目录

这里整理了我学习Kubernetes的资料，供大家参考交流
- [Kubernetes的命名空间]()

# kubeadm安装kubernetes V1.11.1 集群

> 之前测试了[离线环境下使用二进制方法安装配置Kubernetes集群](https://www.cnblogs.com/cocowool/p/install_k8s_offline.html)的方法，安装的过程中听说 kubeadm 安装配置集群更加方便，因此试着折腾了一下。安装过程中，也有一些坑，相对来说操作上要比二进制方便一点，毕竟不用手工创建那么多的配置文件，但是对于了解Kubernetes的运作方式，可能不如二进制方式好。同时，因为kubeadm方式，很多集群依赖的组件都是以容器方式运行在Master节点上，感觉对于虚拟机资源的消耗要比二进制方式厉害。

## 0. kubeadm 介绍与准备工作
> kubeadm is designed to be a simple way for new users to start trying Kubernetes out, possibly for the first time, a way for existing users to test their application on and stitch together a cluster easily, and also to be a building block in other ecosystem and/or installer tool with a larger scope.
kubeadm是一个python写的项目，代码在[这里](https://github.com/kubernetes/kubeadm)，用来帮助快速部署Kubernetes集群环境，但是目前仅仅是作为测试环境使用，如果你想在生产环境使用，可是要三思。

本文所用的环境：
- 虚拟机软件：VirtualBox
- 操作系统：Centos 7.3 minimal 安装
- 网卡：两块网卡，一块 Host-Only方式，一块 Nat 方式。
- 网络规划：
    - Master:192.168.0.101
    - Node:192.168.0.102-104

### 0.1 关掉 selinux
```sh
$ setenforce  0 
$ sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
```

### 0.2 关掉防火墙
```sh
$ systemctl stop firewalld
$ systemctl disable firewalld
```

### 0.3 关闭 swap
```sh
$ swapoff -a 
$ sed -i 's/.*swap.*/#&/' /etc/fstab
```

### 0.4 配置转发参数
```sh
$ cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sysctl --system
```

### 0.5 设置国内 yum 源
```sh
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

### 0.6 安装一些必备的工具
```sh
$ yum install -y epel-release 
$ yum install -y net-tools wget vim  ntpdate
```

## 1. 安装 kubeadm 必须的软件，在所有节点上运行
### 1.1 安装Docker
```sh
$ yum install -y docker
$ systemctl enable docker && systemctl start docker
$ #设置系统服务，如果不设置后面 kubeadm init 的时候会有 warning
$ systemctl enable docker.service
```
如果想要用二进制方法安装最新版本的Docker，可以参考我之前的文章[在Redhat 7.3中采用离线方式安装Docker](https://www.cnblogs.com/cocowool/p/install_docker_ce_in_redhat_73.html)

### 1.2 安装kubeadm、kubectl、kubelet
```sh
$ yum install -y kubelet kubeadm kubectl kubernetes-cni
$ systemctl enable kubelet && systemctl start kubelet
```
这一步之后kubelet还不能正常运行，还处于下面的状态。
> The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

## 2. 安装Master节点
因为国内没办法访问Google的镜像源，变通的方法是从其他镜像源下载后，修改tag。执行下面这个Shell脚本即可。
```sh
#!/bin/bash
images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
for imageName in ${images[@]} ; do
  docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
  docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName k8s.gcr.io/$imageName
  #docker rmi registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
done
docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1
```
接下来执行Master节点的初始化，因为我的虚拟机是双网卡，需要指定apiserver的监听地址。
```sh
[root@devops-101 ~]# kubeadm init --kubernetes-version=v1.11.0 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.0.101
[init] using Kubernetes version: v1.11.0
[preflight] running pre-flight checks
I0724 08:36:35.636931    3409 kernel_validator.go:81] Validating kernel version
I0724 08:36:35.637052    3409 kernel_validator.go:96] Validating kernel config
	[WARNING Hostname]: hostname "devops-101" could not be reached
	[WARNING Hostname]: hostname "devops-101" lookup devops-101 on 172.20.10.1:53: no such host
	[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [devops-101 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.0.101]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated sa key and public key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [devops-101 localhost] and IPs [127.0.0.1 ::1]
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [devops-101 localhost] and IPs [192.168.0.101 127.0.0.1 ::1]
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[controlplane] wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests" 
[init] this might take a minute or longer if the control plane images have to be pulled
[apiclient] All control plane components are healthy after 46.002877 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.11" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node devops-101 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node devops-101 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "devops-101" as an annotation
[bootstraptoken] using token: wkj0bo.pzibll6rd9gyi5z8
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.0.101:6443 --token wkj0bo.pzibll6rd9gyi5z8 --discovery-token-ca-cert-hash sha256:51985223a369a1f8c226f3ccdcf97f4ad5ff201a7c8c708e1636eea0739c0f05
```
看到以上信息表示Master节点已经初始化成功了。如果需要用普通用户管理集群，可以按照提示进行操作，如果是使用root用户管理，执行下面的命令。

```sh
[root@devops-101 ~]# export KUBECONFIG=/etc/kubernetes/admin.conf 
[root@devops-101 ~]# kubectl get nodes
NAME         STATUS     ROLES     AGE       VERSION
devops-101   NotReady   master    7m        v1.11.1
[root@devops-101 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY     STATUS    RESTARTS   AGE
kube-system   coredns-78fcdf6894-8sd6g             0/1       Pending   0          7m
kube-system   coredns-78fcdf6894-lgvd9             0/1       Pending   0          7m
kube-system   etcd-devops-101                      1/1       Running   0          6m
kube-system   kube-apiserver-devops-101            1/1       Running   0          6m
kube-system   kube-controller-manager-devops-101   1/1       Running   0          6m
kube-system   kube-proxy-bhmj8                     1/1       Running   0          7m
kube-system   kube-scheduler-devops-101            1/1       Running   0          6m
```
可以看到节点还没有Ready，dns的两个pod也没不正常，还需要安装网络配置。

## 3. Master节点的网络配置
这里我选用了 Flannel 的方案。
> kubeadm only supports Container Network Interface (CNI) based networks (and does not support kubenet).

修改系统设置，创建 flannel 网络。
```sh
[root@devops-101 ~]# sysctl net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-iptables = 1
[root@devops-101 ~]# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.extensions/kube-flannel-ds created
```
flannel 默认会使用主机的第一张网卡，如果你有多张网卡，需要通过配置单独指定。修改 kube-flannel.yml 中的以下部分
```yaml
containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.10.0-amd64
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=enp0s3            #指定内网网卡
```
执行成功后，Master并不能马上变成Ready状态，稍等几分钟，就可以看到所有状态都正常了。

```sh
[root@devops-101 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY     STATUS    RESTARTS   AGE
kube-system   coredns-78fcdf6894-8sd6g             1/1       Running   0          14m
kube-system   coredns-78fcdf6894-lgvd9             1/1       Running   0          14m
kube-system   etcd-devops-101                      1/1       Running   0          13m
kube-system   kube-apiserver-devops-101            1/1       Running   0          13m
kube-system   kube-controller-manager-devops-101   1/1       Running   0          13m
kube-system   kube-flannel-ds-6zljr                1/1       Running   0          48s
kube-system   kube-proxy-bhmj8                     1/1       Running   0          14m
kube-system   kube-scheduler-devops-101            1/1       Running   0          13m
[root@devops-101 ~]# kubectl get nodes
NAME         STATUS    ROLES     AGE       VERSION
devops-101   Ready     master    14m       v1.11.1
```
## 4. 加入节点
Node节点的加入集群前，首先需要按照本文的第0节和第1节做好准备工作，然后下载镜像。
```sh
$ docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/kube-proxy-amd64:v1.11.0
$ docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1
$ docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1 k8s.gcr.io/pause-amd64:3.1
$ docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/kube-proxy-amd64:v1.11.0 k8s.gcr.io/kube-proxy-amd64:v1.11.0
$ docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1 k8s.gcr.io/pause:3.1
```
最后再根据Master节点的提示加入集群。
```sh
$ kubeadm join 192.168.0.101:6443 --token wkj0bo.pzibll6rd9gyi5z8 --discovery-token-ca-cert-hash sha256:51985223a369a1f8c226f3ccdcf97f4ad5ff201a7c8c708e1636eea0739c0f05
```
节点的启动也需要一点时间，稍后再到Master上查看状态。
```sh
[root@devops-101 ~]# kubectl get nodes
NAME         STATUS    ROLES     AGE       VERSION
devops-101   Ready     master    1h        v1.11.1
devops-102   Ready     <none>    11m       v1.11.1
```

我把安装中需要用到的一些命令整理成了几个脚本，放在我的[Github](https://github.com/cocowool/k8s-go)上，大家可以下载使用。

![](https://images2018.cnblogs.com/blog/39469/201807/39469-20180710163655709-89635310.png)

## X. 坑

### pause:3.1
安装的过程中，发现kubeadmin会找 pause:3.1 的镜像，所以需要重新 tag 。
```sh
$ docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/pause-amd64:3.1 k8s.gcr.io/pause:3.1
```

### 两台服务器时间不同步。
报错信息
```sh
[discovery] Failed to request cluster info, will try again: [Get https://192.168.0.101:6443/api/v1/namespaces/kube-public/configmaps/cluster-info: x509: certificate has expired or is not yet valid]
```
解决方法，设定一个时间服务器同步两台服务器的时间。
```sh
$ ntpdate ntp1.aliyun.com
```

## 参考资料
1. [centos7.3 kubernetes/k8s 1.10 离线安装](https://www.jianshu.com/p/9c7e1c957752)
2. [Kubeadm安装Kubernetes环境](https://www.cnblogs.com/ericnie/p/7749588.html)
3. [Steps to install kubernetes](https://www.assistanz.com/steps-to-install-kubernetes-cluster-manually-using-centos-7/)
4. [kubeadm reference guide](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)
5. [kubeadm安装Kubernetes V1.10集群详细文档](https://www.kubernetes.org.cn/3808.html)
6. [kubeadm reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file)
7. [kubeadm搭建kubernetes1.7.5集群](https://blog.csdn.net/zhongyuemengxiang/article/details/79121932)
8. [安装部署 Kubernetes 集群](https://www.cnblogs.com/Leo_wl/p/8511902.html)
9. [linux 命令 ---- 同步当前服务器时间](https://www.cnblogs.com/chenzeyong/p/5951959.html)
10. [CentOS 7.4 安装 K8S v1.11.0 集群所遇到的问题](https://www.cnblogs.com/myzony/p/9298783.html#1.准备工作)
11. [使用kubeadm部署kubernetes](https://blog.csdn.net/andriy_dangli/article/details/79269348)
