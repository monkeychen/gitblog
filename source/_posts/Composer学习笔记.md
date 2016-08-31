title: Composer学习笔记
date: 2016-09-01 00:01:12
tags: [Composer]
keywords: [Composer]
---
#Composer学习笔记

## 一、安装(MacOS)
> 系统要求：PHP5.3.2+以上版本
> 学习参考：[Composer官方文档][1]

Composer安装分两种：
### 1.局部安装
将`composer.phar`文件内嵌于PHP应用目录下，命令如下：
```
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
```
> 以上命令分别做如下几件事件：
> * 下载安装器
> * 校验
> * 执行安装
> * 删除安装器

安装完成后，会在当前工作目录下生成可执行文件：`composer.phar`，你可以通过如下方式使用（运行）composer来进行项目的依赖管理：
```
php composer.phar <command>
# command指install等composer命令
```
<!--more-->
### 2.全局安装
将可执行二进制文件放在系统PATH路径下，命令如下：
```
# 假设局部安装中生成的composer.phar文件在当前目录下
# /usr/local/bin/目录是一个现成的PATH目录，
# 你也可以将可执行文件放置于其他PATH目录下
mv composer.phar /usr/local/bin/composer
```
通过这种方式，你就可以直接按如下方式来使用composer：
```
composer <command>
# command指install等composer命令
```
## 二、基本概念
### 1. composer.json文件

每个基于Composer的项目都需要包含`composer.json`文件，该文件用于声明项目所依赖的第三方库，其为JSON文件，格式类似：
```
{
       	"require": {
       		"monolog/monolog": "1.2.*"
       	}
}
```
> require属性是用于声明依赖信息的地方。

当运行`composer install`安装依赖时，Composer会将依赖库下载到项目根目录的`vendor`目录下。如monolog依赖安装后，其存放在`vendor\monolog\monolog`目录下。

### 2. composer.lock文件

当执行如下命令安装依赖后，Composer将会在项目目录下创建`composer.lock`文件。
```
composer install
```
> Composer将把安装时确切的版本号列表写入`composer.lock`文件。这将锁定改项目的特定版本。
> 后续再次运行`composer install`时，Composer将先检查目录下是否有`composer.lock`，若有则直接忽略`composer.json`，而使用`composer.lock`中的确切的版本信息。团队成员可以共享该lock文件以解决版本不一致问题。
> 当依赖版本有升级时，若想更新依赖至最新版本可以运行如下命令
```
# 全部更新
composer update
# 只更新某个依赖库
composer update monolog/monolog [...]
```
### 3. 自动加载

对于库的自动加载信息，Composer 生成了一个`vendor/autoload.php`文件。通过引入这个文件，就实现了自动加载功能。
```
require 'vendor/autoload.php';
```
通过自动加载功能我们可以很容易的使用第三方代码。例如：项目依赖monolog，我们就可以像这样开始使用这个类库，并且他们将被自动加载。
```
$log = new Monolog\Logger('name');
$log->pushHandler(new Monolog\Handler\StreamHandler('app.log', Monolog\Logger::WARNING));

$log->addWarning('Foo');
```
当然，我们也可以在`composer.json`的`autoload`字段中增加自己的`autoloader`。
```
{
    "autoload": {
        "psr-4": {"Acme\\": "src/"}
    }
}
```
Composer将注册一个`PSR-4 autoloader`到`Acme`命名空间。

你可以定义一个从命名空间到目录的映射。此时src会在你项目的根目录，与`vendor`文件夹同级。例如`src/Foo.php`文件应该包含`Acme\Foo`类。

添加`autoload`字段后，你应该再次运行`install`命令来生成 `vendor/autoload.php`文件。

引用这个文件也将返回`autoloader`的实例，你可以将包含调用的返回值存储在变量中，并添加更多的命名空间。这对于在一个测试套件中自动加载类文件是非常有用的，例如：
```
$loader = require 'vendor/autoload.php';
$loader->add('Acme\\Test\\', __DIR__);
```

## 三、库


未完[待续][2]

[1]: https://getcomposer.org/doc/
[2]: https://getcomposer.org/doc/02-libraries.md
