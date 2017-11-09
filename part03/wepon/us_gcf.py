import pandas as pd
from sklearn.metrics import roc_auc_score
from sklearn.ensemble import ExtraTreesClassifier, RandomForestClassifier
from deep_forest import MGCForest

# 做特征选择，去除一些冗余特征
# user_sku_feature_score.csv是之前训练xgb得到的特征重要性文件
fs = pd.read_csv('./preds/user_sku_feature_score.csv')
fs = list(fs.feature)[0:400] + ['user_id','sku_id','cate','brand','label']

drops = ['l1_usb_b','l1_usac_ac','l1_usdc_dc','l1_usi_i','l1_usc_c','l3_usb_b','l3_usac_ac','l3_usdc_dc','l3_usi_i','l3_usc_c',\
         'l7_usb_b','l7_usac_ac','l7_usdc_dc','l7_usi_i','l7_usc_c','l30_usb_b','l30_usac_ac','l30_usdc_dc','l30_usi_i','l30_usc_c',\
         'l1_usb_ucb','l1_usac_ucac','l1_usdc_ucdc','l1_usi_uci','l1_usc_ucc','l3_usb_ucb','l3_usac_ucac','l3_usdc_ucdc','l3_usi_uci','l3_usc_ucc',\
         'l7_usb_ucb','l7_usac_ucac','l7_usdc_ucdc','l7_usi_uci','l7_usc_ucc','l14_usb_ucb','l14_usac_ucac','l14_usdc_ucdc','l14_usi_uci','l14_usc_ucc',\
         'l30_usb_ucb','l30_usac_ucac','l30_usdc_ucdc','l30_usi_uci','l30_usc_ucc']
         
for d in drops:
    if d in fs:
        fs.remove(d)

trainset1 = pd.read_csv('./data/trainset1.csv')[fs].fillna(-999)
trainset1_pos = trainset1[trainset1.label==1]
trainset1_neg = trainset1[trainset1.label==0].sample(50000)
trainset1 = pd.concat([trainset1_pos,trainset1_neg])
trainset1 = trainset1.sample(trainset1.shape[0])

testset = pd.read_csv('./data/testset.csv')[fs].fillna(-999)

trainset1_y = trainset1.label.values
trainset1_x = trainset1.drop(['user_id','sku_id','cate','brand','label'],axis=1).values

testset_preds = testset[['user_id','sku_id']]
testset_x = testset.drop(['user_id','sku_id','cate','brand','label'],axis=1).values



# training phase
mgc_forest = MGCForest(
    estimators_config={
        'mgs': [{
            'estimator_class': ExtraTreesClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 6,
                'min_samples_split': 10,
                'max_features': 0.7,
                'random_state': 2,
                'class_weight': 'balanced',
                'n_jobs': -1
            }
        }, {
            'estimator_class': RandomForestClassifier,
            'estimator_params': {
                'n_estimators': 150,
                'max_depth': 6,
                'min_samples_split': 10,
                'max_features': 0.7,
                'random_state': 4,
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
    stride_ratios=[0.75,0.45],
    metric=roc_auc_score
)

mgc_forest.fit(trainset1_x, trainset1_y)


# predict test set
testset_preds['label'] = mgc_forest.predict(testset_x)
testset_preds.to_csv("preds/user_sku_preds_gcf.csv", index=None)

