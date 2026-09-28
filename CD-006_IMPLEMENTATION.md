# CD-006 — سجل التنفيذ (الوحدة A2)

وفق الملاحظة الإلزامية: يُحدَّث **بعد كل بند**، لا في النهاية. تنسيق كل إدخال: الوصف، الملفات، إثبات، التاريخ.
سطر الإغلاق الإلزامي لكل بند: «البند X مكتمل — Commit Y — إثبات في القسم Z».

**نطاق CD-006:** 4 مراحل / 17 بندًا. **المرحلة 1 (البنود 1–6) فقط الآن**، ثم تقرير موجز + توقف إلزامي للاعتماد.
قواعد عامة: لا تعديل DB إلا بترحيل موثق؛ اختبار إثبات لكل بند؛ اختبار انحدار بعد كل مرحلة؛ أي اكتشاف خارج النطاق → `CD-006_OUT_OF_SCOPE.md` → CD-007.

| المرحلة | البنود | الحالة |
|---|---|---|
| 1 | 1–6 | **مكتملة** |
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

- **الإغلاق:** البند 3 مكتمل — Commit `0982ccd` — إثبات في قسم «بند 3 — حماية آخر مدير نظام نشط» بهذا الملف.

### بند 4 — تصحيح صلاحيات Manager (RBAC)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_21_A2_item4_manager_rbac.sql` + نسخة `CD-001_delivery/database/migrations/` |

**التنفيذ:**
- إنشاء صلاحيتين مفقودتين: `evaluations.view.team` (id=39) و`evaluations.create.team` (id=40)، الفئة «التقييمات».
- منح دور Manager (role_id=3) الصلاحيات الثلاث: `evaluations.view.team`, `evaluations.create.team`, `reports.view.team` (id=10) عبر `INSERT IGNORE INTO role_permissions`.
- تسجيل `PERMISSION_ADDED` في `audit_logs` (entity_type=roles، entity_id=3، details `{migration, granted[]}`، ip=CLI).
- مشغّل `cd004_trg_role_permissions_ai` رفع `permissions_version` تلقائيًا لمستخدمي Manager (kghamdi: 2→5) → انعاش الجلسة.

**الإثبات:**
- تطبيق الترحيل: خروج 0. **ملاحظة تشغيلية:** أول تطبيق عبر تمرير PowerShell للـstdin شوّه العربية (`?`) بسبب إعادة ترميز وحدة التحكم؛ أُعيد التطبيق عبر `mysql ... source <file>` (يقرأ الملف UTF-8 مباشرة) فظهرت الفئة «التقييمات» صحيحة.
- فحص DB: Manager = **3 صلاحيات** (ids 10,39,40)، وبقية الأدوار بلا تغيير (Admin 35، HR 2، Staff 2). ✔
- فحص تطبيقي عبر `tests/bootstrap.php` و`User::getUserPermissions(2)` → القائمة الثلاث بالضبط (`missing=[]`, `count=3`). ✔
- سجل تدقيق `PERMISSION_ADDED` (entity_id=3) موجود. ✔

- **الإغلاق:** البند 4 مكتمل — Commit `fb96fa8` — إثبات في قسم «بند 4 — تصحيح صلاحيات Manager» بهذا الملف.

### بند 5 — تصحيح صلاحيات Staff (إزالة `branches.manage`)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_21_A2_item5_staff_branches.sql` + نسخة `CD-001_delivery/database/migrations/` |

**التنفيذ:**
- إزالة `branches.manage` (id=14) من دور Staff (role_id=4) — كان خطرًا أمنيًا (منح إدارة الفروع).
- منح `branches.view` (id=13) بدلاً منها (عرض فقط).
- تسجيل `PERMISSION_REMOVED` في `audit_logs` (entity_type=roles، entity_id=4، details `{removed, added}`).
- مشغّل `cd004_trg_role_permissions_ad/ai` رفع `permissions_version` لمستخدم Staff (smutairi: 2→4).

**الإثبات:**
- تطبيق عبر `mysql ... source` (UTF-8): خروج 0.
- فحص DB: Staff = {`branches.view`, `departments.view`} بلا `branches.manage`؛ بقية الأدوار بلا تغيير (Admin 35، HR 2، Manager 3). ✔
- فحص تطبيقي: `User::getUserPermissions(3)` = `branches.view,departments.view`؛ `has_branches_manage=0`، `has_branches_view=1`. ✔
- سجل تدقيق `PERMISSION_REMOVED` (entity_id=4) موجود. ✔

- **الإغلاق:** البند 5 مكتمل — Commit `01f59fc` — إثبات في قسم «بند 5 — تصحيح صلاحيات Staff» بهذا الملف.

