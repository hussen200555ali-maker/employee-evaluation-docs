<div dir="rtl">

# توجيه تصحيحي إلى المساعد المطور — CD-020 / Sprint 0 (الموجّه 2)

| البند | القيمة |
|---|---|
| **من** | كبير المطورين |
| **إلى** | المساعد المطور |
| **الموضوع** | تصحيح طريقة تنفيذ المهمة A + قرار حفظ ميزة OOS-5 على فرع WIP |
| **التاريخ** | 2026-11-03 |
| **المرجع** | تقريرك «حالة معوقي الاعتماد A وB» بتاريخ 2026-11-03 19:04 |
| **القاعدة** | `employee-evaluation` @ `54ee0e5` |

---

## 1. تقييم تقريرك

**انضباط ممتاز مرة أخرى.** أقدّر تحديداً:
- **أخذك نسخة احتياطية قبل محاولة التنظيف** (`sprint0_precleanup_...sql`, 173,814 بايت) — ممارسة صحيحة.
- **توقّفك الفوري عند خطأ PHP** دون إعادة المحاولة — التزام كامل بالقاعدة #5.
- **تأكيدك أن قاعدة البيانات لم تتغير** نتيجة المحاولة الفاشلة — توثيق دقيق.
- **جردك الكامل للتغييرات المحلية** مع وصف موجز لكل ملف وتقييم صادق (OOS-5، لا يكفي تحديد الصاحب).

**لم ترتكب خطأً تقنياً** — فقط استخدمت الوسيلة الخاطئة لتشغيل SQL (PHP بدل mysql CLI). والسبب أنني لم أُوضّح طريقة التشغيل بدقة كافية في التوجيه الأول. هذا خطأ تواصلي مني، وأصححه هنا.

---

## 2. تصحيح المهمة A — طريقة تشغيل SQL الصحيحة

### 2.1 التشخيص

الخطأ الذي واجهته:
```
Parse error: Unclosed '(' in Command line code on line 4
```

هذا **خطأ PHP** وليس خطأ SQL. يعني أنك شغّلت SQL عبر PHP (ربما `php -r "..."` أو حاولت استخدام مُشغّل ترحيلات PHP). **الإجراء الذي أعطيته SQL خالص** — يجب تشغيله عبر **`mysql` CLI client** مباشرةً، لا PHP.

### 2.2 الطريقة الصحيحة (انسخ SQL إلى ملف ثم شغّله عبر mysql)

**الخطوة 1:** احفظ المحتوى التالي في ملف باسم `cleanup_test_snapshot.sql` في `C:\xampp\htdocs\employee-evaluation\`:

```sql
-- CD-020 / Sprint 0 — Sanctioned cleanup of test snapshot
-- Run via: mysql -u root employee_evaluation_mvc < cleanup_test_snapshot.sql
-- CAUTION: Temporarily removes DELETE immutability protection, then restores it.

-- 1) تأكيد وجود الصف الاختباري (قبل الحذف):
SELECT id, report_number, created_at FROM report_snapshots
WHERE report_number = 'ER-TEST-00000001';

-- 2) حفظ تعريف محفّز منع الحذف (للمرجعية):
SHOW CREATE TRIGGER report_snapshots_block_delete;

-- 3) حذف محفّز منع الحذف فقط (مؤقتاً):
DROP TRIGGER IF EXISTS report_snapshots_block_delete;

-- 4) حذف صف الاختبار:
DELETE FROM report_snapshots WHERE report_number = 'ER-TEST-00000001';

-- 5) إعادة إنشاء المحفّز بالضبط كما كان:
CREATE TRIGGER report_snapshots_block_delete
    BEFORE DELETE ON report_snapshots FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report snapshots are immutable';

-- 6) التحقق أن المحفزات عادت إلى 6:
SELECT COUNT(*) AS trigger_count_after
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'employee_evaluation_mvc';

-- 7) التحقق أن صف الاختبار اختفى:
SELECT COUNT(*) AS test_rows_after
FROM report_snapshots
WHERE report_number = 'ER-TEST-00000001';

-- 8) توثيق العملية في سجل التدقيق:
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES (
    (SELECT id FROM users WHERE username = 'sysadmin' LIMIT 1),
    'TEST_SNAPSHOT_CLEANUP',
    'report_snapshots',
    NULL,
    'Removed ER-TEST-00000001 test row created during Sprint 0 immutability verification. DELETE trigger dropped/recreated under DBA sanction (CD-020). Trigger count reverified = 6.',
    'localhost'
);
```

**الخطوة 2:** شغّل الملف عبر mysql CLI (ليس PHP):

```bash
cd C:\xampp\htdocs\employee-evaluation
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc < cleanup_test_snapshot.sql
```

**ملاحظة:** إن واجهت خطأ في الخطوة 5 (CREATE TRIGGER) بسبب الفاصلة المنقوطة داخل جسم المحفّز، استخدم الطريقة البديلة أدناه.

### 2.3 طريقة بديلة (خطوة بخطوة عبر `-e`)

إن فشلت الطريقة أعلاه، نفّذ كل عبارة SQL منفصلة عبر `-e`:

```bash
# 1) تأكيد وجود الصف (المتوقع: id=15, ER-TEST-00000001):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "SELECT id, report_number, created_at FROM report_snapshots WHERE report_number='ER-TEST-00000001';"

