# سجل التغييرات

## 2026-09-15 — CD-004 بند 5: تحصين الجلسة
- `config/config.php`: كتلة إعدادات جلسة موحّدة قبل `session_start()` — `session_name('EVALSESSID')`، `gc_maxlifetime=1800`، `cookie_httponly=1`، `cookie_samesite=Strict`، `use_strict_mode=1`، `use_only_cookies=1`، `cookie_lifetime=0`.
- `public/index.php`: تحميل `config/config.php` قبل `session_start()` (كان بعده فيُبطل الإعدادات)؛ **تنبيه**: إعادة تسجيل دخول جميع المستخدمين (اسم جلسة جديد).
- تنظيفات لازمة: إزالة السطر الفارغ الفاتح في `config/config.php` (منع إخراجًا مبكرًا)، وتحويل `public/index.php` من CP-1256 إلى UTF-8 (تحويل معكوس 1:1، نسخة أصلية محفوظة).
- إثبات: `php -l` نظيف + smoke (EVALSESSID/1800/Strict فعّالة) + `AuthTest` 20/20.

## 2026-09-15 — CD-004 المرحلة 0: ترحيل قاعدة بيانات A1
- `database/migrations/2026_09_15_A1_authentication.sql` — إنشاء `login_attempts` (قفل المحاولات) و`password_history` (FK → users) + إضافة `users.must_change_password` و`users.permissions_version` + إزالة `password_resets` (متحقق: 0 صفوف/لا FK/لا مراجع كود).
- اعتماد خطة `CD-004_Execution_Plan.md` (قرار كبير المستشارين 2026-09-15 مع 5 ملاحظات إلزامية)؛ Dry Run لخطة التراجع قبل المرحلة 0 موثقًا.
- نسخ احتياطي قبل الترحيل: `storage/backups/CD-004/2026-09-15/` (mysqldump 884KB) + `_emergency/rollback/CD-004/2026-09-15/` (configs + forgot-password).
- انحدار خفيف بعد الترحيل: `AuthTest` 20/20 نجاح؛ فشلان سابقان خارج النطاق (`DatabaseTest::testRowCount`, `HelpersTest::testConvertToHijriValidDate`) سُجّلا في `CD-004_OUT_OF_SCOPE.md`.

## 2026-09-15 — CD-003: توثيق الوحدة A1 (المصادقة والدخول والجلسات)
- `CD-001_delivery/A1_Authentication_Unit_Documentation.md` + `.pdf` — دراسة قراءة فقط (11 قسمًا) مع مراجع ملف:سطر وجداول قاعدة البيانات.
- خلاصة النتائج: لا قفل محاولات، لا فحص لحالة الحساب عند الدخول، POST /login معفى من CSRF، خروج عبر GET، جلسة غير محصّنة (`config/performance.php` غير محمّل)، حارس `Admin\UserController` مكسور.
- إعلان: لقطات الشاشات غير متوفرة (MySQL متوقف لاستعادة حالة الاستضافة الأصلية).

## 2026-09-02 — حقول المقيّم الحرة وفصل الأدوار
- `evaluations` — `evaluator_employee_id NULLABLE` + `evaluator_name/title VARCHAR(255) NULL` — `created_by_user_id` هو المستورد — تعبئة رجعية من `employees` — `docs/MONTHLY_PRACTICAL_TEMPLATE.md` محدث
- `EvaluationExcelService` — `buildTemplate` لا يملأ `Q/R` تلقائياً (حقلان حران) — `validateSingleRow` قاعدة `evaluator_name أو evaluator_title` أحدهما إلزامي + فحص `^[=+@-]` وطول 255 — `parseFlexibleDate` يقبل `DD-MM-YYYY` — `commitBatch` يحفظ `evaluator_name/title` لكل صف ويحاول مطابقة موظف داخلي وإلا `NULL`
- `EvaluationController::store` — يدعم `is_external_evaluator` مع حقلين حرّين — `Evaluation::create` محدث — `show/print/fill` و `getFullEvaluationData` و `getEvaluationsByEmployeeForYear` تستخدم `COALESCE(evaluator_name, emp.full_name)`
- `create.php` + `evaluation-creator.js` — checkbox مقيّم خارجي مع إظهار/إخفاء الحقلين والتحقق
- `excel_import` — فلترة الأقسام ديناميكية `__lookup` و `max_rows` مرن (سابقا)

## 2026-09-01 — مولد Excel الديناميكي المرن + فلترة الأقسام + مرونة التاريخ
- `buildTemplate` مع `__lookup` و `INDIRECT("Dept_"&S6)` — `maxRows` مرن 100/1000 — `parseFlexibleDate` — `DataValidation` تاريخ غير معيق

## 2026-09-01 — مولد Excel الديناميكي (100 موظف) + قالب التقرير الشهري
- انشاء قالب `id=2` التقرير الشهري — 3 معايير 40/30/30 — 9 اقسام تقدير
## 2026-09-02 � ��� ������ ������� ������
- evaluations_by_year.php � ����� ���� �� 4 KPIs (�����/����/���/����) � grid 3 ����� �� ���� ���� � progress � ����� ����� PHP ����� numeric � clamp 0-100 � ������ navy/gold ������� �� ������ � Evaluation.php:getComparisonStatsForYear ���� ���� status completed
## 2026-09-02 � ����� �������� ������ ��� �������
- evaluations_by_year.php � ������� ����� width:min(96%,1400px) + padding:clamp � ������� uto-fit minmax(240px/340px) � ������ clamp � ����� �� 100% ��� 1366/1920 � 90%/125% zoom � ������� ������� �����
