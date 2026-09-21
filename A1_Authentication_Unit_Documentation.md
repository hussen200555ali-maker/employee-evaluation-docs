# توثيق الوحدة A1 — المصادقة والدخول والجلسات

| بند | البيان |
|---|---|
| **اسم الوثيقة** | `A1_Authentication_Unit_Documentation` |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **مرجع الإعداد** | التوجيه الاستشاري CD-003 |
| **الوحدة** | A1 — المصادقة والدخول والجلسات (Authentication, Login, Sessions) |
| **النطاق** | دراسة/توثيق قراءة فقط — لا تغييرات في الشيفرة |
| **التسليم** | إدارة المشروع فقط |

> **ملاحظات منهجية (مُعلنة صراحة):**
> - الدراسة قائمة على **القراءة فقط** للشيفرة المصدري والمخطط الحي للمشروع؛ لم تُجرَ اختبارات تشغيلية حية.
> - **لقطات الشاشات غير متوفرة**: خادم MySQL أُغلق عمدًا لاستعادة حالة الاستضافة الأصلية، فلا يمكن تشغيل الشاشات للتصوير. لذلك تُوثَّق الشاشات من مصدر HTML/العرض المباشر مع مراجع الأسطر.
> - جميع المراجع بصيغة `ملف:سطر` لأغراض التحقق.
> - المرجع الأمني العام: وثيقة CD-001 `13_Security.md` (نتائجها مؤكدة ومتناسقة مع هذه الدراسة).

---

## 1. نظرة عامة على الوحدة

وحدة A1 هي **البوابة الوحيدة** لدخول النظام والخروج منه، وتضمن أن كل صفحة/إجراء لا يُنفَّذ إلا بعد مصادقة ناجحة وتحقق من الصلاحية عبر نظام الأدوار (RBAC). تشمل:

| الجانب | الوصف |
|---|---|
| الدخول | تحقق من `username` أو `email` + `password_verify` + إنشاء الجلسة |
| الأدوار والصلاحيات | جلبها وقت الدخول وتخزينها في الجلسة + فحصها في كل طلب |
| الجلسة | إعادة توليد `PHPSESSID` عند الدخول، إتلاف البيانات عند الخروج |
| حماية CSRF | توليد توكن لكل جلسة + تخزين في الجلسة وفي جدول `csrf_tokens` + فحص كل POST |
| المساعدة | تسجيل تدقيق، رسائل Flash، صفحات 403/404، لوحة تحكم محمية |

**الأرقام الحية (من المخطط):**
| العنصر | القيمة | المصدر |
|---|---|---|
| حسابات المستخدمين | 7 (ترقيم حتى `AUTO_INCREMENT=8`) | `db_live_schema.sql:652` |
| الأدوار | 6 (ترقيم حتى `AUTO_INCREMENT=7`) | `db_live_schema.sql:561` |
| سجلات التدقيق | ~466 (`AUTO_INCREMENT=467`) | `db_live_schema.sql:54` |
| توكنات CSRF | ~91 (`AUTO_INCREMENT=92`) | `db_live_schema.sql:237` |
| إشعارات مرسلة للمشرفين | 5 (`AUTO_INCREMENT=6`) | `db_live_schema.sql:464` |

---

## 2. الملفات والمكونات

### 2.1 الملفات البرمجية

| الملف | الدور | ملاحظات |
|---|---|---|
| `app/Controllers/AuthController.php` | `showLoginForm` / `login` / `logout` / `csrfToken` | قلب الوحدة؛ 80 سطرًا |
| `app/Core/Auth.php` | 13 دالة ثابتة: `check, id, is, hasRole, isAdmin, user, userHasPermission, can, logout, generateCsrfToken, validateCsrfToken, enforceCsrfToken` | ترخيص + CSRF |
| `app/Models/User.php` | استعلامات المصادقة والجلب: `findByUsernameOrEmail, findById, getUserRoles, getUserPermissions, updateLastLogin` + دوال إدارة الحسابات | 373 سطرًا |
| `app/Core/CsrfGraceLogger.php` | فترة سماح CSRF (240 دقيقة) + تسجيل + إشعار المشرفين | إشعار المشرفين عبر دور Admin ديناميكي (بند 14) |
| `app/Core/Flash.php` | رسائل جلسة تُعرض مرة واحدة | `flash_messages` |
| `app/Core/Audit.php` | الكتابة في `audit_logs` (user_id, action, entity, ip) | يبتلع الأخطاء |
| `app/Core/Database.php` | مساعد PDO: `query/bind/execute/fetch/fetchAll/fetchColumn` + Transactions | `ATTR_ERRMODE=EXCEPTION` |
| `app/Core/Controller.php` | `view / redirect / json` | قاعدة المتحكمات |
| `app/Core/Router.php` | توزيع المسارات + الوقوع التلقائي على 404 | `direct()` |
| `app/Controllers/ErrorController.php` | `notFound` (404) / `forbidden` (403) | |

