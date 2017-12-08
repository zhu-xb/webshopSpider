
CREATE TABLE [dbo].[jd_products](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[productId] [varchar](50) NULL,
	[productName] [nvarchar](500) NULL,
	[productPrice] [varchar](50) NULL,
	[productPromotionPrice] [decimal](10, 2) NULL,
	[productPromotion] [nvarchar](2000) NULL,
	[productDate] [datetime] NULL,
 CONSTRAINT [PK_products] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


/**
*根据促销信息和当前销售价格计算出促销价
*/
CREATE FUNCTION [dbo].[ufn_jd_calcPromotionPrice]
(
@productPromotion nvarchar(2000),
@productPrice varchar(50)
)
RETURNS decimal(10,2) 
AS
begin
	declare @tempPromotion  nvarchar(2000)
	set @tempPromotion = @productPromotion

	declare @PromotionPrice decimal(10,2)
	if ISNUMERIC(@productPrice)=0
	begin
		set @PromotionPrice = 0
		return @PromotionPrice
	end
	set @PromotionPrice=convert(decimal(10,2),@productPrice)
	
	--折扣幅度
	declare @zk decimal(4,2) 
	declare @zktemp decimal(4,2)
	set @zk=1
	set @zktemp=1
	
	declare @temp1  nvarchar(200)
	declare @temp2  nvarchar(200)
	
	declare @index int
	set @index=0

	while @index<10--为了避免出现死循环，限制检索次数
	begin
		set @index=@index+1
		if @tempPromotion like '%每满%元，可减%元现金%'
		begin
			 set @temp2 =substring(@tempPromotion,charindex('每满',@tempPromotion)+2,20)
			 set @temp1 = substring(@temp2,1,charindex('元',@temp2)-1)
			 if charindex('可减',@temp2)>0
			 begin
				 set @temp2 =substring(@temp2,charindex('可减',@temp2)+2,6)
				 set @temp2 = substring(@temp2,1,charindex('元',@temp2)-1)
				 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2)
		 
				 set @tempPromotion=replace(@tempPromotion,'每满'+@temp1+'元，可减'+@temp2+'元现金','')
			 end
			 else
			 begin
				 set @tempPromotion=replace(@tempPromotion,'每满'+@temp1+'元','')
			 end
		end
		else if @tempPromotion like '%总价打%折%'
		begin
			 set @temp1 =substring(@tempPromotion,charindex('总价打',@tempPromotion)+3,5)
			 set @temp1 = substring(@temp1,1,charindex('折',@temp1)-1)
			 set @zktemp = convert(decimal(4,2) ,@temp1)*0.1
			 set @tempPromotion=replace(@tempPromotion,'总价打'+@temp1+'折','')
		end
		else if @tempPromotion like '%满%元减%元%'
		begin	
			 set @temp2 =substring(@tempPromotion,charindex('满',@tempPromotion)+1,12)
			 set @temp1 = substring(@temp2,1,charindex('元',@temp2)-1)
			 if charindex('减',@temp2)>0
			 begin
				 set @temp2 =substring(@temp2,charindex('减',@temp2)+1,6)
				 set @temp2 = substring(@temp2,1,charindex('元',@temp2)-1)
				 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2) 
				 set @tempPromotion=replace(@tempPromotion,'满'+@temp1+'元减'+@temp2+'元','')
			 end
			 else
			 begin
				 set @tempPromotion=replace(@tempPromotion,'满'+@temp1+'元','')
			 end
		end
		else
		begin
			set @index=20
		end

		if @zk > @zktemp
		begin
			set @zk=@zktemp
		end
	end

	return convert(decimal(10,2),round(@zk*@PromotionPrice,2))
end



GO



/**
*商品历史最低价格和最近日期
*/
CREATE view [dbo].[v_jd_productMinPrice]
as 
	select a.productid,a.productPromotionPrice,max(productdate) as 'productdate'
	from (select productid,min([productPromotionPrice]) as 'productPromotionPrice'
			from [jd_products]
			group by productid) a
	inner join [jd_products] b on a.productid=b.productid and a.[productPromotionPrice]=b.[productPromotionPrice]
	group by a.productid,a.productPromotionPrice



GO

/**
*商品昨日价格/最近价格和最低价格对比
*/

CREATE view [dbo].[v_jd_productHisPrice]
as 	
	select a.productid as '商品编号'
		,a.productName as '商品名称'
		,isnull(convert(decimal(10,2),b.[productPromotionPrice]),0) as '昨日价格'
		,isnull(convert(decimal(10,2),a.[productPromotionPrice]),0) as '最新价格'
		,isnull(convert(decimal(10,2),c.[productPromotionPrice]),0) as '历史最低价格'
		,isnull(c.productdate,'') as '最低价格时间'
	from [jd_products] a 
	inner join (select productid,max(ID) as 'ID'
				from [jd_products] 
				group by productid) m 
					on a.ID=m.ID

	left join (select productid,min([productPromotionPrice]) as 'productPromotionPrice',max(productdate) as 'productdate'
				from[jd_products]
				where productdate between convert(varchar(10),dateadd(day,-1,getdate()),120) and convert(varchar(10),getdate(),120)
				group by productid) b 
					on a.productid=b.productid

	left join  [v_jd_productMinPrice] c on a.productid=c.productid


GO


