# الوثيقة 05 — قاعدة البيانات

| بند | البيان |
|---|---|
| **اسم الوثيقة** | قاعدة البيانات |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. معلومات عامة

| البند | القيمة |
|---|---|
| نظام إدارة قواعد البيانات | MariaDB 10.4.32 (XAMPP) |
| قاعدة بيانات العمل | `employee_evaluation_mvc` |
| الترميز | utf8mb4 (عام/unicode) |
| عدد الجداول | 40 |
| حجم القاعدة | ~3.2 م.ب تقريبًا (بيانات + فهارس) |
| محرك التخزين | InnoDB (جميع الجداول) |

**قواعد أخرى موجودة على الخادم (خارج نطاق العمل):** `employee_eval`, `employee_eval_archive`, `employee_eval_qa`, `employee_evaluation_excel_test`, `employee_evaluation_system`, `eps_eval` — بيئات اختبار/سابقة.

---

## 2. مخطط العلاقات (ERD نصي)

```
branches (1) ──< departments (N)
                   │
                   └──< employees (N) ──< manager_id ── (مرجع ذاتي)
positions (1) ──< employees (N)

employees (1) ──< users (1:1 عبر employee_id فريد)

form_templates (1) ──< criteria (N) ──< criteria_sections (N)
form_templates (1) ──< evaluations (N) ──< evaluation_answers (N) >── criteria_sections
form_templates (1) ──< template_versions (N)

users (1) ──< role_permissions >── permissions
roles (1) ──< role_permissions >── permissions
users (1) ──< user_roles >── roles

users (1) ──< course_catalog, workshop_catalog, training_courses, training_workshops (created_by)
course_catalog (1) ──< training_courses (N) ──< course_evaluations (1:1)
workshop_catalog (1) ──< training_workshops (N) ──< workshop_evaluations (1:1)
branches/departments ──< training_courses/workshops (branch_id/department_id)

form_templates (1) ──< evaluation_schedules (N)   [فارغ حاليًا]
evaluations (1) ──< admin_report_evaluators (N) >── employees
form_templates (1) ──< admin_schedules (N)        [فارغ حاليًا]
users (1) ──< admin_notifications (N)

users (1) ──< evaluation_import_batches (N) ──< evaluation_import_rows (N) ──< evaluation_import_row_errors (N)
users (1) ──< audit_logs (N), users (1) ──< notifications (N), users (1) ──< csrf_tokens (N)
users (1) ──< backup_logs (N) ; backup_logs (1) ──< backup_encryption_keys (N)
```

الملف المرجعي الكامل: `appendices/db_live_schema.sql` (تصدير `mysqldump --no-data` للجداول الأربعين).

---

## 3. الجداول الـ 40 بالبيانات الفعلية

| الجدول | الصفوف (فعلية) | الحجم (م.ب تقريبًا) | الغرض |
|---|---|---|---|
| branches | 3 | 0.03 | الفروع |
| departments | 7 | 0.03 | الأقسام |
| positions | 8 | 0.02 | المناصب |
| employees | 27 | 0.13 | الموظفون |
| users | 4 | 0.06 | الحسابات |
| roles | 4 | 0.03 | الأدوار |
| permissions | 36 | 0.03 | الصلاحيات |
| role_permissions | 39 | 0.03 | ربط أدوار↔صلاحيات |
| user_roles | 4 | 0.03 | ربط مستخدمین↔أدوار |
| form_templates | 8 | 0.08 | القوالب |
| criteria | 15 | 0.03 | المعايير |
| criteria_sections | 38 | 0.05 | أقسام/أسئلة |
| template_versions | 0 | 0.03 | إصدارات القوالب |
| evaluations | 50 | 0.14 | التقييمات |
| evaluation_answers | 360 | 0.05 | الإجابات والدرجات |
| evaluation_schedules | 0 | 0.05 | جدولة الوحدات |
| course_catalog | 4 | 0.05 | لكتالوج الدورات |
| workshop_catalog | 3 | 0.03 | لكتالوج الورش |
| training_courses | 6 | 0.08 | الدورات |
| training_workshops | 3 | 0.06 | الورش |
| course_evaluations | 2 | 0.05 | تقييمات الدورات |
| workshop_evaluations | 2 | 0.03 | تقييمات الورش |
| evaluation_import_batches | 48 | 0.03 | دفعات استيراد |
| evaluation_import_rows | 1041 | 0.48 | صفوف الاستيراد |
| evaluation_import_row_errors | 1828 | 0.45 | أخطاء الاستيراد |
| admin_reports (جدولة) | admin_schedules 0 / admin_notifications 0 / admin_report_evaluators 0 | 0.11 | نظام التقييم الإداري |
| backup_logs | 3 | 0.06 | سجل النسخ |
| backup_encryption_keys | 0 | 0.03 | مفاتيح التشفير |
| backup_health_logs | 0 | 0.02 | سجل الصحة |
| backup_settings | 0 | 0.03 | إعدادات النسخ |
| audit_logs | 192 | 0.06 | سجل التدقيق |
| notifications | 5 | 0.03 | إشعارات |
| password_resets | 0 | 0.02 | استعادة كلمة المرور |
| settings | 5 | 0.02 | الإعدادات العامة |
| rating_settings | 4 | 0.02 | فئات التقدير (ضعيف/متوسط/جيد/ممتاز) |
| report_templates | 0 | 0.02 | قوالب تقارير (unified builder) |
| report_template_columns | 4 | 0.03 | أعمدة قوالب التقارير |
| csrf_tokens | 89 | 0.06 | توكنات CSRF |
| api_keys | (غیر مدرجة بالعد — انظر الملاحظة) | — | مفاتيح REST API |

