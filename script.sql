CREATE TABLE [dbo].[products](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[productId] [varchar](50) NULL,
	[productName] [nvarchar](500) NULL,
	[productPrice] [varchar](50) NULL,
	[productPromotion] [nvarchar](2000) NULL,
	[productDate] [datetime] NULL,
 CONSTRAINT [PK_products] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/*
* 根据促销信息计算出折扣幅度
*/
create FUNCTION [dbo].[ufn_getPromotion]
(	@productPromotion nvarchar(2000)
)
RETURNS decimal(4,2) 
AS
begin
	declare @tempPromotion  nvarchar(2000)
	set @tempPromotion = @productPromotion
	
	--折扣幅度
	declare @zk decimal(4,2) 
	declare @zktemp decimal(4,2)
	set @zk=1
	set @zktemp=1
	
	declare @temp1  nvarchar(200)
	declare @temp2  nvarchar(200)
	
	declare @isnext char(1)
	set @isnext='Y'

	while @isnext='Y'
	begin
		if @tempPromotion like '%每满%元，可减%元现金%'
		begin
			 set @temp1 =substring(@tempPromotion,charindex('每满',@tempPromotion)+2,6)
			 set @temp1 = substring(@temp1,1,charindex('元',@temp1)-1)
			 set @temp2 =substring(@tempPromotion,charindex('可减',@tempPromotion)+2,6)
			 set @temp2 = substring(@temp2,1,charindex('元',@temp2)-1)
			 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2)
		 
			 set @tempPromotion=replace(@tempPromotion,'每满'+@temp1+'元，可减'+@temp2+'元现金','')
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
			 set @temp1 =substring(@tempPromotion,charindex('满',@tempPromotion)+1,6)
			 set @temp1 = substring(@temp1,1,charindex('元',@temp1)-1)
			 set @temp2 =substring(@tempPromotion,charindex('减',@tempPromotion)+1,6)
			 set @temp2 = substring(@temp2,1,charindex('元',@temp2)-1)
			 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2) 
			 set @tempPromotion=replace(@tempPromotion,'满'+@temp1+'元减'+@temp2+'元','')
		end
		else
		begin
			set @isnext='N'
		end

		if @zk > @zktemp
		begin
			set @zk=@zktemp
		end
	end

	return @zk
end




create view [dbo].[v_products]
as
	SELECT [ID]
      ,[productId]
      ,[productName]
      ,[productPrice]
      ,[productPromotion]
      ,[dbo].[ufn_getPromotion] ([productPromotion]) as 'zkfd'
      ,[dbo].[ufn_getPromotion] ([productPromotion]) * convert(decimal(10,4),productPrice) as 'zkPrice'
      ,[productDate]
  FROM [dbo].[products]

GO


CREATE view [dbo].[v_productHisPrice]
as 
	select a.productid as '商品编号'
		,a.productName as '商品名称'
		,isnull(convert(decimal(10,2),b.yestodayPrice),0) as '昨日价格'
		,isnull(convert(decimal(10,2),a.todayPrice),0) as '今日价格'
		,isnull(convert(decimal(10,2),c.minPrice),0) as '历史最低价格'
		,isnull(c.productdate,'') as '最低价格时间'
	from 
		(select productid,productName,min(zkprice) as 'todayPrice' from v_products
		where productdate between convert(varchar(10),getdate(),120) and convert(varchar(10),dateadd(day,1,getdate()),120)
		group by productid,productName) a
	left join 
		(select productid,min(zkprice) as 'yestodayPrice' from v_products
		where productdate between convert(varchar(10),dateadd(day,-1,getdate()),120) and convert(varchar(10),getdate(),120)
		group by productid) b on a.productid=b.productid
	left join 
		(select productid,min(zkprice) as 'minPrice',max(convert(varchar(10),productdate,120)) as 'productdate' from v_products
		group by productid) c on a.productid=c.productid

GO