### 2.2 ملفات العرض

| الملف | الحالة |
|---|---|
| `app/Views/auth/login.php` | كاملة (60 سطرًا) |
| `app/Views/auth/forgot-password.php` | **فارغة، 0 بايت** |
| `app/Views/errors/403.php` و`404.php` | كاملة |
| `app/Views/layouts/header.php` و`footer.php` | تضمين الهيدر/الفوتر + عرض Flash |

### 2.3 المسارات المعنية (routes/web.php)

| المسار | الدالة | حماية |
|---|---|---|
| `GET /login` (سطر 22) | `showLoginForm` | عام |
| `POST /login` (سطر 23) | `login` | معفى من CSRF (قائمة التخطي) |
| `GET /logout` (سطر 24) | `logout` | — |
| `GET /dashboard` (سطر 25) | `DashboardController@index` | مُنشئ يحوّل غير المسجَّل لـ `/login` |
| `GET /csrf/token` (سطر 309) | `csrfToken` | يتطلب `Auth::check()` |

### 2.4 الجداول المرتبطة (db_live_schema.sql)

| الجدول | السطر | أبرز الأعمدة |
|---|---|---|
| `users` | 652 | `username/email` (فريد)، `password_hash`, `employee_id` (فريد FK), `status enum(active,suspended,invited)`, `last_login_at` |
| `csrf_tokens` | 237 | `user_id FK`, `token`, `used`, `expires_at` |
| `password_resets` | 480 | `email PK`, `token`, `created_at` — **لا عمود انتهاء/استخدام** |
| `audit_logs` | 54 | `user_id FK NULL`, `action`, `entity_type`, `entity_id`, `details JSON`, `ip_address` |
| `notifications` | 464 | يُستخدم في إشعارات CSRF للمشرفين |
| `roles` | 561 | `name` فريد، `is_system_role` |
| `user_roles` | 641 | الربط many-to-many |

### 2.5 الإعدادات

| الملف | المضمون | الحالة |
|---|---|---|
| `config/config.php` | إعدادات موحّدة (بند 6): `DEBUG_MODE=false`, `display_errors=0` + `log_errors=1` → `storage/logs/php-error.log`, `CSRF_GRACE_PERIOD_MINUTES=240`, `APP_TIMEZONE=Asia/Riyadh`, حدود ذاكرة/رفع كبيرة | **محمّل** (index.php:10) |
| `config/app.php` + `config/performance.php` | دُمجتا في `config/config.php` (بند 6) وحُذفتا | **محذوفتان** |
| `config/database.php` | `root` بلا كلمة مرور، `employee_evaluation_mvc`, `utf8mb4` | **محمّل** (index.php:11) |

---

## 3. دورة العمل (Workflow)

### 3.1 الدخول الناجح
1. `POST /login` → `AuthController::login()` (AuthController.php:16).
2. `User::findByUsernameOrEmail($_POST['username'])` (User.php:14) — استعلام مجمّع مع `user_roles` و`roles` لإحضار `role_name`.
3. `password_verify($_POST['password'], $user->password_hash)` — عند الصح:
   - `User::findById()` لإحضار الكائن الكامل + `employees.full_name` (User.php:30–54؛ القِيمة النهائية "مدير النظام" عند غياب الربط).
   - `session_unset()` ثم `session_regenerate_id(true)` (AuthController.php:29–30) — درء تثبيت الجلسة.
   - تخزين: `user_id`, `user_object`, `user_roles`, `user_permissions` (AuthController.php:32–37).
   - `updateLastLogin()` و`Audit::log('USER_LOGIN_SUCCESS', ...)` (AuthController.php:40–48).
   - توجيه إلى `/dashboard` ثم `exit` (AuthController.php:50–51).
4. `DashboardController::__construct` (DashboardController.php:24–27) يعيد توجيه غير المسجَّل إلى `/login`.

