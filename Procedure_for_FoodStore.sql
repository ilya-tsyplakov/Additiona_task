--1 Процедура создает отчет о продажах по годам и месяцам
create procedure dbo.GetMonthlySalesReport
as
begin
    select
        year(OrderDate) as SalesYear,
        month(OrderDate) as SalesMonth,
        sum(p.Price * ord.Quantity) as TotalRevenue
    from Orders as ord
        inner join Products as p on p.ProductID = ord.ProductID
    group by year(OrderDate), month(OrderDate)
    order by SalesYear, SalesMonth
end;


go

--2 Процедура возвращает всех покупателей и количество сделанных ими заказов
create procedure dbo.GetAllCustomersCountOrders
as
begin
    select
        c.CustomerID,
        c.FullName,
        count(ord.OrderID) as cnt_orders
    from Customers as c
        left join Orders as ord on ord.CustomerID = c.CustomerID
    group by c.CustomerID, c.FullName
end;

go

--3 Процедура добавляет нового поставщика и возвращает результат
create procedure dbo.AddNewSupplier(
    @SupplierCompany varchar(100),
    @ContactName varchar(30),
    @Address varchar(255)
)
as
begin
    -- Проверяем существует ли указанный поставщик
    if exists(
	select 1
    from Suppliers
    where SupplierCompany = @SupplierCompany)
	begin
        raiserror('Поставщик с таким именем уже существует', 16, 1)
        return
    end

    -- Добавляем поставщика
    insert into Suppliers
        (SupplierCompany, ContactName, [Address])
    values
        (@SupplierCompany, @ContactName, @Address)

    -- Выводим результат выполнения процедуры
    select top 1
        *
    from Suppliers
    order by SupplierID desc
end;

go

--4 Процедура добавляет новую категорию товаров и связывает ее с поставщиком
create procedure dbo.AddNewCategory(
    @CategoryName varchar(50),
    @SupplierID int
)
as
begin
    -- Проверяем существует ли указанная категория
    if exists(
		select 1
    from Categories
    where CategoryName = @CategoryName)
	begin
        raiserror('Категория с таким именем уже существует', 16, 1)
        return
    end

    -- Проверяем существует ли указанный поставщик
    if not exists(
		select 1
    from Suppliers
    where SupplierID = @SupplierID)
	begin
        raiserror('Поставщик с таким ID не найден', 16, 1)
        return
    end

    -- Добавляем новую категорию и выбранного поставщика
    insert into Categories
        (CategoryName, SupplierID)
    values
        (@CategoryName, @SupplierID)

    -- Выводим результат выполнения процедуры
    select top 1
        *
    from Categories
    order by CategoryID desc
end;

go

--5 Процедура добавляет новый продукт
create procedure dbo.AddNewProductInCategory(
    @ProductName varchar(255),
    @CategoryID int,
    @Price decimal(10, 2),
    @StockQuantity int
)
as
begin
    -- Проверяем существует ли указаный продукт
    if exists(
		select 1
    from Products
    where ProductName = @ProductName)
	begin
        raiserror('Прдукт с таким именем уже существует', 16, 1)
        return
    end

    -- Проверяем существует ли указанная категория
    if not exists(
		select 1
    from Categories
    where CategoryID = @CategoryID)
	begin
        raiserror('Категории с таким ID не существует', 16, 1)
        return
    end

    -- Добавляем новый продукт
    insert into Products
        (ProductName, CategoryID, Price, StockQuantity)
    values
        (@ProductName, @CategoryID, @Price, @StockQuantity)

    -- Выводим результат выполнения процедуры
    select top 1
        *
    from Products
    order by ProductID desc
end;

go

--6 Процедура добовляет нового клиента
create procedure dbo.AddNewCustomer(
    @FullName varchar(50),
    @Email varchar(50),
    @Phone varchar(20),
    @Address varchar(100),
    @DateBirth date
)
as
begin
    -- Проверяем существует ли указанный клиент
    if exists(
		select 1
    from Customers
    where FullName = @FullName)
	begin
        raiserror('Клиент с таким именем уже существует', 16, 1)
        return
    end

    -- Добавляем нового клиента
    insert into Customers
        (FullName, Email, Phone, [Address], DateBirth)
    values
        (@FullName, @Email, @Phone, @Address, @DateBirth)

    -- Выводим результат выполнения процедуры
    select top 1
        *
    from Customers
    order by CustomerID desc
