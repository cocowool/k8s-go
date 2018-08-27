# Kubernetes 的命名空间

> 本文环境为Kubernetes V1.11，操作系统版本为 CentOs 7.3，Kubernetes集群安装可以参考 [kubeadm安装kubernetes V1.11.1 集群](https://www.cnblogs.com/cocowool/p/kubeadm_install_kubernetes.html)

## 1. 什么是Namespaces
Kubernetes中提供了命名空间，但是如果你的团队规模比较小并且集群规模也不大，完全可以不用Namespaces而使用```labels```来区分不同的资源，随着项目增多、集群规模扩大、人员的增加，你才需要使用Namespaces，通过namespace你可以创建多个虚拟的集群。

Namespaces提供了一种在不同用户间分隔集群资源的方法，未来Kubernetes可能会提供基于命名空间的权限控制。

## 2. Namespaces 的常用操作
### 2.1 查看命名空间
```sh
[root@devops-101 ~]# kubectl get namespaces
NAME          STATUS    AGE
default       Active    7d
kube-public   Active    7d
kube-system   Active    7d
```

Kubernetes默认有三个命名空间
- default:默认的命名空间
- kube-system:由Kubernetes系统对象组成的命名空间
- kube-public:该空间由系统自动创建并且对所有用户可读性，做为集群公用资源的保留命名空间

### 2.2 创建命名空间
```sh
[root@devops-101 ~]# kubectl create namespace test-cluster
namespace/test-cluster created
[root@devops-101 ~]# kubectl get namespaces
NAME           STATUS    AGE
default        Active    7d
kube-public    Active    7d
kube-system    Active    7d
test-cluster   Active    3s
```

### 2.2 查询命名空间中的资源
```sh
[root@devops-101 ~]# kubectl get all --namespace=test-cluster
No resources found.
[root@devops-101 ~]# kubectl get all -n test-clutser
No resources found.
[root@devops-101 ~]# kubectl get nodes
NAME         STATUS     ROLES     AGE       VERSION
devops-101   Ready      master    7d        v1.11.2
devops-102   Ready      <none>    7d        v1.11.2
devops-103   NotReady   <none>    4d        v1.11.2
```

### 2.3 修改默认的namespace配置
```sh
# kubectl config view //先查看是否设置了current-context
# kubectl config set-context default --namespace=bs-test //设置default配置的namespace参数
# kubectl config set current-context default //设置当前环境变量为 default
```
通过这段代码设置默认的命名空间后，就不用每次在输入命令的时候带上```--namespace```参数了。

## 3. 注意
不是所有的对象都在命名空间中，例如 nodes、persistentVolumes 就没有命名空间，所有用户都是可见的。

可以通过下面的命令查看命名空间中的资源。
```sh
[root@devops-101 ~]# kubectl api-resources --namespaced=true
# 查看不在命名空间中的资源
[root@devops-101 ~]# kubectl api-resources --namespaced=false
```

![](https://images2018.cnblogs.com/blog/39469/201807/39469-20180710163655709-89635310.png)

## 参考资料：
1. [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
2. [Kubernetes中文手册](http://docs.kubernetes.org.cn/749.html)
