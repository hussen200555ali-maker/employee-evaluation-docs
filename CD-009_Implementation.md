# CD-009 — سجل تنفيذ إصلاحات A3 الحرجة (الهيكل التنظيمي)

**المرجع:** التوجيه الاستشاري CD-009 (2026-10-20)
**الحالة:** الإصلاحات الثلاثة مُنجزة · تسليم مكتمل
**آخر تحديث:** 2026-10-20

---

## 1) الملخص التنفيذي

عولجت ثلاث فئات من الخلل في وحدة الموظفين (حزمة A3 — الهيكل التنظيمي):

1. **تنظيف `EmployeeController` + تأمين الحراس + إصلاح صفحة الخطأ الخاطئة.**
2. **فرض سلامة التسلسل الإداري (`manager_id`):** منع اختيار الموظف لنفسه كمدير ومنع الحلقات المفرغة.
3. **منع حذف مدير لديه مرؤوسون:** كان القيد `ON DELETE SET NULL` ييتّم المرؤوسين بصمت.

أُضيفت ابنتان جديدتان إلى `Auth` (`canBool` و`enforce`) دون المساس بسلوك `Auth::can()` الحالية لحماية 171 موضعًا قائمًا (سُجّل كـ `OOS-19`). حُذف ~490 سطرًا من الشيفرة الميتة. الاختبارات ارتفعت **103 → 112** (9 اختبارات جديدة، كلها ناجحة).

---

## 2) الإصلاح 1 — Refactor حارس `Auth` + تنظيف `EmployeeController`

### 2.1 `app/Core/Auth.php`
- **لم تُمَس** `Auth::can()` الحالية (تطبع 403 وتُنهي التنفيذ) — حماية للـ146 موضعًا المستقلة و25 الموضعًا المحروسة التي تعتمد عليها.
- أُضيفت `Auth::canBool($perm)`: فحص منطقي خالص (bool) بلا طباعة ولا `exit`.
- أُضيفت `Auth::enforce($perm)`: حارس صريح يطبع 403 ويُنهي التنفيذ عند غياب الصلاحية.

### 2.2 `app/Controllers/EmployeeController.php`
- حُذف **~490 سطرًا** من الكتل المُعلَّقة المتكررة (نسخ ميتة من `show/create/store/edit/update/destroy/showEmployeeEvaluations*`).
- حُوِّلت كل حراسات المتحكم إلى `Auth::enforce(...)`:
  `index` (employees.view) · `show` (employees.view) · `create/store` (employees.create) ·
  `edit/update` (employees.edit) · `destroy` (employees.delete) ·
  `showEmployeeEvaluations` و`showEmployeeEvaluationsByYear` (reports.view.all).
- **إصلاح خطأ صفحة الخطأ:** كان `edit($id)` عند عدم وجود الموظف يضبط `http_response_code(404)` ثم يُرجع `forbidden()` (صفحة 403). صُحِّح إلى `notFound()`.
- `show($id)`: أُبقيت تحويلة غير المسجَّل أولًا (سلوك قائم)، ثم `Auth::enforce('employees.view')`.

---

## 3) الإصلاح 2 — سلامة `manager_id` (لا نفس / لا حلقات)

### 3.1 `app/Models/Employee.php`
- `getManagerId($employeeId): ?int` — يجلب المدير المباشر.
- `wouldCreateManagerCycle($employeeId, $managerId): bool` — يتصاعد من المدير المقترح عبر `manager_id` مع مجموعة زيارات + سقف عمق (100 خطوة) لتفادي السلاسل التالفة؛ يعيد `true` عند بلوغ الموظف نفسه أو تكرار عقدة أو تجاوز السقف. `null/0` لا يُنشئ حلقة أبدًا.

### 3.2 `app/Controllers/EmployeeController.php` (`update()`)
- يرفض `manager_id === $id` (اختيار الموظف لنفسه كمدير) → Flash + إعادة توجيه.
- يرفض أي `manager_id` يُنشئ حلقة عبر `wouldCreateManagerCycle` → Flash + إعادة توجيه.

> ملاحظة: `store()` لا يحتاج الفحص لأن الموظف الجديد لا معرّف له بعد ولا يمكن أن يكون طرفًا في حلقة.