### بند 6 — منع تصعيد الصلاحيات في `RoleController::updatePermission`
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Controllers/Admin/RoleController.php` ، `app/Models/Role.php` (بدون ترحيل DB) |

**التنفيذ:**
- `Auth::isAdmin()` إلزامي داخل `updatePermission()`: تعديل الصلاحيات مقصور على دور Admin — يمنع تصعيدًا مستقبليًا عبر أي دور آخر يملك `roles.manage`. الرفض: 403 «تعديل الصلاحيات مقصور على مدير النظام.»
- التحقق من وجود الصلاحية بـ`Role::findPermissionById()` (دالة جديدة): غير موجودة → 404 «الصلاحية غير موجودة.»
- عند الإضافة: رفض منح صلاحية لا يملكها المُنفِّذ (`Auth::userHasPermission`) → 403 «لا يمكنك منح صلاحية لا تملكها.» (طبقة دفاع في العمق؛ والوصول إليها غير ممكن حاليًا لأن الوحدة محصورة على Admin الذي يملك كل الصلاحيات).
- حماية دور Admin الاسمية قائمة (403 «لا يمكن تعديل صلاحيات دور المدير.»).
- **Audit:** تسجيل `old`/`new` مع `permission_id`, `permission_name`, `actor_id` بدلًا من المعرّف وحده.

**الإثبات (Live HTTP — حسابات مؤقتة `cd006.item6.*` ثم حُذفت):**
- A: Admin يضيف `users.view` إلى دور مؤقت → **200** `{"success":true}`؛ DB: أُضيفت؛ audit `PERMISSION_ADDED` `{permission_id:1, permission_name:users.view, old:false, new:true, actor_id:553}`.
- B: Admin يزيلها → **200**؛ DB: حُذفت؛ audit `PERMISSION_REMOVED` `{... old:true, new:false}`.
- C: Admin يحاول تعديل صلاحيات دور Admin نفسه → **403** «لا يمكن تعديل صلاحيات دور المدير.»
- D: Admin يُدخل صلاحية غير موجودة (99999) → **404** «الصلاحية غير موجودة.»
- E: مستخدم (صاحب دور مؤقت يملك `roles.manage`) يحاول الإضافة → **403** «تعديل الصلاحيات مقصور على مدير النظام.» مع عدم تغيير في DB.
- `php -l` نظيف للملفّين. ✔
- **التنظيف:** users=4، user_roles=4، roles=4، permissions=38، وتوزيع الصلاحيات كما هو (Admin 35 / HR 2 / Manager 3 / Staff 2). ✔
- **الرجوع:** `_emergency/rollback/CD-006/2026-09-21/controllers/admin-role-controller.php` + `.../models/role.php`.

- **الإغلاق:** البند 6 مكتمل — Commit `901c55a` — إثبات في قسم «بند 6 — منع تصعيد الصلاحيات» بهذا الملف.

### بند 7 — تفعيل صلاحيات `users.*` في حارس `UserController`
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-28 |
| الحالة | **معتمد من كبير المستشارين (توقيع 2026-09-28)** — التنفيذ مُعتمد: «البند 7: معتمد. تنفيذ ممتاز» |
| مرجع التفصيل | نص البند 7 الكامل المعتمد (توقيع كبير المستشارين 2026-09-28) — «البند 7 ≠ FK: البند 7 = تفعيل صلاحيات users.*. البند 12-b = FK + حذف مستخدم» |
| الهدف | تحويل حارس `UserController` من `Auth::is('Admin')` إلى `Auth::can('users.*')` |
| الملفات | `app/Controllers/Admin/UserController.php` + `app/Views/layouts/header.php` |

**قاعدة الإنتاج المثبتة:** `employee_evaluation_mvc` (قرار المستشار — المصدر `config/database.php` الرسمي؛ `employee_evaluation` غير موجودة — خطأ 1046).

**قرارات المخطّط المعتمدة قبل التنفيذ (استشاري):**
- `Auth::can()` ينفّذ `forbidden()` + `exit` — غير صالح في بناء القوائم، لذا `header.php` يستخدم `Auth::userHasPermission()` اتساقًا مع النمط الموجود (L373).
- **ترحيل `permissions_version`: تمّ التخطي** — الشرط المشروط تحقق: `Auth::permissionsNeedRefresh()` يعمل كل 60 ثانية بقراءة `users.permissions_version` من DB فعليًا (`Auth.php` L464–480، `PERMISSIONS_VERSION_CACHE_SECONDS = 60`) فتُبطَل الجلسات تلقائيًا بلا ترحيل.

**التنفيذ:**
- `__construct`: `if (!Auth::is('Admin')) { forbidden(); exit; }` → `Auth::can('users.view');` (بقيت حماية آخر Admin من البند 3 داخل `destroy`/`toggleStatus`/`updateRole` دون مساس).
- حارس لكل عملية داخل دالتها: `create`+`store` → `users.create`، `edit`+`update`+`updateRole`+`toggleStatus`+`resetPassword` → `users.edit`، `destroy` → `users.delete` (9 مواضع إجمالًا).
- `header.php`: رابط «إدارة المستخدمين/الأدوار» نُقل خارج كتلة «الإعدادات» (التي تشترط `templates.manage`/`settings.manage`/`backup.manage`) إلى قائمة مستقلة مشروطة بـ`Auth::isAdmin() || Auth::userHasPermission('users.view')` — وإلا لم يظهر لمن يملك `users.view` وحدها. الاستعلام بالدالة المستقلة `userHasPermission` لا `can()` (لأن `can()` فيه `exit`).

**الإثبات (Live HTTP — Apache + MySQL، قاعدة `employee_evaluation_mvc`):**
- **سيناريو A — Admin (bypass):** GET `/admin/users` = **200**، `/admin/users/create` = **200**، `/admin/users/edit/3` = **200** — بلا تغيير.
- **سيناريو B — دور يملك `users.view` فقط:** GET `/admin/users` = **200** (يرى القائمة)، و`/admin/users/create` = **403**، `/admin/users/edit/3` = **403**، POST `delete` = **403**، POST `update-role` = **403**، POST `toggle-status` = **403**، POST `reset-password` = **403**، POST `store` = **403**.
  - فحص DB بعد المحاولات المرفوضة: `users=30` (بلا زيادة)، `smutairi` `status=active` و`permissions_version=4` (بلا تغيير)، `user_roles(3)={4}` (بلا تغيير)، `hack_users=0`.
- **سيناريو C — bypass لـ Admin:** `Auth::userHasPermission()` يعمل short-circuit عبر `isAdmin()` فيعيد `true` فورًا قبل فحص الجلسة، وهذا هو ما أثبته السيناريو A (200 على `users.create`/`users.edit` وهما ممنوحتان لـ Admin وحده).
- **سيناريو D — دور بلا `users.*` (Staff):** GET `/admin/users` = **403**، ورابط المستخدمين **غير موجود** في صفحته (يُقارن بـ`viewer` الذي ظهر له الرابط مرة واحدة).
- **header.php:** `viewer` (users.view فقط) = ظهور الرابط **1** مرة، `admin` = **1** مرة (بلا تكرار) — بعد نقل الكتلة.
- `php -l` نظيف على الملفين المعدَّلين.
- بيانات الاختبار المؤقتة حُذفت بالكامل: `users` 32 → **30**، الأدوار 5 → **4**، `permissions=38` (بلا تغيير) — بلا أثر متبقٍ.

- **الحدود المُلتزَمة:** لا دور جديد ✔ · لا تعديل مصفوفة الصلاحيات ✔ (`permissions=38` قبل/بعد) · لا مسّ FK ✔ (`eval_fk_creator` RESTRICT كما هو — البند 12-b بعد CP2).
- **نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-28/admin-user-controller.pre-item7.php` + `.../layouts-header.pre-item7.php`.
- **توثيق متقاطع مُحدَّث (late sync):** `A2_Users_Roles_Unit_Documentation.md` (9 مواضع: جدول الحارس L35، جدول المتحكم L70، جدول المسارات L94–102، تحليل الحارس L151–154، جدول قواعد الأمان L235، جدول نقاط القوة L274، فجوة «الصلاحيات غير مستخدمة» L294، فجوة reachability الأدوار L305، جدول الملفات L377–378) و`13_Security.md` (ثغرة «تجاوز الحارس» — تُعلَّم كمُغلَقة). قبل ذلك كانت توثيق A2 تصف الحارس القديم `Auth::is('Admin')` فكانت تتعارض مع الكود المُنفَّذ.
- **تقرير التسليم:** `CD-006_Phase2_Item7_Report.md` + `CD-006_Phase2_Item7_Report.pdf` (موقّع، 2026-09-28) — يتضمّن جدول أسطر الحُرّاس التسعة المتحقَّق منه،Discovery المعماري (نقل القائمة خارج كتلة الإعدادات L373–413 → L415–435)، وتنبيهين ترقيمين: (1) إثبات آخر Admin بفحص الكود لا بتركيب قاعدة معزولة، (2) **ليس** تقرير CP2.
- **فجوة متبقية مُبلَّغ عنها دون تنفيذ (خارج نطاق البند 7):** رابط `/admin/roles` (L429) صار داخل قائمة `users.view`، فمن يملك `users.view` دون `roles.manage` يراه ويصطدم بـ403، ومن يملك `roles.manage` بلا صلاحيات الإعدادات لا يجده. سُجِّلت كفجوة `#13` في وثيقة A2، والقرار مطلوب من المستشار (ربط الرابط بـ`roles.manage`؟).

- **الإغلاق:** البند 7 مكتمل — Commit `f44d525` (`feat(A2.7): …`) — إثبات في قسم «بند 7 — تفعيل صلاحيات users.*» بهذا الملف.

### قرارات كبير المستشارين على نتائج البند 7 (2026-09-28)

