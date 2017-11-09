#coding=utf-8

#融合deep forest和xgboost结果

import pandas as pd


xgb_user = pd.read_csv('../preds/user_preds_xgb.csv')
xgb_user.label = xgb_user.label.rank()
xgb_user_sku = pd.read_csv('../preds/user_sku_preds_xgb.csv')
xgb_user_sku.label = xgb_user_sku.label.rank()

gcf_user = pd.read_csv('../preds/user_preds_gcf.csv')
gcf_user.label = gcf_user.label.rank()
gcf_user.rename(columns={'label':'gcf_label'},inplace=True)

gcf_user_sku = pd.read_csv('../preds/user_sku_preds_gcf.csv')
gcf_user_sku = pd.merge(gcf_user_sku,xgb_user_sku[['user_id','sku_id']],on=['user_id','sku_id'])
gcf_user_sku.label = gcf_user_sku.label.rank()
gcf_user_sku.rename(columns={'label':'gcf_label'},inplace=True)



print xgb_user.shape,xgb_user_sku.shape,gcf_user.shape,gcf_user_sku.shape


xgb_gcf_user = pd.merge(xgb_user,gcf_user,on=['user_id'],how='left')
xgb_gcf_user.label = 0.75*xgb_gcf_user.label + 0.25*xgb_gcf_user.gcf_label

xgb_gcf_user_sku = pd.merge(xgb_user_sku,gcf_user_sku,on=['user_id','sku_id'],how='left')
xgb_gcf_user_sku.label = 0.75*xgb_gcf_user_sku.label + 0.25*xgb_gcf_user_sku.gcf_label


#
xgb_gcf_user[['user_id','label']].to_csv('user_preds.csv',index=None)
xgb_gcf_user_sku[['user_id','sku_id','label']].to_csv('user_sku_preds.csv',index=None)


# Top2000user
top2000user = xgb_gcf_user.sort_values(by='label',ascending=False).iloc[0:2000][['user_id']]
top2000user = pd.merge(top2000user,pd.read_csv('../preds/user_preds_xgb.csv'),on='user_id',how='left')
top2000user.to_csv('Top2000user.csv',index=None)
