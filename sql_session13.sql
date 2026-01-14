create database trigger_K24_CNTT04;
use trigger_K24_CNTT04;
create table products(
	pro_id int auto_increment primary key,
    pro_name varchar(100),
    producer varchar(100),
    price numeric(15,2) check(price >=0)
);

create table product_stock(
	stock_id int auto_increment primary key,
    pro_id int references products(pro_id),
    quantity int check(quantity>=0) default 0    
);

create table product_export(
	export_id int auto_increment primary key,
    pro_id int references products(pro_id),
    quantity int check(quantity>0)
);

-- Cài đặt trigger để số lượng xuất kho phải nhỏ hơn số lượng tồn kho
delimiter //
create trigger tg_quantity_export
before insert on product_export
for each row
begin
	if New.quantity>(select quantity from product_stock where pro_id=New.pro_id) then
		signal sqlstate '45000' set message_text = 'Số lượng xuất kho không được vượt quá số lượng tồn kho';
	end if;
    
    -- Cập nhật lại số lượng tồn kho (trừ đi số lượng xuất kho)
    update product_stock set quantity = quantity - New.quantity
    where pro_id = New.pro_id;
end //
delimiter ;


-- insert dl để test
select * from products;
insert into products(pro_name,producer,price) values
('Máy tính dell insprion core i7','Dell',18000000),
('Điện thoại samsung A32','Samsung',7000000);

insert into product_stock(pro_id,quantity)
values (1,10),(2,5);

insert into product_export(pro_id,quantity) values
(1,2);

-- test lại tồn kho
select * from product_stock;

-- Cài đặt trigger
-- Dữ liệu bóng đá
create table doi_bong(
	ma_doi_bong char(15) not null primary key,
    ten_doi_bong varchar(100) not null unique
);

create table tt_thi_dau(
	ma_tran_dau int auto_increment primary key,
    ngay_thi_dau date,
    ma_doi_bong char(15),
    so_ban_thang int check(so_ban_thang>=0),
    so_ban_thua int check(so_ban_thua>=0),
    diem int check(diem>=0 and diem<=3)
);

insert into doi_bong(ma_doi_bong,ten_doi_bong) values
('MU','Manchester United'),
('ARS','Arsenal'),
('LIV','Liverpool');

insert into tt_thi_dau(ngay_thi_dau,ma_doi_bong,so_ban_thang,so_ban_thua) values
('2025-10-22','MU',3,1),
('2025-10-22','ARS',1,3),
('2025-10-30','MU',2,2),
('2025-10-30','LIV',2,2),
('2025-11-10','ARS',0,2),
('2025-11-10','LIV',2,0);

select * from tt_thi_dau;

-- Cài đặt trigger để mỗi khi insert hoặc update dữ liệu vào bảng
-- tt_thi_dau thì cột điểm sẽ được tự tính

delimiter //
create trigger tg_update_diem_for_tt_thi_dau_insert
before insert on tt_thi_dau
for each row
begin
	if (New.so_ban_thang>New.so_ban_thua) then set New.diem=3;
    elseif (New.so_ban_thang<New.so_ban_thua) then set New.diem = 0;
    else set New.diem = 1; end if;
end //
delimiter ;

-- Cài đặt trigger để mỗi khi update dữ liệu bảng tt_thi_dau sẽ
-- cập nhật lại giá trị cho cột điểm
delimiter //
create trigger tg_update_diem_for_tt_thi_dau_update
before update on tt_thi_dau
for each row
begin
	if (New.so_ban_thang>New.so_ban_thua) then set New.diem=3;
    elseif (New.so_ban_thang<New.so_ban_thua) then set New.diem = 0;
    else set New.diem = 1; end if;
end //
delimiter ;

select * from tt_thi_dau;
-- delete from tt_thi_dau;

update tt_thi_dau set so_ban_thang = 1, so_ban_thua=1 where ma_tran_dau=11 or ma_tran_dau=12;


-- --------------------------
create database SocialNetworkDB;
use SocialNetworkDB;
create table users(
	user_id int auto_increment primary key,
    username  varchar(100) not null unique,
    total_posts int default 0
);

create table posts(
	post_id int auto_increment primary key,
    user_id int references users(user_id),
    content text,
    created_at  datetime
);

create table post_audits(	
	audit_id int auto_increment primary key,
    post_id int references posts(post_id),
    old_content text,
    new_content  text,
	changed_at  datetime
);

/*
Task 1 (BEFORE INSERT): Viết trigger tg_CheckPostContent trên bảng posts.
Nhiệm vụ: Kiểm tra nội dung bài viết (content). Nếu nội dung trống hoặc chỉ toàn khoảng trắng,
hãy ngăn chặn hành động chèn và thông báo lỗi: "Nội dung bài viết không được để trống!".
*/
delimiter //
create trigger tg_CheckPostContent
before insert on posts
for each row
begin
	if New.content = ' ' or length(New.content)=0 or New.content is null then
		signal sqlstate '45000' set message_text = 'Nội dung bài viết không được để trống!';
    end if;
end //
delimiter ;
-- test
-- insert users
insert into users(username) values
('cuongbg'),('dunghn'),('binhnt');

select * from posts;

insert into posts(user_id,content,created_at) values
(1,'',current_date());
insert into posts(user_id,created_at) values
(1,current_date());

/*
Task 2 (AFTER INSERT): Viết trigger tg_UpdatePostCountAfterInsert trên bảng posts.
Nhiệm vụ: Mỗi khi một bài viết được thêm mới thành công, hãy tự động tăng giá trị cột 
total_posts của người dùng đó trong bảng users lên 1 đơn vị.
*/
delimiter //
create trigger tg_UpdatePostCountAfterInsert
after insert on posts
for each row
begin
	update users set total_posts = total_posts + 1 where user_id = New.user_id;
end //
delimiter ;

insert into posts(user_id,content,created_at) values
(1,'Bài viết 1 của bạn Cường',current_date()),
(1,'Bài viết 2 của bạn Cường',current_date()),
(2,'Bài viết 1 của bạn Dũng',current_date());

select * from users;

/*
Task 3 (AFTER UPDATE): Viết trigger tg_LogPostChanges trên bảng posts.
Nhiệm vụ: Khi nội dung (content) của một bài viết bị thay đổi, hãy tự động chèn một dòng 
vào bảng post_audits để lưu lại nội dung cũ, nội dung mới và thời điểm chỉnh sửa.
*/
delimiter //
create trigger tg_LogPostChanges
after update on posts
for each row
begin
	insert into post_audits(post_id,old_content,new_content,changed_at) values
    (New.post_id,Old.content,New.content,current_date());
end //
delimiter ;

select * from posts;

select * from posts;
update posts set content = 'Bài viết 2 đã được cập nhật lại của bạn Cường' where post_id=5;

select * from post_audits;

/*
Task 4 (AFTER DELETE): Viết trigger tg_UpdatePostCountAfterDelete trên bảng posts.
Nhiệm vụ: Khi một bài viết bị xóa, hãy tự động giảm giá trị cột total_posts của người 
dùng đó trong bảng users xuống 1 đơn vị.
*/
delimiter //
create trigger tg_UpdatePostCountAfterDelete
after delete on posts
for each row
begin
	update users set total_posts = total_posts - 1 where user_id = Old.user_id;
end //
delimiter ;

select * from users;

delete from posts where post_id = 5;
