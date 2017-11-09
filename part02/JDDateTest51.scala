package jd

import org.apache.spark.{SparkConf, SparkContext}
import java.util
/**
  * 合并连续相同访问次数为一次
  */
object JDDateTest51 {

  def main(args: Array[String]) {

    val conf = new SparkConf().setAppName("SparkWordCount").setMaster("local[2]")
    val sc = new SparkContext(conf)

    sc.textFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/Action_all2.csv").map(x=>{
      val lineArray = x.split(",")
      val user_id = lineArray(0)
      val sku_id  = lineArray(1)
      val types = lineArray(4)
      val year = lineArray(2)
      var time = lineArray(7)

      (user_id+","+types+","+year,sku_id+","+time)

    }).distinct().groupByKey().map(x=>{
      val sortlist = x._2.toArray.sortBy(x=>x.split(",")(1))
      val hashmap = new util.HashMap[String,Int]()

      for(i <- 0 until (sortlist.length-1) ){
        if(!hashmap.containsKey(x._1+","+sortlist(i).split(",")(0)))  {
          hashmap.put(x._1+","+sortlist(i).split(",")(0),0)
        }
        if(!(x._1+","+sortlist(i).split(",")(0)).equals(x._1+","+sortlist(i+1).split(",")(0))){
          var count = hashmap.get(x._1+","+sortlist(i).split(",")(0))+1
          hashmap.put(x._1+","+sortlist(i).split(",")(0),count)
        }
      }

      var count = hashmap.get(x._1+","+sortlist(sortlist.length-1).split(",")(0))+1
      hashmap.put(x._1+","+sortlist(sortlist.length-1).split(",")(0),count)
      hashmap
    }).map(x=>{
      val sb = new StringBuilder
      val it = x.entrySet().iterator()
      while(it.hasNext){
        val value = it.next()
        val key = value.getKey
        var values = value.getValue.toInt

        sb.append(key+","+values+"\n")
      }
      sb.toString()
    }).repartition(1).saveAsTextFile("/Users/yuyin/Downloads/笔记学习/天池比赛/JD高潜用户购买意向预测/记录/第五周top1_0.197/x4")
    sc.stop()

  }
}
