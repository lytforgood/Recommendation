#coding=utf-8

import pandas as pd
import xgboost as xgb

# 选取top200特征，特征重要性文件是之前训练xgb生成的
fs = pd.read_csv('./preds/user_feature_score.csv')
fs = list(fs.feature)[0:200] + ['user_id','cate','label']

trainset1 = pd.read_csv('./data/user_trainset1.csv')[fs]
trainset2 = pd.read_csv('./data/user_trainset2.csv')[fs]
testset = pd.read_csv('./data/user_testset.csv')[fs]


trainset1_y = trainset1.label
trainset1_x = trainset1.drop(['user_id','cate','label'],axis=1)
trainset2_y = trainset2.label
trainset2_x = trainset2.drop(['user_id','cate','label'],axis=1)

testset_preds = testset[['user_id']]
testset_x = testset.drop(['user_id','cate','label'],axis=1)

print trainset1_x.shape,trainset2_x.shape,testset_x.shape
print trainset1.label.sum(),trainset2.label.sum()

trainset1 = xgb.DMatrix(trainset1_x,label=trainset1_y)
trainset2 = xgb.DMatrix(trainset2_x,label=trainset2_y)
testset = xgb.DMatrix(testset_x)

params={'booster':'gbtree',
	    'objective': 'binary:logistic',
	    'eval_metric':'auc',
	    'gamma':0.05,
	    'min_child_weight':0.7,
	    'max_depth':5,
	    'lambda':5,
	    'subsample':0.7,
	    'colsample_bytree':0.7,
	    'colsample_bylevel':0.7,
	    'eta': 0.005,
	    'tree_method':'exact',
	    'seed':0,
	    'nthread':12
	    }

#train on trainset1, evaluate on trainset2
watchlist = [(trainset1,'train'),(trainset2,'val')]
model = xgb.train(params,trainset1,num_boost_round=6000,evals=watchlist,early_stopping_rounds=200)
    

#predict test set
testset_preds['label'] = model.predict(testset)
testset_preds.sort_values(by=['user_id','label'],inplace=True)
testset_preds.to_csv("./preds/user_preds_xgb.csv",index=None)
print testset_preds.describe()

