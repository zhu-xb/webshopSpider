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
* ���ݴ�����Ϣ������ۿ۷���
*/
create FUNCTION [dbo].[ufn_getPromotion]
(	@productPromotion nvarchar(2000)
)
RETURNS decimal(4,2) 
AS
begin
	declare @tempPromotion  nvarchar(2000)
	set @tempPromotion = @productPromotion
	
	--�ۿ۷���
	declare @zk decimal(4,2) 
	declare @zk1 decimal(4,2) 
	declare @zk2 decimal(4,2) 
	declare @zk3 decimal(4,2) 
	set @zk=1
	set @zk1=1
	set @zk2=1
	set @zk3=1	
	
	declare @temp1  nvarchar(200)
	declare @temp2  nvarchar(200)
	
	if @tempPromotion like '%ÿ��%Ԫ���ɼ�%Ԫ�ֽ�%'
	begin
		 set @temp1 =substring(@tempPromotion,charindex('ÿ��',@tempPromotion)+2,6)
		 set @temp1 = substring(@temp1,1,charindex('Ԫ',@temp1)-1)
		 set @temp2 =substring(@tempPromotion,charindex('�ɼ�',@tempPromotion)+2,6)
		 set @temp2 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
		 set @zk1 = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2)
		 
		 set @tempPromotion=replace(@tempPromotion,'ÿ��'+@temp1+'Ԫ���ɼ�'+@temp2+'Ԫ�ֽ�','')
	end
	
	if @tempPromotion like '%�ܼ۴�%��%'
	begin
		 set @temp1 =substring(@tempPromotion,charindex('�ܼ۴�',@tempPromotion)+3,5)
		 set @temp1 = substring(@temp1,1,charindex('��',@temp1)-1)
		 set @zk2 = convert(decimal(4,2) ,@temp1)
		 set @tempPromotion=replace(@tempPromotion,'�ܼ۴�'+@temp1+'��','')
	end
		
	if @tempPromotion like '%��%Ԫ��%Ԫ%'
	begin	
		 set @temp1 =substring(@tempPromotion,charindex('��',@tempPromotion)+1,6)
		 set @temp1 = substring(@temp1,1,charindex('Ԫ',@temp1)-1)
		 set @temp2 =substring(@tempPromotion,charindex('��',@tempPromotion)+1,6)
		 set @temp2 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
		 set @zk3 = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2) 
		 set @tempPromotion=replace(@tempPromotion,'��'+@temp1+'Ԫ��'+@temp2+'Ԫ','')
	end
	
	set @zk=@zk1
	if @zk > @zk2
	begin
		set @zk=@zk2
	end
	if @zk > @zk3
	begin
		set @zk=@zk3
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
	select a.productid as '��Ʒ���'
		,a.productName as '��Ʒ����'
		,isnull(convert(decimal(10,2),b.yestodayPrice),0) as '���ռ۸�'
		,isnull(convert(decimal(10,2),a.todayPrice),0) as '���ռ۸�'
		,isnull(convert(decimal(10,2),c.minPrice),0) as '��ʷ��ͼ۸�'
		,isnull(c.productdate,'') as '��ͼ۸�ʱ��'
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