### 3.2 الدخول الفاشل
- `Audit::log('USER_LOGIN_FAILED', ...)` مع `username_attempt` (AuthController.php:54–59).
- `Flash::set(..., 'danger')` برسالة موحّدة «اسم المستخدم أو كلمة المرور غير صحيحة.» (AuthController.php:61) — **لا كشف** لأي حساب صحيح.
- إعادة توجيه لـ `/login` (AuthController.php:62–63).

### 3.3 الخروج
- `GET /logout` → `Auth::logout()` = `session_unset()` (Auth.php:53–55) ثم `session_destroy()` (AuthController.php:69) ثم توجيه `/login`.
- **ملاحظات:** لا يُمسح كوكي `PHPSESSID` صراحةً، ولا يُدورّ توكن CSRF عند الخروج، والخروج عبر GET (قابل للتزوير كـ logout-CSRF).

### 3.4 حماية CSRF (Overview)
| الخطوة | الموقع |
|---|---|
| توليد التوكن (32 بايت `random_bytes`) بعمر ساعتين وتخزينه في الجلسة والجدول | `Auth.php:117–148` |
| حقن التوكن في الهيدر `<meta name="csrf-token">` وكل نموذج عبر `csrf_field()` | `header.php:31`, `helpers.php:12` |
| فحص كل طلب POST في المتصفح | `public/index.php:37` → `Auth::enforceCsrfToken()` |
| المسارات المعفاة: `login, register, forgot-password, reset-password` وكل `api/...` | `Auth.php:206–223` |
| الفشل → JSON 403 (AJAX) أو Flash + إعادة توجيه (`HTTP_REFERER`) | `Auth.php:225–237` |
| التخزين الثانوي في `csrf_tokens` (فحص `used=0` + `expires_at`) وتحديد `used=1` | `Auth.php:165–183` |
| فترة سماح 240 دقيقة: تسجيل استخدام + إشعار للمشرفين + إغلاق تلقائي | `CsrfGraceLogger.php` |

### 3.5 الوصول المرفوض (403/404)
- 403: `Auth::can()` تُظهر `ErrorController->forbidden()` و`exit` (Auth.php:100–107).
- 404: `Router::direct()` يوجّه أي URI غير مطابق إلى `ErrorController->notFound()` (Router.php:48–49).
- **ثغرة معروفة:** في `Admin\UserController::__construct` تُستدعى `forbidden()` دون `exit` (المرجع: 13_Security.md §2أ).

---

## 4. الشاشات

> **لقطات الشاشات غير متوفرة** (MySQL متوقف لاستعادة حالة الاستضافة الأصلية — لا يمكن تشغيل الشاشات للتصوير). تُوثَّق الشاشات من مصدر العرض.

### 4.1 شاشة تسجيل الدخول `app/Views/auth/login.php`
| العنصر | التفاصيل |
|---|---|
| الهيدر/الفوتر | `layouts/header.php` + `footer.php` |
| عنوان | «تسجيل الدخول إلى النظام» (سطر 10) |
| حقل الهوية | `username` — «اسم المستخدم أو البريد الإلكتروني» (سطر 30) |
| حقل كلمة المرور | `password` (سطر 37) |
| عرض الخطأ | `$error` في بطاقة `alert-message error` (سطر 17–23) — لكن المرسل فعليًا عبر Flash في الهيدر |
| نموذج | `POST {APP_URL}/login` بلا `_token` (سطر 25) |
| «تذكرني» | checkbox **بلا `name`** (سطر 42) → لا يُرسل، واجهة ميتة دون تنفيذ خلفي |
| «نسيت كلمة المرور؟» | رابط `href="#"` (سطر 45) ميت — لا مسار/عرض |
| زر | «تسجيل الدخول» (سطر 47–50) |

### 4.2 شاشة استعادة كلمة المرور `forgot-password.php`
- **فارغة 0 بايت**؛ لا مسار لها في `routes/web.php`؛ جدول `password_resets` موجود ولم يُستخدم.

### 4.3 صفحتي الخطأ
| الصفحة | المحتوى |
|---|---|
| `403.php` | كود 403 + «هذه المساحة ليست ضمن صلاحياتك» + عرض اسم الصلاحية المطلوبة + زر العودة للوحة |
| `404.php` | كود 404 + «لا يمكن العثور على الصفحة المطلوبة» + زر العودة |

