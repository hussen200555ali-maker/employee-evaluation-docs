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
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Controllers/AuthController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- في `AuthController::login()` بعد نجاح `password_verify` (وبعد مسح/تسجيل المحاولة الناجحة) أُضيف فحص `$userCheck->status`:
  - `active`: يُكمل تدفق الدخول الحالي إلى `/dashboard`.
  - `suspended`: رفض + `Audit::log('USER_LOGIN_SUSPENDED', id, 'users', {username})` + `Auth::notifyAdmins('محاولة دخول بحساب موقوف — …')` + فلاش «تم تعليق حسابك…» + توجيه إلى `/login`.
  - `invited`: رفض + `Audit::log('USER_LOGIN_INVITED', id, 'users', {username})` + `Auth::notifyAdmins('محاولة دخول بحساب غير مفعَّل — …')` + فلاش «لم يتم تفعيل حسابك بعد…» + توجيه إلى `/login`.
- **قرار داخل البند:** تدفق `invited` الكامل (شاشة تعيين كلمة المرور + التوجيه الإجباري) مؤجل إلى **بند 10**؛ في هذا البند يُرفض الدخول لكلا الحالتين. لا توجد شاشة تعيين كلمة مرور ولا مسار لها في `routes/web.php` حاليًا.
- المساعد العام `Auth::notifyAdmins(title, message)` (أُضيف مسبقًا كخطوة أولى للبند) هو مسار الإشعار الموحّد، ويُعيد استخدامه بند 2 أيضًا (`notifyLoginLocked`).

**الإثبات:**
- `php -l` للملفين: لا أخطاء. ✔
- `AuthTest` **27/27 نجاح** (3 اختبارات جديدة عبر عملية فرعية مع بذر مستخدمين مؤقتين وقراءة أثر التنفيذ):
  - `testLoginRejectsSuspendedAccount` — كلمة مرور صحيحة + `status=suspended` → لا جلسة (`SESSION_USER_ID=none`) + فلاش الرفض + `USER_LOGIN_SUSPENDED` + إشعار لمشرف نشط (role_id=1). ✔
  - `testLoginRejectsInvitedAccount` — نفسه مع `invited` + `USER_LOGIN_INVITED`. ✔
  - `testLoginContinuesForActiveAccount` — `active` → جلسة مؤمّنة (`SESSION_USER_ID=<id>`) بلا فلاش + `USER_LOGIN_SUCCESS`. ✔
  - تنظيف تلقائي في `tearDown` (بذر معزول بأسماء `cd004.*`)؛ شُغِّل الاختبار **مرتين متتاليتين** → 27/27 وبلا أي صفوف متبقية (تحقق SQL: users=0, login_attempts=0, notifications=0). ✔
- **Live HTTP** (Apache/MySQL، نموذج الدخول الحقيقي مع توكن CSRF): ثلاثة مستخدمين مؤقتين (suspended/invited/active) بكلمة مرور صحيحة →
  - suspended: `302 → /login` + `ACTION_USER_LOGIN_SUSPENDED=1` + `NOTIF=1`.
  - invited: `302 → /login` + `ACTION_USER_LOGIN_INVITED=1` + `NOTIF=1`.
  - active (ضبط موجب): `302 → /dashboard` + `ACTION_USER_LOGIN_SUCCESS=1` + `NOTIF=0`.
  - تنظيف: `USERS=0` → **PASS**. ✔
- انحدار خفيف: `DatabaseTest` 4/5 و`HelpersTest` 2/3 (نفس الفشلين السابقين الموثقين في OUT_OF_SCOPE) — بلا انحدار جديد. ✔

