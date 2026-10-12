# سجل التغييرات — حزمة CD-001 / توثيق الوحدات

## 2026-10-12 — CD-007 / OOS-11: كشف U+FFFD + BOM في بوابة الترميز + allowlist pChart

- **القرار المعتمد:** إصلاح BOM في التسليم + إعفاء pChart (طرف ثالث لا يُعدّل) — **مع شرط إضافي:** التحقق من خلو ملفات pChart التنفيذية `.php` من BOM؛ الـallowlist للملفات غير التنفيذية فقط.
- **قياس «قبل» — بوابة زائفة النجاح:** الأداة القديمة أعطت `exit=0` على مستندَي تسليم يحملان BOM (`EF BB BF`)، و`exit=0` على ملف U+FFFD — أي أنها لم تكن تكشف BOM ولا U+FFFD.
- **اكتشاف BOM مملوك (تلف حقيقي):** `CD-006_Phase2_Item7_Report.md` (12,977→12,974 بايت) و`CD-006_Phase2_Request.md` (6,770→6,767 بايت) كانا يحملان BOM منذ التزامهما. أُزيل بـ`ReadAllText` + `WriteAllText(UTF8Encoding($false))` (‎-3 بايت/ملف). مسح كل مستودع التسليم = **0 BOM** بعد الإصلاح.
- **جرد pChart (217 ملفًا / 29,739 سطرًا):** 15 ملفًا بترميز قديم (CP1252) يظهر U+FFFD عند فكّها قسرًا (منها 14 `.php` + `buildAll.cmd`) · 2 BOM في ملفات **غير تنفيذية** (`change.log` · `readme.txt`) · **BOM في `.php` التنفيذية = 0** (الشرط الإضافي متحقّق).
- **تصحيح فهم:** «14 سطر U+FFFD» ليست محارف U+FFFD حرفية بل ملفات بترميز قديم — فالإعفاء يشمل صلاحية UTF-8 لا مدى U+FFFD فقط.
- **الإصلاح في `scripts/check-encoding.php`:** إضافة `\x{FFFD}` · فحص BOM (UTF-8/UTF-16 LE/UTF-16 BE) على كل ملف · allowlist pChart (كل الامتدادات للمجموعات؛ وغير التنفيذية فقط لـBOM) · توسيع المجلدات تكراريًا.
- **قياس «بعد»:** التسليم **35/6807/0** `exit=0` · pChart **217/29739/0** `exit=0` · سالب BOM UTF-8/UTF-16 `exit=1` · سالب U+FFFD `exit=1` · **93/93** اختبار.
- **التوثيق:** `CD-007_OOS_Resolution.md` قسم OOS-11 + سطر الإغلاق · `CD-006_IMPLEMENTATION.md` **§2.2** (BOM في البوابة) و**§2.11** (نجاح البوابة الزائف · تمييز pChart التنفيذي) · `CHANGELOG.md` (تسليم + جذر).
- **نسخة الرجوع:** `_emergency/rollback/CD-007/2026-10-12/OOS-11/` — `check-encoding.pre-item11.php` · `install-hooks.pre-item11.php` · `CD-006_Phase2_Item7_Report.pre-item11.md` · `CD-006_Phase2_Request.pre-item11.md`.
- **الالتزامات:** الأداة `d2e5f8a` (`fix(OOS-11)`) · التوثيق `docs(OOS-11)`.
- **التالي:** `OOS-12` — توسيع نطاق الفاحص إلى `app/**/*.php` (426 ملفًا / 64,639 سطرًا) مع إبقاء allowlist pChart.

## 2026-10-12 — CD-007 / OOS-10: محارف صينية في `app/Views/admin-reports/create.php`

- **القياس:** `Select-String` عن `[\u4E00-\u9FFF]` في الملف = **سطر واحد (28)** → **0** بعد الإصلاح. المحرفان `U+52B2` و`U+6001` في placeholder حقل `report_title` — موجودان منذ أول التزام للملف (`6cfa863`، baseline CD-006) أي خلل زمن التأليف لا انحدار.
- **التشخيص:** نص عرض (placeholder) لا تعليق ولا قيمة بيانات. البديل العربي الصحيح «الأداء» (العبارة السائدة: `ReportPDF.php:11` · `reports/builder.php:21` · `ReportsController.php:51`).
- **الإصلاح:** `placeholder="مثال: تقرير الأداء الإداري"` — سطر واحد (`تغيير 1 +1/−1`).
- **الفحص الشامل `app/` خارج `pChart/`:** كل الملفات النصية بأي امتداد → **0 محارف CJK/Kana/Hangul** — قائمة الجرد لـOOS-11 **فارغة**.
- **الفحص الحي:** عرض صفحة `admin/reports/create` عبر `AdminReportController@create` بجلسة Admin كاملة — تُرسم (لا 403) 61,633 محرفًا، النص العربي ظاهر، صفر بايتات CJK. **درس محقن:** أول محاولة أعطت 403 لجلسة ناقصة `user_roles` — قياس خاطئ لا يُعتمَد.
- **الاختبارات:** 93/93 · فشل 0 · أخطاء 0 · بلا ترحيل DB.
- **التوثيق:** `CD-007_OOS_Resolution.md` قسم OOS-10 + سطر الإغلاق · `CD-006_IMPLEMENTATION.md` **§2.11** (جرد CJK الحتمي + الفحص الحي بجلسة كاملة + نقل فواصل النطاق صراحة) · `CHANGELOG.md` (تسليم + جذر).
- **نسخة الرجوع:** `_emergency/rollback/CD-007/2026-10-12/OOS-10/create.pre-item10.php`.
- **التالي:** `OOS-11` — بوابة BOM الإلزامية على كل ملف + pChart (14 سطر allowlist).

## 2026-10-12 — CD-007 / OOS-13: تدقيق فشل `updateRole`

- **القياس:** `USER_ROLE_UPDATE_FAILED` بعد فشل `updateRole` = **0 → 1**. تفاصيل الفحص: `{"role_id":999,"reason":"invalid_role_or_transaction_failed"}` · الدور لم يُسنَد · Flash `danger` واضحة.
- **ضبط موجب:** `USER_ROLE_UPDATE` **7 → 8** عند النجاح، بلا `_FAILED`، والدور أُسند فعلًا.
- **الإصلاح:** `UserController::updateRole` فقط — `try/catch` حول الاستدعاء؛ عند `false` يسجّل `USER_ROLE_UPDATE_FAILED` (شكل موقّعي) بـ`role_id`+`reason`، وعند استثناء بـ`error` ثم يعيد الإلقاء. **لا تعديل على `User::updateRole`.**
- **الاختبارات:** 93/93 (جديد: `testUpdateRoleFailureAuditLog` في `tests/cases/Controllers/UserControllerTest.php`، عملية فرعية لأن المتحكّم يخرج بـ`exit()`). بلا ترحيل DB.
- **التوثيق:** `CD-007_OOS_Resolution.md` قسم OOS-13 · `CD-006_OUT_OF_SCOPE.md` إغلاق · `CD-006_IMPLEMENTATION.md` **§§2.5-bis و2.8 و2.9** (الفحص المستقل في الكتابة · قاعدة `--result-file` واختبار الاسترجاع وتصحيح التسمية · اختبار ملف التراجع قبل الاعتماد) و**§2.10** (قواعد OOS-1 + درس OOS-13).
- **التالي:** المسار C — `OOS-10`.

## 2026-10-06 — CD-007 / OOS-9: إعادة ربط 9 صفوف `evaluations` يتيمة إلى `sysadmin`

- **القياس:** يتيمة **9 → 0** · `created_by=1` **38 → 47** (+9 بالضبط) · الإجمالي **50 ثابت** · مخالفة القيد **0**. الصفوف `4`–`12` بتاريخ `2026-08-24 03:29:48`; القيم القديمة `4,5,6→8` · `7→7` · `8,11→12` · `9→11` · `10,12→16`.
- **السبب الجذر:** `AuthTest` يحذف مستخدمين مع `SET FOREIGN_KEY_CHECKS=0` فتتجاوز القيد `eval_fk_creator` (نوع `RESTRICT`). **الترحيل:** صف واحد `UPDATE`، بلا كود، بلا `permissions_version`، بلا محفّزات.
- **Audit:** `EVALUATIONS_RELINKED_TO_SYSADMIN` — السجل **id=1018** بـ`count=9` ومعرّفات الصفوف وقيمها القديمة.
- **اكتشاف 1 — نسخة الاحتياطية الأولى تاملة و`?`:** أُنشئت بإعادة توجيه PowerShell فصار مخرج `mysqldump` UTF-16 و**123** علامة استفهام بدل العربية (**صفر** محارف عربية) ⇒ غير صالحة للاسترجاع. أُصلحت بـ`--result-file` (كتابة ثنائية بلا أنبوب): **977,591 بايت / 80,399 محرفًا عربية**، ومُختبَرة بالاسترجاع على قاعدة مؤقتة (41 جدولًا، 50 صفًا). **هذا هو فخ §2.2/§2.7 واقعًا في نسخة قاعدة بيانات.**
- **اكتشاف 2 — `rollback.sql` الأول يفشل بخطأ `1452`:** القيد `RESTRICT` يرفض إرجاع القيم إلى `7/8/11/12/16`. أُصلح بـ`SET FOREIGN_KEY_CHECKS = 0` حول التراجع، **واختُبر فعليًا**: يتيمة 9 · `created_by=1` = 38 · الإجمالي 50 · والقيم التسعة طابقت CSV واحدًا واحدًا.
- **تصحيح تسمية:** اللقطة الكاملة `db_after_fix.sql` لا `db_before.sql` (أُعيد إنشاؤها بعد الترحيل)، وكذلك `db_snapshot_after_oos9.sql` في مجلد `OOS-1`. **الرجوع المرجعي = `rollback.sql` + ملفّا CSV.**
- **الاختبارات:** 92/92 · فشل 0 · أخطاء 0 — **بلا تغيير كود**.
- **تحديث الملفات:** `CD-007_OOS_Resolution.md` (قسم OOS-9 كاملًا) · `CD-006_OUT_OF_SCOPE.md` (إغلاق OOS-9) · `CD-006_IMPLEMENTATION.md` (**§§2.6–2.8** الجديدة: قاعدة `amend` · أداة القياس أنظف من الذي تقيسه · المحفّزات والتوقيع الفعلي واختبار ملف التراجع).
- **التالي:** `OOS-13` — إثبات فشل `updateRole` وتسجيل `USER_ROLE_UPDATE_FAILED`.

