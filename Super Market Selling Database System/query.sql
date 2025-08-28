--Truy vấn
--Đức
--Câu truy vấn 1: Trả về thông tin các hóa đơn có tổng tiền hóa đơn lớn hơn tổng tiền trung bình của tất cả các hóa đơn trong siêu thị trong khoảng tháng 6/2025 (Đức)
--Cách 1:
SELECT it.mahd, it.manv, it.makhach, it.ngaylap, it.phuongthuc, it.trangthai, it.tong_tien
FROM (
  SELECT hd.mahd, hd.manv, hd.makhach, hd.ngaylap, hd.phuongthuc, hd.trangthai,
    ROUND(SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau) / 100.0), 2) AS tong_tien
  FROM hoadon hd
  JOIN chitiethd ct ON ct.mahd = hd.mahd
  JOIN hanghoa hh ON hh.mahh = ct.mahh
  WHERE hd.ngaylap BETWEEN '2025-06-01' AND '2025-06-30'
  GROUP BY hd.mahd
) AS it
WHERE it.tong_tien > (
  -- Sub-query trong WHERE tính  AVG(tong_tien)
  SELECT AVG(sub.tong_tien)
  FROM (SELECT ROUND(SUM(ct2.soluong * hh2.dongiaban * (100 - ct2.chietkhau) / 100.0), 2) AS tong_tien
    FROM hoadon     hd2
    JOIN chitiethd  ct2 ON ct2.mahd = hd2.mahd
    JOIN hanghoa    hh2 ON hh2.mahh = ct2.mahh
    WHERE hd2.ngaylap BETWEEN '2025-06-01' AND '2025-06-30'
    GROUP BY hd2.mahd
  ) AS sub
)
ORDER BY it.tong_tien DESC;

--Cách 2
WITH invoice_totals AS (
SELECT hd.mahd, hd.manv, hd.makhach, hd.ngaylap, hd.phuongthuc, hd.trangthai,
ROUND(SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau) / 100.0), 2) AS tong_tien
    FROM hoadon hd
    JOIN chitiethd ct ON ct.mahd = hd.mahd
    JOIN hanghoa hh ON hh.mahh = ct.mahh
    WHERE hd.ngaylap BETWEEN '2025-06-01' AND '2025-06-30'
    GROUP BY hd.mahd
)
SELECT * 
FROM invoice_totals it
WHERE it.tong_tien > (
    SELECT AVG(tong_tien)
    FROM invoice_totals
)
ORDER BY tong_tien desc;

--Câu truy vấn 2: Tìm kiếm các khách hàng đã mua hàng hóa có mã 81 (do hàng phát hiện bị lỗi và cần thu hồi, đền bù cho khách), hãy trả về thông tin khách hàng (tên + sdt) và mã hóa đơn chứa mặt hãng mã 81 đó. (Đức)
--Cách 1:
SELECT hd.*, k.makhach, k.tenkh, k.sdt
FROM hoadon hd
JOIN (
  SELECT DISTINCT mahd
  FROM chitiethd
  WHERE mahh = 81
) sub ON hd.mahd = sub.mahd
JOIN khachhang k ON hd.makhach = k.makhach;

--Cách 2: Thêm index
CREATE INDEX idx_chitiethd_mahh ON chitiethd(mahh);
SELECT hd.*, k.makhach, k.tenkh, k.sdt
FROM hoadon hd
JOIN (
  SELECT DISTINCT mahd
  FROM chitiethd
  WHERE mahh = 81
) sub ON hd.mahd = sub.mahd
JOIN khachhang k ON hd.makhach = k.makhach;

--Câu truy vấn 3: Top 3 sản phẩm mang lại nhiều lợi nhuận nhất trong tháng 6/2025 (Đức)
WITH top3 AS (
  SELECT DISTINCT loi_nhuan
  FROM vw_doanh_thu_thang_6_2025
  ORDER BY loi_nhuan DESC
  LIMIT 3
)
SELECT *
FROM vw_doanh_thu_thang_6_2025 v
WHERE v.loi_nhuan >= (SELECT MIN(loi_nhuan) FROM top3)
ORDER BY loi_nhuan DESC;

--Cường
-- Câu 1: Hiển thị top 3 sản phẩm bán chạy nhất theo số lượng bán. Nếu có nhiều sản phẩm có cùng số lượng bán, hãy hiển thị tất cả các sản phẩm đó.
WITH top3_sl AS (
    SELECT DISTINCT SUM(ct2.soluong) AS tong
    FROM hanghoa h2
    JOIN chitiethd ct2 ON h2.mahh = ct2.mahh
    GROUP BY h2.mahh
    ORDER BY tong DESC
    LIMIT 3
)
SELECT 
    h.mahh,
    h.tenhh,
    SUM(ct.soluong) AS tong_so_luong_ban
FROM 
    hanghoa h
JOIN 
    chitiethd ct ON h.mahh = ct.mahh
GROUP BY 
    h.mahh, h.tenhh
HAVING 
    SUM(ct.soluong) IN (SELECT tong FROM top3_sl)
ORDER BY 
    tong_so_luong_ban DESC;

-- Câu 2: Tìm ra thông tin của nhân viên đã lập hóa đơn (ví dụ: hoá đơn mã 21).
SELECT 
    nv.manv,
    nv.hoten,
    nv.chucvu,
    nv.sdt,
    nv.diachi
FROM 
    hoadon hd
JOIN 
    nhanvien nv ON hd.manv = nv.manv
WHERE 
    hd.mahd = 21;

-- Câu 3: Hiển thị thông tin nhân viên có số ca làm việc nhiều nhất trong tháng 6.
SELECT 
    nv.manv,
    nv.hoten,
    COUNT(*) AS so_ca_lam
