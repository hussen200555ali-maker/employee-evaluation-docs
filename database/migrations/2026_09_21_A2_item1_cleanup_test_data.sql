-- ============================================================
-- CD-006 / A2 — البند 1: تنظيف بيانات الاختبار (بقايا CD-004)
-- التاريخ: 2026-09-21
-- الوصف: حذف الحسابات الاختبارية المتبقية من CD-004:
--        (email LIKE '%@test.local' OR username LIKE 'test\_%' OR username LIKE 'cd004.%')
--        مع تسجيل إجراء USER_CLEANUP_TEST_DATA في audit_logs مع العدد.
-- ملاحظة: حذف user_roles يتم تلقائيًا عبر FK ON DELETE CASCADE
--         (وكذلك notifications عبر ON DELETE CASCADE).
-- معيار القبول: يبقى 4 حسابات حقيقية فقط (sysadmin, kghamdi, smutairi, fzahrani).
-- ============================================================

START TRANSACTION;

SET @deleted = (
    SELECT COUNT(*) FROM users
    WHERE email LIKE '%@test.local'
       OR username LIKE 'test\_%'
       OR username LIKE 'cd004.%'
);

DELETE FROM users
WHERE email LIKE '%@test.local'
   OR username LIKE 'test\_%'
   OR username LIKE 'cd004.%';

INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES (
    NULL,
    'USER_CLEANUP_TEST_DATA',
    'users',
    NULL,
    JSON_OBJECT(
        'deleted', @deleted,
        'criteria', 'email LIKE %@test.local OR username LIKE test\\_% OR username LIKE cd004.%'
    ),
    'CLI'
);

-- إزالة أي عضوية يتيمة في user_roles (user_id بلا أب) — بقايا اختبار قديمة
-- أُدخلت قبل تفعيل قيد المفتاح الخارجي؛ القيد الحالي ON DELETE CASCADE يمنع تكرارها.
-- ملاحظة تقنية: مشغّل بند 8 على user_roles يحدّث users، لذا لا يجوز أن يقرأ
-- استعلام الحذف جدول users مباشرة (خطأ 1442). نُجمّد الصفوف في جدول مؤقت أولًا.
CREATE TEMPORARY TABLE _cd006_orphan_ur AS
    SELECT ur.user_id, ur.role_id
    FROM user_roles ur
    LEFT JOIN users u ON u.id = ur.user_id
    WHERE u.id IS NULL;

SET @orphan = (SELECT COUNT(*) FROM _cd006_orphan_ur);

DELETE ur FROM user_roles ur
JOIN _cd006_orphan_ur o ON o.user_id = ur.user_id AND o.role_id = ur.role_id;

DROP TEMPORARY TABLE _cd006_orphan_ur;

INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES (
    NULL,
    'USER_CLEANUP_TEST_DATA',
    'user_roles',
    NULL,
    JSON_OBJECT('orphan_memberships', @orphan),
    'CLI'
);

COMMIT;

SELECT @deleted AS deleted_test_users, @orphan AS orphan_memberships;
