title: VUE学习笔记：环境准备
date: 2018-08-17 09:39:43
tags: [vue,npm]
categories: [前端]
keywords: [npm,vue,node,前端开发]
---


> 转载请注明出处：[simiam.com][1]

# 1. Node

Node是JavaScript语言的服务器运行环境。

所谓“运行环境”有两层意思：首先，JavaScript语言通过Node在服务器运行，在这个意义上，Node有点像JavaScript虚拟机；其次，Node提供大量工具库，使得JavaScript语言与操作系统互动（比如读写文件、新建子进程），在这个意义上，Node又是JavaScript的工具库。

Node内部采用Google公司的V8引擎，作为JavaScript语言解释器；通过自行开发的libuv库，调用操作系统资源。

## 1.1. 安装与更新

* 安装方式一：访问官方网站nodejs.org或者github.com/nodesource/distributions，查看Node的最新版本和安装方法。
* 安装方式二：通过官方网站提供编译好的各平台下的二进制包，可以把它们解压到/usr/local/lib/nodejs目录下面，具体过程如下：

<!--More-->

```
# 如macOS下的二进制包
sudo mkdir -p /usr/local/lib/nodejs
sudo cd /usr/local/lib/nodejs
sudo wget https://nodejs.org/dist/v10.15.3/node-v10.15.3-darwin-x64.tar.gz
sudo tar -zxvf node-v10.15.3-darwin-x64.tar.gz

# 设置环境变量，如在~/.profile文件末尾增加如下内容：
export PATH=/usr/local/lib/nodejs/node-v10.15.3-darwin-x64/bin:$PATH

# 执行如下命令使配置生效：
. ~/.profile

# 测试安装是否成功
node -v
npm version
npx -v

```

* 更新方式：更新node.js版本，可以通过node.js的n模块完成，具体过程如下：

```
# 通过npm安装n模块
sudo npm install n -g

# 通过n模块，将node.js更新为最新发布的稳定版
sudo n stable

# n模块也可以指定安装特定版本的node
sudo n 10.10.21
```

## 1.2. 基本用法

* 安装环境搭建完成后，运行node.js程序，其实就是使用node命令读取解析执行JavaScript脚本。比如当前目录存在一个`demo.js`脚本文件，可以这样执行：

```
$ node demo
# 或者
$ node demo.js
```

* 使用`-e`参数，可以执行代码字符串：

```
$ node -e 'console.log("Hello World")'
# 执行输出结果为：Hello World
```

## 1.3. REPL环境

> REPL是Node.js与用户互动的shell，各种基本的shell功能都可以在里面使用，比如使用上下方向键遍历曾经使用过的命令。

在命令行键入node命令，后面没有文件名，就进入一个Node.js的REPL环境（Read–eval–print loop，”读取-求值-输出”循环），可以直接运行各种JavaScript命令：

```
$ node
> 1+1
2
>

# 特殊变量下划线（_）表示上一个命令的返回结果
> _ + 1
3

# 在REPL中，如果运行一个表达式，会直接在命令行返回结果。如果运行一条语句，就不会有任何输出，因为语句没有返回值。
# 如下面代码的第二条命令，没有显示任何结果。因为这是一条语句，不是表达式，所以没有返回值

> x = 1
1
> var x = 1

```


# 2. 模块包管理器npm

npm是Node的模块管理器，功能极其强大，它是Node获得成功的重要原因之一。npm是随node一起发布安装的，不需要单独安装。正因为有了npm，我们只要使用如下一行命令，就能安装或更新别人写好的模块。

```
# 安装新模块
sudo npm install module_name@version [-g]
# 更新新模块
sudo npm update module_name@version [-g]
```
参数选项`-g`代表是全局安装，即会安装到`/usr/local/lib/node_modules`目录下，如果不加则为本地安装，会将模块安装在当前目录的`node_modules`目录下。

## 2.1. npm自身版本更新
因为在安装Node的时候，会连带一起安装npm。但是Node附带的npm可能不是最新版本，最好用下面的命令，更新到最新版本。

```
$ npm install npm@latest -g
```

上面的命令中，@latest表示最新版本，-g表示全局安装。所以，命令的主干是npm install npm，也就是使用npm安装自己。之所以可以这样，是因为npm本身与Node的其他模块没有区别，其本质上也是一个node模块，因此可以通过npm命令来进行版本更新。

然后，运行下面的命令，查看各种信息。

```
# 查看 npm 命令列表
$ npm help

# 查看各个命令的简单用法
$ npm -l

# 查看 npm 的版本
$ npm -v

# 查看 npm 的配置
$ npm config list -l
```

# 3. 版本管理工具nvm

如果想在同一台机器，同时安装多个版本的node.js，就需要用到版本管理工具nvm。

## 3.1. 安装与更新

```
$ git clone https://github.com/creationix/nvm.git ~/.nvm
$ source ~/.nvm/nvm.sh
```

安装以后，nvm的执行脚本，每次使用前都要激活，建议将其加入`~/.bashrc`文件（假定使用Bash）。激活后，就可以安装指定版本的Node，命令如下：

```
# 安装最新版本
$ nvm install node

# 安装指定版本
$ nvm install 0.12.1

# 使用已安装的最新版本
$ nvm use node

# 使用指定版本的node
$ nvm use 0.12
```

nvm也允许进入指定版本的`REPL`环境（Read–eval–print loop，”读取-求值-输出”循环）：

> REPL是Node.js与用户互动的shell，各种基本的shell功能都可以在里面使用，比如使用上下方向键遍历曾经使用过的命令。

```
$ nvm run 0.12
```

如果在项目根目录下新建一个`.nvmrc`文件，将版本号写入其中，就只输入`nvm use`命令即可，不再需要附加版本号。

下面是其他经常用到的nvm使用命令：

```
# 查看本地安装的所有版本
$ nvm ls

# 查看服务器上所有可供安装的版本。
$ nvm ls-remote

# 退出已经激活的nvm，使用deactivate命令。
$ nvm deactivate
```

# 参考文献

* [npm模块管理器][2]
* [npm模块安装机制简介][3]
* [npx使用教程][4]


> 转载请注明出处：[simiam.com][1]

[1]: http://simiam.com
[2]: http://javascript.ruanyifeng.com/nodejs/npm.html
[3]: http://www.ruanyifeng.com/blog/2016/01/npm-install.html
[4]: http://www.ruanyifeng.com/blog/2019/02/npx.html



