# -*- coding: utf-8 -*-
"""
Created on Wed Apr 12 22:19:40 2017

@author: mashiro
"""


import numpy as np
import pandas as pd
import xgboost as xgb

train = pd.read_csv('./feature_data/cate8_train_f2.csv')
train_y = train['label']
train_user = train.loc[:,['user_id','sku_id']]
train_x = train.drop(['user_id','sku_id','label'],axis=1)

test = pd.read_csv('./feature_data/cate8_test_f2.csv')
test_user = test.loc[:,['user_id','sku_id']]
test_x = test.drop(['user_id','sku_id'],axis=1)

dtrain = xgb.DMatrix(train_x, label=train_y)
dtest = xgb.DMatrix(test_x)


def get_f11(pred, label):
    a = pd.DataFrame()
    a['pred'] = pred
    a['label'] = label
    a = a.sort_values(by=['pred'],ascending=False)
    p = sum(np.ravel(a['label'])[:800])/800.0
    r = sum(np.ravel(a['label'])[:800])/800.0
    f11 = 6*p*r/(5*r+p)
    return f11

def eval_f11(preds, dtrain):
    label = dtrain.get_label()
    a = pd.DataFrame()
    a['pred'] = preds
    a['label'] = label
    a = a.sort_values(by=['pred'],ascending=False)
    p = sum(np.ravel(a['label'])[:800])/800.0
    r = sum(np.ravel(a['label'])[:800])/800.0
    f11 = 6*p*r/(5*r+p)
    return 'f11',f11


params={
    'booster':'gbtree',
    #'objective':'binary:logistic',
    'objective': 'rank:pairwise',
    'eval_metric':['auc'],
    #'gamma':0,
    #'alpha':0,
    'max_depth':6,
    #'lambda':1.0,
    'subsample':1.0,
    'colsample_bytree':1.0,
    #'max_delta_step':10,
    'min_child_weight':1.0,
    'eta': 0.01,#0.03
    'scale_pos_weight':13627/745.0,
    'nthread':6,
    'seed':2016,
    }

model = xgb.train(
                params,
                dtrain,
                num_boost_round=800,
                #early_stopping_rounds=500,
                #maximize=True,
                #evals=[(dtrain,'train'),(dval,'eval')],
                #feval=eval_f11
                evals=[(dtrain,'train')]
                )

pred = model.predict(dtest,ntree_limit=model.best_ntree_limit)

out = pd.DataFrame()
out['user_id'] = test_user['user_id']
out['sku_id'] = test_user['sku_id']
out['pred'] = pred
out_grp = out.loc[:,['user_id','pred']].groupby(by=['user_id'],as_index=False).max()

out_grp = pd.merge(out_grp, out, how='left',on=['user_id','pred']).loc[:,['user_id','sku_id']]

user800 = pd.read_csv('./out_cate8_800.csv')
user800 = user800.loc[:,['user_id']]
out_grp800 = pd.merge(user800, out_grp, how='left',on=['user_id'])
out_grp800.to_csv('./cate8_f2_800.csv',index=False,encoding='utf-8')

user_list = pd.read_csv('./out_cate8_1000.csv')['user_id']
user850 = pd.DataFrame()
user850['user_id'] = user_list
out_grp850 = pd.merge(user850, out_grp, how='left',on=['user_id'])
out_grp850.to_csv('./cate8_f2_1000.csv',index=False,encoding='utf-8')

#out_cate8sku_800 = pd.read_csv('./out_cate8sku_800.csv')
#out_cate8sku_650 = out_cate8sku_800.loc[:650,:]
#out_cate8sku_650.to_csv('./out_cate8sku_650.csv',index=False,encoding='utf-8')


#cate8sku_650 = out_cate8sku_800.loc[:,['user_id']]
#cate8_800_inn_cate8sku_650 = pd.merge(user800, cate8sku_650, how='inner',on=['user_id'])
#cate8_800_inn_cate8sku_650['sku_id'] = 10
#cate8_800_inn_cate8sku_650.to_csv('./cate8_inn_cate8sku.csv',index=False,encoding='utf-8')



