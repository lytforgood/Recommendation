import pandas as pd
from sklearn.metrics import roc_auc_score
from sklearn.ensemble import ExtraTreesClassifier, RandomForestClassifier
from deep_forest import MGCForest


# 选取top200特征，特征重要性文件是之前训练xgb生成的
fs = pd.read_csv('./preds/user_feature_score.csv')
fs = list(fs.feature)[0:200] + ['user_id', 'cate', 'label']

trainset1 = pd.read_csv('./data/user_trainset1.csv')[fs].fillna(-999)
trainset2 = pd.read_csv('./data/user_trainset2.csv')[fs].fillna(-999)
testset = pd.read_csv('./data/user_testset.csv')[fs].fillna(-999)

trainset1_y = trainset1.label.values
trainset1_x = trainset1.drop(['user_id', 'cate', 'label'],axis=1).values
trainset2_y = trainset2.label.values
trainset2_x = trainset2.drop(['user_id', 'cate', 'label'],axis=1).values

testset_preds = testset[['user_id']]
testset_x = testset.drop(['user_id', 'cate', 'label'],axis=1).values

# training phase
mgc_forest = MGCForest(
    estimators_config={
        'mgs': [{
            'estimator_class': ExtraTreesClassifier,
            'estimator_params': {
                'n_estimators': 200,
                'max_depth': 6,
                'min_samples_split': 10,
                'max_features': 0.7,
                'random_state': 1024,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }, {
            'estimator_class': RandomForestClassifier,
            'estimator_params': {
                'n_estimators': 200,
                'max_depth': 6,
                'min_samples_split': 5,
                'max_features': 0.7,
                'random_state': 4086,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }],
        'cascade': [{
            'estimator_class': ExtraTreesClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 8,
                'min_samples_split': 10,
                'max_features': 0.7,
                'random_state': 8,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }, {
            'estimator_class': ExtraTreesClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 7,
                'min_samples_split': 5,
                'max_features': 0.7,
                'random_state': 16,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }, {
            'estimator_class': RandomForestClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 8,
                'min_samples_split': 10,
                'max_features': 0.7,
                'random_state': 32,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }, {
            'estimator_class': RandomForestClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 7,
                'min_samples_split': 5,
                'max_features': 0.7,
                'random_state': 64,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }]
    },
    stride_ratios=[0.75,0.5,0.25],
    metric=roc_auc_score
)

mgc_forest.fit(trainset1_x, trainset1_y)


# predict test set
testset_preds['label'] = mgc_forest.predict(testset_x)
testset_preds.sort_values(by=['user_id', 'label'], inplace=True)
testset_preds.to_csv("preds/user_preds_gcf.csv", index=None)

