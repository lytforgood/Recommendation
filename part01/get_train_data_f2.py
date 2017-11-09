# -*- coding: utf-8 -*-
"""
Created on Sat Apr 08 17:43:48 2017

@author: mashiro
"""

import pandas as pd
import numpy as np
import gc

def get_chunk_feature(chunk):
    #print('get data',chunk)
    action = pd.read_csv('./chunk_data/action_chunk'+str(chunk)+'.csv')
    action['month'] = action['time'].apply(lambda x: int(x[5:7]))
    action['day'] = action['time'].apply(lambda x: int(x[8:10]))
    action = action[action['month'] >= 2]
    action['day_s'] = action['month'].apply(lambda x: {0:0,1:29,2:60}[x-2])
    action['day_s'] = action['day_s'] + action['day'] -1
    action = action.sort_values(by=['user_id','time'])
    #action['jiaquan_day_s'] = action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)  
    
    user_list = np.ravel(action['user_id'])
    sku_list = np.ravel(action['sku_id'])
    same_list = []
    user = -1
    sku = -1
    same = 0
    for i in range(len(user_list)):
        if (user != user_list[i])|(sku != sku_list[i]):
            same += 1
            user = user_list[i]
            sku = sku_list[i]
        same_list.append(same)
    
    action['same_list'] = same_list
    
    print('get y',chunk)
    ###得到y
    has_action = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id','sku_id']].drop_duplicates()
    y = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8),['user_id','sku_id']].drop_duplicates()
    has_action = pd.merge(has_action, y, how='inner', on=['user_id','sku_id'])
    has_action = has_action.loc[:,['user_id']].drop_duplicates()
    has_action = pd.merge(has_action, y, how='left', on=['user_id'])
    y = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id','sku_id']].drop_duplicates()
    y['label'] = 1
    y = pd.merge(has_action,y, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print(y.shape,'get y')
    
#    has_action = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
#    y = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8),['user_id','sku_id']].drop_duplicates()
#    has_action = pd.merge(has_action, y, how='left', on=['user_id'])
#    has_action = has_action.loc[:,['user_id','sku_id']].drop_duplicates()
#    #has_action = pd.merge(has_action, y, how='left', on=['user_id'])
#    y = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id','sku_id']].drop_duplicates()
#    y['label'] = 1
#    y = pd.merge(has_action,y, how='left',on=['user_id','sku_id'])
#    y = y.fillna(0)
#    del has_action
#    gc.collect()
    
    
    action_qian_cate8 = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    has_user = y.loc[:,['user_id']].drop_duplicates()
    action_qian_cate8 = pd.merge(has_user, action_qian_cate8, how='left', on=['user_id'])
    ###最后一天交互该产品距离天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).max()
    has_action['last_days_gaisku'] = 70 - has_action['day_s']
    has_action = has_action.drop(['day_s'],axis=1)
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    
    ###最后一天交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','day_s']]
    has_action = has_action.groupby(by=['user_id'],as_index=False).max()
    has_action['last_days_cate8'] = 70 - has_action['day_s']
    has_action = has_action.drop(['day_s'],axis=1)
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    ###最后一天交互天数该产品 减 cate8
    y['last_day_gaisku_jian_cate8'] = y['last_days_gaisku'] - y['last_days_cate8']
    
    ###交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action.columns = ['user_id','has_jiaohu_cate8_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    ###最后一天交互是否有该产品
    y['gaisku_in_last_days'] = y['last_day_gaisku_jian_cate8'].apply(lambda x: 1 if int(x)==0 else 0)
    
    ###最后一天交互cate8产品数量
    has_action = action_qian_cate8.loc[:,['user_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id'],as_index=False).max()
    has_action2 = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id','sku_id'],as_index=False).max()
    has_action = pd.merge(has_action, has_action2, how='left', on=['user_id','day_s'])
    has_action = has_action.loc[:,['user_id','sku_id']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action.columns = ['user_id','last_days_cate8_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###最后一天交互该产品距离天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).max()
    has_action['last_day_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','last_day_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['last_day_rankdense_chu_cate8count'] = y['last_day_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###最后一天交互距离天数小于等于该产品的cate8产品数， /交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).max()
    has_action['last_day_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','last_day_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['last_day_rankmax_chu_cate8count'] = y['last_day_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'last day')
    
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_days_count']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action_qian_cate8.loc[:,['user_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action.columns=['user_id','jiaohu_cate8_days_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_days_chu_jiaohu_cate8_days'] = y['jiaohu_gaisku_days_count'] / y['jiaohu_cate8_days_count']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_daysmean']
    has_action2['jiaohu_cate8sku_daysvar'] = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).var()['day_s']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_days_jian_cate8sku_daysmean'] = y['jiaohu_gaisku_days_count'] - y['jiaohu_cate8sku_daysmean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_days_jianmean_chuvar'] = y['jiaohu_gaisku_days_jian_cate8sku_daysmean'] / y['jiaohu_cate8sku_daysvar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_days_jianmean_chuvar'] = y['jiaohu_days_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_days_jianmean_chuvar'] = y['jiaohu_days_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_days_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_days_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_days_rankdense_chu_cate8count'] = y['jiaohu_days_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_days_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_days_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_days_rankmax_chu_cate8count'] = y['jiaohu_days_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaohu days')
    
    ###加权天数
    ##########
    ##########
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_jiaquandays_count']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action_qian_cate8.loc[:,['user_id','day_s']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    has_action.columns=['user_id','jiaohu_cate8_jiaquandays_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_jiaquandays_chu_jiaohu_cate8_jiaquandays'] = y['jiaohu_gaisku_jiaquandays_count'] / y['jiaohu_cate8_jiaquandays_count']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)    
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action2 = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_jiaquandaysmean']
    has_action2['jiaohu_cate8sku_jiaquandaysvar'] = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).var()['day_s']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_jiaquandays_jian_cate8sku_jiaquandaysmean'] = y['jiaohu_gaisku_jiaquandays_count'] - y['jiaohu_cate8sku_jiaquandaysmean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_jiaquandays_jianmean_chuvar'] = y['jiaohu_gaisku_jiaquandays_jian_cate8sku_jiaquandaysmean'] / y['jiaohu_cate8sku_jiaquandaysvar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_jiaquandays_jianmean_chuvar'] = y['jiaohu_jiaquandays_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_jiaquandays_jianmean_chuvar'] = y['jiaohu_jiaquandays_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquandays_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquandays_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquandays_rankdense_chu_cate8count'] = y['jiaohu_jiaquandays_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquandays_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquandays_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquandays_rankmax_chu_cate8count'] = y['jiaohu_jiaquandays_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaquan jiaohu days')
    ###################################################
    ###################################################
    ###交互次数
    ###加权次数
    ###################################################
    ###################################################
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_cishu']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action_qian_cate8.loc[:,['user_id','same_list']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action.columns=['user_id','jiaohu_cate8_cishu']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_cishu_chu_jiaohu_cate8_cishu'] = y['jiaohu_gaisku_cishu'] / y['jiaohu_cate8_cishu']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_cishumean']
    has_action2['jiaohu_cate8sku_cishuvar'] = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).var()['same_list']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_cishu_jian_cate8sku_cishumean'] = y['jiaohu_gaisku_cishu'] - y['jiaohu_cate8sku_cishumean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_cishu_jianmean_chuvar'] = y['jiaohu_gaisku_cishu_jian_cate8sku_cishumean'] / y['jiaohu_cate8sku_cishuvar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_cishu_jianmean_chuvar'] = y['jiaohu_cishu_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_cishu_jianmean_chuvar'] = y['jiaohu_cishu_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_cishu_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['same_list']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_cishu_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_cishu_rankdense_chu_cate8count'] = y['jiaohu_cishu_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_cishu_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['same_list']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_cishu_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_cishu_rankmax_chu_cate8count'] = y['jiaohu_cishu_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaohu cishu')
    ###加权天数
    ##########
    ##########
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_jiaquancishu_count']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action_qian_cate8.loc[:,['user_id','day_s','same_list']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','day_s']]
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    has_action.columns=['user_id','jiaohu_cate8_jiaquancishu_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_jiaquancishu_chu_jiaohu_cate8_jiaquancishu'] = y['jiaohu_gaisku_jiaquancishu_count'] / y['jiaohu_cate8_jiaquancishu_count']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)    
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action2 = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_jiaquancishumean']
    has_action2['jiaohu_cate8sku_jiaquancishuvar'] = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).var()['day_s']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_jiaquancishu_jian_cate8sku_jiaquancishumean'] = y['jiaohu_gaisku_jiaquancishu_count'] - y['jiaohu_cate8sku_jiaquancishumean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_jiaquancishu_jianmean_chuvar'] = y['jiaohu_gaisku_jiaquancishu_jian_cate8sku_jiaquancishumean'] / y['jiaohu_cate8sku_jiaquancishuvar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_jiaquancishu_jianmean_chuvar'] = y['jiaohu_jiaquancishu_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_jiaquancishu_jianmean_chuvar'] = y['jiaohu_jiaquancishu_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquancishu_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancishu_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquancishu_rankdense_chu_cate8count'] = y['jiaohu_jiaquancishu_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']].drop_duplicates()
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquancishu_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancishu_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquancishu_rankmax_chu_cate8count'] = y['jiaohu_jiaquancishu_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaquan jiaohu cishu')
    
    #############################################
    #############################################
    ###交互操作数
    ###加权操作数
    #############################################
    #############################################
    
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_caozuo']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8),['user_id','same_list']]
    has_action = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action.columns=['user_id','jiaohu_cate8_caozuo']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_caozuo_chu_jiaohu_cate8_caozuo'] = y['jiaohu_gaisku_caozuo'] / y['jiaohu_cate8_caozuo']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_caozuomean']
    has_action2['jiaohu_cate8sku_caozuovar'] = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).var()['same_list']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_caozuo_jian_cate8sku_caozuomean'] = y['jiaohu_gaisku_caozuo'] - y['jiaohu_cate8sku_caozuomean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_caozuo_jianmean_chuvar'] = y['jiaohu_gaisku_caozuo_jian_cate8sku_caozuomean'] / y['jiaohu_cate8sku_caozuovar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_caozuo_jianmean_chuvar'] = y['jiaohu_caozuo_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_caozuo_jianmean_chuvar'] = y['jiaohu_caozuo_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_caozuo_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['same_list']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_caozuo_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_caozuo_rankdense_chu_cate8count'] = y['jiaohu_caozuo_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','same_list']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action['jiaohu_caozuo_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['same_list']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_caozuo_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_caozuo_rankmax_chu_cate8count'] = y['jiaohu_caozuo_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaohu caozuo shu')
    ###加权天数
    ##########
    ##########
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']]
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action.columns=['user_id','sku_id','jiaohu_gaisku_jiaquancaozuo_count']
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    
    has_action = action_qian_cate8.loc[:,['user_id','day_s','same_list']]
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','day_s']]
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    has_action.columns=['user_id','jiaohu_cate8_jiaquancaozuo_count']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    y['jiaohu_gaisku_jiaquancaozuo_chu_jiaohu_cate8_jiaquancaozuo'] = y['jiaohu_gaisku_jiaquancaozuo_count'] / y['jiaohu_cate8_jiaquancaozuo_count']
    
    ###交互cate8各个产品天数的mean，var
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']]
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)    
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action2 = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).mean()
    has_action2.columns=['user_id','jiaohu_cate8sku_jiaquancaozuomean']
    has_action2['jiaohu_cate8sku_jiaquancaozuovar'] = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).var()['day_s']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    
    ###交互该产品天数 - 交互cate8各个产品天数的mean
    y['jiaohu_gaisku_jiaquancaozuo_jian_cate8sku_jiaquancaozuomean'] = y['jiaohu_gaisku_jiaquancaozuo_count'] - y['jiaohu_cate8sku_jiaquancaozuomean']
    
    ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
    y['jiaohu_jiaquancaozuo_jianmean_chuvar'] = y['jiaohu_gaisku_jiaquancaozuo_jian_cate8sku_jiaquancaozuomean'] / y['jiaohu_cate8sku_jiaquancaozuovar']
    y = y.fillna(0)
    
    ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['sign_jiaohu_jiaquancaozuo_jianmean_chuvar'] = y['jiaohu_jiaquancaozuo_jianmean_chuvar'].apply(lambda x: np.sign(x))
    
    ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
    y['abs_jiaohu_jiaquancaozuo_jianmean_chuvar'] = y['jiaohu_jiaquancaozuo_jianmean_chuvar'].apply(lambda x: np.abs(x))
    
    ###交互该产品天数rank，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']]
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquancaozuo_rank_dense'] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancaozuo_rank_dense']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquancaozuo_rankdense_chu_cate8count'] = y['jiaohu_jiaquancaozuo_rank_dense'] / y['has_jiaohu_cate8_count']
    
    ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','day_s','same_list']]
    has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
    has_action = has_action.loc[:,['user_id','sku_id','day_s']]
    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action['jiaohu_jiaquancaozuo_rank_max'] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
    has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancaozuo_rank_max']]
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    y['jiaohu_jiaquancaozuo_rankmax_chu_cate8count'] = y['jiaohu_jiaquancaozuo_rank_max'] / y['has_jiaohu_cate8_count']
    #print(y.shape,'jiaquan jiaohu caozuoshu')
    
    
    
    ##################################################################
    ##################################################################
    ###各个type操作数
    ###各个type加权操作数
    ##################################################################
    ##################################################################
    ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
    for i in [1,2,3,6]:
        action_qian_cate8_type = action_qian_cate8[action_qian_cate8['type']==i]
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','same_list']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
        has_action.columns=['user_id','sku_id','jiaohu_gaisku_caozuo_type'+str(i)]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        
        has_action = action_qian_cate8_type.loc[:,['user_id','same_list']]
        has_action = has_action.groupby(by=['user_id'],as_index=False).count()
        has_action.columns=['user_id','jiaohu_cate8_caozuo_type'+str(i)]
        y = pd.merge(y, has_action, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        
        y['jiaohu_gaisku_caozuo_chu_jiaohu_cate8_caozuo_type'+str(i)] = y['jiaohu_gaisku_caozuo_type'+str(i)] / y['jiaohu_cate8_caozuo_type'+str(i)]
        
        ###交互cate8各个产品天数的mean，var
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','same_list']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
        has_action2 = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).mean()
        has_action2.columns=['user_id','jiaohu_cate8sku_caozuomean_type'+str(i)]
        has_action2['jiaohu_cate8sku_caozuovar_type'+str(i)] = has_action.loc[:,['user_id','same_list']].groupby(by=['user_id'],as_index=False).var()['same_list']
        y = pd.merge(y, has_action2, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action, has_action2
        gc.collect()
        
        ###交互该产品天数 - 交互cate8各个产品天数的mean
        y['jiaohu_gaisku_caozuo_jian_cate8sku_caozuomean_type'+str(i)] = y['jiaohu_gaisku_caozuo_type'+str(i)] - y['jiaohu_cate8sku_caozuomean_type'+str(i)]
        
        ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
        y['jiaohu_caozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_gaisku_caozuo_jian_cate8sku_caozuomean_type'+str(i)] / y['jiaohu_cate8sku_caozuovar_type'+str(i)]
        y = y.fillna(0)
        
        ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
        y['sign_jiaohu_caozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_caozuo_jianmean_chuvar_type'+str(i)].apply(lambda x: np.sign(x))
        
        ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
        y['abs_jiaohu_caozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_caozuo_jianmean_chuvar_type'+str(i)].apply(lambda x: np.abs(x))
        
        ###交互该产品天数rank，/交互cate8产品数
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','same_list']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
        has_action = has_action.loc[:,['user_id','sku_id','same_list']]
        has_action['jiaohu_caozuo_rank_dense_type'+str(i)] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['same_list']
        has_action = has_action.loc[:,['user_id','sku_id','jiaohu_caozuo_rank_dense_type'+str(i)]]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        y['jiaohu_caozuo_rankdense_chu_cate8count_type'+str(i)] = y['jiaohu_caozuo_rank_dense_type'+str(i)] / y['has_jiaohu_cate8_count']
        
        ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','same_list']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
        has_action = has_action.loc[:,['user_id','sku_id','same_list']]
        has_action['jiaohu_caozuo_rank_max_type'+str(i)] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['same_list']
        has_action = has_action.loc[:,['user_id','sku_id','jiaohu_caozuo_rank_max_type'+str(i)]]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        y['jiaohu_caozuo_rankmax_chu_cate8count_type'+str(i)] = y['jiaohu_caozuo_rank_max_type'+str(i)] / y['has_jiaohu_cate8_count']
        #print(y.shape,'type'+str(i)+' caozuo shu')
        ###加权天数
        ##########
        ##########
        ###交互该产品天数，交互cate8产品天数， 交互该产品天数/交互cate8产品天数
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','day_s','same_list']]
        has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
        has_action = has_action.loc[:,['user_id','sku_id','day_s']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
        has_action.columns=['user_id','sku_id','jiaohu_gaisku_jiaquancaozuo_count_type'+str(i)]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        
        has_action = action_qian_cate8_type.loc[:,['user_id','day_s','same_list']]
        has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
        has_action = has_action.loc[:,['user_id','day_s']]
        has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
        has_action.columns=['user_id','jiaohu_cate8_jiaquancaozuo_count_type'+str(i)]
        y = pd.merge(y, has_action, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        
        y['jiaohu_gaisku_jiaquancaozuo_chu_jiaohu_cate8_jiaquancaozuo_type'+str(i)] = y['jiaohu_gaisku_jiaquancaozuo_count_type'+str(i)] / y['jiaohu_cate8_jiaquancaozuo_count_type'+str(i)]
        
        ###交互cate8各个产品天数的mean，var
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','day_s','same_list']]
        has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)    
        has_action = has_action.loc[:,['user_id','sku_id','day_s']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
        has_action2 = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).mean()
        has_action2.columns=['user_id','jiaohu_cate8sku_jiaquancaozuomean_type'+str(i)]
        has_action2['jiaohu_cate8sku_jiaquancaozuovar_type'+str(i)] = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).var()['day_s']
        y = pd.merge(y, has_action2, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action, has_action2
        gc.collect()
        
        ###交互该产品天数 - 交互cate8各个产品天数的mean
        y['jiaohu_gaisku_jiaquancaozuo_jian_cate8sku_jiaquancaozuomean_type'+str(i)] = y['jiaohu_gaisku_jiaquancaozuo_count_type'+str(i)] - y['jiaohu_cate8sku_jiaquancaozuomean_type'+str(i)]
        
        ###（交互该产品天数 - 交互cate8各个产品天数的mean）/var
        y['jiaohu_jiaquancaozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_gaisku_jiaquancaozuo_jian_cate8sku_jiaquancaozuomean_type'+str(i)] / y['jiaohu_cate8sku_jiaquancaozuovar_type'+str(i)]
        y = y.fillna(0)
        
        ###sign(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
        y['sign_jiaohu_jiaquancaozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_jiaquancaozuo_jianmean_chuvar_type'+str(i)].apply(lambda x: np.sign(x))
        
        ###abs(（交互该产品天数 - 交互cate8各个产品天数的mean）/var)
        y['abs_jiaohu_jiaquancaozuo_jianmean_chuvar_type'+str(i)] = y['jiaohu_jiaquancaozuo_jianmean_chuvar_type'+str(i)].apply(lambda x: np.abs(x))
        
        ###交互该产品天数rank，/交互cate8产品数
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','day_s','same_list']]
        has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
        has_action = has_action.loc[:,['user_id','sku_id','day_s']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
        has_action['jiaohu_jiaquancaozuo_rank_dense_type'+str(i)] = has_action.groupby(by=['user_id','sku_id']).rank(method='dense',ascending=False)['day_s']
        has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancaozuo_rank_dense_type'+str(i)]]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        y['jiaohu_jiaquancaozuo_rankdense_chu_cate8count_type'+str(i)] = y['jiaohu_jiaquancaozuo_rank_dense_type'+str(i)] / y['has_jiaohu_cate8_count']
        
        ###交互天数大于等于该产品的cate8产品数，/交互cate8产品数
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id','day_s','same_list']]
        has_action['day_s'] = has_action['day_s'].apply(lambda x: (1/(1 + np.exp(x/(-100.0))))*3-1)
        has_action = has_action.loc[:,['user_id','sku_id','day_s']]
        has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).sum()
        has_action['jiaohu_jiaquancaozuo_rank_max_type'+str(i)] = has_action.groupby(by=['user_id','sku_id']).rank(method='max',ascending=False)['day_s']
        has_action = has_action.loc[:,['user_id','sku_id','jiaohu_jiaquancaozuo_rank_max_type'+str(i)]]
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        y['jiaohu_jiaquancaozuo_rankmax_chu_cate8count_type'+str(i)] = y['jiaohu_jiaquancaozuo_rank_max_type'+str(i)] / y['has_jiaohu_cate8_count']
        #print(y.shape,'jiaquan type'+str(i)+' caozuo shu')
    
    
    
    #############
    for i in [2,3,4,5]:
        action_qian_cate8_type = action_qian_cate8[action_qian_cate8['type']==i]
        ###是否买过该产品
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id']].drop_duplicates()
        has_action['has_type'+str(i)+'_gaisku'] = 1
        y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        
        ###是否买过cate8产品
        has_action = action_qian_cate8_type.loc[:,['user_id']].drop_duplicates()
        has_action['has_type'+str(i)+'_cate8sku'] = 1
        y = pd.merge(y, has_action, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
        
        ###买过的cate8产品数， 是否买过其他cate8产品
        has_action = action_qian_cate8_type.loc[:,['user_id','sku_id']].drop_duplicates()
        has_action = has_action.groupby(by=['user_id'],as_index=False).count()
        has_action.columns=['user_id','has_type'+str(i)+'_cate8count']
        y = pd.merge(y, has_action, how='left',on=['user_id'])
        y = y.fillna(0)
        
        y['has_type'+str(i)+'_othercate8sku_num'] = (y['has_type'+str(i)+'_cate8count'] - y['has_type'+str(i)+'_gaisku'])
        y['has_type'+str(i)+'_othercate8sku'] = y['has_type'+str(i)+'_othercate8sku_num'].apply(lambda x: 1 if x>0 else 0)
        
        ###对任意cate是否买过
        has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['type']==i),['user_id']].drop_duplicates()
        has_action['has_type'+str(i)+'_renyisku'] = 1
        y = pd.merge(y, has_action, how='left',on=['user_id'])
        y = y.fillna(0)
        del has_action
        gc.collect()
    #print(y.shape,'4 for action')
    ###是否在购物车中，购物车中cate8产品总数， 是否有其他cate8产品在购物车中, 是否有任意产品在购物车中
    has_action = action_qian_cate8.loc[:,['user_id','sku_id','type']]
    has_action['in_gouwuche'] = 0
    has_action.loc[has_action['type']==2,['in_gouwuche']] = 1
    has_action.loc[has_action['type']==3,['in_gouwuche']] = -1
    has_action = has_action.loc[:,['user_id','sku_id','in_gouwuche']].groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action = has_action.loc[has_action['in_gouwuche']>0,['user_id','sku_id']]
    has_action['in_gouwuche'] = 1
    y = pd.merge(y, has_action, how='left',on=['user_id','sku_id'])
    y = y.fillna(0)
    
    has_action = has_action.loc[:,['user_id','in_gouwuche']].groupby(by=['user_id'],as_index=False).sum()
    has_action.columns = ['user_id','in_gouwuche_cate8skunum']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    
    y['in_gouwuche_othercate8sku'] = (y['in_gouwuche_cate8skunum'] - y['in_gouwuche']).apply(lambda x: 1 if x>0 else 0)
    
    has_action = action.loc[((action['month']<4)|(action['day']<=10)),['user_id','sku_id','type']]
    has_action['in_gouwuche'] = 0
    has_action.loc[has_action['type']==2,['in_gouwuche']] = 1
    has_action.loc[has_action['type']==3,['in_gouwuche']] = -1
    has_action = has_action.loc[:,['user_id','sku_id','in_gouwuche']].groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action = has_action.loc[has_action['in_gouwuche']>0,['user_id','sku_id']]
    has_action['in_gouwuche'] = 1
    has_action = has_action.loc[:,['user_id','in_gouwuche']].groupby(by=['user_id'],as_index=False).sum()
    has_action = has_action.loc[has_action['in_gouwuche']>0,['user_id']]
    has_action['in_gouwuche_renyisku'] = 1
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    
    
    print(y.shape)
    y.to_csv('./chunk_feature/f2_cate8_feature_chunk'+str(chunk)+'.csv',index=None, encoding='utf-8')
    
    has_action = action.loc[((action['month'] == 4)&(action['day']>=11))&(action['cate']==8)&(action['type']==4),['user_id','sku_id']].drop_duplicates()
    
    product_buy_rate = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8)&(action['type']==4),['sku_id']]
    
    del  action,y
    gc.collect()
    
    return has_action, product_buy_rate
    
