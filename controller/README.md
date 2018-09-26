## Kubernetes Controller 介绍

## 0. 概述
Kubernetes提供了很多Controller资源来管理、调度Pod，包括Replication Controller、ReplicaSet、Deployments、StatefulSet、DaemonSet等等。本文介绍这些控制器的功能和用法。控制器是Kubernetes中的一种资源，用来方便管理Pod。可以把控制器想象成进程管理器，负责维护进程的状态。进程掉了负责拉起，需要更多进程了负责增加进程，可以监控进程根据进程消耗资源的情况动态扩缩容。只是在Kubernetes中，控制器管理的是Pods。Controller通过API Server提供的接口实时监控整个集群的每个资源对象的当前状态，当发生各种故障导致系统状态发生变化时，会尝试将系统状态修复到“期望状态”。


### Spec
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
spec:
  replicas: #默认为1
  selector:
    
  template:
    metadata:
      labels:
    spec:
      containers:
      - name: image-name
        image:
        
```

### 必须字段
1.9版本之后，应当使用 ```apps/v1```。

### Pod Template

### Pod Selector
并不区分Pod的创建人或进程，好处是容易被其他的管理工具替换。

> Also you should not normally create any pods whose labels match this selector, either directly, with another ReplicaSet, or with another controller such as a Deployment. If you do so, the ReplicaSet thinks that it created the other pods. Kubernetes does not stop you from doing this.

## 1. ReplicationController
Replication Controller 通常缩写为 rc、rcs。RC同RS一样，保持Pod数量始终维持在期望值。RC创建的Pod，遇到失败后会自动重启。RC的编排文件必须的字段包括apiVersion、kind、metadata、.spec.repicas、.spec.template。其中```.spec.template.spec.restartPolicy``` 只能是 ```Always```，默认为空。看一下RC的编排文件。

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: docker.io/nginx
        ports:
        - containerPort: 80
```

### 1.1 常用管理操作
- 删除RC和相关的Pod，使用```kubectl delete```命令删除RC，会同步删除RC创建的Pods
- 仅删除RC，使用```kubectl delete --cascade=false```仅删除RC而不删除相关的Pods
- 隔离Pod，通过修改标签的方式隔离Pod

### 1.2 常用场景
- Rescheduling，RC控制器会确保集群中始终存在你设定数量的Pod在运行
- Scaling，通过修改replicas字段，可以方便的扩容
- Rolling updates，可以使用命令行工具```kubectl rolling-update```实现滚动升级
- Multriple release tracks，配合label和service，可以实现金丝雀发布
- 与Services配合

> RC没有探测功能，也没有自动扩缩容功能。也不会检查

## 2. ReplicaSet
RS是RC的下一代，只有对于标签选择的支持上有所不同，RS支持集合方式的选择，RC仅支持相等方式的选择。ReplicasSet确保集群在任何时间都运行指定数量的Pod副本，看一下RS的编排文件。

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx
  labels:
    app: nginx
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
    matchExpressions:
      - {key:tier, operator: In, values: [frontend]}
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
      spec:
        containers:
        - name: nginx
          image: docker.io/nginx
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            ports:
            - containerPort: 80
```
编排文件必须的几个字段包括：apiVersion、kind、metadata、spec以及spec.replicas、spec.template、spec.selector。

> 尽管ReplicaSet可以单独使用，但是如今推荐使用Deployments做为Pod编排的（新建、删除、更新）的主要方式。Deploymnets是更高一级的抽象，提供了RS的管理功能，除非你要使用自定义的更新编排或者不希望所有Pod进行更新，否则基本上没有用到RS的机会。



### 2.1 常用管理操作
- 删除RS和相关Pods，```kubectl delete <rs-name>```
- 仅删除RS，```kubectl delete <rs-name> --cascade=false```
- Pod 隔离，通过修改Pod的label，可以将Pod隔离从而进行测试、数据恢复等操作。
－ HPA 自动扩容，ReplicaSet可以作为HPA的目标
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-scaler
spec:
  scaleTargetRef:
    kind: ReplicaSet
    name: nginx
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```

## 3. Deployments
Deployment实际上是对RS和Pod的管理，它总先是创建RS，由RS创建Pods。由Deployment创建的RS的命名规则为```[DEPLOYMENT-NAME]-[POD-TEMPLATE-HASH-VALUE]```，建议不要手工维护Deployment创建的RS。Deployment的更新仅在Pod的template发生更新的情况下。

