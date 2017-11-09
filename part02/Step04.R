options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/")
require(data.table)
library(dplyr)

us=fread("../part01/cate8_f2_800.csv",header = TRUE)
us$sku_id=as.character(us$sku_id)
write.table (us, file ="cate8_800.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
us=fread("../part01/cate8_alluser.csv",header = TRUE)
write.table (us, file ="cate8_alluser.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

us_all=fread("us_test_all.csv",header = FALSE)
names(us_all)=c("user_id","sku_id","pro")
tt=us_all
user_id=unique(tt$user_id)
rr={}
for(i in 1:length(user_id)){
    index=user_id[i]
    x=filter(tt,user_id == index)
    if(length(x$sku_id)>1){
    x=arrange(x, desc(pro))
    rr=rbind(rr,x[1,])
    }else{
    rr=rbind(rr,x[1,])
    }
}
rr=arrange(rr, desc(pro))
us_all=unique(rr)
write.table (us_all, file ="label4_us_all.csv",sep =",",row.names = F,col.names=TRUE,quote =F)


us_all=fread("us_test_all.csv",header = FALSE)
names(us_all)=c("user_id","sku_id","pro")
us_all=us_all[1:2500,]
tt=us_all
user_id=unique(tt$user_id)
rr={}
for(i in 1:length(user_id)){
    index=user_id[i]
    x=filter(tt,user_id == index)
    if(length(x$sku_id)>1){
    x=arrange(x, desc(pro))
    rr=rbind(rr,x[1,])
    }else{
    rr=rbind(rr,x[1,])
    }
}
rr=arrange(rr, desc(pro))
us_all=unique(rr)
write.table (us_all, file ="us_2162.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

us_all=fread("us_test_all.csv",header = FALSE)
names(us_all)=c("user_id","sku_id","pro")
us_all=us_all[1:3500,]
tt=us_all
user_id=unique(tt$user_id)
rr={}
for(i in 1:length(user_id)){
    index=user_id[i]
    x=filter(tt,user_id == index)
    if(length(x$sku_id)>1){
    x=arrange(x, desc(pro))
    rr=rbind(rr,x[1,])
    }else{
    rr=rbind(rr,x[1,])
    }
}
rr=arrange(rr, desc(pro))
us_all=unique(rr)
write.table (us_all, file ="us_2916.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
