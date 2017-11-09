#coding=utf-8
import os
import pandas as pd
from datetime import date
from fe import *

"""
生成user模型的数据, 产生方法同user-sku模型的

"""

'''

Get_Feature = 65
Get_Sample_3 = [63,65]
Get_Sample_15 = [51,65]
Delete_Sample_60 = [6,65]
Get_Label = [66,70]
File_Name = "user_trainset2.csv"


Get_Feature = 75
Get_Sample_3 = [73,75]
Get_Sample_15 = [61,75]
Delete_Sample_60 = [16,75]
Get_Label = [76,80]
File_Name = "user_testset.csv"

'''

# 替换这几个变量，依次运行得到user_trainset2.csv，user_trainset1.csv,user_testset.csv这三份文件
Get_Feature = 70 
Get_Sample_3 = [68,70]
Get_Sample_15 = [56,70]
Delete_Sample_60 = [11,70]
Get_Label = [71,75]
File_Name = "user_trainset1.csv"



action2 = pd.read_csv('data/JData_Action_201602.csv')
action3 = pd.read_csv('data/JData_Action_201603.csv')
action4 = pd.read_csv('data/JData_Action_201604.csv')
data = pd.concat([action2,action3,action4],axis=0)

def convert_time(x):
    try:
        y,m,d = x.split(' ')[0].split('-')
        return (date(int(y),int(m),int(d)) - date(2016,1,31)).days
    except:
        print x
        return -1
        
data['hour'] = data.time.apply(lambda x:int(x.split(' ')[1].split(':')[0]))
data.time = data.time.apply(convert_time) # convert 2016-01-31~2016-04-15 to 0~75
data.hour = (data.time-1)*24 + data.hour


Feature_Level =[1,2,3,5,7,14,30,50]
os.mkdir(File_Name.split('.')[0])


Pre_3day = data[(data.time<=Get_Sample_3[1])&(data.time>=Get_Sample_3[0])&(data.cate==8)][['user_id','cate']].drop_duplicates()
Pre_15day = data[(data.time<=Get_Sample_15[1])&(data.time>=Get_Sample_15[0])&(data.cate==8)&((data.type==2)|(data.type==5)|(data.type==3))][['user_id','cate']].drop_duplicates()
Pre_3_15day = pd.concat([Pre_3day,Pre_15day]).drop_duplicates()
Pre_60day = data[(data.time<=Delete_Sample_60[1])&(data.time>=Delete_Sample_60[0])&(data.cate==8)&(data.type==4)][['user_id']].drop_duplicates()
Pre_60day['flag'] = 1 
Pre_3_15day = pd.merge(Pre_3_15day,Pre_60day,on=['user_id'],how='left')
Pre_3_15day = Pre_3_15day[Pre_3_15day.flag!=1]
Pre_3_15day = Pre_3_15day.drop('flag',axis=1)


labels = data[(data.time>=Get_Label[0])&(data.time<=Get_Label[1])&(data.type==4)&(data.cate==8)][['user_id']].drop_duplicates()
labels['label'] = 1

samples = pd.merge(Pre_3_15day,labels,on=['user_id'],how='left')
samples.label = samples.label.fillna(0)

print samples.label.sum()
print samples.shape

# 分层次提取特征
for level in Feature_Level:
    this_level_data = data[(data.time>=Get_Feature-level+1)&(data.time<=Get_Feature)]
    
    #user features
    this_level_user_feature = get_user_feature(this_level_data)
    #user-cate
    this_level_user_cate_feature = get_user_cate_feature(this_level_data)
    
    
    this_level_feature = samples[['user_id','cate']]
    print this_level_feature.shape
    this_level_feature = pd.merge(this_level_feature,this_level_user_feature,on='user_id',how='left')
    this_level_feature = pd.merge(this_level_feature,this_level_user_cate_feature,on=['user_id','cate'],how='left')
    cols = list(this_level_feature.columns)
    cols.remove('user_id')
    cols.remove('cate')
    this_level_feature.rename(columns={col:'level'+str(level)+'_'+col for col in cols},inplace=True)
    this_level_feature.to_csv(File_Name.split('.')[0]+'/level'+str(level)+'.csv',index=None)
    print this_level_feature.shape
   

# 合并多个层次的特征文件
files = os.listdir(File_Name.split('.')[0])
dataset = pd.read_csv(File_Name.split('.')[0]+'/'+files[0])
dataset = pd.merge(dataset,samples[['user_id','label']],on=['user_id'])
for f in files[1:]:
    this_file = pd.read_csv(File_Name.split('.')[0]+'/'+f)
    this_file.drop(['cate'],axis=1,inplace=True)
    dataset = pd.merge(dataset,this_file,on=['user_id'])


# 用户基本信息特征
uf = pd.read_csv('data/user_feature.csv')
dataset = pd.merge(dataset,uf,on='user_id',how='left')

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



