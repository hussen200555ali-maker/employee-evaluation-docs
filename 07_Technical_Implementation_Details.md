# الوثيقة 07 — تفاصيل التنفيذ الفني

| بند | البيان |
|---|---|
| **اسم الوثيقة** | تفاصيل التنفيذ الفني |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. التقنية والبيئة

| البند | القيمة |
|---|---|
| اللغة | PHP 8.2 (XAMPP) |
| قاعدة البيانات | MariaDB 10.4.32 (InnoDB / utf8mb4) |
| خادم الويب | Apache + mod_rewrite |
| البنية | MVC مخصص (بدون إطار جاهز مثل Laravel) |
| نقاط الدخول | `public/index.php` (Front Controller) |
| إدارة الاعتماديات | Composer (PSR-4: `App\ → app/`) |

---

## 2. قلب النظام (`app/Core` — 17 كلاسًا)

| الكلاس | المسؤولية |
|---|---|
| `App.php` | تحميل المُوجّه وتشغيل المتحكم المستهدف |
| `Router.php` | مطابقة المسارات مع معاملات موضعية (`:id`) |
| `Controller.php` | قواعد: `view()` / `model()` / CSRF / `sanitize()` |
| `Database.php` | اتصال PDO **Singleton** (محمّل مسبقًا) |
| `Model.php` | قاعدة نماذج البيانات |
| `Auth.php` | مصادقة الجلسة + تفعيل CSRF للمسارات POST |
| `CsrfGraceLogger.php` | تسجيل تفصيلي لحوادث CSRF |
| `Audit.php` | تسجيل أحداث التدقيق في `audit_logs` |
| `Flash.php` | رسائل الجلسة |
| `helpers.php` | دوال مساعدة مشتركة |
| `PdfReportBuilder.php` | توليد PDF (محرك مزدوج mPDF/TCPDF) |
| `Backup*` (7 كلاسات) | مدير، جدولة، تشفير، مراقبة، تحسين النسخ الاحتياطي |

---

## 3. طبقة النماذج (`app/Models` — 28 نموذجًا)

| المجموعة | النماذج |
|---|---|
| الهيكل والتوظيف | Branch, Department, Position, Employee, User |
| الصلاحيات | Role, ApiKey |
| التقييمات | Evaluation (74KB — الأكبر)، Criterion, Template, EvaluationSchedule, RatingSetting, RecommendationModel, ReportModel, ReportTemplateModel |
| التدريب | TrainingCourse, CourseCatalog, CourseEvaluation, TrainingWorkshop, WorkshopCatalog, WorkshopEvaluation, TrainingReport, WorkshopReport |
| التقارير والتحليل | AnalysisModel (52KB), ReportModel, ReportTemplateModel |
| الأرشيف | ArchiveModel |
| النسخ الاحتياطي | Backup (41KB), BackupLog, BackupSetting |

> جميع الاستعلامات عبر PDO **مُعدّة (Prepared Statements)** — لا دمج نصي للمتغيرات في SQL.

---

## 4. طبقة المتحكمات (`app/Controllers` — 41 كلاسًا)

- `Admin/`: UserController, RoleController (مساحات فرعية).
- `Api/`: V1Controller (واجهة v1 المحمية بـ X-API-Key).
- جذر المسار: AuthController, BranchController, DepartmentController, EmployeeController, PositationsController, TemplateController, BuilderController, EvaluationController, EvaluationExcelController, UnitEvaluationController, ScheduleController, FlexibleEvaluationController, TrainingCourseController, CourseCatalogController, CourseEvaluationController, TrainingWorkshopController, WorkshopCatalogController, WorkshopEvaluationController, ReportsController, UnifiedReportController, StatisticalReportController, PerformanceFilesController, TrainingReportController, WorkshopReportController, AnalysisController, BackupController, SettingsController, ArchiveCoursesController, ArchiveWorkshopsController, AdminReportController, ApiController, PagesController, DashboardController, ErrorController, TestController.

---

## 5. الإعدادات (`config/`)

| الملف | أبرز القيم |
|---|---|
| `config.php` | `memory_limit 2048M`، `max_execution_time 600`، `DEBUG_MODE=true`، `display_errors=1`، منطقة `Asia/Riyadh (+03:00)`، `CSRF_GRACE_PERIOD_MINUTES=240`، حدود رفع 256M |
| `app.php` | تعريف `APP_ROOT`، `APP_URL` (اكتشاف تلقائي)، CSRF |
| `database.php` | `localhost / root / (بدون كلمة مرور) / employee_evaluation_mvc / utf8mb4` |
| `performance.php` | `memory_limit 4096M`، `max_execution_time 1200`، استدعاء `opcache_reset()`، `BACKUP_BATCH_SIZE=100` |

---

## 6. محركات الحساب (غير SQL)

نتيجة التقييم تُحسب في طبقة PHP (وليس في قاعدة البيانات):

- درجة القسم = Σ(إدخال القسم × وزن القسم).
- درجة المعيار = إعادة تطبيع داخلية لأقسامه.
- `final_score` = Σ(درجة المعيار × وزن المعيار) / 100.
- القوالب الإدارية تدعم أنواع المدخلات المحوسبة: `formula` / `auto` / `helper` (تفاصيل: وثيقة 04 + `docs/Admin_Reports_Formula_System.md`).
- التقويم الهجري عبر مكتبة `ar-php` (`api/to-hijri`، معاملات التاريخ المرنة DD-MM-YYYY).

---

## 7. اعتماديات Composer

| الحزمة | الحالة |
|---|---|
| `mpdf/mpdf 8` | مستخدمة (طباعة PDF) |
| `phpoffice/phpspreadsheet 1.29` | مستخدمة (Excel dynamic generator + استيراد) |
| `tecnickcom/tcpdf 6.10` | مستخدمة (مسار PDF آخر) |
| `khaled.alshamaa/ar-php 7` | مستخدمة (هجري/عربي) |
| `dompdf/dompdf 3.1` | معرّفة لكن **غير مستخدمة فعليًا** (تعدد تاريخي، انظر وثيقة 01 §6) |
| `phpunit/phpunit 11.5` (dev) | معرّفة لكن الاختبارات الفعلية عبر runner مخصص (وثيقة 14) |

---

## 8. ملاحظات معمارية

- وجود ملفين متوازيين للجدولة (`BackupScheduler.php` و`BackupScheduler_fixed.php`) — مكوّن يحمل نسخة "مصلّحة" بجانب الأصلية (انظر وثيقة 11/12).
- `main.js.bak.encoding` و`public/libs` كاملة الأعضاء داخل نطاق المتصفح — حجم واجهة محلي كبير.
- لا يوجد فصل بيئة (.env)؛ الإعدادات (بما فيها كلمة مرور DB الفارغة) مكتوبة داخل `config/*.php` (انظر وثيقة 13).

---

**نهاية الوثيقة 07 — تفاصيل التنفيذ الفني**