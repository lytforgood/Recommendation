rm(list=ls());gc()
setwd("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/part04")
#载入包
library(sqldf)
library(recharts)
library(xgboost)
library(dplyr)
library(ROCR)
library(stringr)

Action1 <- read.csv("../part02/JData_Action_201602.csv",header = T,fileEncoding = 'GBK')
Action2 <- read.csv("../part02/JData_Action_201603.csv",header = T,fileEncoding = 'GBK')
Action3 <- read.csv("../part02/JData_Action_201604.csv",header = T,fileEncoding = 'GBK')
Action <- rbind(Action1,Action2,Action3)
year <- substr(Action$time,1,10)
year <- str_replace_all(year,"-","")
Action <- cbind(Action,year)

#得到894答案
Action$time <- as.character(Action$time)
t1 <- Action %>% filter(time >= '2016-04-15 21:00:00',time <= '2016-04-15 23:59:59') %>% select(user_id,sku_id) %>% distinct()
#此处读入雨亭
c <- read.csv("../part02/us_2162.csv")
t2 <- left_join(t1,c,by = c("user_id", "sku_id"))
t2 <- na.omit(t2)
t2 <- t2 %>% arrange(desc(pro))
#此处读入879答案
zuiyou <- read.csv("513_879_0.2024.csv")
#加入七个
yuting <- read.csv("../part02/label4_us_all.csv")
yutingfeature  <- read.csv("../part02/user_test.csv")
yuting4 <- yuting %>% left_join(yutingfeature,by="user_id")