all_buy_user = []
product_buy_rate = []
for i in range(20):
    print('chunk',i)
    buy_user, buy_rate = get_chunk_feature(i)
    all_buy_user.append(buy_user)
    product_buy_rate.append(buy_rate)

all_buy_user = pd.concat(all_buy_user)
product_buy_rate = pd.concat(product_buy_rate)

product_buy_rate['sku_buy_sum'] = 1
product_buy_rate = product_buy_rate.groupby(['sku_id'],as_index=False).sum()
all_buy = product_buy_rate['sku_buy_sum'].sum()
product_buy_rate['sku_buy_rate'] = product_buy_rate['sku_buy_sum'] / all_buy

product = pd.read_csv('./new_data/product.csv')
product = product.loc[:,['sku_id','brand']]
product_buy_rate = pd.merge(product_buy_rate, product, how='left',on=['sku_id'])
product_buy_rate2 = product_buy_rate.loc[:,['brand','sku_buy_sum']]
product_buy_rate2 = product_buy_rate2.groupby(by=['brand'],as_index=False).sum()
product_buy_rate2.columns = ['brand','brand_buy_num']
product_buy_rate2['brand_buy_rate'] = product_buy_rate2['brand_buy_num'] / all_buy
product_buy_rate = pd.merge(product_buy_rate, product_buy_rate2, how='left',on=['brand'])
product_buy_rate = product_buy_rate.drop(['brand'],axis=1)