FROM 
    quanly ql
JOIN 
    nhanvien nv ON ql.manv = nv.manv
WHERE 
    ql.ngaylam BETWEEN '2025-06-01' AND '2025-06-30'
GROUP BY 
    nv.manv, nv.hoten
HAVING 
    COUNT(*) >= ALL (
        SELECT 
            COUNT(*)
        FROM 
            quanly ql2
        WHERE 
            ql2.ngaylam BETWEEN '2025-06-01' AND '2025-06-30'
        GROUP BY 
            ql2.manv
    )
ORDER BY 
    so_ca_lam DESC;


-- Câu 4: Hiển thị thông tin nhân viên làm việc vào ngày 14/06/2025. 
SELECT 
    nv.manv,
    nv.hoten,
    nv.chucvu,
    nv.sdt,
    nv.diachi,
    ql.maphong,
	ql.ngaylam,
    ql.calamviec,
    ql.giobatdau,
    ql.giokethuc
FROM 
    quanly ql
JOIN 
    nhanvien nv ON ql.manv = nv.manv
WHERE 
    ql.ngaylam = '2025-06-14';

-- Câu 5: Hiển thị sản phẩm đang ở kệ nào của siêu thị
SELECT 
    hh.mahh,
    hh.tenhh,
    x.kehang,
    SUM(x.soluongxuat) AS soluong_tren_ke
FROM 
    hanghoa hh
JOIN 
    xuat x ON hh.mahh = x.mahh
WHERE 
    hh.tenhh ILIKE '%LED%'
GROUP BY 
    hh.mahh, hh.tenhh, x.kehang
ORDER BY 
    hh.mahh;

-- câu 6: Những sản phẩm bán chậm ( < 5 sản phẩm )
SELECT 
    h.mahh,
    h.tenhh,
    SUM(ct.soluong) AS tong_ban
FROM 
    hanghoa h
JOIN chitiethd ct ON h.mahh = ct.mahh
GROUP BY h.mahh, h.tenhh
HAVING SUM(ct.soluong) < 5
ORDER BY tong_ban ASC;

-- Câu 7: Tính tổng doanh thu của ngày 10/06/2025
SELECT 
    hd.ngaylap,
    SUM(ct.soluong * hh.dongiaban * (1 - ct.chietkhau / 100.0)) AS tong_doanh_thu
FROM 
    hoadon hd
JOIN 
    chitiethd ct ON hd.mahd = ct.mahd
JOIN 
    hanghoa hh ON ct.mahh = hh.mahh
WHERE 
    hd.ngaylap = DATE '2025-06-10'
GROUP BY 
    hd.ngaylap;


--Đăng
--•	Câu truy vấn 1 : Tìm các khách hàng có tổng chi tiêu nhiều nhất theo từng loại hàng hóa (Đăng)
WITH tong_chi_tung_khach AS (
    SELECT hh.loaihh,k.makhach,k.tenkh,
    ROUND(SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau) / 100.0), 2) AS tong_chi
    FROM khachhang k
    JOIN hoadon hd ON k.makhach = hd.makhach
    JOIN chitiethd ct ON ct.mahd = hd.mahd
    JOIN hanghoa hh ON hh.mahh = ct.mahh
    GROUP BY hh.loaihh, k.makhach, k.tenkh
),
max_chi_theo_loai AS (
    SELECT loaihh, MAX(tong_chi) AS max_chi
    FROM tong_chi_tung_khach
    GROUP BY loaihh
)

SELECT t.loaihh, t.makhach, t.tenkh, t.tong_chi
FROM tong_chi_tung_khach t
JOIN max_chi_theo_loai m ON t.loaihh = m.loaihh AND t.tong_chi = m.max_chi
ORDER BY t.loaihh, t.tong_chi DESC;
--•	Câu truy vấn 2 : Liệt kê doanh thu và lợi nhuận của từng loại ngành hàng (Đăng)
SELECT hh.loaihh AS loai_hang,
       SUM(ct.soluong) AS tong_so_luong_ban,
       SUM(ct.soluong * hh.dongianhap) AS tong_tien_nhap,
 ROUND(SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau)/100.0), 2) AS tong_tien_ban,
ROUND(SUM(ct.soluong * ((hh.dongiaban * (100 - ct.chietkhau) /100.0) - hh.dongianhap)), 2) AS loi_nhuan
FROM chitiethd ct
JOIN hanghoa hh ON ct.mahh = hh.mahh
GROUP BY hh.loaihh
ORDER BY loi_nhuan DESC;

--•	Câu truy vấn 3 : Tìm các khách hàng có tổng chi tiêu nhiều nhất theo từng loại hàng hóa (Đăng)
WITH tong_chi_tung_khach AS (
    SELECT hh.loaihh,
           k.makhach,
           k.tenkh,
           ROUND(SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau) / 100.0), 2) AS tong_chi
    FROM khachhang k
    JOIN hoadon hd ON k.makhach = hd.makhach
    JOIN chitiethd ct ON ct.mahd = hd.mahd
    JOIN hanghoa hh ON hh.mahh = ct.mahh
    GROUP BY hh.loaihh, k.makhach, k.tenkh
),
max_chi_theo_loai AS (
    SELECT loaihh, MAX(tong_chi) AS max_chi
    FROM tong_chi_tung_khach
    GROUP BY loaihh
)
SELECT t.loaihh, t.makhach, t.tenkh, t.tong_chi
FROM tong_chi_tung_khach t
JOIN max_chi_theo_loai m ON t.loaihh = m.loaihh AND t.tong_chi = m.max_chi
ORDER BY t.loaihh, t.tong_chi DESC;
