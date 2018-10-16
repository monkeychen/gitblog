title: Maven学习笔记
date: 2018-10-11 09:51:31
tags: [Maven,SpringBoot]
categories: [Java]
keywords: [Maven,SpringBoot]
---
# Maven学习笔记
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


<!--More-->

## 2. Maven构建配置
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

### 2.2. 资源处理相关配置
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

### 2.3. 测试相关插件配置
本文章所讲的测试主要是指单元测试与集成测试：

* Maven通过`maven-surefire-plugin`插件执行单元测试
* Maven通过`maven-failsafe-plugin`插件执行集成测试

#### 2.3.1. 单元测试配置
在pom.xml中配置JUnit，TestNG测试框架的依赖，即可自动识别和运行`src/test/Java`目录下利用该框架编写的测试用例。常用配置如下：

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>2.18.1</version>
    <configuration>
        <!-- 在构建过程中如需要跳过单元测试阶段，则将skipTests节点值设置为true -->
        <skipTests>true</skipTests>
        
        <!-- 忽略测试失败以继续构建项目，不推荐 -->
        <testFailureIgnore>true</testFailureIgnore>
    </configuration>
</plugin>
```

想跳过单元测试还可以使用如下方式：

```
# 方式一：不执行测试用例，但编译测试用例类生成相应的class文件至target/test-classes下
mvn install -DskipTests

# 方式二：不执行测试用例，也不编译测试用例类
mvn install -Dmaven.test.skip=true
```

当然，如果你明确用的是`JUnit4.7`及以上版本，可以明确声明：

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>2.19</version>
    <dependencies>
        <dependency>
            <groupId>org.apache.maven.surefire</groupId>
            <artifactId>surefire-junit47</artifactId>
            <version>2.19</version>
        </dependency>
    </dependencies>
</plugin>
```

surefire默认的查找测试类的模式如下：

* `**/Test*.java`
* `**/*Test.java`
* `**/*TestCase.java`

如果由于历史原因，测试类不符合默认的三种命名模式，可以通过pom.xml设置`maven-surefire-plugin`插件添加命名模式或排除一些命名模式。

```
<plugin>  
    <groupId>org.apache.maven.plugins</groupId>  
    <artifactId>maven-surefire-plugin</artifactId>  
    <version>2.5</version>  
    <configuration>  
        <includes>  
            <include>**/*Tests.java</include>  
        </includes>  
        <excludes>  
            <exclude>**/*ServiceTest.java</exclude>  
            <exclude>**/TempDaoTest.java</exclude>  
        </excludes>  
    </configuration>  
</plugin>
```

