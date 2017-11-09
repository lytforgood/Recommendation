package jd

import org.apache.spark.{SparkConf, SparkContext}

/**
  * 间隔时间
  */
object JDDateTest42 {

  def main(args: Array[String]) {


    val conf = new SparkConf().setAppName("SparkWordCount").setMaster("local[2]")
    val sc = new SparkContext(conf)


    val format = new java.text.SimpleDateFormat("yyyyMMdd")
    sc.textFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/action_val.csv").map(x=>{
      val lineArray = x.split(",")
      val user_id = lineArray(0)
      val time = lineArray(1)
      (user_id,time)
    }).distinct().groupByKey().map(x=>{
      val timeArray = x._2.toArray.sorted
      val sb = new StringBuilder
      if(timeArray.length<2){
        sb.append(x._1+","+0+"\n")

      }else{
        for(i <- 0 until (timeArray.length-1) ){

          val time1 = timeArray(i)
          val time2 = timeArray(i+1)
          var diff:Long = (format.parse(time2).getTime-format.parse(time1).getTime)/(1000*60*60*24)
          sb.append(x._1+","+diff+"\n")
        }
        sb.toString()

      }

    }).repartition(1).saveAsTextFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/x2")


    sc.stop()

  }
}