| # | السؤال المُطرح | القرار | الموضع |
|---|---|---|---|
| Q1 | تعارض `OOS-8` (حذف مستخدم مرتبط بسجلات تقييم) مع «البند 12-b» | **12-b هو الصحيح** — `OOS-8` مشطوب في `CD-006_OUT_OF_SCOPE.md` بإشارة «نُقل إلى البند 12-b» | البند 12-b (بعد CP2) |
| Q2 | ربط رابط `/admin/roles` بـ`roles.manage` بدل إبقائه داخل قائمة `users.view` | **يُنفَّذ ضمن البند 11** — لا تنفيذ في البند 7 (خارج نصّه) | البند 11 |
| Q3 | التحقق من بقايا بيانات الاختبار (مرجع 58 حسابًا) وتنظيفها عند الحاجة | **يُنفَّذ ضمن البند 11** | البند 11 |
| Q4 | إثبات حماية آخر Admin بفحص الكود (لا Live معزول) | **مقبول** — «إثبات بالكود + عدم المساس» | البند 7 (مُغلق) |
| Q5 | `OOS-1` (Admin يفتقد `positions.manage`) | يبقى مؤجلًا إلى **CD-007** | CD-007 |

**نقطة التوقف الإلزامية (2026-09-28):** بعد البند 10 → إرسال **تقرير CP2** + توقف إلزامي. لا بدء البنود 11–12-b قبل الاعتماد.

### بند 8 — تدقيق القيم القديمة/الجديدة في سجل التدقيق

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-28 |
| الحالة | **مُنفَّذ ومُثبَت Live — بانتظار اعتماد المستشار** |
| الهدف | أن يُظهر `audit_logs` **ما الذي تغيّر** (قيمة قديمة + جديدة) لا **ما الذي حدث** فقط |
| الملفات | `app/Controllers/Admin/UserController.php` + `app/Controllers/Admin/RoleController.php` — **و`app/Core/Audit.php` بلا تعديل** |
| الترحيل | **لا ترحيل DB** — `details` عمود `text` موجود أصلًا |

**اكتشاف مُسبق (لم يتغيّر `Audit.php`):** `Audit::log($action,$entityId,$entityType,$details=[])` يستقبل `details array` ويحوّلها إلى JSON في `Audit.php:18`، ويكتب العمود في `Audit.php:33`. أي أن البند 8 مسألة **مراسِل** فقط: من كان يرسل `old/new` بشكل خاطئ أو ناقصًا.

**قرارات المخطّط المعتمدة قبل التنفيذ (استشاري):**
- **أسماء الإجراءات لا تُوحَّد:** يبقى `USER_ACTIVATED` و`USER_SUSPENDED` كما هما مع إضافة `old`/`new` (لا `USER_STATUS_CHANGE`) — قرار المستشار.
- **شكل الصلاحيات يُستبدل بالكامل:** `PERMISSION_ADDED` = `old:null` + `new:{role_id,permission_id}`، و`PERMISSION_REMOVED` = `old:{role_id,permission_id}` + `new:null` (بدل `old/new` booleans)، مع بقاء `permission_name` و`actor_id` أعلى المستوى. حارس CSRF في `RoleController::updatePermission` يقرأ `$_POST['csrf_token'] ?? $_POST['_token']` (نمط بند 6) ويقبل أيضًا ترويسة `X-CSRF-Token` عبر `public/index.php:37` — فمسار JSON يمرّ دون تعطيل الحارس.
- **`RoleController::update`** كان يمرّر `false` كقيمة `old` — تصحيح إلى null.

**التنفيذ:**
- `UserController::updateRole` — كان `['new_role_id' => $roleId]` فقط؛ صار يجلب الدور القديم **قبل** `updateRole` (لأن `User::updateRole` يحذف كل الأدوار ثم يُدرج الجديد) عبر `\App\Core\Database::getInstance()` → `SELECT role_id FROM user_roles WHERE user_id=:id LIMIT 1`، ثم `Audit::log('USER_ROLE_UPDATE', …, ['old'=>['role_id'=>$old], 'new'=>['role_id'=>$new]])`.
- `UserController::toggleStatus` — كان بلا `details`؛ صار يلتقط `status` القديم من `findById($userId)->status` قبل التغيير، ويسجّل `['old'=>['status'=>$old], 'new'=>['status'=>$new]]` تحت الإجراء نفسه (`USER_ACTIVATED`/`USER_SUSPENDED`).
- `RoleController::updatePermission` — `old`/`new` من booleans إلى كائنَي `{role_id, permission_id}` (أو `null` للطرف المقابل).
- `RoleController::update` — الوصف القديم من `findById($id)->description` قبل `updateRole`، بدل تمرير `false` كـ`old`.

**الإثبات (Live HTTP — Apache + MySQL، قاعدة `employee_evaluation_mvc`):**
- التهيئة: مستخدم فاعل بدور `Admin` + هدف منفصل لتغيير الدور + هدف منفصل لتبديل الحالة + دوران مؤقتان (`A2Item8_RoleA`=47، `A2Item8_RoleB`=48) + صلاحية `users.view` (id=1). طلبات POST مرّت بحارس CSRF في `public/index.php:37` بترويسة `X-CSRF-Token` المسحوبة من `_token` في نموذج الدخول.
- **6 عمليات → كلّها HTTP 200**، وسجلات `audit_logs` الناتجة:

| الإجراء | السجل | `details` الفعلية |
|---|---|---|
| `USER_ROLE_UPDATE` | #763 | `{"old":{"role_id":47},"new":{"role_id":48}}` |
| `PERMISSION_ADDED` | #729 | `{"permission_id":1,"permission_name":"users.view","old":null,"new":{"role_id":47,"permission_id":1},"actor_id":648}` |
| `PERMISSION_REMOVED` | #730 | `{"permission_id":1,"permission_name":"users.view","old":{"role_id":47,"permission_id":1},"new":null,"actor_id":648}` |
| `ROLE_UPDATE` | #764 | `{"old":{"description":"وصف أولي A"},"new":{"description":"وصف بعد التعديل - بند 8"}}` |
| `USER_SUSPENDED` | #732 | `{"old":{"status":"active"},"new":{"status":"suspended"}}` |
| `USER_ACTIVATED` | #733 | `{"old":{"status":"suspended"},"new":{"status":"active"}}` |

- **فحص آلي للأشكال:** 7/7 صفوف `old/new` مطابقة للقواعد أعلاه (الأسماء، الاتجاه، `permission_name` أعلى المستوى). كل الصفوف `utf8=valid` (فحص `mb_check_encoding` على البايتات) — لا تشويش ترميز.
- **`Audit.php` = 0 سطر تغيير** (`git diff --numstat`) — لم يُمسّ. `php -l` نظيف على الملفات الثلاثة.
- **السجلات التاريخية سليمة:** `id <= 726` = **246 صفًا** كما قبل التنفيذ بالضبط (بلا إعادة كتابة). صفوف الإثبات الجديدة (38 صفًا، `id 727–764`) باقية كدليل.
- **التنظيف:** `users` 33 → **30**، `roles` 6 → **4**، `permissions=38` (بلا تغيير)، `user_roles` بلا أي يتيم (0)، `sysadmin` ما زال نشطًا، صلاحيات دور Admin = 35 (بلا تغيير).

**الحدود المُلتزَمة:** لا ترحيل DB ✔ · لا تعديل/حذف السجلات القديمة ✔ · لا تعديل توقيع `Audit::log()` ✔ · لا توحيد أسماء الإجراءات ✔ (قرار المستشار) · لا تعديل `Audit.php` ✔.