下面介绍几个Deployment使用的典型场景。
### 3.1 创建部署 Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment        //部署名称
  labels:
    app: nginx
spec:
  replicas: 3                   //副本数量
  selector:                     //Pod选择规则
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:                   //Pods标签
        app: nginx
    spec:
      containers:
      - name: nginx
        image: docker.io/nginx:1.7.9
        ports:
        - contaienrPort: 80
```

```sh
kubectl apply -f dp.yaml
kubectl get deployment nginx-deployment
kubectl rollout status deployment nginx-deployment
kubectl get pods --show-labels
```

### 3.2 更新部署 Deployment
如果需要对已经创建的Deployment进行更新有两种方法，一种是修改编排文件并应用更新，一种是直接通过命令的方式更新部署的参数，分别介绍如下。

**命令方式更新**
更新镜像文件的版本
```sh
kubectl set image depolyment/nginx-deployment nginx=docker.io/nginx:1.9.1
```

**更新编排文件的方式**
首先修改编排文件，然后执行
```sh
kubectl apply -f dp.yaml
```

> 如果一个Deployment已经创建完成，更新Deployment会创建新的RS并逐渐的替换旧的RS（按一定的速率创建新的Pod，确保新的Pod运行正常后，删掉旧的Pod）。因此如果查看Pods，可能会发现一段时间Pods的总量会超过replicas设定的数量。如果一个Deployment正在创建还没有完成，此时更新Deployment会导致刚创建的Pods马上被杀掉，并开始创建新的Pods。

### 3.3 回滚更新
有时部署的版本存在问题，我们需要回滚到之前的版本，Deployment也提供了这种功能。默认情况下，Deployment的更新保存在系统中，我们能够据此实现版本的回滚。

> 只有更新.spec.template的内容才会触发版本记录，单纯的扩容不会记录历史。因此回滚也不会造成Pods数量的变化。

```sh
kubectl apply -f dp.yaml
kubectl set image deployment/nginx-deployment nginx=docker.io/nginx:1.91
kubectl rollout status deployments nginx-deployment
kubectl get rs
kubectl get pods
# kubectl rollout history deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment --revision=2
kubectl rollout undo deployment/nginx-deployment
kubectl rollout undown deployment/nginx-deployment --to-revision=2
kubectl get deployment
```
> 默认记录10个版本，可以通过```.spec.revisionHistoryLimit```修改。

### 3.4 扩容
```sh
# kubectl scale deployment nginx-deployment --replicas=5
```

如果集群打开了自动扩容功能，还可以设置自动扩容的条件。
```sh
# kubectl autoscale deployment nginx-deployment --min=10 --max=15 --cpu-percent=80
```

### 3.5 暂停Deployment
创建部署之后，我们可以暂停和重启部署过程，并在此期间执行一些操作。
```sh
$ kubectl rollout pause deployment/nginx-deployment
$
$ kubectl rollout resume deployment/nginx-deployment
```

### 3.6 Deployment的状态
Deployment包含几种可能的状态。
- Progressing
    - 创建了新的ReplicaSet
    - 正在对新的ReplicaSet进行Scaling up
    - 正在对旧的ReplicaSet进行Scaling down
    - 新的Pods准备就绪
- Complete
    - 所有的副本都已更新为最新状态
    - 所有的副本都已可用
    - 没有旧的副本正在运行
- Failed
    - Quota不足
    - Readiness探测失败
    - 镜像拉取失败
    - 权限不足
    - 应用运行错误

### 3.7 一些参数
- Strategy ```.spec.strategy```，这个有两个选项，分别是Recreate和RollingUpdate，默认为第二种。第一种的策略为先杀死旧Pods再创建新Pods，第二种为一边创建新Pods，一边杀掉旧Pods
- Max Unavailable ```.spec.strategy.rollingUpdate.maxUnavailable```，更新过程中允许不可用Pods的最大比率，默认为25%
- Max Surge ```.spec.strategy.rollingUpdate.maxSurge```，更新过程中允许超过replicas的最大Pods数量，默认为25%
- Progress Deadline Seconds ```.spec.progressDeadlineSeconds``` ，可选参数，设置系统报告进展的时间
- Min Ready Seconds ```.spec.minReadySeconds```，可选参数，设置新建Pod能正常运行的最小时间间隔
- Revision History Limit ```.spec.revisionHistoryLimit``` 可选参数，设置历史记录数量

## 4. StatefulSets

SteatefulSets我专门有一篇文件介绍，大家可以参考[这里](https://www.cnblogs.com/cocowool/p/kubernetes_statefulset.html)。

## 5. DaemonSet
DaemonSet确保所有的Node上都运行了一份Pod的副本，只要Node加入到集群中，Pod就会在Node上创建。典型的应用场景包括：运行一个存储集群（glusterd,ceph）、运行一个日志收集集群（fluentd,logstash）、运行监控程序（Prometheus Node Exporter,collectd,Datadog等）。默认情况下DaemonSet由DaemonSet控制器调度，如果设置了```nodeAffinity```参数，则会有默认的scheduler调度。

典型的编排文件如下。
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-es
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-es
    template:
      metadata:
        labels:
          name: fluentd-es
      spec:
        tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
        containers:
        - name: fluentd-es
          image: docker.io/fluentd:1.20
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 200Mi
          volumeMounts:
          - name: varlog
            mountPath: /var/log
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
            readOnly: true
          terminationGracePeriodSeconds: 30
          volumes:
          - name: varlog
            hostPath:
              path: /var/log
          - name: varlibdockercontainers
            hostPath:
              path: /var/lib/docker/contaienrs
```

