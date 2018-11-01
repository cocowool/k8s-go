# Kubernetes中的Configmap和Secret

> 本文的试验环境为CentOS 7.3，Kubernetes集群为1.11.2，安装步骤参见[kubeadm安装kubernetes V1.11.1 集群](https://www.cnblogs.com/cocowool/p/kubeadm_install_kubernetes.html)

> 应用场景：镜像往往是一个应用的基础，还有很多需要自定义的参数或配置，例如资源的消耗、日志的位置级别等等，这些配置可能会有很多，因此不能放入镜像中，Kubernetes中提供了Configmap来实现向容器中提供配置文件或环境变量来实现不同配置，从而实现了镜像配置与镜像本身解耦，使容器应用做到不依赖于环境配置。

## 向容器传递参数

| Docker | Kubernetes | 描述 |
| --- | --- | --- |
| ENTRYPOINT | command | 容器中的可执行文件 |
| CMD | args | 需要传递给可执行文件的参数 |

如果需要向容器传递参数，可以在Yaml文件中通过command和args或者环境变量的方式实现。
```yaml
kind: Pod
spec:
  containers:
  - image: docker.io/nginx
    command: ["/bin/command"]
    args: ["arg1", "arg2", "arg3"]
    env:
    - name: INTERVAL
      value: "30"
    - name: FIRST_VAR
      value: "foo"
    - name: SECOND_VAR
      value: "$(FIRST_VAR)bar"
```

可以看到，我们可以利用env标签向容器中传递环境变量，环境变量还可以相互引用。这种方式的问题在于配置文件和部署是绑定的，那么对于同样的应用，测试环境的参数和生产环境是不一样的，这样就要求写两个部署文件，管理起来不是很方便。

## 什么是ConfigMap

上面提到的例子，利用ConfigMap可以解耦部署与配置的关系，对于同一个应用部署文件，可以利用```valueFrom```字段引用一个在测试环境和生产环境都有的ConfigMap（当然配置内容不相同，只是名字相同），就可以降低环境管理和部署的复杂度。

![](https://img2018.cnblogs.com/blog/39469/201811/39469-20181101083024064-1406584186.png)

ConfigMap有三种用法：
- 生成为容器内的环境变量
- 设置容器启动命令的参数
- 挂载为容器内部的文件或目录

## ConfigMap的缺点
- ConfigMap必须在Pod之前创建
- ConfigMap属于某个NameSpace，只有处于相同NameSpace的Pod才可以应用它
- ConfigMap中的配额管理还未实现
- 如果是volume的形式挂载到容器内部，只能挂载到某个目录下，该目录下原有的文件会被覆盖掉
- 静态Pod不能用ConfigMap

## ConfigMap的创建

```sh
$ kubectl create configmap <map-name> --from-literal=<parameter-name>=<parameter-value>
$ kubectl create configmap <map-name> --from-literal=<parameter1>=<parameter1-value> --from-literal=<parameter2>=<parameter2-value> --from-literal=<parameter3>=<parameter3-value>
$ kubectl create configmap <map-name> --from-file=<file-path>
$ kubectl apply -f <configmap-file.yaml>
# 还可以从一个文件夹创建configmap
$ kubectl create configmap <map-name> --from-file=/path/to/dir
```
Yaml 的声明方式

```yaml
apiVersion: v1
data:
  my-nginx-config.conf: |
    server {
      listen              80;
      server_name         www.kubia-example.com;

      gzip on;
      gzip_types text/plain application/xml;

	  location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
      }
    }
  sleep-interval: |
    25
kind: ConfigMap		
```

## ConfigMap的调用
### 环境变量的方式
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-configmap
spec:
  containers:
  - image: nginx
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: <map-name>
          key: sleep-interval
```

> 如果引用了一个不存在的ConfigMap，则创建Pod时会报错，直到能够正常读取ConfigMap后，Pod会自动创建。

一次传递所有的环境变量
```yaml
spec:
  containers:
  - image: nginx
    envFrom:
    - prefix: CONFIG_
      configMapRef:
        name: <map-name>
```

### 命令行参数的方式
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-configmap
spec:
  containers:
  - image: nginx
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: <map-name>
          key: sleep-interval
    args: ["$(INTERVAL)"]
```

### 以配置文件的方式
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-test
spec:
  containers:
  - image: nginx
    name: web-server
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: <map-name>
```

将Configmap挂载为一个文件夹后，原来在镜像中的文件夹里的内容就看不到，这是什么原理？这是因为原来文件夹下的内容无法进入，所以显示不出来。为了避免这种挂载方式影响应用的正常运行，可以将configmap挂载为一个配置文件。
```yaml
spec:
  containers:
  - image: nginx
    volumeMounts:
    - name: config
      mountPath: /etc/someconfig.conf
      subPath: myconfig.conf
```
![](https://img2018.cnblogs.com/blog/39469/201811/39469-20181101083101837-948645932.png)

## Configmap的更新
```sh
$ kubectl edit configmap <map-name>

```

confgimap更新后，如果是以文件夹方式挂载的，会自动将挂载的Volume更新。如果是以文件形式挂载的，则不会自动更新。
但是对多数情况的应用来说，配置文件更新后，最简单的办法就是重启Pod（杀掉再重新拉起）。如果是以文件夹形式挂载的，可以通过在容器内重启应用的方式实现配置文件更新生效。即便是重启容器内的应用，也要注意configmap的更新和容器内挂载文件的更新不是同步的，可能会有延时，因此一定要确保容器内的配置也已经更新为最新版本后再重新加载应用。

## 什么是Secret
Secret与ConfigMap类似，但是用来存储敏感信息。在Master节点上，secret以非加密的形式存储（意味着我们要对master严加管理）。从Kubernetes1.7之后，etcd以加密的形式保存secret。secret的大小被限制为1MB。当Secret挂载到Pod上时，是以tmpfs的形式挂载，即这些内容都是保存在节点的内存中，而不是写入磁盘，通过这种方式来确保信息的安全性。

> Kubernetes helps keep your Secrets safe by making sure each Secret is only distributed to the nodes that run the pods that need access to the Secret. Also, on the nodes themselves, Secrets are always stored in memory and never written to physical storage, which would require wiping the disks after deleting the Secrets from them.

每个Kubernetes集群都有一个默认的secrets
![](https://img2018.cnblogs.com/blog/39469/201811/39469-20181101083123554-1363293401.png)

创建和调用的过程与configmap大同小异，这里就不再赘述了。

![](https://images2018.cnblogs.com/blog/39469/201807/39469-20180710163655709-89635310.png)

## 参考资料
1. [Kubernetes Pod 深入理解与实践](https://www.jianshu.com/p/d867539a15cf)
2. [Configmap](https://www.jianshu.com/p/571383da7adf)
