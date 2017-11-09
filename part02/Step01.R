##测试集合
# 测试集   2.14-4.01   4.06-4.10
# 验证集   2.21-4.8    4.11-4.15
# 预测集   3.1-4.15    4.16-4.20
# 预测用户的模型
options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/")
require(data.table)
library(sqldf)
library(dplyr)
t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)

# setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/")


time_end="2016/4/06"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
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
rm(us,usx2,usx3,user_id)

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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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

# ##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
pzh21=log(1+u_all$u24c)-log(1+u_all$u21c)
pzh22=log(1+u_all$u24c)-log(1+u_all$u22c)
pzh23=log(1+u_all$u24c)-log(1+u_all$u23c)
pzh26=log(1+u_all$u24c)-log(1+u_all$u26c)
uzh821=pzh21
uzh822=pzh22
uzh823=pzh23
uzh826=pzh26
u_all=cbind(u_all,uzh821)
u_all=cbind(u_all,uzh822)
u_all=cbind(u_all,uzh823)
u_all=cbind(u_all,uzh826)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0
rm(pzh21,pzh22,pzh23,uzh821,uzh822,uzh823,uzh826)

#加入购物车但没买
ublzh1=log(1+u_all$u22c-u_all$u24c)-log(1+u_all$u22c)
#加入又删除的比例
ublzh2=log(1+u_all$u25c)-log(1+u_all$u22c)
u_all=cbind(u_all,ublzh1)
u_all=cbind(u_all,ublzh2)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0

# rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
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
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday1")
names(u22)=c("user_id","xwday81")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
#最近7天的行为天数比例 flag
u21=u_all$xwday7/7
u22=u_all$xwday87/7
u_all=mutate(u_all,uxwrate7=u21)
u_all=mutate(u_all,uxwrate87=u22)
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

t_1=semi_join(t, u_all, by="user_id") # 数据集a中能与数据集b匹配的记录
#过去45天当天看了又买的次数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1| type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
u_all=left_join(u_all, lm14, by="user_id")
##cate==8
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1,cate==8)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1|type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
names(lm14)=c("user_id","lm814")
u_all=left_join(u_all, lm14, by="user_id")
u_all[is.na(u_all)]=0
rm(ll1,ll4,ll14,lm14)
u_all[is.na(u_all)]=0
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","msk1")
names(u22)=c("user_id","mb1")
names(u23)=c("user_id","msk2")
names(u24)=c("user_id","mb2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)
u_all[is.na(u_all)]=0
u_all=mutate(u_all,msrate1=u_all$msk1/u_all$sk1)
u_all=mutate(u_all,msrate2=u_all$msk2/u_all$sk2)
u_all=mutate(u_all,mbrate1=u_all$mb1/u_all$b1)
u_all=mutate(u_all,mbrate2=u_all$mb2/u_all$b2)

#特征label
d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id)
mai_us=unique(mai_us)
mai_us=mutate(mai_us,label=1)
#拼接label
u_all=left_join(u_all,mai_us,by=c("user_id"))
u_all[which(is.na(u_all$label)),]$label=0
#查看比例
table(u_all$label)

