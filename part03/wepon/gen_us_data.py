#coding=utf-8
import os
import pandas as pd
from datetime import date
from fe import *


'''
生成user-sku模型的数据


数据集构造说明：
    样本选取：前三天交互+前15天重要交互-前60天已经购买，样本的标签提取区间在之后的5天内提取。
    以下是划分的方案：


            get feature(46 day)    get sample(3 day)   get sample(15 day)   delete(60 day)       get label(5 day)   comment                   
testset:      ~75                      73-75                  61-75              16-75            76~80(unknow)      71       
trainset1:    ~70                      68-70                  56-70              11-70            71~75              64        
trainset2:    ~65                      63-65                  51-65              6-65             66~70              57         


特征工程说明：
    特征用滑窗方式分层次提取，比如前1/3/5/7...天
    在每个窗口（层次）内分类提取特征，包括user相关的，sku相关的等等
    具体如下：
    
feature level: last 1,2,3,5,7,9,14,21,33,50
feature category: user, sku,brand, user-sku, user-cate, user-brand

'''



'''
Get_Feature = 75
Get_Sample_3 = [73,75]
Get_Sample_15 = [61,75]
Delete_Sample_60 = [16,75]
Get_Label = [76,80]
Comment_day = 71
File_Name = "testset.csv"

Get_Feature = 70 
Get_Sample_3 = [68,70]
Get_Sample_15 = [56,70]
Delete_Sample_60 = [11,70]
Get_Label = [71,75]
Comment_day = 64
File_Name = "trainset1.csv"

'''

# 替换这几个变量，依次运行得到trainset2.csv，trainset1.csv,testset.csv这三份文件
Get_Feature = 65
Get_Sample_3 = [63,65]
Get_Sample_15 = [51,65]
Delete_Sample_60 = [6,65]
Get_Label = [66,70]
Comment_day = 57
File_Name = "trainset2.csv"



# 读表
action2 = pd.read_csv('data/JData_Action_201602.csv')
action3 = pd.read_csv('data/JData_Action_201603.csv')
action4 = pd.read_csv('data/JData_Action_201604.csv')
data = pd.concat([action2,action3,action4],axis=0)

data = data.drop('model_id',axis=1)
data = data.drop_duplicates()

# 几个时间处理函数
def convert_day(x):
    try:
        y,m,d = x.split(' ')[0].split('-')
        return (date(int(y),int(m),int(d)) - date(2016,1,31)).days
    except:
        print x
        return -1

def convert_second(x):
    y,m,d = x.split(' ')[0].split('-')
    h,m,s = x.split(' ')[1].split(':')
    return (date(int(y),int(m),int(d)) - date(2016,1,31)).days * 24 * 3600 + int(h)*3600 + int(m)*60 + int(s)

def convert_minute(x):
    y,m,d = x.split(' ')[0].split('-')
    h,m,s = x.split(' ')[1].split(':')
    return (date(int(y),int(m),int(d)) - date(2016,1,31)).days * 24 * 60 + int(h)*60 + int(m)

data['hour'] = data.time.apply(lambda x:int(x.split(' ')[1].split(':')[0]))
data.time = data.time.apply(convert_day) # convert 2016-01-31~2016-04-15 to 0~75
data.hour = (data.time-1)*24 + data.hour


data.to_csv('data/t.csv')

Feature_Level =[1,2,3,5,7,14,30,50]
os.mkdir(File_Name.split('.')[0])


Pre_3day = data[(data.time<=Get_Sample_3[1])&(data.time>=Get_Sample_3[0])&(data.cate==8)][['user_id','sku_id','cate','brand']].drop_duplicates()
Pre_15day = data[(data.time<=Get_Sample_15[1])&(data.time>=Get_Sample_15[0])&(data.cate==8)&((data.type==2)|(data.type==5)|(data.type==3))][['user_id','sku_id','cate','brand']].drop_duplicates()
Pre_3_15day = pd.concat([Pre_3day,Pre_15day]).drop_duplicates()
Pre_60day = data[(data.time<=Delete_Sample_60[1])&(data.time>=Delete_Sample_60[0])&(data.cate==8)&(data.type==4)][['user_id','sku_id']].drop_duplicates()
Pre_60day['flag'] = 1 
Pre_3_15day = pd.merge(Pre_3_15day,Pre_60day,on=['user_id','sku_id'],how='left')
Pre_3_15day = Pre_3_15day[Pre_3_15day.flag!=1]
Pre_3_15day = Pre_3_15day.drop('flag',axis=1)

