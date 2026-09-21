-- =============================================
-- هجرة: انعاش نسخة صلاحيات المستخدم (البند 8 — توجيه CD-004)
-- التاريخ: 2026-09-21
-- الوصف: بند 8 = انعاش الصلاحيات فقط. يعتمد على العمود
--        users.permissions_version (مضاف في بند 0).
--        أولاً: زيادة عمومية إلزامية لنسخ كل المستخدمين.
--        ثم: 4 مشغلات على user_roles / role_permissions
--        (INSERT/DELETE) ترفع نسخة المعنيين عند أي تعديل
--        على ربط المستخدمين بالأدوار أو الأدوار بالصلاحيات.
-- =============================================

-- 1) خطوة إلزامية قبل تفعيل الحارس (بند 8):
--    أي جلسة نشطة قبل الترحيل تحمل نسخة قديمة (permissions_check_at/version
--    غير مثبتة أصلاً). بزيادة النسخة لكل المستخدمين مرة واحدة نسجّل
--    «تغييراً شاملاً» يُجبر كل الجلسات القائمة على إعادة الدخول
--    عند أول فحص بعد نهاية نافذة الكاش (60 ثانية).
UPDATE users SET permissions_version = permissions_version + 1;

-- 2) فهرس user_roles.role_id (مطلوب لربط JOIN داخل مشغل role_permissions):
--    متحقق — موجود بالفعل: KEY `role_id` (`role_id`) في جدول user_roles.
--    لا حاجة لإنشائه من جديد.

-- 3) المشغلات الأربعة (تُعاد إنشاؤها بأمان عند إعادة التشغيل)

DROP TRIGGER IF EXISTS cd004_trg_user_roles_ai;
DELIMITER //
CREATE TRIGGER cd004_trg_user_roles_ai
AFTER INSERT ON user_roles
FOR EACH ROW
BEGIN
    UPDATE users SET permissions_version = permissions_version + 1 WHERE id = NEW.user_id;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS cd004_trg_user_roles_ad;
DELIMITER //
CREATE TRIGGER cd004_trg_user_roles_ad
AFTER DELETE ON user_roles
FOR EACH ROW
BEGIN
    UPDATE users SET permissions_version = permissions_version + 1 WHERE id = OLD.user_id;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS cd004_trg_role_permissions_ai;
DELIMITER //
CREATE TRIGGER cd004_trg_role_permissions_ai
AFTER INSERT ON role_permissions
FOR EACH ROW
BEGIN
    UPDATE users u
    JOIN user_roles ur ON ur.user_id = u.id
    SET u.permissions_version = u.permissions_version + 1
    WHERE ur.role_id = NEW.role_id;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS cd004_trg_role_permissions_ad;
DELIMITER //
CREATE TRIGGER cd004_trg_role_permissions_ad
AFTER DELETE ON role_permissions
FOR EACH ROW
BEGIN
    UPDATE users u
    JOIN user_roles ur ON ur.user_id = u.id
    SET u.permissions_version = u.permissions_version + 1
    WHERE ur.role_id = OLD.role_id;
END//
DELIMITER ;