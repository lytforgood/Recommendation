# -*- coding: utf-8 -*-
"""
Created on Sat Apr 08 22:27:13 2017

@author: mashiro
"""



import numpy as np
import pandas as pd
import xgboost as xgb

train = pd.read_csv('./feature_data/cate8_train.csv')
train_y = train['label']
train_user = train['user_id']
train_x = train.drop(['user_id','label'],axis=1)

test = pd.read_csv('./feature_data/cate8_test.csv')
test_user = test['user_id']
test_x = test.drop(['user_id'],axis=1)

dtrain = xgb.DMatrix(train_x, label=train_y)
dtest = xgb.DMatrix(test_x)


def get_f11(pred, label):
    a = pd.DataFrame()
    a['pred'] = pred
    a['label'] = label
    a = a.sort_values(by=['pred'],ascending=False)
    p = sum(np.ravel(a['label'])[:800])/800.0
    r = sum(np.ravel(a['label'])[:800])/(800*1.5)
    f11 = 6*p*r/(5*r+p)
    return f11

def eval_f11(preds, dtrain):
    label = dtrain.get_label()
    a = pd.DataFrame()
    a['pred'] = preds
    a['label'] = label
    a = a.sort_values(by=['pred'],ascending=False)
    p = sum(np.ravel(a['label'])[:800])/800.0
    r = sum(np.ravel(a['label'])[:800])/(800*1.5)
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
    'colsample_bytree':0.8,
    #'max_delta_step':10,
    'min_child_weight':0.5,
    'eta': 0.03,#0.03
    'scale_pos_weight':103114/1107.0,
    'nthread':6,
    'seed':2016,
    }

model = xgb.train(
                params,
                dtrain,
                num_boost_round=275,
                #early_stopping_rounds=500,
                #maximize=True,
                #evals=[(dtrain,'train'),(dval,'eval')],
                #feval=eval_f11
                evals=[(dtrain,'train')]
                )

pred = model.predict(dtest,ntree_limit=model.best_ntree_limit)
out = pd.DataFrame()
out['user_id'] = test_user
out['pred'] = pred
out = out.sort_values(by=['pred'],ascending=False)
out.to_csv('./cate8_alluser.csv',index=False,encoding='utf-8')
out.to_csv('../part02/cate8_alluser.csv',index=False,encoding='utf-8')
out_user = np.ravel(out['user_id'])

out = pd.DataFrame()
out['user_id'] = out_user[:800]
out['sku_id'] = 10
out = pd.DataFrame(out,columns=['user_id','sku_id'])
out =out.astype('int')
out.to_csv('./out_cate8_800.csv',index=False,encoding='utf-8')

out = pd.DataFrame()
out['user_id'] = out_user[:1000]
out['sku_id'] = 10
out = pd.DataFrame(out,columns=['user_id','sku_id'])
out =out.astype('int')
out.to_csv('./out_cate8_1000.csv',index=False,encoding='utf-8')