#前2天删购物车的不要
Pre_3day_delete = data[(data.time<=Get_Sample_3[1])&(data.time>=Get_Sample_3[0]+1)&(data.cate==8)&(data.type==3)][['user_id','sku_id']].drop_duplicates()
Pre_3day_delete['flag'] = 1 
Pre_3_15day = pd.merge(Pre_3_15day,Pre_3day_delete,on=['user_id','sku_id'],how='left')
Pre_3_15day = Pre_3_15day[Pre_3_15day.flag!=1]
Pre_3_15day = Pre_3_15day.drop('flag',axis=1)


labels = data[(data.time>=Get_Label[0])&(data.time<=Get_Label[1])&(data.type==4)&(data.cate==8)][['user_id','sku_id']].drop_duplicates()
labels['label'] = 1

samples = pd.merge(Pre_3_15day,labels,on=['user_id','sku_id'],how='left')
samples.label = samples.label.fillna(0)

print samples.label.sum()
print samples.shape

# 分层次提取特征
for level in Feature_Level:
    this_level_data = data[(data.time>=Get_Feature-level+1)&(data.time<=Get_Feature)]
    
    #user features
    this_level_user_feature = get_user_feature(this_level_data)
    #sku features
    this_level_sku_feature = get_sku_feature(this_level_data)
    #brand features
    this_level_brand_feature = get_brand_feature(this_level_data)
    #user-sku
    this_level_user_sku_feature = get_user_sku_feature(this_level_data)
    #user-cate
    this_level_user_cate_feature = get_user_cate_feature(this_level_data)
    #user-brand
    this_level_user_brand_feature = get_user_brand_feature(this_level_data)
    
    this_level_feature = samples[['user_id','sku_id','cate','brand']]
    this_level_feature = pd.merge(this_level_feature,this_level_user_feature,on='user_id',how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_sku_feature,on='sku_id',how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_brand_feature,on='brand',how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_user_sku_feature,on=['user_id','sku_id'],how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_user_cate_feature,on=['user_id','cate'],how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_user_brand_feature,on=['user_id','brand'],how='left')
    cols = list(this_level_feature.columns)
    cols.remove('user_id')
    cols.remove('sku_id')
    cols.remove('cate')
    cols.remove('brand')
    this_level_feature.rename(columns={col:'level'+str(level)+'_'+col for col in cols},inplace=True)
    this_level_feature.to_csv(File_Name.split('.')[0]+'/level'+str(level)+'.csv',index=None)
    print this_level_feature.shape
   

# 合并多个层次的特征文件
files = os.listdir(File_Name.split('.')[0])
dataset = pd.read_csv(File_Name.split('.')[0]+'/'+files[0])
dataset = pd.merge(dataset,samples[['user_id','sku_id','label']],on=['user_id','sku_id'])
for f in files[1:]:
    this_file = pd.read_csv(File_Name.split('.')[0]+'/'+f)
    this_file.drop(['cate','brand'],axis=1,inplace=True)
    dataset = pd.merge(dataset,this_file,on=['user_id','sku_id'])


# 用户基本信息特征
uf = pd.read_csv('data/user_feature.csv')
dataset = pd.merge(dataset,uf,on='user_id',how='left')

# 评论数据特征
cm = pd.read_csv('data/JData_Comment.csv')
cm.dt = cm.dt.apply(convert_day)
cm = cm[cm.dt==Comment_day][['sku_id','comment_num','has_bad_comment','bad_comment_rate']]
dataset = pd.merge(dataset,cm,on='sku_id',how='left')


# 用户最早/最后一次  交互/对cate8交互/购买/对cate8购买 距离预测窗口的天数
t1 = data[(data.time>=Delete_Sample_60[0])&(data.time<=Delete_Sample_60[1])][['user_id','time']].drop_duplicates()
t1 = t1.groupby('user_id').agg(max).reset_index()
t1['last_active_gap'] = t1.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1.drop('time',axis=1,inplace=True)

t1_1 = data[(data.cate==8)&(data.time<=Delete_Sample_60[1])][['user_id','time']].drop_duplicates()
t1_1 = t1_1.groupby('user_id').agg(max).reset_index()
t1_1['last_cate8_active_gap'] = t1_1.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1_1.drop('time',axis=1,inplace=True)


