# 文件新格式生成
options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part02/")
require(data.table)
library(sqldf)
library(dplyr)

d1<- fread("02/part-00000",header = FALSE)
d2<- fread("03/part-00000",header = FALSE)
d3<- fread("04/part-00000",header = FALSE)
d=rbind(d1,d2,d3)
names(d)=c("user_id","sku_id","time","model_id","type","cate","brand","h","week","xx")
d=tbl_df(d)
action_out=d %>% select(user_id,sku_id,time,model_id,type,cate,brand,h,week)
write.table (action_out, file ="Action_all.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

Action=tbl_df(action_out)
names(Action)=c("user_id","sku_id","year","model_id","type","cate","brand","h","week")
Action$year=as.numeric(Action$year)
action_out=Action %>% filter(year<20160406,cate==8) %>% select(user_id,year)
write.table(action_out,"action_train.csv", col.names = F,row.names = F,quote = F,sep = ",")
action_out=Action %>% filter(year<20160411,cate==8) %>% select(user_id,year)
write.table(action_out,"action_val.csv", col.names = F,row.names = F,quote = F,sep = ",")
action_out=Action %>% filter(year<20160416,cate==8) %>% select(user_id,year)
write.table(action_out,"action_test.csv", col.names = F,row.names = F,quote = F,sep = ",")


u<- read.csv("JData_User.csv",fileEncoding='gbk',header = TRUE)
names(u)=c("user_id","age","sex","user_lv_cd","user_reg_dt")
user_reg_dt=format(as.Date(u$user_reg_dt,format="%Y-%m-%d"),"%Y/%m/%d")
u$user_reg_dt=user_reg_dt
write.table (u, file ="JData_User.csv",fileEncoding='gbk',sep =",",row.names = F,col.names=TRUE,quote =F)

p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
names(p)=c("sku_id","attr1","attr2","attr3","cate","brand")

write.table (p, file ="JData_Product.csv",fileEncoding='gbk',sep =",",row.names = F,col.names=TRUE,quote =F)

rm(list=ls())
d1<- fread("02/part-00000",header = FALSE)
d2<- fread("03/part-00000",header = FALSE)
d3<- fread("04/part-00000",header = FALSE)
d=rbind(d1,d2,d3)
action_out=d
write.table(action_out,"Action_all2.csv", col.names = F,row.names = F,quote = F,sep = ",")


########################
rm(list=ls());gc()
library(stringr)
Action02=fread("JData_Action_201602.csv",header=TRUE)
Action03=fread("JData_Action_201603.csv",header=TRUE)
Action04=fread("JData_Action_201604.csv",header=TRUE)
Action=rbind(Action02,Action03,Action04)
# rm(Action02,Action03,Action04)
# names(Action)=c("user_id","sku_id","year","model_id","type","cate","brand","h","week")
# Action1 <- read.csv("JData_Action_201602.csv",header = T,fileEncoding = 'GBK')
# Action2 <- read.csv("JData_Action_201603.csv",header = T,fileEncoding = 'GBK')
# Action3 <- read.csv("JData_Action_201604.csv",header = T,fileEncoding = 'GBK')
# Action <- rbind(Action1,Action2,Action3)
#修改Action
year <- substr(Action$time,1,10)
year <- str_replace_all(year,"-","")
Action <- cbind(Action,year)
#停留时间特征
fun1 <- function(x){
  max(x) - min(x)
}
fun2 <- function(x){
  l <- length(x)
  x <- x[order(x)]
  x1 <- c(x[2:l],x[l])
  cbind(x,x1-x)
}
grouped <- Action %>% group_indices(user_id,sku_id,year)
Action <- cbind(Action,grouped)
Action <- mutate(Action,difftime = difftime(strptime(Action$time, "%Y-%m-%d %H:%M:%S"),strptime("2016-01-01 00:00:00","%Y-%m-%d %H:%M:%S"),units='secs') )
Action$difftime <- str_replace_all(Action$difftime,"secs","")
Action$difftime <- as.numeric(Action$difftime)
Action$grouped <- as.factor(Action$grouped)
c <-tapply(Action$difftime,Action$grouped, fun1)
c <- as.data.frame(c)
c <- cbind(c,1:length(c$c))
names(c)[2] <- c("grouped")
diffAction <- Action %>% select(user_id,sku_id,year,grouped) %>% distinct()
diffAction <- sqldf("select a.*,c from diffAction a left join c on a.grouped = c.grouped")
diffAction$c[which(diffAction$c==0)] <- 1
diffAction=select(diffAction,-grouped)

write.table(diffAction,"停留时间特征2.csv", col.names = F,row.names = F,quote = F,sep = ",")


temp1 <- Action %>% group_by(brand,type) %>% summarise(count = n())
temp2 <- sqldf("select brand, sum(case when type = '1'  then count else 0 end) bc1,
               sum(case when type = '2'  then count else 0 end) bc2,
               sum(case when type = '3'  then count else 0 end) bc3,
               sum(case when type = '4'  then count else 0 end) bc4,
               sum(case when type = '5'  then count else 0 end) bc5,
               sum(case when type = '6'  then count else 0 end) bc6,
               sum(count) sum from temp1 group by brand")
wsum <- temp2$bc1*0.05+temp2$bc2*0.25+temp2$bc3*0.05+temp2$bc4*0.45+temp2$bc5*0.15+temp2$bc6*0.05
temp2 <- cbind(temp2,wsum)
temp2 <- temp2 %>% arrange(desc(wsum))
top20brandid <- temp2$brand[1:20]


Action$grouped  <-  NULL
Action$difftime <- NULL
temp1 <- Action %>% group_by(user_id,brand,type,year) %>% summarise(count = n())
temp2 <- sqldf("select user_id,brand,year, sum(case when type = '1'  then count else 0 end) bc1,
               sum(case when type = '2'  then count else 0 end) bc2,
               sum(case when type = '3'  then count else 0 end) bc3,
               sum(case when type = '4'  then count else 0 end) bc4,
               sum(case when type = '5'  then count else 0 end) bc5,
               sum(case when type = '6'  then count else 0 end) bc6,
               sum(count) sum from temp1 group by user_id,brand,year")
wsum <- temp2$bc1*0.05+temp2$bc2*0.25+temp2$bc3*0.05+temp2$bc4*0.45+temp2$bc5*0.15+temp2$bc6*0.05
temp2 <- cbind(temp2,wsum)
temp2 <- temp2 %>% select(user_id,brand,year,wsum)
temp3 <- sqldf("select user_id,year,
               sum(case when brand = '214' then wsum else 0.0 end) as b214,
               sum(case when brand = '489' then wsum else 0.0 end) as b489,
               sum(case when brand = '306' then wsum else 0.0 end) as b306,
               sum(case when brand = '545' then wsum else 0.0 end) as b545,
               sum(case when brand = '800' then wsum else 0.0 end) as b800,
               sum(case when brand = '885' then wsum else 0.0 end) as b885,
               sum(case when brand = '78' then wsum else 0.0 end) as b78,
               sum(case when brand = '519' then wsum else 0.0 end) as b519,
               sum(case when brand = '403' then wsum else 0.0 end) as b403,
               sum(case when brand = '658' then wsum else 0.0 end) as b658,
               sum(case when brand = '693' then wsum else 0.0 end) as b693,
               sum(case when brand = '479' then wsum else 0.0 end) as b479,
               sum(case when brand = '200' then wsum else 0.0 end) as b200,
               sum(case when brand = '30' then wsum else 0.0 end) as b30,
               sum(case when brand = '174' then wsum else 0.0 end) as b174,
               sum(case when brand = '159' then wsum else 0.0 end) as b159,
               sum(case when brand = '36' then wsum else 0.0 end) as b36,
               sum(case when brand = '124' then wsum else 0.0 end) as b124,
               sum(case when brand = '640' then wsum else 0.0 end) as b640,
               sum(case when brand = '752' then wsum else 0.0 end) as b752
               from temp2 group by user_id ,year")
write.table(temp3,"用户top20品牌特征.csv", col.names = TRUE,row.names = F,quote = F,sep = ",")
########################


# 停留时间特征
rm(list=ls())
tl=fread("停留时间特征2.csv",header=FALSE)
names(tl)=c("user_id","sku_id","time","tltime")
tl=tbl_df(tl)
p<- read.csv("JData_Product.csv",fileEncoding='gbk',header = TRUE)
p=tbl_df(p)
p=select(p,sku_id,cate,brand)
tl=left_join(tl,p,by="sku_id")
tl=filter(tl,cate==8)
write.table (tl, file ="停留时间特征.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

# 交互间隔天数train
# 交互间隔天数val
# 交互间隔天数test

# 停留时间2
# 连续访问情况2