### 4.4 الهيدر المرتبط بالصلاحيات `header.php`
- يعرض قائمة تبويبات تعتمد على `Auth::userHasPermission(...)` و`Auth::isAdmin()` (سطر 55–430).
- يقحم `<meta name="csrf-token">` (سطر 31) و`Flash::display()` (سطر 472).
- رابط الخروج `GET /logout` (سطر 452) + «أهلاً، username» (سطر 441).

### 4.5 لوحة التحكم `dashboard/index`
- محمية بالمُنشئ؛ تُعيد جلب الأدوار والصلاحيات من DB في كل تحميل (DashboardController.php:53–55).

---

## 5. قواعد العمل

| # | القاعدة | الموضع |
|---|---|---|
| 1 | المعرف هو `username` **أو** `email` الفريديّان (فريد على مستوى الجدول) | `users` schema:663–664 |
| 2 | كلمات المرور تُخزَّن دائمًا عبر `password_hash(PASSWORD_DEFAULT)` وتُفحص عبر `password_verify` | User.php:243, 369, AuthController.php:23 |
| 3 | الحساب له حالة `active / suspended / invited` | schema:658 |
| 4 | ربط الحساب بالموظف اختياري وفريد (`employee_id`)؛ غيابه يعني «مدير النظام» | User.php:50–51 |
| 5 | الأدوار والصلاحيات عبر علاقات many-to-many (`user_roles`, `role_permissions`) | schema:641, 489 |
| 6 | دور `Admin` يملك كل الصلاحيات ضمنيًا (`isAdmin` bypass) | Auth.php:84–92 |
| 7 | رسالة خطأ الدخول **موحدة** مهما كان سبب الفشل | AuthController.php:61 |
| 8 | كل نجاح/فشل دخول يُسجَّل في `audit_logs` مع IP | Audit.php:18–44 |
| 9 | آخر دخول يُحدَّث في `users.last_login_at` | User.php:213 |
| 10 | توكن CSRF عمره ساعتان، فترة سماح 240 دقيقة مع إشعارات للمشرفين | Auth.php:130, CsrfGraceLogger.php:33 |
| 11 | كل طلب POST خاضع لفحص CSRF إلا: صفحات ما قبل الدخول وواجهات `api/*` | Auth.php:206–223 |
| 12 | توليد توكن جديد بعد الدخول + ترقية معرّف الجلسة | AuthController.php:29–30 |

---

## 6. الأمان الحالي

| الأمان | الآلية | المرجع |
|---|---|---|
| سلامة كلمات المرور | `password_hash`/`password_verify` (bcrypt عبر PASSWORD_DEFAULT) | User.php:243, 369 |
| حقن SQL | Prepared Statements عبر طبقة `Database` في كل النماذج | Database.php:40–67 |
| حماية CSRF | توكن جلسة + تخزين `csrf_tokens` + `hash_equals` + فحص كل POST + `csrf_field()` وmeta في الهيدر | Auth.php:155–197 |
| فحص ثنائي للتوكن | جلسة أولًا ثم `csrf_tokens` (يُعلَّم `used=1`) | Auth.php:161–183 |
| فترة سماح مضبوطة | 240 دقيقة + تسجيل استخدام + إشعار المشرفين + إغلاق تلقائي | CsrfGraceLogger.php |
| ترقية الجلسة | `session_unset()` + `session_regenerate_id(true)` عند الدخول | AuthController.php:29–30 |
| RBAC | `userHasPermission` + `can()` (403 + exit) + قائمة تبويبات حسب الصلاحيات | Auth.php:84–107, header.php |
| تدقيق | `audit_logs` لكل نجاح/فشل دخول + أحداث CSRF | Audit.php, CsrfGraceLogger.php:96–109 |
| عدم تمييز الحسابات | رسالة فشل موحدة (لا تعداد للمستخدمين عبر الواجهة) | AuthController.php:61 |
| صفحات خطأ مخصصة | 403/404 موثقان | ErrorController.php |

---

## 7. نقاط القوة

