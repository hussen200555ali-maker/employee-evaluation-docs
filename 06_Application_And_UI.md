# الوثيقة 06 — تطبيق النظام وواجهات المستخدم

| بند | البيان |
|---|---|
| **اسم الوثيقة** | تطبيق النظام وواجهات المستخدم |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. عمارة الواجهة والتنقّل

التطبيق مبنى على نمط **Front Controller** مع مُوجّه (`Router`) مخصص:

```
طلب HTTP → public/index.php (Front Controller) → Auth::enforceCsrfToken() → Router::direct(uri, method) → Controller@Method → Model → View
```

- **إعادة التوجيه:** `.htaccess` يحوّل كل الطلبات (غير الملفات/المجلدات) إلى `public/index.php?url=$1`.
- **المُوجّه:** `routes/web.php` (209 مسارًا) عبر كلاس `App\Core\Router`، ويدعم معاملات بالقالب `:id` (مثل `employees/:id`).
- **التوريث والنماذج:** `app/Core/Controller.php` يوفّر: عرض `view()`, تحميل نموذج `model()`, تجهيز CSRF، وفلترة `sanitize()`. التحميل التلقائي عبر Composer (PSR-4 `App\ → app/`).
- **مصادقة:‏** `app/Core/Auth.php` — جلسة PHP + حماية CSRF لكل طلبات POST عبر جدول `csrf_tokens` (فترة سماح 240 دقيقة).

---

## 2. خريطة المسارات (209) حسب الوحدة

| الوحدة | البادئة | عدد المسارات | المتحكم | الحالة |
|---|---|---|---|---|
| الصفحات العامة | ``, `about`, `login`, `logout` | 5 | PagesController, AuthController | مكتمل |
| لوحة التحكم | `dashboard` | 1 | DashboardController | مكتمل |
| الهيكل التنظيمي | `branches`, `departments`, `employees`, `employees/positions` | 19 | Branch/Department/Employee/PositionsController | مكتمل |
| المستخدمون والأدوار | `admin/users`, `admin/roles` | 15 | Admin\UserController, Admin\RoleController | مكتمل |
| القوالب والباني | `templates`, `builder/*` | 6 | TemplateController, BuilderController | مكتمل |
| التقييمات الفردية | `evaluations/*` + `employees/:id/evaluations(*)` | 11 | EvaluationController, EmployeeController | مكتمل |
| Excel (استيراد/تعليمات) | `evaluations/excel/*` | 8 | EvaluationExcelController | مكتمل |
| تقييم الوحدات | `units/evaluations/*` | 3 | UnitEvaluationController | جزئي (لا جدولة) |
| الجداول | `schedules/*` | 4 | ScheduleController | بنية فقط (جداول فارغة) |
| التقييمات المرنة | `flexible/evaluations/*` | 8 | FlexibleEvaluationController | مكتمل |
| التدريب — الدورات | `training/courses/*` | 7 | TrainingCourseController | مكتمل |
| التدريب — الكتالوج | `training/courses/catalog/*` | 6 | CourseCatalogController | مكتمل |
| التدريب — الدورة | `training/evaluations/*` | 3 | CourseEvaluationController | مكتمل |
| التدريب — الورش | `training/workshops/*` | 6 | TrainingWorkshopController | مكتمل |
| التدريب — تقييم الورش | `training/workshops/evaluations/*` | 3 | WorkshopEvaluationController | مكتمل |
| التقارير | `reports/*` | 11 | ReportsController, UnifiedReportController, StatisticalReportController | مكتمل |
| تقارير التدريب | `reports/training-*`, `reports/workshops`, `api/report*` | 11 | TrainingReportController, WorkshopReportController | مكتمل |
| ملفات الأداء | `courses/performance-files`, `workshops/performance-files`, `units/performance-files`, `employees/performance-files` | 4 | PerformanceFilesController | مكتمل |
| التحليل | `analysis/*` | 13 | AnalysisController | مكتمل |
| النسخ الاحتياطي | `backup/*` (Includes `api/backup/*`) | 30 | BackupController | مكتمل |
| REST API | `api/v1/*` | 5 | Api\V1Controller | مكتمل (محمي بـ X-API-Key) |
| واجهات AJAX | `api/employees/search`, `api/templates/*`, `api/departments/by-branch`, `api/to-hijri`, `csrf/token` | 6 | ApiController, AuthController | متاحة بلا مصادقة (انظر وثيقة 13) |
| الإعدادات | `settings/rating/*` | 2 | SettingsController | مكتمل |
| الأرشيف الشجري | `archive/*` | 10 | ArchiveCoursesController, ArchiveWorkshopsController | مكتمل |
| التقارير الإدارية | `admin/reports/*` | 8 | AdminReportController | مكتمل |

