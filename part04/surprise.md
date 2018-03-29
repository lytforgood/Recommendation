<!-- [TOC]  -->

## 1、精简版的特征、模型与结果
### 1）最少需要保留那些处理方法和特征，才能保证结果在90%以上？
```
第一种模型
f11
train: 
    特征提取区间：02-01 ~ 04-10 所有与cate8发生过交互的user
    label构造：04-11 ~ 04-15 购买过cate8的user标为1
test:
    特征提取区间：02-01 ~ 04-15 所有与cate8发生过交互的user
特征：
    （以下所说的次数，在同一user对同一sku连续产生的操作都记为一次）
    该user最后一天交互cate8产品距离预测第一天的天数 
    该user与cate8产品交互的间隔天数的（mean, median, max, min）
    该user与cate8产品交互的总操作数，type1~6各类别交互操作数
    该user与cate8交互的产品数
    该user与所交互的cate8各个产品的总操作数的（mean,mdian,max,min）
    该user与所交互的cate8各个产品的（type1~6）各类别操作数的（mean,mdian,max,min）
    该user与cate8产品交互的天数
    该user与cate8各个产品交互天数的（mean,median,min.max）
    该user与cate8产品交互的次数
    该user与cate8各个产品交互次数的（mean,median,min,max）
    购物车中是否有cate8商品
    购物车中cate8商品数
    购物车中是否加过cate8商品
    购物车中加过的cate8商品数
    是否关注了cate8商品
    近30天是否下单cate8产品
    是否对cate8下过单
    是否对任意产品下过单
    交互过的非cate8产品数
    交互过的非cate8产品天数
    交互过的非cate8产品次数
    购物车中是否有非cate8商品
    购物车中非cate8商品数
    购物车中是否加过非cate8商品
    购物车中加过的非cate8商品数
    与非cate8产品总交互操作数
    与非cate8产品（type1~6）各类别交互操作数
    user预测第一天与注册日期间隔天数
    user(age，sex，user_lv_cd) OneHotEncoder
f12
train: 
    特征提取区间：在04-11 ~ 04-15 购买过cate8的user，在02-01 ~ 04-10 中所有出现过的user_sku对
    label构造：04-11 ~ 04-15 发生购买的user_sku对标为1
test:
    特征提取区间：f11预测出的user在02-01 ~ 04-15 所有与cate8发生过交互的user_sku对
特征：
    该user与该sku最后一天交互距离预测第一天的天数
    该user与cate8产品最后一天交互距离预测第一天的天数
    该user最后一天交互该sku距离天数 减 该user最后一天交互cate8距离天数
    该user交互cate8产品数
    该user与cate8产品交互的最后一天是否有交互该sku
    该user与cate8产品交互的最后一天所交互的cate8产品数量
    最后一天交互距离预测第一天的天数 小于该产品的cate8产品数，/交互cate8产品数
    最后一天交互距离预测第一天的天数 小于等于该产品的cate8产品数， /交互cate8产品数
    (交互天数系列)
    交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    交互cate8各个产品天数的mean，var
    交互该产品天数 - 交互cate8各个产品天数的mean
    （交互该产品天数 - 交互cate8各个产品天数的mean）/ 交互cate8各个产品天数的var
    sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/ 交互cate8各个产品天数的var)
    abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/ 交互cate8各个产品天数的var)
    交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    交互天数大于该产品的cate8产品数，/交互cate8产品数
    (对交互天数按时间(天)进行加权，特征同上）
    （交互次数系列，将以上天数改为次数）
    （对交互次数按天进行加权）
    （交互操作数，将天数改为操作数）
    （对操作数按天进行加权）
    type(1,2,3,6)各个type的操作数（体系同上）
    type(1,2,3,6)各个type的加权操作数（体系同上）
    type（2,3,4,5）
        是否对该sku有过该type的操作
        是否对cate8产品有过该type的操作
        有过该type操作的cate8产品数
        有过该type操作的cate8产品数（除去该sku）
        sign(有过该type操作的cate8产品数（除去该sku）)
        对任意cate产品是否有过该type的操作
    该sku是否在购物车中
    购物车中cate8产品总数
    是否有其他cate8产品在购物车中
    是否有任意产品在购物车中
    预测日期之前该sku购买总数
    预测日期之前该sku购买总数 / 预测日期之前所有产品购买总数
    预测日期之前该sku所属品牌购买总数
    预测日期之前该sku所属品牌购买总数 / 预测日期之前所有产品购买总数
    预测第一天与用户注册日期间隔天数
    user(age，sex，user_lv_cd) OneHotEncoder
    sku（attr1, attr2, attr3, attr4）OneHotEncoder
    该user交互的cate8产品中 在预测日期前 差评数 小于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 差评率 小于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 差评数 小于等于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 差评率 小于等于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 购买数 小于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 购买率 小于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 购买数 小于等于 该sku 的产品数， /交互的cate8产品数
    该user交互的cate8产品中 在预测日期前 购买率 小于等于 该sku 的产品数， /交互的cate8产品数
第二种模型
1. 预测用户买不买模型。(精简特征)
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
性别 
年龄  
消费等级
注册时间
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差
最近n天内浏览的商品个数、品牌个数
top20品牌浏览量
过去n天的行为天数
过去n天的停留时间
2. 预测用户商品对买不买模型。(精简特征)
user维度
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
性别 
年龄  
消费等级
注册时间
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差
最近n天内浏览的商品个数、品牌个数
top20品牌浏览量
过去n天的行为天数
过去n天的停留时间
sku_id维度
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差
累计评论数分段  
是否有差评  
差评率
brand维度
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差
该品牌有多少种商品
us维度
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差
ub维度    
最近n天的各个行为和
最近n天的各个行为加权和
最近n天的转化率
最近n天的活跃度 
最后一次交互/购买距离预测日前一天的时间间隔
最早一次交互/购买距离预测日前一天的时间间隔
最早与最晚交互的时间差 
```
### 2）最重要的模型是哪个？
u与ui模型都很重要