| # | نقطة القوة | الدليل |
|---|---|---|
| 1 | **تفاصيل PDO آمنة بالكامل** — لا إدراج مباشر للمدخلات في أي استعلام للوحدة | Database.php + User.php |
| 2 | **تجزئة كلمات المرور** بمعيار PHP القياسي | User.php:243 |
| 3 | **تصميم CSRF مزدوج** (جلسة + جدول) مع فحص ثانٍ عند انتهاء صلاحية ساعة الجلسة وطابع `used` | Auth.php:161–183 |
| 4 | **إعادة توليد معرّف الجلسة** بعد `session_unset()` درءًا لتثبيت الجلسة | AuthController.php:29–30 |
| 5 | **RBAC موحّد** مع امتياز Admin كامل والتحقق في الهيدر وكل protected صفحة | Auth.php:84–107 |
| 6 | **تدقيق كامل** لكل محاولة دخول (نجاح/فشل) مع IP وعنوان المستخدم المحاول | Audit.php:18–44 |
| 7 | عدم كشف فاعلية الحسابات في رسالة الخطأ الموحدة | AuthController.php:61 |
| 8 | إشعار المشرفين فور تفعيل فترة سماح CSRF | CsrfGraceLogger.php:111–127 |
| 9 | فصل هوية الموظف عن حساب الوصول (ميزة تنظيمية سليمة) | schema:657 |

---

## 8. نقاط الضعف

| # | الضعف | الموضع | الأثر |
|---|---|---|---|
| 1 | **لا فحص لحالة الحساب عند الدخول** — حسابات `suspended/invited` ينجح دخولها | AuthController.php:21–23 (لا شرط على `status`) | تجاوز الإيقاف |
| 2 | **لا قفل محاولات/تنويعة تأخير/كابتشا** | AuthController.php:16–65 | فرض كلمة المرور (Brute force) |
| 3 | **POST /login معفى من تحقق CSRF** والنموذج بلا `_token` | Auth.php:213, login.php:25 | Login-CSRF (تزوير دخول ضحية) |
| 4 | **خروج عبر GET** + لا تدوير لتوكن CSRF + لا مسح كوكي `PHPSESSID` | routes/web.php:24, header.php:452, AuthController.php:67–72 | Logout-CSRF/جلسة معلّقة |
| 5 | **جلسة غير محصّنة**: `session_start()` بلا `session_name`/`cookie_params`؛ `performance.php` (الذي يضبط `gc_maxlifetime`) **غير محمّل**؛ لا مهلة انتهاء خامل؛ لا `httponly`/`samesite` صريحة | public/index.php:9, config/performance.php:16–17 | سرقة/تسريب جلسة على المدى البعيد |
| 6 | **كشف معلومات في الإنتاج** (عولج بند 6): كان `DEBUG_MODE=true` + `display_errors=1` + طباعة المسار والـ Trace الكامل عند الاستثناء | config/config.php, public/index.php:43–52 | تسريب داخلي للزوار — أصبح يُسجَّل في `storage/logs/php-error.log` بلا عرض |
| 7 | **حارس مكسور** في `Admin\UserController` (`forbidden()` بلا `exit`) | 13_Security.md §2أ | استمرار تنفيذ دوال الإدارة |
| 8 | **صلاحيات جلسة مجمّدة**: `user_roles/user_permissions` تُخزَّن وقت الدخول ولا تنعش عند تعديل أدوار المستخدم | AuthController.php:36–37, Auth.php:35–92 | صلاحية قديمة حتى إعادة الدخول |
| 9 | **`csrf_tokens` بلا تنظيف** للتوكنات المنتهية/المستخدمة | Schema:237, Auth.php:142 | نمو الجدول |
| 10 | **استعادة كلمة المرور غير منفذة** رغم الجدول (لا مسار/عرض فارغ/رابط `#`) + `password_resets` بلا `expires_at`/`used` | routes/web.php (لا يذكرها), forgot-password.php (0 بايت) | انغلاق المستخدم |
| 11 | **«تذكرني» واجهة ميتة** — checkbox بلا `name` وبدون حساب كوكي/توكن | login.php:42 | خداع مستخدمي UI |
| 12 | **ترميز صريح لمعرّف دور Admin في إشعارات المشرفين** — مرجع تاريخي؛ الكود الفعلي يستخدم بحثًا ديناميكيًا عبر roles.name = 'Admin' AND is_system_role = 1: كان `ur.role_id = 1` مضمّنًا | CsrfGraceLogger.php:119 | انهيار الافتراض عند تغيير الدور — أصبح بحثًا ديناميكيًا `roles.name='Admin' AND is_system_role=1` مع كاش وFallback |
| 13 | **لا إعادة مصادقة** للإجراءات الحساسة (تغيير أدوار/صلاحيات/نسخ) | Admin\UserController + roles | طلب مخادع/جلسة متخفية |
| 14 | **تعليقات محطّمة الترميز** في `public/index.php` و`.htaccess` (أثر مراجعة فقط) | index.php:2–5, .htaccess:2 | لا يؤثر وظيفيًا |