t1_2 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['user_id','time']].drop_duplicates()
t1_2 = t1_2.groupby('user_id').agg(max).reset_index()
t1_2['last_buy_gap'] = t1_2.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1_2.drop('time',axis=1,inplace=True)

t1_3 = data[(data.type==4)&(data.cate==8)&(data.time<=Delete_Sample_60[1])][['user_id','time']].drop_duplicates()
t1_3 = t1_3.groupby('user_id').agg(max).reset_index()
t1_3['last_cate8_buy_gap'] = t1_3.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1_3.drop('time',axis=1,inplace=True)

t1_4 = data[data.time<=Delete_Sample_60[1]][['user_id','time']].drop_duplicates()
t1_4 = t1_4.groupby('user_id').agg(min).reset_index()
t1_4['early_active_gap'] = t1_4.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1_4.drop('time',axis=1,inplace=True)

t1_5 = data[(data.cate==8)&(data.time<=Delete_Sample_60[1])][['user_id','time']].drop_duplicates()
t1_5 = t1_5.groupby('user_id').agg(min).reset_index()
t1_5['early_cate8_active_gap'] = t1_5.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t1_5.drop('time',axis=1,inplace=True)

t2 = data[(data.time>=Delete_Sample_60[0])&(data.time<=Delete_Sample_60[1])][['user_id','sku_id','time']].drop_duplicates()
t2 = t2.groupby(['user_id','sku_id']).agg(max).reset_index()
t2['last_sku_active_gap'] = t2.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t2.drop('time',axis=1,inplace=True)

t2_1 = data[data.time<=Delete_Sample_60[1]][['user_id','sku_id','time']].drop_duplicates()
t2_1 = t2_1.groupby(['user_id','sku_id']).agg(min).reset_index()
t2_1['early_sku_active_gap'] = t2_1.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t2_1.drop('time',axis=1,inplace=True)

dataset = pd.merge(dataset,t1,on='user_id',how='left')
dataset = pd.merge(dataset,t1_1,on='user_id',how='left')
dataset = pd.merge(dataset,t1_2,on='user_id',how='left')
dataset = pd.merge(dataset,t1_3,on='user_id',how='left')
dataset = pd.merge(dataset,t1_4,on='user_id',how='left')
dataset = pd.merge(dataset,t1_5,on='user_id',how='left')
dataset = pd.merge(dataset,t2,on=['user_id','sku_id'],how='left')
dataset = pd.merge(dataset,t2_1,on=['user_id','sku_id'],how='left')
dataset['gap_diff'] = dataset['last_sku_active_gap'] - dataset['last_active_gap']
dataset['early_last_diff'] = dataset['early_active_gap'] - dataset['last_active_gap']
dataset['cate8_early_last_diff'] = dataset['early_cate8_active_gap'] - dataset['last_cate8_active_gap']
dataset['sku_early_last_diff'] = dataset['early_sku_active_gap'] - dataset['last_sku_active_gap']


# 用户最早/最后一次  交互/对cate8交互/购买/对cate8购买 距离预测窗口的小时数
t3 = data[(data.time>=Delete_Sample_60[0])&(data.time<=Delete_Sample_60[1])][['user_id','hour']].drop_duplicates()
t3 = t3.groupby('user_id').agg(max).reset_index()
t3['last_active_hour_gap'] = t3.hour.apply(lambda x:Delete_Sample_60[1]*24-x)
t3.drop('hour',axis=1,inplace=True)

t3_1 = data[(data.cate==8)&(data.time<=Delete_Sample_60[1])][['user_id','hour']].drop_duplicates()
t3_1 = t3_1.groupby('user_id').agg(max).reset_index()
t3_1['last_cate8_active_hour_gap'] = t3_1.hour.apply(lambda x:Delete_Sample_60[1]*24-x)
t3_1.drop('hour',axis=1,inplace=True)

t3_2 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['user_id','hour']].drop_duplicates()
t3_2 = t3_2.groupby('user_id').agg(max).reset_index()
t3_2['last_buy_hour_gap'] = t3_2.hour.apply(lambda x:Delete_Sample_60[1]*24-x)
t3_2.drop('hour',axis=1,inplace=True)

