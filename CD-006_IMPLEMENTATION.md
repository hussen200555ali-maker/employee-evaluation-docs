# CD-006 — سجل التنفيذ (الوحدة A2)

وفق الملاحظة الإلزامية: يُحدَّث **بعد كل بند**، لا في النهاية. تنسيق كل إدخال: الوصف، الملفات، إثبات، التاريخ.
سطر الإغلاق الإلزامي لكل بند: «البند X مكتمل — Commit Y — إثبات في القسم Z».

**نطاق CD-006:** 4 مراحل / 17 بندًا. **المرحلة 1 (البنود 1–6) فقط الآن**، ثم تقرير موجز + توقف إلزامي للاعتماد.
قواعد عامة: لا تعديل DB إلا بترحيل موثق؛ اختبار إثبات لكل بند؛ اختبار انحدار بعد كل مرحلة؛ أي اكتشاف خارج النطاق → `CD-006_OUT_OF_SCOPE.md` → CD-007.

| المرحلة | البنود | الحالة |
|---|---|---|
| 1 | 1–6 | **قيد التنفيذ** |
| 2 | 7–12 | بانتظار اعتماد المرحلة 1 |
| 3 | 13–15 | — |
| 4 | 16–17 | — |

---

## المرحلة 1 — إصلاحات A2 الأساسية

### بند 1 — تنظيف بيانات الاختبار (بقايا CD-004)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_21_A2_item1_cleanup_test_data.sql` + نسخة `CD-001_delivery/database/migrations/` |

