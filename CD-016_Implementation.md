# CD-016 — تأسيس بيانات التقييم وسلم التقديرات

**التاريخ:** 2026-11-03
**الحالة:** اكتمل الترحيل والتنفيذ والتحقق

## النسخة الاحتياطية

أُخذت نسخة كاملة قبل تعديل قاعدة البيانات باستخدام `mysqldump --result-file`:

`storage/backups/CD-016/employee_evaluation_mvc_before_CD-016_2026-11-03_0435.sql`

حجم الملف: **154,223 بايت**. وشملت النسخة الإجراءات المخزنة والمحفزات والأحداث.

## التغييرات

### قاعدة البيانات

أُنشئ الترحيل `database/migrations/2026_11_03_CD016_evaluation_foundation.sql`، وصُمم ليكون آمنًا عند إعادة تطبيقه على MariaDB:

- إضافة `evaluations.evaluation_type` بالقيم `annual` و`periodic` و`course` و`workshop`، مع إبقائه `NULL` للسجلات القديمة.
- إضافة `evaluations.final_grade_label` و`evaluations.final_grade_value` كحقلين اختياريين.
- إضافة `form_templates.evaluation_mode` (`numeric` / `descriptive` / `mixed`) بقيمة افتراضية `numeric`، و`evaluation_frequency` (`yearly` / `quarterly` / `monthly` / `ad-hoc`) بقيمة افتراضية `yearly`.
- إنشاء `grading_scales` مع قيد تفرد اسم التقدير داخل السلم ومؤشر ترتيب، وإدخال خمسة تقديرات افتراضية عربية للسلم الخماسي.
- إضافة الصلاحية `grading_scales.manage` وإسنادها إلى دور Admin من قاعدة البيانات.

لم تُعدّل `context_type` أو `context_id` أو حقول `period_*`، ولم تُعدّل جداول `course_evaluations` و`workshop_evaluations` القديمة. بعد الترحيل: `evaluations` = **0**، و`course_evaluations` = **2**، و`workshop_evaluations` = **3**.

### التطبيق

- إتاحة نمط التقييم ودوريته في إنشاء القوالب وتعديلها، وحفظهما في النموذج.
- حفظ نوع التقييم في سجلات التقييم الجديدة: `annual` أو `periodic` للتقييمات الفردية، و`course` أو `workshop` لمسارات التقييم المرنة المرتبطة بها.
- دعم إدخال تقدير عام من سلم نشط في النمطين الوصفي والمختلط. يبقى احتساب الدرجة العددية قائمًا في النمط العددي والمختلط، ولا يُحتسب في النمط الوصفي.
- إضافة صفحة CRUD لإدارة السلال والدرجات، مع التحقق من القيم والحدود والتداخل، وحمايتها بصلاحية `grading_scales.manage`.
- معالجة فشل حفظ نتيجة التقييم أو تعديل/حذف درجة السلم برسالة خطأ بدل عرض نجاح غير صحيح.

## التحقق

- اختبارات `GradingScaleTest` و`TemplateEvaluationMetadataTest`: **1/1 لكل اختبار**.
- `php tests/runner.php`: **105 نجاح، 0 فشل، 0 أخطاء، 0 تخطٍّ**.
- فحص صياغة PHP لكل الملفات المعدلة: **نجاح**.
- `check-encoding.php --path=app`: **359 ملفًا، تسرّب 0، exit=0**.
- `check-encoding.php --path=delivery`: **49 ملفًا، تسرّب 0، exit=0**.
- `git diff --check`: `exit=0`.
- أُعيد تطبيق الترحيل للتحقق من قابلية تكراره؛ بقي عدد صفوف التقديرات الافتراضية خمسة، ولم تظهر صفوف معطوبة بالترميز.

اكتمل CD-016 فقط. لم يبدأ توحيد الجداول القديمة أو تنفيذ CD-017/CD-018.
