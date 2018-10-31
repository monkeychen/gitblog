title: oVirt持续集成方案分析
date: 2018-07-10 16:21:08
tags: [ovirt, engine, 虚拟化]
categories: [分布式, 虚拟化]
keywords: [ovirt, engine, 虚拟化]
---
# oVirt持续集成方案分析

#### 云管理平台组-陈志安

------

## 1. STDCI
oVirt项目定义了一套标准规范，通过这套标准，一个源码工程就可以一种通用的方式定义其应该如何被构建、测试、部署与发行，而这个定义规则是独立于开发该源码工程所使用的编程语言及工具，本质上讲它是由oVirt制定的适用于`CI/CD(持续集成/持续部署)`的`DSL(Domain Specific Language)`，这套规范简称为`STDCI`。

CI团队可以基于这套标准创建像`mock_runner`这一类通用的构建、测试、部署与发行工具，这些工具以统一的方式来处理所有的ovirt工程。

oVirt项目的持续集成系统（CI系统）就是使用这套标准以自动化的方式执行该项目下各个工程的构建、测试、部署、发行进程。

> 该规范的实现请参考：[`https://github.com/oVirt/jenkins/tree/master/scripts`][3]

### 1.1. Stage
`STDCI`中的一个核心概念是“stage”，State是指作用在变更过的源码上的各种操作，它代表了源码从开发人员初始创建到成为正式发布产品整个生命周期的各个阶段。在每个特定的stage会执行一系列与该stage相关的各种操作（命令），这些操作命令是由每个具体工程定义。

当前STDCI定义了如下几个常用的stage：

* build-artifacts：该阶段定义了如何从源码构建出用户可使用的归档文件，比如RPM包或Docker镜像之类的文件。
* build-artifacts-manual：该阶段主要定义了如何从tar格式的源码包进行项目构建，一般在人工处理的方式进行正式版本发布时会涉及到该阶段，比较少用。
* check-patch：这个阶段定义了当代码发生变更时如何进行代码质量、功能或回归验证。一般是用户在Github等平台上发起PR请求会触发与该阶段关联的操作。
* check-merged：这个阶段定义了当代码发生变更时如何进行代码质量、功能或回归验证。一般是分支合并操作后会触发与该阶段关联的操作。
* poll-upstream-sources：有时项目会依赖的上游或外部项目或库，该阶段主要定义了上游或外部依赖项目的更新操作。


<!--More-->

### 1.2. 创建符合STDCI规范的项目
* STDCI配置文件，该文件必须存放在工程根目录下，该配置文件的格式规范及用法请参考链接：[STDCI配置文件使用说明][2]。
* 工程根目录下必须有一个名为`automation`的目录，该目录存放着每个`stage`需要执行的脚本文件。

STDCI配置文件名可以有如何几种：
```
stdci.yaml, automation.yaml, seaci.yaml, ovirtci.yaml
stdci.yml, automation.yml, seaci.yml, ovirtci.yml
.stdci.yaml, .automation.yaml, .seaci.yaml, .ovirtci.yaml
.stdci.yml, .automation.yml, .seaci.yml, .ovirtci.yml
```
默认情况下，在进行工程构建与测试时，STDCI引擎将从工程根目录下依次搜索配置文件，然后在每个特定的stage根据配置文件中设置的规则执行`automation`目录下的相应脚本。

### 1.3. 基于STDCI进行项目构建与测试
目前有两种方式构建与测试符合STDCI规范的工程：
* 使用`mock_runner.sh`在本地执行，请参考：[`mock-runner.sh使用说明`][5]。
* 通过CI系统自动执行构建、测试、部署、发行。

> 本文不深入讲解STDCI的使用说明，您可直接参考：[STDCI介绍文档][1]

## 2. DevOps平台
### 全局流程图