#输出
write.table (u_all, file ="user_train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (u_all, file ="user_val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (u_all, file ="user_test.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

rm(mai_us,u_all,d,d2,end_time,start_time,time_end,time1,tmp_diff)


t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)

time_end="2016/4/11"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
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
rm(us,usx2,usx3,user_id)

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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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

# ##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
pzh21=log(1+u_all$u24c)-log(1+u_all$u21c)
pzh22=log(1+u_all$u24c)-log(1+u_all$u22c)
pzh23=log(1+u_all$u24c)-log(1+u_all$u23c)
pzh26=log(1+u_all$u24c)-log(1+u_all$u26c)
uzh821=pzh21
uzh822=pzh22
uzh823=pzh23
uzh826=pzh26
u_all=cbind(u_all,uzh821)
u_all=cbind(u_all,uzh822)
u_all=cbind(u_all,uzh823)
u_all=cbind(u_all,uzh826)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0
rm(pzh21,pzh22,pzh23,uzh821,uzh822,uzh823,uzh826)

#加入购物车但没买
ublzh1=log(1+u_all$u22c-u_all$u24c)-log(1+u_all$u22c)
#加入又删除的比例
ublzh2=log(1+u_all$u25c)-log(1+u_all$u22c)
u_all=cbind(u_all,ublzh1)
u_all=cbind(u_all,ublzh2)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0

# rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
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
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday1")
names(u22)=c("user_id","xwday81")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
#最近7天的行为天数比例 flag
u21=u_all$xwday7/7
u22=u_all$xwday87/7
u_all=mutate(u_all,uxwrate7=u21)
u_all=mutate(u_all,uxwrate87=u22)
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

t_1=semi_join(t, u_all, by="user_id") # 数据集a中能与数据集b匹配的记录
#过去45天当天看了又买的次数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1| type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
u_all=left_join(u_all, lm14, by="user_id")
##cate==8
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1,cate==8)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1|type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
names(lm14)=c("user_id","lm814")
u_all=left_join(u_all, lm14, by="user_id")
u_all[is.na(u_all)]=0
rm(ll1,ll4,ll14,lm14)
u_all[is.na(u_all)]=0
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","msk1")
names(u22)=c("user_id","mb1")
names(u23)=c("user_id","msk2")
names(u24)=c("user_id","mb2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)
u_all[is.na(u_all)]=0
u_all=mutate(u_all,msrate1=u_all$msk1/u_all$sk1)
u_all=mutate(u_all,msrate2=u_all$msk2/u_all$sk2)
u_all=mutate(u_all,mbrate1=u_all$mb1/u_all$b1)
u_all=mutate(u_all,mbrate2=u_all$mb2/u_all$b2)

#特征label
d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id)
mai_us=unique(mai_us)
mai_us=mutate(mai_us,label=1)
#拼接label
u_all=left_join(u_all,mai_us,by=c("user_id"))
u_all[which(is.na(u_all$label)),]$label=0
#查看比例
table(u_all$label)

#输出
# write.table (u_all, file ="user_train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

write.table (u_all, file ="user_val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)



t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)

time_end="2016/4/16"
time1=as.integer(format(as.Date(time_end,format="%Y/%m/%d"),"%Y%m%d"))
d=seq(as.Date("2016/2/1"),as.Date(time_end), by="day")
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
rm(us,usx2,usx3,user_id)

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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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
u21=filter(t,time>=start_time,time<time1,cate==8,type==1) %>% group_by(user_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8,type==2) %>% group_by(user_id) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==5) %>% group_by(user_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% summarise(u24 = n())
u25=filter(t,time>=start_time,time<time1,cate==8,type==3) %>% group_by(user_id) %>% summarise(u25 = n())
u26=filter(t,time>=start_time,time<time1,cate==8,type==6) %>% group_by(user_id) %>% summarise(u26 = n())
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

# ##前45天转换率 ln(x/y)=ln(1+x)-ln(1+y)=ln(1+x/1+y)
pzh21=log(1+u_all$u24c)-log(1+u_all$u21c)
pzh22=log(1+u_all$u24c)-log(1+u_all$u22c)
pzh23=log(1+u_all$u24c)-log(1+u_all$u23c)
pzh26=log(1+u_all$u24c)-log(1+u_all$u26c)
uzh821=pzh21
uzh822=pzh22
uzh823=pzh23
uzh826=pzh26
u_all=cbind(u_all,uzh821)
u_all=cbind(u_all,uzh822)
u_all=cbind(u_all,uzh823)
u_all=cbind(u_all,uzh826)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0
rm(pzh21,pzh22,pzh23,uzh821,uzh822,uzh823,uzh826)

#加入购物车但没买
ublzh1=log(1+u_all$u22c-u_all$u24c)-log(1+u_all$u22c)
#加入又删除的比例
ublzh2=log(1+u_all$u25c)-log(1+u_all$u22c)
u_all=cbind(u_all,ublzh1)
u_all=cbind(u_all,ublzh2)
u_all=tbl_df(u_all)
u_all[is.na(u_all)] <- 0

# rm(uzh31,uzh32,uzh33,uzh34)
##最近7天的活跃度
tmp_diff=7
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
all=filter(t,time>=start_time,time<time1)  %>% summarise(n())
u41=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% summarise(u41 = n())
len=length(u41$u41)
all=as.integer(all)/len
u41$u41=u41$u41/as.integer(rep(all,length(u41$u41)))
##最近45天的活跃度
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
tmp_diff=1
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1) %>% group_by(user_id) %>% distinct(time) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,cate==8) %>% group_by(user_id) %>% distinct(time) %>% summarise(u22 = n())
names(u21)=c("user_id","xwday1")
names(u22)=c("user_id","xwday81")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
rm(u21,u22)
u_all[is.na(u_all)]=0
#最近45n天的行为天数比例 flag
u21=u_all$xwday45/45
u22=u_all$xwday845/45
u_all=mutate(u_all,uxwrate=u21)
u_all=mutate(u_all,uxwrate8=u22)
#最近7天的行为天数比例 flag
u21=u_all$xwday7/7
u22=u_all$xwday87/7
u_all=mutate(u_all,uxwrate7=u21)
u_all=mutate(u_all,uxwrate87=u22)
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

