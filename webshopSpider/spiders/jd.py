# -*- coding: utf-8 -*-
import scrapy
from webshopSpider.items import WebshopSpiderItem
import datetime

class JdSpider(scrapy.Spider):
    name = 'jd'
    allowed_domains = ['m.jd.com']
    start_urls = ['https://item.m.jd.com/product/4486466.html']

    def __init__(self):
        self.urlTemp = 'https://item.m.jd.com/product/'
        self.productIds = ['412520','11863664','11863682','11881517','2202376',                   
                           '666635','3039347','160207','346416','346417','844714',                   
                           '844715','1015255','1099521','3582618','1039778','1039821',                   
                           '818098','2202076','1233195','1233202','2857852','112165',                   
                           '201450','1039812','1039813','1218759','1917212','5495648',                   
                           '4160255','1062060','862558','736878','1240628','411099',                   
                           '546566','505811','537436','3398890','2242038','2868006',                   
                           '3520852','3520850','3751699','140440','691059','1327678',                   
                           '1537064','1169887','1134285','1095883','1721634','2274330',                   
                           '5259317','1168536','270309','1183382','1290515','686943',                   
                           '1301236','1000840','1221514','1322298']
        self.url_set = set()

    def parse(self, response):
        if response.status == 200:
            item = WebshopSpiderItem()
            item['productId'] = response.css('#currentWareId::attr(value)').extract_first().strip()
            item['productName'] = response.css('#goodName::attr(value)').extract_first().strip()
            item['productPrice'] = response.css('#jdPrice::attr(value)').extract_first().strip()
            productPromotionItems = response.css('span.promotion-item-text::text').extract()
            productPromotion = ''
            for temp in productPromotionItems:
                productPromotion = productPromotion + temp + ';'
            item['productPromotion'] = productPromotion
            item['productDate'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            yield item
        for productId in self.productIds:
            url = self.urlTemp + productId + '.html'
            if url in self.url_set:
                pass
            else:
                self.url_set.add(url)
                # 回调函数默认为parse,也可以通过from scrapy.http import Request来指定回调函数
                # from scrapy.http import Request
                # Request(url,callback=self.parse)
                yield self.make_requests_from_url(url)
