# 离线环境二进制方式安装Kubernetes集群

> 本文环境 Redhat Linux 7.3，操作系统采用的最小安装方式。
>   Kubernetes的版本为 V1.10。
>   Docker版本为18.03.1-ce。
>   etcd 版本为 V3.3.8。

## 1. 准备规划

### 1.1 Node 规划
主机名|地址|角色
--|--|--
devops-101|192.168.0.101|k8s master
devops-102|192.168.0.102|k8s node

### 1.2 Network 网络

### 1.3 安装文件
Kubernetes安装需要以下二进制文件：
- etcd
- docker
- Kubernetes
    - kubelet
    - kube-proxy
    - kube-apiserver
    - kube-controller-manager
    - kube-scheduler

我们可以下载编译好的二进制文件，也可以下载源码自己编译，源码编译可以参考[这里](https://git.k8s.io/community/contributors/devel/)本文只讨论二进制的安装方式。在Kubernetes的Github [Latest](https://github.com/kubernetes/kubernetes/releases/latest) 页面，可以看到最新打包的版本。也可以到 Tag 页面中找到自己需要的版本，我下载的是 [V1.11](https://github.com/kubernetes/kubernetes/releases/tag/v1.11.0)。

> 注意这个页面有可能不是最新的版本，我查看的时候显示的版本是 V1.9.9，但是最新的版本是 V1.11，这时就需要切换到  Tag 页面查找。

服务器上需要的二进制文件并不在下载的 tar 包中，需要解压tar包，然后执行```cluster/get-kube-binaries.sh```。下载需要访问 storage.googleapis.com，因为大家都知道的原因，可能无法正常访问，需要大家科学的获取安装文件。下载完成后，解压```kubernetes-server-linux-amd64.tar.gz```。

可以看到文件列表
```sh
[root@devops-101 bin]# pwd
/root/kubernetes/server/bin
[root@devops-101 bin]# ls -lh
total 1.8G
-rwxr-xr-x. 1 root root  57M Jun 28 04:55 apiextensions-apiserver
-rwxr-xr-x. 1 root root 132M Jun 28 04:55 cloud-controller-manager
-rw-r--r--. 1 root root    8 Jun 28 04:55 cloud-controller-manager.docker_tag
-rw-r--r--. 1 root root 134M Jun 28 04:55 cloud-controller-manager.tar
-rwxr-xr-x. 1 root root 218M Jun 28 04:55 hyperkube
-rwxr-xr-x. 1 root root  56M Jun 28 04:55 kube-aggregator
-rw-r--r--. 1 root root    8 Jun 28 04:55 kube-aggregator.docker_tag
-rw-r--r--. 1 root root  57M Jun 28 04:55 kube-aggregator.tar
-rwxr-xr-x. 1 root root 177M Jun 28 04:55 kube-apiserver
-rw-r--r--. 1 root root    8 Jun 28 04:55 kube-apiserver.docker_tag
-rw-r--r--. 1 root root 179M Jun 28 04:55 kube-apiserver.tar
-rwxr-xr-x. 1 root root 147M Jun 28 04:55 kube-controller-manager
-rw-r--r--. 1 root root    8 Jun 28 04:55 kube-controller-manager.docker_tag
-rw-r--r--. 1 root root 149M Jun 28 04:55 kube-controller-manager.tar
-rwxr-xr-x. 1 root root  50M Jun 28 04:55 kube-proxy
-rw-r--r--. 1 root root    8 Jun 28 04:55 kube-proxy.docker_tag
-rw-r--r--. 1 root root  96M Jun 28 04:55 kube-proxy.tar
-rwxr-xr-x. 1 root root  54M Jun 28 04:55 kube-scheduler
-rw-r--r--. 1 root root    8 Jun 28 04:55 kube-scheduler.docker_tag
-rw-r--r--. 1 root root  55M Jun 28 04:55 kube-scheduler.tar
-rwxr-xr-x. 1 root root  55M Jun 28 04:55 kubeadm
-rwxr-xr-x. 1 root root  53M Jun 28 04:56 kubectl
-rwxr-xr-x. 1 root root 156M Jun 28 04:55 kubelet
-rwxr-xr-x. 1 root root 2.3M Jun 28 04:55 mounter
```
### 1.4 系统配置
- 配置Hosts
- 关闭防火墙
```sh
$ systemctl stop firewalld
$ systemctl disable firewalld
```
- 关闭selinux
```sh
$ setenforce 0 #临时关闭selinux
$ vim /etc/selinux/config
```
将SELINUX=enforcing改为SELINUX=disabled，wq保存退出。
- 关闭swap
```sh
$ swapoff -a
$ vim /etc/fstab #修改自动挂载配置，注释掉即可
#/dev/mapper/centos-swap swap   swap    defaults    0 0
```
- 配置路由
```sh
$ cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sysctl --system
```

## 2. 安装 Node
我们需要在Node机器上安装以下应用：
- Docker
- kubelet
- kube-proxy

### 2.1 Docker
Docker的版本需要与kubelete版本相对应，最好都使用最新的版本。Redhat 中需要使用 Static Binary 方式安装，具体可以参考我之前的[一篇文章](https://www.cnblogs.com/cocowool/p/install_docker_ce_in_redhat_73.html)。

### 2.2 拷贝 kubelet、kube-proxy
在之前解压的 kubernetes 文件夹中拷贝二进制文件
```sh
$ cp /root/kubernetes/server/bin/kubelet /usr/bin/
$ cp /root/kubernetes/server/bin/kube-proxy /usr/bin/
```

### 2.3 安装 kube-proxy 服务
```sh
$ vim /usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
 
[Service]
EnvironmentFile=/etc/kubernetes/config
EnvironmentFile=/etc/kubernetes/proxy
ExecStart=/usr/bin/kube-proxy \
            $KUBE_LOGTOSTDERR \
            $KUBE_LOG_LEVEL \
            $KUBE_MASTER \
            $KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
```
创建配置目录，并添加配置文件
```sh
$ mkdir -p /etc/kubernetes
$ vim /etc/kubernetes/proxy
KUBE_PROXY_ARGS=""
$ vim /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow_privileged=false"
KUBE_MASTER="--master=http://192.168.0.101:8080"
```
启动服务
```sh
[root@devops-102 ~]# systemctl daemon-reload
[root@devops-102 ~]# systemctl start kube-proxy.service
[root@devops-102 ~]# netstat -lntp | grep kube-proxy
tcp        0      0 127.0.0.1:10249         0.0.0.0:*               LISTEN      10522/kube-proxy    
tcp6       0      0 :::10256                :::*                    LISTEN      10522/kube-proxy  
```

### 2.4 安装 kubelete 服务
```sh
$ vim /usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service
 
[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet $KUBELET_ARGS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
$ mkdir -p /var/lib/kubelet
$ vim /etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=0.0.0.0"
KUBELET_HOSTNAME="--hostname-override=192.168.0.102"
KUBELET_API_SERVER="--api-servers=http://192.168.0.101:8080"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=reg.docker.tb/harbor/pod-infrastructure:latest"
KUBELET_ARGS="--enable-server=true --enable-debugging-handlers=true --fail-swap-on=false --kubeconfig=/var/lib/kubelet/kubeconfig"
```

创建配置文件 ```vim /var/lib/kubelet/kubeconfig```
```yaml
apiVersion: v1
kind: Config
users:
- name: kubelet
clusters:
- name: kubernetes
  cluster:
    server: http://192.168.0.101:8080
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: service-account-context
current-context: service-account-context
```

启动kubelet并进行验证。
```sh
$ swapoff -a
$ systemctl daemon-reload
$ systemctl start kubelet.service
$ netstat -tnlp | grep kubelet
tcp        0      0 127.0.0.1:10248         0.0.0.0:*               LISTEN      10630/kubelet       
tcp        0      0 127.0.0.1:37865         0.0.0.0:*               LISTEN      10630/kubelet       
tcp6       0      0 :::10250                :::*                    LISTEN      10630/kubelet       
tcp6       0      0 :::10255                :::*                    LISTEN      10630/kubelet
```

## 3. 安装 Master

### 3.1 安装etcd
本文采用二进制安装方法，首先[下载](https://github.com/coreos/etcd/releases)安装包。
之后进行解压，文件拷贝，编辑 etcd.service、etcd.conf文件夹
```sh
$ tar zxf etcd-v3.2.11-linux-amd64.tar.gz
$ cd etcd-v3.2.11-linux-amd64
$ cp etcd etcdctl /usr/bin/
$ vim /usr/lib/systemd/system/etcd.service
[Unit]
Description=etcd.service
 
[Service]
Type=notify
TimeoutStartSec=0
Restart=always
WorkingDirectory=/var/lib/etcd
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd
 
[Install]
WantedBy=multi-user.target
$ mkdir -p /var/lib/etcd && mkdir -p /etc/etcd/
$ vim /etc/etcd/etcd.conf
ETCD_NAME=ETCD Server
ETCD_DATA_DIR="/var/lib/etcd/"
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.0.101:2379"
# 启动etcd
$ systemctl daemon-reload
$ systemctl start etcd.service
```
查看etcd状态是否正常
```sh
$ etcdctl cluster-health
member 8e9e05c52164694d is healthy: got healthy result from http://192.168.0.101:2379
cluster is healthy
```
### 3.2 安装kube-apiserver
添加启动文件
```sh
[Unit]
Description=Kubernetes API Server
After=etcd.service
Wants=etcd.service
 
[Service]
EnvironmentFile=/etc/kubernetes/apiserver
ExecStart=/usr/bin/kube-apiserver  \
        $KUBE_ETCD_SERVERS \
        $KUBE_API_ADDRESS \
        $KUBE_API_PORT \
        $KUBE_SERVICE_ADDRESSES \
        $KUBE_ADMISSION_CONTROL \
        $KUBE_API_LOG \
        $KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
```

创建配置文件
```sh
$ vim /etc/kubernetes/apiserver 
KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
KUBE_API_PORT="--port=8080"
KUBELET_PORT="--kubelet-port=10250"
KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.0.101:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.0.0.0/24"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
KUBE_API_ARGS=""
```
启动服务
```sh
$ systemctl daemon-reload
$ systemctl start kube-apiserver.service
```
查看启动是否成功
```sh
$ netstat -tnlp | grep kube
tcp6       0      0 :::6443                 :::*                    LISTEN      10144/kube-apiserve 
tcp6       0      0 :::8080                 :::*                    LISTEN      10144/kube-apiserve 
```

### 3.3 安装kube-controller-manager
创建启动文件
```sh
$ vim /usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Scheduler
After=kube-apiserver.service
Requires=kube-apiserver.service
 
[Service]
EnvironmentFile=-/etc/kubernetes/controller-manager
ExecStart=/usr/bin/kube-controller-manager \
        $KUBE_MASTER \
        $KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
```
创建配置文件
```sh
$ vim /etc/kubernetes/controller-manager
KUBE_MASTER="--master=http://192.168.0.101:8080"
KUBE_CONTROLLER_MANAGER_ARGS=" "
```
启动服务
```sh
$ systemctl daemon-reload
$ systemctl start kube-controller-manager.service
```
验证服务状态
```sh
$ netstat -lntp | grep kube-controll
tcp6       0      0 :::10252                :::*                    LISTEN      10163/kube-controll 
```
### 3.4 安装kube-scheduler
创建启动文件
```sh
$ vim /usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
User=root
EnvironmentFile=/etc/kubernetes/scheduler
ExecStart=/usr/bin/kube-scheduler \
        $KUBE_MASTER \
        $KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
修改配置
```sh
$ vim /etc/kubernetes/scheduler
KUBE_MASTER="--master=http://192.168.0.101:8080"
KUBE_SCHEDULER_ARGS="--logtostderr=true --log-dir=/home/log/kubernetes --v=2"
```
启动服务
```sh
$ systemctl daemon-reload
$ systemctl start kube-scheduler.service
```
验证服务状态
```sh
$ netstat -lntp | grep kube-schedule
tcp6       0      0 :::10251                :::*                    LISTEN      10179/kube-schedule 
```
### 3.5 配置Profile

```sh
$ sed -i '$a export PATH=$PATH:/root/kubernetes/server/bin/' /etc/profile
$ source /etc/profile
```
### 3.6 安装 kubectl 并查看状态

```sh
$ cp /root/kubernetes/server/bin/kubectl /usr/bin/
$ kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
etcd-0               Healthy   {"health":"true"}   
controller-manager   Healthy   ok                  
scheduler            Healthy   ok 
```

到这里Master节点就配置完毕。

## 4. 配置flannel网络
Flannel可以使整个集群的docker容器拥有唯一的内网IP，并且多个node之间的docker0可以互相访问。[下载地址]()

## 5. 集群验证 
在101上执行命令，检查nodes，如果能看到，表明集群现在已经OK了。
```sh
$ kubectl get nodes
NAME         STATUS    ROLES     AGE       VERSION
devops-102   Ready     <none>    12s       v1.11.0
```

![](https://images2018.cnblogs.com/blog/39469/201807/39469-20180710163655709-89635310.png)

## 参考资料
1. [Creating a Custom Cluster from Scratch](https://kubernetes.io/docs/setup/scratch/)
2. [etcd](https://coreos.com/etcd/docs/latest/dev-guide/local_cluster.html)
3. [Creating a single master cluster with kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
4. [etcd download](https://github.com/coreos/etcd/releases)
5. [离线安装k8s](http://blog.51cto.com/13120271/2115310)
6. [centos7.3 kubernetes/k8s 1.10 离线安装](https://www.jianshu.com/p/9c7e1c957752)
7. [Kubernetes the hardest way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
8. [kubernetes 安装学习](https://www.cnblogs.com/fengjian2016/p/6392900.html)
9. [kubectl get nodes returns "No resources found."](https://linuxacademy.com/community/posts/show/topic/19040-kubectl-get-nodes-returns-no-resources-found)
10. [nodes with multiple network interfaces can fail to talk to services](https://github.com/kubernetes/kubeadm/issues/102) 
