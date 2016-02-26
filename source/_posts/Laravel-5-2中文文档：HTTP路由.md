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

# 路由参数(占位符)

Laravel中路由规则配置中的URL中允许设置参数(占位符)，便于闭包或控制器方法提取与引用。Laravel的路由URL中参数占位符配置方式分两种：必选与可选。
 >这种机制蛮适合开发符合RESTful规范的应用，这里有一篇由《黑客与画家》、《软件随想录》译者阮一峰写的介绍RESTful概念的文章： [理解RESTful架构](http://www.ruanyifeng.com/blog/2011/09/restful)

**必选参数占位符**

所谓必选，即HTTP请求的URL中参数占位符的部分必需有具体的数据，否则该路由规则不会被匹配到。比如，你可能需要从请求URL中获取用户的ID时，你就可以定义如下的路由规则：

    Route::get('user/{id}', function ($id) {
        return 'User '.$id;
    });
    // 当请求URL为http://somesite/user/2时，2将被提取出来并赋值给闭包函数中的变量id

由上面的例子可知，路由参数占位符是由一对花括号来定义的。当然，我们也可以在URL中定义多个参数占位符，如下：

    Route::get('posts/{post}/comments/{comment}', function ($postId, $commentId) {
         //
    });

> 注意：路由参数占位符的定义需要符合PHP变量命名规范，如不能包含"-"符。

**可选参数占位符**

如果想让路由参数占位符是可选的（有时请求URL中的占位符部分可能是空的），此时可以在占位符名称的后面加上一个问号"?"即可。

    Route::get('user/{name?}', function ($name = null) {
        return $name;
    });
    
    Route::get('user/{name?}', function ($name = 'John') {
        return $name;
    });
    
> 当URL参数占位符设置为可选时，后面的闭包函数的参数**需要**提供默认值。

# 命名路由

命名路由将允许你方便的生成URL或重定向URL，这些生成的URL最终将匹配该路由规则。你可通过如下方式定义命名路由：

    Route::get('profile', ['as' => 'profile', function () {
        //
    }]);

闭包函数的第二个数组参数的元素键值需要指定为"as"，元素值即为路由规则名。当然，你也可以为控制器的方法来代替上面的闭包函数，如下：

    Route::get('profile', [
        'as' => 'profile', 'uses' => 'UserController@showProfile'
    ]);

定义命名路由还有如下方式：

    Route::get('user/profile', 'UserController@showProfile')->name('profile');

即先定义一个普通路由，然后再调用该路由规则实例的name方法。

**路由组与命名路由**

如果你正在使用路由规则组时，你可以在路由规则组定义的属性数组中添加一个key为"as"，值为某字符串的元素，该元素的值将作为该路由组中包含的路由名字的前缀。如下：

    Route::group(['as' => 'admin::'], function () {
        Route::get('dashboard', ['as' => 'dashboard', function () {
            // Route named "admin::dashboard"
        }]);
    });

**生成匹配命名路由的URL**

一旦你已经为某一路由起了相应的名字，那么你就可以通过全局函数`route`来生成相应的URL：

    // Generating URLs...
    $url = route('profile');
    
    // Generating Redirects...
    return redirect()->route('profile');

如果命名路由规则的URL部分包含参数占位符，则你可以将参数值作为`route`函数的第二个数组参数的元素传入，框架将自动用该参数值代替占位符以生成相应的URL。

    Route::get('user/{id}/profile', ['as' => 'profile', function ($id) {
        //
    }]);

    $url = route('profile', ['id' => 1]);

# 路由组

