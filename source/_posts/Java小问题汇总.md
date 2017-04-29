title: Java小问题汇总
date: 2016-11-08 22:09:00
tags: [Java,MySQL]
categories: [Java]
keywords: [JSON,中文乱码]
---
## 1. MySQL5.7下的JSON字段中文乱码问题
中文乱码问题在Java Web开发中经常碰到，大部分原因是后端与前端的编码不一致造成的（如tomcat的默认编码为ISO-8859-1，而前端为GBK），解决办法也简单，只需要加一个`CharsetEncodingFilter`就行。但本文要讲的不是这一类总是，而是纯粹的后端问题。
### 1.1 环境准备
> 假设MySQL的默认CharSet为UTF-8，应用及部署环境也为UTF-8

* 创建包含JSON字段的数据库表

```
CREATE TABLE "ipms_device_feature" (
  "ID" int(11) NOT NULL AUTO_INCREMENT,
  "DEVICE_SERIAL_NUMBER" varchar(100) NOT NULL DEFAULT '' COMMENT '设备SN',
  "DEVICE_IP" varchar(32) NOT NULL DEFAULT '' COMMENT '设备IP',
  "FEATURES" json DEFAULT NULL COMMENT '设备巡检指标集',
  "UPDATETIME" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY ("ID")
)
```

<!--more-->

* 运行如下脚本查看字段详细信息

```
show full fields from ipms_device_feature
```
 
结果如下：
![mysql_json](http://oaivivmzx.bkt.clouddn.com/mysql_json.jpg)

> 上图中`features`这个字段的`Collation`列为`Null`

```
# 使用如下SQL时，JDBC在解析返回的数据（包含中文）时会出现乱码
select features from ipms_device_feature 
```

* 解决办法

第一步：使用MySQL提供的json_unquote方法

```
select json_unquote(features) as features from ipms_device_feature
```

第二步：在Java中调用上面的SQL时，将会返回一个`byte`数组，因此只需要通过`String`提供的方法进行转码就行。

```
List<Map> rows = em.createNamedQuery("XXX").list();
for(Map row : rows) {
	byte[] bytes = (byte[]) row.get("features");
	String features = new String(bytes, "UTF-8");
}
```

这样的话，Java变更`features`就是正常的中文，就可以直接回传给前端页面了。

## 2. 几个容易踩的坑
### 2.1. `Integer`对象之间比较的坑
对于`Integer var=?`在`-128`至`127`之间的赋值，`Integer` 对象是在`IntegerCache.cache`产生，会复用已有对象，这个区间内的`Integer`值可以直接使用==进行判断，但是这个区间之外的所有数据，都会在堆上产生，并不会复用已有对象。因此建议`Integer`对象在比较时应使用`equals`方法。

### 2.2. `ArrayList`的`subList()`方法返回值的坑
`ArrayList`的`subList`方法返回的结果不可强转成`ArrayList`，否则会抛出`ClassCastException`异常：

```
java.util.RandomAccessSubList cannot be cast to java.util.ArrayList;
```

因为`subList`方法返回的是`ArrayList`的内部类`SubList`，并不是`ArrayList`，而是`ArrayList`的一个视图，对于内部类`SubList`的所有操作最终会反映到原列表上。

### 2.3. `Arrays.asList()`方法返回值的坑
使用工具类`Arrays.asList()`把数组转换成集合时，不能使用其修改集合相关的方法，它的 `add/remove/clear`方法会抛出`UnsupportedOperationException`异常。因为`asList`方法的返回对象是一个`Arrays`内部类，并没有实现集合的修改方法。`Arrays.asList`体现的是适配器模式，只是转换接口，后台的数据仍是数组。
 
 ```
 String[] str = new String[] { "a", "b" };
 List list = Arrays.asList(str);
 list.add("c"); // 运行时异常。
 str[0]= "gujin"; // 则list.get(0)也会随之修改。
 ```
 
## 3. 待续...


> 转载请注明出处：[cloudnoter.com](http://cloudnoter.com)