---

## 9. الفجوات (جدول)

| المعرّف | الفجوة | المرجع | الأثر المحتمل | الأولوية |
|---|---|---|---|---|
| G1 | لا تحقق من حالة الحساب عند الدخول | §8-1 | دخول الحسابات الموقوفة | حرجة |
| G2 | لا تخفيف لهجمات فرض كلمة المرور | §8-2 | اختراق بفيد المدى | حرجة |
| G3 | Login-CSRF غير محمي (POST معفى بلا توكن) | §8-3 | تسجيل دخول تزويري للضحية | عالية |
| G4 | خروج غير آمن (GET، لا مسح كوكي/تدوير CSRF) | §8-4 | Logout-CSRF، جلسات متبقية | متوسطة |
| G5 | غياب تحصين الجلسات ومهلة انتهاء خامل | §8-5 | تسريب/سرقة جلسة | عالية |
| G6 | وضع تصحيح مفتوح في الإنتاج | §8-6 | تسريب معلومات | عالية |
| G7 | حارس إدارة المستخدمين مكسور (بلا exit) | §8-7 | وصول غير مصرح | حرجة |
| G8 | صلاحيات جلسة لا تنعش عند تعديل الأدوار | §8-8 | امتياز قديم | متوسطة |
| G9 | تراكم توكنات CSRF بلا تنظيف | §8-9 | نمو الجدول/أداء | منخفضة |
| G10 | استعادة كلمة المرور غير منفذة + جدول ناقص | §8-10 | انغلاق الحسابات | عالية |
| G11 | «تذكرني» ميتة بلا تنفيذ | §8-11 | واجهة مضللة | منخفضة |
| G12 | افتراض صريح لدور المشرف `id=1` | §8-12 | رسائل خاطئة عند إعادة هيكلة الأدوار | منخفضة |
| G13 | لا إعادة مصادقة للأعمال الحساسة | §8-13 | أعمال من جلسة مخترقة | متوسطة |

---

## 10. الأسئلة المفتوحة

1. ~~هل توجد سياسة قوة/دورة لكلمات المرور (minimum length, expiry, history) مطلوب توثيقها؟~~ — **أُجيب (بند 11):** اعتُمدت سياسة موحّدة في `Auth::validatePasswordPolicy()`: الطول الأدنى **8** أحرف + تنوع **3 من 4** (حرف كبير/حرف صغير/رقم/رمز خاص) + رفض آخر **3** كلمات عبر `password_history` + قائمة أعلى 100 كلمة شائعة + **بلا انتهاء صلاحية تلقائي** (لا دورة استبدال إجبارية). تُفرَض عند إنشاء/تعديل/إعادة تعيين المستخدم (Admin) وعبر `User::updatePassword`.
2. هل يتوافر حساب بريد/ـ SMTP لتفعيل استعادة كلمة المرور، أم نكتفي بإعادة تعيين يدوي من لوحة الإدارة؟
3. هل يبقى دور `Admin` برقم `id=1` ثابتًا، أم نعتمد بحثًا بالاسم في الإشعارات؟
4. ما الحد الأقصى المنشود لمحاولات الدخول الفاشلة قبل القفل (نافذة زمنية/مدة القفل)؟
5. ما المدة المطلوبة لمهلة انتهاء الجلسة الخاملة (idle timeout)؟
6. هل يُفترض إلزام HTTPS على الاستضافة النهائية (يشمل `cookie_secure` و`APP_URL https`).
7. ماذا تفترض الجهة المختصة لسلوك حسابات الحالة `invited` عند الدخول (تفعيل إلزامي؟)؟
8. هل وجود نظام إشعارات (`notifications`) يُستخدم حاليًا في واجهة مقروءة، أم مجرد مخزن؟
9. هل توجد أي نية مستقبلية لمصادقة مزدوجة (2FA/OTP)؟ (خارج النطاق الحالي A1، يُفتح كمعلومة)

---

## 11. التوصيات

