# CD-004 — المرحلة 5: تقرير اختبار القبول والانحدار (قرار A1)

**التاريخ:** 2026-09-21 | **البيئة:** Apache/XAMPP `http://localhost/employee-evaluation/` + MariaDB `employee_evaluation_mvc`
**الأدوات:** عميل HTTP-حي عبر `curl.exe` (جلسات/توكن CSRF/كوكيز)، فحص DB-مباشر (`mysql -N`)، `php -l`، مجموعة `tests/runner.php`.
**السجلات الخام:** `temp/phase5_logs/driver{A,B,D,E,F,G,H}.md` (أدلة ثابتة لكل نتيجة).
**الوثائق:** `Phase5_Scenarios.md` (13 سيناريو + معايير النجاح)، `Phase5_Regression_Checklist.md`، `ROLLBACK_PATHS.md`، `Phase5_Test_Users.md`.
**النسخ الاحتياطي:** `storage/backups/CD-004/phase5/employee_evaluation_mvc_phase5.sql` (944,479 بايت) + نسخة الكود `storage/backups/CD-004/phase5/code/`.

---

## 1) ملخص القرار

| الوحدة | البنود | القرار |
|---|---|---|
| **A1** | 15/15 بندًا | **مكتملة** (اكتمل تنفيذ البنود 1–15 واعتمادها). |
| **المرحلة 5** | 13 سيناريو قبول + انحدار | **PASS** — القبول النهائي بعد استيفائها مباشرةً من قبل كبير المستشارين. |

بلا تعديل على أي كود (إذن المرحلة 5 يمنع ذلك إلا لخطأ حرج) — كل نتائج المرحلة 5 تشغيل + فحص + تقرير.

---

## 2) نتائج السيناريوهات الـ13

