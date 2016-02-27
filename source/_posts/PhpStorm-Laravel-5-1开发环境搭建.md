title: PhpStorm+Laravel_5.1开发环境搭建
date: 2016-01-12 00:26:13
tags: [php,laravel]
keywords: [php,laravel,PhpStorm,开发环境搭建]
---
> 参数文档：[Laravel Development using PhpStorm][1]

 1. 在PhpStorm + Laravel5.1下无法为artisan创建【command line tool support】问题

**现象**：
```
Problem
Failed to parse output as xml: Error on line 4: Content is not allowed in prolog..
Command
php.exe C:\Users\Maxim.Kolmakov\PhpstormProjects\Laravel-5\artisan list --xml
Output                                                                               
  [ErrorException]                                                             
  The --xml option was deprecated in version 2.7 and will be removed in versi  
  on 3.0. Use the --format option instead.

```
**原因**：
Laravel 5.1版的Artisan的命令行的xml标志位已经被删除，详见Symfony的[Git提交记录][2]。

**解决办法**：2种
- 将Laravel降级为5.0版本
- 到目录[项目根目录]/vendor/symfony/console/Command下将如下两个文件还原回去：
```
HelpCommand.php
ListCommand.php
```

2.[phpstorm laravel live template][3]

  [1]: https://confluence.jetbrains.com/display/PhpStorm/Laravel+Development+using+PhpStorm
  [2]: https://github.com/symfony/console/commit/6d6d9031b9148fed0e2aacb98ac23ce6168ba7ac
  [3]:https://github.com/koomai/phpstorm-laravel-live-templates