| الأولوية | التوصية | التفصيل |
|---|---|---|
| **P1** | إغلاق وضع التصحيح في أي استضافة إنتاج (نُفِّذ بند 6) | `DEBUG_MODE=false` و`display_errors=0` مع تسجيل الأخطاء في ملف (`log_errors=1` → `storage/logs/php-error.log`) |
| **P1** | فرض التحقق من `users.status='active'` داخل الدخول | في `AuthController::login` أو `findByUsernameOrEmail`؛ رفض `suspended/invited` مع سجل تدقيق |
| **P1** | إصلاح حارس `Admin\UserController` | إضافة `exit()` أو استثناء بعد `forbidden()` |
| **P1** | تخفيف فرض كلمة المرور | قفل بعد N محاولة/نافذة/تنويعة تأخير/كابتشا + تسجيل في `audit_logs` |
| **P1** | حماية Login-CSRF | إنشاء توكن CSRF لصفحات ما قبل الدخول (تخزين مؤقت) أو اعتماد SameSite=Strict |
| **P2** | تحصين الجلسات (نُفِّذ بند 5 في `config/config.php` وحُذف `performance.php` بند 6) | ضبط مباشر في `config.php`: `gc_maxlifetime=1800`، `cookie_httponly`، `cookie_samesite=Strict`، `cookie_secure` (HTTPS)، و`session_name('EVALSESSID')` |
| **P2** | خروج آمن | تحويل `/logout` إلى POST/نموذج + `setcookie(PHPSESSID, '', time()-...)+ تالف التوكن + مسح بيانات الجلسة |
| **P2** | تنفيذ أو إزالة استعادة كلمة المرور | إما بناء التدفق الكامل (جدول + مسار + بريد/إعادة تعيين) أو إزالة الواجهة الميتة وربط `#` بإحداث جهة الاتصال |
| **P2** | انعاش الصلاحيات | جلب `user_roles/user_permissions` في كل طلب، أو إبطال الجلسات عند تغيير الدور، أو تخزين توقيع (signature) يقارن به |
| **P2** | سياسة قوة كلمات المرور (نُفِّذ بند 11) | **المعتمدة:** طول ≥8 + تنوع 3/4 + رفض آخر 3 (`password_history`) + قائمة أعلى 100 شائعة + بلا دورة انتهاء. التنفيذ: `Auth::validatePasswordPolicy()` موحّد + `User::guardPasswordChange/updatePassword` + preflight في `UserController::store/update` + مولد `generateStrongPassword` لإعادة التعيين. **خارطة الترقية المستقبلية:** قائمة **NIST Breached Passwords** عند توفرها ثم **MFA/2FA** — خارج نطاق A1 الحالي، تُدرَج في **CD-005** |
| **P2** | إعادة مصادقة للأعمال الحساسة | طلب كلمة المرور ثانيةً لتغيير الأدوار/الصلاحيات/تنزيل النسخ |
| **P3** | تنظيف `csrf_tokens` | حذف دوري للتوكنات `used=1` أو منتهية الصلاحية (cron) |
| **P3** | ~~استبدال معرّف دور Admin الثابت~~ (نُفّذ بند 14) | بحث ديناميكي `roles.name='Admin' AND is_system_role=1` + كاش + Fallback آمن — طُبّق في `Auth::notifyAdmins` و`CsrfGraceLogger::notifyAdmins` |
| **P3** | البيئة النهائية | HTTPS إلزامي + نقل `config/` و`backups/` والفروعات خارج جذر الويب (يردد 13_Security.md §3) |

---

## ملحق — مراجع تحقق سريعة

| المرجع | الاستخدام |
|---|---|
| `app/Controllers/AuthController.php:16–72` | تدفق الدخول/الفشل/الخروج |
| `app/Core/Auth.php:117–238` | CSRF كامل |
| `app/Models/User.php:14–54, 150–181, 213` | استعلامات المصادقة والأدوار |
| `app/Core/CsrfGraceLogger.php:17–127` | فترة السماح والإشعارات |
| `public/index.php:9, 37, 44–49` | بدء الجلسة + فحص POST + حواجز الأخطاء |
| `routes/web.php:20–25, 309` | مسارات A1 |
| `app/Views/auth/login.php` | شاشة الدخول |
| `CD-001_delivery/appendices/db_live_schema.sql` | الجداول (users:652, csrf_tokens:237, password_resets:480, audit_logs:54, notifications:464, roles:561) |
| `CD-001_delivery/13_Security.md` | النتائج الأمنية الموحدة CD-001 |

---

**نهاية الوثيقة — التوثيق التفصيلي للوحدة A1 (CD-003)**