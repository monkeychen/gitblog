title: 基于Spring的动态多数据源组件使用文档
date: 2017-09-10 23:35:26
tags: [Spring, SpringBoot]
categories: [Java]
keywords: [Spring, SpringBoot]
---

## 项目源码

[https://github.com/monkeychen/xspring](https://github.com/monkeychen/xspring)

> xspring是个组件集，后续会不断增加新的通用组件，本文所介绍的动态多数据源组件位于xspring项目的xspring-data模块中，其maven坐标如下(尚未上传至maven中央库)：

```
<dependency>
    <groupId>org.xspring</groupId>
    <artifactId>xspring-data</artifactId>
    <version>0.0.1-SNAPSHOT</version>
</dependency>
```

## 设计目标

* 无须定义繁琐的配置信息，使用方只需要提供基本的JDBC连接参数即可
* 与spring框架无缝集成
* 默认使用Druid数据库连接池，但支持自定义扩展（可以使用其他数据库连接池）

## 技术原理
本组件是在spring框架提供的各种特性的基础上进行开发的，具体如下：

* 抽象的数据源路由类：`AbstractRoutingDataSource`
* 基于AOP及注解实现数据源动态切换

## 关键类图


## 参考资料:SpringBoot配置文件加载顺序及属性优先级
参考：http://www.importnew.com/17673.html
https://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#resources

`file:./config/ -> file:./ -> classpath:/config/ -> classpath:/`

如果各个目录下都有相同的配置文件（如`application.properties`），则都会被加载进来（即不互斥），但如果多个jar包的相同路径下都存在一样的配置文件，则只会加载第一个匹配的文件（具体由classloader的加载顺序决定）；如果每个文件中都包含相同的key，则最左边文件中的key具有最高的优先级，从源码注释也可证明这一点：

```
// ConfigFileApplicationListener中的描述：
// Note the order is from least to most specific (last one wins)
	private static final String DEFAULT_SEARCH_LOCATIONS = "classpath:/,classpath:/config/,file:./,file:./config/";
	
// ConfigFileApplicationListener.Loader类获取配置文件加载位置：
private Set<String> getSearchLocations() {
	Set<String> locations = new LinkedHashSet<String>();
	// User-configured settings take precedence, so we do them first
	if (this.environment.containsProperty(CONFIG_LOCATION_PROPERTY)) {
		for (String path : asResolvedSet(
				this.environment.getProperty(CONFIG_LOCATION_PROPERTY), null)) {
			if (!path.contains("$")) {
				path = StringUtils.cleanPath(path);
				if (!ResourceUtils.isUrl(path)) {
					path = ResourceUtils.FILE_URL_PREFIX + path;
				}
			}
			locations.add(path);
		}
	}
	locations.addAll(
			asResolvedSet(ConfigFileApplicationListener.this.searchLocations,
					DEFAULT_SEARCH_LOCATIONS));
	return locations;
}

```




> 转载请注明出处：[cloudnoter.com](http://cloudnoter.com)


