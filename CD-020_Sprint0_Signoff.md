<div dir="rtl">

# CD-020 — Sprint 0 Sign-off Report (التحقق والاستعداد)

| البند | القيمة |
|---|---|
| **رقم الوثيقة** | CD-020 / Sprint 0 |
| **العنوان** | تقرير اعتماد Sprint 0 — Baseline Verification |
| **المرجع** | اعتماد SRS v2.0 بتاريخ 2026-11-03 + تكليف Sprint 0 (مدة 1 يوم) |
| **المُعِدّ** | المطور الجديد |
| **التاريخ** | 2026-11-03 |
| **الحالة** | ⏳ الجزء الثابت مُكتمل؛ الجزء التشغيلي بانتظار التنفيذ على XAMPP |
| **القاعدة** | `employee-evaluation` @ `54ee0e5` · `employee-evaluation-docs` @ `e043aff` (SRS v2.0) |

---

## ⚠️ إقرار منهجي حرج (Honest Disclosure)

**هذه البيئة (ساندبوكس Next.js) لا تحوي PHP، Composer، MySQL، ولا mysqldump.** لذلك لا يمكنني تشغيل `tests/runner.php` أو `check-encoding.php` (كـ PHP runtime) أو `mysqldump` هنا.

قسّمتُ التحقق إلى:
- **الجزء أ (ثابت — نُفّذ هنا بالكامل ✅):** تحقق المستودع + تحقق المصدر (تحليل الملفات بدون تشغيلها).
- **الجزء ب (تشغيلي — يتطلب XAMPP عندك ⏳):** `composer install` + `tests/runner.php` + `check-encoding.php` runtime + التحقق من DB + `mysqldump`. أُوفّر لك الأوامر الدقيقة جاهزة للنسخ.

**لم أكذب ولم أختلق أي نتيجة تشغيلية.** كل ادعاء أدناه مدعوم بأمر قابل لإعادة التشغيل.

---

## الجزء أ — التحقق الثابت (نُفّذ هنا ✅)

### أ.1 التحقق من المستودع (Repository Verification) ✅

| الخطوة | الأمر | النتيجة |
|---|---|---|
| **1.1 git fetch --all (الكود)** | `cd ~/github-repos/employee-evaluation && git fetch --all --prune --tags` | ✅ تم، لا تحديثات جديدة |
| **1.2 HEAD الكود** | `git rev-parse HEAD` | ✅ `54ee0e5a1bbe0c821d38f66d617fb75fcca0c64d` = `54ee0e5` (CD-015) — **مطابق للتوجيه** |
| **1.3 نظافة مساحة عمل الكود** | `git status --short` | ✅ نظيف (لا تغييرات معلّقة) |
| **1.4 git fetch --all (التوثيق)** | `cd ~/github-repos/employee-evaluation-docs && git fetch --all` | ✅ تم |
| **1.5 HEAD التوثيق** | `git rev-parse HEAD` | ⚠️ `e043aff` — متقدّم بـ 1 commit عن `ad7ffd1` المذكور في التوجيه. **السبب:** هذا هو commit وثيقة SRS v2.0 الذي دفعته بعد اعتمادها (`e043aff docs(CD-020): SRS v2.0`). متوقع وصحيح. |
| **1.6 نظافة مساحة عمل التوثيق** | `git status --short` | ✅ نظيف |
| **1.7 الفروع** | `git branch -a` | ✅ `master` يتتبع `origin/master` (لا فروع شاردة) |

### أ.2 التحقق الثابت من المصدر (Static Source Verification) ✅

