-- ============================================================
-- CD-006 / A2 — البند 5: تصحيح صلاحيات Staff (إزالة خطر branches.manage)
-- التاريخ: 2026-09-21
-- الوصف:
--   1) إزالة `branches.manage` (id=14) من دور Staff (role_id=4) — خطر أمني (منح إدارة الفروع).
--   2) منح `branches.view` (id=13) لدور Staff بدلاً منها (عرض فقط).
--   3) تسجيل الإجراء في audit_logs.
-- ملاحظة: مشغّل cd004_trg_role_permissions_ad/ai يرفع permissions_version تلقائيًا
--         لمستخدمي Staff (smutairi) عند التعديل.
-- معيار القبول: Staff = branches.view + departments.view (بلا branches.manage).
-- ============================================================

START TRANSACTION;

-- 1) إزالة branches.manage من Staff
DELETE rp FROM role_permissions rp
JOIN permissions p ON p.id = rp.permission_id
WHERE rp.role_id = 4 AND p.name = 'branches.manage';

-- 2) منح branches.view لـ Staff (idempotent)
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 4, p.id FROM permissions p WHERE p.name = 'branches.view';

-- 3) تسجيل الإجراء (نظامي — user_id NULL)
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES (
  NULL,
  'PERMISSION_REMOVED',
  'roles',
  4,
  JSON_OBJECT('migration', 'CD-006 item5', 'removed', 'branches.manage', 'added', 'branches.view'),
  'CLI'
);

COMMIT;

SELECT rp.role_id, p.id AS permission_id, p.name
FROM role_permissions rp
JOIN permissions p ON p.id = rp.permission_id
WHERE rp.role_id = 4
ORDER BY p.name;