product_buy_rate.to_csv('./feature_data/train_product_buy_rate.csv',index=False,encoding='utf-8')
all_buy_user.to_csv('./feature_data/train_all_buy_user_f2.csv',index=None,encoding='utf-8')

del buy_user, buy_rate, all_buy_user, product_buy_rate, all_buy, product, product_buy_rate2
gc.collect()


###feature
print('get_feature')
feature = []
for i in range(20):
    y = pd.read_csv('./chunk_feature/f2_cate8_feature_chunk'+str(i)+'.csv')
    feature.append(y)
feature = pd.concat(feature)

###user
print('user')
from sklearn.preprocessing import OneHotEncoder
user = pd.read_csv('./new_data/user.csv')
last_date = pd.to_datetime('20160411')
user['user_reg_dt'] = user['user_reg_dt'].apply(lambda x: pd.to_datetime(x))
user['chuche_days'] = user['user_reg_dt'].apply(lambda x: (last_date - x).days)

user2 = user.loc[:,['age','sex','user_lv_cd']]
enc = OneHotEncoder(sparse=False)
enc.fit(user2)
user2_cate = enc.transform(user2)
user2_cate = pd.DataFrame(user2_cate)
user2_cate.columns = ['user_x'+str(i) for i in range(user2_cate.shape[1])]
user2_cate['user_id'] = user['user_id']
user2_cate['chuche_days'] = user['chuche_days']

