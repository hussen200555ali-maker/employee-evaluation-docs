# CD-004 — سجل التنفيذ (الوحدة A1)

وفق الملاحظة الإلزامية 2: يُحدَّث **بعد كل بند**، لا في النهاية. تنسيق كل إدخال: الوصف، الملفات، إثبات، التاريخ.

---

## المرحلة 0 — ترحيل قاعدة البيانات (يوم 1)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_15_A1_authentication.sql` + نسخة `CD-001_delivery/database/migrations/` |

### Dry Run لخطة التراجع (ملاحظة إلزامية 3)
نُفِّذ قبل المرحلة 0 — غير مدمر، وأثبت عمل مسارَي النسخ/الاسترجاع:
1. **النسخ (Backup)**: `mysqldump --single-transaction --routines --triggers` اكتمل بدون أخطاء (خروج 0، stderr فارغ، حجم 884,711 بايت) وأنتج ملفًا ذي رأس سليم `-- MariaDB dump 10.19 Distrib 10.4.32`، ويحتوي جداول `notifications`/`password_resets`/`users` ويخلو من الجدولين الجديدين (الوضع قبل الترحيل). ✔
2. **الاسترجاع (Restore)**: عميل `mysql.exe` يتصل بنفس الاعتماديات وينفذ استعلامًا (SELECT 1) بنجاح — مسار `mysql -uroot employee_evaluation_mvc < dump` جاهز وظيفيًا. ✔
3. **الملفات**: نسخ `config/app.php`, `config/config.php`, `config/performance.php`, `app/Views/auth/forgot-password.php` إلى `_emergency/rollback/CD-004/2026-09-15/` (هيكل config/ + views/) وقراءتها. ✔
**الخلاصة**: خطة التراجع جاهزة وقابلة للتطبيق؛ يُعاد Dry Run قبل كل مرحلة بتحديث النسخ.

### التحقق قبل DROP password_resets (ملاحظة إلزامية 5)
| البند | النتيجة |
|---|---|
| عدد الصفوف | 0 (فارغ) — لا خسارة بيانات |
| مراجع FK من جداول أخرى (`information_schema.KEY_COLUMN_USAGE` حيث `REFERENCED_TABLE_NAME='password_resets'`) | **0 مرجع** |
| مراجع كود تشغيلي PHP | لا يوجد (تحقق grep مسبق: `password_resets` لا يظهر إلا في SQL dumps ونسخ البنية `_emergency/` والوثائق) |
| بنية الجدول | `email PK, token, created_at` — بلا `expires_at`/`used` (لا يُستخدم في أي تدفق) |
| الاستنتاج | **DROP آمن** — تحقق موثق قبل التنفيذ |

### النسخ الاحتياطي (قبل الترحيل)
| الأصل | الوجهة |
|---|---|
| DB كامل | `storage/backups/CD-004/2026-09-15/employee_evaluation_mvc_before_phase0.sql` (884,711 بايت، MariaDB dump) |
| `config/app.php`, `config/config.php`, `config/performance.php` | `_emergency/rollback/CD-004/2026-09-15/config/` |
| `app/Views/auth/forgot-password.php` | `_emergency/rollback/CD-004/2026-09-15/views/auth-forgot-password.php` |

### ترحيل DB — `2026_09_15_A1_authentication.sql`
أُسند وأُطبِّق عبر `mysql -uroot --default-character-set=utf8mb4 ... source file` (خروج 0):
1. `DROP TABLE IF EXISTS password_resets;` ✔
2. `CREATE TABLE login_attempts` (id، username VARCHAR(100)، ip_address VARCHAR(45)، attempted_at، success TINYINT(1)، مفاتيح `idx_login_username_time` و`idx_login_attempted_at`) ✔
3. `CREATE TABLE password_history` (user_id INT(11) مطابق users.id، password_hash VARCHAR(255)، created_at، **FK `fk_pwhistory_user` → users(id) ON DELETE CASCADE**) ✔
4. `ALTER TABLE users` +`must_change_password TINYINT(1) NOT NULL DEFAULT 0` +`permissions_version INT UNSIGNED NOT NULL DEFAULT 1` ✔