t3_3 = data[(data.type==4)&(data.cate==8)&(data.time<=Delete_Sample_60[1])][['user_id','hour']].drop_duplicates()
t3_3 = t3_3.groupby('user_id').agg(max).reset_index()
t3_3['last_cate8_buy_hour_gap'] = t3_3.hour.apply(lambda x:Delete_Sample_60[1]*24-x)
t3_3.drop('hour',axis=1,inplace=True)

t4 = data[(data.time>=Delete_Sample_60[0])&(data.time<=Delete_Sample_60[1])][['user_id','sku_id','hour']].drop_duplicates()
t4 = t4.groupby(['user_id','sku_id']).agg(max).reset_index()
t4['last_sku_active_hour_gap'] = t4.hour.apply(lambda x:Delete_Sample_60[1]*24-x)
t4.drop('hour',axis=1,inplace=True)

dataset = pd.merge(dataset,t3,on='user_id',how='left')
dataset = pd.merge(dataset,t3_1,on='user_id',how='left')
dataset = pd.merge(dataset,t3_2,on='user_id',how='left')
dataset = pd.merge(dataset,t3_3,on='user_id',how='left')
dataset = pd.merge(dataset,t4,on=['user_id','sku_id'],how='left')
dataset['hour_gap_diff'] = dataset['last_sku_active_hour_gap'] - dataset['last_active_hour_gap']
dataset['sku_cate8_hour_gap_diff'] = dataset['last_sku_active_hour_gap'] - dataset['last_cate8_active_hour_gap']


# sku最早/最后一次  被交互/被购买 距离预测窗口的天数
t5 = data[data.time<=Delete_Sample_60[1]][['sku_id','time']].drop_duplicates()
t5 = t5.groupby('sku_id').agg(max).reset_index()
t5['sku_last_active_gap'] = t5.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t5.drop('time',axis=1,inplace=True)

t6 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['sku_id','time']].drop_duplicates()
t6 = t6.groupby('sku_id').agg(max).reset_index()
t6['sku_last_buy_gap'] = t6.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t6.drop('time',axis=1,inplace=True)

t7 = data[data.time<=Delete_Sample_60[1]][['sku_id','time']].drop_duplicates()
t7 = t7.groupby('sku_id').agg(min).reset_index()
t7['sku_early_active_gap'] = t7.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t7.drop('time',axis=1,inplace=True)

t8 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['sku_id','time']].drop_duplicates()
t8 = t8.groupby('sku_id').agg(min).reset_index()
t8['sku_early_buy_gap'] = t8.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t8.drop('time',axis=1,inplace=True)

dataset = pd.merge(dataset,t5,on='sku_id',how='left')
dataset = pd.merge(dataset,t6,on='sku_id',how='left')
dataset = pd.merge(dataset,t7,on='sku_id',how='left')
dataset = pd.merge(dataset,t8,on='sku_id',how='left')


# brand最早/最后一次  被交互/被购买 距离预测窗口的天数
t9 = data[data.time<=Delete_Sample_60[1]][['brand','time']].drop_duplicates()
t9 = t9.groupby('brand').agg(max).reset_index()
t9['brand_last_active_gap'] = t9.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t9.drop('time',axis=1,inplace=True)

t10 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['brand','time']].drop_duplicates()
t10 = t10.groupby('brand').agg(max).reset_index()
t10['brand_last_buy_gap'] = t10.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t10.drop('time',axis=1,inplace=True)

t11 = data[data.time<=Delete_Sample_60[1]][['brand','time']].drop_duplicates()
t11 = t11.groupby('brand').agg(min).reset_index()
t11['brand_early_active_gap'] = t11.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t11.drop('time',axis=1,inplace=True)

t12 = data[(data.type==4)&(data.time<=Delete_Sample_60[1])][['brand','time']].drop_duplicates()
t12 = t12.groupby('brand').agg(min).reset_index()
t12['brand_early_buy_gap'] = t12.time.apply(lambda x:Delete_Sample_60[1]+1-x)
t12.drop('time',axis=1,inplace=True)

t13 = data[data.time<=Delete_Sample_60[1]][['brand','sku_id']].drop_duplicates()[['brand']]
t13['brand_sku_cnt'] = 1
t13 = t13.groupby('brand').agg(sum).reset_index()