delete7 <- sqldf("select user_id ,sku_id from yuting4  where u21 = 148 and ujq = 2.586 and t1jq =  0.058 and agelabel = 5 and sex = 0 and user_lv_cd = 4 and utl2 = 129
                  union select user_id ,sku_id from yuting4  where u21 = 100 and ujq = 3.357 and t1jq =  0.064 and agelabel = 4 and sex = 2 and user_lv_cd = 4 and utl2 = 15375
                  union select user_id ,sku_id from yuting4  where u21 = 17 and ujq = 0.916 and t1jq =  0.011 and agelabel = 1 and sex = 2 and user_lv_cd = 3 and utl2 = 1453
                  union select user_id ,sku_id from yuting4  where u21 = 230 and ujq = 3.68 and t1jq =  0 and agelabel = 3 and sex = 1 and user_lv_cd = 3 and utl2 = 269
                  union select user_id ,sku_id from yuting4  where u21 = 91 and ujq = 1.132 and t1jq =  0.35 and agelabel = 5 and sex = 0 and user_lv_cd = 5 and utl2 = 109847
                  union select user_id ,sku_id from yuting4  where u21 = 308 and ujq = 4.002 and t1jq =  0.034 and agelabel = 4 and sex = 2 and user_lv_cd = 4 and utl2 = 102888
                  union select user_id ,sku_id from yuting4  where u21 = 156 and ujq = 2.719 and t1jq =  0 and agelabel = 4 and sex = 2 and user_lv_cd = 4 and utl2 =  0
")
zuiyou <- rbind(zuiyou,delete7)



t3 <- select(t2,user_id,sku_id)
t3 <- setdiff(t3,zuiyou)
t3 <- left_join(t3,t2,by=c("user_id","sku_id"))
t3 <- arrange(t3,desc(pro))
zuiyou2 <- rbind(zuiyou,t3[1:10,1:2])

t4 <- select(c,user_id,sku_id)
t4 <- setdiff(t4,zuiyou2)
t4 <- left_join(t4,c,by=c("user_id","sku_id"))
t4 <- arrange(t4,desc(pro))
zuiyou2 <- rbind(zuiyou2,t4[1:5,1:2])

require(data.table)
library(dplyr)
JData_Action_201602=fread("../part02/JData_Action_201602.csv",header = TRUE)
JData_Action_201603=fread("../part02/JData_Action_201603.csv",header = TRUE)
JData_Action_201604=fread("../part02/JData_Action_201604.csv",header = TRUE)
JData_Action <- rbind(JData_Action_201602,JData_Action_201603,JData_Action_201604)
remove(JData_Action_201602,JData_Action_201603,JData_Action_201604)
JData_Action <- tbl_df(JData_Action)



# best上诉产生的答案
# t 三个JData_Action源文件的合并
md <- function(best,t){
  library(stringr)
  year <- substr(t$time,1,10)
  year <- str_replace_all(year,"-","")
  t$time <- as.integer(year)

  print("开始。。。")

  get_sku_id <- function(t,user){
    new <- {}
    for(i in 1:length(user)){
      te <- t %>% filter(user_id==user[i],cate==8,type ==2) %>% select(user_id,sku_id)
      new <- rbind(new,te[length(te$user_id),])
    }
    return(new)
  }
  getContinuityDayUser <- function(t,N,start_time,end_time){
    userOnlineNum <- filter(t)%>%group_by(user_id,time)%>%summarise(n())%>%group_by(user_id)%>%summarise(num_day=n())
    Online_N <- userOnlineNum[which(userOnlineNum$num_day==N),1]
    Online_N <- left_join(Online_N,t,by=c("user_id"))
    user <- filter(Online_N)%>%group_by(user_id,time)%>%summarise()
    user_time <- user$time
    dim(user_time) <- c(N,length(user_time)/N)
    user_user_id <- user$user_id
    dim(user_user_id) <- c(N,length(user_user_id)/N)
    action_time <- data.frame(start=user_time[N,],end=user_time[1,],user_id=user_user_id[1,])
    action_time <- tbl_df(action_time)
    user <- filter(action_time,start==start_time&end==end_time)
    return(user$user_id)
  }
  delete_ruleContinuityDay <- function(t,N,day){
    trian <- filter(t,time>=as.integer(format(as.Date(as.character(day),format="%Y%m%d")-31,"%Y%m%d")),time<=day)
    CDU <- getContinuityDayUser(trian,N,day,as.integer(format(as.Date(as.character(day),format="%Y%m%d")-N+1,"%Y%m%d")))
    return(CDU)
  }
  rule_oneday <- function(t,N,day){
    trian <- filter(t,time>=as.integer(format(as.Date(as.character(day),format="%Y%m%d")-31,"%Y%m%d")),time<=day)

    CDU <- getContinuityDayUser(trian,N,day,as.integer(format(as.Date(as.character(day),format="%Y%m%d")-N+1,"%Y%m%d")))

    cate <- filter(trian,cate==1|cate==2|cate==3|cate==4|cate==5|cate==6|cate==7)%>%select(user_id)%>%distinct()
    CDU <- setdiff(CDU,cate$user_id)
    user_type4 <- filter(t,type==4,cate==8)%>%select(user_id)%>%distinct()
    CDU <- setdiff(CDU,user_type4$user_id)

    user2 <- filter(trian,cate==8,type==2)%>%select(user_id)%>%distinct()
    CDU <- intersect(CDU,user2$user_id)

    user3 <- filter(trian,type==3)%>%select(user_id)%>%distinct()
    CDU <- setdiff(CDU,user3$user_id)

    user_x3 <- trian%>%group_by(user_id)%>%summarise(count=n())%>%filter(count<3|count>80)%>%select(user_id)
    CDU <- setdiff(CDU,user_x3$user_id)

    user2_count <- filter(trian,type==2)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count>2)%>%select(user_id)
    CDU <- setdiff(CDU,user2_count$user_id)

    return(CDU)
  }

  day <- 20160415

  D <- filter(t,time>day-31,time<day)%>%group_by(user_id)%>%distinct()
  C <- filter(t,time==day)%>%group_by(user_id)%>%distinct()
  user <- setdiff(C$user_id,D$user_id)
  user <- data.frame(user_id=user)
  t2 <- left_join(user,t,by="user_id")
  user2 <- filter(t2,time==day)%>%group_by(user_id,sku_id)%>%summarise(count_sku=n())%>%
    filter(count_sku==1)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==4)
  t3 <- left_join(user2,t,by="user_id")
  user3 <- filter(t3,cate==8)%>%group_by(user_id,sku_id)%>%summarise(count_sku=n())%>%
    filter(count_sku==1)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==2)
  t4 <- left_join(user3,t,by="user_id")
  user4 <- filter(t4,cate==5)
  add_user <- setdiff(user4$user_id,best$user_id)
  best <- rbind(best,get_sku_id(t,add_user))

  D <- filter(t,time>day-31,time<day)%>%group_by(user_id)%>%distinct()
  C <- filter(t,time==day)%>%group_by(user_id)%>%distinct()
  user <- setdiff(C$user_id,D$user_id)
  user <- data.frame(user_id=user)
  t2 <- left_join(user,t,by="user_id")
  user2 <- filter(t2,time==day,cate==8)%>%group_by(user_id,sku_id)%>%summarise(count_sku=n())%>%
    filter(count_sku==4)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==1)%>%select(user_id)
  t3 <- left_join(user2,t,by="user_id")
  user3 <- filter(t3,cate==4)%>%group_by(user_id,sku_id)%>%summarise(count_sku=n())%>%
    filter(count_sku==2)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==2)%>%select(user_id)
  t4 <- left_join(user3,t,by="user_id")
  user4 <- filter(t4,cate==10)%>%select(user_id)%>%distinct()
  add_user <- setdiff(user4$user_id,best$user_id)
  best <- rbind(best,get_sku_id(t,add_user))

  add_CDU15 <- rule_oneday(t,1,day)
  add_CDU15 <- setdiff(add_CDU15,best$user_id)
  best <- rbind(best,get_sku_id(t,add_CDU15))

  delete_CDU4 <- delete_ruleContinuityDay(t,4,day)
  delete_CDU4 <- intersect(delete_CDU4,best$user_id)
  for(i in 1:length(delete_CDU4)){
    best <- best[-which(best$user_id==delete_CDU4[i]),]
  }
  print(1)
  delete_CDU5 <- delete_ruleContinuityDay(t,5,day)
  delete_CDU5 <- intersect(delete_CDU5,best$user_id)
  for(i in 1:length(delete_CDU5)){
    best <- best[-which(best$user_id==delete_CDU5[i]),]
  }
  print(2)
  D <- filter(t,time>(day-5))%>%group_by(user_id)%>%distinct()
  C <- filter(t,time==(day-5))%>%group_by(user_id)%>%distinct()
  user <- C$user_id
  user <- setdiff(user,D$user_id)
  user <- data.frame(user_id=user)
  user <- left_join(user,t,by="user_id")
  user2 <- filter(user,type==2,time==(day-5))%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==1)%>%select(user_id)
  user3 <- filter(user,type==3,time==(day-5))%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==1)%>%select(user_id)
  user_id23 <- user2$user_id
  user_id23 <- intersect(user_id23,user3$user_id)
  user_id23 <- intersect(user_id23,best$user_id)
  for(i in 1:length(user_id23)){
    best <- best[-which(best$user_id==user_id23[i]),]
  }
  print(3)
  day1 <- (day-9)
  day2 <- (day-8)
  D <- filter(t,time>day2)%>%group_by(user_id)%>%distinct()
  C <- filter(t,time>=day1,time<=day2)%>%group_by(user_id)%>%distinct()
  user <- C$user_id
  user <- setdiff(user,D$user_id)
  user <- data.frame(user_id=user)
  user <- left_join(user,t,by="user_id")
  user2 <- filter(user,type==2,time==day1)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==1)%>%select(user_id)
  user3 <- filter(user,type==3,time==day2)%>%group_by(user_id)%>%summarise(count=n())%>%filter(count==1)%>%select(user_id)
  user_id23 <- user2$user_id
  user_id23 <- intersect(user_id23,user3$user_id)
  user_id23 <- intersect(user_id23,best$user_id)
  for(i in 1:length(user_id23)){
    best <- best[-which(best$user_id==user_id23[i]),]
  }
  print(4)
  delete_CDU1 <- delete_ruleContinuityDay(t,1,day)
  delete_CDU1 <- data.frame(user_id=delete_CDU1)
  t2 <- left_join(t,delete_CDU1,by="user_id")
  type1 <- t2%>%group_by(user_id)%>%summarise(count=n())
  cate8_type1 <- filter(t2,cate==8,type==1)%>%group_by(user_id)%>%summarise(cate8_count=n())
  t3 <- left_join(cate8_type1,type1,by="user_id")
  delete_user <- filter(t3,cate8_count==count,count<10,count>5)%>%select(user_id)%>%distinct()
  delete_CDU1 <- delete_user$user_id
  delete_CDU1 <- intersect(delete_CDU1,best$user_id)
  for(i in 1:length(delete_CDU1)){
    best <- best[-which(best$user_id==delete_CDU1[i]),]
  }
  print(5)
  user15 <- filter(t,time>(day-1))%>%select(user_id)%>%distinct()
  user14 <- filter(t,time==(day-1))%>%select(user_id)%>%distinct()
  user_no14 <- filter(t,time<(day-1))%>%select(user_id)%>%distinct()
  user14 <- setdiff(user14,user15,by="user_id")
  user14 <- setdiff(user14,user_no14,by="user_id")
  t2 <- left_join(user14,t,by="user_id")
  user_235 <- filter(t2,type==2|type==3|type==4|type==5)%>%select(user_id)%>%distinct()
  t3 <- left_join(t2,user_235,by="user_id")
  all <- t3%>%group_by(user_id)%>%summarise(count=n())
  user_cate8 <- filter(t3,cate==8)%>%group_by(user_id)%>%summarise(cate8_count=n())
  t4 <- left_join(user_cate8,all,by="user_id")
  user_conut <- filter(t4,cate8_count==count,count<10,count>5)%>%select(user_id)%>%distinct()
  t5 <- left_join(user_conut,t,by="user_id")
  user_num <- t5%>%group_by(user_id,sku_id)%>%summarise()%>%group_by(user_id)%>%summarise(num=n())%>%filter(num>2,num<8)
  delete_user <- intersect(user_num$user_id,best$user_id)
  for(i in 1:length(delete_user)){
    best <- best[-which(best$user_id==delete_user[i]),]
  }
  print(6)
  user13 <- filter(t,time==(day-2))%>%select(user_id)%>%distinct()
  userD13 <- filter(t,time>(day-2))%>%select(user_id)%>%distinct()
  user13 <- setdiff(user13,userD13,by="user_id")
  t2 <- left_join(user13,t,by="user_id")
  t3 <- filter(t2,cate==5,time==(day-2))%>%group_by(user_id)%>%summarise(cate5=n())%>%filter(cate5>30)
  t4 <- filter(t2,cate==8)
  user_68 <- intersect(t3$user_id,t4$user_id)
  delete_user <- intersect(user_68,best$user_id)
  for(i in 1:length(delete_user)){
    best <- best[-which(best$user_id==delete_user[i]),]
  }
  return(best)
}
a <- md(zuiyou2,JData_Action)


