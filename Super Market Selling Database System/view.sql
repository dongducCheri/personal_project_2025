--View 1: View kiểm tra hàng sắp hết hạn sử dụng trong 7 ngày tới (Cường) 
CREATE VIEW v_sanpham_sap_hethan AS
SELECT 
    h.mahh,
    h.tenhh,
    h.hansudung,
    SUM(ctk.soluong_ton) AS soluong_ton,
    SUM(x.soluongxuat) AS soluongxuat,
    SUM(ctk.soluong_ton) + SUM(x.soluongxuat) AS tong_so_luong
FROM 
    hanghoa h
LEFT JOIN chitietkho ctk ON h.mahh = ctk.mahh
LEFT JOIN xuat x ON h.mahh = x.mahh
WHERE 
    h.hansudung IS NOT NULL
    AND h.hansudung >= CURRENT_DATE
    AND h.hansudung <= CURRENT_DATE + INTERVAL '7 days'
GROUP BY 
    h.mahh, h.tenhh, h.hansudung
ORDER BY 
    h.hansudung;

--View 2: View để hiển thị thông tin sản phẩm có tổng số lượng tồn và trên siêu thị ít hơn 50. (Cường) 
CREATE VIEW sanpham_so_luong_it AS
SELECT 
    h.mahh,
    h.tenhh,
    SUM(ctk.soluong_ton) AS soluong_tonkho,
    SUM(x.soluongxuat) AS soluong_tren_ke,
    (SUM(ctk.soluong_ton) + SUM(x.soluongxuat)) AS tong_so_luong
 FROM 
    hanghoa h
 LEFT JOIN 
    chitietkho ctk ON h.mahh = ctk.mahh
 LEFT JOIN 
    xuat x ON h.mahh = x.mahh
 GROUP BY 
    h.mahh, h.tenhh
 HAVING 
    (SUM(ctk.soluong_ton) + SUM(x.soluongxuat)) < 50;

--View 3: Doanh thu của từng hàng hóa trong tháng 6/2025 (Đăng)
CREATE OR REPLACE VIEW vw_doanh_thu_thang_6_2025 AS
SELECT hh.mahh, hh.tenhh, hh.dongianhap,
    SUM(ct.soluong) AS tong_sl_ban,
    ROUND( SUM(ct.soluong * hh.dongiaban * (100 - ct.chietkhau) / 100.0),                    2) AS doanh_thu,
    ROUND(SUM (ct.soluong * (hh.dongiaban * (100 - ct.chietkhau) / 100.0 - hh.dongianhap)), 2) AS loi_nhuan
FROM chitiethd ct
JOIN hanghoa hh ON ct.mahh = hh.mahh
WHERE hd.ngaylap BETWEEN '2025-06-01' AND '2025-06-30'
GROUP BY hh.mahh;

--View 4: Bảng lương của nhân viên trong tháng 6/2025 (Đăng)
CREATE OR REPLACE VIEW vw_luong_nv_thang_6_2025 AS
SELECT
    q.manv, nv.hoten,
    SUM(CASE WHEN q.calamviec = 'morning'   THEN 1 ELSE 0 END) AS ca_sang,
    SUM(CASE WHEN q.calamviec = 'afternoon' THEN 1 ELSE 0 END) AS ca_chieu,
    SUM(CASE WHEN q.calamviec = 'night'     THEN 1 ELSE 0 END) AS ca_toi,
    COUNT(*) AS tong_so_ca,
    ROUND(SUM(EXTRACT(EPOCH FROM (q.giokethuc - q.giobatdau)) / 3600), 2) AS tong_gio_lam,                      
    ROUND(SUM(EXTRACT(EPOCH FROM (q.giokethuc - q.giobatdau)) / 3600 * q.luong1gio), 0) AS tong_luong
FROM quanly q
JOIN nhanvien nv ON q.manv = nv.manv
WHERE EXTRACT(MONTH FROM q.ngaylam) = 6
    AND EXTRACT(YEAR  FROM q.ngaylam) = 2025
GROUP BY q.manv, nv.hoten;

--View 5: Khung nhìn có thể theo dõi được số lần mua hàng và tổng tiền khách hàng đã sử dụng tại siêu thị (Đức)
CREATE VIEW vw_tan_suat_mua AS 
SELECT k.makhach, k.tenkh, count(distinct hd.mahd) AS so_lan_mua_hang,
    ROUND(SUM(ct.soluong * h.dongiaban * (100 - ct.chietkhau) / 100), 2) AS tong_tien_mua 
FROM khachhang k
JOIN hoadon hd ON hd.makhach = k.makhach
JOIN chitiethd ct ON ct.mahd = hd.mahd
JOIN hanghoa h ON h.mahh = ct.mahh
GROUP BY k.makhach;





