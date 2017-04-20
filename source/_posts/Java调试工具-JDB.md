title: 'Java调试工具:JDB'
date: 2016-01-12 23:25:28
tags: [Java,JDB]
keywords: [Java,JDB,调试技术]
---
代码调试是大家在日常应用开发定位BUG时会经常使用的技能。然而在客户生产环境下，一没有开发环境，二没有外网连接，如果此时应用出问题，而通过日志又无法定位时，该怎么办呢？

也许有人会按如下步骤来定位问题（假设BUG可复现且客户允许应用服务重启）：
1. 在本地可能出问题的相关代码中添加许多的日志信息，以将应用运行状态打印出来。
2. 打包并部署至客户现场环境
3. 复现BUG并查看日志信息并最终解决问题

其实JDK中提供的JDB是一个更加理想现场调试工具，其包含的命令列表如下：

<!--more-->

```
** JDB命令列表 **
connectors                -- 列出此 VM 中可用的连接器和传输器

run [类 [参数]]        -- 开始执行应用程序的主类

threads [线程组]     -- 列出线程
thread <线程 ID>        -- 设置默认线程
suspend [线程 ID]    -- 暂停线程（默认值为 all）
resume [线程 ID]     -- 恢复线程（默认值为 all）
where [<线程 ID> | all] -- 转储线程的堆栈
wherei [<线程 ID> | all] -- 转储线程的堆栈以及 pc 信息
up [n 帧]             -- 向上移动线程的堆栈
down [n 帧]           -- 向下移动线程的堆栈
kill <线程 ID> <表达式>   -- 中止具有给定的异常对象的线程
interrupt <线程 ID>     -- 中断线程

print <表达式>              -- 输出表达式的值
dump <表达式>               -- 输出所有对象信息
eval <表达式>               -- 计算表达式的值（与 print 作用相同）
set <lvalue> = <表达式>     -- 为字段/变量/数组元素指定新值
locals                    -- 输出当前堆栈帧中的所有本地变量

classes                   -- 列出当前已知的类
class <类 ID>          -- 显示已命名类的详细信息
methods <类 ID>        -- 列出类的方法
fields <类 ID>         -- 列出类的字段

threadgroups              -- 列出线程组
threadgroup <名称>        -- 设置当前线程组

stop in <类 ID>.<方法>[(参数类型,...)]
                          -- 在方法中设置断点
stop at <类 ID>:<行> -- 在行中设置断点
clear <类 ID>.<方法>[(参数类型,...)]
                          -- 清除方法中的断点
clear <类 ID>:<行>   -- 清除行中的断点
clear                     -- 列出断点
catch [uncaught|caught|all] <类 ID>|<类模式>
                          -- 出现指定的异常时中断
ignore [uncaught|caught|all] <类 ID>|<类模式>
                          -- 对于指定的异常，取消 'catch'
watch [access|all] <类 ID>.<字段名>
                          -- 监视对字段的访问/修改
unwatch [access|all] <类 ID>.<字段名>
                          -- 停止监视对字段的访问/修改
trace [go] methods [thread]
                          -- 跟踪方法的进入和退出。
                          -- 除非指定 'go'，否则所有线程都将暂停
trace [go] method exit | exits [thread]
                          -- 跟踪当前方法的退出或所有方法的退出
                          -- 除非指定 'go'，否则所有线程都将暂停
untrace [方法]         -- 停止跟踪方法的进入和/或退出
step                      -- 执行当前行
step up                   -- 执行到当前方法返回其调用方
stepi                     -- 执行当前指令
next                      -- 跳过一行（跨过调用）
cont                      -- 从断点处继续执行

list [line number|method] -- 输出源代码
use（或 sourcepath）[源文件路径]
                          -- 显示或更改源路径
exclude [<类模式>, ...|“无”]
                          -- 不报告指定类的步骤或方法事件
classpath                 -- 从目标 VM 输出类路径信息

monitor <命令>         -- 每次程序停止时执行命令
monitor                   -- 列出监视器
unmonitor <监视器号>      -- 删除某个监视器
read <文件名>           -- 读取并执行某个命令文件

lock <表达式>               -- 输出对象的锁信息
threadlocks [线程 ID]   -- 输出线程的锁信息

pop                       -- 弹出整个堆栈，且包含当前帧
reenter                   -- 与 pop 作用相同，但重新进入当前帧
redefine <类 ID> <类文件名>
                          -- 重新定义类代码

disablegc <表达式>          -- 禁止对象的垃圾回收
enablegc <表达式>           -- 允许对象的垃圾回收

!!                        -- 重复执行最后一个命令
<n> <命令>             -- 将命令重复执行 n 次
# <命令>               -- 放弃（不执行）
help（或 ?）               -- 列出命令
version                   -- 输出版本信息
exit（或 quit）            -- 退出调试器

<类 ID>: 带有软件包限定符的完整类名
<类模式>: 带有前导或后缀通配符 (*) 的类名
<线程 ID>: 'threads' 命令中所报告的线程号
<表达式>: Java(TM) 编程语言表达式。
支持大多数常见语法。

可以将启动命令置于 "jdb.ini" 或 ".jdbrc" 之中
（两者位于 user.home 或 user.dir 中）
```

有关JDB的使用详细介绍请参考[官方文档][1]。接下来我将用JDB调试Tomcat（以Tomcat7为例）下的应用来介绍下JDB的简单用法。

[1]: https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jdb.html

使用JDB进行调试，大概有下面几个步骤：

1. 在服务器上创建setenv.bat文件，并输入如下内容，并将该文件放在Tomcat安装目录的bin目录下，并重启Tomcat；
    ``` 
    set CATALINA_OPTS="-agentlib:jdwp=transport=dt_socket,address=8787,server=y,suspend=n"
    ```
2. 将应用系统的源码解压至某一目录，如src_dir1与src_dir2
3. 在CLI下输入以下命令连接至服务器上的Tomcat
	```
	jdb -connect com.sun.jdi.SocketAttach:hostname=localhost,port=8787,timeout=3000 -sourcepath src_dir1:src_dir2
	```

这样就可以进入JDB的DEBUG环境了，你可以通过stop命令创建断点，通过next命令单行调试，通过step命令单步调试，通过step up命令返回至上层调用点等，具体使用网上一堆参考资料。


> 转载请注明出处：[cloudnoter.com](http://cloudnoter.com)