**الإغلاق:** البند 8 مُنفَّذ — Commit التسليم `93294f0` + Commit التطبيق `bcb12a7` (`feat(A2.8): تدقيق القيم القديمة/الجديدة في سجل التدقيق`). الإغلاق إلى commit التوثيق: `93294f0`.

### بند 9 — ذرّية استبدال الأدوار في `User::updateRole`

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-28 |
| الحالة | **مُنفَّذ ومُثبَت باختبار وحدة — بانتظار اعتماد المستشار** |
| الخطر المُعالَج | `DELETE` بلا معاملة: لو فشل `INSERT` بعد نجاح الحذف، **يبقى المستخدم بلا دور نهائيًا** |
| الملفات | `app/Models/User.php` (دالة `updateRole` فقط) + `tests/cases/Models/UserTest.php` (جديد) |
| الترحيل | **لا ترحيل DB** |

**اكتشاف مُسبق حوّل التصميم:** `user_roles` يحمل القيد `user_roles_ibfk_2 FOREIGN KEY (role_id) REFERENCES roles(id)`، لذا `role_id=999` **يرمي `PDOException` فعلًا (SQLSTATE 23000 / errno 1452)** — فكان اختبار الرول‑باك ممكنًا وحاسمًا بلا تحقق مسبق. كما أن `Database` تملك أصلًا `beginTransaction`/`commit`/`rollBack` (L101–117) و`getPdo()` (L121)، و`Model::$db` هو `Database::getInstance()` نفسه ⇒ المعاملة تغطي الاستعلامين فعليًا.

**التنفيذ** (`app/Models/User.php` — `updateRole`):
- `$pdo = \App\Core\Database::getInstance()->getPdo()` ثم `beginTransaction()`.
- `DELETE FROM user_roles WHERE user_id=:user_id` ثم `INSERT INTO user_roles (user_id, role_id) …` ثم `commit()` ⇒ `return true`.
- `catch (PDOException)`: `if ($pdo->inTransaction()) { $pdo->rollBack(); }` — التراجع **يُرجع الصف المحذوف** فيحتفظ المستخدم بدوره القديم؛ ثم `SELECT id FROM roles WHERE id=:id`:
  - الدور غير موجود ⇒ `return false` (نمط باقي الدوال، بلا استثناء).
  - الدور موجود ⇒ `throw $e` (أي خطأ آخر يُعاد كما كان، بلا إخفاء).

**قرارات المستشار (2026-09-28):**
- **FK + catch/rollback فقط** بلا تحقق مسبق — ليبقى الـrollback مُختبَرًا فعليًا ويطابق اسم الاختبار المطلوب حرفيًا.
- **بلا Audit عند الفشل** — نص البند 9 لا يطلبه ويقول «لا نُعدّل Audit (البند 8 انتهى)»، والبند 10 وحده يطلب `USER_CREATE_BLOCKED_*`. ⇒ **فجوة مُوثَّقة في تقرير CP2** للمراجعة في CD-007+.
- `Database.php` و`createUser` و`Audit.php` **بلا مساس**.

**الإثبات (اختبار وحدة على `employee_evaluation_mvc`):**
- ملف جديد `tests/cases/Models/UserTest.php` (3 حالات) — يكتشفه `tests/runner.php` تلقائيًا (نمط `*Test.php`)، وكل حالة تنشئ بيانات مؤقتة وتُنظّفها في `tearDown()`.
- `testUpdateRoleRollsBackOnInvalidRole` (الاختبار الحاسم): يمنح المستخدم دورًا مؤقتًا، ثم يمرّر `role_id=999`، ويؤكد ثلاثًا: (أ) `assertFalse` بلا استثناء، (ب) `SELECT role_id FROM user_roles WHERE user_id=X` **ما زال مُساويًا للدور القديم**، (ج) لا صف بدور غير موجود.
- `testUpdateRoleSucceedsForValidRole` و`testUpdateRoleReplacesAllPreviousRoles` (مستخدم بدورين يصبح له دور واحد — يثبت عدم تغيّر السلوك السليم).
- **النتيجة: 3/3 نجح.**
- **إثبات أن الاختبار يكتشف العيب فعليًا (شغل حاسم):** بعد `git stash` مؤقت لإلغاء الإصلاح، فشل الاختبار بخطأ:
  `SQLSTATE[23000]: Integrity constraint violation: 1452 Cannot add or update a child row: a foreign key constraint fails (user_roles, CONSTRAINT user_roles_ibfk_2 …)` عند `Database.php:66`
  — أي أن الكود القديم يرمي استثناءً غير ملتقط **بعد أن يكون `DELETE` قد نُفِّذ بالفعل** (والمستخدم بلا دور)، وهو الخطر الموصوف في البند. بعد `git stash pop` رجع 3/3.
- `php -l` نظيف على الملفين.
- **لا انحدار:** تشغيل `tests/runner.php` كاملًا أعطى **النتيجة نفسها قبل وبعد** التغيير (مقارنة بخط أساس على الكود القديم: `AuthTest 57/58` · `DatabaseTest 4/5` · `HelpersTest 2/3` · `NotificationTest 13/13`).
- **حالة DB بعد الاختبارات:** `users=30`, `roles=4`, `user_roles=20`, `permissions=38`, `employees=27`, `audit_logs=284` (بلا تغيير) · بلا يتام في `user_roles` · `sysadmin` نشط · صلاحيات Admin=35.

**ملاحظة جانبية (خارج نطاق البند 9، مُبلَّغ):** `AuthTest` (58 اختبارًا، 11.9 ثانية) **يُنشئ ~14 حساب `cd004.*@test.local` في كل تشغيل ولا ينظّفها** — 26 حسابًا متراكمًا من تشغيلات سابقة (2026-09-21/23) قبل أن أبدأ، و52 حسابًا أنشأتها تشغيلاتي (4 تشغيلات) حذفتُها كلها فورًا لاستعادة خط الأساس بالضبط. هذا **يؤكد قرار المستشار Q3 (تنظيف بقايا بيانات الاختبار في البند 11)** ويجعلها أولوية فيه. كما أن `RouterTest` يُسقط المشغّل بخطأ `View 'errors/404' does not exist.` فيمنع بقية الملفات (ومنها `UserTest`) من التنفيذ ضمن التشغيل الكامل — **خطأ سابق قائم**، لذلك كان إثبات البند 9 عبر `runner.php UserTest` مباشرة.

**الحدود المُلتزَمة:** لا تغيير لبنية `user_roles` ✔ · لا تعديل `createUser` ✔ · لا تغيّر سلوك `updateRole` في الحالات العادية ✔ · لا تعديل `Audit` ✔ · لا ترحيل DB ✔.

**الإغلاق:** البند 9 مُنفَّذ — Commit التسليم `a3dbc07` + Commit التطبيق `1a7f650` (`feat(A2.9): ذرّية استبدال الأدوار في User::updateRole`). الإغلاق إلى commit التوثيق: `c4096fc`.

### بند 10 — بوابات التحقق المرجعي قبل إنشاء المستخدم

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-28 |
| الحالة | **مُنفَّذ ومُثبَت بأربعة سيناريوهات Live — بانتظار اعتماد المستشار** |
| الملف | `app/Controllers\Admin/UserController.php` (دالة `store()` فقط — +42 سطرًا، **إضافة فقط** بلا حذف) |
| الترحيل | **لا ترحيل DB** · بلا تعديل `User`/`Role`/`Employee`/`Audit`/`Database` |

