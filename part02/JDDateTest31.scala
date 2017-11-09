package jd

import java.util

import org.apache.spark.{SparkConf, SparkContext}

/**
  * 停留时间
  */
object JDDateTest31 {

  def main(args: Array[String]) {
    //    //传入的参数为 输入目录 输出目录
    //    if (args.length != 2) {
    //      System.err.println("Usage: input  output")
    //      System.exit(1)
    //    }
    //  }

    val conf = new SparkConf().setAppName("SparkWordCount").setMaster("local[2]")
    val sc = new SparkContext(conf)

    //  val line=sc.textFile(args(0)).flatMap(_.split(","))
//    val path = "/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/data2/JData_Action_201604.csv"
    val format = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    sc.textFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/IAction").map(x=>{
      val lineArray = x.split(",")
      val user_id = lineArray(0)

      val time = lineArray(1)
      val year = lineArray(2)
      (user_id+","+year,time)
    }).groupByKey().map(x=>{
      val timeArray = x._2.toArray.sorted
      val sb = new StringBuilder
      for(i <- 0 until (timeArray.length-1) ){
        val time1 = timeArray(i)
        val time2 = timeArray(i+1)
        var diff:Long = (format.parse(time2).getTime-format.parse(time1).getTime)/1000
        if(diff >60*30){
          diff = 5
        }
        sb.append(x._1+","+diff+"\n")

      }
      sb.toString()

    }).repartition(1).saveAsTextFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/xx")

    sc.stop()

  }
}