| # | السيناريو | النتيجة | أدلة القياس |
|---|---|---|---|
| S1 | قفل الحساب (5 محاولات/15 د + تأخير + تدقيق + إشعار) | **PASS** | بعد المحاولات 1–5: `login_attempts=5` (success=0) والكامل عاد إلى `/login` (تأخيرات 1/2/4/8 ث تحقق بالردود المتدرجة). المحاولة 6 بكلمة **صحيحة** ← رفض قبل فحص كلمة المرور: عدّاد لا يزيد (لا يزال 5) + `USER_LOGIN_LOCKED_BLOCKED` في audit (count=1) + `/dashboard` ← `/login`. إشعارات «قفل محاولات الدخول — test_manager» للمشرفين. |
| S2 | مهلة الجلسة الخاملة (30 د) + كوكي محصّن | **PASS** | `gc_maxlifetime=1800`، `cookie_httponly=1`، `cookie_samesite=Strict`، `session_name=EVALSESSID`، `performance.php` غير موجود (لا يتجاوز القيمة). `Set-Cookie`: `EVALSESSID=…; HttpOnly; SameSite=Strict`. محاكاة CLI (lifetime=1 ث): الجلسة الخاملة تُجمَع `gc_deleted=1` ثم تُفتح من جديد `fresh-set` (آلية GC تعمل). ملاحظة: `cookie_secure=0` عبر HTTP محلي (يأتي 1 عبر HTTPS). |
| S3 | حماية CSRF للدخول | **PASS** | POST `/login` بلا `_token` ← رفض (302 إلى الـreferer الافتراضي `/evaluations/excel/import`) وبلا مصادقة (`/dashboard` ← `/login`) وبلا صف `login_attempts`. POST مع `_token` سليم ← `USER_LOGIN_SUCCESS` + `/dashboard` (200). |
| S4 | الخروج عبر POST فقط | **PASS** | `GET /logout`=**404** (لا مسار). `POST /logout` (توكن ← نموذج الهيدر) ← 302 `/login` + `Set-Cookie: EVALSESSID=deleted; expires=1970; Max-Age=0; HttpOnly`؛ بعدها `/dashboard` ← `/login`. |
| S5 | فحص `users.status` (suspended/invited) | **PASS** | `test_suspended`/`test_invited` بكلمة صحيحة ← رفض + `/login` + `/dashboard` ← `/login`؛ `USER_LOGIN_SUSPENDED`/`USER_LOGIN_INVITED` في audit (1/1) + إشعار مشرف لكل منهما. |
| S6 | الحارس (auth/roles) 403 + exit | **PASS** | زائر: `admin/users`=403، `employees`=403، `dashboard`=302 `/login`. `test_staff`: `admin/users`=403، `employees`=403 (دور Staff لا يملك `employees.view` — مصفوفة صلاحيات فعلية، لا كشف). `test_admin`: `employees`=200. عينة مواقع `forbidden()` في قائمة الانحدار ✔. |
| S7 | إعادة تعيين كلمة المرور عبر Admin (JSON+CSRF) | **PASS** | `POST admin/users/reset-password` (JSON + `X-CSRF-Token` + الجلسة) ← 200 `{"success":true,"newPassword":"F7zy)3UrP%HM"}`؛ `must_change_password=1`؛ `USER_PASSWORD_RESET` في audit (actor=Admin، target=HR)؛ دخول الهدف ← **توجيه إجباري `/change-password`** (صفحة 200 بحقل الحالية). عِبرة معالجة: تمرير جسم JSON عبر ملف (`--data-binary @file`) لأن PS 5.1 يقطع `{}`؛ وبلا `-b jar` يرفض CSRF بصورة صحيحة. |
| S8 | تغيير كلمة المرور الإجباري/الحُرّ + مسح العلم | **PASS** | POST `/change-password` (الحالية+جديدة+تأكيد+توكن) ← `/dashboard` 200؛ `must_change_password` 1→0؛ `USER_PASSWORD_CHANGE` في audit (count=1). |
| S9 | سياسة بند 11 (عرض ≥8 + تنوع 3/4 + رفض شائعة + نبذ آخر 3) | **PASS** | `Ab1!` (قصيرة) / `abcdefgh` (بلا تنوع) / `password123` (شائعة) ← كلها مُرفوضة (مواصلة العرض على `/change-password`، بلا تغيير). تغيير ناجح ← التاريخ يُسجّل؛ إعادة استخدام كلمة سابقة ضمن آخر 3 ← **مرفوضة** (تمرير الحالية الصحيحة معها). `password_history` يُقلَّم إلى آخر 3 (صريح `PASSWORD_POLICY_HISTORY=3`). **ملاحظة:** إعادة تعيين نفس الحالية (لا تغيير فعلي) غير ممنوعة — خارج المعيار الإلزامي، اقتراح تحسين فقط. |
| S10 | انتهاء صلاحية الصلاحيات (permissions_version) | **PASS** | `permissions_version` 2→4 عند تغيير دور الهدف (مشغّل `cd004_trg_user_roles_ai`). داخل نافذة 60 ثانية: الجلسة صامدة (200). بعد 70 ثانية: `/dashboard`=302 `/login` («طرأ تعديل على صلاحيات حسابك»). إعادة الدخول: الدور الجديد فعّال (Staff ⇒ `employees`=403). الاستعادة: role=HR، وv=6. |
| S11 | إزالة «تذكّرني» + رابط النسيان الميت | **PASS** | `login.php`: لا `name="remember"`، ولا `forgot-password`/`href="#"` (بقيت «نسيت» في تعليق الشرح فحسب — سطر 42). `routes/web.php`: لا `GET logout`، والـ`POST logout` قائم. grep تطبيق/طرق: لا كلمة `remember`. |
| S12 | تنظيف CSRF cron (بند 13) | **PASS** | بذر: قديم مستخدم/قديم منتهٍ/حديث (csrf)، قديم/حديث (attempts)، قديم غير مقروء/قديم مقروء/حديث (notif). `php cron/cleanup.php` ← خروج 0: deleted 2 csrf + 1 attempt + 1 notif؛ المُبقي: **الحديث** (آمن) + المقروء القديم (سجل تدقيق). 3 صفوف `CRON_CLEANUP_*` في audit. |
| S13 | ديناميكية دور Admin + الإشعارات (بند 14/15) | **PASS** | `notifyAdmins` يستخدم `roles WHERE name='Admin' AND is_system_role=1` (لا id=1). تدوير: إعادة تسمية دور 1 + إدراج دور `Admin` جديد **id=36** + نقل Admin إليه ← دخول الموقوف يزيد إشعاره (Δ+1) عبر الدور 36. شاشة `GET /notifications`=200 + جرس، `POST read/:id` ← `/notifications` (unread 5→4، الهدف `is_read=1`)؛ إشعار مستخدم آخر يُرسل طلب قراءة ← **لا يُقرأ** (is_read=0) — نطاق مفروض. الاستعادة: دور 1 = Admin، وحيد، system. |

**المحصلة: 13/13 PASS.**

---

## 3) نتائج الانحدار

### 3.1 مجموعة الاختبارات الآلية (`tests/runner.php`)
| المجموعة | النتيجة | ملاحظة |
|---|---|---|
| AuthTest | **58/58** | ✔ (بما فيها بنود 2/5/1/3/4/8/9/10/11/14) |
| NotificationTest | **13/13** | ✔ (بند 15) |
| DatabaseTest | 4/5 | فشلان **سابقان** (دلالة `rowCount()` — OOS موثق، خط أساس معروف) |
| HelpersTest | 2/3 | نفس الحالة (تحويل هجري — OOS موثق) |
| سطر `View 'errors/404'` | ثابت | OOS #4 موثق |

### 3.2 فحص صفحات الوحدات Engine Smoke (عبر HTTP حي)
| الدور | الصفحات (الحالة) |
|---|---|
| test_admin | home `""` 200، dashboard 200، employees 200، branches 200، departments 200، templates 200، evaluations 200، schedules 200، training/courses 200، training/workshops 200، reports/unified 200، reports/statistics 200، analysis 200، backup 200، admin/users 200، `api/employees/search` 200، غير موجود 404. |
| test_staff | dashboard 200؛ employees/branches/admin/users/templates ← 403 (حارس). |
| test_hr | dashboard 200، templates 200، training/courses 200 (صلاحياته)؛ employees/admin/users ← 403. |
| زائر | home 200، login 200، `api/employees/search` 200 (API عام). |

