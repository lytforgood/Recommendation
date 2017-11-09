# -*- coding: utf-8 -*-
"""
Created on Fri Mar 24 23:53:20 2017

@author: mashiro
"""


import pandas as pd
import numpy as np

comment = pd.read_csv('./new_data/JData_Comment.csv',encoding='gbk')
product = pd.read_csv('./new_data/JData_Product.csv',encoding='gbk')
user = pd.read_csv('./new_data/JData_user.csv',encoding='gbk')

comment.to_csv('./new_data/comment.csv',index=None,encoding='utf-8')

product = pd.DataFrame(product, columns=['sku_id','a1','a2','a3','cate','brand'])
product.columns = ['sku_id','attr1','attr2','attr3','cate','brand']
product.to_csv('./new_data/product.csv',index=None,encoding='utf-8')

user = user[user['age'].isnull()==False]
age = {u'-1':0, u'15\u5c81\u4ee5\u4e0b':1, u'16-25\u5c81':2, u'26-35\u5c81':3, u'36-45\u5c81':4, u'46-55\u5c81':5, u'56\u5c81\u4ee5\u4e0a':6}
user['age'] = user['age'].apply(lambda x: age[x])
user = pd.DataFrame(user, columns=['user_id','age','sex','user_lv_cd','user_reg_tm'])
user.columns=['user_id','age','sex','user_lv_cd','user_reg_dt']
user.to_csv('./new_data/user.csv',index=False, encoding='utf-8')