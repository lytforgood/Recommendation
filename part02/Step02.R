##测试集合
# 测试集   2.14-4.01   4.06-4.10
# 验证集   2.21-4.8    4.11-4.15
# 预测集   3.1-4.15    4.16-4.20
options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/")
require(data.table)
library(sqldf)
library(dplyr)
#library(dtplyr)
t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)
# t=filter(t,cate==8)
# user_rank=fread("train/user_train_pro.csv",header = TRUE)
# user_rank=fread("train/user_val_pro.csv",header = TRUE)
# names(user_rank)=c("user_id","urank")

time_end="2016/4/6"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
#用户id--所有策略对
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# user_id=filter(t,time>=start_time,time<time1) %>% select(user_id)
#用户商品对(删除不在p的子集)
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,sku_id)
us=unique(us)
tmp_diff=25
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx2=filter(t,time>=start_time,time<time1,cate==8,type==2 | type==3|  type==5) %>% select(user_id,sku_id)
usx2=unique(usx2)
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx3=filter(t,time>=start_time,time<time1,cate==8,type==4 | type==3) %>% select(user_id,sku_id)
usx3=unique(usx3)
usx2=setdiff(usx2,usx3) ##（在x中不在y中）
us=rbind(us,usx2)
us=unique(us)
#用户
user_id=unique(select(us,user_id))
u_all=tbl_df(as.data.frame(user_id))

rm(usx2,usx3,user_id)

##45天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
u_all=mutate(u_all,ujqg=1*u24+0.1*u25)
rm(u21,u22,u23,u24,u25,u26)

##45天的cate==8的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u21c")
names(u22)=c("user_id","u22c")
names(u23)=c("user_id","u23c")
names(u24)=c("user_id","u24c")
names(u25)=c("user_id","u25c")
names(u26)=c("user_id","u26c")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天cate=8加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujqc=0.005*u21c+0.05*u22c+0.3*u23c+1*u24c+0.1*u25c+0.003*u26c)
u_all=mutate(u_all,ujqcg=1*u24c+0.1*u25c)
rm(u21,u22,u23,u24,u25,u26)

##n天的浏览1、加入购物车2、关注5、下单4、删除3所有
jqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n()/tmp_diff)
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n()/tmp_diff)
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n()/tmp_diff)
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n()/tmp_diff)
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n()/tmp_diff)
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n()/tmp_diff)
tmp=select(u_all,user_id)
tmp=left_join(tmp, u21, by="user_id")
tmp=left_join(tmp, u22, by="user_id")
tmp=left_join(tmp, u23, by="user_id")
tmp=left_join(tmp, u24, by="user_id")
tmp=left_join(tmp, u25, by="user_id")
tmp=left_join(tmp, u26, by="user_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
ndayjq=tmp$ujq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
t1jq=jqday(1)
t2jq=jqday(2)
t3jq=jqday(3)
t4jq=jqday(4)
t5jq=jqday(5)
t6jq=jqday(6)
t7jq=jqday(7)
t15jq=jqday(15)
u_all=mutate(u_all,t1jq=t1jq)
u_all=mutate(u_all,t2jq=t2jq)
u_all=mutate(u_all,t3jq=t3jq)
u_all=mutate(u_all,t4jq=t4jq)
u_all=mutate(u_all,t5jq=t5jq)
u_all=mutate(u_all,t6jq=t6jq)
u_all=mutate(u_all,t7jq=t7jq)
u_all=mutate(u_all,t15jq=t15jq)

rm(t1jq,t2jq,t3jq,t4jq,t5jq,t6jq,t7jq,t15jq)

#最近3/7天是否加入购物车，删除购物车
##3天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u31")
names(u22)=c("user_id","u32")
names(u23)=c("user_id","u33")
names(u24)=c("user_id","u34")
names(u25)=c("user_id","u35")
names(u26)=c("user_id","u36")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u31+0.05*u32+0.3*u33+1*u34+0.1*u35+0.003*u36)
u_all=mutate(u_all,ujq23=0.005*u31+0.05*u32+0.3*u33-1*u34-0.1*u35+0.003*u36)

##7天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u71")
names(u22)=c("user_id","u72")
names(u23)=c("user_id","u73")
names(u24)=c("user_id","u74")
names(u25)=c("user_id","u75")
names(u26)=c("user_id","u76")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u71+0.05*u72+0.3*u73+1*u74+0.1*u75+0.003*u76)
u_all=mutate(u_all,ujq23=0.005*u71+0.05*u72+0.3*u73-1*u74-0.1*u75+0.003*u76)



##前45天转换率
uzh31={}
for(i in 1:length(u_all$u21)){
  if(u_all$u21[i]==0){
        uzh31=c(uzh31,0)
    }else{
        uzh31=c(uzh31,u_all$u24[i]/u_all$u21[i])
    }
}
uzh32={}
for(i in 1:length(u_all$u22)){
  if(u_all$u22[i]==0){
        uzh32=c(uzh32,0)
    }else{
        uzh32=c(uzh32,u_all$u24[i]/u_all$u22[i])
    }
}
uzh33={}
for(i in 1:length(u_all$u23)){
  if(u_all$u23[i]==0){
        uzh33=c(uzh33,0)
    }else{
        uzh33=c(uzh33,u_all$u24[i]/u_all$u23[i])
    }
}
uzh34={}
for(i in 1:length(u_all$u26)){
  if(u_all$u26[i]==0){
        uzh34=c(uzh34,0)
    }else{
        uzh34=c(uzh34,u_all$u24[i]/u_all$u26[i])
    }
}
u_all=cbind(u_all,uzh31)
u_all=cbind(u_all,uzh32)
u_all=cbind(u_all,uzh33)
u_all=cbind(u_all,uzh34)
u_all=tbl_df(u_all)

rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
# len=length(u41$u41)
# all=as.integer(all)/len
# u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
# tmp_diff=45
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
# len=length(u42$u42)
# all=as.integer(all)/len
# u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
# u_all=left_join(u_all, u41, by="user_id")
# u_all=left_join(u_all, u42, by="user_id")
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
rm(u41,u42,all,len,i)

##最近7天的cate==8活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u43=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u43 = n())
len=length(u43$u43)
all=as.integer(all)/len
u43$u43=u43$u43/as.integer(rep(all,length(u43$u43)))
names(u41)=c("user_id","u41c")
names(u42)=c("user_id","u42c")
names(u43)=c("user_id","u43c")
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
u_all=left_join(u_all, u43, by="user_id")

rm(u41,u42,u43,all,len)
#用户属性
u<- read.csv("JData_User.csv",fileEncoding='gbk',header = TRUE)
# names(u)=c("user_id","age","sex","user_lv_cd","user_reg_dt")
age=sort(unique(u$age))
age=data.frame(age,c(1:length(age)))
names(age)=c("age","agelabel")
u=left_join(u, age, by="age")
##注册时间距离购买日的时间间隔
timediff1=rep(time1,length(u$user_id))
u$user_reg_dt=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(u$user_reg_dt,"%Y/%m/%d")),units='day'))
u=select(u,user_id,agelabel,sex,user_lv_cd,user_reg_dt)
u$user_reg_dt[which(u$user_reg_dt>45)]=45

u_all=left_join(u_all, u, by="user_id")