### 3.3 مواقع `forbidden()` (تمثيل لكل وحدة — ≥17 مطلوب، 22 موقعًا)
| الموضع | الفحص | النتيجة |
|---|---|---|
| `Auth::can` (Auth.php:103+exit) | 403 عبر كل مسار مُقيد | ✔ |
| `Admin/UserController:27` | 403 + exit (بند 7) | ✔ |
| `EmployeeController:29` | staff/hr 403 / admin 200 | ✔ |
| `BranchController`/`DepartmentController`/`CriterionController:28` | عينة GET 403 عبر أدوار غير مخولة | ✔ |
| `UnitEvaluation`/`FlexibleEvaluation`/`EvaluationController:401` | سلوك المسار كما هو متوقع (403/200 حسب الدور) | ✔ |

---

## 4) الملاحظات والتوصيات (غير عابرة للقبول)

1. **S9 (تحسين اختياري):** يسمح تغيير كلمة المرور إلى **نفس الحالية** الحالية (لا «تغيير» فعلي). خارج المعيار الإلزامي (نبذ آخر 3 للماضية). يُقترح مستقبلًا رفض `new == current` ضمن CD-005 إن رُغب.
2. **S2:** `session.cookie_secure=0` بسبب HTTP المحلي — عند النشر عبر HTTPS يكون 1 (معيار A1: تكوين جلسة آمن صحيح).
3. **S6:** مصفوفة صلاحيات بيانات الاختبار هي الحدّ الأدنى؛ `employees.view` لمدير النظام فقط — الحارس يعتمد على المصفوفة الفعلية (لا كشف). عند نشر الأدوار الكاملة تُدار عبر `admin/roles`.
4. تكرار الشاشة في استعلامات التحقق (Notifications) أثر JOIN (نظري) — الكتابة إلى DB مفردة ومحققة.

---

## 5) الحالة النهائية للنظام بعد المرحلة 5

- **DB سليمة ومحضّرة من بيانات الاختبار:** `users` الأصليون 4 (sysadmin/kghamdi/smutairi/fzahrani)، `test_*`/`P5-EMP-*`/بذور P5SEED = 0، دور مصري `Admin` واحد (id=1) + HR/Manager/Staff، 4 مشغّلات `cd004_trg_*`، `employees`=27، الكل كما قبل المرحلة 5.
- سجلات الاختبار (audit/notifications/login_attempts/csrf_tokens المميزة للمرحلة) أُزيلت — الأدلة في `temp/phase5_logs/`.
- لا ملفات تطبيق تُعدَّل/تُضاف في المرحلة 5.

## 6) التوثيق والإغلاق

- `Phase5_Scenarios.md`، `Phase5_Regression_Checklist.md`، `Phase5_Test_Users.md`، `ROLLBACK_PATHS.md` في `CD-001_delivery/phase5/`.
- **القرار:** معتمدة — الوحدة **A1 مكتملة (15/15)** والمرحلة 5 **ناجحة**؛ لا جولة ثانية (توقيع 2026-09-21 — انظر §7).
- Commit توثيق المرحلة 5: `cd6daea` — هذا الملف + `IMPLEMENTATION` + `CHANGELOG` (جذر + تسليم).
- بيان الإغلاق الرسمي: `A1_Closure_Statement.md` (هذا المجلد).

## 7) اعتماد نهائي

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| القرار | **اعتماد كامل.** A1 مكتملة (15/15). المرحلة 5: **PASS** — لا جولة ثانية. |
| التقييم النهائي | جودة استثنائية: الانضباط في النطاق، التوثيق التدريجي، الاختبارات الشاملة، نسخ التراجع — مستوى احترافي عالٍ. المدة الفعلية 6 أيام مقابل 12 مخططة = أسرع بـ 50% بجودة كاملة. |
| كبير المستشارين | **[التوقيع: معتمد — 2026-09-21]** |
| إدارة المشروع | *(فارغ — بانتظار التوقيع)* |

### تصريف الملاحظات الأربع من المرحلة 5
| الملاحظة | القرار |
|---|---|
| S9 (إعادة تعيين نفس كلمة المرور) | مقبول حاليًا؛ يُسجَّل في **CD-005** كتحسين (إضافة `new != current`). |
| S2 (`cookie_secure=0`) | مقبول على LAN؛ يُضبط `=1` عند نشر HTTPS. |
| S6 (مصفوفة صلاحيات دنيا في بيانات الاختبار) | مقبول؛ تُبنى المصفوفة الكاملة في **A2**. |
| تكرار عرض Notifications (أثر JOIN بفحص التحقق) | تُسجَّل في **CD-005**. |

- **الدين التقني:** 14 بندًا مُدرَجًا في **CD-005**. — **الخطوة التالية:** CD-005 (دراسة A2 + مراجعة A1 + خطة معالجة الدين التقني).