#coding=utf-8

"""
user基本信息特征
"""


import pandas as pd
from datetime import date

user = pd.read_csv('data/JData_User.csv')

user.age.fillna('-1',inplace=True)
user_age_dummies = pd.get_dummies(user.age)
user_age_dummies.columns = ['age'+str(i) for i in range(user_age_dummies.shape[1])]
user = pd.concat([user,user_age_dummies],axis=1)

user.sex.fillna(2,inplace=True)
user_sex_dummies = pd.get_dummies(user.sex)
user_sex_dummies.columns = ['sex'+str(i) for i in range(user_sex_dummies.shape[1])]
user = pd.concat([user,user_sex_dummies],axis=1)

user_lv_cd_dummies = pd.get_dummies(user.user_lv_cd)
user_lv_cd_dummies.columns = ['user_lv_cd'+str(i+1) for i in range(user_lv_cd_dummies.shape[1])]
user = pd.concat([user,user_lv_cd_dummies],axis=1)

def get_reg_days(x):
    try:
        y,m,d = x.split('-')
        return (date(2016,4,20) - date(int(y),int(m),int(d))).days
    except:
        return -1

user.user_reg_tm = user.user_reg_tm.apply(get_reg_days)

user.drop(['age','sex','user_lv_cd'],axis=1).to_csv('data/user_feature.csv',index=None)