rm(age,u,timediff1)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
u_all=left_join(u_all, maxtime1, by="user_id")
u_all=left_join(u_all, maxtime2, by="user_id")
rm(maxtime1,maxtime2,timediff1)
#最后一次没有购买的标为前50天到现在的日期
u_all$maxtime2[is.na(u_all$maxtime2)]=tmp_diff
u_all[is.na(u_all)] <- 0
##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
u_all=left_join(u_all, mintime1, by="user_id")
#最早一次没有交互的标为前50天到现在的日期
u_all$mintime1[is.na(u_all$mintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
u_all=mutate(u_all,maxmintime=mintime1-maxtime1)

u_all[is.na(u_all)] <- 0
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday45")
names(u22)=c("user_id","xwday845")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday7")
names(u22)=c("user_id","xwday87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday3")
names(u22)=c("user_id","xwday83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
rm(u21,u22)

##最近45天内浏览的商品个数、品牌个数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk1")
names(u22)=c("user_id","b1")
names(u23)=c("user_id","sk2")
names(u24)=c("user_id","b2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近3天内浏览的商品个数、品牌个数
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk3")
names(u22)=c("user_id","b3")
names(u23)=c("user_id","sk83")
names(u24)=c("user_id","b83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近7天内浏览的商品个数、品牌个数
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk7")
names(u22)=c("user_id","b7")
names(u23)=c("user_id","sk87")
names(u24)=c("user_id","b87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##top10商品的点击/浏览/加入购物车
##好商品top100好品牌50 交互的次数
##品牌top20 加权和
tl=fread("用户top20品牌特征.csv",header=TRUE)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
brandtop20=tl$V1+tl$V2+tl$V3+tl$V4+tl$V4+tl$V5+tl$V6+tl$V7+tl$V8+tl$V9+tl$V10+tl$V11+tl$V12+tl$V13+tl$V14+tl$V15+tl$V16+tl$V17+tl$V18+tl$V19+tl$V20
tl=cbind(tl,brandtop20)
tl=tbl_df(tl)
top20=select(tl,user_id,time,brandtop20)
names(top20)=c("user_id","time","brandtop20")

rm(tl)
#过去1/2/3/7/45天 的品牌加权和
top20day<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(top20,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u21 = sum(brandtop20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=top20day(1,tmp_id)
utl2=top20day(2,tmp_id)
utl3=top20day(3,tmp_id)
utl7=top20day(7,tmp_id)
utl15=top20day(15,tmp_id)
utl45=top20day(45,tmp_id)
u_all=mutate(u_all,btop1=utl1)
u_all=mutate(u_all,btop2=utl2)
u_all=mutate(u_all,btop3=utl3)
u_all=mutate(u_all,btop7=utl7)
u_all=mutate(u_all,btop15=utl15)
u_all=mutate(u_all,btop45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


tl=fread("用户top20品牌特征.csv",header=TRUE)
tl=tbl_df(tl)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
top20nday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(utop1 = sum(V1),utop2 = sum(V2),utop3 = sum(V3),utop4 = sum(V4),utop5 = sum(V5),utop6 = sum(V6),utop7 = sum(V7),utop8 = sum(V8),utop9 = sum(V9),utop10 = sum(V10),utop11 = sum(V11),utop12 = sum(V12),utop13 = sum(V13),utop14 = sum(V14),utop15 = sum(V15),utop16 = sum(V16),utop17 = sum(V17),utop18 = sum(V18),utop19 = sum(V19),utop20 = sum(V20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
return(tmp)
}
tmp_id=select(u_all,user_id)
# utl1=top20nday(1,tmp_id)
# utl2=top20nday(2,tmp_id)
# utl3=top20nday(3,tmp_id)
# utl7=top20nday(7,tmp_id)
# utl15=top20nday(15,tmp_id)
utl45=top20nday(45,tmp_id)
u_all=left_join(u_all,utl45,by="user_id")
rm(utl45,tl)
# write.table (u_all, file ="user_val2.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

##计算每个用户每个商品的停留时间秒 大于1个小时记录为10秒 每个用户商品/类别交互时间和
# tl=fread("停留时间特征2.csv",header=FALSE)
# names(tl)=c("user_id","sku_id","time","tltime")
# tl=tbl_df(tl)
# p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
# p=tbl_df(p)
# p=select(p,sku_id,cate,brand)
# tl=left_join(tl,p,by="sku_id")
# tl=filter(tl,cate==8)
# write.table (tl, file ="停留时间特征.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tl=fread("停留时间特征.csv",header=TRUE)
tl=tbl_df(tl)
#过去1/2/3/7/45天每个用户的停留时间
tltimeday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u21 = sum(tltime))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=tltimeday(1,tmp_id)
utl2=tltimeday(2,tmp_id)
utl3=tltimeday(3,tmp_id)
utl7=tltimeday(7,tmp_id)
utl15=tltimeday(15,tmp_id)
utl45=tltimeday(45,tmp_id)
u_all=mutate(u_all,utl1=utl1)
u_all=mutate(u_all,utl2=utl2)
u_all=mutate(u_all,utl3=utl3)
u_all=mutate(u_all,utl7=utl7)
u_all=mutate(u_all,utl15=utl15)
u_all=mutate(u_all,utl45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


# u_all=left_join(u_all,user_rank,by="user_id")
# rm(user_rank)

##商品特征
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
sku_id=unique(p$sku_id)
p_all=tbl_df(as.data.frame(sku_id))
p_all=left_join(p_all, select(p,sku_id,attr1,attr2,attr3,brand), by="sku_id")
rm(p,sku_id)
#45天的浏览1、加入购物车2、关注5、下单4、删除3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(p11 = n())
p12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(p12 = n())
p13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(p13 = n())
p14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(p14 = n())
p15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(p15 = n())
p16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(p16 = n())
p_all=left_join(p_all, p11, by="sku_id")
p_all=left_join(p_all, p12, by="sku_id")
p_all=left_join(p_all, p13, by="sku_id")
p_all=left_join(p_all, p14, by="sku_id")
p_all=left_join(p_all, p15, by="sku_id")
p_all=left_join(p_all, p16, by="sku_id")
##商品热度 加权和
p_all[is.na(p_all)] <- 0
p_all=mutate(p_all,prd=0.005*p11+0.05*p12+0.3*p13+1*p14+0.1*p15+0.003*p16)
p_all=mutate(p_all,prdg=1*p14+0.1*p15)
rm(p11,p12,p13,p14,p15,p16)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
pjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(p_all,sku_id)
tmp=left_join(tmp, jqu21, by="sku_id")
tmp=left_join(tmp, jqu22, by="sku_id")
tmp=left_join(tmp, jqu23, by="sku_id")
tmp=left_join(tmp, jqu24, by="sku_id")
tmp=left_join(tmp, jqu25, by="sku_id")
tmp=left_join(tmp, jqu26, by="sku_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=pjqday(1)
pt2jq=pjqday(2)
pt3jq=pjqday(3)
pt4jq=pjqday(4)
pt5jq=pjqday(5)
pt6jq=pjqday(6)
pt7jq=pjqday(7)
pt15jq=pjqday(15)
p_all=mutate(p_all,pt1jq=pt1jq)
p_all=mutate(p_all,pt2jq=pt2jq)
p_all=mutate(p_all,pt3jq=pt3jq)
p_all=mutate(p_all,pt4jq=pt4jq)
p_all=mutate(p_all,pt5jq=pt5jq)
p_all=mutate(p_all,pt6jq=pt6jq)
p_all=mutate(p_all,pt7jq=pt7jq)
p_all=mutate(p_all,pt15jq=pt15jq)

rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
p_all[is.na(p_all)] <- 0
pzh21={}
for(i in 1:length(p_all$p11)){
  if(p_all$p11[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,p_all$p14[i]/p_all$p11[i])
    }
}
pzh22={}
for(i in 1:length(p_all$p12)){
  if(p_all$p12[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,p_all$p14[i]/p_all$p12[i])
    }
}
pzh23={}
for(i in 1:length(p_all$p13)){
  if(p_all$p13[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,p_all$p14[i]/p_all$p13[i])
    }
}
p_all=cbind(p_all,pzh21)
p_all=cbind(p_all,pzh22)
p_all=cbind(p_all,pzh23)
p_all=tbl_df(p_all)
rm(pzh21,pzh22,pzh23,i)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("sku_id","pmaxtime1")
names(maxtime2)=c("sku_id","pmaxtime2")
p_all=left_join(p_all, maxtime1, by="sku_id")
p_all=left_join(p_all, maxtime2, by="sku_id")
#最后一次没有购买的标为 tmp_diff
p_all$pmaxtime2[is.na(p_all$pmaxtime2)]=tmp_diff
p_all$pmaxtime1[is.na(p_all$pmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("sku_id","pmintime1")
p_all=left_join(p_all, mintime1, by="sku_id")
#最早一次没有交互的标为前50天到现在的日期
p_all$pmintime1[is.na(p_all$pmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
p_all=mutate(p_all,pmaxmintime=pmintime1-pmaxtime1)
p_all[is.na(p_all)] <- 0


##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% distinct(user_id) %>% summarise(p31 = n())
p_all=left_join(p_all, p31, by="sku_id")
p_all[is.na(p_all)] <- 0
##评价
c<- read.csv("JData_Comment.csv",fileEncoding='gbk',header = TRUE)
c=tbl_df(c)
# cp=filter(c,dt == as.Date(d[length(d)-1],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# if(nrow(cp)<2){
#   cp=filter(c,dt == as.Date(d[length(d)-2],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# }
cp=c %>% group_by(sku_id) %>% summarise(comment_num=mean(comment_num),has_bad_comment=mean(has_bad_comment),bad_comment_rate=mean(bad_comment_rate))
p_all=left_join(p_all, cp, by="sku_id")
rm(p31,c,cp)


#品牌特征B
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
brand=unique(p$brand)
brand_all=tbl_df(as.data.frame(brand))
rm(p,brand)
#该品牌过去45天共有多少种商品
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b11=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(sku_id) %>% summarise(b11 = n())
brand_all=left_join(brand_all,b11, by="brand")
##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(user_id) %>% summarise(p31 = n())
names(p31)=c("brand","p31b")
brand_all=left_join(brand_all, p31, by="brand")
brand_all[is.na(brand_all)] <- 0

#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>%  summarise(b21 = n())
b22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>%  summarise(b22 = n())
b23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>%  summarise(b23 = n())
b24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>%  summarise(b24 = n())
b25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>%  summarise(b25 = n())
b26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>%  summarise(b26 = n())
brand_all=left_join(brand_all, b21, by="brand")
brand_all=left_join(brand_all, b22, by="brand")
brand_all=left_join(brand_all, b23, by="brand")
brand_all=left_join(brand_all, b24, by="brand")
brand_all=left_join(brand_all, b25, by="brand")
brand_all=left_join(brand_all, b26, by="brand")
brand_all=mutate(brand_all,brd=0.005*b21+0.05*b22+0.3*b23+1*b24+0.1*b25+0.003*b26)
brand_all[is.na(brand_all)] <- 0

rm(b11,b21,b22,b23,b24,b25,b26)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
bjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(brand_all,brand)
tmp=left_join(tmp, jqu21, by="brand")
tmp=left_join(tmp, jqu22, by="brand")
tmp=left_join(tmp, jqu23, by="brand")
tmp=left_join(tmp, jqu24, by="brand")
tmp=left_join(tmp, jqu25, by="brand")
tmp=left_join(tmp, jqu26, by="brand")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=bjqday(1)
pt2jq=bjqday(2)
pt3jq=bjqday(3)
pt4jq=bjqday(4)
pt5jq=bjqday(5)
pt6jq=bjqday(6)
pt7jq=bjqday(7)
pt15jq=bjqday(15)
brand_all=mutate(brand_all,bt1jq=pt1jq)
brand_all=mutate(brand_all,bt2jq=pt2jq)
brand_all=mutate(brand_all,bt3jq=pt3jq)
brand_all=mutate(brand_all,bt4jq=pt4jq)
brand_all=mutate(brand_all,bt5jq=pt5jq)
brand_all=mutate(brand_all,bt6jq=pt6jq)
brand_all=mutate(brand_all,bt7jq=pt7jq)
brand_all=mutate(brand_all,bt15jq=pt15jq)
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
brand_all[is.na(brand_all)] <- 0
pzh21={}
for(i in 1:length(brand_all$b21)){
  if(brand_all$b21[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,brand_all$b24[i]/brand_all$b21[i])
    }
}
pzh22={}
for(i in 1:length(brand_all$b22)){
  if(brand_all$b22[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,brand_all$b24[i]/brand_all$b22[i])
    }
}
pzh23={}
for(i in 1:length(brand_all$b23)){
  if(brand_all$b23[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,brand_all$b24[i]/brand_all$b23[i])
    }
}
bzh21=pzh21
bzh22=pzh22
bzh23=pzh23
brand_all=cbind(brand_all,bzh21)
brand_all=cbind(brand_all,bzh22)
brand_all=cbind(brand_all,bzh23)
brand_all=tbl_df(brand_all)
brand_all[is.na(brand_all)] <- 0

rm(bzh21,bzh22,bzh23,pzh21,pzh22,pzh23,i)


##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("brand","bmaxtime1")
names(maxtime2)=c("brand","bmaxtime2")
brand_all=left_join(brand_all, maxtime1, by="brand")
brand_all=left_join(brand_all, maxtime2, by="brand")
#最后一次没有购买的标为 tmp_diff
brand_all$bmaxtime2[is.na(brand_all$bmaxtime2)]=tmp_diff
brand_all$bmaxtime1[is.na(brand_all$bmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("brand","bmintime1")
brand_all=left_join(brand_all, mintime1, by="brand")
#最早一次没有交互的标为前50天到现在的日期
brand_all$bmintime1[is.na(brand_all$bmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
brand_all=mutate(brand_all,bmaxmintime=bmintime1-bmaxtime1)
brand_all[is.na(brand_all)] <- 0

##合并特征
p_all=left_join(p_all, brand_all, by="brand")


#用户-商品 交叉特征
#7天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us11 = n())
us12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us12 = n())
us13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us13 = n())
us14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us14 = n())
us15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us15 = n())
us16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us16 = n())
us_all=left_join(us, us11, by=c("user_id","sku_id"))
us_all=left_join(us_all, us12, by=c("user_id","sku_id"))
us_all=left_join(us_all, us13, by=c("user_id","sku_id"))
us_all=left_join(us_all, us14, by=c("user_id","sku_id"))
us_all=left_join(us_all, us15, by=c("user_id","sku_id"))
us_all=left_join(us_all, us16, by=c("user_id","sku_id"))
#加权
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd=0.005*us11+0.05*us12+0.3*us13+1*us14+0.1*us15+0.003*us16)
us_all=mutate(us_all,usrdg=1*us14+0.1*us15)
rm(us11,us12,us13,us14,us15,us16)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us21 = n())
us22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us22 = n())
us23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us23 = n())
us24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us24 = n())
us25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us25 = n())
us26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us26 = n())
us_all=left_join(us_all, us21, by=c("user_id","sku_id"))
us_all=left_join(us_all, us22, by=c("user_id","sku_id"))
us_all=left_join(us_all, us23, by=c("user_id","sku_id"))
us_all=left_join(us_all, us24, by=c("user_id","sku_id"))
us_all=left_join(us_all, us25, by=c("user_id","sku_id"))
us_all=left_join(us_all, us26, by=c("user_id","sku_id"))
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd45=0.005*us21+0.05*us22+0.3*us23+1*us24+0.1*us25+0.003*us26)
us_all=mutate(us_all,usrdg45=1*us24+0.1*us25)
rm(us21,us22,us23,us24,us25,us26)
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)

pzh21=log(1+us_all$us24)-log(1+us_all$us21)
pzh22=log(1+us_all$us24)-log(1+us_all$us22)
pzh23=log(1+us_all$us24)-log(1+us_all$us23)
uszh21=pzh21
uszh22=pzh22
uszh23=pzh23
us_all=cbind(us_all,uszh21)
us_all=cbind(us_all,uszh22)
us_all=cbind(us_all,uszh23)
us_all=tbl_df(us_all)
us_all[is.na(us_all)] <- 0
rm(pzh21,pzh22,pzh23,uszh21,uszh22,uszh23)

#前一天的是否加入加入购物车/关注
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us31=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us31 = n())
us32=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us32 = n())
us_all=left_join(us_all, us31, by=c("user_id","sku_id"))
us_all=left_join(us_all, us32, by=c("user_id","sku_id"))
rm(us31,us32)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
usjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(us_all,user_id,sku_id)
tmp=left_join(tmp, jqu21, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu22, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu23, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu24, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu25, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu26, by=c("user_id","sku_id"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=usjqday(1)
pt2jq=usjqday(2)
pt3jq=usjqday(3)
pt4jq=usjqday(4)
pt5jq=usjqday(5)
pt6jq=usjqday(6)
pt7jq=usjqday(7)
pt15jq=usjqday(15)
us_all=mutate(us_all,ust1jq=pt1jq)
us_all=mutate(us_all,ust2jq=pt2jq)
us_all=mutate(us_all,ust3jq=pt3jq)
us_all=mutate(us_all,ust4jq=pt4jq)
us_all=mutate(us_all,ust5jq=pt5jq)
us_all=mutate(us_all,ust6jq=pt6jq)
us_all=mutate(us_all,ust7jq=pt7jq)
us_all=mutate(us_all,ust15jq=pt15jq)
us_all[is.na(us_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","sku_id","usmaxtime1")
names(maxtime2)=c("user_id","sku_id","usmaxtime2")
us_all=left_join(us_all, maxtime1, by=c("user_id","sku_id"))
us_all=left_join(us_all, maxtime2, by=c("user_id","sku_id"))
us_all$usmaxtime2[is.na(us_all$usmaxtime2)]=tmp_diff
us_all$usmaxtime1[is.na(us_all$usmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","sku_id","usmintime1")
us_all=left_join(us_all, mintime1, by=c("user_id","sku_id"))
#最早一次没有交互的标为前50天到现在的日期
us_all$usmintime1[is.na(us_all$usmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
us_all=mutate(us_all,usmaxmintime=usmintime1-usmaxtime1)
us_all[is.na(us_all)] <- 0

##过去n天的行为天数
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday845")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday87")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday83")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

rm(u22)
us_all[is.na(us_all)]=0
#最近45n天的行为天数比例 flag
u22=us_all$usxwday845/45
us_all=mutate(us_all,usxwrate8=u22)
rm(u22)



#UB特征
ub=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,brand)
ub=unique(ub)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
ub21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>%  summarise(ub21 = n())
ub22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>%  summarise(ub22 = n())
ub23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>%  summarise(ub23 = n())
ub24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>%  summarise(ub24 = n())
ub25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>%  summarise(ub25 = n())
ub26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>%  summarise(ub26 = n())
ub_all=left_join(ub, ub21, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub22, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub23, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub24, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub25, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub26, by=c("user_id","brand"))
#权值
ub_all=mutate(ub_all,ubrd=0.005*ub21+0.05*ub22+0.3*ub23+1*ub24+0.1*ub25+0.003*ub26)
ub_all[is.na(ub_all)] <- 0
rm(ub21,ub22,ub23,ub24,ub25,ub26)


#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
ubjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(ub_all,user_id,brand)
tmp=left_join(tmp, jqu21, by=c("user_id","brand"))
tmp=left_join(tmp, jqu22, by=c("user_id","brand"))
tmp=left_join(tmp, jqu23, by=c("user_id","brand"))
tmp=left_join(tmp, jqu24, by=c("user_id","brand"))
tmp=left_join(tmp, jqu25, by=c("user_id","brand"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu21)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=ubjqday(1)
pt2jq=ubjqday(2)
pt3jq=ubjqday(3)
pt4jq=ubjqday(4)
pt5jq=ubjqday(5)
pt6jq=ubjqday(6)
pt7jq=ubjqday(7)
pt15jq=ubjqday(15)
ub_all=mutate(ub_all,ubt1jq=pt1jq)
ub_all=mutate(ub_all,ubt2jq=pt2jq)
ub_all=mutate(ub_all,ubt3jq=pt3jq)
ub_all=mutate(ub_all,ubt4jq=pt4jq)
ub_all=mutate(ub_all,ubt5jq=pt5jq)
ub_all=mutate(ub_all,ubt6jq=pt6jq)
ub_all=mutate(ub_all,ubt7jq=pt7jq)
ub_all=mutate(ub_all,ubt15jq=pt15jq)
ub_all[is.na(ub_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##转化率
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
ub_all[is.na(ub_all)] <- 0
pzh21=log(1+ub_all$ub24)-log(1+ub_all$ub21)
pzh22=log(1+ub_all$ub24)-log(1+ub_all$ub22)
pzh23=log(1+ub_all$ub24)-log(1+ub_all$ub23)
  ubzh21=pzh21
  ubzh22=pzh22
  ubzh23=pzh23
  ub_all=cbind(ub_all,ubzh21)
  ub_all=cbind(ub_all,ubzh22)
  ub_all=cbind(ub_all,ubzh23)
  ub_all=tbl_df(ub_all)
  ub_all[is.na(ub_all)] <- 0
  rm(pzh21,pzh22,pzh23,ubzh21,ubzh22,ubzh23)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","brand","ubmaxtime1")
names(maxtime2)=c("user_id","brand","ubmaxtime2")
ub_all=left_join(ub_all, maxtime1, by=c("user_id","brand"))
ub_all=left_join(ub_all, maxtime2, by=c("user_id","brand"))
ub_all$ubmaxtime2[is.na(ub_all$ubmaxtime2)]=tmp_diff
ub_all$ubmaxtime1[is.na(ub_all$ubmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","brand","ubmintime1")
ub_all=left_join(ub_all, mintime1, by=c("user_id","brand"))
#最早一次没有交互的标为前50天到现在的日期
ub_all$ubmintime1[is.na(ub_all$ubmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
ub_all=mutate(ub_all,ubmaxmintime=ubmintime1-ubmaxtime1)
ub_all[is.na(ub_all)] <- 0

#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday845")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday87")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday83")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

rm(u22)
ub_all[is.na(ub_all)]=0
#最近45n天的行为天数比例 flag
u22=ub_all$ubxwday845/45
ub_all=mutate(ub_all,ubxwrate8=u22)
rm(u22)



#合并特征集合
feature_all=left_join(us_all, u_all, by="user_id")
feature_all=left_join(feature_all, p_all, by="sku_id")
# feature_all[is.na(feature_all)] <- 0
feature_all=left_join(feature_all, ub_all, by=c("user_id","brand"))
# feature_all[is.na(feature_all)] <- 0
#去掉最近7天已经购买过的样本
feature_all=filter(feature_all,us14==0)

#特征label
d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id,sku_id)
mai_us=unique(mai_us)
mai_us=mutate(mai_us,label=1)
#拼接label
feature_all=left_join(feature_all,mai_us,by=c("user_id","sku_id"))
feature_all[which(is.na(feature_all$label)),]$label=0
#查看比例
table(feature_all$label)


#输出
write.table (feature_all, file ="train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (feature_all, file ="val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (feature_all, file ="test.csv",sep =",",row.names = F,col.names=TRUE,quote =F)



t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)
# t=filter(t,cate==8)
# user_rank=fread("train/user_train_pro.csv",header = TRUE)
# user_rank=fread("train/user_val_pro.csv",header = TRUE)
# names(user_rank)=c("user_id","urank")

time_end="2016/4/11"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
#用户id--所有策略对
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# user_id=filter(t,time>=start_time,time<time1) %>% select(user_id)
#用户商品对(删除不在p的子集)
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,sku_id)
us=unique(us)
tmp_diff=25
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx2=filter(t,time>=start_time,time<time1,cate==8,type==2 | type==3|  type==5) %>% select(user_id,sku_id)
usx2=unique(usx2)
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx3=filter(t,time>=start_time,time<time1,cate==8,type==4 | type==3) %>% select(user_id,sku_id)
usx3=unique(usx3)
usx2=setdiff(usx2,usx3) ##（在x中不在y中）
us=rbind(us,usx2)
us=unique(us)
#用户
user_id=unique(select(us,user_id))
u_all=tbl_df(as.data.frame(user_id))

rm(usx2,usx3,user_id)

##45天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
u_all=mutate(u_all,ujqg=1*u24+0.1*u25)
rm(u21,u22,u23,u24,u25,u26)

##45天的cate==8的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u21c")
names(u22)=c("user_id","u22c")
names(u23)=c("user_id","u23c")
names(u24)=c("user_id","u24c")
names(u25)=c("user_id","u25c")
names(u26)=c("user_id","u26c")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天cate=8加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujqc=0.005*u21c+0.05*u22c+0.3*u23c+1*u24c+0.1*u25c+0.003*u26c)
u_all=mutate(u_all,ujqcg=1*u24c+0.1*u25c)
rm(u21,u22,u23,u24,u25,u26)

##n天的浏览1、加入购物车2、关注5、下单4、删除3所有
jqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n()/tmp_diff)
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n()/tmp_diff)
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n()/tmp_diff)
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n()/tmp_diff)
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n()/tmp_diff)
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n()/tmp_diff)
tmp=select(u_all,user_id)
tmp=left_join(tmp, u21, by="user_id")
tmp=left_join(tmp, u22, by="user_id")
tmp=left_join(tmp, u23, by="user_id")
tmp=left_join(tmp, u24, by="user_id")
tmp=left_join(tmp, u25, by="user_id")
tmp=left_join(tmp, u26, by="user_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
ndayjq=tmp$ujq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
t1jq=jqday(1)
t2jq=jqday(2)
t3jq=jqday(3)
t4jq=jqday(4)
t5jq=jqday(5)
t6jq=jqday(6)
t7jq=jqday(7)
t15jq=jqday(15)
u_all=mutate(u_all,t1jq=t1jq)
u_all=mutate(u_all,t2jq=t2jq)
u_all=mutate(u_all,t3jq=t3jq)
u_all=mutate(u_all,t4jq=t4jq)
u_all=mutate(u_all,t5jq=t5jq)
u_all=mutate(u_all,t6jq=t6jq)
u_all=mutate(u_all,t7jq=t7jq)
u_all=mutate(u_all,t15jq=t15jq)

rm(t1jq,t2jq,t3jq,t4jq,t5jq,t6jq,t7jq,t15jq)

#最近3/7天是否加入购物车，删除购物车
##3天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u31")
names(u22)=c("user_id","u32")
names(u23)=c("user_id","u33")
names(u24)=c("user_id","u34")
names(u25)=c("user_id","u35")
names(u26)=c("user_id","u36")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u31+0.05*u32+0.3*u33+1*u34+0.1*u35+0.003*u36)
u_all=mutate(u_all,ujq23=0.005*u31+0.05*u32+0.3*u33-1*u34-0.1*u35+0.003*u36)

##7天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u71")
names(u22)=c("user_id","u72")
names(u23)=c("user_id","u73")
names(u24)=c("user_id","u74")
names(u25)=c("user_id","u75")
names(u26)=c("user_id","u76")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u71+0.05*u72+0.3*u73+1*u74+0.1*u75+0.003*u76)
u_all=mutate(u_all,ujq23=0.005*u71+0.05*u72+0.3*u73-1*u74-0.1*u75+0.003*u76)



##前45天转换率
uzh31={}
for(i in 1:length(u_all$u21)){
  if(u_all$u21[i]==0){
        uzh31=c(uzh31,0)
    }else{
        uzh31=c(uzh31,u_all$u24[i]/u_all$u21[i])
    }
}
uzh32={}
for(i in 1:length(u_all$u22)){
  if(u_all$u22[i]==0){
        uzh32=c(uzh32,0)
    }else{
        uzh32=c(uzh32,u_all$u24[i]/u_all$u22[i])
    }
}
uzh33={}
for(i in 1:length(u_all$u23)){
  if(u_all$u23[i]==0){
        uzh33=c(uzh33,0)
    }else{
        uzh33=c(uzh33,u_all$u24[i]/u_all$u23[i])
    }
}
uzh34={}
for(i in 1:length(u_all$u26)){
  if(u_all$u26[i]==0){
        uzh34=c(uzh34,0)
    }else{
        uzh34=c(uzh34,u_all$u24[i]/u_all$u26[i])
    }
}
u_all=cbind(u_all,uzh31)
u_all=cbind(u_all,uzh32)
u_all=cbind(u_all,uzh33)
u_all=cbind(u_all,uzh34)
u_all=tbl_df(u_all)

rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
# len=length(u41$u41)
# all=as.integer(all)/len
# u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
# tmp_diff=45
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
# len=length(u42$u42)
# all=as.integer(all)/len
# u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
# u_all=left_join(u_all, u41, by="user_id")
# u_all=left_join(u_all, u42, by="user_id")
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
rm(u41,u42,all,len,i)

##最近7天的cate==8活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u43=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u43 = n())
len=length(u43$u43)
all=as.integer(all)/len
u43$u43=u43$u43/as.integer(rep(all,length(u43$u43)))
names(u41)=c("user_id","u41c")
names(u42)=c("user_id","u42c")
names(u43)=c("user_id","u43c")
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
u_all=left_join(u_all, u43, by="user_id")

rm(u41,u42,u43,all,len)
#用户属性
u<- read.csv("JData_User.csv",fileEncoding='gbk',header = TRUE)
# names(u)=c("user_id","age","sex","user_lv_cd","user_reg_dt")
age=sort(unique(u$age))
age=data.frame(age,c(1:length(age)))
names(age)=c("age","agelabel")
u=left_join(u, age, by="age")
##注册时间距离购买日的时间间隔
timediff1=rep(time1,length(u$user_id))
u$user_reg_dt=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(u$user_reg_dt,"%Y/%m/%d")),units='day'))
u=select(u,user_id,agelabel,sex,user_lv_cd,user_reg_dt)
u$user_reg_dt[which(u$user_reg_dt>45)]=45

u_all=left_join(u_all, u, by="user_id")

rm(age,u,timediff1)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
u_all=left_join(u_all, maxtime1, by="user_id")
u_all=left_join(u_all, maxtime2, by="user_id")
rm(maxtime1,maxtime2,timediff1)
#最后一次没有购买的标为前50天到现在的日期
u_all$maxtime2[is.na(u_all$maxtime2)]=tmp_diff
u_all[is.na(u_all)] <- 0
##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
u_all=left_join(u_all, mintime1, by="user_id")
#最早一次没有交互的标为前50天到现在的日期
u_all$mintime1[is.na(u_all$mintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
u_all=mutate(u_all,maxmintime=mintime1-maxtime1)

u_all[is.na(u_all)] <- 0
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday45")
names(u22)=c("user_id","xwday845")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday7")
names(u22)=c("user_id","xwday87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday3")
names(u22)=c("user_id","xwday83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
rm(u21,u22)

##最近45天内浏览的商品个数、品牌个数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk1")
names(u22)=c("user_id","b1")
names(u23)=c("user_id","sk2")
names(u24)=c("user_id","b2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近3天内浏览的商品个数、品牌个数
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk3")
names(u22)=c("user_id","b3")
names(u23)=c("user_id","sk83")
names(u24)=c("user_id","b83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近7天内浏览的商品个数、品牌个数
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk7")
names(u22)=c("user_id","b7")
names(u23)=c("user_id","sk87")
names(u24)=c("user_id","b87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##top10商品的点击/浏览/加入购物车
##好商品top100好品牌50 交互的次数
##品牌top20 加权和
tl=fread("用户top20品牌特征.csv",header=TRUE)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
brandtop20=tl$V1+tl$V2+tl$V3+tl$V4+tl$V4+tl$V5+tl$V6+tl$V7+tl$V8+tl$V9+tl$V10+tl$V11+tl$V12+tl$V13+tl$V14+tl$V15+tl$V16+tl$V17+tl$V18+tl$V19+tl$V20
tl=cbind(tl,brandtop20)
tl=tbl_df(tl)
top20=select(tl,user_id,time,brandtop20)
names(top20)=c("user_id","time","brandtop20")

rm(tl)
#过去1/2/3/7/45天 的品牌加权和
top20day<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(top20,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u21 = sum(brandtop20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=top20day(1,tmp_id)
utl2=top20day(2,tmp_id)
utl3=top20day(3,tmp_id)
utl7=top20day(7,tmp_id)
utl15=top20day(15,tmp_id)
utl45=top20day(45,tmp_id)
u_all=mutate(u_all,btop1=utl1)
u_all=mutate(u_all,btop2=utl2)
u_all=mutate(u_all,btop3=utl3)
u_all=mutate(u_all,btop7=utl7)
u_all=mutate(u_all,btop15=utl15)
u_all=mutate(u_all,btop45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


tl=fread("用户top20品牌特征.csv",header=TRUE)
tl=tbl_df(tl)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
top20nday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(utop1 = sum(V1),utop2 = sum(V2),utop3 = sum(V3),utop4 = sum(V4),utop5 = sum(V5),utop6 = sum(V6),utop7 = sum(V7),utop8 = sum(V8),utop9 = sum(V9),utop10 = sum(V10),utop11 = sum(V11),utop12 = sum(V12),utop13 = sum(V13),utop14 = sum(V14),utop15 = sum(V15),utop16 = sum(V16),utop17 = sum(V17),utop18 = sum(V18),utop19 = sum(V19),utop20 = sum(V20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
return(tmp)
}
tmp_id=select(u_all,user_id)
# utl1=top20nday(1,tmp_id)
# utl2=top20nday(2,tmp_id)
# utl3=top20nday(3,tmp_id)
# utl7=top20nday(7,tmp_id)
# utl15=top20nday(15,tmp_id)
utl45=top20nday(45,tmp_id)
u_all=left_join(u_all,utl45,by="user_id")
rm(utl45,tl)
# write.table (u_all, file ="user_val2.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

##计算每个用户每个商品的停留时间秒 大于1个小时记录为10秒 每个用户商品/类别交互时间和
# tl=fread("停留时间特征2.csv",header=FALSE)
# names(tl)=c("user_id","sku_id","time","tltime")
# tl=tbl_df(tl)
# p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
# p=tbl_df(p)
# p=select(p,sku_id,cate,brand)
# tl=left_join(tl,p,by="sku_id")
# tl=filter(tl,cate==8)
# write.table (tl, file ="停留时间特征.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tl=fread("停留时间特征.csv",header=TRUE)
tl=tbl_df(tl)
#过去1/2/3/7/45天每个用户的停留时间
tltimeday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u21 = sum(tltime))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=tltimeday(1,tmp_id)
utl2=tltimeday(2,tmp_id)
utl3=tltimeday(3,tmp_id)
utl7=tltimeday(7,tmp_id)
utl15=tltimeday(15,tmp_id)
utl45=tltimeday(45,tmp_id)
u_all=mutate(u_all,utl1=utl1)
u_all=mutate(u_all,utl2=utl2)
u_all=mutate(u_all,utl3=utl3)
u_all=mutate(u_all,utl7=utl7)
u_all=mutate(u_all,utl15=utl15)
u_all=mutate(u_all,utl45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


# u_all=left_join(u_all,user_rank,by="user_id")
# rm(user_rank)

##商品特征
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
sku_id=unique(p$sku_id)
p_all=tbl_df(as.data.frame(sku_id))
p_all=left_join(p_all, select(p,sku_id,attr1,attr2,attr3,brand), by="sku_id")
rm(p,sku_id)
#45天的浏览1、加入购物车2、关注5、下单4、删除3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(p11 = n())
p12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(p12 = n())
p13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(p13 = n())
p14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(p14 = n())
p15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(p15 = n())
p16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(p16 = n())
p_all=left_join(p_all, p11, by="sku_id")
p_all=left_join(p_all, p12, by="sku_id")
p_all=left_join(p_all, p13, by="sku_id")
p_all=left_join(p_all, p14, by="sku_id")
p_all=left_join(p_all, p15, by="sku_id")
p_all=left_join(p_all, p16, by="sku_id")
##商品热度 加权和
p_all[is.na(p_all)] <- 0
p_all=mutate(p_all,prd=0.005*p11+0.05*p12+0.3*p13+1*p14+0.1*p15+0.003*p16)
p_all=mutate(p_all,prdg=1*p14+0.1*p15)
rm(p11,p12,p13,p14,p15,p16)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
pjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(p_all,sku_id)
tmp=left_join(tmp, jqu21, by="sku_id")
tmp=left_join(tmp, jqu22, by="sku_id")
tmp=left_join(tmp, jqu23, by="sku_id")
tmp=left_join(tmp, jqu24, by="sku_id")
tmp=left_join(tmp, jqu25, by="sku_id")
tmp=left_join(tmp, jqu26, by="sku_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=pjqday(1)
pt2jq=pjqday(2)
pt3jq=pjqday(3)
pt4jq=pjqday(4)
pt5jq=pjqday(5)
pt6jq=pjqday(6)
pt7jq=pjqday(7)
pt15jq=pjqday(15)
p_all=mutate(p_all,pt1jq=pt1jq)
p_all=mutate(p_all,pt2jq=pt2jq)
p_all=mutate(p_all,pt3jq=pt3jq)
p_all=mutate(p_all,pt4jq=pt4jq)
p_all=mutate(p_all,pt5jq=pt5jq)
p_all=mutate(p_all,pt6jq=pt6jq)
p_all=mutate(p_all,pt7jq=pt7jq)
p_all=mutate(p_all,pt15jq=pt15jq)

rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
p_all[is.na(p_all)] <- 0
pzh21={}
for(i in 1:length(p_all$p11)){
  if(p_all$p11[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,p_all$p14[i]/p_all$p11[i])
    }
}
pzh22={}
for(i in 1:length(p_all$p12)){
  if(p_all$p12[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,p_all$p14[i]/p_all$p12[i])
    }
}
pzh23={}
for(i in 1:length(p_all$p13)){
  if(p_all$p13[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,p_all$p14[i]/p_all$p13[i])
    }
}
p_all=cbind(p_all,pzh21)
p_all=cbind(p_all,pzh22)
p_all=cbind(p_all,pzh23)
p_all=tbl_df(p_all)
rm(pzh21,pzh22,pzh23,i)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("sku_id","pmaxtime1")
names(maxtime2)=c("sku_id","pmaxtime2")
p_all=left_join(p_all, maxtime1, by="sku_id")
p_all=left_join(p_all, maxtime2, by="sku_id")
#最后一次没有购买的标为 tmp_diff
p_all$pmaxtime2[is.na(p_all$pmaxtime2)]=tmp_diff
p_all$pmaxtime1[is.na(p_all$pmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("sku_id","pmintime1")
p_all=left_join(p_all, mintime1, by="sku_id")
#最早一次没有交互的标为前50天到现在的日期
p_all$pmintime1[is.na(p_all$pmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
p_all=mutate(p_all,pmaxmintime=pmintime1-pmaxtime1)
p_all[is.na(p_all)] <- 0


##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% distinct(user_id) %>% summarise(p31 = n())
p_all=left_join(p_all, p31, by="sku_id")
p_all[is.na(p_all)] <- 0
##评价
c<- read.csv("JData_Comment.csv",fileEncoding='gbk',header = TRUE)
c=tbl_df(c)
# cp=filter(c,dt == as.Date(d[length(d)-1],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# if(nrow(cp)<2){
#   cp=filter(c,dt == as.Date(d[length(d)-2],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# }
cp=c %>% group_by(sku_id) %>% summarise(comment_num=mean(comment_num),has_bad_comment=mean(has_bad_comment),bad_comment_rate=mean(bad_comment_rate))
p_all=left_join(p_all, cp, by="sku_id")
rm(p31,c,cp)


#品牌特征B
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
brand=unique(p$brand)
brand_all=tbl_df(as.data.frame(brand))
rm(p,brand)
#该品牌过去45天共有多少种商品
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b11=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(sku_id) %>% summarise(b11 = n())
brand_all=left_join(brand_all,b11, by="brand")
##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(user_id) %>% summarise(p31 = n())
names(p31)=c("brand","p31b")
brand_all=left_join(brand_all, p31, by="brand")
brand_all[is.na(brand_all)] <- 0

#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>%  summarise(b21 = n())
b22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>%  summarise(b22 = n())
b23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>%  summarise(b23 = n())
b24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>%  summarise(b24 = n())
b25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>%  summarise(b25 = n())
b26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>%  summarise(b26 = n())
brand_all=left_join(brand_all, b21, by="brand")
brand_all=left_join(brand_all, b22, by="brand")
brand_all=left_join(brand_all, b23, by="brand")
brand_all=left_join(brand_all, b24, by="brand")
brand_all=left_join(brand_all, b25, by="brand")
brand_all=left_join(brand_all, b26, by="brand")
brand_all=mutate(brand_all,brd=0.005*b21+0.05*b22+0.3*b23+1*b24+0.1*b25+0.003*b26)
brand_all[is.na(brand_all)] <- 0

rm(b11,b21,b22,b23,b24,b25,b26)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
bjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(brand_all,brand)
tmp=left_join(tmp, jqu21, by="brand")
tmp=left_join(tmp, jqu22, by="brand")
tmp=left_join(tmp, jqu23, by="brand")
tmp=left_join(tmp, jqu24, by="brand")
tmp=left_join(tmp, jqu25, by="brand")
tmp=left_join(tmp, jqu26, by="brand")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=bjqday(1)
pt2jq=bjqday(2)
pt3jq=bjqday(3)
pt4jq=bjqday(4)
pt5jq=bjqday(5)
pt6jq=bjqday(6)
pt7jq=bjqday(7)
pt15jq=bjqday(15)
brand_all=mutate(brand_all,bt1jq=pt1jq)
brand_all=mutate(brand_all,bt2jq=pt2jq)
brand_all=mutate(brand_all,bt3jq=pt3jq)
brand_all=mutate(brand_all,bt4jq=pt4jq)
brand_all=mutate(brand_all,bt5jq=pt5jq)
brand_all=mutate(brand_all,bt6jq=pt6jq)
brand_all=mutate(brand_all,bt7jq=pt7jq)
brand_all=mutate(brand_all,bt15jq=pt15jq)
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
brand_all[is.na(brand_all)] <- 0
pzh21={}
for(i in 1:length(brand_all$b21)){
  if(brand_all$b21[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,brand_all$b24[i]/brand_all$b21[i])
    }
}
pzh22={}
for(i in 1:length(brand_all$b22)){
  if(brand_all$b22[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,brand_all$b24[i]/brand_all$b22[i])
    }
}
pzh23={}
for(i in 1:length(brand_all$b23)){
  if(brand_all$b23[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,brand_all$b24[i]/brand_all$b23[i])
    }
}
bzh21=pzh21
bzh22=pzh22
bzh23=pzh23
brand_all=cbind(brand_all,bzh21)
brand_all=cbind(brand_all,bzh22)
brand_all=cbind(brand_all,bzh23)
brand_all=tbl_df(brand_all)
brand_all[is.na(brand_all)] <- 0

rm(bzh21,bzh22,bzh23,pzh21,pzh22,pzh23,i)


##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("brand","bmaxtime1")
names(maxtime2)=c("brand","bmaxtime2")
brand_all=left_join(brand_all, maxtime1, by="brand")
brand_all=left_join(brand_all, maxtime2, by="brand")
#最后一次没有购买的标为 tmp_diff
brand_all$bmaxtime2[is.na(brand_all$bmaxtime2)]=tmp_diff
brand_all$bmaxtime1[is.na(brand_all$bmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("brand","bmintime1")
brand_all=left_join(brand_all, mintime1, by="brand")
#最早一次没有交互的标为前50天到现在的日期
brand_all$bmintime1[is.na(brand_all$bmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
brand_all=mutate(brand_all,bmaxmintime=bmintime1-bmaxtime1)
brand_all[is.na(brand_all)] <- 0

##合并特征
p_all=left_join(p_all, brand_all, by="brand")


#用户-商品 交叉特征
#7天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us11 = n())
us12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us12 = n())
us13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us13 = n())
us14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us14 = n())
us15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us15 = n())
us16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us16 = n())
us_all=left_join(us, us11, by=c("user_id","sku_id"))
us_all=left_join(us_all, us12, by=c("user_id","sku_id"))
us_all=left_join(us_all, us13, by=c("user_id","sku_id"))
us_all=left_join(us_all, us14, by=c("user_id","sku_id"))
us_all=left_join(us_all, us15, by=c("user_id","sku_id"))
us_all=left_join(us_all, us16, by=c("user_id","sku_id"))
#加权
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd=0.005*us11+0.05*us12+0.3*us13+1*us14+0.1*us15+0.003*us16)
us_all=mutate(us_all,usrdg=1*us14+0.1*us15)
rm(us11,us12,us13,us14,us15,us16)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us21 = n())
us22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us22 = n())
us23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us23 = n())
us24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us24 = n())
us25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us25 = n())
us26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us26 = n())
us_all=left_join(us_all, us21, by=c("user_id","sku_id"))
us_all=left_join(us_all, us22, by=c("user_id","sku_id"))
us_all=left_join(us_all, us23, by=c("user_id","sku_id"))
us_all=left_join(us_all, us24, by=c("user_id","sku_id"))
us_all=left_join(us_all, us25, by=c("user_id","sku_id"))
us_all=left_join(us_all, us26, by=c("user_id","sku_id"))
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd45=0.005*us21+0.05*us22+0.3*us23+1*us24+0.1*us25+0.003*us26)
us_all=mutate(us_all,usrdg45=1*us24+0.1*us25)
rm(us21,us22,us23,us24,us25,us26)
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)

pzh21=log(1+us_all$us24)-log(1+us_all$us21)
pzh22=log(1+us_all$us24)-log(1+us_all$us22)
pzh23=log(1+us_all$us24)-log(1+us_all$us23)
uszh21=pzh21
uszh22=pzh22
uszh23=pzh23
us_all=cbind(us_all,uszh21)
us_all=cbind(us_all,uszh22)
us_all=cbind(us_all,uszh23)
us_all=tbl_df(us_all)
us_all[is.na(us_all)] <- 0
rm(pzh21,pzh22,pzh23,uszh21,uszh22,uszh23)

#前一天的是否加入加入购物车/关注
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us31=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us31 = n())
us32=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us32 = n())
us_all=left_join(us_all, us31, by=c("user_id","sku_id"))
us_all=left_join(us_all, us32, by=c("user_id","sku_id"))
rm(us31,us32)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
usjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(us_all,user_id,sku_id)
tmp=left_join(tmp, jqu21, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu22, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu23, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu24, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu25, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu26, by=c("user_id","sku_id"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=usjqday(1)
pt2jq=usjqday(2)
pt3jq=usjqday(3)
pt4jq=usjqday(4)
pt5jq=usjqday(5)
pt6jq=usjqday(6)
pt7jq=usjqday(7)
pt15jq=usjqday(15)
us_all=mutate(us_all,ust1jq=pt1jq)
us_all=mutate(us_all,ust2jq=pt2jq)
us_all=mutate(us_all,ust3jq=pt3jq)
us_all=mutate(us_all,ust4jq=pt4jq)
us_all=mutate(us_all,ust5jq=pt5jq)
us_all=mutate(us_all,ust6jq=pt6jq)
us_all=mutate(us_all,ust7jq=pt7jq)
us_all=mutate(us_all,ust15jq=pt15jq)
us_all[is.na(us_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","sku_id","usmaxtime1")
names(maxtime2)=c("user_id","sku_id","usmaxtime2")
us_all=left_join(us_all, maxtime1, by=c("user_id","sku_id"))
us_all=left_join(us_all, maxtime2, by=c("user_id","sku_id"))
us_all$usmaxtime2[is.na(us_all$usmaxtime2)]=tmp_diff
us_all$usmaxtime1[is.na(us_all$usmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","sku_id","usmintime1")
us_all=left_join(us_all, mintime1, by=c("user_id","sku_id"))
#最早一次没有交互的标为前50天到现在的日期
us_all$usmintime1[is.na(us_all$usmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
us_all=mutate(us_all,usmaxmintime=usmintime1-usmaxtime1)
us_all[is.na(us_all)] <- 0

##过去n天的行为天数
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday845")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday87")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday83")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

rm(u22)
us_all[is.na(us_all)]=0
#最近45n天的行为天数比例 flag
u22=us_all$usxwday845/45
us_all=mutate(us_all,usxwrate8=u22)
rm(u22)



#UB特征
ub=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,brand)
ub=unique(ub)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
ub21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>%  summarise(ub21 = n())
ub22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>%  summarise(ub22 = n())
ub23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>%  summarise(ub23 = n())
ub24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>%  summarise(ub24 = n())
ub25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>%  summarise(ub25 = n())
ub26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>%  summarise(ub26 = n())
ub_all=left_join(ub, ub21, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub22, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub23, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub24, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub25, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub26, by=c("user_id","brand"))
#权值
ub_all=mutate(ub_all,ubrd=0.005*ub21+0.05*ub22+0.3*ub23+1*ub24+0.1*ub25+0.003*ub26)
ub_all[is.na(ub_all)] <- 0
rm(ub21,ub22,ub23,ub24,ub25,ub26)


#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
ubjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(ub_all,user_id,brand)
tmp=left_join(tmp, jqu21, by=c("user_id","brand"))
tmp=left_join(tmp, jqu22, by=c("user_id","brand"))
tmp=left_join(tmp, jqu23, by=c("user_id","brand"))
tmp=left_join(tmp, jqu24, by=c("user_id","brand"))
tmp=left_join(tmp, jqu25, by=c("user_id","brand"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu21)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=ubjqday(1)
pt2jq=ubjqday(2)
pt3jq=ubjqday(3)
pt4jq=ubjqday(4)
pt5jq=ubjqday(5)
pt6jq=ubjqday(6)
pt7jq=ubjqday(7)
pt15jq=ubjqday(15)
ub_all=mutate(ub_all,ubt1jq=pt1jq)
ub_all=mutate(ub_all,ubt2jq=pt2jq)
ub_all=mutate(ub_all,ubt3jq=pt3jq)
ub_all=mutate(ub_all,ubt4jq=pt4jq)
ub_all=mutate(ub_all,ubt5jq=pt5jq)
ub_all=mutate(ub_all,ubt6jq=pt6jq)
ub_all=mutate(ub_all,ubt7jq=pt7jq)
ub_all=mutate(ub_all,ubt15jq=pt15jq)
ub_all[is.na(ub_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##转化率
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
ub_all[is.na(ub_all)] <- 0
pzh21=log(1+ub_all$ub24)-log(1+ub_all$ub21)
pzh22=log(1+ub_all$ub24)-log(1+ub_all$ub22)
pzh23=log(1+ub_all$ub24)-log(1+ub_all$ub23)
  ubzh21=pzh21
  ubzh22=pzh22
  ubzh23=pzh23
  ub_all=cbind(ub_all,ubzh21)
  ub_all=cbind(ub_all,ubzh22)
  ub_all=cbind(ub_all,ubzh23)
  ub_all=tbl_df(ub_all)
  ub_all[is.na(ub_all)] <- 0
  rm(pzh21,pzh22,pzh23,ubzh21,ubzh22,ubzh23)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","brand","ubmaxtime1")
names(maxtime2)=c("user_id","brand","ubmaxtime2")
ub_all=left_join(ub_all, maxtime1, by=c("user_id","brand"))
ub_all=left_join(ub_all, maxtime2, by=c("user_id","brand"))
ub_all$ubmaxtime2[is.na(ub_all$ubmaxtime2)]=tmp_diff
ub_all$ubmaxtime1[is.na(ub_all$ubmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","brand","ubmintime1")
ub_all=left_join(ub_all, mintime1, by=c("user_id","brand"))
#最早一次没有交互的标为前50天到现在的日期
ub_all$ubmintime1[is.na(ub_all$ubmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
ub_all=mutate(ub_all,ubmaxmintime=ubmintime1-ubmaxtime1)
ub_all[is.na(ub_all)] <- 0

#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday845")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday87")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday83")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

rm(u22)
ub_all[is.na(ub_all)]=0
#最近45n天的行为天数比例 flag
u22=ub_all$ubxwday845/45
ub_all=mutate(ub_all,ubxwrate8=u22)
rm(u22)



#合并特征集合
feature_all=left_join(us_all, u_all, by="user_id")
feature_all=left_join(feature_all, p_all, by="sku_id")
# feature_all[is.na(feature_all)] <- 0
feature_all=left_join(feature_all, ub_all, by=c("user_id","brand"))
# feature_all[is.na(feature_all)] <- 0
#去掉最近7天已经购买过的样本
feature_all=filter(feature_all,us14==0)

#特征label
d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id,sku_id)
mai_us=unique(mai_us)
mai_us=mutate(mai_us,label=1)
#拼接label
feature_all=left_join(feature_all,mai_us,by=c("user_id","sku_id"))
feature_all[which(is.na(feature_all$label)),]$label=0
#查看比例
table(feature_all$label)


#输出
# write.table (feature_all, file ="train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

write.table (feature_all, file ="val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)


# library(dtplyr)
t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)
# t=filter(t,cate==8)
# user_rank=fread("train/user_train_pro.csv",header = TRUE)
# user_rank=fread("train/user_val_pro.csv",header = TRUE)
# names(user_rank)=c("user_id","urank")

time_end="2016/4/16"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
#用户id--所有策略对
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# user_id=filter(t,time>=start_time,time<time1) %>% select(user_id)
#用户商品对(删除不在p的子集)
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,sku_id)
us=unique(us)
tmp_diff=25
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx2=filter(t,time>=start_time,time<time1,cate==8,type==2 | type==3|  type==5) %>% select(user_id,sku_id)
usx2=unique(usx2)
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
usx3=filter(t,time>=start_time,time<time1,cate==8,type==4 | type==3) %>% select(user_id,sku_id)
usx3=unique(usx3)
usx2=setdiff(usx2,usx3) ##（在x中不在y中）
us=rbind(us,usx2)
us=unique(us)
#用户
user_id=unique(select(us,user_id))
u_all=tbl_df(as.data.frame(user_id))

rm(usx2,usx3,user_id)

##45天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
u_all=mutate(u_all,ujqg=1*u24+0.1*u25)
rm(u21,u22,u23,u24,u25,u26)

##45天的cate==8的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u21c")
names(u22)=c("user_id","u22c")
names(u23)=c("user_id","u23c")
names(u24)=c("user_id","u24c")
names(u25)=c("user_id","u25c")
names(u26)=c("user_id","u26c")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all[is.na(u_all)] <- 0
##前面45天cate=8加权和0.005x1+0.05x2+0.3x5+1x4+0.1x3
u_all=mutate(u_all,ujqc=0.005*u21c+0.05*u22c+0.3*u23c+1*u24c+0.1*u25c+0.003*u26c)
u_all=mutate(u_all,ujqcg=1*u24c+0.1*u25c)
rm(u21,u22,u23,u24,u25,u26)

##n天的浏览1、加入购物车2、关注5、下单4、删除3所有
jqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n()/tmp_diff)
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n()/tmp_diff)
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n()/tmp_diff)
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n()/tmp_diff)
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n()/tmp_diff)
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n()/tmp_diff)
tmp=select(u_all,user_id)
tmp=left_join(tmp, u21, by="user_id")
tmp=left_join(tmp, u22, by="user_id")
tmp=left_join(tmp, u23, by="user_id")
tmp=left_join(tmp, u24, by="user_id")
tmp=left_join(tmp, u25, by="user_id")
tmp=left_join(tmp, u26, by="user_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,ujq=0.005*u21+0.05*u22+0.3*u23+1*u24+0.1*u25+0.003*u26)
ndayjq=tmp$ujq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
t1jq=jqday(1)
t2jq=jqday(2)
t3jq=jqday(3)
t4jq=jqday(4)
t5jq=jqday(5)
t6jq=jqday(6)
t7jq=jqday(7)
t15jq=jqday(15)
u_all=mutate(u_all,t1jq=t1jq)
u_all=mutate(u_all,t2jq=t2jq)
u_all=mutate(u_all,t3jq=t3jq)
u_all=mutate(u_all,t4jq=t4jq)
u_all=mutate(u_all,t5jq=t5jq)
u_all=mutate(u_all,t6jq=t6jq)
u_all=mutate(u_all,t7jq=t7jq)
u_all=mutate(u_all,t15jq=t15jq)

rm(t1jq,t2jq,t3jq,t4jq,t5jq,t6jq,t7jq,t15jq)

#最近3/7天是否加入购物车，删除购物车
##3天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u31")
names(u22)=c("user_id","u32")
names(u23)=c("user_id","u33")
names(u24)=c("user_id","u34")
names(u25)=c("user_id","u35")
names(u26)=c("user_id","u36")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u31+0.05*u32+0.3*u33+1*u34+0.1*u35+0.003*u36)
u_all=mutate(u_all,ujq23=0.005*u31+0.05*u32+0.3*u33-1*u34-0.1*u35+0.003*u36)

##7天的浏览1、加入购物车2、关注5、下单4、删除3所有
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
names(u21)=c("user_id","u71")
names(u22)=c("user_id","u72")
names(u23)=c("user_id","u73")
names(u24)=c("user_id","u74")
names(u25)=c("user_id","u75")
names(u26)=c("user_id","u76")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
u_all=left_join(u_all, u25, by="user_id")
u_all=left_join(u_all, u26, by="user_id")
u_all=mutate(u_all,ujq3=0.005*u71+0.05*u72+0.3*u73+1*u74+0.1*u75+0.003*u76)
u_all=mutate(u_all,ujq23=0.005*u71+0.05*u72+0.3*u73-1*u74-0.1*u75+0.003*u76)



##前45天转换率
uzh31={}
for(i in 1:length(u_all$u21)){
  if(u_all$u21[i]==0){
        uzh31=c(uzh31,0)
    }else{
        uzh31=c(uzh31,u_all$u24[i]/u_all$u21[i])
    }
}
uzh32={}
for(i in 1:length(u_all$u22)){
  if(u_all$u22[i]==0){
        uzh32=c(uzh32,0)
    }else{
        uzh32=c(uzh32,u_all$u24[i]/u_all$u22[i])
    }
}
uzh33={}
for(i in 1:length(u_all$u23)){
  if(u_all$u23[i]==0){
        uzh33=c(uzh33,0)
    }else{
        uzh33=c(uzh33,u_all$u24[i]/u_all$u23[i])
    }
}
uzh34={}
for(i in 1:length(u_all$u26)){
  if(u_all$u26[i]==0){
        uzh34=c(uzh34,0)
    }else{
        uzh34=c(uzh34,u_all$u24[i]/u_all$u26[i])
    }
}
u_all=cbind(u_all,uzh31)
u_all=cbind(u_all,uzh32)
u_all=cbind(u_all,uzh33)
u_all=cbind(u_all,uzh34)
u_all=tbl_df(u_all)

rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
# tmp_diff=7
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
# len=length(u41$u41)
# all=as.integer(all)/len
# u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
# tmp_diff=45
# start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
# all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
# u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
# len=length(u42$u42)
# all=as.integer(all)/len
# u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
# u_all=left_join(u_all, u41, by="user_id")
# u_all=left_join(u_all, u42, by="user_id")
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
rm(u41,u42,all,len,i)

##最近7天的cate==8活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u42=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u42 = n())
len=length(u42$u42)
all=as.integer(all)/len
u42$u42=u42$u42/as.integer(rep(all,length(u42$u42)))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1,cate==8)  %>% summarise(n())
u43=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u43 = n())
len=length(u43$u43)
all=as.integer(all)/len
u43$u43=u43$u43/as.integer(rep(all,length(u43$u43)))
names(u41)=c("user_id","u41c")
names(u42)=c("user_id","u42c")
names(u43)=c("user_id","u43c")
u_all=left_join(u_all, u41, by="user_id")
u_all=left_join(u_all, u42, by="user_id")
u_all=left_join(u_all, u43, by="user_id")

rm(u41,u42,u43,all,len)
#用户属性
u<- read.csv("JData_User.csv",fileEncoding='gbk',header = TRUE)
# names(u)=c("user_id","age","sex","user_lv_cd","user_reg_dt")
age=sort(unique(u$age))
age=data.frame(age,c(1:length(age)))
names(age)=c("age","agelabel")
u=left_join(u, age, by="age")
##注册时间距离购买日的时间间隔
timediff1=rep(time1,length(u$user_id))
u$user_reg_dt=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(u$user_reg_dt,"%Y/%m/%d")),units='day'))
u=select(u,user_id,agelabel,sex,user_lv_cd,user_reg_dt)
u$user_reg_dt[which(u$user_reg_dt>45)]=45

u_all=left_join(u_all, u, by="user_id")

rm(age,u,timediff1)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
u_all=left_join(u_all, maxtime1, by="user_id")
u_all=left_join(u_all, maxtime2, by="user_id")
rm(maxtime1,maxtime2,timediff1)
#最后一次没有购买的标为前50天到现在的日期
u_all$maxtime2[is.na(u_all$maxtime2)]=tmp_diff
u_all[is.na(u_all)] <- 0
##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
u_all=left_join(u_all, mintime1, by="user_id")
#最早一次没有交互的标为前50天到现在的日期
u_all$mintime1[is.na(u_all$mintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
u_all=mutate(u_all,maxmintime=mintime1-maxtime1)

u_all[is.na(u_all)] <- 0
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday45")
names(u22)=c("user_id","xwday845")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday7")
names(u22)=c("user_id","xwday87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday3")
names(u22)=c("user_id","xwday83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
rm(u21,u22)

##最近45天内浏览的商品个数、品牌个数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk1")
names(u22)=c("user_id","b1")
names(u23)=c("user_id","sk2")
names(u24)=c("user_id","b2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近3天内浏览的商品个数、品牌个数
tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk3")
names(u22)=c("user_id","b3")
names(u23)=c("user_id","sk83")
names(u24)=c("user_id","b83")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##最近7天内浏览的商品个数、品牌个数
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","sk7")
names(u22)=c("user_id","b7")
names(u23)=c("user_id","sk87")
names(u24)=c("user_id","b87")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)

##top10商品的点击/浏览/加入购物车
##好商品top100好品牌50 交互的次数
##品牌top20 加权和
tl=fread("用户top20品牌特征.csv",header=TRUE)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
brandtop20=tl$V1+tl$V2+tl$V3+tl$V4+tl$V4+tl$V5+tl$V6+tl$V7+tl$V8+tl$V9+tl$V10+tl$V11+tl$V12+tl$V13+tl$V14+tl$V15+tl$V16+tl$V17+tl$V18+tl$V19+tl$V20
tl=cbind(tl,brandtop20)
tl=tbl_df(tl)
top20=select(tl,user_id,time,brandtop20)
names(top20)=c("user_id","time","brandtop20")

rm(tl)
#过去1/2/3/7/45天 的品牌加权和
top20day<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(top20,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u21 = sum(brandtop20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=top20day(1,tmp_id)
utl2=top20day(2,tmp_id)
utl3=top20day(3,tmp_id)
utl7=top20day(7,tmp_id)
utl15=top20day(15,tmp_id)
utl45=top20day(45,tmp_id)
u_all=mutate(u_all,btop1=utl1)
u_all=mutate(u_all,btop2=utl2)
u_all=mutate(u_all,btop3=utl3)
u_all=mutate(u_all,btop7=utl7)
u_all=mutate(u_all,btop15=utl15)
u_all=mutate(u_all,btop45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


tl=fread("用户top20品牌特征.csv",header=TRUE)
tl=tbl_df(tl)
names(tl)=c("user_id","time","V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20")
top20nday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(utop1 = sum(V1),utop2 = sum(V2),utop3 = sum(V3),utop4 = sum(V4),utop5 = sum(V5),utop6 = sum(V6),utop7 = sum(V7),utop8 = sum(V8),utop9 = sum(V9),utop10 = sum(V10),utop11 = sum(V11),utop12 = sum(V12),utop13 = sum(V13),utop14 = sum(V14),utop15 = sum(V15),utop16 = sum(V16),utop17 = sum(V17),utop18 = sum(V18),utop19 = sum(V19),utop20 = sum(V20))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
return(tmp)
}
tmp_id=select(u_all,user_id)
# utl1=top20nday(1,tmp_id)
# utl2=top20nday(2,tmp_id)
# utl3=top20nday(3,tmp_id)
# utl7=top20nday(7,tmp_id)
# utl15=top20nday(15,tmp_id)
utl45=top20nday(45,tmp_id)
u_all=left_join(u_all,utl45,by="user_id")
rm(utl45,tl)
# write.table (u_all, file ="user_val2.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

##计算每个用户每个商品的停留时间秒 大于1个小时记录为10秒 每个用户商品/类别交互时间和
# tl=fread("停留时间特征2.csv",header=FALSE)
# names(tl)=c("user_id","sku_id","time","tltime")
# tl=tbl_df(tl)
# p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
# p=tbl_df(p)
# p=select(p,sku_id,cate,brand)
# tl=left_join(tl,p,by="sku_id")
# tl=filter(tl,cate==8)
# write.table (tl, file ="停留时间特征.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tl=fread("停留时间特征.csv",header=TRUE)
tl=tbl_df(tl)
#过去1/2/3/7/45天每个用户的停留时间
tltimeday<-function(nday,user_id){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(tl,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% summarise(u21 = sum(tltime))
tmp=user_id
tmp=left_join(tmp, u21, by="user_id")
tmp[is.na(tmp)]=0
ndayjq=tmp$u21
return(ndayjq)
}
tmp_id=select(u_all,user_id)
utl1=tltimeday(1,tmp_id)
utl2=tltimeday(2,tmp_id)
utl3=tltimeday(3,tmp_id)
utl7=tltimeday(7,tmp_id)
utl15=tltimeday(15,tmp_id)
utl45=tltimeday(45,tmp_id)
u_all=mutate(u_all,utl1=utl1)
u_all=mutate(u_all,utl2=utl2)
u_all=mutate(u_all,utl3=utl3)
u_all=mutate(u_all,utl7=utl7)
u_all=mutate(u_all,utl15=utl15)
u_all=mutate(u_all,utl45=utl45)
rm(tmp_id,utl1,utl2,utl3,utl7,utl15,utl45)


# u_all=left_join(u_all,user_rank,by="user_id")
# rm(user_rank)

##商品特征
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
sku_id=unique(p$sku_id)
p_all=tbl_df(as.data.frame(sku_id))
p_all=left_join(p_all, select(p,sku_id,attr1,attr2,attr3,brand), by="sku_id")
rm(p,sku_id)
#45天的浏览1、加入购物车2、关注5、下单4、删除3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(p11 = n())
p12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(p12 = n())
p13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(p13 = n())
p14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(p14 = n())
p15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(p15 = n())
p16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(p16 = n())
p_all=left_join(p_all, p11, by="sku_id")
p_all=left_join(p_all, p12, by="sku_id")
p_all=left_join(p_all, p13, by="sku_id")
p_all=left_join(p_all, p14, by="sku_id")
p_all=left_join(p_all, p15, by="sku_id")
p_all=left_join(p_all, p16, by="sku_id")
##商品热度 加权和
p_all[is.na(p_all)] <- 0
p_all=mutate(p_all,prd=0.005*p11+0.05*p12+0.3*p13+1*p14+0.1*p15+0.003*p16)
p_all=mutate(p_all,prdg=1*p14+0.1*p15)
rm(p11,p12,p13,p14,p15,p16)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
pjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(p_all,sku_id)
tmp=left_join(tmp, jqu21, by="sku_id")
tmp=left_join(tmp, jqu22, by="sku_id")
tmp=left_join(tmp, jqu23, by="sku_id")
tmp=left_join(tmp, jqu24, by="sku_id")
tmp=left_join(tmp, jqu25, by="sku_id")
tmp=left_join(tmp, jqu26, by="sku_id")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=pjqday(1)
pt2jq=pjqday(2)
pt3jq=pjqday(3)
pt4jq=pjqday(4)
pt5jq=pjqday(5)
pt6jq=pjqday(6)
pt7jq=pjqday(7)
pt15jq=pjqday(15)
p_all=mutate(p_all,pt1jq=pt1jq)
p_all=mutate(p_all,pt2jq=pt2jq)
p_all=mutate(p_all,pt3jq=pt3jq)
p_all=mutate(p_all,pt4jq=pt4jq)
p_all=mutate(p_all,pt5jq=pt5jq)
p_all=mutate(p_all,pt6jq=pt6jq)
p_all=mutate(p_all,pt7jq=pt7jq)
p_all=mutate(p_all,pt15jq=pt15jq)

rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
p_all[is.na(p_all)] <- 0
pzh21={}
for(i in 1:length(p_all$p11)){
  if(p_all$p11[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,p_all$p14[i]/p_all$p11[i])
    }
}
pzh22={}
for(i in 1:length(p_all$p12)){
  if(p_all$p12[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,p_all$p14[i]/p_all$p12[i])
    }
}
pzh23={}
for(i in 1:length(p_all$p13)){
  if(p_all$p13[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,p_all$p14[i]/p_all$p13[i])
    }
}
p_all=cbind(p_all,pzh21)
p_all=cbind(p_all,pzh22)
p_all=cbind(p_all,pzh23)
p_all=tbl_df(p_all)
rm(pzh21,pzh22,pzh23,i)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("sku_id","pmaxtime1")
names(maxtime2)=c("sku_id","pmaxtime2")
p_all=left_join(p_all, maxtime1, by="sku_id")
p_all=left_join(p_all, maxtime2, by="sku_id")
#最后一次没有购买的标为 tmp_diff
p_all$pmaxtime2[is.na(p_all$pmaxtime2)]=tmp_diff
p_all$pmaxtime1[is.na(p_all$pmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("sku_id","pmintime1")
p_all=left_join(p_all, mintime1, by="sku_id")
#最早一次没有交互的标为前50天到现在的日期
p_all$pmintime1[is.na(p_all$pmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
p_all=mutate(p_all,pmaxmintime=pmintime1-pmaxtime1)
p_all[is.na(p_all)] <- 0


##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(sku_id) %>% distinct(user_id) %>% summarise(p31 = n())
p_all=left_join(p_all, p31, by="sku_id")
p_all[is.na(p_all)] <- 0
##评价
c<- read.csv("JData_Comment.csv",fileEncoding='gbk',header = TRUE)
c=tbl_df(c)
# cp=filter(c,dt == as.Date(d[length(d)-1],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# if(nrow(cp)<2){
#   cp=filter(c,dt == as.Date(d[length(d)-2],format="%Y-%m-%d")) %>% select(sku_id,comment_num,has_bad_comment,bad_comment_rate)
# }
cp=c %>% group_by(sku_id) %>% summarise(comment_num=mean(comment_num),has_bad_comment=mean(has_bad_comment),bad_comment_rate=mean(bad_comment_rate))
p_all=left_join(p_all, cp, by="sku_id")
rm(p31,c,cp)


#品牌特征B
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
brand=unique(p$brand)
brand_all=tbl_df(as.data.frame(brand))
rm(p,brand)
#该品牌过去45天共有多少种商品
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b11=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(sku_id) %>% summarise(b11 = n())
brand_all=left_join(brand_all,b11, by="brand")
##交互人数 前45天有多少人对该物品进行了action
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
p31=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% distinct(user_id) %>% summarise(p31 = n())
names(p31)=c("brand","p31b")
brand_all=left_join(brand_all, p31, by="brand")
brand_all[is.na(brand_all)] <- 0

#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
b21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>%  summarise(b21 = n())
b22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>%  summarise(b22 = n())
b23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>%  summarise(b23 = n())
b24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>%  summarise(b24 = n())
b25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>%  summarise(b25 = n())
b26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>%  summarise(b26 = n())
brand_all=left_join(brand_all, b21, by="brand")
brand_all=left_join(brand_all, b22, by="brand")
brand_all=left_join(brand_all, b23, by="brand")
brand_all=left_join(brand_all, b24, by="brand")
brand_all=left_join(brand_all, b25, by="brand")
brand_all=left_join(brand_all, b26, by="brand")
brand_all=mutate(brand_all,brd=0.005*b21+0.05*b22+0.3*b23+1*b24+0.1*b25+0.003*b26)
brand_all[is.na(brand_all)] <- 0

rm(b11,b21,b22,b23,b24,b25,b26)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
bjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(brand_all,brand)
tmp=left_join(tmp, jqu21, by="brand")
tmp=left_join(tmp, jqu22, by="brand")
tmp=left_join(tmp, jqu23, by="brand")
tmp=left_join(tmp, jqu24, by="brand")
tmp=left_join(tmp, jqu25, by="brand")
tmp=left_join(tmp, jqu26, by="brand")
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=bjqday(1)
pt2jq=bjqday(2)
pt3jq=bjqday(3)
pt4jq=bjqday(4)
pt5jq=bjqday(5)
pt6jq=bjqday(6)
pt7jq=bjqday(7)
pt15jq=bjqday(15)
brand_all=mutate(brand_all,bt1jq=pt1jq)
brand_all=mutate(brand_all,bt2jq=pt2jq)
brand_all=mutate(brand_all,bt3jq=pt3jq)
brand_all=mutate(brand_all,bt4jq=pt4jq)
brand_all=mutate(brand_all,bt5jq=pt5jq)
brand_all=mutate(brand_all,bt6jq=pt6jq)
brand_all=mutate(brand_all,bt7jq=pt7jq)
brand_all=mutate(brand_all,bt15jq=pt15jq)
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)
##前45天转换率
brand_all[is.na(brand_all)] <- 0
pzh21={}
for(i in 1:length(brand_all$b21)){
  if(brand_all$b21[i]==0){
        pzh21=c(pzh21,0)
    }else{
        pzh21=c(pzh21,brand_all$b24[i]/brand_all$b21[i])
    }
}
pzh22={}
for(i in 1:length(brand_all$b22)){
  if(brand_all$b22[i]==0){
        pzh22=c(pzh22,0)
    }else{
        pzh22=c(pzh22,brand_all$b24[i]/brand_all$b22[i])
    }
}
pzh23={}
for(i in 1:length(brand_all$b23)){
  if(brand_all$b23[i]==0){
        pzh23=c(pzh23,0)
    }else{
        pzh23=c(pzh23,brand_all$b24[i]/brand_all$b23[i])
    }
}
bzh21=pzh21
bzh22=pzh22
bzh23=pzh23
brand_all=cbind(brand_all,bzh21)
brand_all=cbind(brand_all,bzh22)
brand_all=cbind(brand_all,bzh23)
brand_all=tbl_df(brand_all)
brand_all[is.na(brand_all)] <- 0

rm(bzh21,bzh22,bzh23,pzh21,pzh22,pzh23,i)


##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("brand","bmaxtime1")
names(maxtime2)=c("brand","bmaxtime2")
brand_all=left_join(brand_all, maxtime1, by="brand")
brand_all=left_join(brand_all, maxtime2, by="brand")
#最后一次没有购买的标为 tmp_diff
brand_all$bmaxtime2[is.na(brand_all$bmaxtime2)]=tmp_diff
brand_all$bmaxtime1[is.na(brand_all$bmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("brand","bmintime1")
brand_all=left_join(brand_all, mintime1, by="brand")
#最早一次没有交互的标为前50天到现在的日期
brand_all$bmintime1[is.na(brand_all$bmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
brand_all=mutate(brand_all,bmaxmintime=bmintime1-bmaxtime1)
brand_all[is.na(brand_all)] <- 0

##合并特征
p_all=left_join(p_all, brand_all, by="brand")


#用户-商品 交叉特征
#7天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us11=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us11 = n())
us12=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us12 = n())
us13=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us13 = n())
us14=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us14 = n())
us15=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us15 = n())
us16=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us16 = n())
us_all=left_join(us, us11, by=c("user_id","sku_id"))
us_all=left_join(us_all, us12, by=c("user_id","sku_id"))
us_all=left_join(us_all, us13, by=c("user_id","sku_id"))
us_all=left_join(us_all, us14, by=c("user_id","sku_id"))
us_all=left_join(us_all, us15, by=c("user_id","sku_id"))
us_all=left_join(us_all, us16, by=c("user_id","sku_id"))
#加权
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd=0.005*us11+0.05*us12+0.3*us13+1*us14+0.1*us15+0.003*us16)
us_all=mutate(us_all,usrdg=1*us14+0.1*us15)
rm(us11,us12,us13,us14,us15,us16)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>%  summarise(us21 = n())
us22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us22 = n())
us23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us23 = n())
us24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>%  summarise(us24 = n())
us25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>%  summarise(us25 = n())
us26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>%  summarise(us26 = n())
us_all=left_join(us_all, us21, by=c("user_id","sku_id"))
us_all=left_join(us_all, us22, by=c("user_id","sku_id"))
us_all=left_join(us_all, us23, by=c("user_id","sku_id"))
us_all=left_join(us_all, us24, by=c("user_id","sku_id"))
us_all=left_join(us_all, us25, by=c("user_id","sku_id"))
us_all=left_join(us_all, us26, by=c("user_id","sku_id"))
us_all[is.na(us_all)] <- 0
us_all=mutate(us_all,usrd45=0.005*us21+0.05*us22+0.3*us23+1*us24+0.1*us25+0.003*us26)
us_all=mutate(us_all,usrdg45=1*us24+0.1*us25)
rm(us21,us22,us23,us24,us25,us26)
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)

pzh21=log(1+us_all$us24)-log(1+us_all$us21)
pzh22=log(1+us_all$us24)-log(1+us_all$us22)
pzh23=log(1+us_all$us24)-log(1+us_all$us23)
uszh21=pzh21
uszh22=pzh22
uszh23=pzh23
us_all=cbind(us_all,uszh21)
us_all=cbind(us_all,uszh22)
us_all=cbind(us_all,uszh23)
us_all=tbl_df(us_all)
us_all[is.na(us_all)] <- 0
rm(pzh21,pzh22,pzh23,uszh21,uszh22,uszh23)

#前一天的是否加入加入购物车/关注
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
us31=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>%  summarise(us31 = n())
us32=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>%  summarise(us32 = n())
us_all=left_join(us_all, us31, by=c("user_id","sku_id"))
us_all=left_join(us_all, us32, by=c("user_id","sku_id"))
rm(us31,us32)
#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
usjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,sku_id) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,sku_id) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,sku_id) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,sku_id) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,sku_id) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(us_all,user_id,sku_id)
tmp=left_join(tmp, jqu21, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu22, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu23, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu24, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu25, by=c("user_id","sku_id"))
tmp=left_join(tmp, jqu26, by=c("user_id","sku_id"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu26)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=usjqday(1)
pt2jq=usjqday(2)
pt3jq=usjqday(3)
pt4jq=usjqday(4)
pt5jq=usjqday(5)
pt6jq=usjqday(6)
pt7jq=usjqday(7)
pt15jq=usjqday(15)
us_all=mutate(us_all,ust1jq=pt1jq)
us_all=mutate(us_all,ust2jq=pt2jq)
us_all=mutate(us_all,ust3jq=pt3jq)
us_all=mutate(us_all,ust4jq=pt4jq)
us_all=mutate(us_all,ust5jq=pt5jq)
us_all=mutate(us_all,ust6jq=pt6jq)
us_all=mutate(us_all,ust7jq=pt7jq)
us_all=mutate(us_all,ust15jq=pt15jq)
us_all[is.na(us_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,sku_id) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","sku_id","usmaxtime1")
names(maxtime2)=c("user_id","sku_id","usmaxtime2")
us_all=left_join(us_all, maxtime1, by=c("user_id","sku_id"))
us_all=left_join(us_all, maxtime2, by=c("user_id","sku_id"))
us_all$usmaxtime2[is.na(us_all$usmaxtime2)]=tmp_diff
us_all$usmaxtime1[is.na(us_all$usmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","sku_id","usmintime1")
us_all=left_join(us_all, mintime1, by=c("user_id","sku_id"))
#最早一次没有交互的标为前50天到现在的日期
us_all$usmintime1[is.na(us_all$usmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
us_all=mutate(us_all,usmaxmintime=usmintime1-usmaxtime1)
us_all[is.na(us_all)] <- 0

##过去n天的行为天数
#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday845")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday87")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,sku_id) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","sku_id","usxwday83")
us_all=left_join(us_all, u22, by=c("user_id","sku_id"))

rm(u22)
us_all[is.na(us_all)]=0
#最近45n天的行为天数比例 flag
u22=us_all$usxwday845/45
us_all=mutate(us_all,usxwrate8=u22)
rm(u22)



#UB特征
ub=filter(t,time>=start_time,time<time1,cate==8) %>% select(user_id,brand)
ub=unique(ub)
#45天的浏览1、加入购物车2、关注5、下单4、删除购物车3
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
ub21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>%  summarise(ub21 = n())
ub22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>%  summarise(ub22 = n())
ub23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>%  summarise(ub23 = n())
ub24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>%  summarise(ub24 = n())
ub25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>%  summarise(ub25 = n())
ub26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>%  summarise(ub26 = n())
ub_all=left_join(ub, ub21, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub22, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub23, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub24, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub25, by=c("user_id","brand"))
ub_all=left_join(ub_all, ub26, by=c("user_id","brand"))
#权值
ub_all=mutate(ub_all,ubrd=0.005*ub21+0.05*ub22+0.3*ub23+1*ub24+0.1*ub25+0.003*ub26)
ub_all[is.na(ub_all)] <- 0
rm(ub21,ub22,ub23,ub24,ub25,ub26)


#n天的浏览1、加入购物车2、关注5、下单4、删除3所有 加权和 (nday,t,d,time1,u_all)
ubjqday<-function(nday){
tmp_diff=nday
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
jqu21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id,brand) %>% summarise(jqu21 = n()/tmp_diff)
jqu22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id,brand) %>% summarise(jqu22 = n()/tmp_diff)
jqu23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id,brand) %>% summarise(jqu23 = n()/tmp_diff)
jqu24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(jqu24 = n()/tmp_diff)
jqu25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id,brand) %>% summarise(jqu25 = n()/tmp_diff)
jqu26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id,brand) %>% summarise(jqu26 = n()/tmp_diff)
tmp=select(ub_all,user_id,brand)
tmp=left_join(tmp, jqu21, by=c("user_id","brand"))
tmp=left_join(tmp, jqu22, by=c("user_id","brand"))
tmp=left_join(tmp, jqu23, by=c("user_id","brand"))
tmp=left_join(tmp, jqu24, by=c("user_id","brand"))
tmp=left_join(tmp, jqu25, by=c("user_id","brand"))
tmp[is.na(tmp)] <- 0
tmp=mutate(tmp,njq=0.005*jqu21+0.05*jqu22+0.3*jqu23+1*jqu24+0.1*jqu25+0.003*jqu21)
ndayjq=tmp$njq
return(ndayjq)
}
#n=1/2/3/4/5/6/7/15
pt1jq=ubjqday(1)
pt2jq=ubjqday(2)
pt3jq=ubjqday(3)
pt4jq=ubjqday(4)
pt5jq=ubjqday(5)
pt6jq=ubjqday(6)
pt7jq=ubjqday(7)
pt15jq=ubjqday(15)
ub_all=mutate(ub_all,ubt1jq=pt1jq)
ub_all=mutate(ub_all,ubt2jq=pt2jq)
ub_all=mutate(ub_all,ubt3jq=pt3jq)
ub_all=mutate(ub_all,ubt4jq=pt4jq)
ub_all=mutate(ub_all,ubt5jq=pt5jq)
ub_all=mutate(ub_all,ubt6jq=pt6jq)
ub_all=mutate(ub_all,ubt7jq=pt7jq)
ub_all=mutate(ub_all,ubt15jq=pt15jq)
ub_all[is.na(ub_all)] <- 0
rm(pt1jq,pt2jq,pt3jq,pt4jq,pt5jq,pt6jq,pt7jq,pt15jq)

##转化率
##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
ub_all[is.na(ub_all)] <- 0
pzh21=log(1+ub_all$ub24)-log(1+ub_all$ub21)
pzh22=log(1+ub_all$ub24)-log(1+ub_all$ub22)
pzh23=log(1+ub_all$ub24)-log(1+ub_all$ub23)
  ubzh21=pzh21
  ubzh22=pzh22
  ubzh23=pzh23
  ub_all=cbind(ub_all,ubzh21)
  ub_all=cbind(ub_all,ubzh22)
  ub_all=cbind(ub_all,ubzh23)
  ub_all=tbl_df(ub_all)
  ub_all[is.na(ub_all)] <- 0
  rm(pzh21,pzh22,pzh23,ubzh21,ubzh22,ubzh23)
##前50天最后一次交互/购买距离预测日(前一天)的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
maxtime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(maxtime1 = max(time))
timediff1=rep(time1,length(maxtime1$maxtime1))
maxtime1$maxtime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime1$maxtime1,"%Y%m%d")),units='day'))
maxtime2=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id,brand) %>% summarise(maxtime2 = max(time))
timediff1=rep(time1,length(maxtime2$maxtime2))
maxtime2$maxtime2=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(maxtime2$maxtime2,"%Y%m%d")),units='day'))
names(maxtime1)=c("user_id","brand","ubmaxtime1")
names(maxtime2)=c("user_id","brand","ubmaxtime2")
ub_all=left_join(ub_all, maxtime1, by=c("user_id","brand"))
ub_all=left_join(ub_all, maxtime2, by=c("user_id","brand"))
ub_all$ubmaxtime2[is.na(ub_all$ubmaxtime2)]=tmp_diff
ub_all$ubmaxtime1[is.na(ub_all$ubmaxtime1)]=tmp_diff
rm(maxtime1,maxtime2,timediff1)