> 更详细的配置可直接参考[surefire插件官网](http://maven.apache.org/surefire/maven-surefire-plugin/)

#### 2.3.2. 集成测试配置

集成测试过程涉及运行环境准备，如启动tomcat容器等。而单元测试插件有一个特征是如果有一个单元测试用例失败，则会中止整个Maven构建过程，此时会导致之前创建的集成测试环境如tomcat容器未能及时关闭，因此便有了failsafe的用武之地。

Maven构建生命周期中有四个阶段与集成测试有关:

* pre-integration-test：准备集成测试环境
* integration-test：进行正式的集成测试
* post-integration-test：清理集成测试环境
* verify：检查集成测试结果

当failsafe插件在构建过程的`integration-test`或`verify`阶段被调用而进行集成测试时，测试用例执行过程中就算失败也不会中止构建过程，而会继续执行`post-integration-test`阶段以进行环境清理操作。

`maven-failsafe-plugin`插件需要与各种容器插件搭配使用，常用的容器类插件有：tomcat，jetty或者更高级的cargo等。

```
<plugins>
  <!--指定单元测试不执行 否则先执行单元测试 地址不通-->
  <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>2.18</version>
    <configuration>
      <skip>true</skip>
    </configuration>
  </plugin>
  <!--集成测试的插件配置-->
  <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>2.19.1</version>
    <configuration>
      <suiteXmlFiles>
        <!--指定配置文件-->
        <suiteXmlFile>testng.xml</suiteXmlFile>
      </suiteXmlFiles>
    </configuration>
    <executions>
      <execution>
        <id>integration-tests</id>
        <goals>
          <goal>integration-test</goal>
          <goal>verify</goal>
        </goals>
      </execution>
    </executions>
  </plugin>
  <!--tomcat插件-->
  <plugin>
    <groupId>org.apache.tomcat.maven</groupId>
    <artifactId>tomcat7-maven-plugin</artifactId>
    <version>2.2</version>
    <!--部署的端口和配置-->
    <configuration>
      <port>8080</port>
      <path>/</path>
    </configuration>
    <executions>
      <!--什么时候启动 什么时候终止-->
      <execution>
        <id>tomcat-run</id>
        <goals>
          <goal>run-war-only</goal>
        </goals>
        <phase>pre-integration-test</phase>
        <configuration>
          <fork>true</fork>
        </configuration>
      </execution>
      <execution>
        <id>tomcat-shutdown</id>
        <goals>
          <goal>shutdown</goal>
        </goals>
        <phase>post-integration-test</phase>
      </execution>
    </executions>
  </plugin>
</plugins>
```

> 更详细的配置可直接参考[failsafe插件官网](https://maven.apache.org/surefire/maven-failsafe-plugin/index.html)

### 2.4. 打包相关配置
Maven中的打包类型有：jar包、war包以及zip等方便部署的压缩包。

#### 2.4.1. 打Jar包相关配置
Jar包又可分为普通的jar包、可执行jar包。前者通过`maven-jar-plugin`插件就能搞定。对于打可执行的jar包有多种方式：

* 使用`maven-jar-plugin`和`maven-dependency-plugin`插件打包

```
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-jar-plugin</artifactId>
	<version>2.6</version>
	<configuration>
		<archive>
			<manifest>
            <!-- 在MANIFEST.MF加上Class-Path项并配置依赖包 -->
            <addClasspath>true</addClasspath>
            <!-- 指定依赖包所在目录 -->
            <classpathPrefix>lib/</classpathPrefix>
            <mainClass>com.simiam.Main</mainClass>
            <manifestEntries>
                <!-- 将当前目录也加入到classpath中 -->
                <Class-Path>./</Class-Path>
            </manifestEntries>
			</manifest>
		</archive>
	</configuration>
</plugin>
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-dependency-plugin</artifactId>
	<version>2.10</version>
	<executions>
		<execution>
			<id>copy-dependencies</id>
			<phase>package</phase>
			<goals>
				<goal>copy-dependencies</goal>
			</goals>
			<configuration>
				<outputDirectory>${project.build.directory}/lib</outputDirectory>
			</configuration>
		</execution>
	</executions>
</plugin>
```

上述配置所生成的MANIFEST.MF文件中将包含如下内容：

```
Class-Path: lib/commons-logging-1.2.jar lib/commons-io-2.4.jar
Main-Class: com.simiam.Main
```

`maven-jar-plugin`插件只是生成MANIFEST.MF文件，`maven-dependency-plugin`插件用于将依赖包拷贝到`<outputDirectory>${project.build.directory}/lib</outputDirectory>`指定的位置，即`target/lib`目录下。

这种打包方式可以实现依赖的jar包与自研jar包分开，但配置相关的资源文件也被打进jar包中，后续想修改配置信息将很头痛，同时这种打包方式无法解决部署文件目录结构复杂的场景。

> 延伸阅读：`configuration`下的`classifier`节点的作用是什么？在以前的插件版本中会存在`excludes`配置项不生效的问题，目前这个问题已不存在；如果出现这个问题，那一般是默认的执行目标不对导致（`mvn package的运行日志中maven-jar-plugin会执行两次，但目标不一样，分别为default-jar, default`）。

* 使用`maven-assembly-plugin`插件打包

```xml
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-assembly-plugin</artifactId>
	<version>2.5.5</version>
	<executions>
    <execution>
        <phase>package</phase>
        <goals>
            <goal>single</goal>
        </goals>
    </execution>
   </executions>
	<configuration>
		<archive>
			<manifest>
				<mainClass>com.simiam.Main</mainClass>
			</manifest>
		</archive>
		<descriptorRefs>
			<descriptorRef>jar-with-dependencies</descriptorRef>
		</descriptorRefs>
	</configuration>
</plugin>
```

这种打包方式会将所有依赖的jar包中的内容抽取出来，并与自研的代码合在一起打在同一个Jar包中。不过，如果项目使用了SPI机制，且多个依赖中都有SPI实现类，则用这种方式打出来的包会因为相互覆盖问题导致运行时的不确定性甚至出错。比如项目中用到了`Spring Framework`，将依赖打到一个jar包中，运行时会出现读取`XML schema`文件出错。原因是`Spring Framework`的多个jar包中包含相同的文件`spring.handlers`和`spring.schemas`，如果生成一个jar包会互相覆盖。此时可以借助`maven-shade-plugin`插件来解决这个问题。

使用`maven-shade-plugin`插件解决Spring应用打包覆盖问题的配置如下：

``` 
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-shade-plugin</artifactId>
	<version>2.4.1</version>
	<executions>
		<execution>
			<phase>package</phase>
			<goals>
				<goal>shade</goal>
			</goals>
			<configuration>
				<transformers>
					<transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
						<mainClass>com.simiam.Main</mainClass>
					</transformer>
					<transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
						<resource>META-INF/spring.handlers</resource>
					</transformer>
					<transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
						<resource>META-INF/spring.schemas</resource>
					</transformer>
				</transformers>
			</configuration>
		</execution>
	</executions>
</plugin>
```

* 使用`maven-jar-plugin`和`maven-assembly-plugin`插件打包

之前有提过，用`maven-jar-plugin`与`maven-dependences-plugin`插件打包时，配置相关的资源文件也被打进jar包中，后续想修改配置信息将很头痛，同时这种打包方式无法解决部署文件目录结构复杂的场景。因此就有了使用`maven-jar-plugin`和`maven-assembly-plugin`插件打包的方式。

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <version>2.6</version>
    <configuration>
        <archive>
            <manifest>
                <mainClass>com.simiam.HttpIpv6StatisticTaskLauncher</mainClass>
                <addClasspath>true</addClasspath>
                <classpathPrefix>lib/</classpathPrefix>
            </manifest>
            <manifestEntries>
                <Class-Path>.</Class-Path>
            </manifestEntries>
        </archive>
        <excludes>
            <!-- **表示0到N级目录，即包括conf目录 -->
            <exclude>conf/**/*.properties</exclude>
        </excludes>
    </configuration>
</plugin>
<plugin>
    <artifactId>maven-assembly-plugin</artifactId>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <appendAssemblyId>false</appendAssemblyId>
        <descriptors>
            <descriptor>src/main/assembly/package.xml</descriptor>
        </descriptors>
    </configuration>
</plugin>
```

里面的关键就是`package.xml`这个文件了，它告诉插件具体应该如何组织打包等。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3 http://maven.apache.org/xsd/assembly-1.1.3.xsd">
    <id>package</id>
    <formats>
        <format>zip</format>
    </formats>
    <includeBaseDirectory>true</includeBaseDirectory>
    <fileSets>
        <fileSet>
            <directory>src/main/resources</directory>
            <outputDirectory>/</outputDirectory>
        </fileSet>
        <fileSet>
            <directory>${project.build.directory}</directory>
            <outputDirectory>/</outputDirectory>
            <includes>
                <include>*.jar</include>
            </includes>
        </fileSet>
    </fileSets>
    <dependencySets>
        <dependencySet>
            <outputDirectory>lib</outputDirectory>
            <excludes>
                <!-- <exclude>${project.name}-${project.version}</exclude> -->
                <exclude>${groupId}:${artifactId}</exclude>
            </excludes>
        </dependencySet>
    </dependencySets>
</assembly>

```

> `maven-assembly-plugin`插件的详细介绍见[官网][8]。

* 使用`maven-assembly-plugin`插件和shell脚本打包

当然借助`maven-assembly-plugin`插件与shell脚本配合也可以实现上面的功能，但相对复杂一些；能用上一种方式解决的就不要用shell在代替`maven-jar-plugin`插件的功能。这里简单提供示例的shell脚本与bat脚本。

> 脚本来源：`~/workspace/Java/news-recommend/recommend-sys/news-recommend/recommend-osf`

**shell脚本**

```bash
#!/bin/bash
cd `dirname $0`
BIN_DIR=`pwd`
cd ..
DEPLOY_DIR=`pwd`
LOGS_DIR=""
if [ -n "$LOGS_FILE" ]; then
    LOGS_DIR=`dirname $LOGS_FILE`
else
    LOGS_DIR=$DEPLOY_DIR/logs
fi
if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
fi
STDOUT_FILE=$LOGS_DIR/stdout.log
JVM_ERR_FILE=" -XX:ErrorFile=$DEPLOY_DIR/hs_err_pid%p.log "

CONF_DIR=$DEPLOY_DIR/conf
LIB_DIR=$DEPLOY_DIR/lib
LIB_JARS=`ls $LIB_DIR|grep .jar|awk '{print "'$LIB_DIR'/"$0}'|tr "\n" ":"`

JAVA_DEBUG_OPTS=""
if [ "$1" = "debug" ]; then
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n "
fi
JAVA_JMX_OPTS=""
if [ "$1" = "jmx" ]; then
    JAVA_JMX_OPTS=" -Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=localhost -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
fi
JAVA_MEM_OPTS=""
BITS=`java -version 2>&1 | grep -i 64-bit`
if [ -n "$BITS" ]; then
    JAVA_MEM_OPTS=" -server -Xmx4g -Xms4g -XX:NewRatio=1 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m -Xss256k -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/wwwroot/news-recommend-osf/ "
else
    JAVA_MEM_OPTS=" -server -Xms1g -Xmx1g -XX:PermSize=128m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
fi

cd $BIN_DIR

nohup java $JAVA_OPTS $JAVA_MEM_OPTS $JVM_ERR_FILE $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS -classpath $BIN_DIR:$CONF_DIR:$LIB_JARS com.simiam.recommend.osf.RecommendOsfLauncher > $STDOUT_FILE 2>&1 &
echo "JAVA_JMX_OPTS: $JAVA_JMX_OPTS"
echo "OK!"
PIDS=`ps -f | grep java | grep "$DEPLOY_DIR" | awk '{print $2}'`
echo "PID: $PIDS"
echo "STDOUT: $STDOUT_FILE"
```

**bat脚本**

```bat
@echo off & setlocal enabledelayedexpansion

set LIB_JARS=""

cd ..\lib
for %%i in (*) do set LIB_JARS=!LIB_JARS!;..\lib\%%i

cd ..\bin

if ""%1"" == ""debug"" goto debug
if ""%1"" == ""jmx"" goto jmx

java -Xms64m -Xmx1024m -XX:MaxPermSize=64M -cp ..\conf;%LIB_JARS% com.simiam.recommend.osf.RecommendOsfLauncher
goto end

:debug
java -Xms64m -Xmx1024m -XX:MaxPermSize=64M -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n -cp ..\conf;%LIB_JARS% com.simiam.recommend.osf.RecommendOsfLauncher
goto end

:jmx
java -Xms64m -Xmx1024m -XX:MaxPermSize=64M -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -cp ..\conf;%LIB_JARS% com.simiam.recommend.osf.RecommendOsfLauncher
goto end

:end
pause
```

#### 2.4.2. 打War包相关配置
打war包的核心插件为`maven-war-plugin`，因为war包不涉及配置文件独立配置问题，同时其目录结构需要符合servlet规范，因此其打包方式相对简单，基本上只要参考[官网][9]即可。如果说非要注意的无非就以下一点：

* 由于`servlet3.0`及以上版本的来说，工程中可以不提供web.xml文件，如果用`maven-war-plugin`插件的旧版本（3.0.0版本以下）在打包时会报找不到web.xml文件而中止打包，在这种情况下需要在插件配置节点中设置`<failOnMissingWebXml>false</failOnMissingWebXml>`，举例如下：

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-war-plugin</artifactId>
    <version>2.6</version>
    <configuration>
        <failOnMissingWebXml>false</failOnMissingWebXml>
        <!-- 使用web.xml文件路径 -->
        <webXml>src/config/dev/web.xml</webXml>

        <!-- 将某些需要的文件拷贝到WEB-INF下 -->
        <webResources>
            <resource>
                <directory>src/config/dev</directory>
                <targetPath>WEB-INF</targetPath>
                <includes>
                    <include>**/*.xml</include>
                </includes>
            </resource>
        </webResources>
    </configuration>
</plugin>
```

### 2.5.. 依赖分析相关配置

我们会经常碰到这样的问题，在pom中引入了一个jar，里面默认依赖了其他的jar包。jar包一多的时候，我们很难确认哪些jar是我们需要的，哪些jar是冲突的。此时会出现很多莫名其妙的问题，什么类找不到啦，方法找不到啦，这种可能的原因就是jar的版本不是我们所设想的版本，但是我们也不知道低版本的jar是从哪里引入的。此时就出现`maven-enforcer-plugin`插件，其正是用于排查及解决此问题的有力工具。

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-enforcer-plugin</artifactId>
    <version>1.4.1</version>
    <executions>
        <execution>
            <id>enforce</id>
            <configuration>
                <rules>
                    <dependencyConvergence/>
                </rules>
            </configuration>
            <goals>
                <goal>enforce</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

在进行mvn clean package的时候，会在console中打印出来冲突的jar版本和其父pom，如下：

```
Dependency convergence error for org.slf4j:slf4j-api1.6.1 paths to dependency are:
 
[ERROR]
Dependency convergence error for org.slf4j:slf4j-api:1.6.1 paths to dependency are:
+-org.myorg:my-project:1.0.0-SNAPSHOT
  +-org.slf4j:slf4j-jdk14:1.6.1
    +-org.slf4j:slf4j-api:1.6.1
and
+-org.myorg:my-project:1.0.0-SNAPSHOT
  +-org.slf4j:slf4j-nop:1.6.0
    +-org.slf4j:slf4j-api:1.6.0
```

这个时候，我们看一眼就知道应该把哪个`dependency`中的哪个jar进行`exclude`。

> 插件详细配置说明见[插件官网](http://maven.apache.org/enforcer/enforcer-rules/index.html)

### 2.6. SpringBoot插件配置

因为`spring-boot-maven-plugin`插件已经为我们准备了一切，如果无特别需求，我们基本只需要简单引入即可：

```
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <mainClass>com.simiam.PerfHttpIpv6App</mainClass>
    </configuration>
</plugin>

<!-- 因为spring-boot-maven-plugin未提供源码打包插件，所以我们需要自己添加 -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-source-plugin</artifactId>
    <version>3.0.1</version>
    <executions>
        <execution>
            <id>attach-sources</id>
            <phase>verify</phase>
            <goals>
                <goal>jar-no-fork</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### 2.7. 小结
还有非常多的插件，就不在这里一一介绍了，各位可以直接看[官网](https://maven.apache.org/plugins/index.html)

* maven-shade-plugin
* maven-dependences-plugin
* exec-maven-plugin
* ......

## 3. profile配置

> 通过profile中定义的property，基于工程中的properties模板生成最终的properties文件。
> [利用profile实现多环境配置文件打包问题][6]

### 什么是profile配置？
profile是一组配置的集合，用来设置或者覆盖Maven构建的默认配置。通过profile配置，可以为不同的环境定制构建过程，例如`Producation`和`Development`环境。

Profile在pom.xml中使用`activeProfiles或profiles`元素指定，并且可以用很多方式触发。Profile 在构建时修改POM，并且为变量设置不同的目标环境（例如，在开发、测试和产品环境中的数据库服务器路径）。

### Profile目前主要有三种类型：

| 类型 | 在哪里定义 |
| --- | --- |
| Per Project | 定义在工程pom.xml中 |
| Per User | 定义在Maven设置xml文件中（%USER_HOME%/.m2/settings.xml） |
| Global | 定义在Maven全局配置xml文件中（%M2_HOME%/conf/settings.xml） |

### Profile激活方式

Maven的Profile能够通过几种不同的方式激活：

* 显式使用命令控制台输入

```bash
# dev是profile的ID
mvn install -Pdev 
```

* 通过maven设置

```xml
# 在setting.xml文件中添加如下信息，setting.xml位于上节介绍的三种profile类型的相应位置下。
<activeProfiles>
    <activeProfile>dev</activeProfile>
</activeProfiles>
```

以下三种激活方式不常用，这里不作进一步介绍，有需要的请直接参考[这里](http://wiki.jikexueyuan.com/project/maven/build-profiles.html)。

* 基于环境变量（用户/系统变量）
* 操作系统配置（例如，Windows family）
* 现存/缺失文件

> **注意：**profile节点下`<properties>`中定义的属性值会覆盖其所在pom文件中定义的同名的全局属性。

### Spring框架的profile机制与Maven的profile机制的区别

* Spring框架提供的profile机制主要作用于运行时，即应用程序在运行时使用spring提供的profile相关机制来决定应用程序的各种动态行为。
* Maven的profile机制则作用于构建时期，其通常用于生成各种环境（开发、测试、生产）下的与配置相关的资源文件，而这些生成的不同环境的配置文件在应用程序在相应环境下运行时所需要的。
* 这两个Profile机制是可以配合使用以实现不同环境下从构建到部署的全程控制。

比如对于springboot项目来说，可通过maven的profile中添加env属性：

```
<profile>
    <id>dev</id>
    <properties>
        <env>dev</env>
    </properties>
</profile>
```

当运行`mvn install -Pdev`时，会复制`src/main/resources/application.yml`模板文件复制至目标目录下，并将其中的`spring.profiles.active: ${env}` 配置项的`${env}`占位符替换成`dev`。

```
server:
  port: 8080
  servlet:
    context-path: /perf

spring:
  profiles:
    active: ${env}  # 将被替换成目标profile的env属性值
  datasource:
    name: perf-ds
    type: com.alibaba.druid.pool.DruidDataSource
    driver-class-name: org.postgresql.Driver
    druid:
      filters: stat
      maxActive: 20
      initialSize: 1
      maxWait: 60000
      minIdle: 1
      timeBetweenEvictionRunsMillis: 60000
      minEvictableIdleTimeMillis: 300000
      testWhileIdle: true
      testOnBorrow: false
      testOnReturn: false
      poolPreparedStatements: true
      maxOpenPreparedStatements: 20

mybatis:
  mapper-locations: classpath:mapping/*.xml
  type-aliases-package: com.simiam.http.entity

pagehelper:
  helperDialect: postgresql
  reasonable: true
  supportMethodsArguments: true
  params: count=countSql

---

spring:
  profiles: dev
  datasource:
    url: jdbc:postgresql://localhost:5432/perf?currentSchema=dev
    username: *****
    password: *****

---

spring:
  profiles: prod
  datasource:
    url: jdbc:postgresql://localhost:5432/perf?currentSchema=prod
    username: *****
    password: *****
```

最终生成的`application.yml`将被springboot应用程序使用，其会根据激活的profile选择对应的配置项，连接对应的数据库实例。


## 4. 其它常见问题汇总

> 本节主要记录日常开发工作中使用maven所挖过、踩过、填过的坑。（不断更新）

* 使用`import scope`引入`spring-boot-dependencies`时无法引用POM中定义的property、pluginManagement等一系列[问题][2]



> 转载请注明出处：[simiam.com][1]

[1]: https://simiam.com
[2]: https://stackoverflow.com/questions/40606267/how-does-importing-maven-dependencies-impact-plugin-management
[3]: http://www.infoq.com/cn/maven-practice
[4]: https://www.amazon.cn/dp/B009WMAZX4
[5]: http://maven.apache.org/plugins/index.html
[6]: https://blog.csdn.net/DERRANTCM/article/details/71600274
[7]: http://www.voidcn.com/article/p-rvsxmzwk-mt.html
[8]: http://maven.apache.org/plugins/maven-assembly-plugin/
[9]: https://maven.apache.org/plugins/maven-war-plugin/



