title: 迟到的Maven笔记
date: 2018-10-11 09:51:31
tags: [Maven,SpringBoot]
categories: [Java]
keywords: [Maven,SpringBoot]
---
# 迟到的Maven笔记
> 转载请注明出处：[simiam.com][1]

本文主要是对Maven学习与使用过程中的一些经验的总结，不是Maven的入门教程，如需要系统学习Maven，您可以看一下[《Maven实战》][4]这本书，或看下以下几个在线教程：
* [InfoQ上与Maven有关的内容][3]
* [极客学院的Maven教程](http://wiki.jikexueyuan.com/project/maven/)
* [Maven生命周期介绍](https://www.jianshu.com/p/fd43b3d0fdb0)

## 1. 依赖声明中scope的使用
> 网络上有太多的文章介绍，但个人还是推荐直接看[官方文档](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html)，英文不好的朋友可以看[这篇有点老的文章](http://tangyanbo.iteye.com/blog/1503957)。

除了掌握基本内容外，还需要特别关注以下几个内容：

* provided与runtime的区别，system知道下有这个东西就行。
* import这个scope是后面引入的新scope，其只能用于`<dependencyManagement>`中且类型为pom的依赖项，个人感觉其主要作用在于对依赖版本进行分类管理。
* Maven依赖冲突的解决策略，可以参考[这里](https://www.jianshu.com/p/f6ca45865025)

## 2. `build`配置
### 2.1. Maven项目的标准目录结构


* src
    * main
        * java --- 源文件 
        * resources --- 资源文件
        * filters --- 资源过滤文件
        * config --- 配置文件
        * scripts --- 脚本文件
        * webapp --- web应用文件
    * test
        * java --- 测试源文件
        * resources --- 测试资源文件
        * filters --- 测试资源过滤文件
    * it --- 集成测试
    * assembly --- assembly descriptors
    * site --- Site
* target
    * generated-sources
    * classes
    * generated-test-sources
    * test-classes
    * xxx.jar
* pom.xml
* LICENSE.txt
* NOTICE.txt
* README.txt


### 2.2. `resources`节点
构建Maven项目的时候，如果没有进行特殊的配置，Maven会按照标准的目录结构查找和处理各种类型文件。

> **src/main/java和src/test/java**
> 
> 这两个目录中的所有`*.java`文件会分别在`comile`和`test-comiple`阶段被编译，编译结果分别放到了`target/classes`和`targe/test-classes`目录中，但是这两个目录中的其他文件都会被忽略掉。
> 
> **src/main/resources和src/test/resources**
> 
> 这两个目录中的文件也会分别被复制到`target/classes`和`target/test-classes`目录中。
> 
> **target/classes**
> 
> 打包插件默认会把这个目录中的所有内容打入到`jar`包或者`war`包中。


资源文件是Java代码中要使用的文件。代码在执行的时候会到指定位置去查找这些文件。前面已经说了Maven默认的处理方式，但是有时候我们需要进行自定义的配置，比如下面两种情况：

* 有的时候有些配置文件通常与`.java`文件一起放在`src/main/java`目录（如mybatis或hibernate的表映射文件）。
* 有的时候还希望把其他目录中的资源也复制到`classes`目录中。这些情况下就需要在`pom.xml`文件中修改配置了。

目前主要有如下两种方法修改配置：

* 一种是在`<build>`元素下添加`<resources>`进行配置。

```
<build>
    ......
      <resources>
        <resource>
            <directory>src/main/resources</directory>
            <excludes>
                <exclude>**/*.properties</exclude>
                <exclude>**/*.xml</exclude>
            </excludes>
            <filtering>false</filtering>
        </resource>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.properties</include>
                <include>**/*.xml</include>
            </includes>
            <filtering>false</filtering>
        </resource>
    </resources>
    ......
</build>
```

* 另一种是在`<build>`的`<plugins>`子元素中配置`maven-resources-plugin`等处理资源文件的插件。

```
<plugin>
    <artifactId>maven-resources-plugin</artifactId>
    <version>2.5</version>
    <executions>
        <execution>
            <id>copy-xmls</id>
            <phase>process-sources</phase>
            <goals>
                <goal>copy-resources</goal>
            </goals>
            <configuration>
                <outputDirectory>${basedir}/target/classes</outputDirectory>
                <resources>
                    <resource>
                        <directory>${basedir}/src/main/java</directory>
                        <includes>
                            <include>**/*.xml</include>
                        </includes>
                    </resource>
                </resources>
            </configuration>
        </execution>
    </executions>
</plugin>
```

`resources`元素与`maven-resources-plugin`插件一般都是搭配在一起使用实现复杂的资源文件处理逻辑。

默认情况下，Maven会从项目的`src/main/resources`目录下查找资源。如果你的资源不在此目录下，可以用`<resources>`标签指定，同时也支持多个目录，也支持`<include>,<exclude>`之类的精细化配置。

```
<resources>
	<resource>
		<directory>src/main/resources1</directory>
	</resource>
	<resource>
		<directory>src/main/resources2</directory>
	</resource>
</resources>
```

有的时候，资源文件中存在变量引用，可以使用`<filtering>`标签指定是否替换资源中的变量。变量的来源默认为pom文件中的`<project>根元素下的<properties>`标签或`<profile>下的<properties>`标签中定义的变量；当然也可以在`<build>`中定义过滤器资源。

```
<project>
    <properties>
     ......
    </properties>
    
    <build>
        <!-- 自定义过滤器资源文件 -->
        <filters>
            <filter>filter-values.properties</filter>
    	   </filters>
    	   <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
    </build>
    
    <profiles>
        <profile>
            ......
        </profile>
    </profiles>
</project>
```

如果资源中本来存在不需要被替换的`${}`字符，则可以在`$`前加`\`，同时在`maven-resources-plugin`插件配置的`<configuration>`中使用`<escapeString>`；若目录下存在二进制文件，则需要通过以下的后缀名来排除。

```
<plugin>
	<artifactId>maven-resources-plugin</artifactId>
	<version>3.0.2</version>
	<configuration>
	   <!-- 配置资源文件中的转义字符 -->
		<escapeString>\</escapeString>
		<encoding>UTF-8</encoding>
		<!-- 如目录下存在二进制文件，则需要通过以下的后缀名来排除 -->
		<nonFilteredFileExtensions>
			<nonFilteredFileExtension>pdf</nonFilteredFileExtension>
			<nonFilteredFileExtension>swf</nonFilteredFileExtension>
		</nonFilteredFileExtensions>
	</configuration>
</plugin>
```

如果你需要在其他阶段拷贝资源文件，可以使用插件目标copy-resources，类似配置如下：

```
<plugin>
    <artifactId>maven-resources-plugin</artifactId>
    <version>3.0.2</version>
    <executions>
      <execution>
        <id>copy-resources</id>
        <phase>validate</phase>
        <goals>
            <goal>copy-resources</goal>
        </goals>
        <configuration>
            <outputDirectory>${basedir}/target/extra-resources</outputDirectory>
            <resources>          
                <resource>
                    <directory>src/non-packaged-resources</directory>
                    <filtering>true</filtering>
                </resource>
            </resources>              
        </configuration>            
      </execution>
    </executions>
</plugin>
```

> 更详细的配置请参考[`maven-resources-plugin`插件官网](http://maven.apache.org/plugins/maven-resources-plugin/)

简单总结：resources及其对应的插件的作用就是用于资源文件的处理（变量替换、编译时资源文件复制等），为后续的项目打包阶段作准备。

> 一定要注意与`maven-assemble-plugin`插件区别开来，因为`assemble`也涉及到配置文件的拷贝。

### 2.3. `plugin`节点
* 介绍

#### 2.3.1. 常用插件
* maven-resources-plugin

* maven-compiler-plugin

* maven-surefire-plugin

* maven-jar-plugin

* maven-war-plugin

* maven-source-plugin

* maven-assembly-plugin

* maven-dependency-plugin

* maven-failsafe-plugin

* maven-enforcer-plugin

* spring-boot-maven-plugin

## 3. profile配置
> 通过profile中定义的property，基于工程中的properties模板生成最终的properties文件。

## 4. 实战案例
> 使用Maven搭建一个基于SpringBoot的工程介绍，及搭建过程中踩过的坑。

* 使用`import scope`引入`spring-boot-dependencies`时无法引用POM中定义的property、pluginManagement等一系列[问题][2]



> 转载请注明出处：[simiam.com][1]

[1]: https://simiam.com
[2]: https://stackoverflow.com/questions/40606267/how-does-importing-maven-dependencies-impact-plugin-management
[3]: http://www.infoq.com/cn/maven-practice
[4]: https://www.amazon.cn/dp/B009WMAZX4


