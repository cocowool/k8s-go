> 本文的演练环境为基于Virtualbox搭建的Kubernetes集群，具体搭建步骤可以参考[kubeadm安装kubernetes V1.11.1 集群](https://www.cnblogs.com/cocowool/p/kubeadm_install_kubernetes.html)

## 1. 基本概念
### 1.1 Pod是什么
Pod是Kubernetes中能够创建和部署的最小单元，是Kubernetes集群中的一个应用实例，总是部署在同一个节点Node上。Pod中包含了一个或多个容器，还包括了存储、网络等各个容器共享的资源。Pod支持多种容器环境，Docker则是最流行的容器环境。
- 单容器Pod，最常见的应用方式。
- 多容器Pod，对于多容器Pod，Kubernetes会保证所有的容器都在同一台物理主机或虚拟主机中运行。多容器Pod是相对高阶的使用方式，除非应用耦合特别严重，一般不推荐使用这种方式。一个Pod内的容器共享IP地址和端口范围，容器之间可以通过 localhost 互相访问。
![多容器Pod示意图](https://d33wubrfki0l68.cloudfront.net/aecab1f649bc640ebef1f05581bfcc91a48038c4/728d6/images/docs/pod.svg)

Pod并不提供保证正常运行的能力，因为可能遭受Node节点的物理故障、网络分区等等的影响，整体的高可用是Kubernetes集群通过在集群内调度Node来实现的。通常情况下我们不要直接创建Pod，一般都是通过Controller来进行管理，但是了解Pod对于我们熟悉控制器非常有好处。

### 1.2 Pod带来的好处
Pod带来的好处
- Pod做为一个可以独立运行的服务单元，简化了应用部署的难度，以更高的抽象层次为应用部署管提供了极大的方便。
- Pod做为最小的应用实例可以独立运行，因此可以方便的进行部署、水平扩展和收缩、方便进行调度管理与资源的分配。
- Pod中的容器共享相同的数据和网络地址空间，Pod之间也进行了统一的资源管理与分配。

### 1.3 常用Pod管理命令
Pod的配置信息中有几个重要部分，apiVersion、kind、metadata、spec以及status。其中```apiVersion```和```kind```是比较固定的，```status```是运行时的状态，所以最重要的就是```metadata```和```spec```两个部分。

先来看一个典型的配置文件，命名为 first-pod.yml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: first-pod
  labels:
    app: bash
    tir: backend
spec:
  containers:
  - name: bash-container
    image: docker.io/busybox
    command: ['sh', '-c', 'echo Hello Kubernetes! && sleep 3600']
```

在编写配置文件时，可以通过[API Reference](https://kubernetes.io/docs/reference/)来参考，也可以通过命令查看。
```sh
[root@devops-101 ~]# kubectl explain pod
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:
   apiVersion	<string>
     APIVersion defines the versioned schema of this representation of an
     object. Servers should convert recognized schemas to the latest internal
     value, and may reject unrecognized values. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#resources

   kind	<string>
     Kind is a string value representing the REST resource this object
     represents. Servers may infer this from the endpoint the client submits
     requests to. Cannot be updated. In CamelCase. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#types-kinds

   metadata	<Object>
     Standard object's metadata. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata

   spec	<Object>
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

   status	<Object>
     Most recently observed status of the pod. This data may not be up to date.
     Populated by the system. Read-only. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status
[root@devops-101 ~]# kubectl explain pod.spec
KIND:     Pod
VERSION:  v1

RESOURCE: spec <Object>

DESCRIPTION:
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

     PodSpec is a description of a pod.

FIELDS:
   activeDeadlineSeconds	<integer>
     Optional duration in seconds the pod may be active on the node relative to
     StartTime before the system will actively try to mark it failed and kill
     associated containers. Value must be a positive integer.

   affinity	<Object>
     If specified, the pod's scheduling constraints

   automountServiceAccountToken	<boolean>
     AutomountServiceAccountToken indicates whether a service account token
     should be automatically mounted.
```

#### 1.3.1 创建

利用kubectl命令行管理工具，我们可以直接在命令行通过配置文件创建。如果安装了Dashboard图形管理界面，还可以通过图形界面创建Pod。因为最终Pod的创建都是落在命令上的，这里只介绍如何使用kubectl管理工具来创建。

使用配置文件的方式创建Pod。
```sh
$ kubectl create -f first-pod.yml 
```

#### 1.3.2 查看配置
如果想了解一个正在运行的Pod的配置，可以通过以下命令获取。
```sh
[root@devops-101 ~]# kubectl get pod first-pod -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: 2018-08-08T01:45:16Z
  labels:
    app: bash
  name: first-pod
  namespace: default
  resourceVersion: "184988"
  selfLink: /api/v1/namespaces/default/pods/first-pod
  uid: b2d3d2b7-9aac-11e8-84f4-080027b7c4e9
spec:
  containers:
  - command:
    - sh
    - -c
    - echo Hello Kubernetes! && sleep 3600
    image: docker.io/busybox
    imagePullPolicy: Always
    name: bash-container
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-trvqv
      readOnly: true
  dnsPolicy: ClusterFirst
  nodeName: devops-102
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-trvqv
    secret:
      defaultMode: 420
      secretName: default-token-trvqv
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: 2018-08-08T01:45:16Z
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: 2018-08-08T01:45:16Z
    message: 'containers with unready status: [bash-container]'
    reason: ContainersNotReady
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: null
    message: 'containers with unready status: [bash-container]'
    reason: ContainersNotReady
    status: "False"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: 2018-08-08T01:45:16Z
    status: "True"
    type: PodScheduled
  containerStatuses:
  - image: docker.io/busybox
    imageID: ""
    lastState: {}
    name: bash-container
    ready: false
    restartCount: 0
    state:
      waiting:
        reason: ContainerCreating
  hostIP: 192.168.0.102
  phase: Pending
  qosClass: BestEffort
  startTime: 2018-08-08T01:45:16Z
```

#### 1.3.3 查看日志
可以查看命令行标准输出的日志。
```sh
[root@devops-101 ~]# kubectl logs first-pod
Hello Kubernetes!
```
如果Pod中有多个容器，查看特定容器的日志需要指定容器名称```kubectl logs pod-name -c container-name```。

#### 1.3.4 标签管理
标签是Kubernetes管理Pod的重要依据，我们可以在Pod yaml文件中 metadata 中指定，也可以通过命令行进行管理。

显示Pod的标签
```sh
[root@devops-101 ~]# kubectl get pods --show-labels
NAME        READY     STATUS    RESTARTS   AGE       LABELS
first-pod   1/1       Running   0          15m       app=bash
```
使用 second-pod.yml 我们再创建一个包含两个标签的Pod。
```sh
[root@devops-101 ~]# kubectl create -f first-pod.yml 
pod/second-pod created
[root@devops-101 ~]# kubectl get pods --show-labels
NAME         READY     STATUS              RESTARTS   AGE       LABELS
first-pod    1/1       Running             0          17m       app=bash
second-pod   0/1       ContainerCreating   0          20s       app=bash,tir=backend
```
根据标签来查询Pod。
```sh
[root@devops-101 ~]# kubectl get pods -l tir=backend --show-labels
NAME         READY     STATUS    RESTARTS   AGE       LABELS
second-pod   1/1       Running   0          1m        app=bash,tir=backend
```
增加标签
```sh
[root@devops-101 ~]# kubectl label pod first-pod tir=frontend
pod/first-pod labeled
[root@devops-101 ~]# kubectl get pods --show-labels
NAME         READY     STATUS    RESTARTS   AGE       LABELS
first-pod    1/1       Running   0          24m       app=bash,tir=frontend
second-pod   1/1       Running   0          7m        app=bash,tir=backend
```
修改标签
```sh
[root@devops-101 ~]# kubectl label pod first-pod tir=unkonwn --overwrite
pod/first-pod labeled
[root@devops-101 ~]# kubectl get pods --show-labels
NAME         READY     STATUS    RESTARTS   AGE       LABELS
first-pod    1/1       Running   0          25m       app=bash,tir=unkonwn
second-pod   1/1       Running   0          8m        app=bash,tir=backend
```

可以将标签显示为列
```sh
[root@devops-101 ~]# kubectl get pods -L app,tir
NAME         READY     STATUS    RESTARTS   AGE       APP       TIR
first-pod    1/1       Running   0          26m       bash      unkonwn
second-pod   1/1       Running   0          9m        bash      backend
```

标签是Kubernetes中非常强大的一个功能，Node节点也可以增加标签，再利用Pod的标签选择器，可以将Pod分配到不同类型的Node上。

#### 1.3.5 删除Pod
```sh
[root@devops-101 ~]# kubectl delete pods first-pod
pod "first-pod" deleted
```
也可以根据标签选择器删除。
```sh
[root@devops-101 ~]# kubectl delete pods -l tir=backend
pod "second-pod" deleted
```

### 1.4 Pod的生命周期
像单独的容器应用一样，Pod并不是持久运行的。Pod创建后，Kubernetes为其分配一个UID，并且通过Controller调度到Node中运行，然后Pod一直保持运行状态直到运行正常结束或者被删除。在Node发生故障时，Controller负责将其调度到其他的Node中。Kubernetes为Pod定义了几种状态，分别如下：
- Pending，Pod已创建，正在等待容器创建。经常是正在下载镜像，因为这一步骤最耗费时间。
- Running，Pod已经绑定到某个Node并且正在运行。或者可能正在进行意外中断后的重启。
- Succeeded，表示Pod中的容器已经正常结束并且不需要重启。
- Failed，表示Pod中的容器遇到了错误而终止。
- Unknown，因为网络或其他原因，无法获取Pod的状态。

## 2. 如何对Pod进行健康检查
Kubernetes利用[Handler](https://godoc.org/k8s.io/kubernetes/pkg/api/v1#Handler)功能，可以对容器的状况进行探测，有以下三种形式。
- ExecAction：在容器中执行特定的命令。
- TCPSocketAction：检查容器端口是否可以连接。
- HTTPGetAction：检查HTTP请求状态是否正常。

这部分内容展开来也比较多，后续计划单独写一篇来介绍。

## 3. Init Containers
Pod中可以包含一到多个Init Container，在其他容器之前开始运行。Init Container 只能是运行到完成状态，即不能够一直存在。Init Container必须依次执行。在App Container运行前，所有的Init Container必须全部正常结束。

在Pod启动过程中，Init Container在网络和存储初始化完成后开始按顺序启动。Pod重启的时候，所有的Init Container都会重新执行。

>  However, if the Pod restartPolicy is set to Always, the Init Containers use RestartPolicy OnFailure.

### 3.1 好处
- 运行一些不希望在 App Container 中运行的命令或工具
- 包含一些App Image中没有的工具或特定代码
- 应用镜像构建人员和部署人员可以独立工作而不需要依赖对方
- 拥有与App Container不同的命名空间
- 因为在App Container运行前必须运行结束，适合做一些前置条件的检查和配置

### 3.2 语法
先看一下解释
```sh
[root@devops-101 ~]# kubectl explain pod.spec.initContainers
KIND:     Pod
VERSION:  v1

RESOURCE: initContainers <[]Object>

DESCRIPTION:
     List of initialization containers belonging to the pod. Init containers are
     executed in order prior to containers being started. If any init container
     fails, the pod is considered to have failed and is handled according to its
     restartPolicy. The name for an init container or normal container must be
     unique among all containers. Init containers may not have Lifecycle
     actions, Readiness probes, or Liveness probes. The resourceRequirements of
     an init container are taken into account during scheduling by finding the
     highest request/limit for each resource type, and then using the max of of
     that value or the sum of the normal containers. Limits are applied to init
     containers in a similar fashion. Init containers cannot currently be added
     or removed. Cannot be updated. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

     A single application container that you want to run within a pod.
```
具体语法。
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: docker.io/busybox
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: docker.io/busybox
    command: ['sh', '-c', 'echo init-service && sleep 2']
  - name: init-mydb
    image: docker.io/busybox
    command: ['sh', '-c', 'echo init-mydb && sleep 2']
```
> 兼容性问题
> 1.5之前的语法都写在 annotation 中，1.6 以上的版本使用 ```.spec.initContainers``` 字段。建议还是使用 1.6 版本的语法。1.6、1.7的版本还兼容1.5以下的版本，1.8之后就不再兼容老版本了。


## 4. Pod Preset
利用这个特性，可以在Pod启动过程中向Pod中注入密码 Secrets、存储 Volumes、挂载点 Volume Mounts和环境变量。通过标签选择器来指定Pod。利用这个特性，Pod Template的维护人员就不需要为每个Pod显示的提供相关的属性。

具体的工作步骤
- 检查所有可用的ProdPresets
- 检查是否有ProdPreset的标签与即将创建的Pod相匹配
- 将PodPreset中定义的参数与Pod定义合并
- 如果参数合并出错，则丢弃ProPreset参数，继续创建Pod
- 为Pod增加注解，表示层被ProdPreset修改过，形式为 ```podpreset.admission.kubernetes.io/podpreset-<pod-preset name>: "<resource version>"```

对于 ```Env```、```EnvFrom```、```VolumeMounts``` Kubernetes修改Container Spec，对于```Volume```修改Pod Spec。

### 4.1 对个别Pod停用
在Spec中增加注解：
```yaml
podpreset.admission.kubernetes.io/exclude: "true"
```

## 5. 中断
Pod会因为各种各样的原因发生中断。

### 5.1 计划内中断
- 删除部署 Deployment或者其他控制器
- 更新部署模版导致的Pod重启
- 直接删除Pod
- 集群的缩容
- 手工移除

### 5.2 计划外中断
- 硬件故障、物理节点宕机
- 集群管理员误删VM
- 云供应商故障导致的主机不可用
- Kernel panic
- 集群网络分区导致节点消失
- 资源耗尽导致的节点剔除


### 5.3 PDB Disruption Budgets
> Kubernetes offers features to help run highly available applications at the same time as frequent voluntary disruptions. We call this set of features Disruption Budgets.

Kubernetes允许我们创建一个PDB对象，来确保一个RS中运行的Pod不会在一个预算（个数）之下。
Eviction API。

PDB是用来解决集群管理和应用管理职责分离的情况，如果你的单位不存在这种情况，就可以不使用PDB。

## 参考资料
1. [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)
2. [Kubernetes in action](#)
