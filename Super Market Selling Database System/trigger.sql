--Trigger 1: Sau khi 1 hàng hóa được nhập vào siêu thị, số lượng hàng hóa sẽ được cập nhật vào bảng tồn kho của siêu thị. (Đức)
CREATE OR REPLACE FUNCTION fn_cap_nhat_chitietkho_khi_nhap()
RETURNS TRIGGER AS $$
DECLARE
  v_makho INT;
BEGIN
  -- Xác định kho dựa vào loaihh của hàng hóa vừa nhập
  SELECT CASE h.loaihh
    WHEN 'Electronics' THEN 1
    WHEN 'Food' THEN 2
    WHEN 'Furniture' THEN 3
    WHEN 'Clothing' THEN 4
    WHEN 'Building Material' THEN 5
    ELSE NULL
END
  INTO v_makho
  FROM hanghoa h
  WHERE h.mahh = NEW.mahh;
  -- Nếu đã có record thì cộng thêm, nếu chưa có 
     thì chèn mới
  UPDATE chitietkho
  SET soluong_ton = soluong_ton + NEW.soluongnhap
  WHERE makho = v_makho
    AND mahh  = NEW.mahh;
  IF NOT FOUND THEN
    INSERT INTO chitietkho(makho, mahh, soluong_ton)
    VALUES (v_makho, NEW.mahh, NEW.soluongnhap);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger AFTER INSERT on 'nhap'
CREATE TRIGGER trg_after_insert_nhap_cap_nhat_chitietkho
AFTER INSERT ON nhap
FOR EACH ROW
EXECUTE FUNCTION fn_cap_nhat_chitietkho_khi_nhap();



--Trigger 2: Cập nhật số lượng hàng hóa còn lại trong kho sau khi xuất hàng lên kệ của siêu thị (Đức)
CREATE OR REPLACE FUNCTION fn_tru_ton_kho()
RETURNS TRIGGER AS $$
DECLARE
  v_ton INT;
BEGIN
  -- Lấy tồn hiện tại của mặt hàng trong kho
  SELECT soluong_ton
  INTO v_ton
  FROM chitietkho
  WHERE makho = NEW.makho
    AND mahh  = NEW.mahh;

  -- Nếu chưa có record hoặc tồn không đủ thì báo lỗi
  IF v_ton IS NULL OR v_ton < NEW.soluongxuat THEN
    RAISE EXCEPTION
      'Xuất kho không thành công tại kho %, mặt hàng %. Tồn hiện tại: %, số lượng xuất: %',
      NEW.makho, NEW.mahh, COALESCE(v_ton, 0), NEW.soluongxuat;
  END IF;
  -- Trừ số lượng xuất khỏi tồn kho
  UPDATE chitietkho
  SET soluong_ton = soluong_ton - NEW.soluongxuat
  WHERE makho = NEW.makho
    AND mahh  = NEW.mahh;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger before INSERT on 'xuat'
CREATE TRIGGER  trg_before_insert_xuat_tru_ton
BEFORE INSERT ON xuat
FOR EACH ROW

--Lưu ý: 
--Bảng xuất cho ta biết rằng số lượng mặt hàng hiện tại đang có trên kệ hàng siêu thị, mỗi khi ta insert 1 bản ghi vào bảng xuất, thì nó sẽ cập nhật số lượng mới = tổng số lượng cũ + số lượng xuất.
--Tuy nhiên, để thuận tiện cho sau này, khi ta xuất hóa đơn, thì số sản phẩm trên kệ sẽ bị trừ đi do khách hàng mua hàng. Để thuận tiện, ta để thuộc tính xuat(mahh) là UNIQUE CONSTRAINT để thuộc tính chitiethd(mahh) tham chiếu đến xuat(mahh), do hàng hóa phải tồn tại trên kệ hàng thì khách mới chọn mua được. 

--Cách insert lên bảng xuất
INSERT INTO xuat(makho, mahh, ngayxuat, soluongxuat, kehang)
VALUES (1, 3, '2025-05-08', 25, 'K3')
ON CONFLICT (mahh) DO UPDATE
SET soluongxuat = xuat.soluongxuat + EXCLUDED.soluongxuat,
    kehang = EXCLUDED.kehang, ngayxuat = EXCLUDED.ngayxuat;



--Trigger 3: Số lượng hàng còn lại trên siêu thị sẽ bị giảm sau khi khách mua hàng, số lượng khách mua từng loại mặt hàng sẽ ở bảng chi tiết hóa đơn (Đức) 
CREATE OR REPLACE FUNCTION trg_check_and_update_xuat()
RETURNS trigger AS
$$
DECLARE
    current_qty INTEGER;
BEGIN
    -- Lấy số lượng hàng hóa trên kệ hàng hiện tại của mã hàng
    SELECT soluongxuat INTO current_qty
    FROM xuat
    WHERE mahh = NEW.mahh;

    -- Nếu không tìm thấy mã hàng hoặc số lượng không đủ
    IF current_qty < NEW.soluong THEN
        RAISE EXCEPTION 'Không đủ hàng trên kệ để bán. Mã hàng hóa: %, Số lượng yêu cầu: %, Số lượng hiện có: %',
            NEW.mahh, NEW.soluong, COALESCE(current_qty, 0);
    END IF;

    -- Trừ số lượng đã bán đượcđược
    UPDATE xuat
    SET soluongxuat = soluongxuat - NEW.soluong
    WHERE mahh = NEW.mahh;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_insert_chitiethd
