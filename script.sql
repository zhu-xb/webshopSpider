
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
*���ݴ�����Ϣ�͵�ǰ���ۼ۸�����������
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
	
	--�ۿ۷���
	declare @zk decimal(4,2) 
	declare @zktemp decimal(4,2)
	set @zk=1
	set @zktemp=1
	
	declare @temp1  nvarchar(200)
	declare @temp2  nvarchar(200)
	
	declare @index int
	set @index=0

	while @index<10--Ϊ�˱��������ѭ�������Ƽ�������
	begin
		set @index=@index+1
		if @tempPromotion like '%ÿ��%Ԫ���ɼ�%Ԫ�ֽ�%'
		begin
			 set @temp2 =substring(@tempPromotion,charindex('ÿ��',@tempPromotion)+2,50)
			 set @temp1 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
			 set @temp2 =substring(@temp2,charindex('�ɼ�',@temp2)+2,6)
			 set @temp2 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
			 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2)
		 
			 set @tempPromotion=replace(@tempPromotion,'ÿ��'+@temp1+'Ԫ���ɼ�'+@temp2+'Ԫ�ֽ�','')
		end
		else if @tempPromotion like '%�ܼ۴�%��%'
		begin
			 set @temp1 =substring(@tempPromotion,charindex('�ܼ۴�',@tempPromotion)+3,5)
			 set @temp1 = substring(@temp1,1,charindex('��',@temp1)-1)
			 set @zktemp = convert(decimal(4,2) ,@temp1)*0.1
			 set @tempPromotion=replace(@tempPromotion,'�ܼ۴�'+@temp1+'��','')
		end
		else if @tempPromotion like '%��%Ԫ��%Ԫ%'
		begin	
			 set @temp2 =substring(@tempPromotion,charindex('��',@tempPromotion)+1,50)
			 set @temp1 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
			 set @temp2 =substring(@temp2,charindex('��',@temp2)+1,6)
			 set @temp2 = substring(@temp2,1,charindex('Ԫ',@temp2)-1)
			 set @zktemp = round((convert(decimal(10,4) ,@temp1) - convert(decimal(10,4) ,@temp2))/convert(decimal(10,4) ,@temp1),2) 
			 set @tempPromotion=replace(@tempPromotion,'��'+@temp1+'Ԫ��'+@temp2+'Ԫ','')
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
*��Ʒ��ʷ��ͼ۸���������
*/
CREATE view [dbo].[v_jd_productMinPrice]
as 
	select a.productid,b.productName,a.productPromotionPrice,max(productdate) as 'productdate'
	from (select productid,min([productPromotionPrice]) as 'productPromotionPrice'
			from [jd_products]
			group by productid) a
	inner join [jd_products] b on a.productid=b.productid and a.[productPromotionPrice]=b.[productPromotionPrice]
	group by a.productid,b.productName,a.productPromotionPrice



GO

/**
*��Ʒ���ռ۸�/����۸����ͼ۸�Ա�
*/

CREATE view [dbo].[v_jd_productHisPrice]
as 	
	select a.productid as '��Ʒ���'
		,a.productName as '��Ʒ����'
		,isnull(convert(decimal(10,2),b.[productPromotionPrice]),0) as '���ռ۸�'
		,isnull(convert(decimal(10,2),a.[productPromotionPrice]),0) as '���¼۸�'
		,isnull(convert(decimal(10,2),c.[productPromotionPrice]),0) as '��ʷ��ͼ۸�'
		,isnull(c.productdate,'') as '��ͼ۸�ʱ��'
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


