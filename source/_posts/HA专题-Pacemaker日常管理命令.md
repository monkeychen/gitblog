title: HA专题--Pacemaker集群日常管理命令
date: 2017-04-29 13:20:49
tags: [HA,Pacemaker,crmsh,pcs]
categories: [HA]
keywords: [HA,Pacemaker,crmsh,pcs]
---

# 概述

Pacemaker的管理工具主要有两种：crmsh、pcs(Pacemaker/Corosync configuration system)，本文将同时介绍这两种命令行工具。
> 从CentOS6.4以后开始采用PCS替代crmsh来管理pacemaker集群（PCS专用于pacemaker+corosync的设置工具，其有CLI和web-based GUI界面）
> 文档来源于Pacemaker的[Github官网](https://github.com/ClusterLabs/pacemaker/blob/master/doc/pcs-crmsh-quick-ref.md)

<!--More-->

# 通用操作

## 显示配置信息
以XML格式显示

```
# crmsh 
crm configure show xml
# pcs 
pcs cluster cib
```

以非XML格式显示[To show a simplified (non-xml) syntax]

```
# crmsh
crm configure show
# pcs
pcs config
```
    
## 显示集群当前状态

```
# crmsh
crm status
#pcs
pcs status
```

也可以这样：

```
crm_mon -1
```

## 挂起节点（Node standby）

使节点进入Standby状态（Put node in standby）

```
# crmsh
crm node standby pcmk-1
# pcs
pcs cluster standby pcmk-1
```

使节点从Standby状态恢复（Remove node from standby）

```
# crmsh
crm node online pcmk-1
# pcs
pcs cluster unstandby pcmk-1
```

crm has the ability to set the status on reboot or forever. 
pcs can apply the change to all the nodes.

## 设置集群全局属性

```
# crmsh
crm configure property stonith-enabled=false
# pcs
pcs property set stonith-enabled=false
```

# 集群资源处理操作

## 列出所有RA(Resource Agent)的类别:`classes`

```
# crmsh
crm ra classes
# pcs
pcs resource standards
```

## 列出所有可用的RA

```
# crmsh
crm ra list ocf
crm ra list lsb
crm ra list service
crm ra list stonith

# pcs
pcs resource agents ocf
pcs resource agents lsb
pcs resource agents service
pcs resource agents stonith
pcs resource agents
```

您也可以通过`provider`进一步过滤：

```
# crmsh
crm ra list ocf pacemaker
# pcs
pcs resource agents ocf:pacemaker
```

## 查询具体RA的描述信息

```
# crmsh
crm ra meta IPaddr2
# pcs
pcs resource describe IPaddr2
```

Use any RA name (like IPaddr2) from the list displayed with the previous command
You can also use the full class:provider:RA format if multiple RAs with the same name are available :

```
# crmsh
crm ra meta ocf:heartbeat:IPaddr2
# pcs
pcs resource describe ocf:heartbeat:IPaddr2
```

## 创建资源

```
# crmsh
crm configure primitive ClusterIP ocf:heartbeat:IPaddr2 \
       params ip=192.168.122.120 cidr_netmask=32 \
       op monitor interval=30s 
# pcs
pcs resource create ClusterIP IPaddr2 ip=192.168.0.120 cidr_netmask=32
```

The standard and provider (`ocf:heartbeat`) are determined automatically since `IPaddr2` is unique.
The monitor operation is automatically created based on the agent's metadata.

## 显示资源配置信息

```
# crmsh
crm configure show
# pcs
pcs resource show
```

crmsh also displays fencing resources. 
The result can be filtered by supplying a resource name (IE `ClusterIP`):

```
# crmsh
crm configure show ClusterIP
# pcs
pcs resource show ClusterIP
```

crmsh also displays fencing resources. 

## 显示fencing资源

```
# crmsh
crm resource show
# pcs
pcs stonith show
```

pcs treats STONITH devices separately.

## 显示Stonith资源代码(RA)信息

```
# crmsh
crm ra meta stonith:fence_ipmilan
# pcs
pcs stonith describe fence_ipmilan
```

## 启动资源

```
# crmsh
crm resource start ClusterIP
# pcs
pcs resource enable ClusterIP
```

## 停止资源

```
# crmsh
crm resource stop ClusterIP
# pcs
pcs resource disable ClusterIP
```

## 删除资源

```
# crmsh
crm configure delete ClusterIP
# pcs
pcs resource delete ClusterIP
```

## 更新资源

```
# crmsh
crm resource param ClusterIP set clusterip_hash=sourceip
# pcs
pcs resource update ClusterIP clusterip_hash=sourceip
```

crmsh also has an `edit` command which edits the simplified CIB syntax
(same commands as the command line) via a configurable text editor.

```
# crmsh
crm configure edit ClusterIP
```

Using the interactive shell mode of crmsh, multiple changes can be
edited and verified before committing to the live configuration.

```
# crmsh
node-01$ crm configure # 进入crmsh上下文模式
crm(live)configure$ edit
crm(live)configure$ verify
crm(live)configure$ commit
```

## 删除给定资源上的属性信息

```
# crmsh
crm resource param ClusterIP delete nic
# pcs
pcs resource update ClusterIP ip=192.168.0.98 nic=  
```

## 列出资源的默认属性信息

```
# crmsh
crm configure show type:rsc_defaults
# pcs
pcs resource defaults
```

## 设置资源的默认属性信息

```
# crmsh
crm configure rsc_defaults resource-stickiness=100
# pcs
pcs resource defaults resource-stickiness=100
```
    
## 列出资源操作命令相关属性的默认值

```
# crmsh
crm configure show type:op_defaults
# pcs
pcs resource op defaults
```

## 设置资源操作命令相关属性的默认值

```
# crmsh
crm configure op_defaults timeout=240s
# pcs
pcs resource op defaults timeout=240s
```

## 设置Colocation约束

```
# crmsh
crm configure colocation website-with-ip INFINITY: WebSite ClusterIP
# pcs
pcs constraint colocation add ClusterIP with WebSite INFINITY
```

With roles

```
# crmsh
crm configure colocation another-ip-with-website inf: AnotherIP WebSite:Master
# pcs
pcs constraint colocation add Started AnotherIP with Master WebSite INFINITY
```

## 设置ordering约束

```
# crmsh
crm configure order apache-after-ip mandatory: ClusterIP WebSite
# pcs
pcs constraint order ClusterIP then WebSite
```

With roles:

```
# crmsh
crm configure order ip-after-website Mandatory: WebSite:Master AnotherIP
# pcs
pcs constraint order promote WebSite then start AnotherIP
```

## 设置preferred location约束

```
# crmsh
crm configure location prefer-pcmk-1 WebSite 50: pcmk-1
# pcs
pcs constraint location WebSite prefers pcmk-1=50
```

With roles:

```
# crmsh
crm configure location prefer-pcmk-1 WebSite rule role=Master 50: \#uname eq pcmk-1
# pcs
pcs constraint location WebSite rule role=master 50 \#uname eq pcmk-1
```

## 移动资源至指定节点（Move resources）

```
crm resource move WebSite pcmk-1
pcs resource move WebSite pcmk-1
    
crm resource unmove WebSite
pcs resource clear WebSite
```

A resource can also be moved away from a given node:

```
crm resource ban Website pcmk-2
pcs resource ban Website pcmk-2
```

Remember that moving a resource sets a stickyness to -INF to a given node until unmoved    

## Resource tracing

```
crm resource trace Website
# pcs不支持
```

## 清理指定资源的失败计数信息（Clear fail counts）

```
crm resource cleanup Website
pcs resource cleanup Website
```

## 编辑Edit fail counts

```
crm resource failcount Website show pcmk-1
crm resource failcount Website set pcmk-1 100
    
# pcs不支持
```

## Handling configuration elements by type

pcs deals with constraints differently. These can be manipulated by the command above as well as the following and others

```
# 下面这行命令的list可以省略，使用full选项是为了显示相关的id
pcs constraint list --full 
pcs constraint remove cli-ban-Website-on-pcmk-1
```

使用crmsh命令删除约束的方式与删除资源的命令一样
Removing a constraint in crmsh uses the same command as removing a resource.

```
crm configure remove cli-ban-Website-on-pcmk-1
```

The `show` and `edit` commands in crmsh can be used to manage
resources and constraints by type:

```
crm configure show type:primitive
crm configure edit type:colocation
```

## Create a clone

```
crm configure clone WebIP ClusterIP meta globally-unique=true clone-max=2 clone-node-max=2
pcs resource clone ClusterIP globally-unique=true clone-max=2 clone-node-max=2
```

## Create a master/slave clone

```
crm configure ms WebDataClone WebData \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true
pcs resource master WebDataClone WebData \
    master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true
```

# 其它操作

## 批量修改配置信息

```    
    # crmsh通过crm命令进入crmsh上下文模式，直接对CIB文档结构进行操作，最后再一次性commit
    crmsh # crm
    crmsh # cib new drbd_cfg
    crmsh # configure primitive WebData ocf:linbit:drbd params drbd_resource=wwwdata \
            op monitor interval=60s
    crmsh # configure ms WebDataClone WebData meta master-max=1 master-node-max=1 \
            clone-max=2 clone-node-max=1 notify=true
    crmsh # cib commit drbd_cfg
    crmsh # quit

    # pcs则先基于本地文件方式批量设置CIB参数，然后再通过push操作使配置生效
    pcs   # pcs cluster cib drbd_cfg
    pcs   # pcs -f drbd_cfg resource create WebData ocf:linbit:drbd drbd_resource=wwwdata \
            op monitor interval=60s
    pcs   # pcs -f drbd_cfg resource master WebDataClone WebData master-max=1 master-node-max=1 \
            clone-max=2 clone-node-max=1 notify=true
    pcs   # pcs cluster push cib drbd_cfg
```

## 创建模板（Template creation）

Create a resource template based on a list of primitives of the same
type

```
    crm configure assist template ClusterIP AdminIP
```

## 日志分析

Display information about recent cluster events

```
    crmsh # crm history
    crmsh # peinputs
    crmsh # transition pe-input-10
    crmsh # transition log pe-input-10
```

## Configuration scripts

Create and apply multiple-step cluster configurations including
configuration of cluster resources

```
    crmsh # crm script show apache
    crmsh # crm script run apache \
        id=WebSite \
        install=true \
        virtual-ip:ip=192.168.0.15 \
        database:id=WebData \
        database:install=true
```


