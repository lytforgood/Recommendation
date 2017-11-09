# -*- coding: utf-8 -*-
"""
Created on Wed Mar 29 12:50:43 2017

@author: mashiro
"""

import pandas as pd
import numpy as np
import gc

#all_buy_user = []
#for i in range(20):
#    action = pd.read_csv('./chunk_data/action_chunk'+str(i)+'.csv')
#    action['month'] = action['time'].apply(lambda x: int(x[5:7]))
#    action['day'] = action['time'].apply(lambda x: int(x[8:10]))
#    action = action.loc[((action['month'] == 4)&(action['day']>=11))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
#    all_buy_user.append(action)
#all_buy_user = pd.concat(all_buy_user)
#all_buy_user.to_csv('./feature_data/val_all_buy_user.csv',index=None,encoding='utf-8')




def get_chunk_feature(chunk):
    print('get data',chunk)
    action = pd.read_csv('./chunk_data/action_chunk'+str(chunk)+'.csv')
    action['month'] = action['time'].apply(lambda x: int(x[5:7]))
    action['day'] = action['time'].apply(lambda x: int(x[8:10]))
    action = action[action['month'] >= 2]
    action['day_s'] = action['month'].apply(lambda x: {0:0,1:29,2:60}[x-2])
    action['day_s'] = action['day_s'] + action['day'] -1
    action = action.sort_values(by=['user_id','time'])
    
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
    
    #把购买中有过交互的user-sku对作为已购买
#    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
#    has_action = has_action.loc[:,['user_id','sku_id']].drop_duplicates()
#    y = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id','sku_id']].drop_duplicates()
#    y['label'] = 1
#    y = pd.merge(has_action,y, how='left',on=['user_id','sku_id'])
#    y = y.fillna(0)
#    y = y.drop(['sku_id'],axis=1)
#    y = y.groupby(by=['user_id'],as_index=False).max()

    
#    print('get y',chunk)
#    #把购买中出现过cate8产品交互的用户作为已购买
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8),['user_id']].drop_duplicates()
    y = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
    y['label'] = 1
    y = pd.merge(has_action,y, how='left',on=['user_id'])
    y = y.fillna(0)

    ##预测所有出现过的user