### بند 2 — قفل محاولات الدخول
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Controllers/AuthController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- `Auth` (دوال ثابتة جديدة + ثوابت): `MAX_LOGIN_ATTEMPTS=5`، `LOCKOUT_WINDOW_SECONDS=900` (15 دقيقة)، `countLoginFailures(username)`، `isLoginLocked(username)`، `logLoginAttempt(username, success, userId)` (تخزين username+IP في `login_attempts`)، `clearLoginAttempts(username)`، `loginDelaySeconds(priorFailures)` (تأخير متدرج 1/2/4/8 ثوانٍ بسقف 8)، `notifyLoginLocked(username)` (إشعار نوع `warning` لجميع أدوار Admin النشطة — نفس نهج CsrfGraceLogger).
- `AuthController::login()`:
  - قبل التحقق من الاعتمادات: إذا كان الحساب مقفولًا → رفض + `Audit::log('USER_LOGIN_LOCKED_BLOCKED')` + فلاش + توجيه (بدون تسجيل محاولة جديدة).
  - عند الفشل: يُحسب عدد المحاولات السابقة ثم يُسجَّل فشل جديد؛ عند بلوغ العتبة (5) → `Audit::log('USER_LOGIN_LOCKED')` + `notifyLoginLocked` + فلاش القفل، وإلا فلاش الاعتمادات الخاطئة؛ ثم `sleep` بالتأخير المتدرج قبل الرد (أوقات فعلية رُصدت: 1/2/4/8/8 ثانية).
  - عند النجاح: `clearLoginAttempts` + `logLoginAttempt(..., true)` ثم التدفق الحالي (مسح الجلسة/أدوار/صلاحيات/Audit).
- إعادة صياغة استخراج `username` بـ`trim` (اتساق مفتاح القفل).

**قرار داخل البند:** مفتاح القفل هو `username` (حماية الحساب) بغض النظر عن IP؛ يُخزَّن IP في السجلات للتحقيق.

**الإثبات:**
- `php -l` للملفات الثلاثة: لا أخطاء. ✔
- `AuthTest` **24/24 نجاح** (3 اختبارات جديدة: تسلسل التأخير، العد/القفل/المسح، مسح عند النجاح). ✔
- **Live HTTP**: 5 طلبات POST بـاعتمادات خاطئة وتوكن صحيح → failCount 1→5، أوقات ~1.1/2.1/4.1/8.1/8.1 ثانية؛ بعد الخامسة: إشعار في `notifications` (title يحوي اسم المستخدم، type=warning للمشرفين)؛ الطلبان #6 و#7 → فشل **مُحصَّل** (failCount يبقى 5 — لا محاولة جديدة على المسار المقفول) → PASS. تنظيف السجلات والإشعارات التجريبية بعد الاختبار. ✔

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
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-16 |
| الحالة | **مكتمل** |
| الملفات | `routes/web.php`، `app/Controllers/AuthController.php`، `app/Views/layouts/header.php`، `tests/cases/Core/AuthTest.php`، `CD-001_delivery/appendices/routes_inventory.txt` |

