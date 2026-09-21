# CD-004 — المرحلة 5: قائمة اختبار الانحدار

**التاريخ:** 2026-09-21 | **النطاق:** الوحدات غير المشمولة في A1 + مواقع `forbidden()` + الخط الأساس الآلي.
**المبدأ:** الوحدات خارج نطاق A1 (لا تُمسّ بالتنفيذ) تُفحص بالوصول السليم لكل دور عبر مسارات فعلية؛ ومواقع الحارس الـ22 تعطى تمثيلًا لكل وحدة (صفحة محمية `GET` للأدوار غير المخوّلة → 403 + exit، والمخوّل → 200).

## 1) مواقع `forbidden()` (22 موقعًا) — دقّقة تمثيليًا

| # | الملف:سطر | الصلاحية | وضع الدقة |
|---|---|---|---|
| 1 | `app/Core/Auth.php:103` | `can($perm)` الموحّد (+exit) | يُختبر عبر كل مسار |
| 2 | `Admin/UserController.php:27` | حارس وحدة Admin (+exit) | S6 |
| 3 | `BranchController.php:22,51,84,116` | branches.view/create/edit/delete | دقة view بتدوير فردي |
| 4 | `DepartmentController.php:25,53,89,117` | departments.view/create/edit/delete | دقة view |
| 5 | `EmployeeController.php:29,164,243,425,456,516,524,594,635` | employees.view/create/edit/delete | دقة view (R) + create (Staff=مرفوض/HR=مقبول) |
| 6 | `UnitEvaluationController.php:56` | units.create | تمثيل GET |
| 7 | `FlexibleEvaluationController.php:62` | evaluations.create | تمثيل GET |
| 8 | `EvaluationController.php:401` | reports.view.all | تمثيل GET |
| 9 | `CriterionController.php:28` | templates.manage (+exit) | تمثيل SELECT |

## 2) الوحدات غير المشمولة في A1 (سير العمل الأساسي لكل وحدة)

| الوحدة | مسار تمثيلي | الدور | متوقع |
|---|---|---|---|
| لوحة التحكم | `GET /dashboard` | test_admin/test_hr | 200 |
| للموظفين | `GET /employees` | test_admin (master) | 200 |
| ما للفروع | `GET /branches` | test_admin | 200 |
| ما للأقسام | `GET /departments` | test_admin | 200 |
| القوالب | `GET /templates` | test_admin | 200 |
| التقييمات | `GET /evaluations` | test_admin | 200 |
| الوحدات/الجدولة | `GET /schedules` | test_admin | 200 |
| التدريب-الدورات | `GET /training/courses` | test_admin | 200 |
| التدريب-الورش | `GET /training/workshops` | test_admin | 200 |
| التقارير الموحدة | `GET /reports/unified` | test_admin | 200 |
| التقارير الإحصائية | `GET /reports/statistics` | test_admin | 200 |
| التحليل | `GET /analysis` | test_admin | 200 |
| النسخ الاحتياطي | `GET /backup` | test_admin | 200 |
| البحث API | `GET /api/employees/search` | زائر | 200 (API عام/مصفّى) أو 403 حسب التصميم — يُسجَّل الملاحظة |
| `GET /` (home) | زائر | 200 | |
| صفحة 404 | `GET /nonexistent-x` | زائر | 404 |

## 3) الخط الأساس الآلي (يُعاد كاملًا — بلا انحدار)
- `tests/runner.php` — AuthTest **58/58** + DatabaseTest + HelpersTest + NotificationTest **13/13** (+ RouterTest إن وُجِد).
- سيناريوهات سابقة: `RoleDashboardSmoke`, `RoleDashboardPersonaSmoke`, `ExcelWorkflowSmoke`.
- معلومة بيئية ثابتة: CLI لا يقرأ `Location` (`LOCATION=sent` دائمًا) → التأكيد السلوكي عبر حالة DB/إخراج.

## 4) فحوصات ثابتة (code-level)
- `login.php`: غياب `name="remember"` + وجود `csrf_field()` + غياب رابط `#` للنسيان (S11).
- `header.php:488`: خروج عبر نموذج POST؛ لا `GET /logout` (S4).
- `config/config.php`: `DEBUG_MODE=false` + معالم الجلسة (S2).
- مشغّلات DB الأربعة (بند 8): `SHOW TRIGGERS` بيّا — تُثبت عند S10.

## 5) التنظيف بعد المرحلة 5
- إعادة أدوار/حالات المستخدمين إلى الأصل (test_hr→HR، test_staff→Staff)، حذف الإشعارات التجريبية وسجلات audit المميزة، وتشغيل `temp/phase5_cleanup.sql` ثم البذر من جديد إن أُريد تكرار — أوleave clean.
- تجميع النتائج في `Phase5_Acceptance_Report.md`.