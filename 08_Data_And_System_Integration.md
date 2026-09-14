# الوثيقة 08 — نظام البيانات والتكامل

| بند | البيان |
|---|---|
| **اسم الوثيقة** | نظام البيانات والتكامل |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. بنية قاعدة البيانات (40 جدولًا) — مرجع سريع

| المجموعة | الجداول | عدد |
|---|---|---|
| الهيكل التنظيمي | branches, departments, positions, employees | 4 |
| الحسابات والصلاحيات | users, roles, user_roles, permissions, role_permissions, api_keys, csrf_tokens, password_resets | 8 |
| القوالب والتقييم | form_templates, template_versions, criteria, criteria_sections, evaluations, evaluation_answers, evaluation_schedules, rating_settings, settings | 9 |
| التدريب | training_courses, course_catalog, course_evaluations, training_workshops, workshop_catalog, workshop_evaluations | 6 |
| الوحدات والتقارير | admin_schedules, admin_report_evaluators, report_templates, report_template_columns | 4 |
| الاستيراد/التصدير | evaluation_import_batches, evaluation_import_rows, evaluation_import_row_errors | 3 |
| التدقيق والإشعارات | audit_logs, notifications, admin_notifications | 3 |
| النسخ الاحتياطي | backup_logs, backup_settings, backup_health_logs, backup_encryption_keys | 4 |

> المخطط الكامل (DDL الحيّ): `appendices/db_live_schema.sql`.

---

## 2. دورة الاستيراد/التصدير عبر Excel

**الوجهة:** `EvaluationExcelController` (8 مسارات) + `docs/EXCEL_*`.

| الخطوة | المسار | الوصف |
|---|---|---|
| تعليمات النموذج الديناميكي | `evaluations/excel/template` (+`:id`) / `training-template` | مولّد إكسيل ديناميكي يبني قالبًا يحوي `__lookup` و`INDIRECT("Dept_"&S6)` لأقسام حسب الفرع |
| المعاينة | `evaluations/excel/preview` | رفع ملف + تحقق أولي (نطاق صفوف مرن 100/1000) |
| الاعتماد | `evaluations/excel/commit/:id` | إدخال الدفعة + تقرير أخطاء |

**حقول المقيّم الحرة (2026-09-02):** `evaluator_employee_id` (NULLABLE) + `evaluator_name/title` — قاعدة: إلزامية واحد من الاسم/المسمى، فحص `^[=+@-]`، حد 255، وتاريخ مرن `DD-MM-YYYY` عبر `parseFlexibleDate`.

**جداول الاستيراد (أرقام حيّة):**
- `evaluation_import_batches` — دفعات
- `evaluation_import_rows` — 1041 صفًا
- `evaluation_import_row_errors` — 1828 خطأً (نسبة خطأ عالية = بيانات تجريبية)

> **راجع وثيقة 01 §5** للبيانات الملوثة الناتجة عن هذه الدفعة.

---

## 3. واجهة REST API

| الإصدار | النطاق | المسارات | التأمين |
|---|---|---|---|
| v1 | `api/v1/health`, `api/v1/employees` (+`:id`), `api/v1/evaluations` (+`:id`) | 5 | **محمية** — مفتاح `X-API-Key` يُتحقق عبر `app/Models/ApiKey.php` + جدول `api_keys` |

**فجوة هجرات موثقة:**
> جدول `api_keys` **غير موجود** في `appendices/db_live_schema.sql` (المخطط الحيّ) — تم إنشاؤه خارج مسار الترحيلات عبر `_emergency/create_api_keys_table.sql`. يُوصى بإدماجه في `database/migrations/` (انظر وثيقة 11).

**نقاط API مكشوفة (دون مصادقة):** `api/employees/search`, `api/templates/*`, `api/departments/by-branch/:branch_id`, `api/to-hijri`, `api/report*` — تفاصيل في وثيقة 13.

---

## 4. التدقيق والإشعارات

- **التدقيق:** `app/Core/Audit.php` يكتب في `audit_logs` — **192 سجلًا حيًا**.
- **الإشعارات:** جداول `notifications` (5 صفوف) و`admin_notifications` موجودة، لكن **لا يوجد مرسل بريد/منصة إشعار متصل** — الوحدة غير مفعّلة خارجيًا (نسبة الإنجاز ~30%، وثيقة 03).

---

## 5. الجدولة (Cron)

| البرنامج النصي | الدور |
|---|---|
| `cron/backup.php` | مردود CLI للنسخ الاحتياطي المجدول |
| `cron/backup_fixed.php` | نسخة باستخدام `BackupScheduler_fixed` |
| `cron/backup_with_fixed_scheduler.php` | نسخة هجينة |
| `cron/auto_scheduler.php` | جدولة تلقائية |

> الجداول التشغيلية `evaluation_schedules` و`admin_schedules` **فارغة** — النصّاب البرمجي للنسخ الاحتياطي موجود، بينما تقييم الوحدات لا توجد له بيانات مجدولة (وثيقة 03).

---

## 6. التكاملات (الحالية والغائبة)

| التكامل | الحالة |
|---|---|
| ar-php (التحويل الهجري) | ✅ محلي |
| مولد Excel الديناميكي (phpspreadsheet) | ✅ محلي |
| PDF (mPDF/TCPDF) | ✅ محلي |
| REST API v1 (X-API-Key) | ✅ داخلي |
| SMTP/بريد | ❌ غائب (نموذج استعادة كلمة المرور فارغ) |
| نظام موارد بشرية خارجي/تكاملات سحابية | ❌ غائب |
| إشعارات خارجية | ❌ غائبة |

---

**نهاية الوثيقة 08 — نظام البيانات والتكامل**