**التنفيذ:**
- نسخة احتياطية كاملة قبل أي حذف: `mysqldump --single-transaction --routines --triggers` → `storage/backups/CD-006/2026-09-21/employee_evaluation_mvc.pre-item1.sql` (1,244,716 بايت، رأس `-- MariaDB dump 10.19 Distrib 10.4.32-MariaDB`). ✔
- ترحيل موثق داخل `START TRANSACTION`: حساب `@deleted` ثم `DELETE` على معيار `email LIKE '%@test.local' OR username LIKE 'test\_%' OR username LIKE 'cd004.%'`، ثم إدراج `audit_logs` action `USER_CLEANUP_TEST_DATA` (entity_type=`users`، details `{deleted, criteria}`، ip=`CLI`).
- **اكتشاف أثناء التنفيذ:** صف عضوية يتيم في `user_roles` (`user_id=84` بلا أب) من بقايا CD-004 أُدخل قبل تفعيل قيد FK. أُضيف تنظيفه إلى الترحيل (جدول مؤقت ثم حذف) مع إدراج تدقيق ثانٍ (entity_type=`user_roles`، details `{orphan_memberships:1}`).
- **ملاحظة تقنية:** مشغّل `permissions_version` على `user_roles` يحدّث `users`، لذا لا يجوز أن يقرأ استعلام الحذف جدول `users` مباشرة (MySQL error 1442 «Can't update table 'users' in stored function/trigger»). الحل المثبّت في الترحيل: تجميد الصفوف في جدول مؤقت `_cd006_orphan_ur` ثم الحذف بربط الجدول المؤقت فقط.

**الإثبات:**
- تطبيق الترحيل عبر `mysql -uroot --default-character-set=utf8mb4`: خروج 0، الناتج `deleted_test_users=58` ثم `orphan_memberships=1`. ✔
- فحص بعد التنفيذ: `users=4` (sysadmin/Admin، kghamdi/Manager، smutairi/Staff، fzahrani/HR)، `user_roles=4`، لا عضوية يتيمة. ✔
- سجلا تدقيق: `id=682` (entity_type=`users`, `{"deleted":58,...}`) و`id=683` (entity_type=`user_roles`, `{"orphan_memberships":1}`). ✔
- معيار القبول (يبقى 4 حسابات حقيقية فقط) متحقق. ✔

- **الإغلاق:** البند 1 مكتمل — Commit `45225b4` — إثبات في قسم «بند 1 — تنظيف بيانات الاختبار» بهذا الملف.

### بند 2 — إصلاح شاشة إنشاء المستخدم (`admin/users/create.php`)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Views/admin/users/create.php` (إعادة كتابة كاملة) |

**التنفيذ:**
- كان الملف (372 سطرًا) يحتوي markup **باني القوالب** (`form-builder-container`، `draggable-element`، `template_name`، وسكربت باني) بترميز مشوّه بدل نموذج المستخدم — شاشة الإضافة معطوبة (اكتشاف CD-005 G1).
- أُعيدت الكتابة من الصفر على نمط `admin/users/edit.php`: حقول `username`, `email`, `password`, `password_confirm`, `role_id` (إلزامي)، `employee_id` (اختياري)، مع `csrf_field()` وaction `POST /admin/users` (route `UserController@store`).
- القائمة المنسدلة للأدوار تُغذّى من `$data['roles']` (`Role::getAll()`) وقائمة الموظفين من `$data['employees']` (`Employee::getUnlinkedEmployees()`)، مع دعم إعادة تعبئة `$data['old']` إن وُجد (آمن مع null-coalescing).
- النسخة القديمة محفوظة في `_emergency/rollback/CD-006/2026-09-21/views/admin-users-create.php`.

**الإثبات:**
- `php -l`: لا أخطاء. ✔
- **Live HTTP** (Apache/MySQL) بحساب Admin مؤقت (`cd006.item2.tmp`، uid 549):
  - `GET /admin/users/create` → 200؛ الحقول المطلوبة كلها موجودة (`username`/`email`/`password`/`password_confirm`/`role_id`/`employee_id`/`_token`)، action=`/admin/users`، والقوائم تحوي الأدوار (Admin/HR/Manager/Staff) والموظفين غير المرتبطين. **لا وجود** لأي من `form-builder-container`/`draggable-element`/`template_name`. ✔
  - `POST /admin/users` (role_id=4) → أُنشئ المستخدم `cd006.item2.created` (uid 550، status=active، role_id=4) وسُجِّل `USER_CREATE` (entity_id=550، details `{username, role_id:4}`). ✔
- تنظيف: حذف الحسابين المؤقتين (549, 550) → `users=4`، `user_roles=4`. ✔

- **الإغلاق:** البند 2 مكتمل — Commit `89470e3` — إثبات في قسم «بند 2 — إصلاح شاشة إنشاء المستخدم» بهذا الملف.

### بند 3 — حماية آخر مدير نظام نشط
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Models/User.php`، `app/Controllers/Admin/UserController.php` |

**التنفيذ:**
- `User`: أُضيفت `activeAdminCount()`، `isActiveAdmin($id)`، `isLastActiveAdmin($id)` — تُعرَّف «الإدارية» ديناميكيًا عبر `Auth::adminRoleIds()` (`name='Admin' AND is_system_role=1`) بلا معرّف صريح (اتساقًا مع بند 14 من CD-004).
- `UserController`: منع في ثلاثة مسارات قبل التنفيذ:
  - `destroy()` — حذف آخر مدير نشط.
  - `toggleStatus()` — تعليقه (استجابة JSON 403).
  - `updateRole()` — خفضه إلى دور غير إداري (`!in_array($roleId, Auth::adminRoleIds())`).
  - كل محاولة: `Audit::log('LAST_ADMIN_PROTECTED', $id, 'users', ['reason' => delete|suspend|demote, 'actor_id' => ...])` + `Auth::notifyAdmins(...)` + رفض.
- `warnIfSingleActiveAdmin()` (دالة خاصة): بعد أي عملية ناجحة تُنقص عدد المدراء، إن أصبح `activeAdminCount()===1` → `Auth::notifyAdmins('تنبيه: مدير نظام واحد فقط', ...)`.

**الإثبات:**
- `php -l` للملفين: لا أخطاء. ✔
- **Live HTTP** (Apache/MySQL): حساب Admin مؤقت `cd006.item3.actor` (uid 551) بجلسة سليمة، ثم أُزيلت عضويته الإدارية من DB (محاكاة جلسة قديمة) وبقي `sysadmin` (id=1) المدير النشط الوحيد (`active_admins=1`)؛ محاولات الجلسة القديمة على `sysadmin`:
  - `POST /admin/users/delete {id:1}` → 200 (redirect) لكن **مُنعت**، `LAST_ADMIN_PROTECTED` reason=delete. ✔
  - `POST /admin/users/update-role {user_id:1, role_id:4}` → 200 لكن **مُنعت**، reason=demote. ✔
  - `POST /admin/users/toggle-status {user_id:1}` → **403** + JSON، reason=suspend. ✔
  - `sysadmin` بقي `active`/`Admin`. ✔
- **تنبيه الهبوط إلى 1:** عند هبوط العدد إلى 1 أُدرجت إشعارات `warning` بعنوان «تنبيه: مدير نظام واحد فقط» (id 608/609)، وإشعارات المنع الثلاثة (id 610/611/612). ✔
- تنظيف كامل: حذف الحسابين المؤقتين والإشعارات التجريبية → `users=4`، `user_roles=4`، `sysadmin active/Admin`. ✔
- **اكتشاف (OOS-8):** حذف مستخدم مرتبط بسجلات تقييم (`evaluations.created_by_user_id` FK `eval_fk_creator`) يرمي PDOException غير مُلتقط → HTTP 500؛ سُجِّل خارج النطاق.

- **الإغلاق:** البند 3 مكتمل — Commit `(يُحدَّث عند الإغلاق)` — إثبات في قسم «بند 3 — حماية آخر مدير نظام نشط» بهذا الملف.
