title: MAC下搭建Apache+PHP开发环境
date: 2016-07-01 23:18:57
tags: [php,apache2]
categories: [Php]
keywords: [php,apache2,PhpStorm]
---

* apache配置文件为：` /etc/apache2/httpd.conf `
* OSX下默认集成了apache与php；
* Mac Apache 有2个默认的网站目录，一个是`/Library/WebServer/Documents/`，一个是用户目录下的Sites目录（推荐使用），默认未开启；
* Apache 基本命令：

```
启动:sudo apachectl start
停止:sudo apachectl stop
重启:sudo apachectl restart
```

## 1. 配置apache

Step 1. 在用户目录下用Finder创建 Sites 文件夹；

Step 2. 在`/etc/apache2/users/`目录下添加 `username.conf`文件(username要替换成真正的用户名，下同)：

```
cd /etc/apache2/users  
sudo vim username.conf  
```

Step 3. 在`username.conf`文件中添加如下内容：  
	![username.conf内容](/img/username_conf.png)

<!--more-->

Step 4. 检查`username.conf`文件的权限是否正确，正确的应该为：

```
-rw-r--r--  1 root  wheel  126 Mar 23 23:02 username.conf  
```

如果不是，则需要修改权限，使用如下命令：  

```
		sudo chmod 644 username.conf
```

Step 5. 修改`httpd.conf`文件配置：

```
		sudo vim /etc/apache2/httpd.conf  
```

在`httpd.conf`找到如下3行，并确保这3行的注释＃是被删除的  

```
		LoadModule authz_core_module libexec/apache2/mod_authz_core.so
		LoadModule authz_host_module libexec/apache2/mod_authz_host.so
		LoadModule userdir_module libexec/apache2/mod_userdir.so
```

接着启用用户目录配置，同为删除对应行的＃

```
		Include /private/etc/apache2/extra/httpd-userdir.conf
```

Step 6. 修改`httpd-userdir.conf`文件配置  

```
		sudo vim /etc/apache2/extra/httpd-userdir.conf
```

取消如下行的＃

```
		Include /private/etc/apache2/users/*.conf
```

Step 7. 重启Apache，并检查配置是否生效

```
		sudo apachectl restart
```

在浏览器输入：`http://localhost/~username/`，看是否配置成功

Step 8. 让apache支持php脚本  

* 修改 httpd.conf 文件配置

```
			sudo vim /etc/apache2/httpd.conf
```

* 取消php库文件的＃注释

```
			LoadModule php5_module libexec/apache2/libphp5.so
```

* 重启Apache

```
			sudo apachectl restart
```

* 在Sites目录下创建index.php，内容如下：

```
			<?php phpinfo(); ?>
```

* 在浏览器里输入：`http://localhost/~username`   

> 如果能显示php环境信息，则说明php环境搭建成功  

Step 9. 配置虚拟主机(vhost)

* 将/etc/apache2/httpd.conf文件中如下内容的`#`去掉

```
#Include /private/etc/apache2/extra/httpd-vhosts.conf
```

* 修改/etc/apache2/extra/httpd-vhosts.conf:

```
<VirtualHost *:80>
    ServerAdmin admin@simiam.vhost.com
    DocumentRoot "/Users/chenzhian/workspace/php/website/public"
    ServerName simiam.vhost.com
    DirectoryIndex main.php index.php index.html
    <Directory "/Users/chenzhian/workspace/php/website/public">
	Options FollowSymLinks Multiviews
	MultiviewsMatch Any
	AllowOverride All
	Require all granted
    </Directory>
    ErrorLog "/private/var/log/apache2/simiam.vhost.com-error_log"
    CustomLog "/private/var/log/apache2/simiam.vhost.com-access_log" common
</VirtualHost>

<VirtualHost *:80>
    ServerAdmin admin@100.vhost.com
    DocumentRoot "/Users/chenzhian/workspace/php/website/100"
    ServerName 100.vhost.com
    DirectoryIndex index.php index.html
        <Directory "/Users/chenzhian/workspace/php/website/100">
	        Options FollowSymLinks Multiviews
		MultiviewsMatch Any
		AllowOverride All
		Require all granted
	</Directory>
    ErrorLog "/private/var/log/apache2/100.vhost.com-error_log"
    CustomLog "/private/var/log/apache2/100.vhost.com-access_log" common
</VirtualHost>
```


## 2. 修改或创建php.ini

Step 1. 为了开启php的一些扩展功能，有必要对`php.ini`进行修改。OSX默认提供的php是没有`php.ini`文件的，因此我们需要自己创建一个。可以在`/etc/`目录下创建`php.ini`

* /etc/目录下有提供php.ini.default模板

```
		sudo cp /etc/php.ini.default /etc/php.ini
```

* 如果不知道php默认是到哪里找php.ini文件的话，则使用命令`php --ini`：

* 命令输出如下类似信息：  

```
		Configuration File (php.ini) Path: /etc
		Loaded Configuration File:         /etc/php.ini
		Scan for additional .ini files in: /Library/Server/Web/Config/php
		Additional .ini files parsed:      (none)  
```

Step 2. 在`php.ini`文件最后添加如下内容以启用xdebug扩展:

```
		[xdebug]

		zend_extension=/usr/lib/php/extensions/no-debug-non-zts-20121212/xdebug.so
		xdebug.remote_autostart=on
		xdebug.remote_enable=on
		xdebug.remote_enable=1
		xdebug.remote_mode="req"
		xdebug.remote_log="/var/log/xdebug.log"
		xdebug.remote_host=127.0.0.1
		xdebug.remote_port=9000
		xdebug.remote_handler="dbgp"
		xdebug.idekey="PhpStorm"
```

> xdebug.remote_host的值建议设置为127.0.0.1，而不要设置为localhost（当开启调试模式时，可能会出现域名解析很慢的问题）

## 3. 安装并配置PhpStorm

Step 1. 配置php解释器:直接在**`Preferences`**的**`Languages->PHP`**页面添加php命令路径:

```
		/usr/bin/php
```

Step 2. 配置debug  
	在**`PHP->Debug->DBGp`**中添加如下信息:

```
		IDE key:PhpStorm (与php.ini中xdebug配置项xdebug.idekey一致)  
		Host:localhost  (apache服务地址)  
		Port:80 (apache服务端口)  
```


> 转载请注明出处：[cloudnoter.com](http://cloudnoter.com)