dataset = pd.merge(dataset,t9,on='brand',how='left')
dataset = pd.merge(dataset,t10,on='brand',how='left')
dataset = pd.merge(dataset,t11,on='brand',how='left')
dataset = pd.merge(dataset,t12,on='brand',how='left')
dataset = pd.merge(dataset,t13,on='brand',how='left')


# 根据以上提取的特征，进一步得到各种比率特征

dataset.fillna(0,inplace=True)
dataset['l1_usb_b'] = (dataset.level1_user_sku_browse_cnt-0.001) / (dataset.level1_browse_cnt + 0.001)
dataset['l1_usac_ac'] = (dataset.level1_user_sku_add_cart_cnt-0.001) / (dataset.level1_add_cart_cnt + 0.001)
dataset['l1_usdc_dc'] = (dataset.level1_user_sku_delete_cart_cnt-0.001) / (dataset.level1_delete_cart_cnt + 0.001)
dataset['l1_usi_i'] = (dataset.level1_user_sku_interest_cnt-0.001) / (dataset.level1_interest_cnt + 0.001)
dataset['l1_usc_c'] = (dataset.level1_user_sku_click_cnt-0.001) / (dataset.level1_click_cnt + 0.001)

dataset['l3_usb_b'] = (dataset.level3_user_sku_browse_cnt-0.001) / (dataset.level3_browse_cnt + 0.001)
dataset['l3_usac_ac'] = (dataset.level3_user_sku_add_cart_cnt-0.001) / (dataset.level3_add_cart_cnt + 0.001)
dataset['l3_usdc_dc'] = (dataset.level3_user_sku_delete_cart_cnt-0.001) / (dataset.level3_delete_cart_cnt + 0.001)
dataset['l3_usi_i'] = (dataset.level3_user_sku_interest_cnt-0.001) / (dataset.level3_interest_cnt + 0.001)
dataset['l3_usc_c'] = (dataset.level3_user_sku_click_cnt-0.001) / (dataset.level3_click_cnt + 0.001)

dataset['l5_usb_b'] = (dataset.level5_user_sku_browse_cnt-0.001) / (dataset.level5_browse_cnt + 0.001)
dataset['l5_usac_ac'] = (dataset.level5_user_sku_add_cart_cnt-0.001) / (dataset.level5_add_cart_cnt + 0.001)
dataset['l5_usdc_dc'] = (dataset.level5_user_sku_delete_cart_cnt-0.001) / (dataset.level5_delete_cart_cnt + 0.001)
dataset['l5_usi_i'] = (dataset.level5_user_sku_interest_cnt-0.001) / (dataset.level5_interest_cnt + 0.001)
dataset['l5_usc_c'] = (dataset.level5_user_sku_click_cnt-0.001) / (dataset.level5_click_cnt + 0.001)

dataset['l7_usb_b'] = (dataset.level7_user_sku_browse_cnt-0.001) / (dataset.level7_browse_cnt + 0.001)
dataset['l7_usac_ac'] = (dataset.level7_user_sku_add_cart_cnt-0.001) / (dataset.level7_add_cart_cnt + 0.001)
dataset['l7_usdc_dc'] = (dataset.level7_user_sku_delete_cart_cnt-0.001) / (dataset.level7_delete_cart_cnt + 0.001)
dataset['l7_usi_i'] = (dataset.level7_user_sku_interest_cnt-0.001) / (dataset.level7_interest_cnt + 0.001)
dataset['l7_usc_c'] = (dataset.level7_user_sku_click_cnt-0.001) / (dataset.level7_click_cnt + 0.001)

dataset['l14_usb_b'] = (dataset.level14_user_sku_browse_cnt-0.001) / (dataset.level14_browse_cnt + 0.001)
dataset['l14_usac_ac'] = (dataset.level14_user_sku_add_cart_cnt-0.001) / (dataset.level14_add_cart_cnt + 0.001)
dataset['l14_usdc_dc'] = (dataset.level14_user_sku_delete_cart_cnt-0.001) / (dataset.level14_delete_cart_cnt + 0.001)
dataset['l14_usi_i'] = (dataset.level14_user_sku_interest_cnt-0.001) / (dataset.level14_interest_cnt + 0.001)
dataset['l14_usc_c'] = (dataset.level14_user_sku_click_cnt-0.001) / (dataset.level14_click_cnt + 0.001)

dataset['l30_usb_b'] = (dataset.level30_user_sku_browse_cnt-0.001) / (dataset.level30_browse_cnt + 0.001)
dataset['l30_usac_ac'] = (dataset.level30_user_sku_add_cart_cnt-0.001) / (dataset.level30_add_cart_cnt + 0.001)
dataset['l30_usdc_dc'] = (dataset.level30_user_sku_delete_cart_cnt-0.001) / (dataset.level30_delete_cart_cnt + 0.001)
dataset['l30_usi_i'] = (dataset.level30_user_sku_interest_cnt-0.001) / (dataset.level30_interest_cnt + 0.001)
dataset['l30_usc_c'] = (dataset.level30_user_sku_click_cnt-0.001) / (dataset.level30_click_cnt + 0.001)

dataset['l50_usb_b'] = (dataset.level50_user_sku_browse_cnt-0.001) / (dataset.level50_browse_cnt + 0.001)
dataset['l50_usac_ac'] = (dataset.level50_user_sku_add_cart_cnt-0.001) / (dataset.level50_add_cart_cnt + 0.001)
dataset['l50_usdc_dc'] = (dataset.level50_user_sku_delete_cart_cnt-0.001) / (dataset.level50_delete_cart_cnt + 0.001)
dataset['l50_usi_i'] = (dataset.level50_user_sku_interest_cnt-0.001) / (dataset.level50_interest_cnt + 0.001)
dataset['l50_usc_c'] = (dataset.level50_user_sku_click_cnt-0.001) / (dataset.level50_click_cnt + 0.001)



dataset['l1_usb_ucb'] = (dataset.level1_user_sku_browse_cnt-0.001) / (dataset.level1_user_cate_browse_cnt + 0.001)
dataset['l1_usac_ucac'] = (dataset.level1_user_sku_add_cart_cnt-0.001) / (dataset.level1_user_cate_add_cart_cnt + 0.001)
dataset['l1_usdc_ucdc'] = (dataset.level1_user_sku_delete_cart_cnt-0.001) / (dataset.level1_user_cate_delete_cart_cnt + 0.001)
dataset['l1_usi_uci'] = (dataset.level1_user_sku_interest_cnt-0.001) / (dataset.level1_user_cate_interest_cnt + 0.001)
dataset['l1_usc_ucc'] = (dataset.level1_user_sku_click_cnt-0.001) / (dataset.level1_user_cate_click_cnt + 0.001)

dataset['l3_usb_ucb'] = (dataset.level3_user_sku_browse_cnt-0.001) / (dataset.level3_user_cate_browse_cnt + 0.001)
dataset['l3_usac_ucac'] = (dataset.level3_user_sku_add_cart_cnt-0.001) / (dataset.level3_user_cate_add_cart_cnt + 0.001)
dataset['l3_usdc_ucdc'] = (dataset.level3_user_sku_delete_cart_cnt-0.001) / (dataset.level3_user_cate_delete_cart_cnt + 0.001)
dataset['l3_usi_uci'] = (dataset.level3_user_sku_interest_cnt-0.001) / (dataset.level3_user_cate_interest_cnt + 0.001)
dataset['l3_usc_ucc'] = (dataset.level3_user_sku_click_cnt-0.001) / (dataset.level3_user_cate_click_cnt + 0.001)

dataset['l5_usb_ucb'] = (dataset.level5_user_sku_browse_cnt-0.001) / (dataset.level5_user_cate_browse_cnt + 0.001)
dataset['l5_usac_ucac'] = (dataset.level5_user_sku_add_cart_cnt-0.001) / (dataset.level5_user_cate_add_cart_cnt + 0.001)
dataset['l5_usdc_ucdc'] = (dataset.level5_user_sku_delete_cart_cnt-0.001) / (dataset.level5_user_cate_delete_cart_cnt + 0.001)
dataset['l5_usi_uci'] = (dataset.level5_user_sku_interest_cnt-0.001) / (dataset.level5_user_cate_interest_cnt + 0.001)
dataset['l5_usc_ucc'] = (dataset.level5_user_sku_click_cnt-0.001) / (dataset.level5_user_cate_click_cnt + 0.001)

