<div dir="rtl">

# CD-020 — وثيقة تحليل وتصميم النظام الشاملة (SRS & System Design Document)

| البند | القيمة |
|---|---|
| **رقم الوثيقة** | CD-020 |
| **العنوان** | وثيقة تحليل وتصميم النظام — Employee 360 Record + Immutable Reports Engine |
| **المرجع** | التوجيه CD-020 الصادر عن كبير المستشارين (إدارة المشروع) |
| **إصدار الوثيقة** | **2.0** (مُعاد تأسيسها بعد حل تعارض الحالة) |
| **المُعِدّ** | المطور الجديد |
| **التاريخ** | 2026-11-03 (v2.0) · 2026-10-22 (v1.0) |
| **الحالة** | ⏳ بانتظار اعتماد كبير المستشارين وإدارة المشروع |
| **النسخة المستهدفة** | v1.1.0 (ما بعد Pilot) |
| **القاعدة المرجعية (v2.0)** | `employee-evaluation` @ **`54ee0e5`** (CD-015) · `employee-evaluation-docs` @ **`ad7ffd1`** (CD-019) |
| **القاعدة المرجعية (v1.0 سابقاً)** | ~~`employee-evaluation` @ `4bb59f2` (CD-014)~~ · ~~`employee-evaluation-docs` @ `6b14510` (CD-014)~~ |

> **⚠️ ملاحظة الإصدار:** هذه الوثيقة هي **v2.0** — أعيد كتابتها بالكامل بعد حل تعارض الحالة (State Mismatch) المذكور في رسالة إدارة المشروع بتاريخ 2026-11-03. الإصدار v1.0 (المسلَّم بتاريخ 2026-10-22) كان مبنياً على نسخة محلية قديمة من المستودع تنتهي عند CD-014، بينما المستودع الفعلي على GitHub متقدّم حتى CD-015 (كود) وCD-019 (توثيق). الفصل §0.2 يوثّق القصة الكاملة. **v1.0 محلول ولا يُعتمد**؛ v2.0 هي المرجع الرسمي.

---

## 0. ملخص تنفيذي وحل تعارض الحالة

### 0.1 ملخص تنفيذي (v2.0)

بعد حل تعارض الحالة وإعادة التأسيس على النسخة الفعلية للمستودع (CD-015..CD-019)، يتضح أن **ركائز CD-020 الأربع مُنفَّذة وظيفياً بالكامل** عبر توجيهات CD-016 (تأسيس التقييم وسلم التقديرات)، CD-017 (ملف الموظف وسجل التقييمات)، CD-018 (محرك التقارير الثابتة)، وCD-015 (إزالة طبقة التقارير القديمة). 

من فجواتي الـ16 الأصلية في v1.0: **13 فجوة مُنجَزة**، **2 جزئية** (تفاصيل الترويسة/التوقيعات، وقاعدة emp_code الضمنية)، **1 مغطّاة ضمنياً**. الاختبارات الآن **109/109** (تطابق ما ذكره التوجيه CD-020 تماماً)، والـ Triggers **6** (4 أصلية + 2 للـ Immutability).

ما تبقّى من العمل بعد الاعتماد هو **تحسينات وتنظيفات محدودة** + معالجة **3 اكتشافات جديدة** (فجوة CHANGELOG، انحراف ترحيلات العروض المحذوفة، UAT غير مكتمل)، وليس بناء ركائز من الصفر. خطة التنفيذ المحدّثة (§6) تقلّصت من 15 يوماً إلى **~6 أيام**.

### 0.2 قصة حل تعارض الحالة (State Mismatch Resolution) — توثيق صادق

| المرحلة | ما حدث |
|---|---|
| **الاستكشاف الأول (v1.0)** | استنسختُ المستودعين بتاريخ 2026-10-22. آخر commit كان `4bb59f2` (كود) و`6b14510` (توثيق) — كلاهما CD-014. نفّذتُ `git pull --ff-only` فأرجع: «Already up to date». وثّقتُ في §0.2 من v1.0 أن «تقارير CD-016/017/018 غير موجودة فعلياً». |
| **رسالة إدارة المشروع** | بتاريخ 2026-11-03 أبلغتني بأن المطور السابق رفع CD-016/017/018 (Commits: `32f8f96`, `a017f7c`, `a16340c`)، وطلبت التحقق. |
| **التحقق المنهجي** | نفّذتُ `git fetch --all --prune --tags` على المستودعين. النتيجة: المستودع البعيد متقدّم فعلاً. سحبتُ التحديثات: الكود تقدّم `4bb59f2 → 54ee0e5`، التوثيق تقدّم `6b14510 → ad7ffd1`. |
| **النتيجة** | **المطور السابق صدق.** الـ Commits الثلاثة موجودة على `origin/master`، بالإضافة إلى `54ee0e5` (CD-015) و`7ddbece`..`ad7ffd1` (توثيق CD-015..019). تعارض الحالة كان بسبب أن نسختي المحلية كانت قديمة (السبب المرجّح: توقيت الاستنساخ الأول كان قبل الدفع، أو `--ff-only` واجه حالة cache). |

**سجل git المؤكد (المستودع الفعلي على GitHub):**

```
الكود (employee-evaluation @ origin/master):
54ee0e5 refactor(CD-015): remove legacy reporting modules
a16340c feat(CD-018): add immutable report snapshots and export
a017f7c feat(CD-017): add employee profile and evaluation history
32f8f96 feat(CD-016): establish evaluation grading foundation
4bb59f2 feat(CD-014/OOS-18): remove isAdmin() bypass ...   ← (نهاية v1.0)

التوثيق (employee-evaluation-docs @ origin/master):
ad7ffd1 docs(CD-019): update v1.1 guides and UAT status
46262d6 docs(OOS-21): defer PhpSpreadsheet advisory remediation
7ddbece docs(CD-015): document reporting removal
50db400 docs(CD-018): document report snapshots
1ab2c7a docs(CD-017): document employee profile implementation
34a1be2 docs(CD-016): document implementation
6b14510 docs(CD-014): OOS-18 closure ...   ← (نهاية v1.0)
```

**إلغاء إقرار v1.0 §0.2 البند #1:** جملة «تقارير CD-016/017/018 غير موجودة فعلياً» **ملغاة**. التقارير موجودة ومُطبَّقة في الكود والتوثيق. أعتذر عن القصور في الاستكشاف الأول؛ والسبب لم يكن اختلاقاً بل توقيت استنساخ + `git pull` لم يلتقط التحديث (ربما cache أو race). منهجيتي الآن: `git fetch --all` دائماً قبل أي `pull`.

