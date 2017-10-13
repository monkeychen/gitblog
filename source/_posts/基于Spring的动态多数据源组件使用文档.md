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
本框架是在spring框架提供的各种特性的基础上进行开发的，具体如下：

* 抽象的数据源路由类：`AbstractRoutingDataSource`
* 基于AOP及注解实现数据源动态切换

### xspring-core组件
core组件是所有其他组件的基础，其提供了通用的事件总线、日志管理等功能。其中`XspringApplication`是整个框架的启动类，通过调用这个启动类的startup静态方法，并提供您打上`@org.springframework.context.annotation.Configuration`注解的启动类来启动您的应用。

> 框架启动时按如下顺序加载配置文件
> * file:./config/env.properties
> * classpath:/config/env.properties
> * file:./config/xspring.properties
> * file:./xspring.properties
> * classpath:./config/xspring.properties
> * classpath:./xspring.properties

上述配置文件中`env.properties`文件中的属性信息支持热加载（即每隔指定时间框架都会读取该文件并更新至SystemProperties），相关源码请参考类`EnvironmentInitializer`.

基于Xspring框架的应用启动示例代码如下：

```
@Configuration
@ImportResource("classpath:/config/customized-beans.xml")   // 可以通过ImportResource方式加载定义在XML中的bean信息。
public class DemoApplication {
    private ApplicationContext applicationContext;

    private DemoService demoService;

    public static void main(String[] args) throws Exception {
        applicationContext = XspringApplication.startup(DemoApplication.class, args);
        demoService = applicationContext.getBean("demoService", DemoService.class);
    }
}
```

`XspringApplication`类的`startup`方法会创建`XspringApplication`实例并调用其`run`方法：

```
public static ConfigurableApplicationContext startup(Class<?> annotatedClass, String[] args) {
    return new XspringApplication().run(annotatedClass, args);
}
```

在`run`方法中，框架会通过SPI方式加载其他组件提供的标注有`@Configuration`注解的`org.xspring.core.extension.ModuleConfiguration`接口实现类，从而启动其他组件。

SPI声明统一存放在各个组件的`classpath:/META-INF/spring.factories`文件中，整个加载过程源码如下：

```
public ConfigurableApplicationContext run(Class<?> annotatedClass, String[] args) {
    logger.debug("The input arguments is:{}, {}", annotatedClass, args);
    AnnotationConfigApplicationContext context = null;
    // Load other configurations in spring.factories file
    ClassLoader classLoader = ClassUtils.getDefaultClassLoader();
    List<String> factoryNames = SpringFactoriesLoader.loadFactoryNames(ModuleConfiguration.class, classLoader);
    List<Class> moduleConfigClasses = Lists.newArrayList();
    moduleConfigClasses.add(XspringConfiguration.class);
    if (CollectionUtils.isNotEmpty(factoryNames)) {
        for (String factoryName : factoryNames) {
            try {
                Class factoryClass = ClassUtils.forName(factoryName, classLoader);
                moduleConfigClasses.add(factoryClass);
            } catch (ClassNotFoundException e) {
                logger.warn("Can not find the matched class[{}] in classpath!", factoryName);
            }
        }
    }
    if (annotatedClass != null) {
        moduleConfigClasses.add(annotatedClass);
    }
    Class[] configurations = moduleConfigClasses.toArray(new Class[moduleConfigClasses.size()]);
    context = new AnnotationConfigApplicationContext(configurations);
    context.start();
    return context;
}
```

> xspring-core组件还提供了一个基于Google Guava库的事件总线模型，有兴趣的朋友可直接参考`org.xspring.core.eventbus`包下的相关源码。

<!--More-->

### xspring-data组件
xspring-data组件的模块定义（启动）类为：`XspringDataConfiguration`，其会通过`@Import(DataSourceInitializer.class)`方式加载动态数据源初始化配置类。`DataSourceInitializer`也是一个`@Configurable`注解类，其通过`@Bean`的方式定义了`datasource`这个动态数据源。

在动态数据源bean创建过程中，组件会通过SPI方式加载`DataSourceFactory`这个接口的实现类来获取具体的数据库连接池提供方，框架默认提供了`DruidDataSourceFactory`。
您也可以自己提供数据库连接池的实现类（同样定义在各个组件的`classpath:/META-INF/spring.factories`文件中），并通过添加`org.springframework.core.annotation.Order`注解来指定加载优先级。

`DataSourceInitializer`会从属性文件`datasource.properties`中加载JDBC配置信息，然后通过`DataSourceFactory`实现类创建相关的数据库连接池（真正的数据源）实例。
`datasource.properties`文件加载位置如下（先后顺序）：
> * file:./config/datasource.properties
> * classpath:/config/datasource.properties

框架默认提供的Druid数据库连接池所使用的`datasource.properties`文件内容大致如下（不同的数据库连接池提供方则会有所差别）：

