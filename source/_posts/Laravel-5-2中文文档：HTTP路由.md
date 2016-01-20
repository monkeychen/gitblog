title: Laravel 5.2中文文档：HTTP路由
date: 2016-01-20 21:31:08
tags: [php,laravel]
---
# 基本路由
所有的Laravel路由规则都定义在`app/Http/routes.php`文件中，Laravel框架在初始化时将自动加载该文件。Laravel中最基本的路由规则如下：

    Route::get('foo', function () {
        return 'Hello World';
    });
其接受两个参数：匹配该路由的URI、路由处理闭包`Closure`；该闭包定义了具体的路由规则。

**默认路由文件**

默认情况下，`routes.php`中可以定义简单的路由，或者将这些路由定义在路由组中。路由组将利用`web`中间件为定义在其中的路由规则提供'会话状态'与`CSRF`保存等功能。
<!--more-->

任何未放在路由组中的路由规则将无权访问会话，也无法享受web中间件提供的`CSRF`保护等特性，因此如果您定义的路由规则需要web中间件提供的这些特性时，你需要确保将这些路由规则放入路由组中；通过情况下，我们会将大部分的路由规则都放在路由组中。

    Route::group(['middleware' => ['web']], function () {
        //
    });
**Route类中可用的路由方法**

框架路由引擎允许你注册如下的路由规则来响应相应的HTTP请求动作：

    Route::get($uri, $callback);
    Route::post($uri, $callback);
    Route::put($uri, $callback);
    Route::patch($uri, $callback);
    Route::delete($uri, $callback);
    Route::options($uri, $callback);

有时你需要注册一个路由规则来响应多个HTTP请求动作，因此你可以使用`Route`类的`match`方法来满足该需求。甚至你可以使用`Route`类的`any`方法来响应所有的HTTP请求动作。

    Route::match(['get', 'post'], '/', function () {
        //
    });

    Route::any('foo', function () {
        //
    });

# 路由参数