# 2) حفظ تعريف المحفّز:
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "SHOW CREATE TRIGGER report_snapshots_block_delete;"

# 3) حذف محفّز منع الحذف:
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "DROP TRIGGER IF EXISTS report_snapshots_block_delete;"

# 4) حذف صف الاختبار (المتوقع: 1 row affected):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "DELETE FROM report_snapshots WHERE report_number='ER-TEST-00000001';"

# 5) إعادة إنشاء المحفّز:
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "CREATE TRIGGER report_snapshots_block_delete BEFORE DELETE ON report_snapshots FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report snapshots are immutable';"

# 6) التحقق trigger_count (المتوقع: 6):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='employee_evaluation_mvc';"

# 7) التحقق test_rows (المتوقع: 0):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "SELECT COUNT(*) FROM report_snapshots WHERE report_number='ER-TEST-00000001';"

# 8) إدراج سجل التدقيق:
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address) VALUES ((SELECT id FROM users WHERE username='sysadmin' LIMIT 1), 'TEST_SNAPSHOT_CLEANUP', 'report_snapshots', NULL, 'Removed ER-TEST-00000001 test row (CD-020 Sprint 0). DELETE trigger dropped/recreated under DBA sanction.', 'localhost');"
```

### 2.4 ما ترسله لي بعد إعادة التنفيذ

- ناتج الخطوة 1 (الصف موجود: id=15, ER-TEST-00000001)
- ناتج الخطوة 6 (trigger_count = **6**)
- ناتج الخطوة 7 (test_rows = **0**)
- ناتج `SELECT LAST_INSERT_ID();` بعد الخطوة 8 (تأكيد إدراج audit_logs)

---

## 3. قرار المهمة B — حفظ ميزة OOS-5 على فرع WIP

### 3.1 التقييم

جردك كشف أن التغييرات السبعة (+399/-39 سطر) + `public/js/bulk-actions.js` هي **تنفيذ ميزة العمليات الجماعية (OOS-5)** — وهي ميزة **مُؤجَّلة في SRS v2.0** (خارج نطاق CD-020). التغييرات:
- تلمس ملفات حرجة: `UserController`, `EmployeeController`, `User`, `Employee`, `routes/web.php`, واجهتين.
- غير مُختَبَرة (لا توجد اختبارات جديدة لها).
- غير ملتزَم بها (عمل سابق معلّق).
- **ليست في نطاق Sprint 1** الذي سيُعدّل `CHANGELOG.md` + ترحيل جديد + `EmployeeReportService.php`.

**القرار:** **حفظ العمل على فرع WIP مخصّص** (`wip/oos-5-bulk-operations`)، ثم **إعادة master إلى حالة نظيفة**. هذا:
- ✅ لا يفقد العمل (محفوظ على فرع).
- ✅ يُعطي Sprint 1 خط أساس نظيف.
- ✅ يسمح بتقييم OOS-5 واعتماده لاحقاً في sprint مخصّص.
- ✅ لا يُعدّل master أو التطبيق.

### 3.2 الملفات المطلوب حفظها (8 ملفات)

| # | الملف | نوعه |
|---|---|---|
| 1 | `app/Controllers/Admin/UserController.php` | tracked معدّل |
| 2 | `app/Controllers/EmployeeController.php` | tracked معدّل |
| 3 | `app/Models/Employee.php` | tracked معدّل |
| 4 | `app/Models/User.php` | tracked معدّل |
| 5 | `app/Views/admin/users/index.php` | tracked معدّل |
| 6 | `app/Views/employees/index.php` | tracked معدّل |
| 7 | `routes/web.php` | tracked معدّل |
| 8 | `public/js/bulk-actions.js` | untracked (جزء من الميزة) |

### 3.3 الملفات التي تُترَك كما هي (لا تُحفظ ولا تُلمَس)

| الملف | السبب |
|---|---|
| `database/employee_evaluation_mvc.sql` | ملف SQL dump غير متعقب — يحتاج مراجعة لاحقة لتحديد غرضه. لا يُلمس الآن. |
| `sprint0_preflight_2026-11-03_18-29-51.sql` | نسخة تحقق (غير متعقبة) — تُترك. |
| `sprint0_postrun_2026-11-03_18-31-16.sql` | نسخة تحقق (غير متعقبة) — تُترك. |
| `sprint0_precleanup_2026-11-03_19-03-01.sql` | نسخة ما قبل التنظيف (غير متعقبة) — تُترك. |

### 3.4 الأوامر الدقيقة (تنفّذها بالترتيب حرفياً)

```bash
cd C:\xampp\htdocs\employee-evaluation

# 1) تأكيد أنك على master وعند 54ee0e5:
git branch --show-current
git rev-parse --short HEAD
# المتوقع: master / 54ee0e5