t_1=semi_join(t, u_all, by="user_id") # 数据集a中能与数据集b匹配的记录
#过去45天当天看了又买的次数
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1| type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
u_all=left_join(u_all, lm14, by="user_id")
##cate==8
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
tmp=filter(t_1,time>=start_time,time<time1,cate==8)
ll1=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==1|type==6) %>% summarise(ll1=n())
ll4=tmp %>% group_by(user_id,sku_id,time) %>% filter(type==4) %>% summarise(ll4=n())
ll14=left_join(ll1,ll4,by=c("user_id","sku_id","time"))
ll14[is.na(ll14)]=0
lm14=filter(ll14,ll1>0,ll4>0) %>% group_by(user_id) %>% summarise(lm14=n())
names(lm14)=c("user_id","lm814")
u_all=left_join(u_all, lm14, by="user_id")
u_all[is.na(u_all)]=0
rm(ll1,ll4,ll14,lm14)
u_all[is.na(u_all)]=0
tmp_diff=45
start_time=as.integer(format(as.Date(d[length(d)-tmp_diff],format="%Y-%m-%d"),"%Y%m%d"))
u21=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u21 = n())
u22=filter(t,time>=start_time,time<time1,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u22 = n())
u23=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(sku_id) %>% summarise(u23 = n())
u24=filter(t,time>=start_time,time<time1,cate==8,type==4) %>% group_by(user_id) %>% distinct(brand) %>% summarise(u24 = n())
names(u21)=c("user_id","msk1")
names(u22)=c("user_id","mb1")
names(u23)=c("user_id","msk2")
names(u24)=c("user_id","mb2")
u_all=left_join(u_all, u21, by="user_id")
u_all=left_join(u_all, u22, by="user_id")
u_all=left_join(u_all, u23, by="user_id")
u_all=left_join(u_all, u24, by="user_id")
rm(u21,u22,u23,u24)
u_all[is.na(u_all)]=0
u_all=mutate(u_all,msrate1=u_all$msk1/u_all$sk1)
u_all=mutate(u_all,msrate2=u_all$msk2/u_all$sk2)
u_all=mutate(u_all,mbrate1=u_all$mb1/u_all$b1)
u_all=mutate(u_all,mbrate2=u_all$mb2/u_all$b2)

#特征label
# d2=seq(as.Date(time_end),as.Date("2016/4/30"), by="day")
# end_time=as.integer(format(as.Date(d2[5],format="%Y-%m-%d"),"%Y%m%d"))
# mai_us=filter(t,time>=time1,time<=end_time,cate==8,type==4) %>% select(user_id)
# mai_us=unique(mai_us)
# mai_us=mutate(mai_us,label=1)
# #拼接label
# u_all=left_join(u_all,mai_us,by=c("user_id"))
# u_all[which(is.na(u_all$label)),]$label=0
# #查看比例
# table(u_all$label)

#输出
# write.table (u_all, file ="user_train.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# write.table (u_all, file ="user_val.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

write.table (u_all, file ="user_test.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

