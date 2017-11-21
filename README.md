使用scrapy框架制作购物网站爬虫。爬取到各购物网站的商品名称、价格、促销等信息。

目前仅实现了京东网站的商品信息爬取

script.sql是商品信息记录表

爬取的商品都保存到MSSQL数据库中。

数据库连接地址在pipelines.py中配置

settings.py中配置的每10秒爬取一个商品网页DOWNLOAD_DELAY = 10

为了避免被京东封IP，仅爬取自己关注的商品。如需更改爬取商品目录，在spiders/jd.py中的productIds中增加或修改商品ID