feature = pd.merge(feature, user2_cate, how='left',on=['user_id'])
del user, user2, user2_cate
gc.collect()


###product
print('product')
product = pd.read_csv('./new_data/product.csv')
product2 = product.loc[:,['attr1','attr2','attr3']]
product2['attr1'] = product2['attr1'].apply(lambda x: int(x+1))
product2['attr2'] = product2['attr2'].apply(lambda x: int(x+1))
product2['attr3'] = product2['attr3'].apply(lambda x: int(x+1))
enc = OneHotEncoder(sparse=False)
enc.fit(product2)
product2 = enc.transform(product2)
product2 = pd.DataFrame(product2)
product2.columns = ['attr_onehot_x'+str(i) for i in range(product2.shape[1])]
product2['sku_id'] = product['sku_id']

feature = pd.merge(feature, product2, how='left',on=['sku_id'])

product2 = pd.merge(feature.loc[:,['user_id','sku_id']], product2, how='left',on=['sku_id'])
product2 = product2.drop(['sku_id'],axis=1)
product2 = product2.groupby(by=['user_id'],as_index=False).sum()
product2_use = product2['user_id']
product2 = product2.drop(['user_id'],axis=1)
product2.columns = ['has_attr_onehot_x'+str(i) for i in range(product2.shape[1])]
product2['user_id'] = product2_use
feature = pd.merge(feature, product2, how='left',on=['user_id'])
del product, product2
gc.collect()


