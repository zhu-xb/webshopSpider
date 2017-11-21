# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html

import sys
import os
import pymssql


reload(sys)
sys.setdefaultencoding("utf-8")

class webshopSpiderPipeline(object):

    def __init__(self):
        self.host = '192.168.1.1'
        self.user = 'sa'
        self.password = 'sa'
        self.database = 'db'
        self.conn = pymssql.connect(host=self.host,user=self.user,password=self.password,database=self.database,charset="utf8")
        self.cur = self.conn.cursor()
    def process_item(self, item, spider):
        productId = item['productId']
        productName = item['productName']
        productPrice = item['productPrice']
        productPromotion = item['productPromotion']
        productDate = item['productDate']
        sql = "insert into Products values ('"+productId+"','"+productName.replace("'","''")+"','"+productPrice\
              +"','"+productPromotion.replace("'","''")+"','"+productDate+"')"
        #print(sql)
        self.cur.execute(sql)
        self.conn.commit()
        return item

    def close_spider(self, spider):
        self.conn.close()
