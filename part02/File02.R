options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/")
require(data.table)
library(sqldf)
library(dplyr)
# 交互间隔天数train
tmp=read.csv("x1/part-00000",header=FALSE)
write.table (tmp, file ="交互间隔天数train",sep =",",row.names = F,col.names=F,quote =F)
# 交互间隔天数val
tmp=read.csv("x2/part-00000",header=FALSE)
write.table (tmp, file ="交互间隔天数val",sep =",",row.names = F,col.names=F,quote =F)
# 交互间隔天数test
tmp=read.csv("x3/part-00000",header=FALSE)
write.table (tmp, file ="交互间隔天数test",sep =",",row.names = F,col.names=F,quote =F)
# 停留时间2
tmp=read.csv("xx/part-00000",header=FALSE)
write.table (tmp, file ="停留时间2",sep =",",row.names = F,col.names=F,quote =F)

# 连续访问情况2
d3<- read.csv("x4/part-00000",header = FALSE)
names(d3)=c("user_id","type","time","sku_id","num")
write.table (d3, file ="连续访问情况.csv",sep =",",row.names = F,col.names=F,quote =F)
t=fread("Action_all.csv",header = TRUE)
t=tbl_df(t)
scb=select(t,sku_id,cate,brand)
scb=unique(scb)
d<- fread("连续访问情况.csv",header = FALSE)
names(d)=c("user_id","type","time","sku_id","num")
d=left_join(d,scb,by="sku_id")
write.table (d, file ="连续访问情况2.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
