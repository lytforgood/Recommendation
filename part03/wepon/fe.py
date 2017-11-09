#coding=utf-8

import pandas as pd

"""
对user，sku，brand，user-sku，user-cate，user-brand提取相关特征

"""

def get_user_feature(data):
    '''
    browse_cnt,  add_cart_cnt,  delete_cart_cnt,  buy_cnt,  interest_cnt,  click_cnt
    browse_unique_sku_cnt,  browse_unique_cate_cnt,  browse_unique_brand_cnt
    add_cart_unique_sku_cnt,  add_cart_unique_cate_cnt,  add_cart_unique_brand_cnt,
    delete_cart_unique_sku_cnt,  delete_cart_unique_cate_cnt,  delete_cart_unique_brand_cnt,
    buy_unique_sku_cnt,  buy_unique_cate_cnt,  buy_unique_brand_cnt,
    interest_unique_sku_cnt,  interest_unique_cate_cnt,  interest_unique_brand_cnt,
    click_unique_sku_cnt,  click_unique_cate_cnt,  click_unique_brand_cnt,
    active_day
    
    '''
    t1 = data[['user_id','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['user_id','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index='user_id',columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'browse_cnt',2:'add_cart_cnt',3:'delete_cart_cnt',4:'buy_cnt',5:'interest_cnt',6:'click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_uf1'] = 0.1*t1.browse_cnt + 0.5*t1.add_cart_cnt - 0.2*t1.delete_cart_cnt + 2.0*t1.buy_cnt + 0.3*t1.interest_cnt + 0.02*t1.click_cnt
    t1['weighted_uf2'] = 0.2*t1.browse_cnt + 0.5*t1.add_cart_cnt + 0.2*t1.delete_cart_cnt + 2.0*t1.buy_cnt + 0.5*t1.interest_cnt + 0.02*t1.click_cnt
    t1['weighted_uf3'] = 0.2*t1.browse_cnt + 0.8*t1.add_cart_cnt + 0.2*t1.delete_cart_cnt + 3.0*t1.buy_cnt + 0.5*t1.interest_cnt + 0.01*t1.click_cnt
    
    
    #browse how many unique sku
    t2 = data[['user_id','sku_id','type']].drop_duplicates()[['user_id','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['user_id','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index='user_id',columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'browse_unique_sku_cnt',2:'add_cart_unique_sku_cnt',3:'delete_cart_unique_sku_cnt',\
                       4:'buy_unique_sku_cnt',5:'interest_unique_sku_cnt',6:'click_unique_sku_cnt'},inplace=True)
    t2.fillna(0,inplace=True)   
    t2['unique_sku_buy_browse_rate'] = (t2.buy_unique_sku_cnt - 0.01) / (t2.browse_unique_sku_cnt + 0.01)
    
    
    t3 = data[['user_id','cate','type']].drop_duplicates()[['user_id','type']]
    t3['cnt'] = 1
    t3 = t3.groupby(['user_id','type']).agg('sum').reset_index()
    t3 = t3.pivot_table(index='user_id',columns='type',values='cnt').reset_index()
    t3.rename(columns={1:'browse_unique_cate_cnt',2:'add_cart_unique_cate_cnt',3:'delete_cart_unique_cate_cnt',\
                       4:'buy_unique_cate_cnt',5:'interest_unique_cate_cnt',6:'click_unique_cate_cnt'},inplace=True)
    t3.fillna(0,inplace=True)
    
    t4 = data[['user_id','brand','type']].drop_duplicates()[['user_id','type']]
    t4['cnt'] = 1
    t4 = t4.groupby(['user_id','type']).agg('sum').reset_index()
    t4 = t4.pivot_table(index='user_id',columns='type',values='cnt').reset_index()
    t4.rename(columns={1:'browse_unique_brand_cnt',2:'add_cart_unique_brand_cnt',3:'delete_cart_unique_brand_cnt',\
                       4:'buy_unique_brand_cnt',5:'interest_unique_brand_cnt',6:'click_unique_brand_cnt'},inplace=True)
    t4.fillna(0,inplace=True)
    t4['unique_brand_buy_browse_rate'] = (t4.buy_unique_brand_cnt - 0.01) / (t4.browse_unique_brand_cnt + 0.01)
    
    t5 = data[['user_id','time']].drop_duplicates()[['user_id']]
    t5['active_day'] = 1
    t5 = t5.groupby(['user_id']).agg('sum').reset_index()
    
    user_feature = pd.merge(t1,t2,on='user_id')
    user_feature = pd.merge(user_feature,t3,on='user_id')
    user_feature = pd.merge(user_feature,t4,on='user_id')
    user_feature = pd.merge(user_feature,t5,on='user_id')
    return user_feature
    
    
def get_sku_feature(data):
    '''
    sku_browse_cnt,sku_add_cart_cnt,sku_delete_cart_cnt,sku_buy_cnt,sku_interest_cnt,sku_click_cnt
    sku_unique_user_browse_cnt,
    sku_unique_user_add_cart_cnt,
    sku_unique_user_delete_cart_cnt,
    sku_unique_user_buy_cnt,
    sku_unique_user_interest_cnt,
    sku_unique_user_click_cnt
    '''
    t1 = data[['sku_id','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['sku_id','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index='sku_id',columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'sku_browse_cnt',2:'sku_add_cart_cnt',3:'sku_delete_cart_cnt',4:'sku_buy_cnt',5:'sku_interest_cnt',6:'sku_click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_sf1'] = 0.1*t1.sku_browse_cnt + 0.5*t1.sku_add_cart_cnt - 0.2*t1.sku_delete_cart_cnt + 2.0*t1.sku_buy_cnt + 0.3*t1.sku_interest_cnt + 0.02*t1.sku_click_cnt
    t1['weighted_sf2'] = 0.2*t1.sku_browse_cnt + 0.5*t1.sku_add_cart_cnt + 0.2*t1.sku_delete_cart_cnt + 3.0*t1.sku_buy_cnt + 0.5*t1.sku_interest_cnt + 0.02*t1.sku_click_cnt
    t1['sku_buy_browse_rate'] = (t1.sku_buy_cnt - 0.01) / (t1.sku_browse_cnt + 0.01)
    t1['sku_buy_add_cart_rate'] = (t1.sku_buy_cnt - 0.01) / (t1.sku_add_cart_cnt + 0.01)
    
    t2 = data[['user_id','sku_id','type']].drop_duplicates()[['sku_id','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['sku_id','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index='sku_id',columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'sku_unique_user_browse_cnt',2:'sku_unique_user_add_cart_cnt',3:'sku_unique_user_delete_cart_cnt',\
                       4:'sku_unique_user_buy_cnt',5:'sku_unique_user_interest_cnt',6:'sku_unique_user_click_cnt'},inplace=True)
    t2.fillna(0,inplace=True)
    
    t3 = data[['user_id','sku_id']].drop_duplicates()[['sku_id']]
    t3['sku_unique_user_cnt'] = 1
    t3 = t3.groupby(['sku_id']).agg('sum').reset_index()
    t3.fillna(0,inplace=True)
    
    sku_feature = pd.merge(t1,t2,on='sku_id')
    sku_feature = pd.merge(sku_feature,t3,on='sku_id')
    return sku_feature
    

def get_brand_feature(data):
    '''
    brand_browse_cnt,brand_add_cart_cnt,brand_delete_cart_cnt,brand_buy_cnt,brand_interest_cnt,brand_click_cnt
    brand_unique_user_browse_cnt,
    brand_unique_user_add_cart_cnt,
    brand_unique_user_delete_cart_cnt,
    brand_unique_user_buy_cnt,
    brand_unique_user_interest_cnt,
    brand_unique_user_click_cnt
    '''
    t1 = data[['brand','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['brand','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index='brand',columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'brand_browse_cnt',2:'brand_add_cart_cnt',3:'brand_delete_cart_cnt',4:'brand_buy_cnt',5:'brand_interest_cnt',6:'brand_click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_bf1'] = 0.1*t1.brand_browse_cnt + 0.5*t1.brand_add_cart_cnt - 0.2*t1.brand_delete_cart_cnt + 2.0*t1.brand_buy_cnt + 0.3*t1.brand_interest_cnt + 0.02*t1.brand_click_cnt
    t1['weighted_bf2'] = 0.2*t1.brand_browse_cnt + 0.5*t1.brand_add_cart_cnt + 0.2*t1.brand_delete_cart_cnt + 3.0*t1.brand_buy_cnt + 0.5*t1.brand_interest_cnt + 0.02*t1.brand_click_cnt
    t1['brand_buy_browse_rate'] = (t1.brand_buy_cnt - 0.01) / (t1.brand_browse_cnt + 0.01)
    t1['brand_buy_add_cart_rate'] = (t1.brand_buy_cnt - 0.01) / (t1.brand_add_cart_cnt + 0.01)
    
    t2 = data[['user_id','brand','type']].drop_duplicates()[['brand','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['brand','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index='brand',columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'brand_unique_user_browse_cnt',2:'brand_unique_user_add_cart_cnt',3:'brand_unique_user_delete_cart_cnt',\
                       4:'brand_unique_user_buy_cnt',5:'brand_unique_user_interest_cnt',6:'brand_unique_user_click_cnt'},inplace=True)
    t2.fillna(0,inplace=True)
    
    brand_feature = pd.merge(t1,t2,on='brand')
    return brand_feature
    
    
def get_user_sku_feature(data):
    '''
    user_sku_browse_cnt,         user_sku_browse_day
    user_sku_add_cart_cnt,         user_sku_add_cart_day
    user_sku_delete_cart_cnt,         user_sku_delete_cart_day
    user_sku_buy_cnt,         user_sku_buy_day
    user_sku_interest_cnt,         user_sku_interest_day
    user_sku_click_cnt,         user_sku_click_day
    '''
    t1 = data[['user_id','sku_id','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['user_id','sku_id','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index=['user_id','sku_id'],columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'user_sku_browse_cnt',2:'user_sku_add_cart_cnt',3:'user_sku_delete_cart_cnt',\
                       4:'user_sku_buy_cnt',5:'user_sku_interest_cnt',6:'user_sku_click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_usf1'] = 0.1*t1.user_sku_browse_cnt + 0.5*t1.user_sku_add_cart_cnt - 0.2*t1.user_sku_delete_cart_cnt + \
                          2.0*t1.user_sku_buy_cnt + 0.3*t1.user_sku_interest_cnt + 0.02*t1.user_sku_click_cnt
    t1['weighted_usf2'] = 0.2*t1.user_sku_browse_cnt + 0.5*t1.user_sku_add_cart_cnt + 0.2*t1.user_sku_delete_cart_cnt + \
                          3.0*t1.user_sku_buy_cnt + 0.5*t1.user_sku_interest_cnt + 0.02*t1.user_sku_click_cnt
    
    
    t2 = data[['user_id','sku_id','time','type']].drop_duplicates()[['user_id','sku_id','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['user_id','sku_id','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index=['user_id','sku_id'],columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'user_sku_browse_day',2:'user_sku_add_cart_day',3:'user_sku_delete_cart_day',\
                       4:'user_sku_buy_day',5:'user_sku_interest_day',6:'user_sku_click_day'},inplace=True)
    t2.fillna(0,inplace=True)
    
    t3 = data[['user_id','sku_id','time']].drop_duplicates()[['user_id','sku_id']]
    t3['user_sku_active_day'] = 1
    t3 = t3.groupby(['user_id','sku_id']).agg('sum').reset_index()
    t3.fillna(0,inplace=True)
    
    
    user_sku_feature = pd.merge(t1,t2,on=['user_id','sku_id'])
    user_sku_feature = pd.merge(user_sku_feature,t3,on=['user_id','sku_id'])
    return user_sku_feature
    


def get_user_cate_feature(data):
    '''
     user_cate_browse_cnt,     user_cate_browse_day
     user_cate_add_cart_cnt,     user_cate_add_cart_day
     user_cate_delete_cart_cnt,    user_cate_delete_cart_day
     user_cate_buy_cnt,            user_cate_buy_day
     user_cate_interest_cnt,     user_cate_interest_day
     user_cate_click_cnt,         user_cate_click_day  
    '''
    t1 = data[data.cate==8][['user_id','cate','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['user_id','cate','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index=['user_id','cate'],columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'user_cate_browse_cnt',2:'user_cate_add_cart_cnt',3:'user_cate_delete_cart_cnt',\
                       4:'user_cate_buy_cnt',5:'user_cate_interest_cnt',6:'user_cate_click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_ucf1'] = 0.1*t1.user_cate_browse_cnt + 0.5*t1.user_cate_add_cart_cnt - 0.2*t1.user_cate_delete_cart_cnt + \
                          1.5*t1.user_cate_buy_cnt + 0.3*t1.user_cate_interest_cnt + 0.01*t1.user_cate_click_cnt
    t1['weighted_ucf2'] = 0.2*t1.user_cate_browse_cnt + 0.5*t1.user_cate_add_cart_cnt + 0.2*t1.user_cate_delete_cart_cnt + \
                          2.0*t1.user_cate_buy_cnt + 0.5*t1.user_cate_interest_cnt + 0.015*t1.user_cate_click_cnt
    t1['weighted_ucf3'] = 0.2*t1.user_cate_browse_cnt + 0.8*t1.user_cate_add_cart_cnt + 0.2*t1.user_cate_delete_cart_cnt + \
                          3.0*t1.user_cate_buy_cnt + 0.5*t1.user_cate_interest_cnt + 0.02*t1.user_cate_click_cnt
    
    
    t2 = data[data.cate==8][['user_id','cate','time','type']].drop_duplicates()[['user_id','cate','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['user_id','cate','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index=['user_id','cate'],columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'user_cate_browse_day',2:'user_cate_add_cart_day',3:'user_cate_delete_cart_day',\
                       4:'user_cate_buy_day',5:'user_cate_interest_day',6:'user_cate_click_day'},inplace=True)
    t2.fillna(0,inplace=True)
    
    
    t3 = data[data.cate==8][['user_id','cate','time']].drop_duplicates()[['user_id','cate']]
    t3['user_cate_active_day'] = 1
    t3 = t3.groupby(['user_id','cate']).agg('sum').reset_index()
    t3.fillna(0,inplace=True)
    
    #browse/click.. how many unique sku in cate8
    t4 = data[data.cate==8][['user_id','cate','sku_id','type']].drop_duplicates()[['user_id','cate','type']]
    t4['cnt'] = 1
    t4 = t4.groupby(['user_id','cate','type']).agg('sum').reset_index()
    t4 = t4.pivot_table(index=['user_id','cate'],columns='type',values='cnt').reset_index()
    t4.rename(columns={1:'browse_cate8_unique_sku_cnt',2:'add_cate8_cart_unique_sku_cnt',3:'delete_cate8_cart_unique_sku_cnt',\
                       4:'buy_cate8_unique_sku_cnt',5:'interest_cate8_unique_sku_cnt',6:'click_cate8_unique_sku_cnt'},inplace=True)
    t4.fillna(0,inplace=True)
    
    
    user_cate_feature = pd.merge(t1,t2,on=['user_id','cate'])
    user_cate_feature = pd.merge(user_cate_feature,t3,on=['user_id','cate'])
    user_cate_feature = pd.merge(user_cate_feature,t4,on=['user_id','cate'])
    return user_cate_feature


def get_user_brand_feature(data):
    '''
    user_brand_browse_cnt,          user_brand_browse_day
    user_brand_add_cart_cnt,        user_brand_add_cart_day
    user_brand_delete_cart_cnt,      user_brand_delete_cart_day
    user_brand_buy_cnt,           user_brand_buy_day
    user_brand_interest_cnt,         user_brand_interest_day
    user_brand_click_cnt,           user_brand_click_day   
    
    '''
    t1 = data[['user_id','brand','type']]
    t1['cnt'] = 1
    t1 = t1.groupby(['user_id','brand','type']).agg('sum').reset_index()
    t1 = t1.pivot_table(index=['user_id','brand'],columns='type',values='cnt').reset_index()
    t1.rename(columns={1:'user_brand_browse_cnt',2:'user_brand_add_cart_cnt',3:'user_brand_delete_cart_cnt',\
                       4:'user_brand_buy_cnt',5:'user_brand_interest_cnt',6:'user_brand_click_cnt'},inplace=True)
    t1.fillna(0,inplace=True)
    t1['weighted_ubf1'] = 0.1*t1.user_brand_browse_cnt + 0.5*t1.user_brand_add_cart_cnt - 0.2*t1.user_brand_delete_cart_cnt + \
                          1.5*t1.user_brand_buy_cnt + 0.3*t1.user_brand_interest_cnt + 0.01*t1.user_brand_click_cnt
    t1['weighted_ubf2'] = 0.2*t1.user_brand_browse_cnt + 0.5*t1.user_brand_add_cart_cnt + 0.2*t1.user_brand_delete_cart_cnt + \
                          2.0*t1.user_brand_buy_cnt + 0.5*t1.user_brand_interest_cnt + 0.015*t1.user_brand_click_cnt
    t1['weighted_ubf3'] = 0.2*t1.user_brand_browse_cnt + 0.8*t1.user_brand_add_cart_cnt + 0.2*t1.user_brand_delete_cart_cnt + \
                          3.0*t1.user_brand_buy_cnt + 0.5*t1.user_brand_interest_cnt + 0.02*t1.user_brand_click_cnt
    
    
    t2 = data[['user_id','brand','time','type']].drop_duplicates()[['user_id','brand','type']]
    t2['cnt'] = 1
    t2 = t2.groupby(['user_id','brand','type']).agg('sum').reset_index()
    t2 = t2.pivot_table(index=['user_id','brand'],columns='type',values='cnt').reset_index()
    t2.rename(columns={1:'user_brand_browse_day',2:'user_brand_add_cart_day',3:'user_brand_delete_cart_day',\
                       4:'user_brand_buy_day',5:'user_brand_interest_day',6:'user_brand_click_day'},inplace=True)
    t2.fillna(0,inplace=True)
    
    t3 = data[['user_id','brand','time']].drop_duplicates()[['user_id','brand']]
    t3['user_brand_active_day'] = 1
    t3 = t3.groupby(['user_id','brand']).agg('sum').reset_index()
    t3.fillna(0,inplace=True)
    
    #browse/click.. how many unique sku in brand
    t4 = data[['user_id','brand','sku_id','type']].drop_duplicates()[['user_id','brand','type']]
    t4['cnt'] = 1
    t4 = t4.groupby(['user_id','brand','type']).agg('sum').reset_index()
    t4 = t4.pivot_table(index=['user_id','brand'],columns='type',values='cnt').reset_index()
    t4.rename(columns={1:'browse_brand_unique_sku_cnt',2:'add_brand_cart_unique_sku_cnt',3:'delete_brand_cart_unique_sku_cnt',\
                       4:'buy_brand_unique_sku_cnt',5:'interest_brand_unique_sku_cnt',6:'click_brand_unique_sku_cnt'},inplace=True)
    t4.fillna(0,inplace=True)
    
    user_brand_feature = pd.merge(t1,t2,on=['user_id','brand'])
    user_brand_feature = pd.merge(user_brand_feature,t3,on=['user_id','brand'])
    user_brand_feature = pd.merge(user_brand_feature,t4,on=['user_id','brand'])
    return user_brand_feature
    
