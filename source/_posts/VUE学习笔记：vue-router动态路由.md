title: VUE学习笔记：vue-router动态路由权限管理
date: 2019-08-01 16:28:43
tags: [vue,npm]
categories: [前端]
keywords: [vue-router,vue,node,前端开发]
---
## 场景描述
众所周知，任何一个完善的web系统都需要可访问的URL资源进行权限控制，即不同的用户所能访问的URL是不一样的。在前后端未分离前，整个权限控制逻辑都是由后端控制（如通过AOP技术等）。后面随着前端技术的不断发展（如vue等JS框架），慢慢出现了前后端分离的架构模式，特别是单页面应用（SPA）的流行，前端也开始有了对模块路由访问权限控制的需求，因此像`vue-router`这类专门负责前端路由业务的组件就亮相了。

`vue`中引入`vue-router`的方式如下：
```

```

动态路由权限管理是指：根据服务端用户角色生成适合该用户的路由配置信息，并更新Router实例下的routes属性。

## vue-router原理



> 转载请注明出处：[simiam.com](http://simiam.com)





































