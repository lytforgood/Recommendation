#coding=utf-8

import pandas as pd

# 用到的几份文件的路径
cate8_alluser = 'cate8_alluser.csv'
wepon_user = '../wepon/ensemble/user_preds.csv'
wepon_user_sku = '../wepon/ensemble/user_sku_preds.csv'
cate8_800 = 'cate8_800.csv'



siyue = pd.read_csv(cate8_alluser)
siyue = siyue.sort_values(by=['pred'],ascending=False)
siyue = siyue.iloc[:3000]
siyue.pred = siyue.pred.rank()

wepon = pd.read_csv(wepon_user)
wepon = wepon.sort_values(by=['label'],ascending=False)
wepon = wepon.iloc[:3000]
wepon.label = wepon.label.rank()

merge = pd.merge(siyue,wepon,on=['user_id'])
merge['rk'] = 0.6*merge.pred + 0.4*merge.label
merge = merge.sort_values(by=['rk'],ascending=False)

user = merge.iloc[:850][['user_id']]

#对于取出来的top800用户，有在d1742的就取d1742，其他的取d1727的
d1742 = pd.read_csv(wepon_user_sku)
d1742.user_id = d1742.user_id.astype(int)
d1742['rk'] = d1742.groupby('user_id')['label'].rank(ascending=False)
d1742 = d1742[d1742.rk==1]
d1742 = d1742.sort_values(by='label',ascending=False)[['user_id','sku_id']].iloc[0:6500]

pred1 = pd.merge(d1742,user,on=['user_id'])

user_rest = pd.merge(user,pred1,on=['user_id'],how='left')
user_rest.fillna(-1,inplace=True)
user_rest = user_rest[user_rest.sku_id==-1][['user_id']]

d1727 = pd.read_csv(cate8_800)

pred2 = pd.merge(d1727,user_rest,on=['user_id'])

pred = pd.concat([pred1,pred2])
pred[['user_id']].to_csv('832user_0.2965.csv',index=None)

print pred.shape
print len(list(pred.user_id.unique()))