end;

go

--7 Процедура создает новый заказ и обновляет его количество на складе
create procedure dbo.AddNewOrder(
    @CustomerID int,
    @ProductID int,
    @Quantity int
)
as
begin
    -- Проверяем существует ли указанный клиент
    if not exists(
		select 1
    from Customers
    where CustomerID = @CustomerID)
	begin
        raiserror('Клиент с таким ID не найден', 16, 1)
        return
    end

    -- Проверяем существует ли продукт с указанным ID
    if not exists(
		select 1
    from Products
    where ProductID = @ProductID)
	begin
        raiserror('Продукт с таким ID не найден', 16, 1)
        return
    end

    -- Проверяем достаточно ли выбранного товара на складе
    declare @StockQuantity int

    select @StockQuantity = StockQuantity
    from Products
    where ProductID = @ProductID

    if @StockQuantity < @Quantity
	begin
        raiserror('Товара с указанным ID не достаточно на складе', 16, 1)
        return
    end

    -- Обновляем количество товара на складе
    update Products set StockQuantity = StockQuantity - @Quantity
	where ProductID = @ProductID

    -- Добавляем новый заказ в таблицу Orders
    insert into Orders
        (CustomerID, ProductID, Quantity)
    values
        (@CustomerID, @ProductID, @Quantity)

    -- Выводим результат выполнения процедуры
    select top 1
        *
    from Orders
    order by OrderID desc
end;

go

--8 Процедура для изменения информации о продукте
create procedure dbo.UpdateProduct(
    @ProductID int,
    @ProductName varchar(100) = null,
    @CategoryID int = null,
    @Price decimal(10, 2) = null,
    @StockQuantity int = null
)
as
begin
    --проверяем существует ли продукт с таким ID
    if not exists(
		select 1
    from Products
    where ProductID = @ProductID)
	begin
        raiserror('Продукт с таким ID не найден', 16, 1)
        return
    end

    --Обновляем продукт
    update Products set
		ProductName = coalesce(@ProductName, ProductName),
		CategoryID = coalesce(@CategoryID, CategoryID),
		Price = coalesce(@Price, Price),
		StockQuantity = coalesce(@StockQuantity, StockQuantity)
	where ProductID = @ProductID
end;

go

--9 Процедура обновляет информацию о клиенте
create procedure dbo.UpdateCustomer(
    @CustomerID int,
    @FullName varchar(255) = null,
    @Email varchar(50) = null,
    @Phone varchar(20) = null,
    @Address varchar(100) = null,
    @DateBirth date = null
)
as
begin
    -- Проверяем существует ли клиент с выбранным ID
    if not exists( 
        select 1
    from Customers
    where CustomerID = @CustomerID)
    begin
        raiserror('Клиент с таким ID не найден', 16, 1)
        return
    end

    -- Обновляем информацию о клиенте
    update Customers set
        FullName = coalesce(@FullName, FullName),
        Email = coalesce(@Email, Email),
        Phone = coalesce(@Phone, Phone),
        Address = coalesce(@Address, Address),
		DateBirth = coalesce(@DateBirth, DateBirth)
    where CustomerID = @CustomerID

    -- Выводим результат выполнения процедуры
    select *
    from Customers
    where CustomerID = @CustomerID
end;

go

--10  Процедура удаляет выбранного клиента из таблицы Customers
create procedure dbo.DeleteCustomer(
    @CustomerID int
)
as
begin
    -- Проверяем существует ли клиент с выбранным ID
    if not exists(
        select 1
    from Customers
    where CustomerID = @CustomerID
    )
    begin
        raiserror('Клиент с указанным ID не найден', 16, 1)
        return
    end

    -- Удаляем выбранного клиента
    delete from Customers
    where CustomerID = @CustomerID
end;