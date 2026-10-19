# CD-008 — سجل تنفيذ محرك التقارير الديناميكية (Dynamic Reporting Engine)

**المرجع:** التوجيه الاستشاري CD-008 (2026-10-19)
**الحالة:** CP-A معتمد رسمياً · CP-B مُنجز
**آخر تحديث:** 2026-10-20

---

## 1) الملخص التنفيذي

أُنجز محرك تقارير ديناميكي كامل يعتمد على طبقة Views للقراءة فقط (Data Mart) + محرك استعلام مُحصَّن
(`ReportEngine`) + واجهات تحليلية (Builder + 4 تقارير). يلتزم المحرك بـ whitelist صارم للأبعاد
والمقاييس والفلاتر مع prepared statements فقط، وتم التحقق من الأداء (< 2s) عبر قياسات فعلية.

---

## 2) CP-A — طبقة البيانات والمحرك (معتمد)

### 2.1 Views (Data Mart)
أُنشئت 3 عروض في قاعدة البيانات `employee_evaluation_mvc` عبر
`database/migrations/2026_10_19_CD008_reporting_views.sql`:

| العرض | الوصف | الصفوف الفعلية |
|---|---|---|
| `vw_evaluation_facts` | حقيقة التقييمات على مستوى الإجابة (تقييم × معيار) | 332 |
| `vw_employee_scores` | درجات الموظفين المجمّعة لكل تقييم | 40 |
| `vw_criteria_averages` | متوسطات المعايير | 100 |

> ملاحظة: العروض تقرأ الحالة `IN ('submitted','completed')`. القيمة الفعلية الموجودة في الإنتاج
> هي `completed` (40 تقييماً) — أما `submitted` فهي غير مستخدمة في الـ enum الحالي
> (`draft|pending_review|approved|completed|archived|expired`) وأُبقيت للتوافق مع بيانات قديمة.

### 2.2 ReportEngine
`app/Services/ReportEngine.php`:
- `$allowedDimensions` (12 بُعداً) → أعمدة عرض `vw_evaluation_facts` (بأسماء مشتقة `v.xxx`).
- `$allowedMeasures`: `avg_score` · `min_score` · `max_score` · `count_evaluations` · `count_employees` · `completion_rate`.
- `$allowedFilters`: `year` · `month` · `start_date` · `end_date` · `branch_id` · `department_id` · `template_id` · `status` · `evaluated_employee_id`.
- أي بُعد/مقياس/فلتر خارج القائمة يُتجاهَل بصمت (لا يصل إلى SQL).
- اتصال قاعدة البيانات عبر `Database::getInstance()` (Singleton).
- يعيد `['success'=>true,'rows'=>...,'meta'=>['sql'=>...,'params'=>...]]`.

---

## 3) CP-B — الواجهات والتقارير والاختبارات

### 3.1 المسارات المُضافة (`routes/web.php`)
```
POST reports/builder/data              → ReportsController@builderData
POST reports/builder/export/excel      → ReportsController@builderExportExcel
POST reports/builder/export/pdf        → ReportsController@builderExportPdf
GET  reports/analytics/gap             → ReportsAnalyticsController@gap
POST reports/analytics/gap/data        → ReportsAnalyticsController@gapData
GET  reports/analytics/scorecard       → ReportsAnalyticsController@scorecard
GET  reports/analytics/ninebox         → ReportsAnalyticsController@ninebox
POST reports/analytics/ninebox/data    → ReportsAnalyticsController@nineboxData
GET  reports/analytics/executive       → ReportsAnalyticsController@executive
POST reports/analytics/executive/data  → ReportsAnalyticsController@executiveData
```
كل مسارات `POST` محمية بـ CSRF (الرمز يُرسَل في ترويسة `X-CSRF-TOKEN`).

### 3.2 صانع التقارير (Report Builder)
`app/Views/reports/builder.php`:
- فلاتر: السنة · الشهر · الفرع · القسم · القالب.
- أبعاد قابلة للتفعيل (أزرار toggle): الفرع · القسم · الموظف · القالب · المعيار · الشهر · السنة.
- مقاييس قابلة للتفعيل: متوسط/أدنى/أعلى درجة · عدد التقييمات · عدد الموظفين · نسبة الإنجاز.
- عرض Grid ديناميكي عبر AJAX + زمن الاستعلام (ms) ظاهر للمستخدم.
- تصدير Excel (PhpSpreadsheet) و PDF (mPDF) عبر POST يعيد Blob.