| الخطوة | الأمر | النتيجة |
|---|---|---|
| **2.1 PHPWord في composer.json** | `grep "phpoffice/phpword" composer.json` | ✅ `"phpoffice/phpword": "^1.4"` (السطر 18) |
| **2.2 PHPWord في composer.lock** | `grep -A1 '"name": "phpoffice/phpword"' composer.lock` | ✅ version `1.4.0` مُثبَّتة في القفل |
| **2.3 ترحيلات CD-016/017/018 موجودة** | `ls database/migrations/2026_11_03_CD01[678]*` | ✅ الثلاثة موجودة: `2026_11_03_CD016_evaluation_foundation.sql` (2461B) · `2026_11_03_CD017_employee_profile_permission.sql` (697B) · `2026_11_03_CD018_report_snapshots.php` (2749B) |
| **2.4 جدول `grading_scales` في الترحيل** | `grep -c "grading_scales" .../CD016*.sql` | ✅ 7 إشارات — DDL كامل + seed + permission |
| **2.5 جدولا `report_snapshots` + `report_snapshot_counters`** | `grep "CREATE TABLE.*report_snapshot" .../CD018*.php` | ✅ كلاهما موجودان بـ `CREATE TABLE IF NOT EXISTS` |
| **2.6 عدد CREATE TRIGGER عبر كل الترحيلات** | `grep -rE "CREATE TRIGGER" database/migrations/ \| wc -l` | ✅ **6 بالضبط** (متوقع: 4 CD-004 + 2 CD-018) |
| **2.7 تفصيل الـ 6 Triggers** | `grep -rE "CREATE TRIGGER" database/migrations/` | ✅ `cd004_trg_user_roles_ai/ad` · `cd004_trg_role_permissions_ai/ad` · `report_snapshots_block_update` · `report_snapshots_block_delete` |
| **2.8 Immutability: BEFORE UPDATE/DELETE + SIGNAL 45000** | `grep -E "SIGNAL\|45000\|BEFORE" .../CD018*.php` | ✅ `BEFORE UPDATE` + `BEFORE DELETE` + `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report snapshots are immutable'` |
| **2.9 عدد دوال الاختبار** | `grep -rE "^\s*public function test" tests/cases/ \| wc -l` | ✅ **109 بالضبط** — مطابق للتوجيه |
| **2.10 توزيع ملفات الاختبار** | `for f in tests/cases/**/*Test.php` | ✅ 12 ملف، المجموع 109 (AuthTest=62, NotificationTest=13, EmployeeManagerTest=9, RouterTest=7, DatabaseTest=5, UserTest=3, HelpersTest=3, EmployeeReportServiceTest=2, ReportSnapshotServiceTest=2, UserControllerTest=1, GradingScaleTest=1, TemplateEvaluationMetadataTest=1) |
| **2.11 check-encoding.php موجود** | `ls scripts/check-encoding.php` | ✅ موجود في مستودع التوثيق (`employee-evaluation-docs/scripts/check-encoding.php`, 11278B) |
| **2.12 config/database.php (gitignored)** | `ls config/database.php` | ✅ غير موجود — صحيح (مستثنى via .gitignore؛ يُنشأ يدوياً على XAMPP) |
| **2.13 أعمدة CD-016 على evaluations** | `grep -E "evaluation_type\|final_grade" .../CD016*.sql` | ✅ `evaluation_type ENUM('annual','periodic','course','workshop')` + `final_grade_label VARCHAR(50)` + `final_grade_value DECIMAL(5,2)` — كلها `ADD COLUMN IF NOT EXISTS` (idempotent) |
| **2.14 أعمدة CD-016 على form_templates** | `grep -E "evaluation_mode\|evaluation_frequency" .../CD016*.sql` | ✅ `evaluation_mode ENUM('numeric','descriptive','mixed')` + `evaluation_frequency ENUM('yearly','quarterly','monthly','ad-hoc')` |
| **2.15 الصلاحيات الجديدة** | `grep -E "grading_scales.manage\|employees.profile" .../CD01[67]*.sql` | ✅ كلاهما موجودان (CD-016 يضيف `grading_scales.manage`، CD-017 يضيف `employees.profile`) |

**خلاصة الجزء أ:** كل التحقق الثابت نجح بالكامل (15 خطوة). المستودع والترحيلات والمصدر متوافقة تماماً مع ما وثّقته SRS v2.0.

---

## الجزء ب — التحقق التشغيلي (يتطلب XAMPP عندك ⏳)

### ب.0 المتطلبات المسبقة على XAMPP

تأكد أن XAMPP يعمل (Apache + MySQL)، وأن المشروع في `C:\xampp\htdocs\employee-evaluation`، وأن `config/database.php` موجود بمعلومات الاتصال الصحيحة.

### ب.1 التحقق من البيئة (Environment Verification)

**الأمر 1 — composer install:**
```bash
cd C:\xampp\htdocs\employee-evaluation
composer install --no-dev --optimize-autoloader
# المتوقع: "Generating optimized autoload files" + لا أخطاء
# تحقق PHPWord:
composer show phpoffice/phpword
# المتوقع: name : phpoffice/phpword, versions : 1.4.0
```