dataset['l7_usb_ucb'] = (dataset.level7_user_sku_browse_cnt-0.001) / (dataset.level7_user_cate_browse_cnt + 0.001)
dataset['l7_usac_ucac'] = (dataset.level7_user_sku_add_cart_cnt-0.001) / (dataset.level7_user_cate_add_cart_cnt + 0.001)
dataset['l7_usdc_ucdc'] = (dataset.level7_user_sku_delete_cart_cnt-0.001) / (dataset.level7_user_cate_delete_cart_cnt + 0.001)
dataset['l7_usi_uci'] = (dataset.level7_user_sku_interest_cnt-0.001) / (dataset.level7_user_cate_interest_cnt + 0.001)
dataset['l7_usc_ucc'] = (dataset.level7_user_sku_click_cnt-0.001) / (dataset.level7_user_cate_click_cnt + 0.001)

dataset['l14_usb_ucb'] = (dataset.level14_user_sku_browse_cnt-0.001) / (dataset.level14_user_cate_browse_cnt + 0.001)
dataset['l14_usac_ucac'] = (dataset.level14_user_sku_add_cart_cnt-0.001) / (dataset.level14_user_cate_add_cart_cnt + 0.001)
dataset['l14_usdc_ucdc'] = (dataset.level14_user_sku_delete_cart_cnt-0.001) / (dataset.level14_user_cate_delete_cart_cnt + 0.001)
dataset['l14_usi_uci'] = (dataset.level14_user_sku_interest_cnt-0.001) / (dataset.level14_user_cate_interest_cnt + 0.001)
dataset['l14_usc_ucc'] = (dataset.level14_user_sku_click_cnt-0.001) / (dataset.level14_user_cate_click_cnt + 0.001)

dataset['l30_usb_ucb'] = (dataset.level30_user_sku_browse_cnt-0.001) / (dataset.level30_user_cate_browse_cnt + 0.001)
dataset['l30_usac_ucac'] = (dataset.level30_user_sku_add_cart_cnt-0.001) / (dataset.level30_user_cate_add_cart_cnt + 0.001)
dataset['l30_usdc_ucdc'] = (dataset.level30_user_sku_delete_cart_cnt-0.001) / (dataset.level30_user_cate_delete_cart_cnt + 0.001)
dataset['l30_usi_uci'] = (dataset.level30_user_sku_interest_cnt-0.001) / (dataset.level30_user_cate_interest_cnt + 0.001)
dataset['l30_usc_ucc'] = (dataset.level30_user_sku_click_cnt-0.001) / (dataset.level30_user_cate_click_cnt + 0.001)

dataset['l50_usb_ucb'] = (dataset.level50_user_sku_browse_cnt-0.001) / (dataset.level50_user_cate_browse_cnt + 0.001)
dataset['l50_usac_ucac'] = (dataset.level50_user_sku_add_cart_cnt-0.001) / (dataset.level50_user_cate_add_cart_cnt + 0.001)
dataset['l50_usdc_ucdc'] = (dataset.level50_user_sku_delete_cart_cnt-0.001) / (dataset.level50_user_cate_delete_cart_cnt + 0.001)
dataset['l50_usi_uci'] = (dataset.level50_user_sku_interest_cnt-0.001) / (dataset.level50_user_cate_interest_cnt + 0.001)
dataset['l50_usc_ucc'] = (dataset.level50_user_sku_click_cnt-0.001) / (dataset.level50_user_cate_click_cnt + 0.001)


# 一些加权重的组合特征，系数拍脑袋想的
dataset['weighted_uf_browse_decay'] = 1.6*dataset.level1_browse_cnt + 0.8*(dataset.level3_browse_cnt - dataset.level1_browse_cnt) + \
                               0.4*(dataset.level7_browse_cnt - dataset.level3_browse_cnt) + 0.2*(dataset.level14_browse_cnt - dataset.level7_browse_cnt) +\
                               0.1*(dataset.level30_browse_cnt - dataset.level14_browse_cnt) + 0.05*(dataset.level50_browse_cnt - dataset.level30_browse_cnt)

dataset['weighted_uf_interest_decay'] = 1.6*dataset.level1_interest_cnt + 0.8*(dataset.level3_interest_cnt - dataset.level1_interest_cnt) + \
                               0.4*(dataset.level7_interest_cnt - dataset.level3_interest_cnt) + 0.2*(dataset.level14_interest_cnt - dataset.level7_interest_cnt) +\
                               0.1*(dataset.level30_interest_cnt - dataset.level14_interest_cnt) + 0.05*(dataset.level50_interest_cnt - dataset.level30_interest_cnt)