## 2026-09-29 — CD-006: الإغلاق الرسمي — A2/CD-006 معتمدة 17/17
- **تسليم** `CD-006_Closure_Statement.md` (8 أقسام — على نموذج بيان إغلاق A1 `phase5/A1_Closure_Statement.md`): الختم الرسمي · النطاق والمراجع مع **ملاحظة تتبّع عدّ البنود** · سجل الالتزامات (مستودعان) · نتائج القبول والأدلة الحاسمة · التقييم النهائي بصيغة المستشار · تصريف القرارات · الإغلاق الرسمي · الخطوة التالية ونقطة التوقف.
- **قرار كبير المستشارين بحرفه:** «CD-006: معتمدة نهائيًا. 17/17. A2 مُغلقة رسميًا.» — وسُجِّل الرقم **17/17** بحرفه مع **ملاحظة تتبّع** (§2.1) توضّح أن الـ14 وحدة تنفيذ موثّقة هي: 1–6 ثم 7–10 ثم 11-a و11-b و12 و12-b؛ وأن الحزمة لا تحتوي تعريفًا مستقلًا لبنود 13–17 (وبند 13/14/15 الوارد في `CD-004_IMPLEMENTATION.md` ينتمي إلى CD-004). **لم تُنشأ خريطة افتراضية** للبنود 13–17 التزامًا بأمانة التوثيق.
- **قرارات مُصرَّح بهاالأخرى — مُثبَّتة في `CD-006_Closure_Statement.md` §6:**
  - **توسيع البند 12-b إلى `evaluation_import_batches` معتمد** («نفس فئة العطل، إصلاح متسق») ⇒ سُجِّل في `CD-006_Phase3_Report.md` §5.0 كـ**«توسيع مبرر للنطاق»** بدل «مُعلَن للمراجعة» (§7 مُشطوب).
  - `DatabaseTest::testRowCount`: «الخطأ في الاختبار لا في التطبيق» ⇒ **CD-007** (OOS-14) — التوقّع الخاطئ هو `rowCount()===3` على `SELECT COUNT(*)` بينما MySQL يُرجع صفوف النتيجة (1).
  - **الانحدار الشامل معتمد** («إثبات حاسم عبر rollback + إعادة تشغيل») ⇒ **صفر انحدار** مُثبت.
  - `OOS-8` **مُغلق** · حالة DB نظيفة · خطاف `pre-commit` يعمل.
  - `check-encoding` على `app/`: **ليس الآن** ⇒ ضمن OOS في CD-007 (OOS-12).
- **تحديث الملفات:** `CD-006_IMPLEMENTATION.md` (تصحيح جدول النطاق المتقادم + قسم «الإغلاق الرسمي») · `CD-006_Phase3_Report.md` (§5.0 + تشطيب §7) · `CD-006_OUT_OF_SCOPE.md` (**OOS-9…17** جديدة، وإعادة توجيه كل البنود إلى CD-007 + قسم الإغلاق والتصريف).
- **محصّلة البنود:** **14/14 وحدة تنفيذ PASS** — والعدد المعلن في الختم 17/17 بحكم المستشار (انظر ملاحظة التتبّع).
- **الانحدار الشامل:** `NotificationTest` 13/13 · `UserTest` 3/3 · `AuthTest` 58/59 · `DatabaseTest` 4/5 · `HelpersTest` 2/3 · `RouterTest` يُسقط المشغّل — **والإخفاقات الأربعة مُثبتة سابقةً** (رجوع إلى `792d6c9` وإعادة تشغيل ⇒ متطابقة حرفيًا).
- **DB النهائي:** `users=4` · `roles=4` · `user_roles=4` · يتام `user_roles=0` · `permissions=38` · `employees=27` · `audit_logs=299` صفًا (أقصى معرّف 939) · التاريخي `id<=726` = 246 صفًا سليمة.
- **XAMPP:** إيقاف رشيق **مُصرَّح به** («XAMPP: يمكن إيقافه الآن. A2 مُغلقة») — بعد التحقق من نظافة DB.
- **الخطوة التالية:** **CD-007** (دراسة A3 · معالجة OOS · `check-encoding` على `app/` ضمن OOS · `OOS-1`). **التوقف إلزامي حتى استلام CD-007 الرسمي.**

