# -*- coding: utf-8 -*-
"""
Created on Sun Mar 26 19:25:24 2017

@author: mashiro
"""

import csv
user_id = set()
for c,row in enumerate(csv.DictReader(open('./new_data/user.csv'))):
    user_id.add(int(row['user_id']))
user_id = sorted(list(user_id))

user_n = len(user_id)
n_e = int(user_n/20)
user = {}
for i in range(20):
    if i == 19:
        user[i] = set(user_id[i*n_e:])
    else:
        user[i] = set(user_id[i*n_e:(i+1)*n_e])
        
open_file = []
for i in range(20):
    new_file = open('./chunk_data/user_chunk'+str(i)+'.csv','w')
    new_file.write('user_id,age,sex,user_lv_cd,user_reg_dt\n')
    open_file.append(new_file)

for c,row in enumerate(csv.DictReader(open('./new_data/user.csv'))):
    for i in range(20):
        if int(row['user_id']) in user[i]:
            out = [row['user_id'], row['age'], row['sex'], row['user_lv_cd'], row['user_reg_dt']]
            open_file[i].write('%s\n'%(','.join(out)))
            break

for i in range(20):
    open_file[i].close()


open_file = []
for i in range(20):
    new_file = open('./chunk_data/action_chunk'+str(i)+'.csv','w')
    new_file.write('user_id,sku_id,time,model_id,type,cate,brand\n')
    open_file.append(new_file)

#for data in ['JData_Action_201602','JData_Action_201603','JData_Action_201603_extra','JData_Action_201604']:
for data in ['JData_Action_201602','JData_Action_201603','JData_Action_201604']:
    for c,row in enumerate(csv.DictReader(open('./new_data/'+data+'.csv'))):
        for i in range(20):
            if int(float(row['user_id'])) in user[i]:
                out = [str(int(float(row['user_id']))), row['sku_id'], row['time'], row['model_id'], row['type'], row['cate'], row['brand']]
                open_file[i].write('%s\n'%(','.join(out)))
                break
    
        if c%1000000 == 0:
            print(data, c)
    print(data + ' all action', c)

for i in range(20):
    open_file[i].close()