## 6. Grabage Collection
Kubernetes中一些对象间有从属关系，例如一个RS会拥有一组Pod。Kubernetes中的GC用来删除那些曾经有过属主，但是后来没有属主的对象。Kubernetes中拥有属主的对象有一个```metadata.ownerReferences```属性指向属主。在Kubernetes的1.8版本之后，系统会自动为ReplicationController、ReplicaSet、StatefulSet、DaemonSet、Deployment、Job和CronJob创建的对象设置ownerReference。

之前各种控制器中我们提到过级联删除，就是通过这个属性来实现的。级联删除有两种形式 Foreground 以及 Background ，Foreground模式中，选择级联删除后GC会自动将所有```ownerReference.blockOwnerDeletion=true```的对象删除，最后再删除owner对象。Background模式中，owner对象会被立即删除，然后GC在后台删除其他依赖对象。如果我们在删除RS的时候，选择不进行级联删除，那么这个RS创建的Pods就变成了没有属主的孤儿。

## 7. Jobs
Job通过创建一个或多个Pod来运行特定的任务，当正常完成任务的Pod数量达到设定标准时，Job就会结束。删除Job会将Job创建的所有Pods删除。

典型的编排文件
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  backoffLimit: 4
  activeDeadlineSeconds: 100
  template:
    spec:
      containers:
      - name: pi
        image: docker.io/perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpid(2000)"]
      restartPolicy: Never
```

主要有三种类型的Job
- 非并行的Job，通常只启动一个Pod执行任务
- 带有固定完成数量的并行Job，需要将```.spec.completions```设置为非零值
- 与队列结合的并行Job，不需要设置```.spec.completions```，设置```.spec.parallelism```

> Note that even if you specify .spec.parallelism = 1 and .spec.completions = 1 and .spec.template.spec.restartPolicy = "Never", the same program may sometimes be started twice.
> 感觉有坑啊。

Kubernetes提供的并行Job并不适合科学计算或者执行相关的任务，更适合执行邮件发送、渲染、文件转义等等单独的任务。

## 8. CronJob
Cron Job是根据时间来自动创建Job对象。类似于Crontab，周期性的执行一个任务。每次执行期间，会创建一个Job对象。也可能会创建两个或者不创建Job，这个情况可能会发生，因此应该保证Job是幂等的。

> For every CronJob, the CronJob controller checks how many schedules it missed in the duration from its last scheduled time until now. If there are more than 100 missed schedules, then it does not start the job and logs the error 如果错过太多，就不要追了

典型的编排文件
```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: docker.io/busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

所有的编排文件都上传到了我的[Github](https://github.com/cocowool/k8s-go/tree/master/controller)上，大家可以自行[下载](https://github.com/cocowool/k8s-go/tree/master/controller)。

![](https://images2018.cnblogs.com/blog/39469/201807/39469-20180710163655709-89635310.png)

## 参考资料
1. [Kubernetes ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
2. [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)