**التنفيذ** — ثلاث بوابات تُدرَج بعد سياسة كلمة المرور وقبل `createUser`، كل بوابة: فحص ⇒ عند الإخفاق تسجيل Audit + `Flash` + إعادة توجيه + `exit`:
1. `Role::findById($data['role_id'])` ⇒ فاشل: `USER_CREATE_BLOCKED_INVALID_ROLE` + «الدور المحدد غير موجود.»
2. `Employee::findById($data['employee_id'])` (عند إرسال `employee_id` فقط) ⇒ فاشل: `USER_CREATE_BLOCKED_INVALID_EMPLOYEE` + «الموظف المحدد غير موجود.»
3. `SELECT id FROM users WHERE employee_id = :emp_id LIMIT 1` (نفس نمط `Database` المستخدم في البند 8) ⇒ موجود: `USER_CREATE_BLOCKED_EMPLOYEE_TAKEN` + «هذا الموظف مرتبط بحساب مستخدم آخر.» مع `linked_user_id`.
- `entity_id = null` في الأحداث الثلاثة (لا كيان أُنشئ)، و`user_id` = المنفِّذ الفعلي (السجل يخزّن `Auth::id()`)، والرسائل الثلاث **موحّدة** ومطابقة لقرار المستشار.
- `role_id` الفارغ/0 ⇒ `(int)0` ⇒ `findById(0)` فاشل ⇒ رسالة «الدور المحدد غير موجود.» (مطابق لقرار المستشار).
- `Audit::log` يبتلع استثناءاته بنفسه، فلا تعطّل البوابات ولا التسلسل.

**توصيف دقيق للأثر (مُقاس، لا مُفترَض):** القيود في قاعدة البيانات (`user_roles_ibfk_2` و`users.employee_id UNIQUE`) كانت **منع الصفوف السيئة أصلًا** — فلم يحدث تلف بيانات في الحالات الثلاث **قبل** البوابات ولا بعدها. قيمة البند 10 ليست «منع تلف» بل: (أ) **رسالة صحيحة ومحددة** بدل رسالة مضلِّلة، و(ب) **أثر تدقيق** يتيح تتبّع المحاولة المرفوضة. وهذا فرق مهم عن البند 9 الذي كانت خسائر حقيقية (مستخدم بلا دور).

**الشغل الحاسم — سلوك الكود قبل البوابات (مُثبَت بتشغيل موازٍ):** بعد `git stash` مؤقت للبوابات، على حالة نظيفة:
- `role_id=999` ⇒ HTTP 200 · **0 صف تدقيق** · لا مستخدم · رسالة **مضلِّلة** «فشل إنشاء المستخدم. قد يكون اسم المستخدم أو البريد الإلكتروني مستخدماً بالفعل.» (سببها الحقيقي دور غير موجود).
- `employee_id=1` (مرتبط بـ sysadmin) ⇒ HTTP 200 · **0 صف تدقيق** · لا مستخدم · **نفس الرسالة المضلِّلة**.
- بعد إعادة تطبيق البوابات: رسالة محدّدة + **صف تدقيق مخصّص** في كل حالة. ⇒ البوابات حاملة للأثر، والشمسان معطّلان قبلها.

**الإثبات — 4 سيناريوهات Live على `http://localhost/employee-evaluation` (قاعدة الإنتاج `employee_evaluation_mvc`):**
- فاعل الاختبار: حساب إداري مؤقت `a2i10.actor@test.local` بدور Admin (يملك `users.create`، تحقّقتُ من الصلاحية في DB) بُني مباشرة في DB بكلمة مرور `password_hash` ثم حُذف.
- الجلسات بـ cookie jar مع CSRF: الرمز من `<meta name="csrf-token">` في تخطيط الصفحة، ويُرسل كـ`_token`.
- **تعلّم منهجيان (عيب في السكربت لا في المنتج):** (1) توكن ما قبل الدخول يبطل بعد الدخول، (2) توكنات جدول `csrf_tokens` **لمرة واحدة** (`used=1` بعد التحقق، `Auth.php:174`) ⇒ يلزم جلب رمز جديد **قبل كل** POST. أول تشغيل فشلت فيه S1 لهذا السبب فقط (رُفضت بـCSRF وحوّلت إلى `/evaluations/excel/import`)، ولم يُعد الأمر بعد التصحيح.

| # | `role_id` | `employee_id` | HTTP | الرسالة | حدث التدقيق | مستخدم أُنشئ |
|---|---|---|---|---|---|---|
| S1 | `999` (غير موجود) | `3` | 200 | «الدور المحدد غير موجود.» | `USER_CREATE_BLOCKED_INVALID_ROLE` · `{"username":"a2i10.s1@test.local","role_id":999}` | **0** ✔ |
| S2 | `4` | `999999` (غير موجود) | 200 | «الموظف المحدد غير موجود.» | `USER_CREATE_BLOCKED_INVALID_EMPLOYEE` · `{"username":"a2i10.s2@test.local","employee_id":999999}` | **0** ✔ |
| S3 | `4` | `1` (مرتبط) | 200 | «هذا الموظف مرتبط بحساب مستخدم آخر.» | `USER_CREATE_BLOCKED_EMPLOYEE_TAKEN` · `{"username":"a2i10.s3@test.local","employee_id":1,"linked_user_id":1}` | **0** ✔ |
| S4 | `4` | `4` (متاح) | 200 | «تم إنشاء المستخدم الجديد بنجاح.» ⇒ `/admin/users` | `USER_CREATE` · `entity_id=824` | **1** ✔ مع `role_id=4` و`employee_id=4` |

- **صفوف التدقيق المُنشأة:** `811` دخول + `812`–`815` السيناريوهات الأربعة (المنفّذ `823`)، وتحققتُ من `role_id=4` و`employee_id=4` على المستخدم المنشأ.
- **التنظيف:** حُذف حسابا الاختبار (الفاعل + المنشأ) ⇒ `a2i10.%` = 0 مستخدم و0 صف `user_roles`. **أُبقيت صفوف التدقيق كإثبات** (تسجيل إلحاقي) على النمط نفسه الذي اتُّبع في البند 8.
- **حالة DB النهائية:** `users=30`, `roles=4`, `user_roles=20`, `permissions=38`, `employees=27`, `audit_logs=289` (=284 + 5 إثبات) · بلا يتام · `sysadmin` نشط · صلاحيات Admin=35 · **السجلات التاريخية `id<=726` = 246 سليمة**.
- `php -l` نظيف · **بلا انحدار:** `UserTest` 3/3 (لم يتغيّر سلوك `updateRole`) · `git diff --stat` = ملف واحد · +42/−0.

**الحدود المُلتزَمة:** لا تعديل `User`/`Role`/`Employee`/`Audit`/`Database` ✔ · لا ترحيل DB ✔ · السلوك الناجح لم يتغيّر (S4 ينجح بالبوابات وبدونها) ✔ · إضافة فقط داخل `store()` ✔.

**الإغلاق:** البند 10 مُنفَّذ — Commit التسليم `dac9e06` + Commit التطبيق `792d6c9` (`feat(A2.10): بوابات التحقق المرجعي قبل إنشاء المستخدم`). الإغلاق إلى commit التوثيق: (هذا commit).

