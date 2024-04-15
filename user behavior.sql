#确认抽取的数据是否10w条
SELECT count(*)
from userbehavior;

#删除重复值
select 用户ID,商品ID,商品类目ID,行为类型,行为时间
from userbehavior
group by 用户ID,商品ID,商品类目ID,行为类型,行为时间
having count(*)>1;

# 删除缺失值，先确认是否有缺失值
select
count(用户ID),count(商品ID),count(商品类目ID),count(行为类型),count(行为时间)
from userbehavior; 

#增加一列存放日期
alter table userbehavior add column 日期 varchar(255);

#从行为时间里抽取日期，比如2021-01-01
update userbehavior 
set 日期=from_unixtime(行为时间,'%Y-%m-%d');

#增加一列存放时间
alter table userbehavior add column 时间 varchar(255);

#从行为时间里抽取时间，比如21:43:01
update userbehavior 
set 时间=from_unixtime(行为时间,'%H:%i:%s');

#增加一列存放小时
alter table userbehavior add column 小时 varchar(255);

#从行为时间里抽取小时，比如2
update userbehavior 
set 小时=from_unixtime(行为时间,'%H');

#查询转换后的日期，时间，小时
select 日期,时间,小时
from userbehavior;

select 用户ID,商品ID,商品类目ID,行为类型,行为时间,日期,时间,小时
from userbehavior
order by 用户ID asc;

select min(日期),max(日期)
from userbehavior;

#处理异常值
delete from userbehavior
where 日期>'2017-12-03'or 日期<'2017-11-25';

select min(日期),max(日期)
from userbehavior;

#1. 行为分析：用户随时间发生了怎样的变化，并找出用户一天中最活跃的时间段是？
# 用户生命周期分析，基于用群组分析方法，对用户活跃与购买情况进行研究，为运营提供数据支撑；

## 1）总揽独立访客量、商品总数量、商品类型总数等
select count(distinct 用户ID) as 独立访客量,
       count(distinct 商品ID) as 商品总数量,
       count(distinct 商品类目ID) as 商品类型总数,
       count(distinct 行为类型) as 行为类型总数,
       count(distinct 日期) as 天数,
       min(日期) 最早日期,
       max(日期) 最晚日期
from userbehavior;

## 2）总体UV、PV、人均浏览次数、成交量
select count(distinct 用户ID) as 独立访客数,
       sum(case when 行为类型='pv' then 1 else 0 end) as 点击数,
       sum(case when 行为类型='pv' then 1 else 0 end)/count(distinct 用户ID) as 人均浏览次数,
       sum(case when 行为类型='buy' then 1 else 0 end) as 成交量
from userbehavior;

# 3）日均UV、PV、人均浏览次数、成交量

select 日期, count(distinct 用户ID) as 独立访客数,
       sum(case when 行为类型='pv' then 1 else 0 end) as 点击数,
       sum(case when 行为类型='pv' then 1 else 0 end)/count(distinct 用户ID) as 人均浏览次数,
       sum(case when 行为类型='buy' then 1 else 0 end) as 成交量
from userbehavior
group by 日期
order by 日期;

# 4）时均UV、PV、人均浏览次数、成交量
select 小时, count(distinct 用户ID) as 独立访客数,
       sum(case when 行为类型='pv' then 1 else 0 end) as 点击数,
       sum(case when 行为类型='pv' then 1 else 0 end)/count(distinct 用户ID) as 人均浏览次数,
       sum(case when 行为类型='buy' then 1 else 0 end) as 成交量
from userbehavior
group by 小时
order by 小时;

# 4）用户行为数据整理
create view 用户行为数据 as 
select 用户ID, count(行为类型) as 用户行为数,
       sum(case when 行为类型='pv' then 1 else 0 end) as 点击数,
       sum(case when 行为类型='cart' then 1 else 0 end) as 加购数,
       sum(case when 行为类型='fav' then 1 else 0 end) as 收藏量,
       sum(case when 行为类型='buy' then 1 else 0 end) as 成交量
from userbehavior
group by 用户ID
order by 用户行为数;

# 2.环节分析：用户从点击-收藏-加购-购买各环节的流失率如何？
# 用户行为路径分析，基于漏斗分析方法，研究用户群体在整个购物过程中的转化/流失情况，提出改善转化的建议；