![ovirt-devops全局流程图](http://img.simiam.com/ovirt-devops.png)

> Jenkins持续集成系统有一个核心概念：任务（也称为Job），我们通常所说的搭建Jenkins持续集成环境其实就是创建一系列的任务并指定触发任务执行的条件（事件），在某一指定的事件被Jenkins系统捕获后，它将执行相应的任务，这一过程就是一次集成。

oVirt项目基于Jenkins搭建其CI/CD平台（后面简称DevOps平台），整个DevOps平台由以下几个部分组成：

* 基础环境搭建自动化：基于foreman与puppet搭建Jenkins环境，详见项目：[Infra-Puppet][6]。
* Jenkins任务管理自动化：基于JJB（Jenkins Job Builder）实现构建任务管理脚本化、版本化、自动化，让Jenkins管理Jenkins（听上去是不是很神奇）。详见项目：[oVirt-jenkins][7]。
* 自动化持续集成：所有符合STDCI标准的工程都被纳入到以Jenkins环境，包括上面的`Infra-Puppet, oVirt-jenkins`项目；持续集成主要包括构建、测试、部署、发行四个阶段，其中“部署”主要是指部署测试环境，“发行”是指将生成的RPM等归档文件上传至版本发行系统。
* 集成测试套件：这里主要是指OST（Ovirt-System-Test），它提供了一系列的测试套件，包括但不限于基础功能测试套件、性能测试套件等，详见项目：[ovirt-system-test][8]。

oVirt开源项目下的所有子项目都是符合STDCI标准，所有项目的持续集成任务都是自动化生成的，但任务的触发有多种：

* 人工触发（在Jenkins Web UI上操作）
* 基于Github的webhook等机制下事件驱动，如push事件，merge事件，pull-request事件。
* 定时执行，如每天晚上12点执行。

### 2.1. Jenkins-Job管理自动化

Jenkins-Job管理是指通过UI或JJB的方式在Jenkins上创建、更新、删除任务；而Jenkins-Job管理自动化是指借助JJB自动创建、更新、删除任务，而不需要在Jenkins WebUI上人工操作。
> 实现原理也相对简单：因为Jenkins-Job定义了一系列持续集成任务，因此也可以再增加一个特殊的任务，这个任务就是JenkinsJobDeploy，一旦该任务被执行，它就会从Jenkins-Job定义Git仓库下载最新的任务定义脚本并更新Jenkins系统上的任务。

#### 2.1.1. Jenkins任务初始化流程
![Jenkins任务初始化流程](http://img.simiam.com/jenkins-job-init.png)

#### 2.1.2. Jenkins任务管理自动化流程

![Jenkins任务管理自动化流程](http://img.simiam.com/jenkins-job-mgmt.png)

### 2.2. ovirt持续集成
oVirt每个子项目的持续集成流程并无特殊之处，都根据Jenkins上的任务配置步骤依次执行相关脚本：编译、单元测试、构建、部署测试环境、系统测试、发行。

**需要强调的是**：这些持续集成相关的脚本都是通过JJB生成的，且这些脚本最终是由STDCI引擎串联调度完成一次集成过程，而开发人员只需要编写STDCI每个阶段(stage)需要执行的脚本。


### 2.3. 涉及到技术
#### 2.3.1. Python
Python是oVirt持续集成方案的主力开发语言，核心的STDCI控制引擎、OST系统测试框架、与ansible相关的自动化部署脚本、Jenkins Job Builder都是用Python编写。

#### 2.3.2. Groovy
Groovy是基于JVM的脚本语言，像Gradle这样的构建工具便是用Groovy开发的，它也可以同Java互操作，同时它也经常被用于实现代码自动生成这类功能。而Jenkins持续集成平台则使用Groovy来编写`pipeline`脚本。

#### 2.3.3. Foreman
在介绍Foreman之前，我们先介绍下`[Bare Metal Provisioning]`这个术语（英语不好，暂且翻译为“裸机供应”）。所谓`Bare Metal Provisioning`是指为一台服务器（物理机或虚拟机）安装指定的操作系统的过程。通常情况下，有两种办法为服务器安装操作系统：

* 使用DVD等存储媒介人工一台一台安装
* 使用软件工具自动化的批量安装，`Foreman`就是这样的软件工具，类似的还有`Razor, Cobbler, RackHD`。

当然Foreman除了“裸机供应”能力外，它还有提供了其它服务，如与`Puppet, Chef`配合实现自动化配置与管理，它还提供了一个可视化的管理平台。更详细的信息还请直接访问[官网](https://www.theforeman.org/)。

> Foreman是用Ruby语言开发的。

#### 2.3.4. Puppet
[Puppet](https://puppet.com)是开源的系统配置管理工具，基于C/S的部署架构。是一个为实现数据中心自动化管理而设计的配置管理软件，它使用跨平台语言规范，管理配置文件、用户、软件包、系统服务等。Puppet开源项目创建之初主要是为了解决配置管理自动化的相关问题，该项目目前存在两种形态：

* Open Source Puppet：仍然是提供配置管理自动化方案，其通常是与Foreman配合完成数据中心服务器从OS安装到网络配置、应用配置等一系列自动化配置管理操作。
* Puppet Enterprise：收费版本，其不需要借助Foreman等第三方服务就可完成服务器OS安装配置管理，即提供了一站式的解决方案。

> Puppet也是用Ruby语言开发的。

#### 2.3.5. Ansiable
[Ansilbe](https://www.ansible.com/)是一个部署一群远程主机的工具。远程的主机可以是远程虚拟机或物理机， 也可以是本地主机。

> Ansible与Open Source Puppet一样，不具备“裸机供应”能力，其也需要与Foreman或[ansible-os-autoinstall][12]等工具配合使用。

Ansible最初是作为自动化工具（如PupPET和Chef）的轻量级替代而开发的；但是它是用Python编写的（而不是Ruby），并且采用了一个基于SSH的无代理的架构（即不是采用Puppet的C/S架构，在被管理节点上不需要安装任何特殊软件）。

Ansilbe通过SSH协议实现远程节点和管理节点之间的通信，但是SSH必须配置为公钥认证登录方式，而非密码认证。理论上说，只要管理员通过ssh登录到一台远程主机上能做的操作，Ansible都可以做到。包括：

* 拷贝文件
* 安装软件包
* 启动服务
* ......

总得来说，Ansible有如下特点：

```
1、部署简单，只需在主控端部署Ansible环境，被控端无需做任何操作；
2、默认使用SSH协议对设备进行管理；
3、有大量常规运维操作模块，可实现日常绝大部分操作。
4、配置简单、功能强大、扩展性强；
5、支持API及自定义模块，可通过Python轻松扩展；
6、通过Playbooks来定制强大的配置、状态管理；
7、轻量级，无需在客户端安装agent，更新时，只需在操作机上进行一次更新即可；
8、提供一个功能强大、操作性强的Web管理界面和REST API接口——AWX平台。
```

> Ansible是用Python开发的，它目前已被Redhat收购，是自动化运维工具中认可度最高的。oVirt的很多自动化部署子项目都是用Ansible开发的。

#### 2.3.6. Lago
Lago是一个虚拟测试环境框架，它可在服务器或普通PC上为各种测试用例构建虚拟环境。oVirt-System-Test项目使用Lago框架来搭建测试环境。具体可参考[官方文档][14]或[Github库][15]。

> Lago使用Python开发

#### 2.3.7. JJB
JJB全称为Jenkins Job Builder，它是由openstack-infra团队开发的，项目地址：[Jenkins Job Builder Github][11]，详细信息请直接参考[文档][10]。

> JJB使用Python开发

## 3. 总结
oVirt的持续集成方案也是目前IaaS开源领域的主流方案，从基础设施、编译构建、测试、部署等几个方面都实现了自动化。其中值得我们借鉴的地方有：

* 制定了一套统一的持续集成标准规范，并基于它实现了STDCI引擎：oVirt下的所有子项目都严格遵守该规范
* Jenkins平台上维护的任务管理也实现自动化
* 提供了一系列可自动化的系统（集成）测试套件，可以大大提升集成测试、回归测试效率

为了实现自动化水平，整个方案的涉及的技术栈也比较多，这也带来了一定的学习成本。至少在自动化配置管理方面可以统一使用`Ansible`。


## 参考资料
* [oVirt STDCI文档][1]
* [OST（oVirt System Test）文档][9]
* [Jenkins Job Builder文档][10]
* [Jenkins Job Builder源码][11]

[1]: http://ovirt-infra-docs.readthedocs.io/en/latest/CI/Build_and_test_standards/index.html
[2]: http://ovirt-infra-docs.readthedocs.io/en/latest/CI/STDCI-Configuration/index.html
[3]: https://github.com/oVirt/jenkins/tree/master/scripts
[4]: http://ovirt-infra-docs.readthedocs.io/en/latest/CI/Build_and_test_standards/index.html#running-build-and-test-stages
[5]: http://ovirt-infra-docs.readthedocs.io/en/latest/CI/Using_mock_runner/index.html
[6]: https://github.com/oVirt/infra-puppet
[7]: https://github.com/oVirt/jenkins
[8]: https://github.com/oVirt/ovirt-system-tests
[9]: http://ovirt-system-tests.readthedocs.io/en/latest/index.html
[10]: https://docs.openstack.org/infra/jenkins-job-builder/
[11]: https://github.com/openstack-infra/jenkins-job-builder
[12]: https://github.com/sergevs/ansible-os-autoinstall
[13]: https://www.reddit.com/r/ansible/comments/7c7lsg/install_os_on_bare_metal/
[14]: http://lago.readthedocs.io/en/stable/
[15]: https://github.com/lago-project/lago