#out_grp.to_csv('./raw_859_out.csv',index=False,encoding='utf-8')
#user800 = pd.read_csv('./new_data/out_gai_800.csv')
#user800 = user800.loc[:,['user_id']]
#out_grp2 = pd.merge(user800, out_grp, how='inner',on=['user_id'])

#same_list = test.loc[:,['user_id','sku_id','jiaohu_gaisku_cishu']]
#
#out_grp2 = pd.merge(out_grp, same_list, how='left', on=['user_id','sku_id'])
#out_grp3 = out_grp2.loc[:,['user_id','jiaohu_gaisku_cishu']].groupby(by=['user_id'],as_index=False).max()
#out_grp3.columns = ['user_id','max_cishu']
#out_grp2 = pd.merge(out_grp2, out_grp3, how='left', on=['user_id'])
#
#out_grp2['cishu_cha'] = out_grp2['max_cishu'] - out_grp2['jiaohu_gaisku_cishu']
#
#out_grp2 = out_grp2[out_grp2['cishu_cha'] <= 1]
#
#out_grp2 = out_grp2.loc[:,['user_id','sku_id']]
#
##out_grp3 = out_grp2.groupby(by=['user_id'],as_index=False).count()
##out_grp3[out_grp3['sku_id']>1].shape
#
#buy_rate = pd.read_csv('./feature_data/test_product_buy_rate.csv')
#out_grp3 = pd.merge(out_grp2, buy_rate.loc[:,['sku_id','sku_buy_rate']], how='left',on=['sku_id'])
#out_grp4 = out_grp3.loc[:,['user_id','sku_buy_rate']].groupby(by=['user_id'],as_index=False).max()
#out_grp4.columns = ['user_id','sku_buy_rate']
#out_grp3 = pd.merge(out_grp4, out_grp3, how='left', on=['user_id','sku_buy_rate'])
#
##user800 = pd.read_csv('./new_data/out_gai_800.csv')
##user800 = user800.loc[:,['user_id']]
##out_grp4 = pd.merge(user800, out_grp3, how='left',on=['user_id'])
#
#same_list = test.loc[:,['user_id','sku_id','last_days_gaisku']]
#
#out_grp4 = pd.merge(out_grp3.loc[:,['user_id','sku_id']], same_list, how='left', on=['user_id','sku_id'])
#out_grp5 = out_grp4.loc[:,['user_id','last_days_gaisku']].groupby(by=['user_id'],as_index=False).min()
#out_grp5.columns = ['user_id','min_lastday']
#out_grp4 = pd.merge(out_grp4, out_grp5, how='left', on=['user_id'])
#
#out_grp4['cishu_cha'] = out_grp4['last_days_gaisku'] - out_grp4['min_lastday']
#out_grp4 = out_grp4[out_grp4['cishu_cha'] == 0]
#out_grp4 = out_grp4.loc[:,['user_id','sku_id']]
#
#
#
#same_list = test.loc[:,['user_id','sku_id','jiaohu_gaisku_caozuo']]
#
#out_grp5 = pd.merge(out_grp4, same_list, how='left', on=['user_id','sku_id'])
#out_grp6 = out_grp5.loc[:,['user_id','jiaohu_gaisku_caozuo']].groupby(by=['user_id'],as_index=False).max()
#out_grp6.columns = ['user_id','max_caozuo']
#out_grp5 = pd.merge(out_grp5, out_grp6, how='left', on=['user_id'])
#
#out_grp5['caozuo_cha'] = out_grp5['max_caozuo'] - out_grp5['jiaohu_gaisku_caozuo']
#out_grp5 = out_grp5[out_grp5['caozuo_cha'] == 0]
#out_grp5 = out_grp5.loc[:,['user_id','sku_id']]


