title: JVM方法区(PermGen)内存快速飙升问题
date: 2017-05-07 07:01:22
tags: [Java, JVM]
categories: [Java]
keywords: [JVM, PermGen, OutOfMemory]
---

## 1. 问题描述
自从平台升级到3.0后，应用的JVM变得非常不稳定，主要体现为以下三个问题：

1. 内存泄漏：2G的JVM，2天就崩。
2. 方法区内存持续飙升，最终导致频繁的触发FullGC
3. class load频繁导致CPU有30%的资源浪费

## 2. 解决方案
### 2.1. **问题1解决思路**：
问题1相对好解决，先用jmap将堆快照dump出来，用mat分析了下，根据GC-ROOT找到引用路径即可，泄漏原因为：平台自研JPA组件的SQLQuery在实现lazy load时，由于CGLib使用不当(在向当前线程注册回调方法拦截器时，在使用完之后未及时注销)导致的查询结果缓存被线程池中的线程引用，在线程池容量开得比较大时最终将导致OOM异常。

<!--More-->


### 2.2. **问题2,3解决思路**：
以前从没碰到这种情况，方法区的内存大小在应用启动后应该是处于一个相对稳定的状态（因为大部分类在启动时就已经加载完了，就算使用CGLib动态生成代理类也应该是有一个上限，最多就是全部类的一倍），但问题2明显不属于这种情况，不管开多大的内存给方法区（通过`-X:MaxPermSize=xxxM`设置大小），应用总能在几分钟内持续升到最高值并触发FullGC，GC结束后，方法区占用内存降至接近0M（此处就发生的`class unload`），然后又进入新一轮的飙升周期（此处就发生`class loader`）。

刚开始以为仍然是JPA组件使用CGLib不当的问题，认为是为了实现`lazy load`及权限控制时使用了过多的动态代理（每个`Action,Model,Service`都被创建为动态代理，更不合理的时每个model的get方法都使用`ProxyMethodInterceptor`，问当事人原因，其答复说为了`lazy load`，但其实只有关联字段，集合字段才有必要`lazy load`）。基于此做了修改，但测试结果还是没解决问题：因为JPA中并不是每次都创建一个新的proxy，而是根据class做了缓存的，因此只能另找办法。

既然是方法区的问题，那是否可以将方法区的内容dump出来呢？于是查看了下`jmap`参数，其中的有`-permstat`可以用：`jmap -permstat <pid> `
结果如下（截取）

```
25007 intern Strings occupying 2799672 bytes.  
class_loader classesbytes parent_loaderalive? type  
  
  
<bootstrap> 262415108248  null  live <internal>  
0x000000076f045910 38758792 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x000000076f942f10 38758792 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x00000007d00e9ba0 40816816 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x00000007dd170c08 40816816 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x000000079e2f0070 40816816 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x00000007cd6b1140 13112  null  dead sun/reflect/DelegatingClassLoader@0x0000000740067648  
0x000000076fb5d130 38758792 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8  
0x000000076fbe47c0 38758792 0x00000007617d4f70dead com/atomikos/util/ClassLoadingHelper$1@0x0000000741cb86e8
```

`com/atomikos/util/ClassLoadingHelper$1`：是一个匿名内部类（该类是一个加载器），通过这个内部类加载器作为JDK `Proxy.newProxyInstance()`方法的参数，而后者就会生产大量的以Proxy$为前缀的动态类，并且未做任何缓存。
atomikos大家应该都很清楚：JTA的一个实现，但是哪个组件调用了这个工具类呢？通过断点分析，原来是JPA又自己写了个什么数据库连接池，池中的每个连接都是`ProxyConnection`，而池又好像失效的，频繁的回收，创建...

> 到目前为止，我一直没搞清楚为何要用代理类型的连接，这代理的作用从代码中也没看出个门道来，也不是为做监控。

原因定位到了，解决办法就很简单了：直接用阿里的druid替换掉。测试结果证明前面的分析是正确的。