---

## المرحلة 3 (البنود 11–12-b) — بعد اعتماد CP2 (2026-09-29)

**Guardrail:** «الترتيب: 11-a → 11-b (7 خطوات) → Commit → 12 → 12-b → انحدار → CP3. البند كاملًا قبل الانتقال للذي يليه. بعد 12-b: تقرير CP3 + توقف إلزامي.»

### البند 11 — توحيد + تنظيف + أتمتة

#### 11-a — رابط `/admin/roles` محكوم بـ `roles.manage` (مستقل عن `users.view`)

**العيب المكتشف (بالفحص لا بالتخمين):** في `app/Views/layouts/header.php` كان الشرط الواحد
`<?php if (Auth::isAdmin() || Auth::userHasPermission('users.view')): ?>`
يلفّ قائمة «المستخدمون» كاملةً، وكان `<li>` رابط «إدارة الأدوار» **داخلها**. النتيجة قبل التعديل:

| الحالة | يرى `/admin/users` | يرى `/admin/roles` | الحكم |
|---|---|---|---|
| `users.view` فقط | نعم | **نعم (خطأ)** | يرى ما لا يملك صلاحيته |
| `roles.manage` فقط | لا | **لا (خطأ)** | لا يرى ما يملك صلاحيته |

فالقائمة الواحدة كانت تخلط صلاحية إدارة المستخدمين بإدارة الأدوار.

**التنفيذ (فكّ الالتفاف إلى كتلتين مستقلتين، إضافة/تعديل 13/−1 سطرًا في ملف واحد):**
1. كتلة «إدارة المستخدمين» تبقى تحت `Auth::isAdmin() || Auth::userHasPermission('users.view')` كما كانت (بلا تغيير دلالي).
2. كتلة «إدارة الأدوار» رُفعت إلى `<li class="nav-item dropdown">` مستقل بمعرّف `rolesDropdown` (تفاديًا لتكرار `id` في DOM) تحت `Auth::isAdmin() || Auth::userHasPermission('roles.manage')`.
3. لم يُلمس `RoleController` (حدّ البند) ولم تُنشأ صلاحية جديدة (حدّ البند).

**معايير القبول 1 و2 و7 — إثبات Live على `/dashboard` (3× HTTP 200):**

| السيناريو | المستخدم | `/admin/users` | `/admin/roles` | الحكم |
|---|---|---|---|---|
| `users.view` فقط | `a2i11.view` | **True** | **False** | ✔ لا يرى رابط الأدوار |
| `roles.manage` فقط | `a2i11.roles` | **False** | **True** | ✔ يرى رابط الأدوار |
| Admin | `a2i11.admin` | **True** | **True** | ✔ يرى الاثنين |

**إثبات حاسم بـ `git stash` (على نمط البند 9):** بعد `git stash push` لملف `header.php` وحده (تحقّق: `rolesDropdown` غير موجود + `stash@{0}` محفوظ)، أُعيد تشغيل سيناريو `roles.manage` فقط على **الكود القديم** فأعطى: `/admin/roles=False`. ثم `git stash pop` (تحقّق: `rolesDropdown` موجود + `stash` فارغ) وأُعيد التشغيل ⇒ `True`. ⇒ **العيب سببه هذا الشرط الواحد، والتعديل هو ما يُصلحه.**

**منهجية الإثبات:** لم أحدّث كلمة مرور `sysadmin` الحقيقي؛ بل أُنشئ مستخدم مؤقت بدور `Admin` لأن `Auth::isAdmin()` = `hasRole('Admin')` أي قائم على الدور لا على الحساب. والمواد المُنشأة: الأدوار 72 `A2_ITEM11_USERVIEW` (صلاحية 1 `users.view`)، 73 `A2_ITEM11_ROLESMGR` (صلاحية 5 `roles.manage`)؛ المستخدمون 831/832/833. **التنظيف تم بالكامل:** حُذفت `user_roles` ثم `users` ثم `role_permissions` ثم `roles`، ومعها `audit_logs`/`login_attempts`/`notifications` المرتبطة، + حدث `USER_CLEANUP_TEST_DATA` في `audit_logs` يوثّق المعرّفات 831/832/833. **البقايا = 0** و`users` عاد إلى **30**.

**الحدود المُلتزَمة:** لا تعديل `RoleController` ✔ · لا صلاحيات جديدة ✔ · لا تعديل `RouterTest` ✔ · لا معالجة صيني `admin-reports/create.php` ✔.

**الفحوص:** `php -l` نظيف ✔ · UTF-8 سليم ✔ · فحص المحارف الدخيلة (CJK/Cyrillic/Hangul/Kana + خلط لاتيني داخل عربي) = **CLEAN** ✔ · **الحدود:** ملف واحد `+13/−1` ✔.

**نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-29/header.pre-item11.php` — SHA1 `8551BF0E18DECB12361B8113452E679D59DF4E75`.

**الإغلاق:** 11-a مُنفَّذ ضمن `c2e8225` — انظر سطر الإغلاق الختامي في قسم 11-b.

#### 11-b — تنظيف بيانات الاختبار + إصلاح جذر تسرّب `AuthTest` + أداة فحص الترميز + إصلاح U+FFFD

**أ) تنظيف 26 حسابًا متسربًا (11-b/1):** حُدد 26 صفًا في `users` خارج المعرّفات الحقيقية 1/2/3/6، وكلها بنمط `cd004.%@test.local` (صفر بنمط `test_*` أو `cd006.*`) ⇒ لا لبس في النطاق. بوابة `FOREIGN_KEY_CHECKS` (مفعّلة خارج المعاملة) أثبتت أن `evaluations.created_by_user_id` لهذه = 0. المقاسات قبل الحذف: `user_roles=16`، `notifications=116`، `csrf_tokens=2`، `audit_logs=0`. حُذفت داخل Transaction واحدة (الجداول الأبناء أولًا ثم الأب) ⇒ `users=4`، `user_roles=4`، يتامى `user_roles=0`. الحدث `USER_CLEANUP_TEST_DATA` (المعرّف 827) في `audit_logs` يوثّق العملية، وسجلّ `audit_logs` التاريخي `id<=726` (246 صفًا) لم يُمَس.

**ب) جذر تسرّب `AuthTest` — خطآن مستقلان لا واحد (11-b/2 و 11-b/3):**

1. **نقص التسجيل (السبب الظاهر):** كان `$this->seededUsernames[] = $username` مطبَّقًا في **موضع واحد من 18** موضع بذر. فكانت `cleanupStatusUsers()` تخرج مبكرًا عند `if ($usernames === [])` في 17 حالة، فلا تحذف شيئًا.
2. **السبب الجذري الحقيقي — خطأ MySQL 1442 (لم يكن نقص تسجيل):** بعد إصلاح التسجيل اختفت حالة «لا شيء يُحذف»، **لكن** ظهر خطأ حاسم أثناء التشغيل:
   `SQLSTATE[HY000] 1442 Can't update table 'users' in stored function/trigger because it is already used by statement which invoked this stored function/trigger`.
   **السبب:** الـ trigger `cd004_trg_user_roles_ad` (من بنية CD-004) ينفّذ `UPDATE users SET permissions_version = permissions_version + 1 …` عند **كل** حذف من `user_roles`، والتنظيف كان يحذف `user_roles` بجملة **تستعلم `users` في الوقت نفسه** (`… WHERE user_id IN (SELECT id FROM users WHERE username IN (?))`) ⇒ تعارض يمنع تنفيذ حذف `user_roles`، فيلتقطه `catch (\Throwable)` الصامت **قبل** `DELETE FROM users`، فيتسرب كل شيء. والتشخيص: `login_attempts` موجودة وكل الجداول سليمة — العطل تعارض trigger مع استعلام فرعي، لا نقص جدول ولا غياب تسجيل.
