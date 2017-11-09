#coding=utf-8

import pandas as pd
import xgboost as xgb

# 做特征选择，去除一些冗余特征
# user_sku_feature_score.csv是之前训练xgb得到的特征重要性文件
fs = pd.read_csv('./preds/user_sku_feature_score.csv')
fs = list(fs.feature)[0:350] + ['user_id','sku_id','cate','brand','label']

drops = ['l1_usb_b','l1_usac_ac','l1_usdc_dc','l1_usi_i','l1_usc_c','l3_usb_b','l3_usac_ac','l3_usdc_dc','l3_usi_i','l3_usc_c',\
         'l7_usb_b','l7_usac_ac','l7_usdc_dc','l7_usi_i','l7_usc_c','l30_usb_b','l30_usac_ac','l30_usdc_dc','l30_usi_i','l30_usc_c',\
         'l1_usb_ucb','l1_usac_ucac','l1_usdc_ucdc','l1_usi_uci','l1_usc_ucc','l3_usb_ucb','l3_usac_ucac','l3_usdc_ucdc','l3_usi_uci','l3_usc_ucc',\
         'l7_usb_ucb','l7_usac_ucac','l7_usdc_ucdc','l7_usi_uci','l7_usc_ucc','l14_usb_ucb','l14_usac_ucac','l14_usdc_ucdc','l14_usi_uci','l14_usc_ucc',\
         'l30_usb_ucb','l30_usac_ucac','l30_usdc_ucdc','l30_usi_uci','l30_usc_ucc']
         
for d in drops:
    if d in fs:
        fs.remove(d)

trainset1 = pd.read_csv('data/trainset1.csv')[fs]
trainset2 = pd.read_csv('data/trainset2.csv')[fs]
testset = pd.read_csv('data/testset.csv')[fs]

trainset1_y = trainset1.label
trainset1_x = trainset1.drop(['user_id','sku_id','cate','brand','label'],axis=1)
trainset2_y = trainset2.label
trainset2_x = trainset2.drop(['user_id','sku_id','cate','brand','label'],axis=1)

testset_preds = testset[['user_id','sku_id']]
testset_x = testset.drop(['user_id','sku_id','cate','brand','label'],axis=1)

print trainset1_x.shape,trainset2_x.shape,testset_x.shape
print trainset1.label.sum(),trainset2.label.sum()

trainset1 = xgb.DMatrix(trainset1_x,label=trainset1_y)
trainset2 = xgb.DMatrix(trainset2_x,label=trainset2_y)
testset = xgb.DMatrix(testset_x)

params={'booster':'gbtree',
	    'objective': 'binary:logistic',
	    'eval_metric':'auc',
	    'gamma':0.1,
	    'min_child_weight':1.0,
	    'max_depth':6,
	    'lambda':10,
	    'subsample':0.7,
	    'colsample_bytree':0.7,
	    'colsample_bylevel':0.7,
	    'eta': 0.01,
	    'tree_method':'exact',
	    'seed':0,
	    'nthread':12
	    }

#train on trainset1, evaluate on trainset2
watchlist = [(trainset1,'train'),(trainset2,'val')]
model = xgb.train(params,trainset1,num_boost_round=3000,evals=watchlist,early_stopping_rounds=50)

#predict test set
testset_preds['label'] = model.predict(testset)
testset_preds.sort_values(by=['user_id','label'],inplace=True)
testset_preds.to_csv("preds/user_sku_preds_xgb.csv",index=None)
print testset_preds.describe()