# 2) إنشاء فرع WIP جديد:
git checkout -b wip/oos-5-bulk-operations

# 3) إضافة الملفات الثمانية صراحةً (لا تستخدم git add . — أضف كل ملف بالاسم):
git add app/Controllers/Admin/UserController.php
git add app/Controllers/EmployeeController.php
git add app/Models/Employee.php
git add app/Models/User.php
git add app/Views/admin/users/index.php
git add app/Views/employees/index.php
git add routes/web.php
git add public/js/bulk-actions.js

# 4) التحقق مما سيُلتزَم (يجب أن تكون 8 ملفات فقط):
git diff --cached --stat

# 5) الالتزام:
git commit -m "wip(OOS-5): preserve bulk operations for users/employees

Pre-existing uncommitted work found in working tree during CD-020 Sprint 0
inventory. Preserved on WIP branch for future evaluation in a dedicated
OOS-5 sprint. NOT merged to master. NOT tested. NOT approved.

Files (8): UserController, EmployeeController, User, Employee models;
admin/users + employees index views; routes/web.php; bulk-actions.js
Diff: +399/-39 lines"

# 6) العودة إلى master:
git checkout master

# 7) التحقق أن master نظيف (باستثناء الملفات غير المتعقبة المتبقية):
git status

# المتوقع:master نظيف من التغييرات tracked، تبقى فقط الملفات untracked:
#   database/employee_evaluation_mvc.sql
#   sprint0_preflight_...sql
#   sprint0_postrun_...sql
#   sprint0_precleanup_...sql
#   cleanup_test_snapshot.sql (إن حفظته في الخطوة 2.2)

# 8) التحقق أن فرع WIP يحوي العمل:
git log wip/oos-5-bulk-operations --oneline -3
git diff master..wip/oos-5-bulk-operations --stat
# المتوقع: فرع WIP متقدّم بـ 1 commit، يحوي 8 ملفات

# 9) إعادة التحقق من الاختبارات على master النظيف:
C:\xampp\php\php.exe tests\runner.php
# المتوقع: 109 passed, 0 failed (كما كان)
```

### 3.5 ما ترسله لي بعد تنفيذ المهمة B

- ناتج الخطوة 4 (`git diff --cached --stat` — 8 ملفات)
- ناتج الخطوة 7 (`git status` على master — نظيف)
- ناتج الخطوة 8 (`git log` + `git diff --stat` للفرع WIP)
- ناتج الخطوة 9 (`tests/runner.php` — 109/109 على master النظيف)

---

## 4. القواعد الحمراء لهاتين المهمتين (محدّثة)

| # | القاعدة |
|---|---|
| 1 | **لا ترفع أي شيء إلى GitHub** (لا master ولا WIP) دون توجيهي الصريح. |
| 2 | في المهمة A، **شغّل SQL عبر `mysql` CLI فقط** — لا تستخدم PHP. |
| 3 | في المهمة B، **أضف الملفات الثمانية بالاسم صراحةً** — لا تستخدم `git add .` أو `git add -A`. |
| 4 | **لا تلتزم على master** — الالتزام فقط على فرع `wip/oos-5-bulk-operations`. |
| 5 | **لا تلمس** ملفات `database/employee_evaluation_mvc.sql` و`sprint0_*.sql` و`cleanup_test_snapshot.sql` (تُترك غير متعقبة). |
| 6 | **وثّق كل خطوة** بالمخرجات الفعلية. |
| 7 | **توقّف فوراً** عند أي خطأ غير متوقع وأبلغني. |

---

## 5. ما سأفعله بعد استلام تقريرك (A + B مكتملة)

1. التحقق من نتائج المهمة A (trigger_count=6, test_rows=0, audit_logs مُدرَج).
2. التحقق من نتائج المهمة B (master نظيف، WIP branch يحوي 8 ملفات، 109/109 PASS على master).
3. **كتابة تقرير اعتماد Sprint 0 النهائي** (`CD-020_Sprint0_Signoff_FINAL.md`) لكبير المستشارين:
   - الجزء الثابت (15 خطوة — أنجزتُه)
   - الجزء التشغيلي (13 معيار — أنجزتَه)
   - إغلاق المعوق A (تنظيف لقطة الاختبار)
   - إغلاق المعوق B (حفظ OOS-5 على WIP + master نظيف)
   - التوقيع النهائي
4. **رفع كل وثائق CD-020 إلى GitHub** (بعد الحصول على PAT).
5. **بعد اعتماد كبير المستشارين** → الانتقال إلى Sprint 1.

---

## 6. الخلاصة

المعوقان هما **إجراءات إغلاق تنظيمية** لا أعطالاً تقنية. التوجيه أعلاه يُعطي:
- **طريقة تشغيل صحيحة** للمهمة A (mysql CLI لا PHP).
- **قرار حفظ** للمهمة B (WIP branch + master نظيف).

أنجز المهمتين وأرسل لي التقرير. نحن على بُعد **خطوة واحدة** من الاعتماد النهائي وبدء Sprint 1.

— **كبير المطورين**

</div>