> **ملاحظة:** جدول `api_keys` مستخدم بواسطة `ApiKey` model لكنه غير مُصدر في `db_live_schema.sql` (أُنشئ عبر `_emergency/create_api_keys_table.sql`). يجب التأكد من وجوده في الترحيلات.

---

## 4. المفاتيح الأساسية والأجنبية الرئيسية

| الجدول | PK | FKs رئيسية |
|---|---|---|
| branches | id | manager_id→employees.id (SET NULL) |
| departments | id | branch_id→branches.id (SET NULL) |
| employees | id | department_id, branch_id, position_id, manager_id (مرجع ذاتي) |
| users | id | employee_id→employees.id (UNIQUE, CASCADE) |
| evaluations | id | template_id, evaluated_employee_id, evaluator_employee_id, created_by_user_id, schedule_id |
| evaluation_answers | id | evaluation_id→evaluations.id (CASCADE), section_id→criteria_sections.id (CASCADE) |
| criteria | id | template_id→form_templates.id (CASCADE) |
| criteria_sections | id | criterion_id→criteria.id (CASCADE) |
| training_courses/workshops | id | branch_id, department_id, catalog_id (CASCADE) |
| course_evaluations | id | course_id→training_courses.id (UNIQUE 1:1, CASCADE) |
| workshop_evaluations | id | workshop_id→training_workshops.id (CASCADE) |

> الفهارس الكاملة وقيود UNIQUE/CHECK لكل جدول: راجع `appendices/db_live_schema.sql`.

---

## 5. الإجراءات المخزنة والمشاهدات والمشغلات

| النوع | الوجود |
|---|---|
| Stored Procedures | **لا يوجد** |
| Views (قواعد) | **لا يوجد** |
| Triggers | **لا يوجد** |
| Events | **لا يوجد** |

> جميع العمليات الحسابية (الأوزان، الصيغ، درجات التقييم) منفذة في طبقة PHP (`FormulaEngine`, `Evaluation`, `AnalysisModel`) وليس على مستوى قاعدة البيانات.

---

## 6. سكربتات الإنشاء والتعديل

| الملف | الوصف |
|---|---|
| `employee_evaluation_mvc (1).sql` | تصدير أساسي (نوفمبر 2025) — 26 جدولًا |
| `database/migrations/20260824_excel_import.sql` | جداول الاستيراد (batches/rows/errors) |
| `database/migrations/20260908_admin_reports_system.sql` | نظام التقرير الإداري + الصيغ + جداول admin_* |
| `_emergency/create_api_keys_table.sql` | جدول مفاتيح API |
| `_emergency/csrf_migration.sql` | جدول csrf_tokens |
| `_emergency/schema_before_phase1.sql` | لقطة ما قبل المرحلة 1 |
| `backups/*.sql.gz` | نسخ احتياطية قابلة للاستعادة |
| `appendices/db_live_schema.sql` | **اللقطة المرجعية الحية (2026-09-15)** |

**ملاحظة بهجرات منتظرة:** `مستند نصي جديد (2).txt` و `ألجداول الجديدة والتحسينات.txt` تحتويان عبارات ALTER (مثل `employees.nickname`، أعمدة `backup_logs`، جداول `backup_encryption_keys/backup_health_logs`). تحققت الدراسة من تطبيق معظمها على القاعدة الحية (الأعمدة موجودة) — لكن يُنصح بإخراجها إلى `database/migrations/` موثقة.

---

## 7. حجم البيانات الحالي

- إجمالي صفوف بارزة: تقييمات 50، إجابات 360، سجل تدقيق 192، صفوف استيراد 1041، أخطاء استيراد 1828.
- القاعدة الحالية صغيرة (<5 م.ب) — مناسبة للبيئة التشغيلية المحلية الحالية دون حاجة لقرارات أداء كبرى عاجلة، مع ملاحظة أن جداول الاستيراد تتضخم سريعًا (أخطاء الاستيراد 1828 صفًا).

---

**نهاية الوثيقة 05 — قاعدة البيانات**