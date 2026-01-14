CREATE DATABASE trigger_practice;
USE trigger_practice;

-- Bảng khách hàng
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at DATETIME
);

-- Bảng đơn hàng
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Bảng lịch sử thao tác
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    action VARCHAR(20),
    action_time DATETIME,
    description TEXT
);

-- Bảng tồn kho
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT
);

-- Bảng chi tiết bán hàng
CREATE TABLE sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_time DATETIME,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

/*
Bài 1
Yêu cầu:
Khi thêm khách hàng mới, nếu created_at = NULL thì tự động gán thời gian hiện tại.
*/
delimiter //
create trigger tg_insert_customer
before insert on customers
for each row
begin
	if New.created_at is null then
		set New.created_at = current_timestamp();
	end if;
end //
delimiter ;

/*
Bài 2 
Yêu cầu:
Sau khi thêm khách hàng, ghi log vào audit_log.
Nội dung log:
•	table_name = 'customers'
•	action = 'INSERT'
•	action_time = NOW()
•	description = 'Thêm khách hàng mới: <tên>'
*/
select * from audit_log;

delimiter //
create trigger tg_insert_customer_write_log
after insert on customers
for each row
begin
	insert into audit_log(table_name,action,action_time,description) values
    ('customers','INSERT',now(),concat('Thêm khách hàng mới: ',New.name));
end //
delimiter ;

/*
Bài 3
Yêu cầu:
Không cho phép cập nhật email rỗng ('' hoặc NULL).
Nếu vi phạm → báo lỗi bằng SIGNAL SQLSTATE '45000'.
*/
delimiter //
create trigger tg_update_customers
before update on customers
for each row
begin
	if New.email = ' ' or length(New.email)=0 or New.email is null then
		signal sqlstate '45000' set message_text = 'Không cho phép cập nhật email rỗng ('' hoặc NULL)';
	end if;
end //
delimiter ;

/*
Bài 4 
Yêu cầu:
Khi trạng thái đơn hàng (orders.status) thay đổi, ghi log.
Ví dụ log:
Đơn hàng 5 đổi trạng thái từ pending sang completed
*/
delimiter //
create trigger tg_status_order
after update on orders
for each row
begin
	insert into audit_log(table_name,action,action_time,description) values
    ('orders','UPDATE',now(),concat('Đơn hàng ',New.order_id,' đổi trạng thái từ ',Old.status,' sang ',New.status));
end //
delimiter ;

/*
Bài 5 
Yêu cầu:
Không cho xóa khách hàng nếu đã có đơn hàng.

Kiểm tra tồn tại trong orders, nếu có → chặn xóa.
*/
delimiter //
create trigger tg_delete_customers
before delete on customers
for each row
begin
	if exists (select * from orders where customer_id = Old.customer_id) then
		signal sqlstate '45000' set message_text = 'Không xoá được, khách hàng đang có đơn hàng';
    end if;
end //
delimiter ;

/*
Bài 6 
Yêu cầu:
Sau khi xóa đơn hàng, ghi log hành động DELETE.
*/
delimiter //
create trigger tg_delete_order
after delete on orders
for each row
begin
	insert into audit_log(table_name,action,action_time,description) values
    ('orders','DELETE',now(),concat('Đã xoá đơn hàng: ',Old.order_id));
end //
delimiter ;

/*
Bài 7 
Yêu cầu:
Khi thêm đơn hàng, nếu amount < 0 → không cho insert.
*/
-- Tự làm

/*
Bài 8 
Yêu cầu:
Khi bán hàng (insert vào sales), tự động trừ số lượng trong products.stock
*/
-- Tự làm

/*
Bài 9 – (Ngăn âm kho)
Yêu cầu:
Khi cập nhật products.stock, không cho phép giá trị < 0.
*/
-- Tự làm

/*
Bài 10 – AFTER UPDATE + AFTER DELETE
Yêu cầu:
Ghi log cho:
•	Mọi cập nhật trong bảng products
•	Mọi xóa trong bảng products
Nội dung log gồm:
•	Tên bảng + hành động + thời gian + mô tả
*/
-- Tự làm (viết thành 2 triggers)