## 2026-09-29 — CD-006 المرحلة 3 / بند 11-a: توحيد رابط `/admin/roles` بـ`roles.manage`
- **تسليم** قسم «المرحلة 3» + «11-a» في `CD-006_IMPLEMENTATION.md`: تحليل العيب (الشرط الواحد كان يلفّ رابطَي المستخدمين والأدوار معًا)، التنفيذ بفكّ الالتفاف إلى كتلتين مستقلتين (`rolesDropdown`)، جدول معايير القبول 1 و2 و7، وإثبات `git stash` الحاسم.
- **تطبيق** `app/Views/layouts/header.php` ملف واحد ‎+13/−1.
- **إثبات Live** 3× HTTP 200: `users.view` فقط ⇒ لا يرى رابط الأدوار · `roles.manage` فقط ⇒ يراه · Admin ⇒ يرى الاثنين.
- **إثبات stash:** الكود القديم ⇒ `/admin/roles=False` لمستخدم `roles.manage`؛ الجديد ⇒ `True`.
- **نظافة:** حُذفت كل الـfixtures (دوران 72/73، مستخدمون 831/832/833) + حدث `USER_CLEANUP_TEST_DATA` ⇒ `users=30` وبقايا 0.
- **حدود مُلتزَمة:** لا تعديل `RoleController` · لا صلاحيات جديدة · لا `RouterTest` · لا صيني `admin-reports/create.php`.
- **نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-29/header.pre-item11.php` (SHA1 `8551BF0E18DECB12361B8113452E679D59DF4E75`).
- **تصحيح CP2 مسجَّل:** الـ206 محرف U+FFFD في `CHANGELOG.md` **جذر التطبيق** لا `CD-001_delivery/CHANGELOG.md` (الذي نظيف = 0) — والحجر الصحيح أن ملف الجذر **متتبَّع في git** وليس مستثنى (`.gitignore` لا يحوي `/*.md`)، فإصلاحه في البند 11-b سيكون **commit** لا تعديلًا محليًا.

## 2026-09-29 — CD-006 المرحلة 3 / بند 11-b: تنظيف بيانات الاختبار + إصلاح جذر تسرّب `AuthTest` + أداة فحص الترميز + إصلاح U+FFFD
- **تسليم** قسم «11-b» في `CD-006_IMPLEMENTATION.md` بخمسة أجزاء (أCleanup، بجذر التسرّب، جالأداة، دالمثبّت، هـU+FFFD) + جدول قياس التسرّب + جدول الإغلاق.
- **أ) Cleanup:** حُذفت 26 حسابًا متسربًا (كلها `cd004.%@test.local`، صفر `test_*`/`cd006.*`) داخل Transaction واحدة ⇒ `users=4`، `user_roles=4`، يتامى 0. بوابة `FOREIGN_KEY_CHECKS` أثبتت 0 مراجع `evaluations`. حدث `USER_CLEANUP_TEST_DATA` (827) يوثّق العملية، والسجل التاريخي (246 صفًا) سليم.
- **ب) جذر التسرّب — خطآن لا واحد (أهم اكتشاف في 11-b):**
  1. نقص التسجيل: `seededUsernames[]` في موضع واحد من 18 موضع بذر.
  2. **السبب الحقيقي: خطأ MySQL 1442** — الـ trigger `cd004_trg_user_roles_ad` ينفّذ `UPDATE users` عند كل حذف من `user_roles`، والتنظيف كان يستعلم `users` في الجملة نفسها (`IN (SELECT id FROM users …)`) ⇒ تعارض، و`catch` الصامت يوقف التنظيف **قبل** `DELETE FROM users`. (تصحيح تشخيص سابق: `login_attempts` موجودة، والعطل ليس نقص جدول.)
  3. موضعان آخران بلا تسجيل: `seedPolicyUser()` و`seedMustChangeUser()` (11 حسابًا/تشغيل، مثبت بالقياس).
  - **الإصلاح:** حلّ المعرّفات أولًا في استعلام مستقل ثم حذف بقائمة literals (بلا استعلام فرعي على `users`) + تسجيل المواضع الثلاثة + **حذف كلي لتجاوز `FOREIGN_KEY_CHECKS`**.
- **الإثبات الحاسم:** الكود القديم `users 4→17` (+13) · الكود الجديد `4→4→4` في 3 تشغيلات متتالية · يتامى `user_roles=0` · يتامى `evaluations=9` **بلا نمو** (لا صفوف يتيمة جديدة). إثبات `git stash` مؤكِّد. `AuthTest` = **58/59** والفشل الوحيد المتبقي **سابق** (`testAdminUserControllerGuardStopsNonAdmin`، بند 7 ⇒ CD-007).
- **اختبار انحدار جديد:** `testNoOrphanUserRolesAfterCleanup` (يبقى في الملف) — كشف الخطأين معًا.
- **ج) `scripts/check-encoding.php`:** بلا اعتماديات، نطاقه `CD-001_delivery/*.md` + `CHANGELOG.md` الجذري، يكشف CJK/Kana/Hangul/Cyrillic + صلاحية UTF-8 مع `file:line [الفئة]: U+XXXX` و`exit 0/1`. **النطاق الافتراضي 31 ملفًا/5025 سطرًا ⇒ تسرّب 0.** **اختبار سلبي** (ملف تجريبي بالمجموعات الأربع) كشف 4 تسرّبات و`exit 1` — لأن فاحصًا يقول «نظيف» دائمًا بلا قيمة. كشف مستقل لـ CD-007: `admin-reports/create.php` سطر 28 ⇒ `U+52B2 U+6001`.
- **د) `scripts/install-hooks.php`:** خطاف `pre-commit` في مستودع التسليم فقط، **بلا اعتماد على git CLI** (يحلّ الجذر من موقع السكربت؛ ويدعم `.git` مجلدًا أو ملفًا) ويحمل الجذر المطلق مثبَّتًا. **idempotent مُثبَت** (4 تشغيلات ⇒ كتلة واحدة وبصمة واحدة). غير مُتلِف مع خطاف أجنبي (يحفظه + `pre-commit.cd006.bak`). **إثبات حي:** تسرّب مقصود ⇒ `git commit` ممنوع (`exit 1`، `HEAD` لم يتغيّر)؛ النظيف يمرّ؛ `CD006_GUARD_DISABLED=1` تجاوز مقصود. `--status`/`--uninstall` (يحذف الملف إن لم يتبقَّ سوى `shebang`).
- **هـ) إصلاح U+FFFD (206 ⇒ 0):** **القياس الأول كان معطوبًا** (PowerShell + `Out-String` أعطى «0» وهو أثر ترميز الطرفية)؛ القياس الصحيح على **البايتات الخام** (`git cat-file blob` ثم عدّ `EF BF BD`) أثبت **206 في `HEAD` نفسها**،حتى في **النسخة الأساس `6cfa863`** ⇒ **لا نسخة نظيفة في أي commit، والنص الأصلي غير قابل للاسترجاع**. أُعيد بناء السطرين من المصدر الباقي `app/Views/employees/evaluations_by_year.php` (أسماء المؤشرات من `kpi-lbl`، وقيم التخطيط من الملف والشظايا الرقمية) مع **حاشية «إعادة بناء نصية»** تُعلن أن الصياغة من المصدر لا من الأصل — **لا اختراع نص**. النتيجة: `EF BF BD = 0`، بلا BOM، UTF-8 سليم، بلا تكرار.
- **مؤجَّل إلى CD-007:** محرفا CJK في `admin-reports/create.php:28` · 9 صفوف `evaluations` يتيمة (7/8/11/12/16) · `testAdminUserControllerGuardStopsNonAdmin` · `RouterTest` · فجوة Audit في `updateRole` · نقطة عمى الأداة (U+FFFD خارج المجموعة بحكم القرار).
- **نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-29/AuthTest.pre-item11.php` (SHA1 `2FF0746D71E3EDF2FD977006E4A06AAF162E5556`).

## 2026-09-29 — CD-006 المرحلة 3 / بند 12: حذف الدالة الميتة `User::delete()` / بند 12-b: بوابة منع حذف مستخدم مرتبط
- **12 — قياس قبل الحذف لا افتراض:** `User::delete($id)` نسخة حرفية من `deleteUser()`. مسح 14 استدعاء `->delete()` في المشروع كلها على نماذج أخرى (صفر على `User`)، وبحث `userModel->delete` / `this->user->delete` / `User::delete` أعاد **صفرًا**، و`app/Core/Model.php` **لا يعرّف `delete()`** ⇒ لا توارث ولا استيراد.
- **12 — التغيير:** حذف `User::delete($id)` فقط ‎**-11/+0** بلا سطر مضاف؛ والمُبقى `deleteUser($id)` لأنها الحيّة في `UserController::destroy`. الفحوص: `php -l` نظيف · `UserTest` 3/3 · `NotificationTest` 13/13 · `AuthTest` 58/59 · `HelpersTest` 2/3 · DB على خط الأساس.
- **فشل سابق مُثبت:** `HelpersTest::testConvertToHijriValidDate` فاشل **قبل وبعد** التغيير (مقارنة `git stash` على `User.php` بنتيجة متطابقة) ⇒ لا علاقة له بالحذف.
- **12-b — القياس الحاسم من `information_schema`:** القيود المؤدية إلى `users` ليست جدولين كما هو شائع بل **17 قيدًا**: `CASCADE` (5) تُنظَّف ذاتيًا · `SET NULL` (9) · **`RESTRICT` (2)** هما `evaluations.created_by_user_id` و`evaluation_import_batches.uploaded_by_user_id`.
- **تنبيه موثَّق:** `evaluations` ترتبط بـ `users` **فقط** عبر `created_by_user_id`؛ المُقيَّم نفسه `evaluator_employee_id` (موظف) مع لقطة نصية ⇒ العدّ على `created_by_user_id` هو الصحيح.
- **12-b — التنفيذ:** بوابة في `UserController::destroy()` بعد حماية «آخر مدير نشط» وقبل `deleteUser()`: `Audit::log('USER_DELETE_BLOCKED_REFERENCES', …)` + `Flash` + إعادة توجيه. **+48/-0** ملف واحد، بلا تعديل `User`/`Model` ولا ترحيل DB.
- **خارج نصّ البند (مُعلَن للمراجعة):** الحارس يغطي `evaluation_import_batches` أيضًا لأن قيدها `RESTRICT` أيضًا؛ الاكتفاء بـ `evaluations` لبقي مستخدم لديه دفعات استيراد يصل إلى خطأ قاعدة بيانات خام. القيدان من نفس فئة العطل والرسالة تذكرهما معًا بصيغة مفرد/جمع صحيحة.
- **تفاصيل مقيسة:** `EMULATE_PREPARES=false` ⇒ **placeholder منفصلان** (`:id1`/`:id2`) لأن PDO لا يقبل تكرار الاسم في جملة واحدة؛ و`FETCH_OBJ` ⇒ القراءة `->evals` لا `['evals']`.
- **12-b — إثبات stash الحاسم:** بدون البوابة ⇒ `POST=500` و**0 صف** تدقيق (وصل الطلب إلى قيد FK الخام) · مع البوابة ⇒ `POST=302` و**صف واحد** (منع نظيف).
- **12-b — إثبات Live (HTTP بجلسة وCSRF):** (أ) `id=2` (`kghamdi`، 3 تقييمات) ⇒ `302`، المستخدم باقٍ، صف تدقيق واحد، و**لا `SQLSTATE`/`1452`** في الصفحة · (ب) مستخدم مؤقت بلا مراجع ⇒ `302` وحُذف مع صف `USER_DELETE`. الدخول بمستخدم `Admin` **مؤقت** (لم يُمسّ `sysadmin`) وكل الـfixtures حُذفت ⇒ `users=4 user_roles=4 orphans=0`.
- **حدود مُلتزَمة:** لا زر جديد (زر التعطيل/التفعيل موجود في `admin/users/index.php`) · `eval_fk_creator` بقي `RESTRICT` و`created_by_user_id` بقي `NOT NULL` · لا صيني في `admin-reports/create.php`.
- **نسختا الرجوع:** `_emergency/rollback/CD-006/2026-09-29/User.pre-item12.php` (SHA1 `82D695E948BDEA201017336A0FB8EE118D114002`).

## 2026-09-29 — CD-006 المرحلة 3: تقرير CP3 — إغلاق المرحلة (البنود 11-a و11-b و12 و12-b)
- **تسليم** `CD-006_Phase3_Report.md` + `CD-006_Phase3_Report.pdf` (7 صفحات، mPDF RTL بخط `DejaVuSans` مع اختيار mPDF التلقائي لخطّه العربي `XBRiyaz`، وكل الخطوط الست مضمَّنة `Type0`/`CIDFontType2`) — بنفس نمط تقرير CP2.
- **تقرير المرحلة 3 مكتمل (4/4)** وحالة CD-006 النهائية **مكتملة**: 11-a و11-b و12 و12-b مُنفَّذة ومُغلقة.
- **انحدار شامل (بعد 12-b):** `NotificationTest` 13/13 · `UserTest` 3/3 · `AuthTest` 58/59 · `DatabaseTest` 4/5 · `HelpersTest` 2/3 · `RouterTest` يُسقط المشغّل بـ`View 'errors/404' does not exist.`
- **إثبات ما قبل الوجود (حاسم):** رُجعت ملفات المصدر الثلاثة المعدَّلة في المرحلة إلى ما قبلها (الالتزام `792d6c9`، ما قبل 11-a) وأُعيدت المجموعات الأربع ⇒ **الإخفاقات متطابقة حرفيًا** ⇒ **صفر انحدار ناتج عن المرحلة 3**.
- **تشخيص جديد مُوثَّق (كان Listed مسبقًا في CP2 كـ«فشل سابق»):** `DatabaseTest::testRowCount` يتحقق من توقّع خاطئ (`rowCount()===3` على `SELECT COUNT(*)`، و`rowCount()` في MySQL يُرجع عدد **صفوف النتيجة** = 1). ⇒ **تصحيح اختبار لا تغيير سلوك**؛ مُحوَّل لـCD-007 ولم يُعدَّل هنا.
- **`OOS-8` مُغلق** (كان محوَّلًا إلى 12-b): الحارس المضاف يغلق استثناء الحذف الخام؛ القيدان المانعان هما `evaluations.created_by_user_id` و`evaluation_import_batches.uploaded_by_user_id` ضمن 17 قيدًا.
- **حالة DB نهائية مُتحقَّق منها:** `users=4` (1،2،3،6) · `roles=4` · `user_roles=4` · يتام `user_roles=0` · يتام `evaluations=9` (مؤجَّل) · `audit_logs=299` (أقصى معرّف 939) والتاريخي `id<=726` (246 صفًا) سليم · **صفر حساب اختبار متبقٍ**.
- **فجوات معلَنة للمراجعة (لا تُنفَّذ):** توسيع نطاق 12-b ليشمل `evaluation_import_batches` (خارج نصّ البند لكن داخل نفس فئة العطل) · فجوة Audit في `updateRole` · `RouterTest` · محرفا CJK في `admin-reports/create.php:28` · 9 صفوف evaluations يتيمة · نقطة عمى U+FFFD في الأداة · `OOS-1` و`OOS-2..7`.
- **حارس التسليم:** **متوقّف إلزاميًا** — CD-006 مكتملة، ولا بند بعدها دون اعتماد جديد.

## 2026-09-28 — CD-006: نقطة تفتيش CP2 — تقرير المرحلة 2 (البنود 7–10)
- **تسليم** `CD-006_Phase2_Report.md` + `CD-006_Phase2_Report.pdf` (5 صفحات، mPDF RTL بخط DejaVuSans) — تقرير شامل للمرحلة 2 يغطي البنود **7، 8، 9، 10** بنمط تقرير CP1، مع: سجل Git للبنود الأربعة، حالة DB النهائية، الفحوصات الإضافية، الفجوات المُحوَّلة، والتوصيات.
- **أُضيف** قسم `إغلاق المرحلة 2 (البنود 7–10) — إلزامي (CP2)` إلى `CD-006_IMPLEMENTATION.md`.
- **البنود المنجزة:** 7 `f44d525` (+Step A `f4ae1f9`/`9a69680`) · 8 `bcb12a7`/`93294f0`/`1e9de66` · 9 `1a7f650`/`a3dbc07`/`c4096fc` · 10 `792d6c9`/`dac9e06`/`bb583f2`.
- **المكتشفات المُبلَّغة في التقرير (§6):** `AuthTest` يتسرّب ~14 حساب اختبار في كل تشغيل (أولوية البند 11) · `RouterTest` يُسقط مشغّل الاختبارات (`View 'errors/404' does not exist.`) · 3 اختبارات وحدة فاشلة **سابقة** موثّقة · تعليقات `Employee.php` تالفة الترميز · أربعة أسطر U+FFFD **سابقة** في `CHANGELOG.md` (مدخل CD-003).
- **فجوة مُحوَّلة (§7):** فشل تغيير الدور بلا Audit (البند 9) ⇒ مراجعة CD-007+ · `/admin/roles` ⇒ البند 11 · OOS-8 ⇒ 12-b · OOS-1 ⇒ CD-007.
- **نقطة التفITCH:** **التوقف إلزامي — لا بند 11 ولا 12-b ولا أي بند لاحق قبل اعتماد المستشار.** وXAMPP (`httpd`+`mysqld`) أُبقِي يعملًا بطلب المستخدم.

## 2026-09-28 — CD-006 المرحلة 2 / بند 10: بوابات التحقق المرجعي قبل إنشاء المستخدم
- **نطاق التنفيذ:** `app/Controllers/Admin/UserController.php` دالة `store()` فقط (‎+42/−0، إضافة فقط). **بلا ترحيل DB** · بلا تعديل `User`/`Role`/`Employee`/`Audit`/`Database`.
- **السلوك:** ثلاث بوابات قبل `createUser` — دور غير موجود ⇒ «الدور المحدد غير موجود.» · موظف غير موجود ⇒ «الموظف المحدد غير موجود.» · موظف مرتبط بحساب آخر ⇒ «هذا الموظف مرتبط بحساب مستخدم آخر.»؛ كل واحدة تُسجّل حدث تدقيق مخصّصًا (`USER_CREATE_BLOCKED_INVALID_ROLE` / `_INVALID_EMPLOYEE` / `_EMPLOYEE_TAKEN`) بـ`entity_id=null` ومنفِّذ هو `user_id` الفعلي. و`role_id` الفارغ/0 ⇒ رسالة الدور غير الموجود.
- **الإثبات:** 4 سيناريوهات Live (‎4× HTTP 200‎): ثلاث حالات مرفوضة **بلا** إنشاء أي مستخدم مع الرسالة المحدّدة + صف التدقيق الخاص، وحالة سليمة واحدة أنشأت المستخدم بدوره وموظفه. **وتشغيل موازٍ على الكود قبل البوابات** أثبت أن القوائم كانت تمنع الصفوف السيئة أصلًا لكن تُسجّل **0 صف تدقيق** وتعرض رسالة **مضلِّلة** — فقيمة البند هي دقة الرسالة + قابلية تتبّع المحاولة.
- **التنظيف والحالة:** حُذف حسابا الاختبار ⇒ `a2i10.%` = 0؛ وأُبقيت صفوف التدقيق `811`–`815` كإثبات. DB: `users=30 roles=4 user_roles=20 permissions=38 employees=27 audit_logs=289` (‎=284‎+5) والتاريخ `id<=726` = 246 سليمة. `php -l` نظيف · `UserTest` 3/3.
- **دروس مُبلَّغة:** توكن CSRF يُجلب قبل كل POST (توكنات `csrf_tokens` لمرة واحدة)؛ و`RouterTest` ما زال يُسقط مشغّل الاختبارات بخطأ `View 'errors/404' does not exist.` (سابق للبند 10).

## 2026-09-28 — CD-006 المرحلة 2 / بند 9: ذرّية استبدال الأدوار في `User::updateRole`
- **نطاق التنفيذ:** `app/Models/User.php` (دالة `updateRole` فقط) + **ملف اختبار جديد** `tests/cases/Models/UserTest.php`. **بلا ترحيل DB** · بلا تعديل `user_roles` ولا `createUser` ولا `Database.php` ولا `Audit.php`.
- **الأثر:** `DELETE`+`INSERT` صارا داخل `Transaction` واحدة على نفس اتصال الـsingleton؛ عند فشل `INSERT` (قيد `user_roles_ibfk_2`) يتراجع عن `DELETE` فيحتفظ المستخدم بدوره القديم، ثم يميّز السبب: دور غير موجود ⇒ `false` بلا استثناء، وخطأ آخر ⇒ `throw` كما كان.
- **الإثبات:** 3/3 اختبار وحدة نجح (أهمّها `testUpdateRoleRollsBackOnInvalidRole`). **وشغل حاسم:** بإلغاء الإصلاح مؤقتًا (`git stash`) يفشل الاختبار بخطأ `SQLSTATE[23000] … 1452` — أي أن الكود القديم يترك المستخدم بلا دور، وهو الخطر المُعالَج. لا انحدار (نتيجة المجموعة الكاملة مطابقة لخط الأساس). `php -l` نظيف · DB بعد الاختبارات: `users=30`, `roles=4`, `user_roles=20`, `permissions=38`, `audit_logs=284` بلا تغيير.
- **اكتشاف مُوثَّق للـCP2:** `AuthTest` يُنشئ ~14 حساب `cd004.*@test.local` في كل تشغيل ولا ينظّفها (26 متراكمًا سابقًا + 52 من تشغيلاتي حُذفت فورًا لاستعادة خط الأساس) — يؤكد أولوية تنظيف البند 11 (قرار المستشار Q3). و`RouterTest` يُسقط المشغّل بـ`View 'errors/404' does not exist.` — خطأ سابق قائم.
- **فجوة مُوثَّقة للـCP2:** فشل تغيير الدور لا يُسجَّل في `audit_logs` (بلا Audit بنص البند 9) ⇒ مراجعة في CD-007+.
- **نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-28/user-model.pre-item9.php`.

## 2026-09-28 — CD-006 المرحلة 2 / بند 8: تدقيق القيم القديمة/الجديدة في سجل التدقيق
- **نطاق التنفيذ:** `app/Controllers/Admin/UserController.php` (سطران) + `app/Controllers/Admin/RoleController.php` (سطران) — **`app/Core/Audit.php` بلا تعديل (0 سطر)** و**بلا ترحيل DB** و**بلا مساس بالسجلات التاريخية**.
- **الأثر:** `USER_ROLE_UPDATE` صار يحمل `old.role_id` (كان `new_role_id` فقط) · `USER_SUSPENDED`/`USER_ACTIVATED` صارا يحملان `old.status`/`new.status` (كانا بلا `details`) · `PERMISSION_ADDED`/`PERMISSION_REMOVED` انتقلا من booleans إلى `old/new` كائنَي `{role_id, permission_id}` مع إبقاء `permission_name` أعلى المستوى · `ROLE_UPDATE` صار يحمل `old.description` (كان `false`).
- **الإثبات:** 6 عمليات Live HTTP = 200/200/200/200/200/200، وفحص `audit_logs` الفعلي = 7/7 أشكال `old/new` مطابقة، وكلها `utf8=valid`. السجلات التاريخية `id<=726` = 246 صفًا بلا تغيير. `php -l` نظيف. بيانات الاختبار حُذفت (users→30، roles→4، permissions=38، بلا يتام).
- **الوثائق المتزامنة:** `CD-006_IMPLEMENTATION.md` (قسم بند 8 + جدول السجلات الستة + فحص الأشكال) و`CHANGELOG.md` الجذر.
- **نسخة الرجوع:** `_emergency/rollback/CD-006/2026-09-28/{audit,admin-user-controller,admin-role-controller}.pre-item8.php`.

## 2026-09-28 — اعتماد البند 7 + 12 إصلاحًا توثيقيًا (Commit واحد — بلا تغيير كود)
- **اعتماد:** البند 7 **معتمد** (توقيع كبير المستشارين 2026-09-28) — «تنفيذ ممتاز». Commit التطبيق `f44d525` بلا تعديل؛ `app/` لم يُمسّ في هذا الـCommit.
- **الإصلارات الاثنا عشر:** (1) `CD-006_Phase2_Request.md` — hash مفقود الحرف `f` (`44d525` → `f44d525`) · (2، 3) `CD-006_Phase2_Item7_Report.md` — إضافة `ff66d2f` للترويسة + تصحيح سطر مرجع Git · (4) التقرير — إصلاح لصقة «أو حالة» · (5) `13_Security.md:80` — بند خارطة المعالجة #1 معلَّم مُنفَّذًا مع إبقاء (ب/ج/د/هـ) مفتوحة · (6) `13_Security.md:33` — تصحيح مرجع السطر 26 → 25 · (7) `CD-006_OUT_OF_SCOPE.md` — **شطب OOS-8** + «نُقل إلى البند 12-b» · (8) `CD-006_IMPLEMENTATION.md:184` — **إصلاح تشويش ترميز (محارف كورية/صينية)** · (9)IMPLEMENTATION — حالة البند 7 → «معتمد من كبير المستشارين» · (10) IMPLEMENTATION — سجل قرارات Q1–Q5 + نقطة التوقف الإلزامية · (11) `CHANGELOG.md` الجذر + التسليم — مدخل الاعتماد · (12) `CD-006_Phase2_Request.md` — تسجيل الإذن + Guardrail + التوقف بعد البند 10.
- **قرارات المستشار (2026-09-28):** Q1 → سلوك FK لحذف منشئ تقييم = **البند 12-b** (OOS-8 مشطوب) · Q2 (رابط `/admin/roles` بـ`roles.manage`) و Q3 (تنظيف بقايا بيانات الاختبار) **ضمن البند 11** · Q4 = إثبات آخر Admin بفحص الكود + عدم المساس **مقبول** · Q5 = `OOS-1` يبقى **CD-007**.
- **Guardrail:** «Guardrail CD-006 — الخطوة A + الخطوة B معتمدتان.» **التوقف الإلزامي:** بعد البند 10 → تقرير CP2 + توقف؛ لا بدء 11–12-b قبل الاعتماد.

## 2026-09-28 — CD-006 المرحلة 2 / بند 7: تفعيل صلاحيات `users.*` في حارس UserController
- **قاعدة الإنتاج المثبتة:** `employee_evaluation_mvc` (قرار المستشار — المصدر `config/database.php` الرسمي؛ `employee_evaluation` غير موجودة: خطأ 1046). **توضيح المرجع:** سؤالا قابلية العمود وسلوك FK يخصّان **البند 12-b** لا البند 7؛ و`created_by_user_id NOT NULL` + `eval_fk_creator RESTRICT` يؤكد قرار «الخيار (ج)» — والبند 12-b بعد CP2.
- **التنفيذ:** `UserController::__construct` من `Auth::is('Admin')` إلى `Auth::can('users.view')` + حارس لكل عملية (9 مواضع: `users.create` لـcreate/store، `users.edit` لـedit/update/updateRole/toggleStatus/resetPassword، `users.delete` لـdestroy). `header.php`: قائمة «إدارة المستخدمين/الأدوار» مستقلة مشروطة بـ`Auth::isAdmin() || Auth::userHasPermission('users.view')`.
- **قرارات استشارية موثّقة:** `can()` فيه `exit` → يُستخدم في الحُرّاس لا في القوالب (القوائم تستخدم `userHasPermission()` اتساقًا مع L373). **ترحيل `permissions_version` مُتخطّى** لأن `permissionsNeedRefresh()` يفحص DB كل 60 ثانية. بُنيت قائمة users خارج كتلة «الإعدادات» وإلا لم تظهر لمن يملك `users.view` وحدها.
- **الإثبات (Live HTTP):** Admin 200/200/200 (bypass) · دور `users.view` فقط = 200 على القائمة و403 على كل عمليات التعديل/الحذف (مع DB بلا تغيير) · Staff بلا `users.*` = 403 وبلا رابط · رابط users يظهر مرة واحدة لكل من Admin وviewer · `php -l` نظيف · بيانات الاختبار حُذفت (users 32→30، roles 5→4، permissions=38). نسخة الرجوع `_emergency/rollback/CD-006/2026-09-28/`.
- **الإغلاق:** البند 7 مكتمل — Commit التطبيق `f44d525` (`feat(A2.7): …`) + سطر إغلاق إلزامي في `CD-006_IMPLEMENTATION.md` + تقرير التسليم `CD-006_Phase2_Item7_Report.md` (MD + PDF) + مزامنة `A2_Users_Roles_Unit_Documentation.md` (9 مواضع) و`13_Security.md` في `459f7a9`.
- **فجوة متبقية مُبلَّغ عنها دون تنفيذ (خارج نطاق البند 7):** رابط `/admin/roles` صار داخل قائمة `users.view`، فمن يملك `users.view` دون `roles.manage` يرى الرابط ويصطدم بـ403؛ ومن يملك `roles.manage` بلا صلاحيات الإعدادات لا يجد رابطًا. سُجِّلت كفجوة `#13` في وثيقة A2، والقرار مطلوب من المستشار.

## 2026-09-23 — CD-006 المرحلة 2: طلب تفصيل البنود 7–12 من المستشار (قرار CD-006/CD-007 المثبَّت)
- قرّر كبير المستشارين اعتماد المرحلة 2 (البنود 7–12 + 12-b)؛ سطر الإطلاق مكتوب في CD-006_IMPLEMENTATION.md («المرحلة 2 مفتوحة — البند 7 بدأ في 2026-09-23»).
- **لا تنفيذ بعد:** التعريف التفصيلي للبنود 7–12 غير موجود في مستودعَي التطبيق والتسليم (بحث شامل: ملفات، git log، reflog، backups خارج كود التطبيق).
- وفق «قرار CD-006/CD-007» وتمسّكًا بقاعدة «لا تخترع النطاق»: طُلب من المستشار تزويد التفصيل المعتمد لكل البنود 7–12 قبل أي تنفيذ. التوقف آمن بانتظار الرد.


## 2026-09-23 — CD-006 المرحلة 1 (البنود 1–6) — إغلاق + تقرير CP1
- **تسليم:** *Git commit* في مستودع التسليم — إغلاق المرحلة 1 (6/6) بالتقرير الإلزامي:
  - `CD-006_Phase1_Report.md` + `CD-006_Phase1_Report.pdf` (**نمط A2**: mPDF RTL عربي بخط Cairo عبر سكربت مؤقت خارج كود التطبيق).
  - تحديث `CD-006_IMPLEMENTATION.md` (جدول الحالة → المرحلة 1 **مكتملة** + سطر إغلاق إلزامي «المرحلة 1 مكتملة — Commit … — إثبات في قسم «إغلاق المرحلة 1»).
  - Git جذر التطبيق: Baseline نظيف واحد — Commit `6cfa863` — بلا Gitlink، بلا vendor/config، الترحيلات متتبَّعة، العمل نظيف.
- **الحالة:** المرحلة 1 **مكتملة** — التوقف إلزامي قبل المرحلة 2 (البنود 7–12) بانتظار اعتماد CP1.


## 2026-09-21 — CD-006 المرحلة 1 / بند 6: منع تصعيد الصلاحيات في updatePermission
- `RoleController::updatePermission`: الإلزام بدور Admin (`Auth::isAdmin`) وتضمين دالة جديدة `Role::findPermissionById` + رفض منح صلاحية لا يملكها المنفّذ + Audit بـ`old/new` و`permission_name` و`actor_id`. ترحيل DB غير مطلوب.
- إثبات Live HTTP: Admin يضيف/يزيل (200)، تعديل دور Admin (403)، صلاحية غير موجودة (404)، مستخدم بـ roles.manage دون Admin (403). `php -l` نظيف، وبعد التنظيف DB رجع إلى users=4/user_roles=4/roles=4/permissions=38. نسخ رجوع في `_emergency/rollback/CD-006/2026-09-21/{controllers,models}`.

## 2026-09-21 — CD-006 المرحلة 1 / بند 5: تصحيح صلاحيات Staff (إزالة branches.manage)
- ترحيل `database/migrations/2026_09_21_A2_item5_staff_branches.sql` (+ نسخة التسليم): إزالة `branches.manage` (id14) من Staff (role_id=4) ومنحه `branches.view` (id13)، مع `PERMISSION_REMOVED` في audit_logs ورفع permissions_version (smutairi 2→4).
- إثبات: Staff={branches.view,departments.view} بلا branches.manage، وفحص تطبيقي `User::getUserPermissions(3)` يؤكد ذلك؛ بقية الأدوار دون تغيير.

## 2026-09-21 — CD-006 المرحلة 1 / بند 4: تصحيح صلاحيات Manager (RBAC)
- ترحيل `database/migrations/2026_09_21_A2_item4_manager_rbac.sql` (+ نسخة التسليم): إنشاء `evaluations.view.team` (id39) و`evaluations.create.team` (id40)، ومنح Manager (role_id=3) الصلاحيات الثلاث `evaluations.view.team`/`evaluations.create.team`/`reports.view.team` (id10)، مع `PERMISSION_ADDED` في audit_logs ورفع permissions_version تلقائيًا (kghamdi 2→5).
- إثبات: Manager=3 صلاحيات، وبقية الأدوار دون تغيير، وفحص تطبيقي `User::getUserPermissions(2)` = الثلاث بالضبط. ملاحظة: تمرير stdin عبر PowerShell شوّه العربية → أُعيد التطبيق عبر `mysql source` (UTF-8).

## 2026-09-21 — CD-006 المرحلة 1 / بند 3: حماية آخر مدير نظام نشط
- `User`: `activeAdminCount()`/`isActiveAdmin()`/`isLastActiveAdmin()` بتعريف ديناميكي لدور Admin (`Auth::adminRoleIds`). `UserController`: منع حذف/تعليق/خفض آخر مدير نشط في `destroy`/`toggleStatus`/`updateRole` + `LAST_ADMIN_PROTECTED` + إشعار للمشرفين، ودالة `warnIfSingleActiveAdmin()` تُنبّه عند الهبوط إلى مدير واحد.
- إثبات Live HTTP بجلسة Admin قديمة والمدير النشط الوحيد `sysadmin`: المسارات الثلاثة مُنعت (حذف/خفض 200 مع منع، تعليق 403)، `sysadmin` بقي active/Admin، وإشعارات warning (منع + هبوط إلى 1). تنظيف كامل → users=4. اكتشاف OOS-8 (FK `eval_fk_creator` يسبب 500 عند الحذف).

## 2026-09-21 — CD-006 المرحلة 1 / بند 2: إصلاح شاشة إنشاء المستخدم
- `app/Views/admin/users/create.php` أُعيدت كتابتها من الصفر (كانت 372 سطرًا من markup باني القوالب بترميز مشوّه — اكتشاف CD-005 G1). النموذج الآن: username/email/password/password_confirm/role_id (إلزامي)/employee_id (اختياري) + `csrf_field()` + `POST /admin/users`.
- إثبات Live HTTP بحساب Admin مؤقت: GET الشاشة 200 بكل الحقول والقوائم (أدوار/موظفين) وغياب آثار الباني؛ POST أنشأ مستخدمًا فعليًا (role_id=4) مع `USER_CREATE`. حُذف الحسابان المؤقتان → users=4. النسخة القديمة في `_emergency/rollback/CD-006/2026-09-21/views/`.

## 2026-09-21 — CD-006 المرحلة 1 / بند 1: تنظيف بيانات الاختبار (بقايا CD-004)
- نسخة DB كاملة قبل الحذف: `storage/backups/CD-006/2026-09-21/employee_evaluation_mvc.pre-item1.sql` (1,244,716 بايت، MariaDB dump).
- ترحيل موثق `database/migrations/2026_09_21_A2_item1_cleanup_test_data.sql` (+ نسخة التسليم): حذف **58 حساب اختبار** (`%@test.local`/`test\_%`/`cd004.%`) + **صف عضوية يتيم واحد** في `user_roles`، مع إدراج `USER_CLEANUP_TEST_DATA` في `audit_logs` (id 682/683). ملاحظة: مشغّل `permissions_version` يمنع قراءة `users` داخل حذف `user_roles` (MySQL error 1442) → جدول مؤقت.
- النتيجة: `users=4` (sysadmin/kghamdi/smutairi/fzahrani)، `user_roles=4`، بلا يتيم. إنشاء `CD-006_IMPLEMENTATION.md` + `CD-006_OUT_OF_SCOPE.md`. النسختان (جذر/تسليم) متزامنتان.

## 2026-09-21 — CD-005: توثيق وحدة A2 — المستخدمون والأدوار والصلاحيات
- إذن كبير المستشارين + أمر «ابدأ التنفيذ» 2026-09-21: دراسة/توثيق **قراءة فقط** — لا تعديل كود ولا DB، نطاق A2 فقط (لا A1، لا دين تقني). قراران: (1) شاشة إنشاء المستخدم التالفة تُوثَّق **كاكتشاف فقط** بلا إصلاح → CD-006؛ (2) التسليم = MD + PDF + CHANGELOG في Commit واحد، وADR منفصل لاحقًا فقط عند قرار معماري حقيقي.
- `A2_Users_Roles_Unit_Documentation.md` (جديد، 11 قسمًا + ملحق التوثيق الدائم): نظرة عامة/الملفات والدورة/الشاشات/قواعد العمل/الأمان/القوة (12)/الضعف (16)/الفجوات (G1–G16)/الأسئلة المفتوحة (11)/التوصيات (P1–P3). + `A2_Users_Roles_Unit_Documentation.pdf` (mPDF RTL بخط Cairo عبر سكربت مؤقت خارج كود التطبيق).
- اكتشافات بارزة: **`Views/admin/users/create.php` تالف** (markup باني القوالب بدل نموذج المستخدم — شاشة الإضافة معطوبة، G1 حرجة). **Admin يملك 35/36** ويفتقد `positions.manage` (تعارض مع `02_Org_Structure.md:132`). **HR=2، Manager=0، Staff=`branches.manage`** (خطر أمني). صلاحيات `users.*` معطّلة. لا `Permission` model ولا `/admin/permissions`. لا اختبارات A2. تلوّث 58 حساب اختبار مقابل 4 حقيقية.
- لا تعديل أي ملف تطبيق/قاعدة بيانات. المراجع: `Role.php`, `User.php`, `Auth.php`, `RoleController`, `UserController`, `routes/web.php:78–95`, `main.js:490–790`, `db_live_schema.sql`. النسختان (جذر/تسليم) متزامنتان.

## 2026-09-21 — CD-004 إغلاق رسمي للوحدة A1 (توقيع كبير المستشارين — A1 COMPLETE)
- الإذن 2026-09-21: **فقط إغلاق A1** — تحديث سجلات + Commitment ثم وقف إلزامي. لا بدء لـ CD-005.
- `phase5/A1_Closure_Statement.md` (8 أقسام: ختم رسمي/نطاق/سجل الالتزامات/نتائج القبول 13/13/تقييم/تصريف الملاحظات/الإغلاق/الخطوة التالية). + «§7 اعتماد نهائي» في `Phase5_Acceptance_Report.md` (توقيع المستشار + إدارة المشروع فارغ).
- الاعتماد الكامل: A1 **15/15**، المرحلة 5 **PASS** لا جولة ثانية؛ التقييم: جودة استثنائية، 6 أيام فعلية مقابل 12 مخططة.
- التصريف: S9 + تكرار Notifications → **CD-005**؛ S2 → HTTPS تشغيلي؛ S6 مصفوفة كاملة → **A2**؛ الدين التقني **14 بندًا → CD-005**.
- رأس الحالة في `A1_Authentication_Unit_Documentation.md`/`00_INDEX.md`: لم يُعدَّل (ترميز غير قابل للتعديل الآمن) → سُجّل للتعامل ضمن CD-005. النسختان (جذر/تسليم) متزامنتان. **نقطة التوقف الإلزامية بعد Commit الإغلاق.**

## 2026-09-21 — CD-004 المرحلة 5: اختبار القبول والانحدار (13/13 PASS) — A1 مكتملة
- إذن كبير المستشارين 2026-09-21 (تجهيز + تنفيذ 13 سيناريو + انحدار + تقرير؛ بلا تعديل كود — لم يُعدَّل أي ملف تطبيق في المرحلة 5).
- توثيق التجهيز: `CD-001_delivery/phase5/Phase5_Acceptance_Report.md` + `Phase5_Scenarios.md` (13 سيناريو بخطوات/متوقع/معيار) + `Phase5_Regression_Checklist.md` + `Phase5_Test_Users.md` (6 مستخدمين) + `ROLLBACK_PATHS.md`. نسخة DB كاملة + نسخة كود في `storage/backups/CD-004/phase5/`.
- النتائج 13/13: S1 قفل الحساب، S2 مهلة الجلسة/الكوكي، S3 CSRF الدخول، S4 خروج POST، S5 فحص status، S6 الحارس، S7 إعادة تعيين Admin، S8 تغيير إجباري/حُرّ، S9 سياسة + نبذ آخر 3، S10 انتهاء صلاحية الصلاحيات، S11 رفع تذكّرني، S12 تنظيف cron، S13 دور Admin ديناميكي + إشعارات — التفاصيل والأرقام في التقرير.
- انحدار: AuthTest 58/58، NotificationTest 13/13، فحص صفحات الوحدات عبر HTTP + مواقع forbidden() — بلا انحدار (DatabaseTest 4/5 + HelpersTest 2/3 خط أساس معروف OOS).
- تنظيف كامل لبيانات المرحلة (`temp/phase5_cleanup.sql`): test_* / P5-EMP-* / P5SEED = 0، أدوار ومشغّلات سليمة، DB عادت لحالتها. القرار: A1 مكتملة (15/15) بانتظار التوقيع.

## 2026-09-21 — CD-004 بند 13: cron التنظيف اليومي (cron/cleanup.php)
- إذن مستشار 2026-09-21 بنطاق محدد: (1) `csrf_tokens` المستخدمة أو المنتهية والأقدم من 24 ساعة، (2) `login_attempts` الأقدم من 24 ساعة، (3) الإشعارات `is_read=0` الأقدم من 90 يومًا فقط، (4) تسجيل كل عملية في `audit_logs` (`CRON_CLEANUP_CSRF_TOKENS / _LOGIN_ATTEMPTS / _NOTIFICATIONS` مع count والـrule؛ `user_id=NULL` إجراء نظام). لا «إعادة مصادقة» — مؤجلة (OOS #9 → CD-005).
- حارس CLI + bootstrap بفشل اتصال `exit(1)` وفشل وحدة لا يوقف بقية الوحدات. لا OOS جديد (تحذير المستشار مطابق: الثلاثة فقط؛ أرشفة لاحقة → CD-005).
- اختبار يدوي على DB الحية (بذر 8 صفوف مميزة): قديم يُحذف، حديث (<24 ساعة) يُبقى، إشعار قديم مقروء يُبقى للتدقيق؛ سجل audit بثلاث عمليات ✔؛ تنظيف شامل للبذر/الإدخالات التجريبية. `php -l` نظيف. نسخة `cron-cleanup.pre-item13.php`.

## 2026-09-21 — CD-004 بند 15: شاشة الإشعارات (شيفرة المصدر في جذر المشروع)
- `GET /notifications` → `NotificationController@index` — قائمة حساب (الأحدث أولًا، مقروء + غير مقروء بتمييز)، تعرض الإشعارات **القديمة** (قبل بند 14 — بلا `related_url`) والجديدة، بأنماط enum الأربعة بشارة وتسمية عربية (بلا تعديل ENUM — OOS #1)، وحالة فارغة.
- `POST /notifications/read/:id` (مسار مُسند لصاحب الحساب — لا قراءة لإشعارات الغير) و`POST /notifications/read-all` (لا يمس إشعارات الغير) — POST محمي بـCSRF.
- جرس هيدر: أيقونة + شارة عدد غير المقروء + منسدلة بأحدث 5 إشعارات + «عرض كل الإشعارات»؛ أنماط CSS.
- `app/Models/Notification.php` (جديد، نمط `getPdo+FETCH_ASSOC`): `forUser/unreadCount/recentForUser/markRead/markAllRead` — **بلا أي DELETE**.
- سياسة احتفاظ (تُحترم في cron بند 13): لا يُحذف إلا غير المقروء قبل 90 يومًا (`is_read=0`)، والمقروءة تبقى للتدقيق (متطلب المستشار).
- إثبات: `tests/cases/Core/NotificationTest.php` — **13/13** (عدّاد، ترتيب/legacy، حد الـ5، نطاق per-user، تخزين `notifyAdmins`، عرض كامل، حالة فارغة، بوابة زائر، إجراءا POST). `php -l` نظيف. **المجموعة الكاملة بلا انحدار** (AuthTest 58/58 + خط أساس معروف). نسخ استرجاع `*.pre-item15`.
- اعتماد مشروط متمَّم: شرط «تأكيد session_unset قبل session_regenerate_id (بند 8)» مؤكَّد — ADR في IMPLEMENTATION + `app/Core/Auth.php:498-499`.

## 2026-09-21 — CD-004 بند 8: انعاش نسخة صلاحيات المستخدم (permissions_version) (شيفرة المصدر في جذر المشروع)
- `database/migrations/2026_09_21_A1_permissions_version.sql` (جديد) — **خطوة أولى إلزامية** `UPDATE users SET permissions_version = permissions_version + 1` (أي جلسة نشطة قبل الترحيل تحمل نسخة قديمة) ثم 4 مشغّلات `cd004_trg_*` على `user_roles` و`role_permissions` (AFTER INSERT/DELETE) ترفع نسخة المعنيين عند أي تعديل — قرار المستشار: **Triggers على مستوى البيانات** (الاكتمال > الشفافية). فهرس `user_roles.role_id` متحقق موجود.
- `app/Core/Auth.php` — `permissionsVersionOf()` (‑1 عند تعذر القراءة = لا تغيير، حفاظًا على التوافر)، `refreshSessionPermissions()` (يعيد بناء أدوار/صلاحيات الجلسة ويثبّت النسخة ووقت الفحص — يُستدعى من `login()`)، `permissionsNeedRefresh()` (نافذة كاش `PERMISSIONS_VERSION_CACHE_SECONDS=60`) و`invalidateSessionIfPermissionsChanged()` (حارس الطلب: `session_unset` + `session_regenerate_id(true)` + رسالة «طرأ تعديل…» + `/login`).
- `public/index.php` — استدعاء الحارس بعد `enforceCsrfToken()`.
- `app/Controllers/AuthController.php` — `login()` يستخدم `Auth::refreshSessionPermissions()` (تثبيت النسخة عند الدخول).
- `tests/cases/Core/AuthTest.php` — 7 اختبارات جديدة (من 51 إلى **58**): مشغلا `user_roles`، مشغّل `role_permissions` مع **3 مستخدمين بدور واحد** + مستخدم تحكمي بدور آخر (لو رُفعت مرة واحدة لكان المشغّل خاطئًا)، تثبيت النسخة عند الدخول، إبطال عند الاختلاف، نافذة الـ60 ثانية، جلسة ما قبل بند 8، وانخفاض **Admin→Staff** الإجباري (إبطال + `IS_ADMIN=0` بعد إعادة الدخول).
- إثبات: تطبيق الترحيل على DB الحية (4 مشغّلات + `permissions_version=2` لجميع المستخدمين) + `php -l` نظيف + **AuthTest 58/58** + المجموعة الكاملة بلا انحدار (خط الأساس معروف).
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/Auth.pre-item8.php` + `AuthController.pre-item8.php` + `public/index.pre-item8.php`. تراجع DB: `DROP TRIGGER IF EXISTS cd004_trg_*`.
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 8) + `A1_Authentication_Unit_Documentation.md` (§11 صف P2 «انعاش الصلاحيات» → نُفِّذ). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 10: شاشة تغيير كلمة المرور (شيفرة المصدر في جذر المشروع)
- `routes/web.php` — `GET/POST /change-password` → `AuthController@showChangePassword/changePassword`.
- `app/Controllers/AuthController.php` — `requireLogin()`؛ `showChangePassword()` (عرض بشـ«مرجع سياسة بند 11»)؛ `changePassword()`: تأكيد كلمة المرور الحالية (`password_verify`) ← مطابقة التأكيد ← `User::updatePassword` (سياسة بند 11 + نبذ آخر 3 + **مسح `must_change_password`**) ← `Audit::log('USER_PASSWORD_CHANGE')` ← `/dashboard`. كل POST محمي بـ CSRF عبر `enforceCsrfToken`.
- `app/Views/auth/change-password.php` (جديد) — نمط صفحة الدخول + حقل الحالية/الجديدة/التأكيد + قائمة مرجع السياسة + `csrf_field()`.
- يكمل بند 9 تلقائيًا (وجهة فرع الإلزام قائمة فعليًا)؛ تدفق تفعيل `invited` خارج النطاق → OOS #10 → CD-005.
- `tests/cases/Core/AuthTest.php` — 8 اختبارات `testChangePassword*`؛ مساعدا `changePasswordScript`/`changePasswordPageScript`.
- إثبات: `php -l` نظيف + **AuthTest 51/51** + المجموعة الكاملة بلا انحدار (خط الأساس معروف؛ DatabaseTest 4/5 + HelpersTest 2/3). خدعتان موثقتان: إخراج الصفحة الكبيرة (~13KB) فوق حد أنبوب Windows يشلّ `runCli` → `$stdoutFile` (OOS #8)؛ و`LOCATION=sent` تحت CLI → تثبيت الوجهات ساكنًا.
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 10) + `CD-004_OUT_OF_SCOPE.md` (OOS #10) + `A1_Authentication_Unit_Documentation.md` (§2.3 مسارات، §2.2 المتحكم، §10 سؤالي 2 و7، §11 صف P2). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 9: إعادة تعيين كلمة المرور عبر Admin + إلزام التغيير + ر.ق 2 (شيفرة المصدر في جذر المشروع)
- `app/Models/User.php` — `updatePassword($userId, $newPassword, $mustChange = false)`: إعادة التعيين الإدارية تفعّل `must_change_password=1`، والتغيير العادي يمسحه إلى 0 (الحارس/السياسة/التاريخ كما في بند 11).
- `app/Controllers/Admin/UserController.php` — `resetPassword()` يستدعي `updatePassword(..., true)` ورسالة نجاح تُعلم بوجوب التغيير عند الدخول التالي.
- `app/Controllers/AuthController.php` — `login()`: بعد نجاح المصادقة، مستخدم `must_change_password=1` يُوجَّه إجباريًا إلى `/change-password` مع `Flash` توضيحي (الوجهة تُبنى في بند 10).
- **ر.ق 2 (إزالة استعادة كلمة المرور الميتة):** حذف رابط «نسيت كلمة المرور؟» (`href="#"`) + صف `form-options` الفارغ من `login.php`؛ حذف ملف `forgot-password.php` (0 بايت)؛ إزالة `'forgot-password'` من `skipRoutes` في `Auth::enforceCsrfToken` — الإعادة حصرية عبر Admin.
- `tests/cases/Core/AuthTest.php` — 4 اختبارات جديدة + استبدال `testEnforceCsrfTokenSkipsForgotPasswordPost` بـ `testEnforceCsrfTokenNoLongerSkipsForgotPassword`.
- إثبات: `php -l` نظيف + **AuthTest 43/43** + المجموعة الكاملة بلا انحدار (خط الأساس معروف).
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 9) + `A1_Authentication_Unit_Documentation.md` (§8-10, G10, §10 سؤال 2, §11 P2 أُجيبوا بالحذف/الإزالة). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 11: سياسة كلمة المرور (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `PASSWORD_POLICY_MIN_LENGTH=8` + `PASSWORD_POLICY_HISTORY=3` + قائمة `PASSWORD_POLICY_COMMON` (أعلى 100) + `passwordPolicyRules()` + `validatePasswordPolicy()` (الطول/التنوع 3من4/السوداء/نبذ آخر 3) + `passwordReusedRecently()` + `recordPasswordHistory()` (prune إلى 3 عبر derived-table لتجاوز MySQL 1093) + `generateStrongPassword(12)` (CSPRNG يضمن الأنواع الأربعة).
- `app/Models/User.php` — الخاصية `lastPasswordErrors` + الحارس `guardPasswordChange()` + `updatePassword()` و`updateUser()` يفرضان السياسة ويسجّلان هاش القديم في `password_history`.
- `app/Controllers/Admin/UserController.php` — preflight بالسياسة في `store()`/`update()` (Flash برسائل موحّدة) و`resetPassword()` بمولّد `generateStrongPassword` واستجابة أخطاء موحّدة.
- `tests/cases/Core/AuthTest.php` — 9 اختبارات: القواعد المعتمدة، القبول، الرفض (فارغ/قصير/تنوع/سوداء)، نبذ آخر 3 + prune (الرابع الأقدم مسموح)، `updateUser` يفرض السياسة، توافق مولد بقوة مع السياسة بأكملها.
- إثبات: `php -l` نظيف + **AuthTest 40/40** + المجموعة الكاملة بلا انحدار (DatabaseTest 4/5، HelpersTest 2/3 خط أساس معروف).
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 11) + `A1_Authentication_Unit_Documentation.md` (§10 سؤال 1 أُجيب + §11 توصية P2 + خارطة NIST/MFA→CD-005). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — إغلاق CD-004: اعتماد البند 6 + خطة C/B/A + سطور الإغلاق الإلزامية
- **إغلاق البند 6 (استيضاح المستشار)**: `git log` يُثبت التسلسل 6(`8a72979`)←7(`991e0bb`)←14(`0982b3e`) — البند 6 أُغلق قبل 7 و14؛ لا إعادة عمل. أدلة مُعادة التوكيد (القراءة الآنية): `php -l` نظيف لـ config.php/index.php/verify_phase1.php، غياب `config/app.php`+`performance.php`، حضور `storage/logs/php-error.log`+`storage/.htaccess`، grep بلا مراجع للملفين المحذوفين.
- **C — تذييل مرجعي تاريخي** بالنص الموحّد (مرجع تاريخي — الكود الفعلي يستخدم بحثًا ديناميكيًا عبر `roles.name='Admin' AND is_system_role=1`) في 4 مواضع: `CD-004_Execution_Plan.md:58`، `CD-004_IMPLEMENTATION.md:74`، `A1:246`، `docs/Phase_0_Documentation.md:46`. قرار المعتمد: لا تُذيَّل المواضع ذاتية التوثيق (CHANGELOG، سجل بند 14).
- **B — إعادة تحقق بند 14 بعد البند 6**: `AuthTest` **31/31** (DatabaseTest 4/5 وHelpersTest 2/3 خط أساس) + تكرر Live HTTP (بذرة → إشعار أساس → تدوير roles.id حتى 13 → إشعار عبر الدور الجديد Δ+1 → استعادة → تنظيف `USERS=0`) **PASS** — سُجّل في قسم بند 14.
- **A — سطور الإغلاق الإلزامية** «البند X مكتمل — Commit Y — إثبات في القسم Z» أُضيفت رجعيًا: المرحلة 0 (`1bdca31`)، 1 (`ab51405`)، 2 (`62499d3`)، 3 (`e0118ff`)، 4 (`6ce71d6`)، 5 (`19ce159`)، 6 (`8a72979`)، 7 (`991e0bb`)، 12 (`718c0e3`)، 14 (`0982b3e`).
- **OUT_OF_SCOPE**: #7 (`App.php:52` `if(DEBUG_MODE)` — غير حاجب، يُدرَج في CD-005) + #9 (نطاق بند 13 = تنظيف `csrf_tokens` فقط؛ إعادة المصادقة G13 مؤجلة لـA1-3 → CD-005).
- الاستئناف وفق الاعتماد: **المرحلة 3** (11→9→10). إثبات التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 14: دور Admin ديناميكي (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `adminRoleIds()`: `roles.name='Admin' AND is_system_role=1` مع كاش ثابت لكل طلب وFallback آمن (لا إشعارات + `error_log('CD004_ITEM14…')` في `storage/logs/php-error.log`)، و`clearAdminRoleIdsCache()`؛ `notifyAdmins()` أعيدت كتابتها بـ`role_id IN (:rid…)` وتعود فورًا عند قائمة فارغة.
- `app/Core/CsrfGraceLogger.php` — `notifyAdmins` تستخدم `Auth::adminRoleIds()` (Remedy النطاق المعتمد للبند 14) لنفس النمط.
- `_emergency/create_api_keys_table.sql` + `_emergency/csrf_migration.sql` — `role_id=1` الصريح → `IN (SELECT id FROM roles WHERE name='Admin' AND is_system_role=1)`؛ أدوار HR/Manager/Staff بقيت ثوابت كما كانت.
- `tests/cases/Core/AuthTest.php` — `seedAdminUser` ديناميكي + أدوات تدوير/تنزيل دور Admin النظامي (`rotateAdminRole`/`restoreAdminRole`/`demoteSystemAdminRole`/`restoreSystemAdminRole`) و`notificationTitleCount`.
- الإثبات: grep شامل صفر + `php -l` نظيف + `AuthTest` 31/31 (وصول إشعار إدارة عبر معرّف جديد ≠ 1، وFallback بلا دور نظامي) + **Live HTTP** (تسجيل موقوف → إشعار؛ تدوير `roles.id` → إشعار عبر الدور الجديد ثم استعادة؛ تنظيف `USERS=0`) **PASS**.
- إعادة مرجعية «الاتفاقية»: معرّف الدور الترقيمي غير ثابت — المطابقة بالمعرّف فقط داخل نموذج عرض (radio) بلا كتابته في منطق التشغيل.
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 14) + `CHANGELOG.md` (جذر/تسليم) + `A1_Authentication_Unit_Documentation.md` (3 مواضع). تفاصيل الإثبات الكاملة في `CD-004_IMPLEMENTATION.md`.

## 2026-09-16 — CD-004 بند 7: إصلاح حارس Admin/UserController (شيفرة المصدر في جذر المشروع)
- `app/Controllers/Admin/UserController.php` — `exit;` بعد `forbidden()` داخل `__construct`: سابقًا `return forbidden()` بلا `exit` يترك تنفيذ دالة الإدارة يستمر للمستخدم غير Admin (Remedy A1 §2 أ: الحارس القاصر Google-Bot-accessible).
- `tests/cases/Core/AuthTest.php` — `testAdminUserControllerGuardStopsNonAdmin` (subprocess: غير-Admin يتوقف عند 403 بلا «إدارة المستخدمين»؛ وAdmin يمر — `ADMIN_PASSED`).
- الإثبات: `php -l` + `AuthTest` 29/29 + Live HTTP (Staff → GET `/admin/users` 403 بلا محتوى إداري وPOST `update-role` 403 بلا `USER_ROLE_UPDATE`؛ Admin → GET 200 مع الصفحة؛ تنظيف `USERS=0`) PASS. **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 7) + `CD-004_OUT_OF_SCOPE.md` (بند 8: قياس `runCli`).

## 2026-09-16 — CD-004 بند 6: إخفاء الأخطاء ودمج الإعدادات (شيفرة المصدر في جذر المشروع)
- `config/config.php` — دمج `app.php` + `performance.php` (ر.ق 1): `memory_limit=2048M`، `max_execution_time=600`، `BACKUP_BATCH_SIZE=100`؛ `DEBUG_MODE=false` + `display_errors=0` + `log_errors=1` + `error_log → storage/logs/php-error.log`؛ `opcache_reset()` مستبعد عمدًا من الدمج.
- حذف `config/app.php` + `config/performance.php` — لا `require` لهما في أي موضع (متحقق grep قبل/بعد).
- `public/index.php` — إزالة فرع `DEBUG_MODE` وطباعة الـ Trace (44–49) → `error_log` كامل + `http_response_code(500)` + صفحة عامة.
- `storage/logs/` + `storage/.htaccess` (`Require all denied` — حماية السجلات والنسخ من الوصول عبر الويب).
- `_emergency/verify_phase1.php` — فحوصات بند 6 في [2/8] + `PHP_BINARY` ليعمل بلا `php` على PATH.
- وثائق محدّثة: `07_Technical_Implementation_Details.md`, `10_Performance_Backup_API.md`, `99_Master_Handover_Report.md`, `A1_Authentication_Unit_Documentation.md` (إزالة مراجع app.php/performance.php وضبط DEBUG_MODE).
- إثبات: `php -l` + grep بلا مراجع + `AuthTest` 28/28 + اختبار خطأ متعمد (CLI/HTTP) سُجّل في `storage/logs/` وأُخفي من الشاشة + Live HTTP (login 200، storage→403، مسبار 500 صامت) + verify_phase1 [2/8] 10/10. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-16 — CD-004 بند 4: الخروج عبر POST (شيفرة المصدر في جذر المشروع)
- `routes/web.php` — حذف `GET /logout` نهائيًا (أصبح 404) واستبداله بـ`POST /logout` (Remedy P2 في A1 §3.3) — يمنع Logout-CSRF عبر رابط مُضمَّن.
- `app/Controllers/AuthController.php` — `logout()`: `Auth::logout()` + `session_destroy()` + إتلاف كوكي الجلسة (EVALSESSID) عبر `setcookie(session_name(), '', time()-42000, ...)` ثم توجيه `/login`.
- `app/Views/layouts/header.php` — ربط الخروج من `<a href>` إلى نموذج POST مع `csrf_field()` (يُغطَّى بـ`Auth::enforceCsrfToken`).
- `tests/cases/Core/AuthTest.php` — `testLogoutRouteIsPostOnly` (تحقق Reflection من خريطة `$router`: لا `GET['logout']`، و`POST['logout']` صحيح).
- `appendices/routes_inventory.txt` — سطر logout حُدِّث إلى POST + تعليق البند.
- إثبات: `php -l` + `AuthTest` 28/28 + Live HTTP (GET /logout→404 والجلسة سليمة؛ POST بلا توكن→رفض CSRF والجلسة سليمة؛ POST بتوكن→302 `/login` مع `Set-Cookie: EVALSESSID=deleted; Max-Age=0` والجلسة ملغاة؛ نموذج header يحوي action/token) PASS. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 1: فحص users.status بعد password_verify (شيفرة المصدر في جذر المشروع)
- `app/Controllers/AuthController.php` — بعد نجاح كلمة المرور: `active` يكمل الدخول؛ `suspended`/`invited` يُرفضان مع `Audit::log` (`USER_LOGIN_SUSPENDED`/`USER_LOGIN_INVITED`) وإشعار `Auth::notifyAdmins` وفلاش وتوجيه `/login`. تدفق `invited` الكامل مؤجل إلى بند 10.
- `tests/cases/Core/AuthTest.php` — 3 اختبارات (رفض suspended/رفض invited/قبول active) عبر عملية فرعية + بذر/تنظيف مستخدمين مؤقتين.
- إثبات: `php -l` + `AuthTest` 27/27 (مرتان، بلا بقايا) + Live HTTP (suspended/invited → /login مع Audit+إشعار؛ active → /dashboard) PASS. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 2: قفل محاولات الدخول (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — ثوابت ومساعدات القفل (`MAX_LOGIN_ATTEMPTS=5`, `LOCKOUT_WINDOW_SECONDS=900`, `countLoginFailures`, `isLoginLocked`, `logLoginAttempt`, `clearLoginAttempts`, `loginDelaySeconds`, `notifyLoginLocked`) عبر جدول `login_attempts` المترحّل (بند 0).
- `app/Controllers/AuthController.php` — منع الدخول قبل التحقق للحساب المقفول؛ تسجيل الفشل + تأخير متدرج 1/2/4/8ث؛ القفل عند 5 فاشلة/15د مع `USER_LOGIN_LOCKED` وإشعار محذر لـAdmin؛ النجاح يمسح المحاولات.
- `tests/cases/Core/AuthTest.php` — 3 اختبارات جديدة.
- إثبات: `php -l` + `AuthTest` 24/24 + Live HTTP (failCount 1→5، أوقات رصدت 1/2/4/8/8ث، إشعار للمشرف، الطلبان #6/#7 مرفوضان مع بقاء العد=5). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 12: إزالة «تذكرني» (شيفرة المصدر في جذر المشروع)
- `app/Views/auth/login.php` — حذف checkbox «تذكرني» (كان بلا `name`)؛ بقيت `form-options` مع رابط «نسيت كلمة المرور؟».
- إثبات: `php -l` نظيف + Live HTTP (لا `name="remember"` في صفحة الدخول، ورابط forgot-password حاضر). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 3: CSRF صفحة الدخول (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `generateCsrfToken`/`validateCsrfToken` يعملان **قبل المصادقة** (الجلسة أولًا؛ DB طبقة ثانية للمصادقين عبر `self::check()`)؛ إزالة `'login'` من `$skipRoutes` في `enforceCsrfToken` → POST /login يخضع الآن لفحص CSRF.
- `app/Views/auth/login.php` — `csrf_field()` داخل نموذج الدخول.
- `tests/cases/Core/AuthTest.php` — استبدال اختبار السلوك القديم (المسبب لـ`exit()` الصامت في المشغّل) باختبارَي السلوك الجديد.
- إثبات: `php -l` + محاكاة توكن ما قبل المصادقة PASS + Live HTTP (GET يحوي التوكن؛ إعادة استخدام عبر إعادة التحميل؛ POST بتوكن صحيح → /login، بدون/خاطئ → رفض) + `AuthTest` 21/21. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 5: تحصين الجلسة (شيفرة المصدر في جذر المشروع)
- `config/config.php` — إعدادات جلسة موحّدة قبل `session_start()`: `session_name('EVALSESSID')`, `gc_maxlifetime=1800`, `cookie_httponly=1`, `cookie_samesite=Strict`, `use_strict_mode=1`, `use_only_cookies=1`, `cookie_lifetime=0` + إزالة السطر الفارغ الفاتح.
- `public/index.php` — تحميل الإعدادات قبل `session_start()` (كان بعده فيُبطل فعاليتها) + تحويل الترميز CP-1256→UTF-8 (معكوس وحرفي).
- إثبات: `php -l` نظيف + smoke فعّال + `AuthTest` 20/20. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 المرحلة 0: ترحيل قاعدة بيانات A1
- `CD-004_Execution_Plan.md` — خطة تنفيذ الوحدة A1 معتمدة (قرار كبير المستشارين 2026-09-15، 5 ملاحظات إلزامية).
- `CD-004_IMPLEMENTATION.md` — سجل تنفيذ يُحدَّث بعد كل بند؛ أُنجِزت المرحلة 0 (ترحيل DB + Dry Run لخطة التراجع + تحقق DROP password_resets).
- `CD-004_OUT_OF_SCOPE.md` — سجل ما خارج النطاق (ملاحظة الـENUM + فشلان سابقان في اختبارات غیر مرتبطة).
- `database/migrations/2026_09_15_A1_authentication.sql` — login_attempts + password_history + users(must_change_password, permissions_version) + DROP password_resets. انحدار خفيف: AuthTest 20/20.

## 2026-09-15 — CD-003: التوثيق التفصيلي للوحدة A1
- `A1_Authentication_Unit_Documentation.md` + `.pdf` — دراسة قراءة فقط لوحدة المصادقة والدخول والجلسات بالأقسام الأحد عشر (نظرة عامة، الملفات والمكونات، دورة العمل، الشاشات، قواعد العمل، الأمان الحالي، نقاط القوة، نقاط الضعف، الفجوات، الأسئلة المفتوحة، التوصيات).
- تأكيد نتائج `13_Security.md`: لا قفل محاولات، لا فحص لحالة الحساب عند الدخول، حارس `Admin\UserController` مكسور، وجلسة غير محصّنة (`config/performance.php` غير محمّل).
- إعلان صريح: لقطات الشاشات غير متوفرة (MySQL متوقف لاستعادة حالة الاستضافة الأصلية) — تُوثَّق الشاشات من مصدر العرض.

## 2026-09-15 — CD-001: حزمة التوثيق الكاملة v1.0
- الوثائق 01–15 + `00_INDEX` + `00_COVER` + `99_Master_Handover_Report` + `appendices/` (schema, routes_inventory, views_inventory, live_data_snapshot).

---

**نهاية سجل التغييرات — CD-001/CD-003/CD-004**