###comment
print('comment')
comment = pd.read_csv('./new_data/comment.csv')
for i in [0,1,2,3,4]:
    comment['comment_num_'+str(i)] = 0
    comment.loc[comment['comment_num']==i,'comment_num_'+str(i)] = 1
comment2 = comment.loc[comment['dt'] == '2016-04-11',:]
comment3 = comment2.drop(['dt','comment_num'],axis=1)
feature = pd.merge(feature, comment3, how='left',on=['sku_id'])

comment3 = feature.loc[:,['user_id','sku_id']]
comment3 = pd.merge(comment3, comment2, how='left',on=['sku_id'])
comment2 = comment3.loc[:,['user_id','comment_num']]
comment3['comment_num_rank_dense'] = comment2.groupby(by=['user_id']).rank(method='dense',ascending=False)['comment_num']
comment2 = comment3.loc[:,['user_id','sku_id']]
comment2 = comment2.groupby(by=['user_id'],as_index=False).count()
comment2.columns = ['user_id','sku_count']
comment3 = pd.merge(comment3, comment2, how='left',on=['user_id'])
comment3['comment_num_rank_dense_chu_skucount'] = comment3['comment_num_rank_dense'] / comment3['sku_count']
comment2 = comment3.loc[:,['user_id','comment_num']]
comment3['comment_num_rank_max'] = comment2.groupby(by=['user_id']).rank(method='max',ascending=False)['comment_num']
comment3['comment_num_rank_max_chu_skucount'] = comment3['comment_num_rank_max'] / comment3['sku_count']
comment2 = comment3.loc[:,['comment_num_rank_dense','comment_num_rank_dense_chu_skucount','comment_num_rank_max','comment_num_rank_max_chu_skucount']]
feature = pd.concat([feature, comment2],axis=1)

