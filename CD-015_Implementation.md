# CD-015 — تقرير تنفيذ إزالة طبقة التقارير

**التاريخ:** 2026-11-03  
**الحالة:** اكتمل التنظيف والتحقق

## النسخة الاحتياطية

أُخذت نسخة كاملة قبل أي حذف من قاعدة البيانات باستخدام `mysqldump --result-file`:

`storage/backups/CD-015/employee_evaluation_mvc_before_CD-015_2026-11-03_02-13-31.sql`

## ما أُزيل

- **الشريط الجانبي:** مجموعتا الجوانب الإدارية والتقارير، رابط التحليل الاستراتيجي، وروابط أرشيف الدورات والورش. بقيت روابط الموظفين والهيكل التنظيمي والتقييمات والتدريب والإعدادات والمستخدمين والأدوار.
- **المسارات:** مسارات التقارير الموحدة والإحصائية والتحليلية والإدارية، تحليل الأداء، أرشيف الدورات والورش، وتقارير التدريب وواجهاتها البرمجية وملفات الأداء.
- **المتحكمات:** `AdminReportController` و`AnalysisController` و`ArchiveCoursesController` و`ArchiveWorkshopsController` و`ReportsController` و`ReportsAnalyticsController` و`UnifiedReportController` و`StatisticalReportController` و`PerformanceFilesController` و`TrainingReportController` و`WorkshopReportController`.
- **النماذج والخدمات:** `AnalysisModel` و`ArchiveModel` و`ReportModel` و`ReportTemplateModel` و`TrainingReport` و`WorkshopReport` و`ReportEngine`.
- **العروض:** مجلدات `reports/` و`analysis/` و`archive/` و`admin-reports/`، وعروض `performance/` التابعة لملفات الأداء، والعرض `statistics/report.php`. لم يكن مجلد `app/Views/performance-files/` موجوداً.
- **الاختبارات والأصول:** اختبار `ReportEngineTest`، وأصول CSS/JavaScript الخاصة بالتقارير والأرشيف.
- **الروابط التابعة:** إزالة اختصار التقارير من لوحة التحكم، وتغيير رابط العودة في صفحة تقييم الدورة ليعود إلى قائمة الدورات بدلاً من لوحة التقارير المحذوفة.
- **README:** تحديث وصف الميزات ولقطات الشاشة لإزالة الإشارة إلى التقارير المحذوفة.

## قاعدة البيانات

بعد التحقق من وجود النسخة الاحتياطية، أُزيلت العروض:

- `vw_evaluation_facts`
- `vw_employee_scores`
- `vw_criteria_averages`

وأُزيلت الجداول الخاصة ببناء التقارير وجدولتها: `report_template_columns` (4 صفوف)، و`report_templates` (صفّان)، و`admin_schedules` (0 صفوف). لم يُعثر على جدول `archives`.

لم تُحذف جداول البيانات الأساسية. وبقي `admin_report_evaluators` لاستخدامه في سير التقييم الأساسي، كما بقي `admin_notifications` لارتباطه بتنظيف حسابات المستخدمين.

## التحقق

- `php tests/runner.php`: **103 نجاح، 0 فشل، 0 أخطاء، 0 تخطٍّ**.
- `check-encoding.php --path=app`: نظيف، `exit=0`.
- `check-encoding.php --path=delivery`: نظيف، `exit=0`.
- قاعدة البيانات: غابت العروض والجداول المستهدفة بعد الحذف.

توقّف العمل عند إتمام CD-015؛ لم يبدأ تنفيذ نظام تقارير جديد.
