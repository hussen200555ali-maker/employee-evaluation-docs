# CD-010 — سجل تنفيذ محرك التقييمات الأساسي (B2 & B5)

**المرجع:** التوجيه الاستشاري CD-010 (2026-10-20)
**الحالة:** مُنجز — بانتظار المراجعة
**آخر تحديث:** 2026-10-20

---

## 1) الملخص التنفيذي

الهدف من CD-010 هو التأكد من أن مسار العمل الكامل للتقييم يعمل من البداية إلى النهاية،
وأن بيانات التقييم تتدفق من **شاشة الإدخال** → **قاعدة البيانات** → **تقارير CD-008** دون انقطاع.

**النتيجة:** محرك B2/B5 (`Evaluation::create` · `saveEvaluationResults` · `calculateFinalScore` ·
`updateScoreAndStatus`) **موجود ومكتمل مسبقاً**. أجرينا تقييماً تجريبياً شاملاً (E2E) أثبت أن المسار
يعمل بالكامل، ثم وثّقنا الفجوات المكتشفة **قبل** إصلاحها، وأصلحنا **فقط** ما يمنع البيانات من الوصول
إلى تقارير CD-008.

> **مبدأ التنفيذ المطبَّق (Guardrail CD-010):** لا إعادة بناء · لا لمس B1 · لا تعديل بنية الـ Enums
> العامة · فقط إصلاحات موضعية للفجوات الحرجة · الحفاظ على 112/112 اختباراً · بوابة ترميز نظيفة.

---

## 2) نتائج التقييم التجريبي (E2E Demo)