#此处删除37个
#读入雨亭特征
yutingfeature  <- read.csv("../part02/user_test.csv")
r <- left_join(zuiyou2,yutingfeature,by="user_id")

rule <- sqldf(" select user_id,sku_id from r where  u21 =  3  and ujq =  0.024  and ujqc =  0.005  and t2jq =  0.0025 and u41 =  0.0560747663551402  and agelabel =  4  and sex =  2  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  2  and ujq =  0.01  and ujqc =  0.01  and t2jq =  0.005 and u41 =  0.0186915887850467  and agelabel =  5  and sex =  2  and maxtime1 =  1
union  all select user_id,sku_id from r where  u21 =  2  and ujq =  0.01  and ujqc =  0.01  and t2jq =  0.005 and u41 =  0.0186915887850467  and agelabel =  4  and sex =  2  and maxtime1 =  1
union  all select user_id,sku_id from r where  u21 =  12  and ujq =  0.06  and ujqc =  0.01  and t2jq =  0.005 and u41 =  0.0654205607476635  and agelabel =  5  and sex =  0  and maxtime1 =  1
union  all select user_id,sku_id  from r where  u21 =  5  and ujq =  0.052  and ujqc =  0.008  and t2jq =  0.004 and u41 =  0.0373831775700935  and agelabel =  4  and sex =  0  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  2  and ujq =  0.01  and ujqc =  0.01  and t2jq =  0.005 and u41 =  0.0186915887850467  and agelabel =  5  and sex =  0  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  3  and ujq =  0.069  and ujqc =  0.008  and t2jq =  0 and u41 =  0.0186915887850467  and agelabel =  1  and sex =  0  and maxtime1 =  3
union  all select user_id,sku_id from r where  u21 =  2  and ujq =  0.022  and ujqc =  0.011  and t2jq =  0.0055 and u41 =  0.0280373831775701  and agelabel =  1  and sex =  2  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  1  and ujq =  0.011  and ujqc =  0.011  and t2jq =  0.0055 and u41 =  0.0280373831775701  and agelabel =  3  and sex =  0  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  1  and ujq =  0.014  and ujqc =  0.011  and t2jq =  0 and u41 =  0.0280373831775701  and agelabel =  1  and sex =  2  and maxtime1 =  3
union  all select user_id,sku_id from r where  u21 =  4  and ujq =  0.344  and ujqc =  0.011  and t2jq =  0.0055 and u41 =  0.0280373831775701  and agelabel =  4  and sex =  1  and maxtime1 =  1
union  all select user_id,sku_id from r where  u21 =  1  and ujq =  0.011  and ujqc =  0.011  and t2jq =  0.0055 and u41 =  0.0280373831775701  and agelabel =  1  and sex =  2  and maxtime1 =  1 and utl2 = 2
union  all select user_id,sku_id from r where  u21 =  34  and ujq =  1.82  and ujqc =  0.02  and t2jq =  0.01 and u41 =  0.0467289719626168  and agelabel =  5  and sex =  2  and maxtime1 =  2
union   all select user_id,sku_id from r where  u21 =  2  and ujq =  0.016  and ujqc =  0.016  and t2jq =  0 and u41 =  0.0373831775700935  and agelabel =  4  and sex =  2  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  12  and ujq =  0.167  and ujqc =  0.019  and t2jq =  0.0095 and u41 =  0.252336448598131  and agelabel =  4  and sex =  0  and maxtime1 =  1
union   all select user_id,sku_id from r where  u21 =  4  and ujq =  0.359  and ujqc =  0.114  and t2jq =  0 and u41 =  0  and agelabel =  5  and sex =  2  and maxtime1 =  9
union   all select user_id,sku_id from r where  u21 =  15  and ujq =  0.165  and ujqc =  0.024  and t2jq =  0 and u41 =  0.373831775700935  and agelabel =  4  and sex =  0  and maxtime1 =  1
union   all select user_id,sku_id from r where  u21 =  82  and ujq =  3.057  and ujqc =  0.022  and t2jq =  0.011 and u41 =  0.672897196261682  and agelabel =  4  and sex =  0  and maxtime1 =  2
union   all select user_id,sku_id from r where  u21 =  2  and ujq =  0.022  and ujqc =  0.022  and t2jq =  0 and u41 =  0.0560747663551402  and agelabel =  3  and sex =  0  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  75  and ujq =  1.77  and ujqc =  0.022  and t2jq =  0 and u41 =  1.2803738317757  and agelabel =  4  and sex =  0  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  3  and ujq =  0.033  and ujqc =  0.03  and t2jq =  0 and u41 =  0.0747663551401869  and agelabel =  1  and sex =  2  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  42  and ujq =  0.66  and ujqc =  0.04  and t2jq =  0.02 and u41 =  0.429906542056075  and agelabel =  5  and sex =  2  and maxtime1 =  1
union   all select user_id,sku_id from r where  u21 =  27  and ujq =  0.983  and ujqc =  0.135  and t2jq =  0 and u41 =  0.224299065420561  and agelabel =  4  and sex =  2  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  46  and ujq =  0.513  and ujqc =  0.043  and t2jq =  0.0215 and u41 =  0.121495327102804  and agelabel =  4  and sex =  0  and maxtime1 =  2
union   all select user_id,sku_id from r where  u21 =  18  and ujq =  0.183  and ujqc =  0.047  and t2jq =  0 and u41 =  0.345794392523364  and agelabel =  4  and sex =  2  and maxtime1 =  3
union   all select user_id,sku_id from r where  u21 =  8  and ujq =  0.2  and ujqc =  0.103  and t2jq =  0.0125 and u41 =  0.14018691588785  and agelabel =  4  and sex =  0  and maxtime1 =  1
union  all select user_id,sku_id from r where  u21 =  45  and ujq =  2.86  and ujqc =  0.108  and t2jq =  0 and u41 =  0.616822429906542  and agelabel =  5  and sex =  0  and maxtime1 =  1
union   all select user_id,sku_id from r where  u21 =  6  and ujq =  0.122  and ujqc =  0.122  and t2jq =  0.025 and u41 =  0.196261682242991  and agelabel =  4  and sex =  2  and maxtime1 =  1
union   all select user_id,sku_id from r where  u21 =  22  and ujq =  1.133  and ujqc =  0.978  and t2jq =  0 and u41 =  0.233644859813084  and agelabel =  5  and sex =  2  and maxtime1 =  3
union  all select user_id,sku_id from r where  u21 =  158  and ujq =  3.86  and ujqc =  0.329  and t2jq =  0.0175 and u41 =  1.1588785046729  and agelabel =  5  and sex =  2  and maxtime1 =  2
union  all select user_id,sku_id from r where  u21 =  30  and ujq =  0.449  and ujqc =  0.247  and t2jq =  0.1235 and u41 =  0.626168224299065  and agelabel =  5  and sex =  2  and maxtime1 =  1
union  all select user_id,sku_id from r where  u21 =  22  and ujq =  1.444  and ujqc =  0.347  and t2jq =  0 and u41 =  0  and agelabel =  4  and sex =  2  and maxtime1 =  10
union  all  select user_id,sku_id from r where  u21 =  77  and ujq =  2.398  and ujqc =  0.171  and t2jq =  0.0855 and u41 =  1.92523364485981  and agelabel =  4  and sex =  0  and maxtime1 =  1
union  all  select user_id,sku_id from r where  u21 =  16  and ujq =  0.517  and ujqc =  0.517  and t2jq =  0 and u41 =  0.00934579439252336  and agelabel =  5  and sex =  0  and maxtime1 =  4
union all  select user_id,sku_id from r where  u21 =  44  and ujq =  0.494  and ujqc =  0.209  and t2jq =  0.1045 and u41 =  0.97196261682243  and agelabel =  5  and sex =  2  and maxtime1 =  1
              ")
a <- setdiff(a,rule)

#219345,63006
#243280,63006
#289692,24371
yuting <- read.csv("label4_us_all.csv")

yuting <- arrange(yuting,desc(pro))

yuting2 <-  setdiff(yuting[,1:2],a)

yuting2 <- left_join(yuting2,yuting,by=c("user_id","sku_id"))

yuting2 <- arrange(yuting2,desc(pro))

a <- rbind(a,yuting2[1:5,1:2])


yuting3 <- yuting %>% left_join(yutingfeature,by="user_id")



add1 <- sqldf("select user_id,sku_id from yuting3  where u21 = 4 and ujq = 0.091 and t1jq = 0.064 and agelabel = 5 and sex = 0 and user_lv_cd = 4
              union select user_id,sku_id from yuting3  where u21 = 12 and ujq = 0.152 and t1jq =  0 and agelabel = 4 and sex = 2 and user_lv_cd = 4 and utl2 = 91
              union select user_id,sku_id from yuting3  where u21 = 10 and ujq = 0.448  and t1jq =  0 and agelabel = 1 and sex = 2 and user_lv_cd = 2 and utl2 = 0
              ")

a <- rbind(a,add1)
#删去7个
a <- setdiff(a,delete7)

write.table (a, file ="submit.csv",sep =",",row.names = F,col.names=TRUE,quote =F)