```
# 数据源个数
xspring.datasource.jdbc.max=2

# 默认数据源编号
xspring.datasource.jdbc.default=1

# 第一个数据源
xspring.datasource.jdbc.1.name=ds_mysql
xspring.datasource.jdbc.1.driverClassName=com.mysql.jdbc.Driver
xspring.datasource.jdbc.1.url=jdbc:mysql://localhost:3306/mooc?useUnicode=true&characterEncoding=UTF8
xspring.datasource.jdbc.1.username=root
xspring.datasource.jdbc.1.password=*****
xspring.datasource.jdbc.1.initialSize=10
xspring.datasource.jdbc.1.minPoolSize=5
xspring.datasource.jdbc.1.maxPoolSize=10
xspring.datasource.jdbc.1.maxWait=60000
xspring.datasource.jdbc.1.poolFilters=stat

# 第二个数据源
xspring.datasource.jdbc.2.name=ds_postgresql
xspring.datasource.jdbc.2.driverClassName=org.postgresql.Driver
xspring.datasource.jdbc.2.url=jdbc:postgresql://localhost:5432/blog
xspring.datasource.jdbc.2.username=postgres
xspring.datasource.jdbc.2.password=*****
xspring.datasource.jdbc.2.initialSize=10
xspring.datasource.jdbc.2.minPoolSize=5
xspring.datasource.jdbc.2.maxPoolSize=10
xspring.datasource.jdbc.2.maxWait=60000
xspring.datasource.jdbc.2.poolFilters=stat

```

> **注意：xspring-data组件的动态多数据源目前只支持相同数据库连接池提供方，即只会使用order值最小的`DataSourceFactory`实现类来创建真正的数据源对象。**


源码如下：

```
@Bean
    public DataSource dataSource() {
        // 加载DataSourceFactory实现类列表，返回的实例已根据@order注解进行升序排序
        ClassLoader classLoader = ClassUtils.getDefaultClassLoader();

        // 通过SPI方式加载DataSourceFactory这个接口的实现类来获取具体的数据库连接池提供方，框架默认提供了DruidDataSourceFactory。
        List<DataSourceFactory> dataSourceFactories = SpringFactoriesLoader.loadFactories(DataSourceFactory.class, classLoader);
        if (CollectionUtils.isEmpty(dataSourceFactories)) {
            throw new BeanCreationException("Not found any DataSourceFactory implementer in class path!");
        }

        DataSourceFactory dataSourceFactory = dataSourceFactories.get(0);
        Map<String, DataSource> dataSourceMap = dataSourceFactory.loadOriginalDataSources(environment);
        if (CollectionUtils.isEmpty(dataSourceMap)) {
            throw new BeanCreationException("Fail to load any original DataSource instance!");
        }

        Map<Object, Object> targetDataSourceMap = Maps.newHashMap();
        dataSourceMap.forEach((name, dataSource) -> {
            beanFactory.registerSingleton(name, dataSource); // 将具体的DataSource实例注册进ApplicationContext
            targetDataSourceMap.put(name, dataSource);
            DynamicDataSourceContextHolder.addDataSourceId(name);
        });
        DataSource defaultDataSource = dataSourceFactory.getDefaultDataSource(environment);

        DynamicDataSource dataSource = new DynamicDataSource();
        dataSource.setTargetDataSources(targetDataSourceMap);
        dataSource.setDefaultTargetDataSource(defaultDataSource);
        return dataSource;
    }
```

使用示例见单元测试类：`DynamicDataSourceTest, DemoServiceImpl`

```
// DemoServiceImpl源码：
@Component("demoService")
public class DemoServiceImpl implements DemoService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    @TargetDataSource("ds_mysql")
    public void printClassroomList() {
        List list = jdbcTemplate.queryForList("SELECT * FROM classroom");
        System.out.println(list);
    }

    @Override
    @TargetDataSource("ds_postgresql")
    public void printUserList() {
        List list = jdbcTemplate.queryForList("SELECT * FROM t_user");
        System.out.println(list);
    }
}

// DynamicDataSourceTest源码（启动配置类）：
@Configuration
@ImportResource("classpath:/config/xspring-context-test.xml")
public class DynamicDataSourceTest {
    private ApplicationContext applicationContext;

    private DemoService demoService;
    @Before
    public void setUp() throws Exception {
        applicationContext = XspringApplication.startup(DynamicDataSourceTest.class, null);
        demoService = applicationContext.getBean("demoService", DemoService.class);
    }

    @Test
    public void testDynamicDataSource() throws Exception {
        demoService.printClassroomList();
        demoService.printUserList();
    }
}

```

自定义的XML配置文件`xspring-context-test.xml`内容如下：

```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="
       http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.3.xsd
       http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-4.3.xsd
       http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-4.3.xsd">

    <context:component-scan base-package="org.xspring" />

    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
        <property name="dataSource" ref="dataSource"/>
    </bean>
</beans>
```

## 关键类图

待补充

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