**الأمر 2 — تشغيل الاختبارات:**
```bash
cd C:\xampp\htdocs\employee-evaluation
C:\xampp\php\php.exe tests\runner.php
# المتوقع: "109 passed, 0 failed, 0 errors, 0 skipped" + exit code 0
```

**الأمر 3 — بوابة الترميز:**
```bash
cd C:\xampp\htdocs\employee-evaluation
C:\xampp\php\php.exe CD-001_delivery\scripts\check-encoding.php --path=app
# المتوقع: exit code 0 (لا CJK، لا BOM، لا U+FFFD)
```

### ب.2 التحقق من قاعدة البيانات (Database Verification)

**الأمر 4 — تطبيق ترحيلات CD-016/017/018 (إن لم تُطبَّق بعد):**
```bash
cd C:\xampp\htdocs\employee-evaluation
# CD-016 (SQL):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc < database\migrations\2026_11_03_CD016_evaluation_foundation.sql
# CD-017 (SQL):
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc < database\migrations\2026_11_03_CD017_employee_profile_permission.sql
# CD-018 (PHP — يحتاج تنفيذ):
C:\xampp\php\php.exe database\migrations\2026_11_03_CD018_report_snapshots.php
# المتوقع لكل: لا أخطاء. الترحيلات idempotent (IF NOT EXISTS / IF EXISTS).
```

**الأمر 5 — التحقق من الجداول الجديدة:**
```bash
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "
SHOW TABLES LIKE 'grading_scales';
SHOW TABLES LIKE 'report_snapshots';
SHOW TABLES LIKE 'report_snapshot_counters';
SELECT COUNT(*) AS grading_scales_rows FROM grading_scales;
"
# المتوقع: 3 جداول موجودة + grading_scales بها 5 صفوف (seed)
```

**الأمر 6 — التحقق من الـ 6 Triggers:**
```bash
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "
SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'employee_evaluation_mvc'
ORDER BY TRIGGER_NAME;
"
# المتوقع: 6 صفوف:
#   cd004_trg_role_permissions_ad / ai  (AFTER DELETE/INSERT)
#   cd004_trg_user_roles_ad / ai        (AFTER DELETE/INSERT)
#   report_snapshots_block_delete       (BEFORE DELETE)
#   report_snapshots_block_update       (BEFORE UPDATE)
```

**الأمر 7 — تحقق إضافي: اختبار Immutability مباشرةً:**
```bash
C:\xampp\mysql\bin\mysql.exe -u root employee_evaluation_mvc -e "
-- أنشئ صف اختبار:
INSERT INTO report_snapshots (report_number, employee_id, created_by_user_id, snapshot_json)
VALUES ('ER-TEST-00000001', 1, 1, '{\"test\":true}');
-- حاول تعديله (يجب أن يفشل):
UPDATE report_snapshots SET snapshot_json='{\"hacked\":true}' WHERE report_number='ER-TEST-00000001';
"
# المتوقع: ERROR 1644 (45000): Report snapshots are immutable
```

### ب.3 النسخة الاحتياطية (Backup)

**الأمر 8 — mysqldump كاملة:**
```bash
cd C:\xampp\htdocs\employee-evaluation
mkdir -p backups
C:\xampp\mysql\bin\mysqldump.exe -u root \
  --routines --triggers --single-transaction \
  --default-character-set=utf8mb4 \
  --result-file=backups\sprint0_backup_$(date +%Y-%m-%d_%H-%M-%S).sql \
  employee_evaluation_mvc

# على Windows PowerShell استخدم:
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
C:\xampp\mysql\bin\mysqldump.exe -u root --routines --triggers --single-transaction --default-character-set=utf8mb4 --result-file="backups\sprint0_backup_$ts.sql" employee_evaluation_mvc
```

**الأمر 9 — التحقق من النسخة الاحتياطية:**
```bash
# الحجم > 50KB:
ls -la backups\sprint0_backup_*.sql    # (Linux/Git Bash)
dir backups\sprint0_backup_*.sql        # (Windows cmd)

# يحتوي CREATE TABLE:
grep -c "CREATE TABLE" backups\sprint0_backup_*.sql   # (Git Bash)
findstr /c:"CREATE TABLE" backups\sprint0_backup_*.sql | find /c "CREATE TABLE"   # (Windows cmd)

# يحتوي Triggers:
grep -c "CREATE TRIGGER" backups\sprint0_backup_*.sql   # (المتوقع: 6 أو أكثر مع تعليقات mysqldump)
```

