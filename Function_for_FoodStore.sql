--1 Функция возвращает информацию о колличестве выбранного товара на складе
create function dbo.func_GetProductCount(
	@ProductID int
)
returns int
as
begin
    declare @Count int

    select @Count = StockQuantity
    from Products
    where ProductID = @ProductID

    return @Count
end;

go

--2 Функция возвращает полную информацию о поставщике и о его товарах
create function dbo.func_GetInfoSupplierName(
	@SupplierID int
)
returns table
as
return
select
    s.SupplierID,
    s.ContactName,
    s.Address,
    c.CategoryName,
    p.ProductName
from Suppliers as s
    left join Categories as c on c.SupplierID = s.SupplierID
    left join Products as p on p.CategoryID = c.CategoryID
where s.SupplierID = @SupplierID;

go

--3 Функция возвращает 1 если клиент с указаным ID совершал покупки в течении последних 7 дней
create function dbo.func_CheckCustomerRecentPurchases(
	@CustomerID int
)
returns bit
as
begin
    declare @Purchases bit

    select @Purchases = 
		case
			when count(*) > 0 then 1
			else 0
		end
    from Orders
    where CustomerID = @CustomerID
        and OrderDate >= dateadd(day, -7, getdate())

    return @Purchases
end;

go

--4 Функция возвращает возраст клиента
create function dbo.func_GetAgeCustomer(
	@CustomerID int
)
returns int
as
begin
    declare @Age int

    select @Age = datediff(year, DateBirth, getdate()) - 
		case
			when month(DateBirth) > month(getdate())
            or (month(DateBirth) = month(getdate()) and day(DateBirth) > day(getdate())) then 1
			else 0
		end
    from Customers
    where CustomerID = @CustomerID

    return @Age
end;

go

--5 Функция возвращает полную информацию о клиенте и о его заказе
create function dbo.func_GetCustomerOrder(
    @CustomerID int
)
returns table
as
return
select
    c.CustomerID,
    c.FullName,
    c.Email,
    c.Phone,
    c.Address,
    c.DateBirth,
    ord.OrderID,
    p.ProductName,
    ctg.CategoryName,
    ord.Quantity,
    ord.OrderDate,
    (ord.Quantity * p.Price) as TotalSum
from Customers as c
    left join Orders as ord on ord.CustomerID = c.CustomerID
    left join Products as p on p.ProductID = ord.ProductID
    inner join Categories as ctg on ctg.CategoryID = p.CategoryID
where c.CustomerID = @CustomerID;

go

--6 Функция возвращает общее количество проданного товара по его ID
create function dbo.func_GetTotalSoldQuantity(
	@ProductID int
)
returns int
as
begin
    declare @TotalSold int

    select @TotalSold = sum(Quantity)
    from Orders
    where ProductID = @ProductID

    return @TotalSold
end;

go

--7 Функция возвращает общюю сумму заказов каждого клиента
create function dbo.func_GetTotalRevenue(
	@CustomerID int
)
returns decimal(10, 2)
as
begin
    declare @TotalRevenue decimal(10, 2)

    select @TotalRevenue = sum(ord.Quantity * p.Price)
    from Orders as ord
        inner join Products as p on p.ProductID = ord.ProductID
    where ord.CustomerID = @CustomerID

    return @TotalRevenue
end;

go

--8 Функция возвращает название всех продуктов из выбраной категории
create function dbo.func_GetProductsInCategory(
	@CategoryID int
)
returns table
as
return
select ProductName
from Products as p
    right join Categories as c on c.CategoryID = p.CategoryID
where c.CategoryID = @CategoryID;

go

--9 Функция будет генерировать отчет о продажах по каждому продукту за указанный период времени
create function dbo.func_GetSalesReport(
    @StartDate date,
    @EndDate date
)
returns table
as
return
select
    p.ProductID,
    p.ProductName,
    sum(ord.Quantity) as QuantitySold,
    sum(ord.Quantity * p.Price) as TotalSales
from Orders as ord
    inner join Products as p on p.ProductID = ord.ProductID
where ord.OrderDate between @StartDate and @EndDate
group by p.ProductID, p.ProductName;

go

--10 Функция возвращает информацию о клиенте по ID заказа
create function dbo.func_GetCustomerInfoByOrderID(
	@OrderID int
)
returns table
as
return
select
    c.CustomerID,
    c.FullName,
    c.Phone,
    c.DateBirth
from Customers as c
    inner join Orders as ord on ord.CustomerID = c.CustomerID
where OrderID = @OrderID;