**التنفيذ (Remedy P2 في وثيقة A1 §3.3):**
- `routes/web.php`: حُذف `$router->get('logout', ...)` نهائيًا (أصبح GET /logout → 404) واستُبدل بـ`$router->post('logout', ...)` مع تعليق يوثق البند — الخروج الآن عبر POST فقط، ما يمنع Logout-CSRF عبر رابط مُضمَّن.
- `AuthController::logout()`: `Auth::logout()` (مسح بيانات الجلسة) + `session_destroy()` + **إتلاف كوكي الجلسة صراحةً** عبر `setcookie(session_name(), '', time()-42000, path/domain/secure/httponly)` محروسًا بـ`ini_get('session.use_cookies')` وبقيم `session_get_cookie_params()` (اسم الكوكي الفعلي EVALSESSID بعد بند 5) ثم توجيه `/login`.
- `app/Views/layouts/header.php`: ربط الخروج في القائمة المنسدلة تحوّل من `<a href>` إلى **نموذج POST** (method=POST، action=APP_URL/logout) مع `csrf_field()` — يُغطَّى تلقائيًا بـ`Auth::enforceCsrfToken()` (public/index.php:37).
- `CD-001_delivery/appendices/routes_inventory.txt`: سطر المسار حُدِّث إلى POST + تعليق البند.
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/AuthController.pre-item4.php`, `views/header.pre-item4.php`, `routes/web.pre-item4.php`.

**الإثبات:**
- `php -l` للملفات الأربعة: لا أخطاء. ✔
- `AuthTest` **28/28 نجاح** (اختبار جديد `testLogoutRouteIsPostOnly`: عبر Reflection يتحقق من خريطة `$router` أن `GET['logout']` غير موجود وأن `POST['logout']` = `App\Controllers\AuthController@logout`). ✔
- **Live HTTP** (Apache/MySQL، جلسة حقيقية EVALSESSID): مستخدم مؤقت فاعل →
  - GET /logout → **404** وبعدها GET /dashboard → **200** (الجلسة سليمة — رابط GET لا يُخرج). ✔
  - POST /logout **بلا توكن** → 302 → `/evaluations/excel/import` (رفض CSRF كما هو محدد — لا توجيه لدخول) وبعدها GET /dashboard → **200** (الجلسة سليمة). ✔
  - POST /logout **بتوكن CSRF سليم** (مستخرج من نموذج الخروج المعروض في الـ header) → **302 → /login** مع `Set-Cookie: EVALSESSID=deleted; expires=Thu, 01 Jan 1970 …; Max-Age=0` (كوكي مُتْلَف) وبعدها GET /dashboard → **302 → /login** (الجلسة ملغاة). ✔
  - تحقق أن نموذج الخروج في الـ header يحوي `action=".../logout"` + `name="_token"` (64 محرفًا). ✔
  - تنظيف: USERS=0, NOTIF=0, ATTEMPTS=0, USER_ROLES=0, AUDIT=0 → **PASS**. ✔
- انحدار خفيف: `DatabaseTest` 4/5 و`HelpersTest` 2/3 (الفشلان السابقان الموثقان في OUT_OF_SCOPE) — بلا انحدار جديد. ✔

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
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-16 |
| الحالة | **مكتمل** |
| الملفات | `config/config.php` (الدمج + إخفاء الأخطاء)، `public/index.php` (إزالة Trace)، `_emergency/verify_phase1.php`، `storage/.htaccess`، حذف `config/app.php` و`config/performance.php` |

**التنفيذ (ر.ق 1 + قرار كبير المستشارين 2026-09-16):**
- **دمج `app.php` + `performance.php` في `config/config.php`** وفق جدول قيم الدمج المعتمد في خطة التنفيذ:
  - `memory_limit` **2048M** (رُفضت 4096M) و`max_execution_time` **600** (رُفض 1200) — كما طُلب.
  - `BACKUP_BATCH_SIZE` **100** (قيمة `performance.php` المعتمدة في الجدول — كانت 1000 في config.php).
  - `opcache_reset()` **مستبعد عمدًا** من الدمج (يبقى فقط في كود النسخ الاحتياطي `app/Core/BackupOptimizer.php`) — كما طُلب بعدم نقله.
  - `session.gc_maxlifetime=1800` و`session.cookie_lifetime=0` و`session_name('EVALSESSID')` (بند 5) باقية كما هي.
  - `DEBUG_MODE`/`APP_URL`/`APP_ROOT`/`CSRF_GRACE_PERIOD_MINUTES` — نسخة واحدة في config.php.
- **حذف الملفين نهائيًا**: `config/app.php` + `config/performance.php` (متحقق مسبقًا: لا `require` لأي منهما في أي موضع). grep بعد الحذف: **لا مراجع متبقية** في config/public/app/routes/cron/tests.
- **إخفاء الأخطاء**: `DEBUG_MODE=false`، `error_reporting(E_ALL)`، `display_errors=0`، `log_errors=1`، `ini_set('error_log', APP_ROOT.'/storage/logs/php-error.log')` مع إنشاء دفاعي `@mkdir` للمجلد.
- **`storage/logs/`**: أُنشئ + `storage/.htaccess` بـ`Require all denied` (يمنع الوصول المباشر عبر الويب لسجلات PHP والنسخ الاحتياطية في storage/ — كان ملف حقيقي يُقدَّم مباشرة).
- **`public/index.php` (الأصل 44–49)**: حُذف فرع `DEBUG_MODE` وطباعة الـ Trace بالكامل؛ استُبدل بـ`error_log('[FATAL] '…)` كامل (الرسالة+الملف+السطر+الـTrace) + `http_response_code(500)` + صفحة عامة «حدث خطأ غير متوقع» (بدلًا من 404).
- **`_emergency/verify_phase1.php`**: أُزيل `config/app.php` من قائمة فحص الصياغة؛ استُبدل القسم [2/8] بفحوصات الدمج/الإخفاء (app.php/performance.php محذوفان، لا require لهما، DEBUG_MODE=false، display_errors=0، log_errors=1، error_log→storage/logs، .htaccess موجود)؛ استُبدل `php -l` بـ`PHP_BINARY` ليعمل بلا PHP على PATH.

**الإثبات:**
- `php -l` لـ config.php وindex.php وverify_phase1.php: لا أخطاء. ✔
- grep لأي `require` أو مرجع للملفين المحذوفين: **لا شيء** (config، public، app، routes، cron، tests). ✔
- `AuthTest` **28/28 نجاح** (لا انحدار). ✔
- **اختبار خطأ متعمد (CLI)**: سكربت يستدعي config.php ويطبّع JSON ثم `trigger_error('CD004_ITEM6_DELIBERATE_ERROR', E_USER_WARNING)`:
  - إعدادات تحققت كلها صحيحة (debug_false, display_errors_0, log_errors_1, error_log_path, memory_2048, exec_time_600, الملفان محذوفان).
  - `storage/logs/php-error.log` حوى الواسم؛ وstdout خلا من نص الخطأ (`STDOUT_HIDES_ERROR=YES`) → **PASS**. ✔
- **Live HTTP** (Apache/MySQL) — التطبيق يعمل بالإعداد المندمج:
  - GET /login → 200 مع النموذج؛ GET /dashboard (ضيف) → 302 /login. ✔
  - GET /storage/logs/php-error.log → **403** (محمي). ✔
  - خطأ متعمد عبر HTTP (مسبار مؤقت `public/_item6_error_probe.php` يُرمي Exception) → **500** بجسم فارغ (`PROBE_HIDES_ERROR=YES` — لا نص خطأ/سلسلة/مسار) + الواسم سُجّل في `storage/logs/php-error.log` بعمود Asia/Riyadh؛ حُذف المسبار بعد الاختبار. → **PASS**. ✔
- `_emergency/verify_phase1.php`: القسم [2/8] الجديد **10/10 ✓** والفحصان القديمان المتبقيان (`division_id`، `analysis.view`) فشلان **سابقان** لمرحلة DB قديمة (متحقق: غائبان قبل البند 6، وترحيل CD-004 سليم: login_attempts/password_history موجودان) — سُجّلا في OUT_OF_SCOPE (البندان 6 و7). ✔
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/config/config.pre-item6.php`, `app.pre-item6.php`, `performance.pre-item6.php`, `public/index.pre-item6.php`. ✔