dataset['weighted_uf_click_decay'] = 1.6*dataset.level1_click_cnt + 0.8*(dataset.level3_click_cnt - dataset.level1_click_cnt) + \
                               0.4*(dataset.level7_click_cnt - dataset.level3_click_cnt) + 0.2*(dataset.level14_click_cnt - dataset.level7_click_cnt) +\
                               0.1*(dataset.level30_click_cnt - dataset.level14_click_cnt) + 0.05*(dataset.level50_click_cnt - dataset.level30_click_cnt)

dataset['weighted_uf_add_cart_decay'] = 1.6*dataset.level1_add_cart_cnt + 0.8*(dataset.level3_add_cart_cnt - dataset.level1_add_cart_cnt) + \
                               0.4*(dataset.level7_add_cart_cnt - dataset.level3_add_cart_cnt) + 0.2*(dataset.level14_add_cart_cnt - dataset.level7_add_cart_cnt) +\
                               0.1*(dataset.level30_add_cart_cnt - dataset.level14_add_cart_cnt) + 0.05*(dataset.level50_add_cart_cnt - dataset.level30_add_cart_cnt)
                               
dataset['weighted_uf_delete_cart_decay'] = 1.6*dataset.level1_delete_cart_cnt + 0.8*(dataset.level3_delete_cart_cnt - dataset.level1_delete_cart_cnt) + \
                               0.4*(dataset.level7_delete_cart_cnt - dataset.level3_delete_cart_cnt) + 0.2*(dataset.level14_delete_cart_cnt - dataset.level7_delete_cart_cnt) +\
                               0.1*(dataset.level30_delete_cart_cnt - dataset.level14_delete_cart_cnt) + 0.05*(dataset.level50_delete_cart_cnt - dataset.level30_delete_cart_cnt)

# 用户前50天转化率特征
dataset['cvr_buy_browse'] = (dataset.level50_buy_cnt-0.01) / (dataset.level50_browse_cnt+0.01)
dataset['cvr_buy_click'] = (dataset.level50_buy_cnt-0.01) / (dataset.level50_click_cnt+0.01)
dataset['cvr_buy_interest'] = (dataset.level50_buy_cnt-0.01) / (dataset.level50_interest_cnt+0.01)
dataset['cvr_buy_add_cart'] = (dataset.level50_buy_cnt-0.01) / (dataset.level50_add_cart_cnt+0.01)
dataset['cvr_buy_delete_cart'] = (dataset.level50_buy_cnt-0.01) / (dataset.level50_delete_cart_cnt+0.01)

# 用户前50天对cate8的转化率特征
dataset['cate8_cvr_buy_browse'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_browse_cnt+0.01)
dataset['cate8_cvr_buy_click'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_click_cnt+0.01)
dataset['cate8_cvr_buy_interest'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_interest_cnt+0.01)
dataset['cate8_cvr_buy_add_cart'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_add_cart_cnt+0.01)
dataset['cate8_cvr_buy_delete_cart'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_delete_cart_cnt+0.01)

# 用户前50天对brand的转化率特征
dataset['brand_cvr_buy_browse'] = (dataset.level50_user_brand_buy_cnt-0.01) / (dataset.level50_user_brand_browse_cnt+0.01)
dataset['brand_cvr_buy_click'] = (dataset.level50_user_brand_buy_cnt-0.01) / (dataset.level50_user_brand_click_cnt+0.01)
dataset['brand_cvr_buy_interest'] = (dataset.level50_user_brand_buy_cnt-0.01) / (dataset.level50_user_brand_interest_cnt+0.01)
dataset['brand_cvr_buy_add_cart'] = (dataset.level50_user_brand_buy_cnt-0.01) / (dataset.level50_user_brand_add_cart_cnt+0.01)
dataset['brand_cvr_buy_delete_cart'] = (dataset.level50_user_brand_buy_cnt-0.01) / (dataset.level50_user_brand_delete_cart_cnt+0.01)

# user对sku，预测窗口前一天是否加购物车，是否点关注
dataset['pre1day_add_cart'] = dataset.level1_user_sku_add_cart_cnt>0
dataset['pre1day_interest'] = dataset.level1_user_sku_interest_cnt>0

dataset.to_csv('data/'+File_Name,index=None)


