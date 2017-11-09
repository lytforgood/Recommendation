# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
from xgboost.sklearn import XGBClassifier
from sklearn import metrics
import xgboost as xgb

path="/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/"


train = pd.read_csv(path+"user_train.csv")
val = pd.read_csv(path+"user_val.csv")

test= pd.read_csv(path+"user_test.csv")
train_all=pd.concat([train,val])
X_train_all,y_train_all=train_all.iloc[:,1:(train_all.shape[1]-1)],train_all.iloc[:,-1]
X_test=test.iloc[:,1:(test.shape[1])]

clf = XGBClassifier(
 learning_rate =0.03,
 n_estimators=500,
 max_depth=3,
 min_child_weight=1,
 gamma=0.3,
 subsample=0.6,
 colsample_bytree=0.6,
 objective= 'binary:logistic',
 nthread=6,
 scale_pos_weight=1,
 reg_lambda=1,
seed=1)

clf.fit(X_train_all, y_train_all,eval_metric='auc')
y_pro= clf.predict_proba(X_test)[:,1]
pre=pd.concat([test[['user_id']],pd.DataFrame({'pro':y_pro})],axis=1)
pre=pre.sort(["pro"],ascending=False)
re=pre.iloc[0:1500,]
# re=re[['user_id','sku_id']]

# re.to_csv("user_top1500.csv",header=False,index=False)
pre.to_csv("user_topallx.csv",header=False,index=False)



train = pd.read_csv(path+"train.csv")
val = pd.read_csv(path+"val.csv")
test= pd.read_csv(path+"test.csv")
train_all=pd.concat([train,val])
X_train_all,y_train_all=train_all.iloc[:,2:(train_all.shape[1]-1)],train_all.iloc[:,-1]
X_test=test.iloc[:,2:(test.shape[1])]

clf = XGBClassifier(
 learning_rate =0.03,
 n_estimators=500,
 max_depth=3,
 min_child_weight=1,
 gamma=0.3,
 subsample=0.6,
 colsample_bytree=0.6,
 objective= 'binary:logistic',
 nthread=6,
 scale_pos_weight=1,
 reg_lambda=1,
seed=1)

clf.fit(X_train_all, y_train_all,eval_metric='auc')
y_pro= clf.predict_proba(X_test)[:,1]
pre=pd.concat([test[['user_id','sku_id']],pd.DataFrame({'pro':y_pro})],axis=1)
pre=pre.sort(["pro"],ascending=False)
re=pre.iloc[0:2500,]
# re=re[['user_id','sku_id']]
# re.to_csv("model_top2500.csv",header=False,index=False)
pre.to_csv("us_test_all.csv",header=False,index=False)


