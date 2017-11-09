options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part04")
require(data.table)
library(sqldf)
library(dplyr)
tmp=fread("../part02/us_test_all.csv",header = FALSE)
write.table (tmp, file ="us_test_all.csv",sep =",",row.names = F,col.names=FALSE,quote =F)
tmp=fread("../part02/cate8_alluser.csv",header = TRUE)
write.table (tmp, file ="cate8_alluser.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tmp=fread("../part02/cate8_alluser.csv",header = TRUE)
write.table (tmp, file ="cate8_alluser.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tmp=fread("../part02/label4_us_all.csv",header = TRUE)
write.table (tmp, file ="label4_us_all.csv",sep =",",row.names = F,col.names=TRUE,quote =F)

tmp=fread("../part03/we_all/817_0.19517_F11_0.30407_F12_0.12257.csv",header = TRUE)
write.table (tmp, file ="817_0.19517_F11_0.30407_F12_0.12257.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tmp=fread("../part03/we_all/832user_0.2965.csv",header = TRUE)
write.table (tmp, file ="832user_0.2965.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tmp=fread("../part03/wepon/ensemble/Top2000user.csv",header = TRUE)
write.table (tmp, file ="Top2000user.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
tmp=fread("../part03/wepon/ensemble/wepon174.csv",header = TRUE)
write.table (tmp, file ="wepon174.csv",sep =",",row.names = F,col.names=TRUE,quote =F)


tt=fread("us_test_all.csv",header = FALSE)
tt=tt[1:3500,]
# tt=fread("4d508_top3500.csv",header = FALSE)
names(tt)=c('user_id','sku_id','pro')
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
rr=unique(rr)
tt2=fread("cate8_alluser.csv",header = TRUE)
names(tt2)=c('user_id','pro2')
tt2=tt2[1:1500,]
tt2=arrange(tt2, desc(pro2))
tt3=left_join(tt2,rr,by="user_id")
tt4=tt3[-which(is.na(tt3$pro)),]
tmp=tt4[,c(1,3)]
p790=tmp
# 790 245 131 0.18854(F11:0.28417/F12:0.12479)
tt5=tt3[which(is.na(tt3$pro)),]
tx=filter(tt5,pro2 >2.5) %>% select(user_id)
#tx=mutate(tx,sku_id=0)
#tx=select(tx,user_id)
rr=fread("label4_us_all.csv",header = TRUE)
tx=left_join(tx,rr,by="user_id")
tx=na.omit(tx) #37  37  13
#tx=anti_join(tx,rr,by="user_id")
tx=tx[,c(1,2)]
tmp=tt4[,c(1,3)]
tmp=rbind(tmp,tx)
# 827 258 131 0.1894(F11:0.28891/F12:0.12305)

tmp=p790
tt=fread("us_test_all.csv",header = FALSE)
tt=tt[1:3500,]
names(tt)=c('user_id','sku_id','pro')
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
rr=unique(rr)
rr=anti_join(rr,tmp,by="user_id")
tmp2=rr
tmp2=arrange(tmp2,desc(pro))
tmp3=tmp2[1:20,c(1,2)]   #40 8 8  20 6 6s
tmp=rbind(tmp,tmp3)
p512_810=tmp
# 0.19195

tmp=p512_810
tmp2=fread("wepon174.csv",header=TRUE)
tmp3=fread("Top2000user.csv",header=TRUE)
tmp=left_join(tmp,tmp3,by="user_id")
tmx=na.omit(tmp)
quantile(tmx$label)
tmp4=anti_join(tmp2,tmp,by="user_id")
tmp4=arrange(tmp4,desc(label))
tmp4=tmp4[1:18,c(1,2)]
tmp=tmp[,c(1,2)]
tmp=rbind(tmp,tmp4)
# 828 256 139 0.19287(F11:0.28641/F12:0.13052)
p828=tmp



d1=p828
d2=fread("832user_0.2965.csv",header=TRUE) #266
d=semi_join(d1,d2,by="user_id") #614
d3=anti_join(d1,d2,by="user_id") #214  39  24 0.1928sheng 59 12 12
d4=anti_join(d2,d1,by="user_id") #218  46  9  wepon
us=fread("label4_us_all.csv",header=TRUE)
d2=left_join(d2,us,by="user_id")
x=na.omit(d2)
tmp=x[,c(1,2)]

d3=left_join(d3,us,by="user_id")
d3=na.omit(d3)#214
d3=arrange(d3,desc(pro))
tmp=d3[1:59,]  #59 12 12
tmp=tmp[,c(1,2)]
names(tmp)=c("user_id","sku_id")
tmp=rbind(tmp,d)
p512_673=tmp
tmp=p512_673 # 673 229 127
dd=fread("817_0.19517_F11_0.30407_F12_0.12257.csv",header=TRUE) #269 130
xx=anti_join(tmp,dd,by="user_id") ##56 10 10
xx1=anti_join(dd,tmp,by="user_id") ##200--52  15
dd=rbind(dd,xx)
# 873 279 140 0.19739(F11:0.29957/F12:0.12927)
# write.table (dd, file ="out/512_873.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
# d1=fread("out/512_873.csv",header=TRUE)
# d2=fread("out/430_7.csv",header=TRUE)
# d=rbind(d1,d2)
# d=unique(d)
p512_873=dd

# d1=p512_873
# d2=fread("430_7.csv",header=TRUE)
# d=rbind(d1,d2)
# d=unique(d)
write.table (p512_873, file ="513_879_0.2024.csv",sep =",",row.names = F,col.names=TRUE,quote =F)



dd=fread("525topA.csv",header=TRUE)
setdiff(a,dd)
