# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy

class WebshopSpiderItem(scrapy.Item):
    productId = scrapy.Field()
    productName = scrapy.Field()
    productPrice = scrapy.Field()
    productPromotion = scrapy.Field()
    productDate = scrapy.Field()
