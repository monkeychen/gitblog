title: Java小问题汇总
date: 2016-11-08 22:09:00
tags: [Java,MySQL]
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

* 运行如下脚本查看字段详细信息

```
show full fields from ipms_device_feature
```
 
结果如下：
![mysql_json](/img/mysql_json.jpg)

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

## 2. 待续...