أُجري اختبار شامل يحاكي مسار `EvaluationController` الفعلي عبر الاستدعاء المباشر لدوال الموديل
(`create` → `saveEvaluationResults` → `calculateFinalScore` → `updateScoreAndStatus`) على قالب فعلي
(قالب #1: 4 معايير · 10 أقسام · أوزان 30/25/25/20) وموظف فعلي (id=1)، ثم حُذف بعد التحقق.

**الناتج:**

```
[1] create()                    -> id=73
[2] prepared 10 answers
[3] saveEvaluationResults()     -> true   (10 صفوف في evaluation_answers)
[4] calculateFinalScore()       -> 87.70  (محسوب مرجّحاً)
[5] updateScoreAndStatus(completed) -> true
[6] normalized_score            -> min=80.00 max=100.00 count=10
[7] vw_evaluation_facts         -> rows=10 criteria=4 total_score=87.70 normalized_total=87.70
[cleanup] removed evaluation id=73
```

**الخلاصة:** المسار الكامل (إنشاء → حفظ الإجابات → حساب الدرجة → تغيير الحالة → ظهور في العرض)
**يعمل** بلا أخطاء. البيانات تصل إلى `vw_evaluation_facts` وتظهر التقارير.

---

## 3) سجل الفجوات (موثَّق قبل الإصلاح — إلزامي)

| # | الفجوة | الموقع | السبب | الأثر | الإصلاح المُطبَّق |
|---|--------|--------|-------|-------|-------------------|
| **G1** | فلتر الحالة `IN ('submitted','completed')` في العروض الثلاثة | `vw_evaluation_facts` · `vw_employee_scores` · `vw_criteria_averages` | القيمة `submitted` **ليست عضواً في enum** `evaluations.status` (`draft\|pending_review\|approved\|completed\|archived\|expired`) — شرط ميت | تقييمات الوحدات المعتمدة (`approved`) وتقييمات `pending_review` التي لها إجابات **لا تظهر أبداً** في تقارير CD-008 (البيانات الفعلية: 9 صفوف `pending_review` · `approved` غير محصورة) | تغيير الفلتر إلى `IN ('approved','completed')` — وهو الفلتر **المعتمد في باقي النظام بأكمله** (AnalysisModel · StatisticalReportController · UnifiedReportController · ArchiveModel · Employee …) |
| **G2** | `completion_rate` يستخدم `IN ('completed','submitted')` | `app/Services/ReportEngine.php:79` | نفس القيمة الميتة `submitted` | نسبة الإنجاز في بانِ التقارير تُقصِّر من التقييمات المعتمدة | تغيير المجموعة إلى `IN ('approved','completed')` |
| **G3** | خطأ صياغة في `GROUP BY` (اسم مستعار في GROUP BY) | `database/migrations/2026_10_19_CD008_reporting_views_fixed.sql` (أسطر 106–108: `d.name AS department_name`) | كتابة الاسم المستعار داخل `GROUP BY` بدل العمود الأصلي | العرض `vw_criteria_averages` **يعمل حالياً** لأن النسخة الحيّة صحيحة، لكن إعادة تشغيل ملف الترحيل كان **ستفشل** بصياغة SQL | تصحيح `GROUP BY` إلى أعمدة أصلية (`d.name`, `b.name`) |
| **G4** | تكرار العمود `e.final_score` مرتين بلا اسم مستعار | نفس الملف (عرضا `vw_evaluation_facts` و`vw_employee_scores`) | فقدان الأسماء المستعارة `total_score`/`normalized_total` عند كتابة الملف «المُصلَّح» | `ERROR 1060: Duplicate column name 'final_score'` — الملف لم يكن قد طُبِّق قط على قاعدة البيانات | استعادة الأسماء المستعارة `e.final_score AS total_score` و`e.final_score AS normalized_total` (يطابق ما يتوقعه `ReportsAnalyticsController`: `es.normalized_total`) |

> **ملاحظة تحليلية:** المسار `draft → pending_review → approved` مُنفَّذ فعلياً في
> `UnitEvaluationController::review()` (سطر 128: `updateScoreAndStatus($id, $final, 'approved')`).
> لذلك فإن **الحالة النهائية المعتمدة للعرض في التقارير هي `approved` و`completed` فقط**،
> وليس `submitted` (غير موجود) ولا `pending_review` (قابل للتعديل، غير نهائي).

---

## 4) الإصلاحات المُطبَّقة (موضعية فقط)

### 4.1 G1 — توحيد فلتر حالة العروض
في `database/migrations/2026_10_19_CD008_reporting_views_fixed.sql`، غُيِّر الشرط في العروض
الثلاثة من:
```sql
WHERE e.status IN ('submitted', 'completed')
```
إلى:
```sql
WHERE e.status IN ('approved', 'completed')
```
ثم أُعيد إنشاء العروض في قاعدة البيانات الحيّة بنفس SQL.

### 4.2 G2 — نسبة الإنجاز
في `app/Services/ReportEngine.php`، غُيِّرت مجموعة الحالات في حساب `completion_rate` لتطابق
باقي النظام.

### 4.3 G3 — صياغة `GROUP BY`
صُحِّح `GROUP BY` في ملف الترحيل لاستخدام أعمدة أصلية بدل الأسماء المستعارة.

**لم يُلمس:** بنية الـ Enums · واجهات باني القوالب (B1) · OOS-2..6 · دورة حياة التقييم نفسها.

---

## 5) التحقق النهائي (التكامل مع CD-008)

- تقدير تجريبي متكامل أظهر ظهور التقييم في `vw_evaluation_facts` (10 صفوف · 4 معايير).
- بعد الإصلاح، أصبحت الحالات المعتمدة (`approved`) قابلة للظهور في التقارير، والفلتر موحَّد مع
  باقي استعلامات النظام.
- `vw_employee_scores` و`vw_criteria_averages` أُعيد إنشاؤهما بنفس الفلتر الموحَّد.

---

## 6) القياسات (Evidence)

```
tests/runner.php                     -> 112/112 نجحت · 0 فشل · 0 خطأ · 14.95s
check-encoding --path=app            -> 432 ملفاً / 73630 سطراً / تسرّب 0 / exit=0
check-encoding --path=delivery       -> 40 ملفاً / 7464 سطراً / تسرّب 0 / exit=0
git diff --check                     -> exit=0
E2E demo                             -> create/save/score/status/vw_facts = نجاح كامل (id=73 · درجة 87.70)
تحقق G1                             -> pending_review=0 صف · بعد approved=3 صفوف في vw_evaluation_facts
إعادة إنشاء العروض                   -> vw_evaluation_facts=342 · vw_employee_scores=41 · vw_criteria_averages=100
```

---

## 7) الملفات

**مُنشأة/مُعدَّلة في مستودع التطبيق:**
- `database/migrations/2026_10_19_CD008_reporting_views_fixed.sql` (فلتر الحالة + صياغة GROUP BY).
- `app/Services/ReportEngine.php` (مجموعة حالات `completion_rate`).

**في مستودع التسليم:**
- `CD-010_Implementation.md` (هذا الملف).
- `CHANGELOG.md` (إدخال CD-010).

---

## 8) القرارات المطبَّقة (Guardrail CD-010)

1. التقييم التجريبي E2E أُجري أولاً وأثبت عمل المسار الكامل.
2. الفجوات وُثِّقت في هذا الملف **قبل** أي إصلاح.
3. الإصلاح **موضعي فقط**: فلتر حالة العروض + نسبة الإنجاز + صياغة GROUP BY.
4. لا لمس لـ B1 · لا تعديل بنية الـ Enums · الحفاظ على 112/112.
5. بوابة الترميز نظيفة (app + delivery).