3. **مواضع بذر ناقصة التغطية (مثبتة بالقياس لا بالافتراض):** بعد إصلاح (1)+(2) ظل التسرّب 11 حسابًا لكل تشغيل. القياس على البايتات حدّدها بالضبط: `seedPolicyUser()` و`seedMustChangeUser()` لم يكونا يسجّلان الاسمين، وهما يُنشئان مستخدمين فعليين (`cd004.item10.*` / `item11.*` / `item9.*`). سُجّل الاسمان في الموضعين ⇒ صفر تسرّب.
4. **الإصلاح الجذري المطبَّق:** (أ) تُحلّ المعرّفات أولًا في **استعلام مستقل** (`SELECT id FROM users WHERE username IN (?)`)، ثم تُحذف كل الجداول بقائمة معرّفات literals **بلا أي استعلام فرعي على `users`** ⇒ لا تعارض مع الـ trigger. (ب) حُذف تجاوز `FOREIGN_KEY_CHECKS=0` من كود الاختبار كليًا، والاعتماد على `CASCADE` الحقيقي. (ج) `seedPolicyUser()`/`seedMustChangeUser()` يسجّلان الاسمين.

**الإثبات الحاسم — المعيار: خط أساس 4 بلا نمو بين تشغيلين (بالتشغيل الفعلي):**

| القياس | الكود القديم | الكود الجديد | يتامى `user_roles` | يتامى `evaluations` |
|---|---|---|---|---|
| خط الأساس | 4 | 4 | 0 | 9 |
| بعد التشغيل 1 | **17** (+13) | **4** | 0 | 9 |
| بعد التشغيل 2 | — | **4** | 0 | 9 |
| بعد التشغيل 3 | — | **4** | 0 | 9 |

**إثبات `git stash` (نمط البنود 7/9):** `git stash push -- tests/cases/Core\AuthTest.php` (تحقّق: `seededUsernames[]` = موضع واحد، و`stash@{0}` محفوظ) ثم تشغيل `AuthTest` على **الكود القديم** ⇒ `users 4→17`؛ ثم `git stash pop` (تحقّق: `seededUsernames[]` = 4 مواضع، و`stash` فارغ) ⇒ `users=4` في 3 تشغيلات متتالية. ⇒ **العيب سببه هذا الملف، والتعديل هو ما يُصلحه.**

**اختبار انحدار جديد (يبقى في `AuthTest`):** `testNoOrphanUserRolesAfterCleanup` — يبذر مستخدمًا مربوطًا بدور، ينظّفه، ثم يؤكد ثلاثة أشياء: 0 صف في `user_roles`، و0 صف يتيم في `user_roles`، و0 صف في `users` باسم الاختبار. هذا الاختبار هو ما كشف الخطأين معًا (هو أول ما أخفق، بسبب 1442).

**الحالة النهائية لـ`AuthTest`:** **58/59** في 3 تشغيلات متتالية، والفشل الوحيد المتبقي **سابق** وموثّق للـ CD-007: `testAdminUserControllerGuardStopsNonAdmin` (بند 7 — المتوقَّع `false` والفعلي `true`). `php -l` نظيف.

**ج) أداة فحص الترميز (11-b/4):** `CD-001_delivery/scripts/check-encoding.php` — PHP بلا اعتماديات، نطاقه `CD-001_delivery/*.md` + `CHANGELOG.md` جذر التطبيق. يكشف CJK (U+4E00–9FFF) وKana (U+3040–30FF) وHangul (U+AC00–D7AF) وCyrillic (U+0400–04FF) + صلاحية UTF-8، ويطبع `ملف:سطر [الفئة]: U+XXXX` مع `exit 0/1`.
- **النطاق الافتراضي:** 31 ملفًا / 5025 سطرًا ⇒ تسرّب **0**، `exit 0` ✔
- **اختبار سلبي** (لا معنى لفاحص يقول «نظيف» دائمًا): ملف تجريبي يحوي المجموعات الأربع ⇒ كشف 4 تسرّبات بأكوادها (U+62A5/U+544A، U+30AB/U+30CA، U+D55C/U+AD6D، U+41F…U+442) و`exit 1` ✔
- **تحقّق مستقل لاكتشاف CD-007:** فحص صريح لـ `app/Views/admin-reports/create.php` كشف `سطر 28 [CJK]: U+52B2 U+6001` (محرفا U+52B2 وU+6001) ⇒ يؤكد الاكتشاف بدقّة. (خارج النطاق الافتراضي؛ لا يُمس.)

**د) مثبّت الخطاف (11-b/5):** `CD-001_delivery/scripts/install-hooks.php` — خطاف `pre-commit` **في مستودع التسليم فقط** (مُتحقَّق: `git rev-parse --show-toplevel` = `CD-001_delivery`).
- **بلا اعتماد على git CLI:** يحلّ الجذر من موقع السكربت، ويدعم `.git` مجلدًا أو ملفًا (worktree/submodule)؛ والخطاف يحمل **الجذر المطلق مثبَّتًا وقت التثبيت** فلا يحتاج git على PATH. أُصلح خطأ في ذلك: `git` غير موجود في PATH لعملية PHP على هذا الجهاز.
- **idempotent مُثبَت:** 4 تشغيلات متتالية ⇒ **كتلة واحدة** وبصمة الملف واحدة (MD5 `07BCF2DC…`) في كل تشغيل.
- **غير مُتلِف:** مع خطاف أجنبي موجود ⇒ حُفظ سليمةً وأُلحقت كتلتنا بعده + نسخة `pre-commit.cd006.bak`.
- **الخطاف يضمن** سطر `#!/bin/sh` (شرط تنفيذه)، ويقبل `PHP_BIN` ثم `php` من PATH ثم XAMPP.
- **إثبات حي:** تسرّب مقصود في `ZZ_ENCODING_LEAK_TEST.md` ⇒ `git commit` **ممنوع** (`exit 1`، و`HEAD` لم يتغيّر، والسبب مطبوع `U+62A5`)؛ النطاق النظيف يمرّ (`exit 0`)؛ و`CD006_GUARD_DISABLED=1` يتجاوزه عمدًا برسالة في stderr.
- `--status` و`--uninstall` (يحذف الملف إن لم يتبقَّ سوى `shebang`)، ومخرجات عربية خالصة (أُصلح داخلها لفظتان غير عربيتين).