select count(distinct 用户ID) AS '独立访客量',
sum(case when 行为类型='pv' then 1 else 0 end) as '点击量',
sum(case when 行为类型='cart' then 1 else 0 end) as '加购数',
sum(case when 行为类型='fav' then 1 else 0 end) as '收藏量',
sum(case when 行为类型 ='buy' then 1 else 0 end) as '成交量',
sum(case when 行为类型='pv' then 1 else 0 end)/count(distinct 用户ID) as '人均点击次数',
(select count(distinct 用户ID) as 购买人数
from  userbehavior
where 行为类型 ='buy')/count(distinct 用户ID) as '购买转化率'
from  userbehavior;

## 在淘宝购物时，用户行为路径可分为四部分：点击-加入购物车-收藏-购买
select 行为类型,
count(distinct 用户ID) AS '独立访客量',
sum(case when 行为类型='pv' then 1 else 0 end) as '点击',
sum(case when 行为类型='cart' then 1 else 0 end) as '加购',
sum(case when 行为类型='fav' then 1 else 0 end) as '收藏',
sum(case when 行为类型 ='buy' then 1 else 0 end) as '成交'
from userbehavior
group by 行为类型
order by 行为类型 desc;

## 环节转化率=本环节用户数/上一环节用户数
## 整体转化率=某环节用户数/第一环节用户数

# 3. 商品分析：找出点击量、收藏量、加购量及购买量TOP10的商品，如何更好营销商品？
# 用户消费偏好分析，基于环节数据统计，找出点击量、收藏量、加购量及购买量TOP10的商品，为运营及营销提供策略支持；

## 从用户角度解读：
### 从整体上统计有购买行为的用户总数

-- 有购买行为的用户总数为：
select count(distinct 用户ID) as 购买总人数
from userbehavior
where 行为类型='buy';

-- 找出用户购买的次数及总人数
select 购买次数,count(*) as 人数
from
(select 用户ID,count(用户ID) as 购买次数
from userbehavior
where 行为类型='buy'
group by 用户ID
having count(用户ID)>=1) as 用户购买
group by 购买次数 
order by 购买次数 asc;

-- 找出购买次数大于等于2的Top10用户
select 用户ID,count(用户ID) as 购买次数
from  userbehavior
where 行为类型='buy'
group by 用户ID
having count(用户ID)>=2
order by 购买次数 desc
limit 10;

-- 复购次数Top10用户购买的TOP10商品
select 商品类目ID,count(用户ID) as 购买次数
from userbehavior
where 用户ID in('1003983','1003901','100101','1000488','1000723','1002031','1001305','1001866','100134','100116')and 行为类型='buy'
group by 商品类目ID
having count(用户ID)>=2
order by 购买次数 desc
limit 10;

## 从商品角度解读：
### 比较各行为类型的商品
-- 比较各行为类型的商品
select 商品类目ID,
sum(case when 行为类型 = 'pv' then 1 else 0 end)as 点击量,
sum(case when 行为类型 = 'fav' then 1 else 0 end)as 收藏量,
sum(case when 行为类型 = 'cart' then 1 else 0 end)as 加购量,
sum(case when 行为类型 = 'buy' then 1 else 0 end)as 购买量
from userbehavior
group by 商品类目ID;

-- 创建视图商品用于存放各行为类型的商品

create view 商品
as
select 商品类目ID,
sum(case when 行为类型 = 'pv' then 1 else 0 end)as 点击量,
sum(case when 行为类型 = 'fav' then 1 else 0 end)as 收藏量,
sum(case when 行为类型 = 'cart' then 1 else 0 end)as 加购量,
sum(case when 行为类型 = 'buy' then 1 else 0 end)as 购买量
from userbehavior
group by 商品类目ID;

### 分别找出点击量-收藏量-加购量-购买量Top10商品
-- 点击量Top10的商品
select 商品类目ID,点击量
from 商品
order by 点击量 desc
limit 10;

-- 收藏量Top10的商品
select 商品类目ID,收藏量
from 商品
order by 收藏量 desc
limit 10;

-- 加购量Top10的商品
select 商品类目ID,加购量
from 商品
order by 加购量 desc
limit 10;

-- 购买量Top10的商品
select 商品类目ID,购买量
from 商品
order by 购买量 desc
limit 10;

# 4.类型分析：有哪些？针对不同类型的用户应该采取什么措施？
# 用户价值分析，基于RFM分析方法，找出高价值用户，对其进行精准营销，并对不同价值的用户采用不同的运营策略来刺激消费；

## 由于本次数据集中缺少金额，所以我们只能以R（时间间隔R）和F（购买次数F）来对用户的价值进行分类。

-- RFM模型第一步：计算R、F值，并创建视图存放。
-- R：根据用户购买的时间到2017年12月3日的时间差值，来判断用户的最近一次消费时间间隔
-- F：将数据集中用户从2017年11月25日到12月3日的消费次数来作为频率