comment2 = comment.loc[comment['dt'] == '2016-04-11',:]
comment3 = feature.loc[:,['user_id','sku_id']]
comment3 = pd.merge(comment3, comment2, how='left',on=['sku_id'])
comment3['bad_comment_rate'] = 1 - comment3['bad_comment_rate']
comment2 = comment3.loc[:,['user_id','bad_comment_rate']]
comment3['good_comment_rate_rank_dense'] = comment2.groupby(by=['user_id']).rank(method='dense',ascending=False)['bad_comment_rate']
comment2 = comment3.loc[:,['user_id','sku_id']]
comment2 = comment2.groupby(by=['user_id'],as_index=False).count()
comment2.columns = ['user_id','sku_count']
comment3 = pd.merge(comment3, comment2, how='left',on=['user_id'])
comment3['good_comment_rate_rank_dense_chu_skucount'] = comment3['good_comment_rate_rank_dense'] / comment3['sku_count']
comment2 = comment3.loc[:,['user_id','bad_comment_rate']]
comment3['good_comment_rate_rank_max'] = comment2.groupby(by=['user_id']).rank(method='max',ascending=False)['bad_comment_rate']
comment3['good_comment_rate_rank_max_chu_skucount'] = comment3['good_comment_rate_rank_max'] / comment3['sku_count']
comment2 = comment3.loc[:,['good_comment_rate_rank_dense','good_comment_rate_rank_dense_chu_skucount','good_comment_rate_rank_max','good_comment_rate_rank_max_chu_skucount']]
feature = pd.concat([feature, comment2],axis=1)

