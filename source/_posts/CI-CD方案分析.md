title: CI/CD方案分析
date: 2018-07-13 09:56:59
tags: [devops, CI, CD, 持续集成, 持续交付, 持续部署]
categories: [devops, CI, CD, 持续集成, 持续交付, 持续部署]
keywords: [devops, CI, CD, 持续集成, 持续交付, 持续部署]
---
# CI/CD方案分析

## 1. DevOps介绍

随着软件发布迭代的频率越来越高，传统的“瀑布型”（开发—测试—发布）模式已经不能满足快速交付的需求。2009年左右DevOps（Development和Operations的组合）应运而生，简单地来说，就是更好的优化开发(DEV)、测试(QA)、运维(OPS)的流程，开发运维一体化，通过高度自动化工具与流程来使得软件构建、测试、发布更加快捷、频繁和可靠。

![DevOps的组成](http://oaivivmzx.bkt.clouddn.com/what-is-devops.jpg)

DevOps出现以前，开发与运维对于生产环境上出现的问题是这样处理的：

运维人员：

![It's not my machine](http://oaivivmzx.bkt.clouddn.com/devops-ops-say.png)

开发人员：

![It's not my code](http://oaivivmzx.bkt.clouddn.com/devops-dev-say.png)

处理问题的模式：（未进行有效沟通，而是相互责备、报怨，在经过长时间的各种扯皮后把问题解决了）

![Before apply DevOps](http://oaivivmzx.bkt.clouddn.com/before-devops.png)

DevOps出现以后，开发与运维的关系转变为：

![Think for peer](http://oaivivmzx.bkt.clouddn.com/devops-love.png)

因此，他们对于生产环境上出现的问题是这样处理的：

![Think for peer](http://oaivivmzx.bkt.clouddn.com/devops-together.png)

处理问题的模式变为：（相互理解，充分沟通并最终快速解决问题）

![After apply DevOps](http://oaivivmzx.bkt.clouddn.com/after-devops.png)


### 1.1. DevOps生命周期

DevOps集文化理念、实践和工具于一身，可以提高组织高速交付应用程序和服务的能力，与使用传统软件开发和基础设施管理流程相比，能够帮助组织更快地发展和改进产品。这种速度使组织能够更好地服务其客户，并在市场上更高效地参与竞争。

DevOps是一个完整的面向IT运维的工作流，以IT自动化以及持续集成（CI）、持续部署（CD）为基础，来优化程式开发、测试、系统运维等所有环节，其典型的运作流程如下：

![DevOps-lifecycle](http://oaivivmzx.bkt.clouddn.com/devops-lifecycle.png)

上图中的`Build, Test, Release`对应的CI/CD平台中的构建、测试、交付（部署）这几个概念，也就是说CI/CD是实施DevOps的基础，除此之外还会涉及源码质量管理平台（静态代码分析、潜在BUG分析、单元测试覆盖报表等）。

实施DevOps前，软件开发管理生命周期如下：

![before apply devops](http://oaivivmzx.bkt.clouddn.com/devops-old-way.png)

实施DevOps后，软件开发管理生命周期如下：

![after apply devops](http://oaivivmzx.bkt.clouddn.com/devops-new-way.png)

### 1.2. 适用场景

到底DevOps能给企业带来什么样的业务价值呢？DevOps平台的理念固然是将软件研发的全生命周期管理起来，但是并不意味着一定要做到全生命周期的管理，落实到企业内部，终究还是要结合企业的现状和实际的需求，有选择性有目标的去建设。对于企业而言，不管是提升IT的运营效率70%，还是做到开发测试环境的持续集成、自动化测试、自动化部署，亦或是一天部署10次这种DevOps最初的目标，最重要的还是要结合现状，先认清DevOps能给企业带来什么样的业务价值。

DevOps涉及到源码质量管理、持续集成、持续交付、持续部署、运维管理等多个系统平台，其天然适合那些主要提供线上服务的互联网团队（特别是基于微服务架构的团队）。而对于非互联网企业（主要是传统软件厂商）来说，其主要是为用户提交软件产品，基本不存在运维管理的需求。同时，传统软件厂商的软件开发管理生命周期中，其对源码质量管理、持续集成、持续交付的需求比较强烈，而持续部署主要是为了解决开发与测试环境自动化搭建问题。

企业引入DevOps也可能需要对企业组织架构进行调整，以解决部门墙问题。

> 很显然，我们暂时不需要引入DevOps这种软件开发模式。

## 2. 持续集成、持续交付与持续部署

> 持续交付依赖持续集成，而持续部署依赖持续交付，因此我们将这三者放在同一章节里介绍。

### 2.1. 概念介绍
#### 2.1.1. 持续集成（Continuous Integration，简称CI）

> 持续集成是一种软件开发实践，即团队开发成员经常集成他们的工作，通过每个成员每天至少集成一次，也就意味着每天可能会发生多次集成。每次集成都通过自动化的构建（包括编译，发布，自动化测试）来验证，从而尽早地发现集成错误。
>
>    --- 摘自`Martin Fowler`的文章：[Continuous Integration][14]

传统软件开发模式下，通常情况下是在每个项目成员完成他们各自的任务后才开始进行系统集成。整个集成过程一般会长达数周甚至几个月的时间，在此期间经常出现让所有相关人员都十分痛苦的事情。而持续集成（CI）则将传统软件开发过程中的集成阶段大大提前了，只要有代码提交至源码库（如Git）就会触发构建（包括代码分析）、测试等任务，通过这种频繁的集成来防止传统模式下因集成问题堆积而导致”集成地狱（Integration Hell）“。

简单讲，持续集成就是不断对合并项目主干的源码进行相应的检查、构建、测试，通常每天至少进行一次；持续集成不是为了避免软件开发过程中的各种问题，而是为了尽量早的发现问题。

引入CI意味着：在家里远程办公的开发人员A与在公司办公的开发人员B可以很方便的在同一个项目中进行协同办公，而不需要担心源码合并问题，因为他们的每次源码提交操作都会触发CI进行构建、测试以验证他们的代码是否能正常工作。

开发人员通常会使用CI服务器来进行源码构建与集成，为了让持续集成流程有效的运行起来，项目组的所有开发人员都需要编写单元测试代码以保证其提交的代码能按预期的目标执行，同时不会影响其他人的工作成果。当所有的单元测试用例都执行通过后，这些集成后的代码还不能马上交付或部署至生产环境，因为在交付前还需要在集成测试环境（准生产环境）进行集成测试、验收测试（Acceptance Testing），这部分内容属于持续交付的范畴，下节将会详细介绍。

下图为持续集成的主要流程：

![Continuous Integration](http://oaivivmzx.bkt.clouddn.com/continuous-integration-flow.png)

引入持续集成的好处：

* 集成频率高，至少每天一次，集成时间可预期可控。
* 可快速暴露问题，加速问题定位


#### 2.1.2. 持续交付

持续交付(Continuous Delivery)是指在持续集成的基础上，将集成后的代码部署到更贴近真实运行环境的“准生产环境”（production-like）中。 比如，我们完成单元测试后，可以把代码部署到连接数据库的Staging环境中进行更多的测试。如果代码没有问题，可以继续手动部署到生产环境中。

![Continuous Delivery](http://oaivivmzx.bkt.clouddn.com/continuous-delivery-flow.png)

由上图可知，从开发一直到项目可交付整个过程中涉及的环境可能有：开发环境、测试环境（包括压测环境）、准生产环境，生产环境，这整个过程也常被称为部署管道（Deployment Pipeline），每个环境所执行的测试用例也将不一样，只有前一个环境的测试用例全部通过才能继续进入下一个环境（即自动部署新环境 + 执行适合该环境的测试用例）；同时每个环境的执行结果都会及时反馈给相应的开发人员，如果环境部署异常或用例执行失败他们就能更容易更及时的解决问题。

整个过程基本按“部署环境 -> 执行测试用例 -> ... -> 部署环境 -> 执行测试用例”这一模式不断重复，因此为了实现自动化的持续交付，“自动化部署”、“可自动化执行的测试用例”是关键的前提条件。

> 有一点需要注意，对于提供线上服务的团队，当功能代码可交付时，还需要将相关代码部署至生产环境，但这一部署过程是纯手工的。这也是持续交付与持续部署的区别。

#### 2.1.3. 持续部署

持续部署(Continuous Deploy)是在持续交付的基础上，把部署到生产环境的过程自动化。持续部署和持续交付的区别就是最终部署到生产环境是自动化的。

![Continuous Deployment](http://oaivivmzx.bkt.clouddn.com/continuous-deployment-flow.png)

这里大家也许有个疑问：在生产环境是否需要执行测试用例，如果需要执行，那会否影响系统性能或产生脏数据？

这个问题不好简单的回答是或否，从我自己的经验来讲：

* 对于线上服务（应用）一般会采用灰度发布，同时只执行关键的验收测试用例，且这些用例所产生的数据会被认定为合法的生产环境数据，不做任何回滚，最多只做备注；
* 而对于非线上服务（传统的软件交付方式），则技术支持人员在帮客户安装或升级软件后，也会对关键功能做验证（常见的方式为一键体检之类的工具或自动化脚本）。


## 3. 可选的工具链

一个项目要引入CI/CD（持续集成与持续交付），一般情况下需要具备以下几个条件：

* 源码管理仓库：可以是类似分布式的Git、集中式的SVN。
* 搭建CI平台：使用业界流行的CI软件（如Jenkins，Gitlab CI）搭建的CI系统平台。
* 源码质量管理平台：主要是指静态代码分析与测试覆盖统计，如业务比较流行的SonarQube，CheckStyle，FindBug等。
* 单元测试：项目组的每个成员都需要编写单元测试代码，并严格遵守约定的单元测试相关规范。
* 集成测试：包括可自动化执行的测试用例管理（编写、归档等），集成测试环境自动化搭建。
* 测试环境搭建自动化：主要是指可以自动化的部署集成测试环境，为集成测试、验收测试准备可用的测试环境。
* 软件发布平台：为可交付的软件提供对外发行及展示的平台，如基于Nexus的maven仓库、用于托管docker镜像的镜像仓库、NPM私有仓库等。

### 3.1. CI/CD平台分析

通用指标分析结果：

![CI/CD平台比对](http://oaivivmzx.bkt.clouddn.com/ci-platform-compare.png)

上面的分析结果中，排除掉非开源与收费版的，就只剩下Jenkins，Gitlab CI，Go CD，Flow CI四个版本，而flow.ci为国内开源项目，根据国内开源项目的尿性（基本都是先开源后收费），个人认为也不适合使用Flow CI。那么就只剩下三个可选方案了。

#### Jenkins
Jenkins是一款用Java编写的开源的跨平台的CI工具，同时可以通过插件扩展功能。Jenkins插件非常好用，我们可以容易地添加自己的插件。除了它的扩展性之外，Jenkins还有另一个非常好的功能——它可以在多台机器上进行分布式地构建和负载测试。Jenkins是根据MIT许可协议发布的，因此可以自由地使用和分发。

总的来说：Jenkins是最好的持续集成工具之一，它既强大又灵活。但其UI比较古老，同时学习它可能要花费一些时间，如果你需要一个灵活的持续集成解决方案，那么学习如何使用它将是非常值得的。

#### Gitlab CI
GitLab CI是GitLab的一个组成部分，GitLab CI能与GitLab完全集成，可以通过使用GitLab API轻松地作为项目的钩子。GitLab的执行部分（流程构建）使用Go语言编写，可以运行在Windows，Linux，OSX，FreeBSD和Docker上。

官方的Go Runner可以同时运行多个作业，并具有内置的Docker支持。对基于Gitlab找寻私有源码仓库的公司来说，可以考虑使用Gitlab CI作为其CI/CD平台。

#### Go CD
Go CD是ThoughtWorks公司Cruise Control的化身。让Go CD脱颖而出的是它的流水线概念，使复杂的构建流程变得简单。关于流水线概念是如何帮助持续交付，以及如何与Jenkins的流水线流程进行比较，可以参考[这里][18]。它最初在设计时就支持流水线概念，消除了构建过程的瓶颈，并能够并行地执行任务。

> Jenkins也可以通过plugins机制引入流水线功能。

#### 小结

本文章只提供三个可选方案，每个方案各有其优势：

* Jenkins拥有广泛的群众基础，社区活跃，插件丰富，同时还有Jenkins Job Builder这种美妙的Job自动化插件，很多开源项目都使用Jenkins作为其CI平台。
* GitLab CI能与GitLab完全集成是其一个非常重要的优势，同时其GoRunner机制相当灵活，最新版本引入DevOps流程，同时支持K8S。
* Go CD脱颖而出的是它的流水线概念，使复杂的构建流程变得简单。

但具体选择哪一款，还是得根据项目团队的实际需要来定。对于我们组来讲，Jenkins基本能满足需求，个人认为可优先使用Jenkins并收集使用过程中碰到的问题与新需求；同时，在资源允许的情况下可事先安排人员深入分析这三个平台以后需。

### 3.2. 代码质量管理平台
#### SonarQube
随着IT行业中软件产品的推陈出新，客户对于软件产品的要求也越来越高，因此如何高质量的管理软件代码，及时地对代码质量进行分析并给出合理的解决方案就成为了当下必须要解决的一个问题。与当今众多的代码质量管理工具相比，SonarQube更具有特色和竞争力，其优势主要体现为：它是一个开源的代码质量管理系统，支持25+种语言，可以通过使用插件机制与eclipse、JIRA、Jenkins等其他外部工具集成，从而实现了对代码质量的全面自动化分析和管理。

SonarQube既可以本地安装也可以选择托管在云端，云端托管地址为：[https://sonarcloud.io/](https://sonarcloud.io/)。

可用的SonarQube管理平台：[SonarQube Demo](http://172.21.192.216:9000/)

![SonarQube截图](http://oaivivmzx.bkt.clouddn.com/sonarqube-demo.png)

#### Jenkins + CheckStyle + FindBug
Jenkins，CheckStyle，FindBug三者配合起来能够实现最基本代码分析需求，但其分析结果展现还需要再配合其他插件来实现，同时其展示界面比较古老，本质上讲该功能是依附于Jenkins的，并不是一个独立的代码质量管理平台。

### 3.3. 自动化测试工具
#### 3.3.1. 支持BDD(行为驱动开发)的自动化测试框架分析

自动化测试可以快速自动完成大量测试用例，节约巨大的人工测试成本；同时它需要拥有专业开发技能的人才能完成开发，且需要大量时间进行维护（在需求经常变化的情况下），所以大部分具有很好开发技能的人员不是很愿意编写自动化用例。但由于软件规模的高速增长，人力资源的逐步稀缺，自动化测试已是势在必行。

对于自动化测试首先需要保证其功能是对客户有价值的和正确可用的。而这一切的基础就是用例要能测试客户的需求，期望，最好能让客户参与到测试用例的开发过程中来或让客户评审测试用例，因此出现了ATDD、BDD等各种理论方法来支撑这一行为。现有很多自动化测试工具可支持ATDD、BDD等，比如Cucumber、RobotFramework、SpecFlow、JBehave、Fitness、Concordion、Guage等，其中Cucumber和RobotFramework是最流行的两个框架，本文将简单分析这两个框架（想要完全搞懂这两个框架还是需要安排相关资源投入分析）：

![Cucumber VS RobotFramework](http://oaivivmzx.bkt.clouddn.com/cucumber-robot-compare.png)

#### 3.3.2. 单元测试Mock框架

单元测试的思路是在不涉及依赖关系的情况下测试代码（隔离性），所以测试代码与其他类或者系统的关系应该尽量被消除。一个可行的消除方法是替换掉依赖类（测试替换），也就是说我们可以使用替身来替换掉真正的依赖对象。

常见的测试模拟类的分类如下：

* `dummy object`：其作为参数传递给方法但是绝对不会被使用。比如说，这种测试类内部的方法不会被调用，或者是用来填充某个方法的参数。
* `Fake`：它是真正接口或抽象类的实现类，但其对象内部实现很简单。比如说，它存在内存中而不是数据库中。（即：Fake实现了真正的逻辑，但它的存在只是为了测试，而不适合于用在产品中。）
* `stub`：Stub类是依赖类的部分方法实现，而这些方法在进行类和接口的测试时会被用到，也就是说stub类在测试中会被实例化。stub类会回应任何外部调用。stub类有时候还会记录调用的一些信息。
* `mock object`：其是指类或者接口的模拟实现，我们可以自定义这个对象中某个方法的输出结果；Stub和Mock虽然都是模拟外部依赖，但Stub是完全模拟一个外部依赖， 而Mock还可以用来判断测试通过还是失败。

我们可以手动创建一个Mock对象或者使用Mock框架来模拟这些类，Mock框架允许你在运行时创建Mock对象并且定义它的行为。

一个典型的例子是把Mock对象模拟成数据的提供者。在正式的生产环境中它会被实现用来连接数据源。但是我们在测试的时候Mock对象将会模拟成数据提供者来确保我们的测试环境始终是相同的。

通过Mock对象或者Mock框架，我们可以测试代码中期望的行为。

##### Mockito, EasyMock, PowerMock

* EasyMock是相对比较早出现的Mock框架，现在流行度不如Mockito。
* Mockito是一个流行Mock框架，它刚开始基本只是对EasyMock的增强，但后面基本重写了，其整个风格与EasyMock基本不一样了。它可以和JUnit/TestNG结合起来使用。Mockito允许你创建和配置Mock对象。使用Mockito可以明显的简化对外部依赖的测试类的开发。
* PowerMock也是一个单元测试模拟框架，它是在EasyMock和Mockito框架的基础上做出的扩展。通过提供定制的类加载器以及一些字节码篡改技巧的应用，PowerMock实现了对静态方法、构造方法、私有方法以及Final方法的模拟支持等强大的功能（即对于`静态方法、构造方法、私有方法以及Final方法`来说，EasyMock与Mockito都无能为力，需要结合PowerMock来搞定）。

> Mockito与EasyMock的比较可参考：[https://github.com/mockito/mockito/wiki/Mockito-vs-EasyMock][22]


### 3.4. 自动化部署工具
#### Foreman

在介绍Foreman之前，我们先介绍下`[Bare Metal Provisioning]`这个术语（英语不好，暂且翻译为“裸机供应”）。所谓`Bare Metal Provisioning`是指为一台服务器（物理机或虚拟机）安装指定的操作系统的过程。通常情况下，有两种办法为服务器安装操作系统：

* 使用DVD等存储媒介人工一台一台安装
* 使用软件工具自动化的批量安装，`Foreman`就是这样的软件工具，类似的还有`Razor, Cobbler, RackHD`。

当然Foreman除了“裸机供应”能力外，它还有提供了其它服务，如与`Puppet, Chef`配合实现自动化配置与管理，它还提供了一个可视化的管理平台。更详细的信息还请直接访问[官网](https://www.theforeman.org/)。

> Foreman是用Ruby语言开发的。

#### Ansible
[Ansilbe](https://www.ansible.com/)是一个部署一群远程主机的工具。远程的主机可以是远程虚拟机或物理机， 也可以是本地主机。

> Ansible与Open Source Puppet一样，不具备“裸机供应”能力，其也需要与Foreman或[ansible-os-autoinstall][19]等工具配合使用。

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

#### Puppet

[Puppet](https://puppet.com)是开源的系统配置管理工具，基于C/S的部署架构。是一个为实现数据中心自动化管理而设计的配置管理软件，它使用跨平台语言规范，管理配置文件、用户、软件包、系统服务等。Puppet开源项目创建之初主要是为了解决配置管理自动化的相关问题，该项目目前存在两种形态：

* Open Source Puppet：仍然是提供配置管理自动化方案，其通常是与Foreman配合完成数据中心服务器从OS安装到网络配置、应用配置等一系列自动化配置管理操作。
* Puppet Enterprise：收费版本，其不需要借助Foreman等第三方服务就可完成服务器OS安装配置管理，即提供了一站式的解决方案。

> Puppet也是用Ruby语言开发的。

由于Ansible与Puppet属于同一类型的工具，使用哪一种则由团队成员的技能储备决定，就我们组来说，个人觉得Ansible更合适：a.团队有python储备；b.被管节点不需要安装代理。 

#### 其它工具

* Jenkins Job Builder: 它是由openstack-infra团队开发的，项目地址：[Jenkins Job Builder Github][20]，详细信息请直接参考[文档][21]

## 4. 总结

本文主要介绍了CI/CD方案的常见流程及相关的工具集，但对于大部分工具并未进行深入的学习与分析，因此接下来需要安排专门的资源深入学习，特别是自动化测试相关框架的学习。

### 4.1. 技术分析专项

* 深入研究Jenkins、Gitlab CI、Go CD三个平台：易用性、可扩展性、社区活跃度，与我们团队的CI/CD目标的契合度
* 深入研究RobotFramework与Cucumber这两个自动化测试框架：基本原理、测试用例编写规则、常用的测试库、与CI/CD平台协作方法、分析实现自动化测试的流程
* 深入学习单元测试Mock框架：Mockito与Powermock
* 深入研究自动化部署工具：Foreman与Ansible，结合我们组的实际需求梳理出可行的自动化部署方案
* 深入学习Jenkins Job Builder，实现Jenkins任务管理自动化与脚本化




---
### 参考资料
* [什么是DevOps -- atlassian][8]
* [什么是DevOps -- Redhat][9]
* [自动化测试框架分类与思考][10]
* [部分自动化测试框架列表][11]
* [Martin Fowler’s easy to read guide on CI][14]
* [Cucumber快速入门-Java版][15]
* [GoCD][16]


[1]: https://segmentfault.com/a/1190000007021659
[2]: http://www.slideshare.net
[3]: http://www.infoq.com/cn/news/2016/04/DevOps-continuous-integration-to
[4]: https://zhuanlan.zhihu.com/p/26684543
[5]: https://www.jianshu.com/p/e083531434f5
[6]: https://blog.csdn.net/kerryzhu/article/details/2958155
[7]: https://aws.amazon.com/cn/devops/what-is-devops/
[8]: https://www.atlassian.com/devops
[9]: https://www.redhat.com/en/topics/devops#
[10]: https://insights.thoughtworks.cn/automated-testing-framework/
[11]: https://en.wikipedia.org/wiki/List_of_unit_testing_frameworks
[12]: http://www.infoq.com/cn/articles/cucumber-robotframework-comparison
[14]: https://www.martinfowler.com/articles/continuousIntegration.html
[15]: http://docs.cucumber.io/guides/10-minute-tutorial/
[16]: https://docs.gocd.org/current/
[17]: https://www.testwo.com/article/1170
[18]: https://highops.com/insights/continuous-delivery-pipelines-gocd-vs-jenkins
[19]: https://github.com/sergevs/ansible-os-autoinstall
[20]: https://github.com/openstack-infra/jenkins-job-builder
[21]: https://docs.openstack.org/infra/jenkins-job-builder/
[22]: https://github.com/mockito/mockito/wiki/Mockito-vs-EasyMock
[23]: http://www.baeldung.com/mockito-vs-easymock-vs-jmockit





