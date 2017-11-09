#coding=utf-8

import pandas as pd

#按照前1天，2天，3天，4天及4天以前，用户出现的比例选取top user
#分别取760,318,174,249个

pred1 = pd.read_csv('user_preds.csv')
pred1 = pred1.sort_values(by='label',ascending=False)
pred1 = pred1[['user_id','label']]

Get_Label = [76,80]
data = pd.read_csv('../data/t.csv')

pre1 = data[(data.time==Get_Label[0]-1)&(data.cate==8)][['user_id']].drop_duplicates()
pre1 = pd.merge(pre1,pred1,on='user_id')
pre1 = pre1.sort_values(by='label',ascending=False)[['user_id']]

pre2 = data[(data.time==Get_Label[0]-2)&(data.cate==8)][['user_id']].drop_duplicates()
pre2 = pd.merge(pre2,pred1,on='user_id')
pre1['flag'] = 1
pre2 = pd.merge(pre2,pre1,on='user_id',how='left')
pre2 = pre2[pre2.flag!=1]
pre2 = pre2.sort_values(by='label',ascending=False)[['user_id']]


pre3 = data[(data.time==Get_Label[0]-3)&(data.cate==8)][['user_id']].drop_duplicates()
pre3 = pd.merge(pre3,pred1,on='user_id')
pre1['flag'] = 1
pre3 = pd.merge(pre3,pre1,on='user_id',how='left')
pre3 = pre3[pre3.flag!=1][['user_id','label']]
pre2['flag'] = 1
pre3 = pd.merge(pre3,pre2,on='user_id',how='left')
pre3 = pre3[pre3.flag!=1][['user_id','label']]
pre3 = pre3.sort_values(by='label',ascending=False)[['user_id']]

pre1['flag'] = 1
pre4 = pd.merge(pred1,pre1,on='user_id',how='left')
pre4 = pre4[pre4.flag!=1][['user_id','label']]
pre2['flag'] = 1
pre4 = pd.merge(pre4,pre2,on='user_id',how='left')
pre4 = pre4[pre4.flag!=1][['user_id','label']]
pre3['flag'] = 1
pre4 = pd.merge(pre4,pre3,on='user_id',how='left')
pre4 = pre4[pre4.flag!=1][['user_id','label']]
pre4 = pre4.sort_values(by='label',ascending=False)[['user_id']]


pre1 = pre1.iloc[0:760]
pre2 = pre2.iloc[0:318]
pre3 = pre3.iloc[0:174]
pre4 = pre4.iloc[0:149]

pred1 = pd.concat([pre1,pre2])
pred1 = pd.concat([pred1,pre3])
pred1 = pd.concat([pred1,pre4])
pred1.drop_duplicates()

print pred1.shape,pre1.shape,pre2.shape,pre3.shape,pre4.shape


pred2 = pd.read_csv('user_sku_preds.csv')
pred2 = pred2.sort_values(by='label',ascending=False)
pred2 = pred2.iloc[0:2500]

pred = pd.merge(pred2,pred1,on='user_id')
print pred.shape

pred['ranks'] = pred.groupby('user_id')['label'].rank(ascending=False)
pred = pred[pred.ranks==1]

pred.user_id = pred.user_id.astype(int)
pred.sku_id = pred.sku_id.astype(int)
print pred.iloc[0:750]
pred = pred.iloc[0:750][['user_id','sku_id']]

xgb_user_sku = pd.read_csv('../preds/user_sku_preds_xgb.csv')
pred = pd.merge(pred,xgb_user_sku,on=['user_id','sku_id'],how='left')

pred.to_csv('wepon174.csv',index=None)