> القائمة الكاملة بالترتيب: `appendices/routes_inventory.txt` (209 سطرًا).

---

## 3. المخازن (Views — 129 ملفًا) حسب المجلد

| المجلد | الملفات | الغرض |
|---|---|---|
| `layouts/` | 6 (main, header, footer, header-builder, footer-builder, _flash_messages) | الهيكل العام + نسخة خاصة للباني |
| `pages/` | 2 (home, about) | الصفحات العامة |
| `dashboard/` | 1 | لوحة التحكم |
| `branches/`, `departments/` | 2 | إدارة الفروع والأقسام |
| `employees/` | 7 (+`positions/`) | الموظفون والمناصب |
| `admin/` | 6 (users + roles) | المستخدمون والأدوار |
| `templates/` | 2 + `builder/` 2 | القوالب والباني (بمعاينة طباعة) |
| `evaluations/` | 7 (create/fill/show/print/index/excel_import) | دورة التقييم الفردي |
| `flexible/` | 4 | مسارات التقييمات المرنة |
| `units/` | 1 | تقييم الوحدات |
| `schedules/` | 1 | الجداول |
| `training/` | 19 (courses, workshops, catalog, evaluations) | منظومة التدريب |
| `reports/` | 12 (+training/workshops/statistics) | التقارير |
| `analysis/` | 17 (+partials, print-parts) | التحليلات ومخرجات الطباعة |
| `backup/` | 10 | النسخ الاحتياطي والتشفير |
| `archive/` | 8 | الأرشيف الشجري |
| `admin-reports/` | 7 | التقارير الإدارية |
| `settings/` | 1 | إعدادات التقدير |
| `performance/` | 4 | ملفات الأداء |
| `auth/` | 2 (login, forgot-password) | الدخول |
| `errors/` | 2 (403, 404) | الأخطاء |

> القائمة الكاملة: `appendices/views_inventory.txt` (129 سطرًا).

---

## 4. المكونات المشتركة (الواجهة)

| المكوّن | الوصف |
|---|---|
| الزرار/الخط | Cairo (4 أوزان) + Font Awesome 6 + خطوط ويب محلية في `public/webfonts` |
| النماذج المتزامنة | Bootstrap-like + Tailwind Lite (صمّم يدويًا بدون إطار) |
| JavaScript | `main.js` (66KB)، `builder.js` (39KB)، `report-builder.js` (19KB)، `evaluation-creator.js`، `pdf-export-enhancer.js`، `print-logic.js`، `report-enhancer.js` |
| المكتبات | jQuery 3.6، SweetAlert2 (نسخة كاملة في `public/libs`)، Chart.js |
| تحذيرات | SweetAlert2 عبر `layouts/_flash_messages.php` |

---

## 5. أزرار/مسارات الطباعة والتصدير (A4)

- طباعة تقييم فردي: `evaluations/print/:id`
- طباعة تقارير موحدة: `reports/print`
- طباعة تحليل: `analysis/print`, `analysis/print/level`
- PDF مع رسوم: `analysis/exportPdfWithCharts`
- تصدير Excel: `reports/unified/export`, `reports/statistics/export`, `analysis/export/excel*`

---

**نهاية الوثيقة 06 — تطبيق النظام وواجهات المستخدم**