### 3.3 التقارير الأربعة
| التقرير | الملف | الميزة الأساسية |
|---|---|---|
| Gap Analysis | `reports/analytics/gap.php` | Bar Chart (Chart.js) — أعمدة أقل من 60% بالأحمر + 4 KPIs + جدول الفجوات |
| Employee Scorecard | `reports/analytics/scorecard.php` | جدول الموظفين مع أسهم اتجاه أخضر/أحمر (مقارنة آخر فترتين) |
| 9-Box Grid | `reports/analytics/ninebox.php` | شبكة 3×3 — المحور الرأسي (Y) **«متوسط الكفاءة العام»**، حدود 60%/80% |
| Executive Dashboard | `reports/analytics/executive.php` | 4 KPIs + أفضل 3 فروع + أسوأ 3 أقسام |

### 3.4 الاختبارات
`tests/cases/Reporting/ReportEngineTest.php` (10 اختبارات):
- وجود العروض الثلاثة + احتواء `vw_evaluation_facts` على صفوف.
- سالب: بُعد/مقياس/فلتر خارج whitelist يُتجاهل (لا يظهر في SQL).
- سالب: محاولة حقن SQL تُعامَل كـ parameter وليس كنص حرفي.
- موجب: مقارنة نتائج المحرك مع SQL مباشر لـ (متوسط الفرع) و(فلتر السنة).
- أداء: 4 سيناريوهات كلها < 2s.

### 3.5 الإصلاحات التقنية المكتشفة أثناء CP-B
- `ReportEngine` و`ReportsAnalyticsController` كانا يستخدمان `new Database()` بينما البانية
  **خاصة** (Singleton) → تم التحويل إلى `Database::getInstance()`.
- الأبعاد في whitelist كانت تُشير إلى مراجع جداول (`b.name`, `d.name`) غير موجودة في جملة
  `FROM vw_evaluation_facts v` → تم تصحيحها إلى أعمدة العرض (`v.branch_name`, `v.department_name`, ...).
- إضافة `assertStringNotContainsString()` إلى `tests/lib/TestCase.php`.

---

## 4) القياسات (Evidence)

```
tests/runner.php           → 103/103 نجحت · 0 فشل · 0 خطأ
check-encoding --path=delivery → 37 ملفاً / 7024 سطراً / تسرّب 0 / exit=0
check-encoding --path=app      → 432 ملفاً / 73975 سطراً / تسرّب 0 / exit=0

زمن الاستعلامات (microtime):
  Builder: branch+avg     10.8 ms
  Builder: dept+year       5.5 ms
  Gap: criterion           5.8 ms
  Scorecard: employees    10.6 ms
  9Box: employees          6.7 ms
  Executive: KPIs          0.9 ms
  Executive: top branches  0.9 ms
  Executive: bottom depts  0.7 ms
  → MAX = 10.8 ms  (الحد 2000 ms)
```

---

## 5) القرارات المطبَّقة (Guardrail CP-B)

1. محور Y في 9-Box يحمل اسم **«متوسط الكفاءة العام»** في UI والتوثيق.
2. فهارس `evaluation_answers(evaluation_id)` و`(section_id)` مُتحقق من وجودها (BTREE).
3. PDF = جداول + KPIs فقط (RTL) — لا Chart.js ولا html2canvas ولا مكتبات جديدة.
4. `< 2s` لكل استعلام (مُقاس) · `tests/runner.php` 103/103 · whitelist + prepared statements.
5. لم يُلمس B1 ولا OOS-2..6.

---

## 6) ملفات CP-B

**مُنشأة/مُعدَّلة في مستودع التطبيق:**
- `app/Views/reports/builder.php` (استُبدل الباني القديم بباني CD-008 الديناميكي).
- `app/Views/reports/analytics/gap.php`
- `app/Views/reports/analytics/scorecard.php`
- `app/Views/reports/analytics/ninebox.php`
- `app/Views/reports/analytics/executive.php`
- `tests/cases/Reporting/ReportEngineTest.php`
- `app/Services/ReportEngine.php` (إصلاح Singleton + whitelist)
- `app/Controllers/ReportsAnalyticsController.php` (إصلاح Singleton + إعلان `$db`)
- `tests/lib/TestCase.php` (إضافة assertion)
- `routes/web.php` (مسارات CP-B)

**في مستودع التسليم:**
- `CD-008_Reporting_Engine_Plan.md` (تحديث الحالة والقائمة).
- `CD-008_Implementation.md` (هذا الملف).
- `CHANGELOG.md` (إدخالات CD-008).