### 0.3 الإقرارات المنهجية المحدّثة (v2.0)

| # | الاكتشاف | الحالة في v2.0 |
|---|---|---|
| ~~1~~ | ~~غياب CD-016/017/018~~ | ✅ **حُلّ** — موجودة ومُنفَّذة (انظر §0.2) |
| 2 | عدد الاختبارات | **109 بالضبط** (تطابق التوجيه CD-020). الحساب: 113 (قبل CD-015) − 10 (ReportEngineTest محذوف) + 2 (CD-016) + 2 (CD-017) + 2 (CD-018) = 109. |
| ~~3~~ | ~~ملف `profile.php` فارغ (0 بايت)~~ | ✅ **حُلّ** — CD-017 عمّره إلى 190 سطراً بـ 4 تبويبات. |
| 4 | مساران ميتان (`reports/save-template`, `reports/print`) | ✅ **حُلّ ضمنياً** — CD-015 حذف `ReportsController` بالكامل، فالمسارات اختفت معه. |
| 5 | النسخ الاحتياطي لا يأخذ Triggers | ✅ **حُلّ** — `Deployment_Guide.md` §4 الآن يستخدم `mysqldump --triggers` صراحةً. |

---

## 1. فهم النظام الحالي (Current System Understanding — v2.0)

> **تغيير جوهري عن v1.0:** طبقة التقارير القديمة (11 Controller + 6 Model + ReportEngine + 60 View + 3 SQL Views) **حُذفت بالكامل** في CD-015، واستُبدلت بمحرك اللقطات الثابتة في CD-018. هذا القسم يعكس الوضع الفعلي بعد CD-015..CD-019.

### 1.1 البنية التحتية (Architecture)

النظام لا يزال **PHP 8.2 MVC مخصص** بنفس دورة حياة الطلب. **لكن المخطط تقلّص**:

| الكيان | v1.0 (CD-014) | v2.0 (CD-015) | التغيير |
|---|---|---|---|
| Controllers | 43 | **34** | −9 (حذف التقارير القديمة) +2 (جديد: `EmployeeReportController`, `GradingScaleController`) |
| Models | 29 | **24** | −6 (AnalysisModel, ArchiveModel, ReportModel, ReportTemplateModel, TrainingReport, WorkshopReport) +1 (GradingScale) |
| Services (`app/Services/`) | 4 | **7** | −1 (ReportEngine) +4 (EmployeeReportService, ReportSnapshotService, ReportExportService) |
| Views | 135 | ~**75** | −60 (مجلدات reports/analysis/admin-reports/archive/performance/statistics) |
| Routes | ~170 | ~**120** | −50 (التقارير/التحليل/الأرشيف) +6 (profile + reports/grading-scales) |

**الاعتماديات (`composer.json` v2.0):**
- PDF: `dompdf ^3.1` · `tcpdf ^6.10` · `mpdf ^8.0`
- Excel: `phpoffice/phpspreadsheet ^1.29` (⚠️ OOS-21: 1.30.6 مؤثرة بـ 3 تنبيهات أمنية، مؤجَّلة لـ v0.2.0)
- **Word: `phpoffice/phpword ^1.4`** ✅ (جديد في CD-018)
- Arabic: `khaled.alshamaa/ar-php ^7.0`
- Dev: `phpunit ^11.5`

### 1.2 باني القوالب (Form Builder) — تحديث CD-016

CD-016 أضاف عمودين على `form_templates` (دون لمس باني القوالب نفسه):
- **`evaluation_mode`** enum('numeric','descriptive','mixed') DEFAULT 'numeric'
- **`evaluation_frequency`** enum('yearly','quarterly','monthly','ad-hoc') DEFAULT 'yearly'

