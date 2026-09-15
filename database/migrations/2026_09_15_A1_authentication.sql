-- =============================================
-- هجرة: تهيئة نظام المصادقة A1 (توجيه CD-004)
-- التاريخ: 2026-09-15
-- الوصف: إنشاء `login_attempts` و`password_history`،
--        إضافة عمودي `users` (must_change_password, permissions_version)،
--        إزالة `password_resets` (متحقق: 0 صفوف، لا FK، لا مراجع كود تشغيلي).
-- =============================================

-- 1) إزالة جدول استعادة كلمة المرور القديم (بند 9 / ر.ق 2)
DROP TABLE IF EXISTS password_resets;

-- 2) جدول محاولات الدخول (بند 2)
CREATE TABLE login_attempts (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(100) NOT NULL COMMENT 'اسم المستخدم المقدم في المحاولة',
  ip_address VARCHAR(45) NOT NULL COMMENT 'عنوان IP للمحاولة (يدعم IPv6)',
  attempted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'وقت المحاولة',
  success TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = نجاح، 0 = فشل',
  PRIMARY KEY (id),
  KEY idx_login_username_time (username, attempted_at),
  KEY idx_login_attempted_at (attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='محاولات الدخول — قفل بعد 5 فاشلة خلال 15 دقيقة';

-- 3) جدول تاريخ كلمات المرور (بند 11)
CREATE TABLE password_history (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT(11) NOT NULL COMMENT 'مطابق users.id',
  password_hash VARCHAR(255) NOT NULL COMMENT 'رمز BCrypt لكلمة المرور السابقة',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pwhistory_user (user_id, created_at),
  CONSTRAINT fk_pwhistory_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='كلمات مرور سابقة — نبذ آخر 3 كلمات';

-- 4) أعمدة users (بند 8 و9)
ALTER TABLE users
  ADD COLUMN must_change_password TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'إجبار تغيير كلمة المرور عند الدخول التالي' AFTER updated_at,
  ADD COLUMN permissions_version INT UNSIGNED NOT NULL DEFAULT 1
    COMMENT 'نسخة صلاحيات المستخدم — تزداد عند تعديل الدور' AFTER must_change_password;