#    has_action = action.loc[(action['month']<4)|(action['day']<=10),['user_id']].drop_duplicates()
#    y = action.loc[((action['month']==4)&(action['day']>10))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
#    y['label'] = 1
#    y = pd.merge(has_action,y, how='left',on=['user_id'])
#    y = y.fillna(0)
    
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(1, chunk)
    ###最后一天交互cate8产品距离天数,  last_days
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #mid_y = y.loc[:,['user_id']]
    #has_action = pd.merge(has_action, mid_y, how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','day_s']].groupby(by=['user_id'],as_index=False).max()
    has_action['last_days'] = 70 - has_action['day_s']
    has_action = has_action.drop(['day_s'],axis=1)
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(2, chunk)
    ###cate8产品交互的间隔天数的（mean, median, max, min）jiangedays_xxx
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','day_s']].drop_duplicates().sort_values(['user_id','day_s'])
    has_action2 = pd.DataFrame()
    has_action2['user_id'] = has_action['user_id'][:-1]
    has_action2['user_id2'] = has_action['user_id'][1:] - has_action['user_id'][:-1]
    has_action2['days'] = has_action['day_s'][1:] - has_action['day_s'][:-1]
    has_action2 = has_action2.loc[has_action2['user_id2'] == 0,['user_id','days']]
    has_action = has_action2.groupby(by=['user_id'], as_index=False).mean()
    has_action.columns = ['user_id', 'jiangedays_mean']
    has_action['jiangedays_median'] = has_action2.groupby(by=['user_id'], as_index=False).median()['days']
    has_action['jiangedays_max'] = has_action2.groupby(by=['user_id'], as_index=False).max()['days']
    has_action['jiangedays_min'] = has_action2.groupby(by=['user_id'], as_index=False).min()['days']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(3, chunk)
    ###cate8产品总交互次数，type1~6各类别交互操作次数
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','type']]
    has_action2 = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action2.columns=['user_id','all_jiaohu_count']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    for i in range(1,7):
        has_action2 = has_action[has_action['type'] == i]
        has_action2 = has_action2.groupby(by=['user_id'],as_index=False).count()
        has_action2.columns=['user_id','type'+str(i)+'_jiaohu_count']
        y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(4, chunk)
    ###cate8交互的产品数，cate8各个产品的交互的（总数，type1~6）操作数的（mean,mdian,max,min）
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','sku_id','type']]
    has_action2 = has_action.loc[:,['user_id','sku_id']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).count()
    has_action2.columns = ['user_id','has_jiaohu_sku']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    
    has_action2 = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action2.loc[:,['user_id','type']]
    has_acti = has_action2.groupby(by=['user_id'],as_index=False).mean()
    has_acti.columns = ['user_id','sku_all_jiaohu_mean']
    has_acti['sku_all_jiaohu_median'] = has_action2.groupby(by=['user_id'],as_index=False).median()['type']
    has_acti['sku_all_jiaohu_max'] = has_action2.groupby(by=['user_id'],as_index=False).max()['type']
    has_acti['sku_all_jiaohu_min'] = has_action2.groupby(by=['user_id'],as_index=False).min()['type']
    y = pd.merge(y, has_acti, how='left',on=['user_id'])
    
    for i in range(1,7):
        has_action2 = has_action[has_action['type'] == i]
        has_action2 = has_action2.groupby(by=['user_id','sku_id'],as_index=False).count()
        has_action2 = has_action2.loc[:,['user_id','type']]
        has_acti = has_action2.groupby(by=['user_id'],as_index=False).mean()
        has_acti.columns = ['user_id','sku_type'+str(i)+'_jiaohu_mean']
        has_acti['sku_type'+str(i)+'_jiaohu_median'] = has_action2.groupby(by=['user_id'],as_index=False).median()['type']
        has_acti['sku_type'+str(i)+'_jiaohu_max'] = has_action2.groupby(by=['user_id'],as_index=False).max()['type']
        has_acti['sku_type'+str(i)+'_jiaohu_min'] = has_action2.groupby(by=['user_id'],as_index=False).min()['type']
        y = pd.merge(y, has_acti, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2, has_acti
    gc.collect()
    #print (y.shape)
    
    #print(5, chunk)
    ###cate8交互天数，各个产品交互天数的（mean,median,min.max）
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action2 = has_action.loc[:,['user_id','day_s']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).count()
    has_action2.columns = ['user_id','has_jiaohu_days']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    has_action2 = has_action.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action2.loc[:,['user_id','day_s']]
    has_action = has_action2.groupby(by=['user_id'],as_index=False).mean()
    has_action.columns = ['user_id','sku_jiaohu_days_mean']
    has_action['sku_jiaohu_days_median'] = has_action2.groupby(by=['user_id'],as_index=False).median()['day_s']
    has_action['sku_jiaohu_days_max'] = has_action2.groupby(by=['user_id'],as_index=False).max()['day_s']
    has_action['sku_jiaohu_days_min'] = has_action2.groupby(by=['user_id'],as_index=False).min()['day_s']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(6, chunk)
    ###cate8交互次数， 各个产品交互次数的（mean,median,min,max）
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action2 = has_action.loc[:,['user_id','same_list']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).count()
    has_action2.columns = ['user_id','has_jiaohu_cishu']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    has_action2 = has_action.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
    has_action2 = has_action2.groupby(by=['user_id','sku_id'],as_index=False).count()
    has_action2 = has_action2.loc[:,['user_id','same_list']]
    has_action = has_action2.groupby(by=['user_id'],as_index=False).mean()
    has_action.columns = ['user_id','sku_jiaohu_cishu_mean']
    has_action['sku_jiaohu_cishu_median'] = has_action2.groupby(by=['user_id'],as_index=False).median()['same_list']
    has_action['sku_jiaohu_cishu_max'] = has_action2.groupby(by=['user_id'],as_index=False).max()['same_list']
    has_action['sku_jiaohu_cishu_min'] = has_action2.groupby(by=['user_id'],as_index=False).min()['same_list']
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(7, chunk)
    ###购物车中是否有cate8商品/商品数，是否加过cate8商品/商品数
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','sku_id','type']]
    has_action['jia_gouwuche'] = 0
    has_action.loc[has_action['type']==2,['jia_gouwuche']] = 1
    has_action.loc[has_action['type']==3,['jia_gouwuche']] = -1
    has_action2 = has_action.loc[:,['user_id','sku_id','jia_gouwuche']].groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action2 = has_action2.loc[has_action2['jia_gouwuche']>0,['user_id']]
    has_action2['gouwuche_sku_num'] = 1
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).sum()
    has_action2['in_gouwuche'] = 1
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    has_action2 = has_action.loc[has_action['jia_gouwuche']==1,['user_id','sku_id']].drop_duplicates()
    has_action2['jiaguo_gouwuche_sku_num'] = 1
    has_action2 = has_action2.drop(['sku_id'],axis=1)
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).sum()
    has_action2['jiaguo_gouwuche'] = 1
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(8, chunk)
    ###是否关注了cate8商品
    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action = has_action.loc[:,['user_id','sku_id','type']]
    has_action['guanzhu'] = 0
    has_action.loc[has_action['type']==5,['guanzhu']] = 1
    has_action2 = has_action.loc[has_action['guanzhu']==1,['user_id','sku_id']].drop_duplicates()
    has_action2['guanzhu_sku_num'] = 1
    has_action2 = has_action2.drop(['sku_id'],axis=1)
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).sum()
    has_action2['has_guanzhu'] = 1
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(9, chunk)
    ###近30天是否下单cate8产品
    has_action = action.loc[(((action['month']==4)&(action['day']<=10))|((action['month']==3)&(action['day']>=12)))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    #has_action = has_action.loc[:,['user_id','sku_id','type']]
    has_action['zuijin30_xiadan'] = 1
    #has_action.loc[has_action['type']==4,['zuijin30_xiadan']] = 1
    #has_action2 = has_action.loc[has_action['zuijin30_xiadan']==1,['user_id','zuijin30_xiadan']].drop_duplicates()
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(10, chunk)
    ###是否对cate8下过单
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    #has_action = has_action.loc[:,['user_id','sku_id','type']]
    has_action['cate8_xiadan'] = 1
    #has_action.loc[has_action['type']==4,['cate8_xiadan']] = 1
    #has_action2 = has_action.loc[has_action['cate8_xiadan']==1,['user_id','cate8_xiadan']].drop_duplicates()
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(11, chunk)
    ###是否下过单
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['type']==4),['user_id']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    #has_action = has_action.loc[:,['user_id','sku_id','type']]
    #has_action = has_action.loc[:,['user_id']].drop_duplicates()
    has_action['xiadan'] = 1
    #has_action.loc[has_action['type']==4,['xiadan']] = 1
    #has_action2 = has_action.loc[has_action['xiadan']==1,['user_id','xiadan']]
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(12, chunk)
    ###是否对非cate8产品下过单
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8)&(action['type']==4),['user_id']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    #has_action = has_action.loc[:,['user_id','sku_id','type']]
    #has_action = has_action.loc[:,['user_id']]
    has_action['nocate8_xiadan'] = 1
    #has_action.loc[has_action['type']==4,['nocate8_xiadan']] = 1
    #has_action2 = has_action.loc[has_action['nocate8_xiadan']==1,['user_id','nocate8_xiadan']]
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(13, chunk)
    ###交互过的非cate8产品数
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8),['user_id','sku_id']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action['has_nocate8_jiaohu_sku'] = 1
    has_action = has_action.drop(['sku_id'],axis=1)
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(14, chunk)
    ###交互过的非cate8产品天数
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8),['user_id','day_s']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action['has_nocate8_jiaohu_days'] = 1
    has_action = has_action.drop(['day_s'],axis=1)
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(15, chunk)
    ###交互过的非cate8产品次数
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8),['user_id','same_list']].drop_duplicates()
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action['has_nocate8_jiaohu_cishu'] = 1
    has_action = has_action.drop(['same_list'],axis=1)
    has_action = has_action.groupby(by=['user_id'],as_index=False).sum()
    y = pd.merge(y, has_action, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action
    gc.collect()
    #print (y.shape)
    
    #print(16, chunk)
    ###购物车中是否有非cate8商品/商品数，是否加过非cate8商品/商品数
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8),['user_id','sku_id','type']]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    has_action['jia_gouwuche'] = 0
    has_action.loc[has_action['type']==2,['jia_gouwuche']] = 1
    has_action.loc[has_action['type']==3,['jia_gouwuche']] = -1
    has_action2 = has_action.loc[:,['user_id','sku_id','jia_gouwuche']].groupby(by=['user_id','sku_id'],as_index=False).sum()
    has_action2 = has_action2.loc[has_action2['jia_gouwuche']>0,['user_id']]
    has_action2['gouwuche_nocate8sku_num'] = 1
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).sum()
    has_action2['nocate8_in_gouwuche'] = 1
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    has_action2 = has_action.loc[has_action['jia_gouwuche']==1,['user_id','sku_id']].drop_duplicates()
    has_action2['jiaguo_gouwuche_nocate8sku_num'] = 1
    has_action2 = has_action2.drop(['sku_id'],axis=1)
    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).sum()
    has_action2['jiaguo_gouwuche'] = 1
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    #print (y.shape)
    
    #print(17, chunk)
    ###非cate8产品总交互次数，type1~6各类别交互操作次数
    has_action = action.loc[((action['month']<4)|(action['day']<=10))&(action['cate']!=8),['user_id','type']]
    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
    #has_action = has_action.loc[:,['user_id','type']]
    has_action2 = has_action.groupby(by=['user_id'],as_index=False).count()
    has_action2.columns=['user_id','nocate8_all_jiaohu_count']
    y = pd.merge(y, has_action2, how='left',on=['user_id'])
    for i in range(1,7):
        has_action2 = has_action[has_action['type'] == i]
        has_action2 = has_action2.groupby(by=['user_id'],as_index=False).count()
        has_action2.columns=['user_id','nocate8_type'+str(i)+'_jiaohu_count']
        y = pd.merge(y, has_action2, how='left',on=['user_id'])
    y = y.fillna(0)
    del has_action, has_action2
    gc.collect()
    print (y.shape)
    
    
    