---

## الجزء ج — سكربت تحقق موحَّد (اختياري — للنسخ)

إن أردت تنفيذ كل الخطوات بضغطة، احفظ هذا كـ `sprint0_verify.bat` في جذر مستودع الكود ونفّذه:

```bat
@echo off
echo ============================================================
echo   CD-020 Sprint 0 - Verification Script
echo ============================================================
set DB=employee_evaluation_mvc
set MYSQL=C:\xampp\mysql\bin\mysql.exe
set MYSQLDUMP=C:\xampp\mysql\bin\mysqldump.exe
set PHP=C:\xampp\php\php.exe

echo.
echo [1/7] composer install...
call composer install --no-dev --optimize-autoloader
if errorlevel 1 (echo FAIL: composer install & exit /b 1)

echo.
echo [2/7] PHPWord check...
call composer show phpoffice/phpword | findstr "1.4"
if errorlevel 1 (echo FAIL: PHPWord missing & exit /b 1)

echo.
echo [3/7] Apply migrations CD-016/017/018...
%MYSQL% -u root %DB% < database\migrations\2026_11_03_CD016_evaluation_foundation.sql
%MYSQL% -u root %DB% < database\migrations\2026_11_03_CD017_employee_profile_permission.sql
%PHP% database\migrations\2026_11_03_CD018_report_snapshots.php
if errorlevel 1 (echo FAIL: migrations & exit /b 1)

echo.
echo [4/7] Verify new tables...
%MYSQL% -u root %DB% -e "SHOW TABLES LIKE 'grading_scales'; SHOW TABLES LIKE 'report_snapshots'; SHOW TABLES LIKE 'report_snapshot_counters'; SELECT COUNT(*) FROM grading_scales;"

echo.
echo [5/7] Verify 6 triggers...
%MYSQL% -u root %DB% -e "SELECT TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='%DB%';"

echo.
echo [6/7] Run tests...
%PHP% tests\runner.php
if errorlevel 1 (echo FAIL: tests & exit /b 1)

echo.
echo [7/7] mysqldump backup...
mkdir backups 2>nul
%MYSQLDUMP% -u root --routines --triggers --single-transaction --default-character-set=utf8mb4 --result-file=backups\sprint0_backup.sql %DB%
dir backups\sprint0_backup.sql

echo.
echo ============================================================
echo   Sprint 0 verification complete. Review output above.
echo ============================================================
```

---

## الجزء د — تقرير الاعتماد (Sign-off)

### د.1 ملخص النتائج

| القسم | الحالة | الأدلة |
|---|---|---|
| **أ. المستودع (git)** | ✅ **مُكتمل** | §أ.1 — HEAD مطابق، نظيف، متزامن |
| **أ. المصدر (static)** | ✅ **مُكتمل** | §أ.2 — 15 خطوة تحقق ثابتة كلها نجحت |
| **ب. البيئة (runtime)** | ⏳ **يتطلب XAMPP** | §ب.1 — أوامر جاهزة (`composer install`, `tests/runner.php`, `check-encoding`) |
| **ب. قاعدة البيانات** | ⏳ **يتطلب MySQL** | §ب.2 — أوامر جاهزة (تطبيق الترحيلات + التحقق من الجداول/Triggers) |
| **ب. النسخ الاحتياطي** | ⏳ **يتطلب mysqldump** | §ب.3 — أمر جاهز |

### د.2 ما أتحقق منه مباشرةً (يمكنني توقيعه الآن)

1. ✅ المستودع على `54ee0e5` (كود) + `e043aff` (توثيق، +1 commit = SRS v2.0).
2. ✅ مساحتا العمل نظيفتان (لا تغييرات معلّقة).
3. ✅ `phpoffice/phpword ^1.4` في composer.json + locked في composer.lock.
4. ✅ ترحيلات CD-016/017/018 موجودة بكامل DDL (الجداول + الأعمدة + الصلاحيات).
5. ✅ **109 دوال اختبار** بالضبط (مطابق للتوجيه CD-020).
6. ✅ **6 CREATE TRIGGER** في المصدر (4 CD-004 + 2 CD-018 Immutability مع `SIGNAL SQLSTATE '45000'`).
7. ✅ الجداول الجديدة `grading_scales` + `report_snapshots` + `report_snapshot_counters` مُعرَّفة في الترحيلات.
8. ✅ الأعمدة الجديدة على `evaluations` و`form_templates` مُعرَّفة (idempotent `IF NOT EXISTS`).
9. ✅ الصلاحيات الجديدة `grading_scales.manage` و`employees.profile` مُعرَّفة في الترحيلات.
10. ✅ `check-encoding.php` موجود + `config/database.php` مستثنى صحيحاً (gitignored).

