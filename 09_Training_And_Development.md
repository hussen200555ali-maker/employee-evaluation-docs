# الوثيقة 09 — التدريب والتطوير

| بند | البيان |
|---|---|
| **اسم الوثيقة** | التدريب والتطوير |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. كيانات التدريب وعلاقاتها

| الجدول | الدور |
|---|---|
| `training_courses` | الدورات التدريبية (6 دورات حية) |
| `training_workshops` | ورش العمل (3 ورش حية) |
| `course_catalog` | كتالوجات قوالب الدورة (حسب القسم) |
| `workshop_catalog` | كتالوجات قوالب الورشة (حسب القسم/الفرع) |
| `course_evaluations` | تقييم "الدورة ككيان" |
| `workshop_evaluations` | تقييم "الورشة ككيان" |
| `evaluations` | تقييم "موظف داخل دورة/ورشة" (نطاقات `employee_in_course`, `employee_in_workshop`) |

**سلسلة تشغيل:** كيان تدريبي (دورة/ورشة) ← تقييم كيان + تقييم موظف داخل الكيان ← أداء (performance files) ← أرشيف شجري.

---

## 2. مسارات التقييم (أنواع المدخلات)

| النوع | المتحكم | ملاحظات |
|---|---|---|
| دورة ككيان | `CourseEvaluationController` | create/store/show (`training/evaluations/*`) |
| ورشة ككيان | `WorkshopEvaluationController` | create/store/show (`training/workshops/evaluations/*` + نسخة قديمة `workshop_evaluations/*`) |
| موظف في دورة | `FlexibleEvaluationController` | `flexible/evaluations/create/employee-in-course` |
| موظف في ورشة | `FlexibleEvaluationController` | `flexible/evaluations/create/employee-in-workshop` |
| إنشاء كيان | `FlexibleEvaluationController` | create/store للدورة والورشة (مساران سريعان) |

---

## 3. القوالب والكتالوجات

- قالب **#23 (ورشة)** و**#26 (وحدة)** قوالب استكشافية (وثيقة 04).
- الكتالوجات تربط قالبًا بقسم/فرع يدويًا عبر `course_catalog` / `workshop_catalog` (واجهات CRUD).
- تعليمات Excel تدريبية: `evaluations/excel/training-template` + `api/training-templates` + `api/training-list`.

---

## 4. ملفات الأداء

`PerformanceFilesController` — 4 شاشات:
- `courses/performance-files`, `workshops/performance-files`, `units/performance-files`, `employees/performance-files`.

---

## 5. تقارير التدريب والورش

| المتحكم | المخرج |
|---|---|
| `TrainingReportController` | dashboard، طباعة (`reports/print`)، تقرير قسم (`reports/training-*`)، بيانات AJAX (`api/report`, `api/reports/by-branch`, `by-department`) |
| `WorkshopReportController` | dashboard/فهرس/طباعة + واجهات AJAX فرع/قسم |

---

## 6. الأرشيف الشجري

`ArchiveCoursesController` / `ArchiveWorkshopsController` — تنقّل بثلاث مستويات + عرض سجل:

```
فرع (bid) ← قسم (did) ← سنة (year) ← سجلات (records) ← عرض الكيان (show)
```

- 10 مسارات في `archive/*` (وثيقة 06).

---

## 7. البيانات الحية (لقطة 2026-09-15)

| المؤشر | القيمة |
|---|---|
| الدورات (`training_courses`) | 6 |
| الورش (`training_workshops`) | 3 |
| تقييمات الكيانات التدريبية | متوفرة عبر جدولي `course_evaluations` / `workshop_evaluations` (سجلات تجريبية) |
| التعينات بالكتالوجات | يدوية (لا ارتباط تلقائي بالفرع/القسم في شاشات القوائم حتى الآن) |

---

## 8. دورة الحياة والملاحظات

1. إنشاء كيان (دورة/ورشة) → ترتيب قالب → تقييم الموظفين/الكيان → توليد ملفات أداء → أرشفة دورية.
2. **ملاحظة:** الجدولة الدورية لتقييم الوحدات غير مفعّلة (جداول فارغة) — أقرب فجوة للتدريب بالنسبة لوحدة "تقييم الوحدات".
3. **جودة:** بيانات التدريب الحالية تجريبية (من استيراد phase 4) — تتم المعايرة الفعلية بعد التنظيف (وثيقة 12).

---

**نهاية الوثيقة 09 — التدريب والتطوير**