##前50天最早一次交互的时间间隔
tmp_diff=50
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
mintime1=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% summarise(mintime1 = min(time))
timediff1=rep(time1,length(mintime1$mintime1))
mintime1$mintime1=as.integer(difftime((strptime(timediff1,"%Y%m%d")),(strptime(mintime1$mintime1,"%Y%m%d")),units='day'))
names(mintime1)=c("user_id","brand","ubmintime1")
ub_all=left_join(ub_all, mintime1, by=c("user_id","brand"))
#最早一次没有交互的标为前50天到现在的日期
ub_all$ubmintime1[is.na(ub_all$ubmintime1)]=tmp_diff
rm(mintime1,timediff1)
##最早与最晚交互的时间差
ub_all=mutate(ub_all,ubmaxmintime=ubmintime1-ubmaxtime1)
ub_all[is.na(ub_all)] <- 0

#最近45n天的行为天数 flag
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday845")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday87")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

tmp_diff=3
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id,brand) %>% distinct(time) %>% summarise(u22 = n())
names(u22)=c("user_id","brand","ubxwday83")
ub_all=left_join(ub_all, u22, by=c("user_id","brand"))

rm(u22)
ub_all[is.na(ub_all)]=0
#最近45n天的行为天数比例 flag
u22=ub_all$ubxwday845/45
ub_all=mutate(ub_all,ubxwrate8=u22)
rm(u22)



#合并特征集合
feature_all=left_join(us_all, u_all, by="user_id")
feature_all=left_join(feature_all, p_all, by="sku_id")
# feature_all[is.na(feature_all)] <- 0
feature_all=left_join(feature_all, ub_all, by=c("user_id","brand"))
# feature_all[is.na(feature_all)] <- 0
#去掉最近7天已经购买过的样本
feature_all=filter(feature_all,us14==0)

#特征label
# d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
# end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
# mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id,sku_id)
# mai_us=unique(mai_us)
# mai_us=mutate(mai_us,label=1)
# #拼接label
# feature_all=left_join(feature_all,mai_us,by=c("user_id","sku_id"))
# feature_all[which(is.na(feature_all$label)),]$label=0
# #查看比例
# table(feature_all$label)


#输出
# write.table (feature_all, file ="train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (feature_all, file ="val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

write.table (feature_all, file ="test.csv",sep =",",row.names = F,col.names=TRUE,quote =F)