#    product = pd.read_csv('./product.csv')
#    
#    product['attr1_0'] = product['attr1'].apply(lambda x: 1 if x == -1 else 0)
#    product['attr1_1'] = product['attr1'].apply(lambda x: 1 if x == 1 else 0)
#    product['attr1_2'] = product['attr1'].apply(lambda x: 1 if x == 2 else 0)
#    product['attr1_3'] = product['attr1'].apply(lambda x: 1 if x == 3 else 0)
#    
#    product['attr2_0'] = product['attr2'].apply(lambda x: 1 if x == -1 else 0)
#    product['attr2_1'] = product['attr2'].apply(lambda x: 1 if x == 1 else 0)
#    product['attr2_2'] = product['attr2'].apply(lambda x: 1 if x == 2 else 0)
#    
#    product['attr3_0'] = product['attr2'].apply(lambda x: 1 if x == -1 else 0)
#    product['attr3_1'] = product['attr2'].apply(lambda x: 1 if x == 1 else 0)
#    product['attr3_2'] = product['attr2'].apply(lambda x: 1 if x == 2 else 0)
#    
#
#    ###交互次数最多的sku对应attr1,2,3 onehot
#    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
#    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
#    has_action = has_action.loc[:,['user_id','sku_id','same_list']].drop_duplicates()
#    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
#    has_action2 = has_action.loc[:,['user_id','same_list']]
#    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).max()
#    has_action2 = pd.merge(has_action2, has_action, how='left',on=['user_id','same_list'])
#    has_action2 = has_action2.loc[:,['user_id','sku_id']]
#    has_action2 = pd.merge(has_action2, product, how='left',on=['sku_id'])
#    has_action2 = has_action2.loc[:,['user_id','attr1_0','attr1_1','attr1_2','attr1_3','attr2_0','attr2_1','attr2_2','attr3_0','attr3_1','attr3_2']]
#    has_action2.columns = ['user_id','most_cishu_attr1_0','most_cishu_attr1_1','most_cishu_attr1_2','most_cishu_attr1_3',
#                           'most_cishu_attr2_0','most_cishu_attr2_1','most_cishu_attr2_2',
#                           'most_cishu_attr3_0','most_cishu_attr3_1','most_cishu_attr3_2']
#                           
#    y = pd.merge(y, has_action2, how='left',on=['user_id'])
#    y = y.fillna(0)
#    del has_action, has_action2
#    gc.collect()
#    print (y.shape)
#    
#    print(18, chunk)
#    ###交互天数最多的sku对应attr1,2,3 onehot
#    has_action = action[((action['month']<4)|(action['day']<=10))&(action['cate']==8)]
#    #has_action = pd.merge(has_action, y.loc[:,['user_id']], how='inner',on=['user_id'])
#    has_action = has_action.loc[:,['user_id','sku_id','day_s']].drop_duplicates()
#    has_action = has_action.groupby(by=['user_id','sku_id'],as_index=False).count()
#    has_action2 = has_action.loc[:,['user_id','day_s']]
#    has_action2 = has_action2.groupby(by=['user_id'],as_index=False).max()
#    has_action2 = pd.merge(has_action2, has_action, how='left',on=['user_id','day_s'])
#    has_action2 = has_action2.loc[:,['user_id','sku_id']]
#    has_action2 = pd.merge(has_action2, product, how='left',on=['sku_id'])
#    has_action2 = has_action2.loc[:,['user_id','attr1_0','attr1_1','attr1_2','attr1_3','attr2_0','attr2_1','attr2_2','attr3_0','attr3_1','attr3_2']]
#    has_action2.columns = ['user_id','most_days_attr1_0','most_days_attr1_1','most_days_attr1_2','most_days_attr1_3',
#                           'most_days_attr2_0','most_days_attr2_1','most_days_attr2_2',
#                           'most_days_attr3_0','most_days_attr3_1','most_days_attr3_2']
#                           
#    y = pd.merge(y, has_action2, how='left',on=['user_id'])
#    y = y.fillna(0)
#    del has_action, has_action2
#    gc.collect()
#    print (y.shape)
    
    y.to_csv('./chunk_feature/cate8_feature_chunk'+str(chunk)+'.csv',index=None, encoding='utf-8')
    
    has_action = action.loc[((action['month'] == 4)&(action['day']>=11))&(action['cate']==8)&(action['type']==4),['user_id']].drop_duplicates()
    return has_action
    del  action,y
    gc.collect()
    
all_buy_user = []
for i in range(20):
    print('chunk',i)
    buy_user = get_chunk_feature(i)
    all_buy_user.append(buy_user)
all_buy_user = pd.concat(all_buy_user)
#all_buy_user.to_csv('./feature_data/val_all_buy_user.csv',index=None,encoding='utf-8')

###user
print('user')
feature = []
for i in range(20):
    y = pd.read_csv('./chunk_feature/cate8_feature_chunk'+str(i)+'.csv')
    feature.append(y)
feature = pd.concat(feature)

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
feature.to_csv('./feature_data/cate8_train.csv',index=None,encoding='utf-8')