### بند 7 — إصلاح حارس Admin/UserController
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Controllers/Admin/UserController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:** كان `__construct()` يستدعي `return (new ErrorController())->forbidden();` بلا `exit` — يقصر العمل على الكونستركتور فقط (تُهمَل القيمة المعادة) ويستمر تنفيذ دالة الإدارة المستهدفة بلا تحقق. أُضيف `exit;` بعد `forbidden()` ليتطابق مع النمط الصحيح في `Auth::can()` (عرض 403 ثم إيقاف فوري). وُثّق التعديل بتعليق داخلي يشير للبند 7.

**الإثبات:**
- `php -l`: لا أخطاء (`UserController.php`, `AuthTest.php`). ✔
- **AuthTest 29/29** ← اختبار جديد `testAdminUserControllerGuardStopsNonAdmin`:
  - عملية فرعية بمستخدم **Staff**: `new UserController()` يوقف التنفيذ قبل `index()` (لا `PHASE1_SENTINEL`) ويعرض صفحة 403 ولا يظهر محتوى «إدارة المستخدمين». ✔
  - عملية فرعية بمستخدم **Admin**: `new UserController()` يمر عبر الحارس (`ADMIN_PASSED`). ✔
  - ملاحظة آلية: عبّر الاختبار عن حد أقصى لقراءة الأنبوبة في `runCli` (مخرجات HTML كبيرة >4KB تُسدّ stdout pipe عند قراءة stderr أولًا) — عُولج بتمرير `$stdoutFile`، وسُجّل كثمرة معرفة في OUT_OF_SCOPE (البند 8).
- **Live HTTP** (Apache/MySQL، ببذرة مستخدمين مؤقتة+أدوار):
  - Staff: تسجيل دخول 302 /dashboard ثم GET `/admin/users` → **403** مع «هذه المساحة ليست ضمن صلاحياتك» دون أي جزء من «إدارة المستخدمين». ✔
  - Staff: POST `/admin/users/update-role` (دور هدف + توكن سليم) → **403** و**لا** سجل `USER_ROLE_UPDATE` جديد للهدف (0 قبل = 0 بعد). ✔
  - Admin: GET `/admin/users` → **200** مع «إدارة المستخدمين». ✔
  - تنظيف: `USERS=0` بعد الحذف. → **PASS**. ✔
- نسخة تراجع: `_emergency/rollback/CD-004/2026-09-15/UserController.pre-item7.php`. ✔

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