**فحص بعد الترحيل** (probe): `login_attempts=1`, `password_history=1`, `password_resets=NO`, أعمدة `users` الجديدة موجودة بالقيم الافتراضية، وFK جديد واحد (`password_history.fk_pwhistory_user`). ✔

### انحدار خفيف بعد الترحيل
- `AuthTest` **20/20 نجاح** (الاختبار الحرج لنظام الدخول غير متأثر). ✔
- فشلان **سابقان** غير مرتبطين بالترحيل (اختبارات معيوبة قائمة): `DatabaseTest::testRowCount` (دلالة `rowCount()` بعد `SELECT COUNT(*)` تعيد 1 صفًا) و`HelpersTest::testConvertToHijriValidDate` (تحويل تاريخ هجري) — سُجّلا في `CD-004_OUT_OF_SCOPE.md` ولا يُصلحان ضمن البنود 1–15.

---

## البنود 1–15
(تُضاف بعد كل بند)

### بند 1 — فحص `users.status` بعد `password_verify`
*بانتظار التنفيذ*

### بند 2 — قفل محاولات الدخول
*بانتظار التنفيذ*

### بند 3 — CSRF صفحة الدخول
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Views/auth/login.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- `Auth::generateCsrfToken()`: أصبح يعمل **قبل المصادقة** — أُزيل `if (!self::check()) return '';` المبكّر؛ يعيد استخدام توكن الجلسة الحالي طالما لم تنتهِ صلاحيته (يمنع إبطال توكنات الصفحات الأخرى)؛ تخزين DB (`csrf_tokens`) محصور داخل `self::check()` (الجدول يتطلب `user_id`) مع try/catch للنسخة غير المنتقلة.
- `Auth::validateCsrfToken()`: يتحقق من **الجلسة أولًا** (يعمل قبل المصادقة لتوكن صفحة الدخول)، ثم DB كطبقة ثانية للمستخدمين المسجّلين فقط.
- `enforceCsrfToken()`: أُزيل `'login'` من `$skipRoutes` — أصبح `['register', 'forgot-password', 'reset-password']` وبه تعليق يوثق بند 3 (POST /login الآن يخضع للتحقق من CSRF)؛ الاستثناءات المتبقية لمسارات ما قبل المصادقة التي تولّد توكناتها داخل صفحاتها، ولـ`api/`.
- `app/Views/auth/login.php`: أُضيف `csrf_field()` داخل نموذج POST — يولّد التوكن قبل المصادقة.

**لازم وظيفي (اختبارات):**
- `AuthTest::testEnforceCsrfTokenSkipsLoginPost` كان يختبر السلوك القديم (تخطي POST /login)؛ بعد بند 3 صار `enforceCsrfToken` يرفض الطلب بلا توكن ويدعو `exit()` (Auth.php:235) فيُنهي **مشغّل الاختبارات كلها** بصمت (خروج 0 بلا أي إخراج) — هذا سبب «اختفت مخرجات runner.php». استُبدل الاختبار باختبارين للسلوك الجديد: `testEnforceCsrfTokenAllowsLoginPostWithValidToken` (توكن صحيح يمرّ) و`testEnforceCsrfTokenRejectsLoginPostWithoutToken` (رفض بلا توكن عبر عملية فرعية — لا يصل تنفيذ ما بعد الرفض).

**الإثبات:**
- `php -l` لـ `Auth.php` و`login.php` و`AuthTest.php`: لا أخطاء. ✔
- محاكاة توكن ما قبل المصادقة (سكربت تجريبي): طول 64، إعادة استخدام `reuse_same=yes`، تحقق صحيح `validate_ok=yes`، تحقق خاطئ مرفوض `validate_bad=rejected` → PASS. ✔
- **Live HTTP** (Apache/MySQL): GET /login → 200 ويحوي `name="_token"` بقيمة 64-سداسي عشرية (csrffield يُرسم قبل المصادقة)؛ إعادة استخدام التوكن عبر إعادة تحميل الصفحة (REUSE_SAME=True)؛ POST /login **بتوكن صحيح** → 302 → `/login` (وصل لفحص الاعتمادات — مرّ من بوابة CSRF)؛ POST **بلا توكن** أو **بتوكن خاطئ** → 302 → `/evaluations/excel/import` (رفض CSRF كما هو محدد بلا HTTP_REFERER). ✔
- `AuthTest` **21/21 نجاح** (بعد تحديث الاختبارات للسلوك الجديد)؛ المجموعة الكاملة: AuthTest 21/21 — مع فشلين سابقين موثقين (`DatabaseTest` 4/5، `HelpersTest` 2/3). ✔

