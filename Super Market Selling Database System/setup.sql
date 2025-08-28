CREATE TABLE kho (
    makho INTEGER PRIMARY KEY,
    tenkho VARCHAR(100) NOT NULL,
    quanly VARCHAR(50) NOT NULL,
    sdt VARCHAR(15)
);

CREATE TABLE hanghoa (
    mahh INTEGER PRIMARY KEY,
    tenhh VARCHAR(100) NOT NULL,
    loaihh VARCHAR(50) NOT NULL,
    dongiaban NUMERIC(10,2) NOT NULL,
    dongianhap NUMERIC(10,2) NOT NULL,
    donvi VARCHAR(20) NOT NULL,
    hansudung DATE
);

CREATE TABLE nhacungcap (
    mancc INTEGER PRIMARY KEY,
    tenncc VARCHAR(100) NOT NULL,
    nguoidaidien VARCHAR(100) NOT NULL,
    diachi VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    sdt VARCHAR(15) NOT NULL
);

CREATE TABLE phongban (
    maphong INTEGER PRIMARY KEY,
    tenphong VARCHAR(100) NOT NULL,
    truongphong VARCHAR(100) NOT NULL
);


CREATE TABLE nhanvien (
    manv INTEGER PRIMARY KEY,
    hoten VARCHAR(100) NOT NULL,
    chucvu VARCHAR(50) NOT NULL,
    sdt VARCHAR(15) NOT NULL,
    diachi VARCHAR(100),
    ngayvaolam DATE NOT NULL
);


CREATE TABLE khachhang (
    makhach INTEGER PRIMARY KEY,
    loaikh VARCHAR(50) NOT NULL,
    tenkh VARCHAR(100) NOT NULL,
    sdt VARCHAR(15) NOT NULL,
    ngaydangky DATE,
    expired_date DATE
);


CREATE TABLE xuat (
    makho INTEGER NOT NULL,
    mahh INTEGER NOT NULL,
    soluongxuat INTEGER NOT NULL,
    ngayxuat DATE NOT NULL,
    PRIMARY KEY (makho, mahh, ngayxuat),
    FOREIGN KEY (makho) REFERENCES kho(makho),
    FOREIGN KEY (mahh) REFERENCES hanghoa(mahh)
);


CREATE TABLE nhap (
    mahh INTEGER NOT NULL,
    mancc INTEGER NOT NULL,
    soluongnhap INTEGER NOT NULL,
    ngaynhap DATE NOT NULL,
    PRIMARY KEY (mahh, mancc, ngaynhap),
    FOREIGN KEY (mahh) REFERENCES hanghoa(mahh),
    FOREIGN KEY (mancc) REFERENCES nhacungcap(mancc)
);

CREATE TABLE quanly (
    manv INTEGER NOT NULL,
    maphong INTEGER NOT NULL,
    ngaylam DATE NOT NULL,
    calamviec VARCHAR(10) NOT NULL,
    giobatdau TIME NOT NULL,
    giokethuc TIME NOT NULL,
    luong1gio NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (manv, maphong, ngaylam),
    FOREIGN KEY (manv) REFERENCES nhanvien(manv),
    FOREIGN KEY (maphong) REFERENCES phongban(maphong)
);

CREATE TABLE hoadon (
    mahd INTEGER PRIMARY KEY,
    manv INTEGER NOT NULL,
    makhach INTEGER NOT NULL,
    ngaylap DATE NOT NULL,
    phuongthuc VARCHAR(50) NOT NULL,
    trangthai VARCHAR(50) NOT NULL,
    FOREIGN KEY (manv) REFERENCES nhanvien(manv),
    FOREIGN KEY (makhach) REFERENCES khachhang(makhach)
);

CREATE TABLE chitiethd (
    mahd INTEGER NOT NULL,
    mahh INTEGER NOT NULL,
    soluong INTEGER NOT NULL,
    chietkhau NUMERIC(5,2),
    PRIMARY KEY (mahd, mahh),
    FOREIGN KEY (mahd) REFERENCES hoadon(mahd),
    FOREIGN KEY (mahh) REFERENCES hanghoa(mahh),
    CHECK (chietkhau >= 0 AND chietkhau <= 100)
);


CREATE TABLE chitietkho (
    makho INTEGER NOT NULL,
    mahh INTEGER NOT NULL,
    soluong_ton INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (makho, mahh),
    UNIQUE (mahh),
    FOREIGN KEY (makho) REFERENCES kho(makho),
    FOREIGN KEY (mahh) REFERENCES hanghoa(mahh)
);

--Các rằng buộc 
ALTER TABLE xuat
ADD CONSTRAINT uq_mahh_in_xuat UNIQUE (mahh);

ALTER TABLE chitietkho
ADD CONSTRAINT uq_chitietkho_mahh UNIQUE (mahh);

ALTER TABLE xuat
ADD CONSTRAINT fk_xuat_chitietkho
FOREIGN KEY (mahh) REFERENCES chitietkho(mahh);

-- Đảm bảo hàng hóa trong hóa đơn phải có trên kệ hàng 
ALTER TABLE chitiethd
ADD CONSTRAINT fk_chitiethd_xuat_mahh
FOREIGN KEY (mahh) REFERENCES xuat(mahh);

ALTER TABLE xuat
  ADD CONSTRAINT chk_xuat_soluongxuat_nonneg
  CHECK (soluongxuat >= 0);

ALTER TABLE nhap
  ADD CONSTRAINT chk_nhap_soluongnhap_nonneg
  CHECK (soluongnhap >= 0);

ALTER TABLE chitiethd
  ADD CONSTRAINT chk_chitiethd_soluong_nonneg
  CHECK (soluong >= 0);

ALTER TABLE chitietkho
  ADD CONSTRAINT chk_chitietkho_soluong_ton_nonneg
  CHECK (soluong_ton >= 0);
