# CD-008 — خطة تنفيذ محرك التقارير الديناميكية (Dynamic Reporting Engine)

**المرجع:** التوجيه الاستشاري CD-008 (2026-10-19)
**الحالة:** CP-A مُنجز ومعتمد · CP-B مُنجز (4 تقارير + Builder + تصدير + اختبارات + أداء)

## 1) السياق
التحول من نظام إدخال بيانات إلى منصة ذكاء أعمال (BI) عبر 4 طبقات.

## 2) المعمارية (4 طبقات)
1. **طبقة البيانات (Data Mart & Views)** — SQL Views تفصل OLTP عن القراءة.
2. **محرك الاستعلام (Query Engine & API)** — `ReportEngine` يبني استعلامات ديناميكية.
3. **واجهة صانع التقارير (Report Builder UI)** — فلاتر + أبعاد + Grid.
4. **التقارير الأربعة الجاهزة** — Gap, Scorecard, 9-Box, Executive.

## 3) القيود (Guardrails)
- لا تلمس B1 (باني القوالب): نقرأ فقط.
- لا تلمس OOS-2..6: مجمّدة.
- الأداء: < 2 ثانية لكل استعلام.
- الاختبارات: `tests/runner.php` = 93/93 (لا يُكسر).
- التصدير: `PhpSpreadsheet` + `mPDF` فقط (بدون مكتبات جديدة).
- SQL Injection: whitelist + prepared statements.

## 4) معايير القبول (Checklist)
- [x] SQL Views تعمل وتعيد بيانات حقيقية.
- [x] ReportEngine يبني الاستعلامات ديناميكياً.
- [x] Report Builder UI يفلتر ديناميكياً (AJAX).
- [x] Gap Analysis (Bar Chart، <60% أحمر).
- [x] Employee Scorecard (أسهم خضراء/حمراء).
- [x] 9-Box Grid (محور Y: متوسط الكفاءة العام).
- [x] Executive Dashboard (4 KPIs + أفضل 3 فروع + أسوأ 3 أقسام).
- [x] تصدير Excel/PDF يعمل.
- [x] زمن التحميل < 2s (مُقاس — أقصى 10.8ms).
- [x] اختبارات الدقة PHP vs SQL.
- [x] `tests/runner.php` = 103/103.
- [x] `check-encoding` (delivery+app) = `exit=0`.
- [x] Commits منفصلة + توثيق.