BEFORE INSERT ON chitiethd
FOR EACH ROW
EXECUTE FUNCTION trg_check_and_update_xuat();



--Trigger 4: Cập nhật lại loại khách sang ‘Loyal” khi khách hàng mua hàng trên 3 lần tại siêu thị, với tổng giá trị mua hàng trên 100000 đồng, chỉ áp dụng khi khách là khách lẻ(Retail). (Đức)
CREATE OR REPLACE FUNCTION fn_capnhatkh_loyal()
RETURNS TRIGGER AS $$
DECLARE 
    buy_count int;
    total_amt numeric;
    v_loaikh varchar;
BEGIN
    --Lấy số lần mua của khách 
    SELECT count(*) INTO buy_count
    FROM hoadon
    WHERE makhach = (SELECT makhach 
			FROM hoadon WHERE mahd = NEW.mahd);

    -- Tính tổng tiền các hóa đơn
    SELECT SUM(ct.soluong * hh.dongiaban) INTO total_amt
    FROM hoadon h
    JOIN chitiethd ct ON h.mahd = ct.mahd
    JOIN hanghoa hh ON hh.mahh = ct.mahh
    WHERE h.makhach = (SELECT makhach 
			FROM hoadon WHERE mahd = NEW.mahd);
    --Lấy thông tin loại khách hiện tại
    SELECT loaikh INTO v_loaikh
    FROM khachhang
    WHERE makhach = (SELECT makhach FROM hoadon WHERE mahd = NEW.mahd);

-- Cập nhật nếu thỏa điều kiện
    IF buy_count > 3 AND total_amt > 100000 AND v_loaikh = 'Retail' THEN
        UPDATE khachhang
        SET loaikh = 'Loyal'
        WHERE makhach = (SELECT makhach FROM hoadon WHERE mahd = NEW.mahd);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_capnhat_loyal
AFTER INSERT ON chitiethd
FOR EACH ROW
EXECUTE FUNCTION fn_capnhatkh_loyal();

--Trigger 5: Trigeer để tự động cập nhật chiết khấu 10% khi hàng hóa sắp hết hạn (cụ thể là 30 ngày cuối) (Cường)
CREATE OR REPLACE FUNCTION trig_cap_nhat_chiet_khau_hsd_ngan()
RETURNS TRIGGER AS $$
DECLARE
    v_hsd DATE;
    v_ngaylap DATE;
BEGIN
    -- Lấy hạn sử dụng của sản phẩm
    SELECT hansudung INTO v_hsd
    FROM hanghoa
    WHERE mahh = NEW.mahh;

    -- Lấy ngày lập hóa đơn
    SELECT ngaylap INTO v_ngaylap
    FROM hoadon
    WHERE mahd = NEW.mahd;

    -- Nếu hạn sử dụng không NULL và còn <= 30 ngày thì set chiết khấu = 10%
    IF v_hsd IS NOT NULL AND v_ngaylap IS NOT NULL AND v_hsd - v_ngaylap <= 30 THEN
        NEW.chietkhau := 10.00;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_truoc_insert_cthd_cap_nhat_ck
BEFORE INSERT ON chitiethd
FOR EACH ROW
EXECUTE FUNCTION trig_cap_nhat_chiet_khau_hsd_ngan();

--Trigger 6: Đối với các khách hàng Loyal hoặc các khách hàng có thẻ thành viên chưa hết hạn khi mua hàng, áp dụng chiết khấu 5% lên toàn bộ mặt hàng trong hóa đơn đó. (Đức)
CREATE OR REPLACE FUNCTION trg_auto_chietkhau_loyal_thanhvien()
RETURNS TRIGGER AS $$
DECLARE
    v_makhach INT;
    v_ngaylap DATE;
    v_loaikh VARCHAR;
    v_expired DATE;
BEGIN
    -- Lấy thông tin hóa đơn + khách
    SELECT h.makhach, h.ngaylap, k.loaikh, k.expired_date
    INTO v_makhach, v_ngaylap, v_loaikh, v_expired
    FROM hoadon h
    JOIN khachhang k ON h.makhach = k.makhach
    WHERE h.mahd = NEW.mahd;

    -- Nếu khách là Loyal hoặc còn hạn thẻ
    IF v_loaikh = 'Loyal' OR v_ngaylap < v_expired THEN
        NEW.chietkhau := 5.00;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_chietkhau_loyal_thanhvien
BEFORE INSERT ON chitiethd
FOR EACH ROW
EXECUTE FUNCTION trg_auto_chietkhau_loyal_thanhvien();

--Trigger 7: Khách hàng muốn đổi, trả hàng, khi khách trả hàng thì số lượng hàng hóa đó sẽ được cập nhật lại vào số lượng tồn kho (Đăng)
CREATE OR REPLACE FUNCTION fn_hoan_tra_hang()
RETURNS TRIGGER AS $$
BEGIN
UPDATE chitietkho
    SET soluong_ton = soluong_ton + OLD.soluong
    WHERE mahh = OLD.mahh;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_doi_tra_hang
AFTER DELETE ON chitiethd
FOR EACH ROW
EXECUTE FUNCTION fn_hoan_tra_hang();