### 3.3 الاختبارات — `tests/cases/Models/EmployeeManagerTest.php`
حالات Fix 2 (6): الاختيار الذاتي · الحلقة المباشرة A→B→A · الحلقة الأطول A→B→C→A ·
السلسلة الصحيحة · `null/0` ليس حلقة · بقاء البيانات سليمة عند رفض الحلقة.

---

## 4) الإصلاح 3 — منع حذف مدير لديه مرؤوسون

### 4.1 التحليل
القيد `employees_ibfk_3 (manager_id) REFERENCES employees(id) ON DELETE SET NULL` يعني أن حذف
مدير كان ينجح ويجعل `manager_id` لمرؤوسيه `NULL` **بصمت** — فيُدمّر التسلسل الإداري بلا إنذار
(الفرع `catch 23000` في `destroy` لا يُطلق أصلًا لهذه الحالة).

### 4.2 `app/Models/Employee.php`
- `countDirectReports($employeeId): int` — يحصي `WHERE manager_id = $id`.

### 4.3 `app/Controllers/EmployeeController.php` (`destroy()`)
- قبل الحذف: إذا كان `countDirectReports($id) > 0` يُرفض الحذف برسالة واضحة تعرض عدد المرؤوسين
  («لا يمكن حذف الموظف "…" لوجود X موظفين يتبعون له. يرجى إعادة تعيين مديرهم أولاً.») وإعادة توجيه.
- خلاف ذلك يُنفَّذ الحذف كالمعتاد.

### 4.4 الاختبارات — `tests/cases/Models/EmployeeManagerTest.php`
حالات Fix 3 (3): `countDirectReports` (مرؤوسان مقابل ورقة) · مدير لديه مرؤوسون لا يُحذف ويبقى
صفّه ورابط مرؤوسه سليمًا · ورقة بلا مرؤوسين تُحذف فعلًا.

---

## 5) القياسات (Evidence)

```
tests/runner.php                → 112/112 نجحت · 0 فشل · 0 خطأ  (كانت 103)
  من ضمنها:
  AuthTest                      → 61/61
  EmployeeManagerTest (جديد)    → 9/9
  ReportEngineTest              → 10/10
check-encoding --path=app       → 432 ملفًا / 73630 سطرًا / تسرّب 0 / exit=0
git diff --check                → exit=0 (لا مسافات زائدة)

حالة القاعدة بعد الاختبارات: employees = 37 صفًا · صفوف مؤقتة cd009.mgr.% = 0 (تنظيف كامل)
```

---

## 6) الالتزامات والضوابط (Guardrail CD-009 — الخيار ب)

1. `Auth::can()` **لم تُمَس**؛ أُضيفت `canBool` + `enforce` فقط. (171 موضعًا محميًا).
2. `OOS-19` مُسجَّل: توحيد الـ171 موضعًا في `Auth::enforce()` مؤجَّل إلى CD-010 (ما بعد الإطلاق).
3. لم يُلمس B1 ولا OOS-2..6.
4. الاختبارات **112/112** (≥ 103 المطلوب).
5. بوابة الترميز نظيفة (`--path=app` و`--path=delivery` = exit 0).
6. نسخ رجوع في `_emergency/rollback/CD-009/2026-10-20/`.

---

## 7) الالتزامات (Commits)

**مستودع التطبيق:**
- `e22f8fe` — `fix(CD-009): refactor Auth guard + cleanup EmployeeController dead code`
- `5d9c208` — `fix(CD-009): enforce manager_id validation (no self/hierarchy cycles)`
- `d3ad960` — `fix(CD-009): block manager deletion if subordinates exist`

**مستودع التسليم:**
- `docs(CD-009): implementation log, OOS-19 and changelog` (هذا الملف + `CHANGELOG.md` + `Deferred_to_Post_Launch.md`).

---

## 8) الملفات

**مستودع التطبيق (مُنشأة/مُعدَّلة):**
- `app/Core/Auth.php` (+ `canBool` + `enforce`).
- `app/Controllers/EmployeeController.php` (تنظيف + حراس + إصلاح `edit` + Fix 2 + Fix 3).
- `app/Models/Employee.php` (`getManagerId` · `wouldCreateManagerCycle` · `countDirectReports`).
- `tests/cases/Models/EmployeeManagerTest.php` (جديد — 9 اختبارات).

**مستودع التسليم:**
- `CD-009_Implementation.md` (هذا الملف).
- `Deferred_to_Post_Launch.md` (بند `OOS-19`).
- `CHANGELOG.md` (إدخال CD-009).