dataset = pd.merge(dataset,t1,on='user_id',how='left')
dataset = pd.merge(dataset,t1_1,on='user_id',how='left')
dataset = pd.merge(dataset,t1_2,on='user_id',how='left')
dataset = pd.merge(dataset,t1_3,on='user_id',how='left')
dataset = pd.merge(dataset,t1_4,on='user_id',how='left')
dataset = pd.merge(dataset,t1_5,on='user_id',how='left')
dataset['early_last_diff'] = dataset['early_active_gap'] - dataset['last_active_gap']
dataset['cate8_early_last_diff'] = dataset['early_cate8_active_gap'] - dataset['last_cate8_active_gap']


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



dataset = pd.merge(dataset,t3,on='user_id',how='left')
dataset = pd.merge(dataset,t3_1,on='user_id',how='left')
dataset = pd.merge(dataset,t3_2,on='user_id',how='left')
dataset = pd.merge(dataset,t3_3,on='user_id',how='left')




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

# 用户前50天cate8转化率特征
dataset['cate8_cvr_buy_browse'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_browse_cnt+0.01)
dataset['cate8_cvr_buy_click'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_click_cnt+0.01)
dataset['cate8_cvr_buy_interest'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_interest_cnt+0.01)
dataset['cate8_cvr_buy_add_cart'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_add_cart_cnt+0.01)
dataset['cate8_cvr_buy_delete_cart'] = (dataset.level50_user_cate_buy_cnt-0.01) / (dataset.level50_user_cate_delete_cart_cnt+0.01)

# 用户前14天转化率特征
dataset['cvr_14_buy_browse'] = (dataset.level14_buy_cnt-0.01) / (dataset.level14_browse_cnt+0.01)
dataset['cvr_14_buy_click'] = (dataset.level14_buy_cnt-0.01) / (dataset.level14_click_cnt+0.01)
dataset['cvr_14_buy_interest'] = (dataset.level14_buy_cnt-0.01) / (dataset.level14_interest_cnt+0.01)
dataset['cvr_14_buy_add_cart'] = (dataset.level14_buy_cnt-0.01) / (dataset.level14_add_cart_cnt+0.01)
dataset['cvr_14_buy_delete_cart'] = (dataset.level14_buy_cnt-0.01) / (dataset.level14_delete_cart_cnt+0.01)

# 用户前14天cate8转化率特征
dataset['cate8_cvr_14_buy_browse'] = (dataset.level14_user_cate_buy_cnt-0.01) / (dataset.level14_user_cate_browse_cnt+0.01)
dataset['cate8_cvr_14_buy_click'] = (dataset.level14_user_cate_buy_cnt-0.01) / (dataset.level14_user_cate_click_cnt+0.01)
dataset['cate8_cvr_14_buy_interest'] = (dataset.level14_user_cate_buy_cnt-0.01) / (dataset.level14_user_cate_interest_cnt+0.01)
dataset['cate8_cvr_14_buy_add_cart'] = (dataset.level14_user_cate_buy_cnt-0.01) / (dataset.level14_user_cate_add_cart_cnt+0.01)
dataset['cate8_cvr_14_buy_delete_cart'] = (dataset.level14_user_cate_buy_cnt-0.01) / (dataset.level14_user_cate_delete_cart_cnt+0.01)


# 用户前7天转化率特征
dataset['cvr_7_buy_browse'] = (dataset.level7_buy_cnt-0.01) / (dataset.level7_browse_cnt+0.01)
dataset['cvr_7_buy_click'] = (dataset.level7_buy_cnt-0.01) / (dataset.level7_click_cnt+0.01)
dataset['cvr_7_buy_interest'] = (dataset.level7_buy_cnt-0.01) / (dataset.level7_interest_cnt+0.01)
dataset['cvr_7_buy_add_cart'] = (dataset.level7_buy_cnt-0.01) / (dataset.level7_add_cart_cnt+0.01)
dataset['cvr_7_buy_delete_cart'] = (dataset.level7_buy_cnt-0.01) / (dataset.level7_delete_cart_cnt+0.01)

# 用户前7天cate8转化率特征
dataset['cate8_cvr_7_buy_browse'] = (dataset.level7_user_cate_buy_cnt-0.01) / (dataset.level7_user_cate_browse_cnt+0.01)
dataset['cate8_cvr_7_buy_click'] = (dataset.level7_user_cate_buy_cnt-0.01) / (dataset.level7_user_cate_click_cnt+0.01)
dataset['cate8_cvr_7_buy_interest'] = (dataset.level7_user_cate_buy_cnt-0.01) / (dataset.level7_user_cate_interest_cnt+0.01)
dataset['cate8_cvr_7_buy_add_cart'] = (dataset.level7_user_cate_buy_cnt-0.01) / (dataset.level7_user_cate_add_cart_cnt+0.01)
dataset['cate8_cvr_7_buy_delete_cart'] = (dataset.level7_user_cate_buy_cnt-0.01) / (dataset.level7_user_cate_delete_cart_cnt+0.01)


dataset.to_csv('data/'+File_Name,index=None)