## 2、可运行的代码：
备注:用到R,会消耗很多内存,内存不要太小,需要修改文件里的目录
### 1）训练（模型生成）部分
原始数据需要放入三份 part01 part02 part03 原始数据的使用三部分各自独立

第一部分part01：
- 原始数据放在'part01/new_data/'目录下
- 运行顺序：
- encod_data.py
- chunk_data.py
- get_train_data.py
- get_test_data.py
- xgb_out_f1.py
- get_train_data_f2.py
- get_test_f2.py
- xgb_out_f2.py

第二部分part02：
- 原始数据放在'part02/'目录下
- scala文件注意修改里面的输入输出路径(最后那个目录必须为文件里面显示的那个目录)
- R需要修改工作目录
- 运行顺序：
- JDDateFormat01.scala
- JDDateFormat02.scala
- JDDateFormat03.scala
- File01.R
- JDDateTest31.scala
- JDDateTest41.scala
- JDDateTest42.scala
- JDDateTest43.scala
- JDDateTest51.scala
- File02.R
- Step01.R
- Step02.R
- Step03.py
- Step04.R

第三部分part03：
原始数据放在'part02/wepon/data'目录下
- 依次执行`wepon`文件夹下的`user_feature.py`, `gen_us_data.py`, `gen_u_data.py`得到用于训练user模型的数据，用于训练user-sku模型的数据
gen_us_data.py gen_u_data.py 这两个文件需要分别替换变量运行3次(代码开头有说明)

- 执行`wepon`文件夹下的`u_xgb.py`和`u_gcf.py`，对user建模，用了xgboost和[deep forest](https://github.com/leopiney/deep-forest)两种算法，得到`user_preds_xgb.csv`和`user_preds_gcf.csv`两份用户模型的预测结果

- 执行`wepon`文件夹下的`us_xgb.py`和`us_gcf.py`，对user-sku建模，用了xgboost和[deep forest](https://github.com/leopiney/deep-forest)两种算法，得到`user_sku_preds_xgb.csv`和`user_sku_preds_gcf.csv`两份user-sku模型的预测结果

- 执行`wepon/ensemble`文件夹下的`ensemble.py`对xgb和gcf的预测结果进行加权融合，得到`Top2000user.csv`,`user_preds.csv`,`user_sku_preds.csv`几份文件

- 执行`wepon/ensemble`文件夹下的`gen_submission.py`生成提交文件 `wepon174.csv`

- 运行`we_all`文件夹下的`gen_817us.py`得到`817_0.19517_F11:0.30407_F12:0.12257.csv`文件，里面用到了各个队员的预测文件，文件路径需要设置对

- 运行`we_all`文件夹下的`gen_top832user.py`得到`832user_0.2965.csv`文件，里面用到了各个队员的预测文件

第四部分part04：
- Step01.R
- Step02.R

- 注: 产出文件校对 目录下为每个part产出的最终结果,每步全一致就可以得到完整的最终结果。

A. 必要注释。
- 原始数据应该放在工作目录下
- R:setwd()修改工作目录
- python: path对应工作目录

### 2）预测部分（为了测试选手结果的真实性，请提供可编译/运行的预测代码）
A. 输入：原始数据，处理后数据或提取的特征；
part01:cate8_alluser.csv cate8_f2_800.csv
part02:us_2162.csv us_2916.csv us_test_all.csv user_test.csv
part03:817_0.19517_F11_0.30407_F12_0.12257.csv 832user_0.2965.csv
Top2000user.csv wepon174.csv
B. 输出：预测csv，结果应与排行榜提交一致；
输出：
part04:submit.csv 

## 3、解题思路：
1）概述
    A. 采用的模型？
    xbgoost deep forest
    B. 最重要的特征？
    很多，详细前见面
    C. 使用的工具？
    scala python R
2）数据处理
    A. 数据的处理？
    使用了spark，对数据异常值进行清洗,对数据结合业务背景进行合理采样
    B. 为什么要使用这些数据？数据的作用？
    该赛题是基于用户的在线行为来预测用户的购买，所以要基于用户在线行为和合理的用户画像来建模
3）特征选择与获取
    A. 哪些特征是关键特征？
    用户的特定交互行为时间特征，用户等级特征
    B. 特征是如何想到和获取的？
    结合业务背景建立合理的特征体系，然后对特征进行过虑筛选，最后以结果为导向选择最合适的特征
    C. 特征之间是否有相关关系？
    有相关性
    D. 特征是否经过处理？
    对部分特征进行的平滑，填充，one－hot编码，使其更符合业务逻辑
4）模型选择与训练
    A. 为什么选择这个模型？
    对于样本不平衡解决能力好，可以有效解决非线性问题，不必要人工构建大量特征。集成学习模型鲁棒性好，不容易过拟合。该模型可实现并行化操作，训练速度快
    B. 模型的训练方式？
    随机梯度下降法
    C. 是否进行了模型融合？模型的融合方式？
    是。各个模型排序top融合。首先，预测多个user_item模型（2个），然后通过训练的user模型对其重排序，分布取topN，再去重。
5）有趣的发现
    A. 使用的小技巧？
    样本构建选取特定天数特定行为的用户商品对
    B. 对于特殊、异常数据，如何处理它们？
    贝叶斯平滑，均值填充，删样本
    C. 你觉得你最突出的优势是什么？
    样本的构建
6）其他你想分享的
    多次验证代码中的逻辑，防止出错，在做模型之前多试一些想法，尽可能理解数据