### بند 4 — الخروج عبر POST
*بانتظار التنفيذ*

### بند 5 — تحصين الجلسة
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `config/config.php` (إعدادات الجلسة + إزالة السطر الفارغ الفاتح)، `public/index.php` (إعادة ترتيب: تحميل الإعدادات قبل `session_start`) |

**التنفيذ:**
- `config/config.php`: كتلة إعدادات جلسة موحّدة تُنفَّذ قبل `session_start()`: `session.gc_maxlifetime=1800`, `session.cookie_lifetime=0`, `session.cookie_httponly=1`, `session.cookie_samesite=Strict`, `session.cookie_secure=0`, `session.use_strict_mode=1`, `session.use_only_cookies=1`, `session_name('EVALSESSID')` (محروسة بـ`session_status()===PHP_SESSION_NONE`).
- `public/index.php`: نُقل `require config/config.php` و`require config/database.php` **قبل** `session_start()` (كانا بعدها — فسيسبب الإعدادات بلا مفعول).

**اكتشافات عرَضية عُولجت ضمن البند (لازمه وظيفي للبند ذاته):**
1. `config/config.php` كان يبدأ بسطر فارغ قبل `<?php` → إخراج مبكر يمنع فعالية إعدادات الجلسة — أُزيل السطر الفاتح.
2. `public/index.php` كان مشفّرًا **CP-1256** (تراثي) → حُوِّل إلى **UTF-8** (التحويل حرفي معكوس 1:1، لا تغيير دلالي) — نسخة مكافئة CP-1256 محفوظة في `_emergency/rollback/CD-004/2026-09-15/index.php.orig-cp1256.raw`.

**إشعار مسبق (ملاحظة إلزامية 1):** تغيير `session_name` إلى `EVALSESSID` يبطل الجلسات القائمة (PHPSESSID) — **مطلوب إعادة تسجيل دخول جميع المستخدمين**؛ نُفِّذ في بداية يوم العمل.

**الإثبات:**
- `php -l` لكلا الملفين: لا أخطاء. ✔
- Smoke (التسلسل الفعلي config←session_start←echo): `session_name=EVALSESSID`, `gc_maxlifetime=1800`, `cookie_httponly=1`, `cookie_samesite=Strict`, `use_strict_mode=1`, `use_only_cookies=1`, جلسة تبدأ بـ26 حرفًا بلا تحذيرات. ✔
- `AuthTest` **20/20 نجاح** (لا انحدار). ✔

### بند 6 — إخفاء الأخطاء ودمج الإعدادات
*بانتظار التنفيذ*

### بند 7 — إصلاح حارس Admin/UserController
*بانتظار التنفيذ*

### بند 8 — نسخة صلاحيات المستخدم
*بانتظار التنفيذ*

### بند 9 — إعادة تعيين كلمة المرور عبر Admin
*بانتظار التنفيذ*

### بند 10 — شاشة تغيير كلمة المرور
*بانتظار التنفيذ*

### بند 11 — سياسة كلمة المرور
*بانتظار التنفيذ*

### بند 12 — إزالة «تذكرني»
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Views/auth/login.php` |

**التنفيذ:** حُذف checkbox «تذكرني» من نموذج الدخول (كان بلا `name` وكذلك بلا أثر فعلي في تدفق الجلسة)؛ بقيت `form-options`ضمّ ربط «نسيت كلمة المرور؟» كما هي.

**الإثبات:**
- `php -l`: لا أخطاء. ✔
- Live HTTP: صفحة `/login` لا تحتوي `name="remember"`، ورابط `forgot-password` حاضر. ✔

### بند 13 — سكربت تنظيف CSRF
*بانتظار التنفيذ*

### بند 14 — دور Admin ديناميكي
*بانتظار التنفيذ*

### بند 15 — شاشة الإشعارات
*بانتظار التنفيذ*