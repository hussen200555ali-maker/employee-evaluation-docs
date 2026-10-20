# CD-014 — الإصدار v0.2.0 (معالجة الديون التقنية)

**التاريخ:** 2026-10-21 · **المرجع:** التوجيه الاستشاري CD-014
**الحالة:** قيد التنفيذ — OOS-18 ✅ مُغلق

---

## نطاق CD-014
| البند | الوصف | الحالة |
|---|---|---|
| **OOS-18** | إزالة تجاوز `isAdmin()` من فحص الصلاحيات | ✅ مُغلق |
| OOS-2..6 | Role Hierarchy · Permission Groups · Role Templates · Bulk Ops · تقارير A2 | ⏳ لاحقًا |
| OOS-20 | كاش التقارير للاستعلامات غير المفلترة | ⏳ لاحقًا |

Guardrail: لا لمس واجهة Sidebar المعتمدة · البوابة نظيفة · 112 اختبارًا محفوظ.

---

## OOS-18 — البيانات مصدر الحقيقة للصلاحيات ✅

### المشكلة
`Auth::userHasPermission()` كانت تُعيد `true` لأي حامل لدور `Admin` **بغض النظر عن
`role_permissions`** (`Auth.php:88`). النتيجة: RBAC يعتمد على الصدفة لا البيانات،
ويخفي حقيقة أن Admin يملك 36/38 فقط.

### الحل (بقرار كبير المستشارين 2026-10-21)
«البيانات مصدر الحقيقة» — منح Admin كل الصلاحيات في البيانات، ثم إزالة التجاوز:

1. **ترحيل:** `database/migrations/2026_10_21_CD014_oos18_admin_full_permissions.sql`
   - `INSERT INTO role_permissions ... SELECT ... WHERE NOT EXISTS` (متكرر الآمن/Idempotent، بلا معرّفات صلبة).
   - يمنح الصلاحيتين الناقصتين: `evaluations.view.team` · `evaluations.create.team`.
   - المحفّز `cd004_trg_role_permissions_ai` يُكبّر `users.permissions_version` تلقائيًا (sysadmin 9→11).
   - **القياس:** Admin 36→**38** (يملك كل الـ38).
2. **الكود:** أُزيل شرط `self::isAdmin()` من `Auth::userHasPermission()`.
   - توثيق الدالة يشرح القرار والترحيل.

### التبعيات العرضية المكتشفة والأصلاح
كانت اختبارات تضع `$_SESSION['user_roles']=["Admin"]` **بلا `user_permissions`**
وتعتمد على التجاوز ضمنيًا:
- `AuthTest::testAdminUserControllerGuardStopsNonAdmin` → أُضيف `refreshSessionPermissions()` في العملية الفرعية.
- `UserControllerTest` (الفاعل Admin) → أُضيف `refreshSessionPermissions()`.
- **بديل الاختبار القديم:** `testUserHasPermissionAdminBypass` استُبدل بـ
  `testUserHasPermissionNoAdminBypass` + أُضيف `testAdminHoldsAllPermissionsFromData`.
- **إصلاح بنية اختبار:** `tests/lib/TestCase.php::runCli()` كان يقرأ stderr قبل stdout
  (جمود عند المخرجات الكبيرة مثل صفحة 403 كاملة) → قراءة متزامنة غير حاجبة للأنبوبين.

### الأدلة (§2.12: موجب + سالب)
```
tests/runner.php                    -> 112 نجحت · 1 تخطّيت · 0 فشل  (AuthTest 62/62)
ADMIN_perms_count=38                 (من البيانات)
ADMIN_view_team=PASS · users_view=PASS
ADMIN_fake_perm=DENIED_OK            ← إثبات إزالة التجاوز (كان LEAK_BAD)
STAFF_users_view=DENIED_OK           ← الحارس ما زال يعمل
check-encoding --path=app           -> 433/73527/تسرّب 0
git diff --check                    -> exit=0
```

### الملفات المتأثرة
- `app/Core/Auth.php` (إزالة التجاوز).
- `database/migrations/2026_10_21_CD014_oos18_admin_full_permissions.sql` (جديد).
- `tests/cases/Core/AuthTest.php` · `tests/cases/Controllers/UserControllerTest.php` · `tests/lib/TestCase.php`.