### د.3 ما لا أتحقق منه هنا (يتطلب تنفيذك على XAMPP)

1. ⏳ `composer install` فعلي (تثبيت PHPWord + autoloader).
2. ⏳ `php tests/runner.php` = 109/109 PASS (runtime).
3. ⏳ `check-encoding.php --path=app` exit=0 (runtime).
4. ⏳ تطبيق الترحيلات على DB + التحقق من الجداول الـ3 + الـ 6 Triggers في `information_schema`.
5. ⏳ `mysqldump` + التحقق من حجم الملف (>50KB) ومحتواه (`CREATE TABLE`).

> **هذه الخطوات الخمس تتطلب بيئة XAMPP. لا يمكنني تشغيلها في هذه الساندبوكس Next.js.** الأوامر الدقيقة في §ب جاهزة للنسخ، والسكربت الموحَّد في §ج.

### د.4 طلب الاعتماد

| الطرف | الاسم | التوقيع | التاريخ |
|---|---|---|---|
| **كبير المستشارين** | ____________________ | ____________________ | ____/____/2026 |
| **إدارة المشروع** | ____________________ | ____________________ | ____/____/2026 |
| **المطور** | المطور الجديد | — | 2026-11-03 |

### د.5 معيار الانتقال إلى Sprint 1

ينتقل Sprint 0 → Sprint 1 عند تحقق **كل** الشروط التالية:
1. ✅ الجزء أ (ثابت) — **مُكتمل الآن**.
2. ⏳ الجزء ب (تشغيلي) — ينفّذه المستخدم على XAMPP ويرسل مخرجات:
   - `tests/runner.php` → "109 passed, 0 failed"
   - `check-encoding.php` → exit 0
   - `SHOW TABLES` للجداول الـ3 + `SELECT COUNT(*) FROM grading_scales` = 5
   - `information_schema.TRIGGERS` = 6 صفوف
   - `mysqldump` ملف > 50KB + يحوي `CREATE TABLE`

بمجرّد إرسالك لمخرجات الأوامر الـ5 في §ب، أتحققها وأُصدر اعتماد Sprint 0 النهائي، ثم ننتقل إلى Sprint 1 (إغلاق الاكتشافات الجديدة).

---

## الجزء هـ — مرجع التحقق السريع (Quick Reproduce)

كل ادعاء في الجزء أ قابل لإعادة التحقق بأمر واحد:

```bash
# المستودع:
cd ~/github-repos/employee-evaluation && git rev-parse HEAD          # → 54ee0e5...
cd ~/github-repos/employee-evaluation-docs && git rev-parse HEAD     # → e043aff...

# PHPWord:
grep "phpoffice/phpword" ~/github-repos/employee-evaluation/composer.json
grep -A1 '"name": "phpoffice/phpword"' ~/github-repos/employee-evaluation/composer.lock

# الترحيلات:
ls ~/github-repos/employee-evaluation/database/migrations/2026_11_03_CD01[678]*

# Triggers (6):
grep -rE "CREATE TRIGGER" ~/github-repos/employee-evaluation/database/migrations/ | wc -l

# Immutability SIGNAL:
grep "SIGNAL" ~/github-repos/employee-evaluation/database/migrations/2026_11_03_CD018_report_snapshots.php

# Tests (109):
grep -rE "^\s*public function test" ~/github-repos/employee-evaluation/tests/cases/ | wc -l

# الأعمدة الجديدة:
grep -E "evaluation_type|final_grade|evaluation_mode|evaluation_frequency" ~/github-repos/employee-evaluation/database/migrations/2026_11_03_CD016_evaluation_foundation.sql

# الصلاحيات الجديدة:
grep -E "grading_scales.manage|employees.profile" ~/github-repos/employee-evaluation/database/migrations/2026_11_03_CD01[67]*.sql
```

---

**نهاية تقرير Sprint 0 — بانتظار تنفيذك للجزء ب على XAMPP ومشاركة المخرجات للاعتماد النهائي.**

</div>
