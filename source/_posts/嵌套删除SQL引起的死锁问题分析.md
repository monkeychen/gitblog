title: 嵌套删除SQL引起的死锁问题分析
date: 2015-12-19 18:03:53
tags: [MySQL,DeadLock]
keywords: [MySQL,DeadLock,死锁,数据库死锁]
---
# 问题背景
应用系统后台有两个计划任务

 - 每天1：00定时删除N天前的计划日志表数据
 - 每隔5分钟统计AP终端在线用户数并更新计划日志表某一条记录的状态

 <!--more-->
# 错误日志
```
------------------------
LATEST DETECTED DEADLOCK
------------------------
150914  3:00:12
*** (1) TRANSACTION:
TRANSACTION 209F80FE, ACTIVE 2 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 320, 1 row lock(s)
MySQL thread id 241534, OS thread handle 0x2e5c, query id 2220277302 localhost 127.0.0.1 root Updating
UPDATE T_BATCH_JOB_EXECUTION set START_TIME = '2015-09-14 03:00:06', END_TIME = '2015-09-14 03:00:10',  STATUS = 'COMPLETED', CONTINUABLE = 'N', EXIT_CODE = 'COMPLETED', EXIT_MESSAGE = '', VERSION = 4, CREATE_TIME = '2015-09-14 03:00:06' where JOB_EXECUTION_ID = 435431
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F80FE lock_mode X locks rec but not gap waiting

*** (2) TRANSACTION:
TRANSACTION 209F7560, ACTIVE 7 sec fetching rows, thread declared inside InnoDB 130
mysql tables in use 2, locked 2
1108 lock struct(s), heap size 77120, 52179 row lock(s), undo log entries 7455
MySQL thread id 235617, OS thread handle 0xf10, query id 2220277303 localhost 127.0.0.1 root preparing
delete from t_batch_job_execution where job_instance_id in (select id from t_batch_plan_execution where due_time <= '2015-09-07 00:00:00' )
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F7560 lock mode S locks rec but not gap

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F7560 lock_mode X locks rec but not gap waiting


*** WE ROLL BACK TRANSACTION (1)
```

# 问题分析

 1. mysql在执行【delete from T where ... in select ... from K ...】的SQL时，会对K表的查询结果集添加共享锁【S锁】，以防止SQL执行过程中其它事务对K表进行变更操作，最终影响查询结果。可参考[InnoDB存储引擎SQL语句加锁类型分析][1]
 2. 【事务2】为"系统日志删除计划任务"，该事务涉及多个DELETE SQL，其中
```
delete from t_batch_step_execution where job_execution_id in 
(
select job_execution_id from t_batch_job_execution as job, t_batch_plan_execution as exec where job.job_instance_id = exec.id and exec.due_time <= ? 
)
```
会导致t_batch_job_execution表的某些记录被加上S锁，可从死锁日志中得到验证
```
*** (2) HOLDS THE LOCK(S):RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F7560 lock mode S locks rec but not gap
```
3. 【事务1】的"5分钟终端统计任务"的SQL
```
UPDATE T_BATCH_JOB_EXECUTION set START_TIME = '2015-09-14 03:00:06', END_TIME = '2015-09-14 03:00:10',  STATUS = 'COMPLETED', CONTINUABLE = 'N', EXIT_CODE = 'COMPLETED', EXIT_MESSAGE = '', VERSION = 4, CREATE_TIME = '2015-09-14 03:00:06' where JOB_EXECUTION_ID = 435431
```
需要对T_BATCH_JOB_EXECUTION表指定行申请加上排它锁【X锁】；在加【X锁】前，INNODB存储引擎会先隐式申请该行的意向排它锁【IX锁】；由于该行已经被【事务2】加上【S锁】，但是【IX锁】与【S锁】是兼容的，因此【事务2】对该行加【IX锁】成功，而【X锁】与【S锁】会冲突，因此本事务就处理等待【X锁】状态，可从死锁日志得到验证
```
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F80FE lock_mode X locks rec but not gap waiting
```
4. 【事务2】接下来执行SQL
```
delete from t_batch_job_execution where job_instance_id in (select id from t_batch_plan_execution where due_time <= ? )
```
需要申请【IX琐】(原理同上)、【X琐】,而由于指定行此时已经被【事务1】加上【IX锁】，由于而【IX锁】与【X锁】会冲突，因此【事务2】就处理申请等待【X锁】的状态，可从死锁日志得到验证
```
*** (2) WAITING FOR THIS LOCK TO BE GRANTED:RECORD LOCKS space id 101740 page no 388 n bits 240 index `PRIMARY` of table `emp`.`t_batch_job_execution` trx id 209F7560 lock_mode X locks rec but not gap waiting
```
# 解决方案
对"系统日志删除计划任务"的相关SQL进行拆分，避免出现S锁的现象，即将
```
delete from t_batch_step_execution where job_execution_id in (select job_execution_id from t_batch_job_execution as job, t_batch_plan_execution as exec where job.job_instance_id = exec.id and exec.due_time <= ? )
```
拆分为两个SQL：
```
1. select job_execution_id from t_batch_job_execution as job, t_batch_plan_execution as exec where job.job_instance_id = exec.id and exec.due_time <= ? 
2. delete from t_batch_step_execution where job_execution_id in ( ? )
```
可以这样拆分的原因为：系统日志删除任务主要是删除N天前的数据，子查询的结果在短时间内是不会变化的。

# 参考资料
1. [MySQL加锁处理分析][2]


  [1]: http://dev.mysql.com/doc/refman/5.7/en/innodb-locks-set.html
  [2]: http://hedengcheng.com/?p=771