**هـ) إصلاح U+FFFD (11-b/6) — والقياس الأول كان نفسه معطوبًا:**
- **القياس الأول خاطئ:** عبر PowerShell مع `Out-String` ظهر «التاريخ نظيف (0)» — وهو **أثر ترميز الطرفية لا واقع الملف**. القياس الصحيح على **البايتات الخام** (`git cat-file blob HEAD:CHANGELOG.md > file` ثم عدّ `EF BF BD`) أعطى **206** في `HEAD` نفسها.
- **النتيجة:** التلف **تاريخي**: موجود في **النسخة الأساس `6cfa863`** (أول commit) ⇒ لا نسخة نظيفة في أي commit ⇒ **النص الأصلي غير قابل للاسترجاع** (مستحيل، لا مؤجَّل).
- **الإصلاح بأمانة لا باختراع نص:** أُعيد بناء السطرين من المصدر الباقي `app/Views/employees/evaluations_by_year.php`: أسماء المؤشرات الأربعة من `kpi-lbl` (متوسط الأداء/أعلى درجة/متوسط القسم/متوسط الشركة)، وقيم التخطيط من الملف نفسه + من الشظايا الرقمية الباقية في السطر (`width:min(96%,1400px)`، `minmax(240px/340px)`، `1366/1920`، `90%/125% zoom`). و**كُتبت حاشية «إعادة بناء نصية»** تحت كل سطر تُعلن أن الصياغة من المصدر لا من النص الأصلي.
- **النتيجة:** `U+FFFD = 0` (متحقَّق بالبايتات: `EF BF BD = 0`)، بلا BOM، UTF-8 سليم، بلا أسطر مكرّرة (فحص تكرار على كل سطر > 25 محرفًا). `git diff --numstat` = `+16/−4`.

**نقاط مؤجَّلة إلى CD-007 (لا تُصلَح في 11-b):** `app/Views/admin-reports/create.php:28` (محرفا CJK داخل نص `placeholder` ظاهر) · 9 صفوف `evaluations` يتيمة (7/8/11/12/16) ناتجة عن تجاوز `FOREIGN_KEY_CHECKS` تاريخًا · `AuthTest::testAdminUserControllerGuardStopsNonAdmin` · `RouterTest` · فجوة Audit في `updateRole` · نقطة عمى الأداة (U+FFFD خارج مجموعة الكشف بحكم القرار).

**نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-29/AuthTest.pre-item11.php` — SHA1 `2FF0746D71E3EDF2FD977006E4A06AAF162E5556`.

**الإغلاق:** 11-a و 11-b مُنفَّذان — Commit التسليم `609e8ee` + Commit التطبيق `c2e8225` (`feat(A2.11)`). الترتيب المُلتزَم: 11-a ← 11-b ← Commit ← 12.

---

## إغلاق المرحلة 1 (البنود 1–6) — إلزامي (CP1)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-23 |
| الحالة | **المرحلة 1 مكتملة (6/6)** |
| التقرير الموجز | `CD-006_Phase1_Report.md` + `CD-006_Phase1_Report.pdf` (نمط A2 — mPDF RTL بخط Cairo عبر سكربت مؤقت خارج كود التطبيق) |
| Git — مستودع التطبيق (جذر المشروع) | Baseline جدید `6cfa863` — 4 Commit (1 baseline + 3 إغلاق بندية إثبات) بلا Gitlink، بلا vendor/config، الترحيلات متتبَّعة |
| Git — مستودع التسليم | Commit الإغلاق المدوَّن هنا (انظر `CHANGELOG.md` في التسليم) |
| DB | `users=4` (sysadmin/kghamdi/smutairi/fzahrani)، `user_roles=4`، `roles=4`، `permissions=38` — بلا بقايا تنظيفٍ، بلا بيانات اختبار |
| الاختبارات | مجموعة كاملة بلا انحدار عن خط الأساس المعروف — التفاصيل في ملفات `tests/cases/` بهذا الملف |
| الاكتشافات خارج النطاق | موثقة في `CD-006_OUT_OF_SCOPE.md` (OOS-1…OOS-8) — لا تُعالج في المرحلة 1 |

---

**المرحلة 1 مكتملة — مرجع Git: مستودع التطبيق Commit `6cfa863` — إثبات البنود 1–6 في أقسامها بهذا الملف — التوقف إلزامي قبل المرحلة 2 (البنود 7–12) بانتظار اعتماد CP1.**

---

## إطلاق المرحلة 2 (البنود 7–12) — إلزامي (بعد اعتماد CP1)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-23 |
| الحالة | **المرحلة 2 مفتوحة — البند 7 بدأ في 2026-09-23** |
| مرجع الاعتماد | «المرحلة 2 معتمدة — ابدأ البند 7» (CP1 معتمد — توقيع كبير المستشارين 2026-09-23) |
| نطاق المرحلة 2 | البنود 7، 8، 9، 10، 11، 12، 12-b |
| نقاط التفتيش | **CP2** بعد البنود 7–10 (توقف إلزامي) — **CP3** بعد البنود 11–12-b + اختبار انحدار (تقرير نهائي) |
| القواعد | لكل بند: تنفيذ → نسخة رجوع → توثيق (IMPLEMENTATION + CHANGELOG للجذر والتسليم) → Commit تسليم → Commit تطبيق بصيغة `feat(A2.N): <وصف>` + سطر إغلاق إلزامي + إشارة `docs commit <hash>` |

---

## إغلاق المرحلة 2 (البنود 7–10) — إلزامي (CP2)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-28 |
| الحالة | **المرحلة 2: البنود 7–10 مكتملة (4/4)** — البنود 11 و12 و12-b لم تبدأ |
| تقرير المرحلة | `CD-006_Phase2_Report.md` + `CD-006_Phase2_Report.pdf` (5 صفحات — mPDF RTL بخط DejaVuSans عبر سكربت مؤقت خارج كود التطبيق) |
| Git — البند 7 | تطبيق `f44d525` · Step A تطبيق `f4ae1f9` / تسليم `9a69680` |
| Git — البند 8 | تطبيق `bcb12a7` · تسليم `93294f0` · إغلاق `1e9de66` |
| Git — البند 9 | تطبيق `1a7f650` · تسليم `a3dbc07` · إغلاق `c4096fc` |
| Git — البند 10 | تطبيق `792d6c9` · تسليم `dac9e06` · إغلاق `bb583f2` |
| DB (نهائي) | `users=30` · `roles=4` · `user_roles=20` · `permissions=38` · `employees=27` · `audit_logs=289` (=284 خط أساس + 5 إثبات البند 10) · بلا يتام |
| سجل التدقيق التاريخي | `id<=726` = **246 صفًا سليمة** (لم تُمسّ في أي بند) · إثباتات البندين 8 و10 محفوظة `727–764` و`811–815` |
| الاختبارات | `UserTest` 3/3 (جديد في البند 9) · بلا انحدار (نتيجة المجموعة الكاملة = خط الأساس) · 3 اختبارات فاشلة **سابقة** موثّقة في تقرير CP2 §6 |
| الترحيلات | **لا ترحيل DB في أي بند من بنود المرحلة 2** |
| فجوة مُحوَّلة | فشل تغيير الدور بلا Audit (البند 9) ⇒ مراجعة CD-007+ (تفصيلها `CD-006_Phase2_Report.md` §7) |
| بنود مؤجَّلة | `/admin/roles` ⇒ البند 11 · OOS-8 ⇒ البند 12-b · OOS-1 ⇒ CD-007 · تنظيف 26 حساب اختبار ⇒ البند 11 (قرار المستشار Q3) |

---

**نقطة تفتيش CP2 وصلت — التوقف إلزامي: لا يُنفَّذ البند 11 ولا 12-b ولا أي بند لاحق قبل اعتماد المستشار لهذا التقرير.**