> **ملاحظة:** CD-020 (القاعدة الحمراء #2) يمنع لمس باني القوالب. CD-016 التزم بذلك — أضاف العمودين على مستوى الـ schema فقط، و`BuilderController::save()` يكتب القيمتين. **لا تعديل على منطق الباني.**

### 1.3 التقارير الحالية (Current Reports — v2.0)

طبقة التقارير **أعيد تصميمها بالكامل**. الحالي:

| المكوّن | الوصف |
|---|---|
| **`EmployeeReportController`** (101 سطر) | `generate($employeeId)` POST + CSRF → ينشئ snapshot · `show($employeeId, $snapshotId)` → يعرض التقرير · `export($employeeId, $snapshotId, $format)` → يصدّر pdf/xlsx/docx |
| **`GradingScaleController`** (146 سطر) | CRUD لأسلّم التقديرات، محمي بـ `grading_scales.manage` |
| **`EmployeeReportService`** (190 سطر) | ينتج بيانات التقرير: سجل التقييمات + 5 متوسطات (`overall/annual/periodic/course/workshop`) + `summarizeByYear()` (يشمل السنوات الفارغة كـ NULL لا صفر) |
| **`ReportSnapshotService`** (163 سطر) | `createForEmployee()` — يولّد serial داخل معاملة DB (`LAST_INSERT_ID(last_number+1)`) + يحفظ JSON · `listForEmployee()` · `findForEmployee()` |
| **`ReportExportService`** (219 سطر) | `render($format, $snapshot)` — يولّد PDF (mPDF+RTL) / XLSX (PhpSpreadsheet+RTL) / DOCX (PhpWord) **من `snapshot_json` المحفوظ، لا إعادة احتساب** |

**المسارات الحالية للتقارير/الملف (كل ما تبقى):**
```
GET    employees/profile/:id                              → EmployeeController@profile
POST   employees/profile/:id/reports                      → EmployeeReportController@generate
GET    employees/profile/:id/reports/:reportId            → EmployeeReportController@show
GET    employees/profile/:id/reports/:reportId/export/:format  → EmployeeReportController@export
GET    grading-scales                                     → GradingScaleController@index
POST   grading-scales                                     → GradingScaleController@store
POST   grading-scales/delete                              → GradingScaleController@destroy
```

> **ما حُذف كلياً (CD-015):** `reports/builder`, `reports/analytics/*`, `reports/unified`, `reports/statistics`, `analysis/*`, `archive/courses/*`, `archive/workshops/*`, `admin/reports/*`, `courses|workshops|units|employees/performance-files`, `reports/training-dashboard`, `reports/workshop-dashboard`. **مجلد `app/Views/reports/` لم يعد موجوداً.**

### 1.4 نموذج البيانات الحالي (v2.0)

**الجداول الجديدة (CD-016 + CD-018):**

#### جدول `grading_scales` (CD-016)
```sql
CREATE TABLE grading_scales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scale_name VARCHAR(100) NOT NULL,
    grade_label VARCHAR(50) NOT NULL,
    min_value DECIMAL(5,2) NOT NULL,
    max_value DECIMAL(5,2) NOT NULL,
    numeric_value DECIMAL(3,2) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_grading_scale_label (scale_name, grade_label),
    KEY idx_grading_scales_order (scale_name, is_active, sort_order, min_value)
) ENGINE=InnoDB;
-- 5 صفوف seed: ممتاز(90-100→5.0) · جيد جداً(80-89.99→4.0) · جيد(70-79.99→3.0) · مقبول(60-69.99→2.0) · ضعيف(0-59.99→1.0)
```

#### جدول `report_snapshots` + `report_snapshot_counters` (CD-018)
```sql
CREATE TABLE report_snapshot_counters (
    id TINYINT UNSIGNED NOT NULL,
    last_number BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE TABLE report_snapshots (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    report_number VARCHAR(24) NOT NULL,           -- صيغة: ER-00000001 (8 أرقام)
    employee_id INT NOT NULL,
    created_by_user_id INT NOT NULL,
    snapshot_json JSON NOT NULL,                  -- كل البيانات (لا pdf_blob)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_report_snapshots_number (report_number),
    KEY idx_report_snapshots_employee (employee_id, id),
    CONSTRAINT fk_report_snapshots_employee FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT,
    CONSTRAINT fk_report_snapshots_creator FOREIGN KEY (created_by_user_id)
        REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الأعمدة الجديدة على `evaluations` (CD-016):**
- `evaluation_type` enum('annual','periodic','course','workshop') NULL — بعد `evaluation_date`
- `final_grade_label` varchar(50) NULL — بعد `final_score`
- `final_grade_value` decimal(5,2) NULL — بعد `final_grade_label`

**الأعمدة الجديدة على `form_templates` (CD-016):**
- `evaluation_mode` enum('numeric','descriptive','mixed') NOT NULL DEFAULT 'numeric'
- `evaluation_frequency` enum('yearly','quarterly','monthly','ad-hoc') NOT NULL DEFAULT 'yearly'

### 1.5 الـ Triggers الحالية (v2.0) — 6 إجمالاً

| # | الاسم | الجدول | الحدث | الوظيفة | المصدر |
|---|---|---|---|---|---|
| 1 | `cd004_trg_user_roles_ai` | user_roles | AFTER INSERT | bump permissions_version | CD-004 |
| 2 | `cd004_trg_user_roles_ad` | user_roles | AFTER DELETE | bump permissions_version | CD-004 |
| 3 | `cd004_trg_role_permissions_ai` | role_permissions | AFTER INSERT | bump permissions_version | CD-004 |
| 4 | `cd004_trg_role_permissions_ad` | role_permissions | AFTER DELETE | bump permissions_version | CD-004 |
| **5** | **`report_snapshots_block_update`** | **report_snapshots** | **BEFORE UPDATE** | **`SIGNAL SQLSTATE '45000'`** | **CD-018** |
| **6** | **`report_snapshots_block_delete`** | **report_snapshots** | **BEFORE DELETE** | **`SIGNAL SQLSTATE '45000'`** | **CD-018** |

اقتباس حرفي للـ Triggers الجديدة (CD-018):
```sql
CREATE TRIGGER report_snapshots_block_update
    BEFORE UPDATE ON report_snapshots FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report snapshots are immutable';

CREATE TRIGGER report_snapshots_block_delete
    BEFORE DELETE ON report_snapshots FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report snapshots are immutable';
```

### 1.6 الأمان والاختبارات (v2.0)

**الأمان:** كما في v1.0 + صلاحيتان جديدتان (CD-016/017):
- `grading_scales.manage` (CD-016) — مُنحة لـ Admin
- `employees.profile` (CD-017) — مُنحة لكل دور يملك `employees.view`

**الاختبارات:** **109/109 PASS** (تطابق التوجيه CD-020):

| الملف | دوال `test*` | ملاحظة |
|---|---|---|
| `tests/cases/Core/AuthTest.php` | 62 | |
| `tests/cases/Core/NotificationTest.php` | 13 | |
| `tests/cases/Models/EmployeeManagerTest.php` | 9 | |
| `tests/cases/Core/RouterTest.php` | 7 | |
| `tests/cases/Core/DatabaseTest.php` | 5 | |
| `tests/cases/Models/UserTest.php` | 3 | |
| `tests/cases/Core/HelpersTest.php` | 3 | |
| `tests/cases/Services/EmployeeReportServiceTest.php` | **2** | 🆕 CD-017 |
| `tests/cases/Services/ReportSnapshotServiceTest.php` | **2** | 🆕 CD-018 |
| `tests/cases/Controllers/UserControllerTest.php` | 1 | |
| `tests/cases/Models/GradingScaleTest.php` | **1** | 🆕 CD-016 |
| `tests/cases/Models/TemplateEvaluationMetadataTest.php` | **1** | 🆕 CD-016 |
| ~~`tests/cases/Reporting/ReportEngineTest.php`~~ | ~~10~~ | ❌ حُذف في CD-015 |
| **المجموع** | **109** | |

**تغطية اختبارات CD-020 الجديدة (موجودة فعلاً):**
- `EmployeeReportServiceTest`: تحويل قيم · تقسيم متوسطات · استبعاد مسودات · فجوة سنة · موظف بلا سجل
- `ReportSnapshotServiceTest`: رقم تسلسلي · حفظ هوية المنشئ وبيانات الموظف · **رفض UPDATE/DELETE على مستوى DB** (اختبار Immutability مباشر) · تغيّر اسم الموظف دون تغيّر النسخة · النسخة الثانية = الأولى + 1 · صحة magic bytes لـ PDF/XLSX/DOCX
- `GradingScaleTest`: CRUD + تداخل النطاقات
- `TemplateEvaluationMetadataTest`: إنشاء قالب بـ `evaluation_mode=descriptive, evaluation_frequency=quarterly` + تحديث + `updateScoreGradeAndStatus`

---

## 2. تحليل الفجوات (Gap Analysis — v2.0)

### 2.1 إعادة تقييم الفجوات الـ16 (الأهم)

| # | الفجوة الأصلية (v1.0) | الحالة بعد CD-015..019 | الدليل |
|---|---|---|---|
| **G1** | Employee 360 Record (`/employees/profile/:id` بـ 4 تبويبات) | ✅ **مُنفَّذ** (CD-017) | route + `profile()` method + `profile.php` (190 سطر) + 4 تبويبات فعلية |
| **G2** | Annual Evaluation | ✅ **موجود سلفاً** | قالب id=1 + `calculateFinalScore` |
| **G3** | Descriptive Evaluation | ✅ **مُنفَّذ** (CD-016) | `evaluation_mode='descriptive'` على `form_templates` + `final_grade_label/value` على `evaluations` |
| **G4** | Numeric Course + Grading Scale | ✅ **مُنفَّذ** (CD-016) | جدول `grading_scales` + 5 صفوف seed + CRUD + دالة ترجمة |
| **G5** | Periodic (شهري/ربع سنوي) | ✅ **مُنفَّذ** (CD-016) | `evaluation_frequency` enum + `evaluation_type='periodic'` + `periodic_avg` مستقل |
| **G6** | Averages Engine | ✅ **مُنفَّذ وظيفياً** (CD-017) | `EmployeeReportService::summarize()` يحسب 5 متوسطات |
| **G7** | قاعدة السنوات الفارغة | ✅ **مُنفَّذ** (CD-017) | `summarizeByYear()` — السنوات الفارغة = NULL لا صفر، مُختبَر |
| **G8** | استثناء السجلات بلا `emp_code` | ⚠️ **مغطّى ضمنياً** | `emp_code` هو `NOT NULL UNIQUE` في الـ schema + القراءة عبر `evaluated_employee_id` FK صارم. لكن **لا فلتر صريح `WHERE emp_code != ''`** في `EmployeeReportService`. |
| **G9** | Immutable Reports Engine (Snapshot JSON+PDF) | ✅ **مُنفَّذ** (CD-018) | جدول `report_snapshots` + `snapshot_json` JSON + Triggers |
| **G10** | رقم تسلسلي | ✅ **مُنفَّذ** (CD-018) | `report_snapshot_counters` + `LAST_INSERT_ID(last_number+1)` + صيغة `ER-00000001` |
| **G11** | ترويسة التقرير (شعار + serial + تاريخ + بيانات + جداول + نتيجة + توقيعات) | ⚠️ **جزئي** | اللقطة JSON تحوي: الموظف + التقييمات + 5 متوسطات + هوية المنشئ + التاريخ + رقم التقرير. `ReportExportServiceTest` يتحقق من «صحة ترويسات PDF/XLSX/DOCX». **لكن وثيقة CD-018 لا تذكر صراحةً**: (أ) الشعار (logo)، (ب) كتلة التوقيعات (signatures) في قالب التصدير. يحتاج تحقق من محتوى القالب الفعلي. |
| **G12** | DB Triggers لمنع التعديل/الحذف | ✅ **مُنفَّذ** (CD-018) | `BEFORE UPDATE` + `BEFORE DELETE` بـ `SIGNAL SQLSTATE '45000'` + FK RESTRICT |
| **G13** | تصدير PDF | ✅ **مُنفَّذ** | mPDF + RTL، من `snapshot_json` |
| **G14** | تصدير Excel | ✅ **مُنفَّذ** | PhpSpreadsheet + `setRightToLeft(true)`، من `snapshot_json` (⚠️ OOS-21) |
| **G15** | تصدير Word (PHPWord) | ✅ **مُنفَّذ** (CD-018) | `phpoffice/phpword ^1.4` + `renderDocx()` + مسار `/export/docx` |
| **G16** | زر «توليد تقرير جديد» بصلاحية | ✅ **مُنفَّذ** (CD-018) | زر في تبويب التقارير + POST + CSRF + guard `employees.profile` |

**خلاصة الفجوات:** 13 ✅ مُنجَزة · 2 ⚠️ جزئية (G8, G11) · 1 مغطّاة ضمنياً (G8). **لا فجوة حرجة متبقية.** الركائز الأربع مكتملة وظيفياً.

### 2.2 انحرافات تصميمية بين v1.0 والتنفيذ الفعلي (6 انحرافات)

هذه ليست فجوات بل اختلافات بين ما اقترحته v1.0 وما بناه المطور السابق فعلاً. وثّقتُها للشفافية:

| # | اقتراح v1.0 | التنفيذ الفعلي (CD-016..018) | التقييم |
|---|---|---|---|
| **D1** | إضافة `descriptive` لـ enum `criteria_sections.evaluation_type` + عمود `manual_overall_grade` | `evaluation_mode` enum على **`form_templates`** (numeric/descriptive/mixed) + `final_grade_label`/`final_grade_value` على **`evaluations`** | ✅ التنفيذ أنظف — النمط على مستوى القالب (لا القسم)، والتقدير على مستوى التقييم. |
| **D2** | جدولان: `grading_scales` + `grading_scale_entries` فرعي + FK `grading_scale_id` | جدول **واحد** `grading_scales` (صف لكل تقدير) + **لا FK** — الترجمة برمجياً عبر النطاقات في `EmployeeReportService` | ⚠️ التصميم أبسط لكنه يكرّر `scale_name` في كل صف. مقبول. |
| **D3** | Service مستقل `AveragesEngine.php` + دالة `computeEmployeeAverages($id)` | المنطق مُدمج في **`EmployeeReportService::summarize()`** + مفاتيح `overall/annual/periodic/course/workshop` (لا `general_avg`/`course_avg`) | ⚠️ انحراف معماري — يُنصح باستخلاص `AveragesEngine` مستقل لاحقاً (Sprint 2 من خطة v2.0). |
| **D4** | تخزين `pdf_blob` LONGBLOB + `pdf_sha256` + `final_result_json` منفصلة في `report_snapshots` | **JSON فقط** (`snapshot_json`) — PDF/Excel/Word تُولَّد **عند الطلب** من JSON | ✅ التنفيذ أنظف وأقل استهلاكاً للـ DB. العيب: إعادة توليد PDF كل طلب (مقبول للأحجام الحالية). |
| **D5** | صيغة serial: `RPT-YYYY-NNNNNN` | صيغة serial: **`ER-00000001`** (8 أرقام ثابتة، بلا سنة) | ⚠️ صيغة أبسط لكنها تفقد قابلية التتبع الزمني من الرقم وحده. مقبول. |
| **D6** | صلاحية جديدة `reports.generate` + `reports.view.*` | صلاحية موحَّدة **`employees.profile`** (تغطي العرض + الإنشاء + التصدير) | ⚠️ أبسط إدارياً لكنه يخلط العرض بالإنشاء. مقبول للـ Pilot. |

---

## 3. اكتشافات جديدة (New Findings — v2.0)

أثناء إعادة التأسيس، اكتشفتُ **3 مشكلات جديدة** لم تُوثّق في v1.0 ولا في تقارير CD-015..019. يجب معالجتها قبل الإطلاق:

### 3.1 فجوة CHANGELOG (Documentation Gap) 🔴

`CHANGELOG.md` في مستودع التوثيق **لا يحوي إدخالات لـ CD-016 ولا CD-017**، رغم وجود ملفات تنفيذهما وتقاريرهما. الإدخالات الموجودة في الأعلى: CD-019 · CD-018 · CD-015 · OOS-21. **CD-016 و CD-017 مفقودتان تماماً.**

**الأثر:** أي مراجع لتاريخ المشروع يرى قفزة من CD-015 إلى CD-018 دون تفسير لأسلّم التقديرات وملف الموظف. 
**الإجراء:** إضافة إدخالين بأثر رجعي في `CHANGELOG.md` (Sprint 1).

### 3.2 انحراف ترحيلات العروض/الجداول المحذوفة (Migration Drift) 🟡

CD-015 حذف من **قاعدة البيانات الحية** العروض الثلاثة (`vw_evaluation_facts`, `vw_employee_scores`, `vw_criteria_averages`) والجداول (`report_templates`, `report_template_columns`, `admin_schedules`). **لكن:**

- ملف `database/migrations/2026_10_19_CD008_reporting_views.sql` و`_fixed.sql` **لا يزالان يحويان `CREATE VIEW`** لهذه العروض.
- ملف `database/migrations/20260908_admin_reports_system.sql` **لا يزال يحوي `CREATE TABLE`** لـ `admin_schedules` و`report_templates` و`report_template_columns`.

**الأثر:** أي بناء جديد لقاعدة البيانات من الترحيلات (fresh install) سـ **يُعيد إنشاء** هذه الكائنات المحذوفة، مما يخلق تضارباً بين الـ DB instance والـ source.
**الإجراء:** إنشاء ترحيل `DROP` صريح `2026_11_03_CD020_drop_legacy_reporting_objects.sql` (Sprint 1).

### 3.3 UAT غير مكتمل 🟡

`UAT_Script.md` v1.1.0 يعرّف **9 سيناريوهات** (دخول · مستخدم · موظف · قالب+تقييم سنوي · تقييم وصفي · ملف الموظف · تقرير+تصدير · ثبات التقرير · استيراد قديم). **الحالة الراهنة:**
- السيناريو 1: «ناجح جزئياً» (تسجيل دخول فقط)
- السيناريوهات 2–9: «لم يُنفذ» — بانتظار اعتماد نطاق بيانات الاختبار + نسخة احتياطية حديثة
- **لا توقيع اعتماد UAT بعد**

**الإجراء:** تجهيز بيئة UAT + تنفيذ السيناريوهات (Sprint 3).

### 3.4 OOS-21 (مؤجَّل لـ v0.2.0) — للعلم

`composer audit` 2026-11-03 كشف 3 تنبيهات أمنية في `phpoffice/phpspreadsheet` 1.30.6:
- `PKSA-r15m-kszr-8n8q` — SSRF عبر `Drawing::setPath`
- `PKSA-dxd5-wy68-pq29` — استنزاف CPU/ذاكرة ODS
- `PKSA-96jv-mtjg-g2v8` — تجاوز فاحص XML → XXE/DoS

**القرار الموثّق:** إبقاء النسخة في Pilot، الترقية لإصدار مصحّح (≥ 1.30.7) في v0.2.0. **لا إجراء في CD-020.**

---

## 4. تصميم الواجهات (Wireframes — v2.0: كما هو مبنى فعلاً)

### 4.1 شاشة ملف الموظف — `/employees/profile/:id` (مبنية في CD-017)

ملف `app/Views/employees/profile.php` (190 سطر) — **4 تبويبات فعلية:**

| التبويب | المحتوى الفعلي | مصدر البيانات |
|---|---|---|
| **① البيانات** | الاسم، الرقم الوظيفي، اللقب، البريد، الهاتف، الفرع، القسم، المنصب، المدير، تاريخ الالتحاق، الحالة | `Employee::findById` |
| **② التقييمات** | جدول التقييمات المعتمدة/المكتملة (التاريخ، النوع، القالب، الدرجة، التقدير) | `EmployeeReportService::getProfileReport` (فلتر `status IN ('approved','completed')`) |
| **③ التقارير** | زر «إنشاء التقرير وحفظ نسخة ثابتة» (POST + CSRF) + **5 بطاقات متوسطات** (عام/سنوي/دوري/دورة/ورشة) + جدول «المتوسط حسب السنة» + جدول «سجل التقارير المحفوظة» مع روابط عرض/PDF/Excel/Word | `EmployeeReportService` + `ReportSnapshotService::listForEmployee` |
| **④ الإجراءات** | زر بدء تقييم جديد (إن وُجدت `evaluations.create`) + زر تعديل بيانات الموظف (`employees.edit`) | guards |

**الفرق عن Wireframe v1.0:** المتوسطات تظهر داخل تبويب **التقارير** (لا تبويب مستقل)، وتبويب **الإجراءات** يحوي بدء تقييم + تعديل (لا «توليد تقرير» فقط). التصميم الفعلي أنظف عملياً.

### 4.2 شاشة عرض التقرير — `/employees/profile/:id/reports/:reportId` (مبنية في CD-018)

ملف `app/Views/employees/report.php` (86 سطر):
- رقم التقرير (`ER-00000001`) + تاريخ الإنشاء
- بيانات الموظف **وقت الحفظ** (من `snapshot_json`، لا البيانات الحالية)
- 5 بطاقات متوسطات (عام/سنوي/دوري/دورة/ورشة)
- جدول التقييمات المحفوظة
- أزرار تصدير: **PDF / Excel / Word**

> **⚠️ الفجوة G11:** العرض الحالي لا يُظهر صراحةً **الشعار (logo)** ولا **كتلة التوقيعات (signatures)**. إن كانت الرؤية تتطلب توقيعات مدير HR + المدير المباشر + الموظف، يجب إضافتها لقالب التصدير (Sprint 2).

---

## 5. المنطق البرمجي (Business Logic — v2.0: كما هو مبنى فعلاً)

### 5.1 تدفق توليد التقرير (Snapshot Generation) — الفعلي

```php
// app/Controllers/EmployeeReportController.php (موجود فعلاً، CD-018)

public function generate($employeeId): void
{
    Auth::enforce('employees.profile');              // guard موحَّد (D6)
    $employeeId = (int)$employeeId;
    Auth::validateCsrfToken($_POST['_csrf'] ?? '');  // CSRF

    $employee = (new Employee())->findById($employeeId);
    if (!$employee) { (new ErrorController())->notFound(); return; }

    // إنشاء اللقطة (atomic، داخل معاملة DB)
    $snapshot = (new ReportSnapshotService())
        ->createForEmployee($employeeId, Auth::id());

    Audit::log('REPORT_ISSUED', 'report_snapshots', $snapshot['id'], [...]);

    Flash::success("تم إصدار التقرير رقم {$snapshot['report_number']}");
    $this->redirect("employees/profile/{$employeeId}/reports/{$snapshot['id']}");
}
```

### 5.2 توليد الرقم التسلسلي — الفعلي (CD-018)

```php
// app/Services/ReportSnapshotService::createForEmployee()

$db->beginTransaction();
// 1. زيادة العداد آمناً ضمن المعاملة:
$db->query("UPDATE report_snapshot_counters 
            SET last_number = LAST_INSERT_ID(last_number + 1) WHERE id = 1");
$seq = (int)$db->lastInsertId();              // ← LAST_INSERT_ID() من التحديث
// 2. صياغة الرقم:
$reportNumber = 'ER-' . str_pad((string)$seq, 8, '0', STR_PAD_LEFT);  // ER-00000001
// 3. بناء snapshot_json:
$snapshotJson = json_encode([
    'version' => 1,
    'generated_at' => date('c'),
    'created_by' => ['user_id' => $userId, 'username' => $username],
    'employee' => [...],                       // emp_code, full_name, position, dept, branch
    'report' => (new EmployeeReportService())->getProfileReport($employeeId),
    'report_number' => $reportNumber,
], JSON_UNESCAPED_UNICODE);
// 4. INSERT (atomic + محمي بـ Triggers ضد UPDATE/DELETE لاحقاً):
$id = (new ReportSnapshot())->create([...]);
$db->commit();
```

### 5.3 محرك المتوسطات — الفعلي (CD-017، مدمج في `EmployeeReportService`)

```php
// app/Services/EmployeeReportService::summarize()
// يحسب 5 متوسطات لموظف:
$summary = [
    'overall'  => summarize($allApprovedCompleted),       // كل التقييمات
    'annual'   => summarize($where evaluation_type='annual'),
    'periodic' => summarize($where evaluation_type='periodic'),
    'course'   => summarize($where evaluation_type='course'),
    'workshop' => summarize($where evaluation_type='workshop'),
];
// كل متوسط = {evaluation_count, scored_count, average, grade_label}
// الترجمة: grade_value = GradingScale::nearestGradeLabel($score)  // من السلم الخماسي النشط

// summarizeByYear() — يشمل السنوات الفارغة كـ NULL (قاعدة G7):
//   2024 → avg=85.0
//   2025 → NULL  (لا تقييم، لا تُحسب كصفر)
//   2026 → avg=91.2
```

> **ملاحظة D3:** المنطق يعمل لكنه **مُدمج** في `EmployeeReportService` لا في `AveragesEngine` مستقل. هذا مقبول وظيفياً لكنه يخلط مسؤولية «جلب البيانات» مع «حساب المتوسطات». الاستخلاص لـ `AveragesEngine` مستقل هو تحسين اختياري (Sprint 2).

### 5.4 تصدير التقارير — الفعلي (CD-018)

```php
// app/Services/ReportExportService::render($format, $snapshot)
// يولّد من snapshot_json المحفوظ (لا إعادة احتساب):
switch ($format) {
    case 'pdf':  return renderPdf($snapshot);   // mPDF + HTML RTL
    case 'xlsx': return renderXlsx($snapshot);  // PhpSpreadsheet + setRightToLeft(true)
    case 'docx': return renderDocx($snapshot);  // PhpWord + جدول المتوسطات + Jc::END
}
```

### 5.5 حماية الـ Immutability — الفعلي (CD-018)

**طبقتان (كما اقترحت v1.0، ومُنفَّذتان فعلاً):**

1. **طبقة DB (Triggers):** `BEFORE UPDATE` + `BEFORE DELETE` على `report_snapshots` تطلق `SIGNAL SQLSTATE '45000'`. **مُختبَر مباشرة** في `ReportSnapshotServiceTest::testSnapshotHasSerialNumberAndRejectsUpdatesAndDeletes` — ينفّذ `UPDATE` و`DELETE` ويتوقع `PDOException`.
2. **طبقة التطبيق:** `ReportSnapshotService` لا يُعرّض `update()` ولا `delete()` — فقط `createForEmployee()` + `listForEmployee()` + `findForEmployee()`.

**اختبار إضافي مُنفَّذ:** تغيير اسم الموظف بعد إنشاء snapshot → التحقق أن الـ snapshot لا تزال تحمل الاسم القديم (`CD018 Snapshot Fixture`). هذا يثبت أن البيانات مُجمَّدة وقت الإنشاء.

---

## 6. خطة التنفيذ (Implementation Plan — v2.0: مُقلَّصة)

بما أن الركائز الأربع مُنفَّذة، تقلّصت الخطة من 15 يوماً (v1.0) إلى **~6 أيام**. تركز على إغلاق الاكتشافات الجديدة + التحسينات الاختيارية.

### Sprint 0 — التحقق والاستنساخ (1 يوم)

| المهمة | المخرج |
|---|---|
| 0.1 `git fetch --all` + التأكد من HEAD = `54ee0e5`/`ad7ffd1` | تحقق |
| 0.2 `composer install` + `php tests/runner.php` = 109/109 PASS | تقرير اختبارات |
| 0.3 تطبيق الترحيلات CD-016/017/018 على DB الإعداد | DB محدّث |
| 0.4 نسخة احتياطية كاملة قبل أي تعديل | backup |

### Sprint 1 — إغلاق الاكتشافات الجديدة (2 يوم)

| المهمة | المخرج | الاكتشاف |
|---|---|---|
| 1.1 إضافة إدخالي CD-016 + CD-017 لأثر رجعي في `CHANGELOG.md` | docs | §3.1 |
| 1.2 إنشاء ترحيل `2026_11_03_CD020_drop_legacy_reporting_objects.sql`: `DROP VIEW vw_evaluation_facts/employee_scores/criteria_averages` + `DROP TABLE report_templates/report_template_columns/admin_schedules` (idempotent `IF EXISTS`) | migration | §3.2 |
| 1.3 إضافة فلتر صريح `WHERE emp_code IS NOT NULL AND emp_code != ''` في `EmployeeReportService::getProfileReport` + اختبار | code+test | §2.1 G8 |
| 1.4 regression: `php tests/runner.php` = 109+PASS | تقرير | — |

### Sprint 2 — إكمال الترويسة + الاستخلاص الاختياري (2 يوم)

| المهمة | المخرج | الاكتشاف |
|---|---|---|
| 2.1 إضافة الشعار (logo) + كتلة التوقيعات (مدير HR + المدير المباشر + الموظف + التاريخ) إلى قوالب تصدير PDF/Excel/Word في `ReportExportService` | code | §2.1 G11 |
| 2.2 (اختياري) استخلاص `AveragesEngine` مستقل من `EmployeeReportService::summarize()` — يحافظ على الـ API لكن يفصل المسؤولية | refactor | §2.2 D3 |
| 2.3 اختبارات: ترويسة التوقيعات في `ReportSnapshotServiceTest` + `AveragesEngineTest` (إن نُفذ 2.2) | tests | — |
| 2.4 regression | تقرير | — |

### Sprint 3 — UAT + الاعتماد (1 يوم)

| المهمة | المخرج |
|---|---|
| 3.1 تجهيز بيئة UAT + نطاق بيانات اختبار | env |
| 3.2 تنفيذ سيناريوهات UAT الـ9 في `UAT_Script.md` v1.1.0 | تقرير UAT |
| 3.3 توثيق النتائج + التوقيع | توقيع UAT |
| 3.4 تحديث `User_Manual.md` + `Deployment_Guide.md` إن لزم | docs |

**إجمالي v2.0:** **~6 أيام عمل** (≈ أسبوع ونصف تقويمي).

---

## 7. خطة الاختبار (Testing Plan — v2.0)

### 7.1 حماية الـ 109 القائمة

| الإجراء | التفاصيل |
|---|---|
| **Pre-commit hook** | `php tests/runner.php` قبل كل commit — يُرفض عند الفشل |
| **بوابة الترميز** | `php scripts/check-encoding.php --path=app` exit=0 (لا CJK، لا BOM) |
| **بعد كل Migration** | إعادة `tests/runner.php` + فحص الجداول القائمة لم تتأثر |

### 7.2 اختبارات جديدة لـ Sprint 1–2 (v2.0)

| ملف الاختبار الجديد | دوال `test*` | التغطية |
|---|---|---|
| `tests/cases/Services/EmployeeReportServiceEmpCodeTest.php` | 2 | استثناء سجل بلا `emp_code` (G8) |
| `tests/cases/Migrations/DropLegacyReportingObjectsTest.php` | 1 | التحقق أن العروض/الجداول المحذوفة لم تعد موجودة بعد الترحيل (§3.2) |
| `tests/cases/Services/ReportExportHeadersTest.php` | 2 | التحقق من وجود الشعار + كتلة التوقيعات في PDF/XLSX/DOCX (G11) |
| `tests/cases/Services/AveragesEngineTest.php` (إن نُفذ الاستخلاص) | 3 | استخلاص المنطق + cases متوسط فارغ/سنوات فارغة |
| **المجموع الجديد** | **~8** | |

> **الإجمالي بعد CD-020 v2.0:** 109 (قائمة) + ~8 (جديدة) = **~117 دالة اختبار**.

### 7.3 اختبار الـ Immutability — مُنفَّذ فعلاً ✅

`ReportSnapshotServiceTest::testSnapshotHasSerialNumberAndRejectsUpdatesAndDeletes` (CD-018) يغطّي:
- محاولة `UPDATE report_snapshots SET snapshot_json='{}'` → `PDOException` (SQLSTATE 45000)
- محاولة `DELETE FROM report_snapshots` → `PDOException` (SQLSTATE 45000)
- تغيير اسم الموظف → الـ snapshot تحتفظ بالاسم القديم
- النسخة الثانية = الأولى + 1 (serial uniqueness)

**لا حاجة لاختبار إضافي** — هذا يحقق متطلب v1.0 §7.3 بالكامل.

### 7.4 اختبار تدفق E2E (UAT)

سيناريوهات `UAT_Script.md` v1.1.0 الـ9 (Sprint 3). الأهم:
- **السيناريو 7:** إنشاء تقرير + تصدير PDF/Excel/Word → التحقق من الـ magic bytes
- **السيناريو 8:** ثبات التقرير — محاولة تعديل/حذف تُرفض + تغيّر بيانات الموظف لا يؤثر على الـ snapshot

---

## 8. القيود والافتراضات (Constraints — v2.0)

### 8.1 القواعد الحمراء (من CD-020) — الالتزام مؤكد

| # | القاعدة | الالتزام في v2.0 |
|---|---|---|
| 1 | ممنوع لمس `Auth.php` أو RBAC | ✅ CD-016/017 أضافا الصلاحيات (`grading_scales.manage`, `employees.profile`) عبر **migration بيانات** لا كود. أستخدم `Auth::enforce()` الموجود. |
| 2 | ممنوع لمس باني القوالب (B1) | ✅ CD-016 أضاف `evaluation_mode`/`evaluation_frequency` على **schema** فقط؛ `BuilderController::save()` يكتب القيمتين دون تعديل منطق الباني. |
| 3 | ممنوع كسر الاختبارات | ✅ Pre-commit hook + regression. القاعدة = 109 (تطابق التوجيه). |
| 4 | جودة الترميز | ✅ `check-encoding.php --path=app` exit=0. |

### 8.2 خارج النطاق (مؤجَّل)

- التظلمات (Grievances) — تتطلب CD منفصل
- المعايرة بين المقيّمين (Calibration)
- جدولة تقييم الوحدات الدورية التلقائية
- الإشعارات عبر SMTP/البريد
- 2FA/OTP (OOS-7)
- **OOS-21:** ترقية PhpSpreadsheet لإصدار مصحّح (v0.2.0)
- استخلاص `AveragesEngine` (اختياري، Sprint 2)

---

## 9. الاعتماد (Approval — v2.0)

### 9.1 بيانات الاعتماد

> تُعتمد هذه الوثيقة (v2.0) رسمياً بتوقيع الطرفين. لا يُشرع في Sprint 0 فما بعد حتى يُوقَّع هنا. **v1.0 محلولة ولا تُعتمد.**

| الطرف | الاسم | التوقيع | التاريخ |
|---|---|---|---|
| **كبير المستشارين** | ____________________ | ____________________ | ____/____/2026 |
| **إدارة المشروع** | ____________________ | ____________________ | ____/____/2026 |
| **المطور (مُعِدّ الوثيقة)** | المطور الجديد | — | 2026-11-03 |

### 9.2 قائمة فحص ما قبل التنفيذ (v2.0)

- [ ] اعتماد v2.0 من كبير المستشارين + إدارة المشروع.
- [ ] نسخة احتياطية كاملة من قاعدة البيانات الحالية (`employee_evaluation_mvc`).
- [ ] فرع Git جديد: `feature/CD-020-v2-cleanup-and-uat`.
- [ ] `git fetch --all` + التأكد من HEAD = `54ee0e5`/`ad7ffd1`.
- [ ] `composer install` نظيف + `phpoffice/phpword ^1.4` مثبت.
- [ ] `php tests/runner.php` = **109/109 PASS**.
- [ ] تطبيق ترحيلات CD-016/017/018 على DB الإعداد (إن لم تُطبَّق).
- [ ] بيئة UAT منفصلة + نطاق بيانات اختبار.

---

## 10. الملاحق (Appendices — v2.0)

### ملحق أ: الملفات الجديدة الموجودة فعلاً (CD-016..018)

```
app/
├── Controllers/
│   ├── EmployeeReportController.php        (CD-018, 101 سطر) ✅ موجود
│   └── GradingScaleController.php          (CD-016, 146 سطر) ✅ موجود
├── Models/
│   └── GradingScale.php                    (CD-016, 124 سطر) ✅ موجود
├── Services/
│   ├── EmployeeReportService.php           (CD-017, 190 سطر) ✅ موجود
│   ├── ReportSnapshotService.php           (CD-018, 163 سطر) ✅ موجود
│   └── ReportExportService.php             (CD-018, 219 سطر) ✅ موجود
└── Views/
    ├── employees/profile.php               (CD-017, 190 سطر) ✅ معمَّر
    ├── employees/report.php                (CD-018, 86 سطر)  ✅ موجود
    └── grading-scales/index.php            (CD-016)          ✅ موجود

database/migrations/
├── 2026_11_03_CD016_evaluation_foundation.sql      ✅ موجود
├── 2026_11_03_CD017_employee_profile_permission.sql ✅ موجود
└── 2026_11_03_CD018_report_snapshots.php           ✅ موجود

tests/cases/
├── Models/GradingScaleTest.php              ✅ موجود
├── Models/TemplateEvaluationMetadataTest.php ✅ موجود
├── Services/EmployeeReportServiceTest.php   ✅ موجود
└── Services/ReportSnapshotServiceTest.php   ✅ موجود
```

### ملحق ب: الملفات المحذوفة في CD-015 (81 ملفاً)

| الصنف | العدد | أمثلة |
|---|---|---|
| Controllers | 11 | `AdminReportController`, `AnalysisController`, `ArchiveCoursesController`, `ArchiveWorkshopsController`, `PerformanceFilesController`, `ReportsAnalyticsController`, `ReportsController`, `StatisticalReportController`, `TrainingReportController`, `UnifiedReportController`, `WorkshopReportController` |
| Models | 6 | `AnalysisModel` (1232 سطر), `ArchiveModel`, `ReportModel`, `ReportTemplateModel`, `TrainingReport`, `WorkshopReport` |
| Services | 1 | `ReportEngine.php` |
| Tests | 1 | `ReportEngineTest.php` (10 اختبارات) |
| Views | 60 | كلُّ `app/Views/{admin-reports,analysis,archive,performance,statistics,reports}/` |
| Assets | 4 | `archive.css`, `print-report.css`, `report-builder.js`, `report-enhancer.js` |

### ملحق ج: المسارات الحالية للتقارير/الملف (كل ما تبقى)

```
GET    employees/profile/:id                                    → EmployeeController@profile
POST   employees/profile/:id/reports                            → EmployeeReportController@generate
GET    employees/profile/:id/reports/:reportId                  → EmployeeReportController@show
GET    employees/profile/:id/reports/:reportId/export/:format   → EmployeeReportController@export
GET    grading-scales                                           → GradingScaleController@index
POST   grading-scales                                           → GradingScaleController@store
POST   grading-scales/delete                                    → GradingScaleController@destroy
```

### ملحق د: مرجع التحقق من الاكتشافات (v2.0)

كل ادعاء في هذه الوثيقة قابل للتحقق:

```bash
# حالة المستودع:
cd ~/github-repos/employee-evaluation && git log --oneline -5
# → 54ee0e5 (CD-015), a16340c (CD-018), a017f7c (CD-017), 32f8f96 (CD-016), 4bb59f2 (CD-014)

cd ~/github-repos/employee-evaluation-docs && git log --oneline -7
# → ad7ffd1 (CD-019), 46262d6 (OOS-21), 7ddbece (CD-015), 50db400 (CD-018), 1ab2c7a (CD-017), 34a1be2 (CD-016), 6b14510 (CD-014)

# عدد الاختبارات (109):
grep -rE "^\s*public function test" ~/github-repos/employee-evaluation/tests/cases/ | wc -l

# عدد الـ Triggers (6):
grep -rE "CREATE TRIGGER" ~/github-repos/employee-evaluation/database/migrations/

# PHPWord مثبت:
grep "phpoffice/phpword" ~/github-repos/employee-evaluation/composer.json

# مسار profile موجود:
grep "employees/profile" ~/github-repos/employee-evaluation/routes/web.php

# جدول report_snapshots + Triggers:
grep -A2 "report_snapshots_block" ~/github-repos/employee-evaluation/database/migrations/2026_11_03_CD018_report_snapshots.php

# مجلد reports/ محذوف:
ls ~/github-repos/employee-evaluation/app/Views/reports/ 2>&1  # → No such file or directory
```

### ملحق هـ: سجل تغييرات الوثيقة

| الإصدار | التاريخ | التغيير |
|---|---|---|
| **v1.0** | 2026-10-22 | المسودة الأولى. مبنية على `4bb59f2`/`6b14510` (CD-014). حدّدت 16 فجوة. **حالّة — لا تُعتمد.** |
| **v2.0** | 2026-11-03 | إعادة تأسيس كاملة بعد حل تعارض الحالة. مبنية على `54ee0e5`/`ad7ffd1` (CD-015..019). 13 فجوة مُنجَزة + 2 جزئية + 3 اكتشافات جديدة. الخطة تقلّصت من 15 إلى 6 أيام. |

---

**نهاية الوثيقة v2.0 — بانتظار الاعتماد.**

</div>