-- RFM模型第一步：计算R、F值，并创建视图存放。

create view RFM
as
select 用户ID,
datediff('2017-12-03',max(日期)) as '时间间隔R',
count(行为类型) as '购买次数F'
from userbehavior
where 行为类型='buy'
group by 用户ID
order by 用户ID;

-- 查看最长时间间隔和最大购买次数

select max(时间间隔R),max(购买次数F)
from RFM;

-- 统计各购买时间间隔的用户数

select 时间间隔R,
count(用户ID) as 用户数
from RFM
group by 时间间隔R
order by 时间间隔R;

-- 统计各购买次数的用户数

select 购买次数F,
count(用户ID) as 用户数
from RFM
group by 购买次数F
order by 购买次数F;

-- RFM模型第二步：给R、F按价值打分，并创建视图分数用于存放R、F值打分。

create view 分数 as
select
用户ID,
(case
when 时间间隔R between 0 and 1 then '0分'
when 时间间隔R between 2 and 3 then '4分'
when 时间间隔R between 4 and 5 then '3分'
when 时间间隔R between 6 and 8 then '2分'
else 0
end)
as 'R值打分',
(case
when 购买次数F between 0 and 3 then '0分'
when 购买次数F between 4 and 10 then '1分'
when 购买次数F between 11 and 20 then '2分'
when 购买次数F between 21 and 30 then '3分'
when 购买次数F between 31 and 57 then '4分'
else 0
end)
as 'F值打分'
from RFM;

-- 统计各购买时间间隔的用户数

select count(*),
sum(case when R值打分='0分' then 1 else 0 end) as '0<=R<=1',
sum(case when R值打分='4分' then 1 else 0 end) as '2<=R<=3',
sum(case when R值打分='3分' then 1 else 0 end) as '4<=R<=5',
sum(case when R值打分='2分' then 1 else 0 end) as '6<=R<=8'
from 分数;

-- 统计各购买次数的用户数

select count(*),
sum(case when F值打分='0分' then 1 else 0 end) as '0<=F=3',
sum(case when F值打分='1分' then 1 else 0 end) as '4<=F=10',
sum(case when F值打分='2分' then 1 else 0 end) as '11<=F=20',
sum(case when F值打分='3分' then 1 else 0 end) as '21<=F=30',
sum(case when F值打分='4分' then 1 else 0 end) as '31<=F=57'
from 分数;

## RFM模型第三步：对R、F值打分求平均值
select avg(R值打分),avg(F值打分)
from 分数;

## RFM模型第四步：用户分类规则
select
用户ID,
(case when R值打分>(select avg(R值打分)from 分数) then '高' else'低'end) 
as 'R值高低',
(case when F值打分>(select avg(F值打分)from 分数) then '高' else'低'end)
as 'F值高低'
from 分数;

## RFM模型第五步：用户分类
create view 用户分类划分
as
select
用户ID,
(case when R值打分>(select avg(R值打分)from 分数) then '高' else'低'end) 
as 'R值高低',
(case when F值打分>(select avg(F值打分)from 分数) then '高' else'低'end)
as 'F值高低'
from 分数;

select *,
(case
when R值高低='高' and F值高低='高' then '价值用户'
when R值高低='高' and F值高低='低' then '发展用户'
when R值高低='低' and F值高低='高' then '保持用户'
when R值高低='低' and F值高低='低' then '挽留用户'
else 0
end) as'用户分类'
from 用户分类划分;

-- 统计各分类下的用户数
select count(*) as 总用户数,
sum(case when 用户分类='价值用户' then 1 else 0 end)as 价值用户数,
sum(case when 用户分类='发展用户' then 1 else 0 end)as 发展用户数,
sum(case when 用户分类='保持用户' then 1 else 0 end)as 保持用户数,
sum(case when 用户分类='挽留用户' then 1 else 0 end)as 挽留用户数
from 分类;

create view 用户数
as
select count(*) as 总用户数,
sum(case when 用户分类='价值用户' then 1 else 0 end)as 价值用户数,
sum(case when 用户分类='发展用户' then 1 else 0 end)as 发展用户数,
sum(case when 用户分类='保持用户' then 1 else 0 end)as 保持用户数,
sum(case when 用户分类='挽留用户' then 1 else 0 end)as 挽留用户数
from 分类;

select
价值用户数/总用户数 as 价值用户比例,
发展用户数/总用户数 as 发展用户比例,
保持用户数/总用户数 as 保持用户比例,
挽留用户数/总用户数 as 挽留用户比例
from 用户数;




