del comment, comment2, comment3


###buy_rate
print('buy_rate')
product_buy_rate = pd.read_csv('./feature_data/train_product_buy_rate.csv')
feature = pd.merge(feature, product_buy_rate, how='left',on=['sku_id'])
buy_rate = feature.loc[:,['user_id','sku_id','sku_buy_rate','brand_buy_rate']]
buy_rate['sku_buy_rate_rank_dense'] = buy_rate.loc[:,['user_id','sku_buy_rate']].groupby(by=['user_id']).rank(method='dense',ascending=False)['sku_buy_rate']
buy_rate['brand_buy_rate_rank_dense'] = buy_rate.loc[:,['user_id','brand_buy_rate']].groupby(by=['user_id']).rank(method='dense',ascending=False)['brand_buy_rate']
buy_rate['sku_buy_rate_rank_max'] = buy_rate.loc[:,['user_id','sku_buy_rate']].groupby(by=['user_id']).rank(method='max',ascending=False)['sku_buy_rate']
buy_rate['brand_buy_rate_rank_max'] = buy_rate.loc[:,['user_id','brand_buy_rate']].groupby(by=['user_id']).rank(method='max',ascending=False)['brand_buy_rate']

buy_rate2 = buy_rate.loc[:,['user_id','sku_id']]
buy_rate2 = buy_rate2.groupby(by=['user_id'],as_index=False).count()
buy_rate2.columns=['user_id','sku_count']
buy_rate = pd.merge(buy_rate, buy_rate2, how='left',on=['user_id'])

buy_rate['sku_buyrate_rankdense_chu_skucount'] = buy_rate['sku_buy_rate_rank_dense'] / buy_rate['sku_count']
buy_rate['sku_buyrate_rankmax_chu_skucount'] = buy_rate['sku_buy_rate_rank_max'] / buy_rate['sku_count']
buy_rate['brand_buyrate_rankdense_chu_skucount'] = buy_rate['brand_buy_rate_rank_dense'] / buy_rate['sku_count']
buy_rate['brand_buyrate_rankmax_chu_skucount'] = buy_rate['brand_buy_rate_rank_max'] / buy_rate['sku_count']

buy_rate = buy_rate.drop(['user_id','sku_id','sku_buy_rate','brand_buy_rate','sku_count'],axis=1)
feature = pd.concat([feature, buy_rate],axis=1)

del product_buy_rate, buy_rate, buy_rate2
gc.collect()

print('to_csv')
feature.to_csv('./feature_data/cate8_train_f2.csv',index=None,encoding='utf-8')

    


    