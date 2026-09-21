-- ============================================================
-- CD-006 / A2 — البند 4: تصحيح صلاحيات Manager (RBAC)
-- التاريخ: 2026-09-21
-- الوصف:
--   1) إنشاء صلاحيتين مفقودتين: evaluations.view.team و evaluations.create.team.
--   2) منح دور Manager (role_id=3) الصلاحيات الثلاث:
--      evaluations.view.team, evaluations.create.team, reports.view.team (id=10).
--   3) تسجيل الإجراء في audit_logs.
-- ملاحظة: مشغّل cd004_trg_role_permissions_ai يرفع permissions_version تلقائيًا
--         لمستخدمي دور Manager (kghamdi) عند إدراج role_permissions.
-- معيار القبول: Manager يملك 3 صلاحيات: evaluations.view.team, evaluations.create.team, reports.view.team.
-- ============================================================

START TRANSACTION;

-- 1) الصلاحيتان الجديدتان (INSERT IGNORE يحترم UNIQUE name → idempotent)
INSERT IGNORE INTO permissions (name, description, category) VALUES
  ('evaluations.view.team', 'عرض تقييمات الفريق', 'التقييمات'),
  ('evaluations.create.team', 'إنشاء تقييمات لفريق العمل', 'التقييمات');

-- 2) منح Manager (role_id=3) الصلاحيات الثلاث
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 3, p.id
FROM permissions p
WHERE p.name IN ('evaluations.view.team', 'evaluations.create.team', 'reports.view.team');

-- 3) تسجيل الإجراء (نظامي — user_id NULL)
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES (
  NULL,
  'PERMISSION_ADDED',
  'roles',
  3,
  JSON_OBJECT(
    'migration', 'CD-006 item4',
    'granted', JSON_ARRAY('evaluations.view.team', 'evaluations.create.team', 'reports.view.team')
  ),
  'CLI'
);

COMMIT;

SELECT rp.role_id, p.id AS permission_id, p.name
FROM role_permissions rp
JOIN permissions p ON p.id = rp.permission_id
WHERE rp.role_id = 3
ORDER BY p.name;
