# CD-007 — سجل معالجة بنود خارج النطاق (OOS Resolution Log)

سجل حيّ لكل بند من بنود OOS في CD-007: سبب الجذر، الإجراء، القياس، والدليل.
يُحدَّث بعد كل بند. الأرقام فيه **مقيسة لا مقدَّرة**.

**الحالة:** المسار B — `OOS-1` و `OOS-9` و `OOS-13` مُغلقون · `OOS-10` قيد الانتظار.

---

## OOS-1 — منح `positions.manage` لدور Admin

**الحالة: مُغلق** · commit التطبيق `8ba0100` · 2026-10-06

### انحراف موثّق — الفرضية الأصلية كانت خاطئة

الوصف الوارد في `CD-006_OUT_OF_SCOPE.md` كان: «دور Admin بلا صلاحية
`positions.manage` (id=23) ← خطأ 403». **القياس الحيّ أنكر نصفه.**

| الفرضية | القياس | الحكم |
|---|---|---|
| Admin يُمنع بـ403 | `Auth::userHasPermission('positions.manage')` = **true** | ✗ |
| `positions.manage` غير مُسندة | 0 صفوف في `role_permissions` | ✓ |
| الصلاحية لـAdmin وحده | **لا يملكها أي دور** | ✗ أوسع |

**السبب الجذري الحقيقي:** `app/Core/Auth.php:88`

```php
if (self::isAdmin()) { return true; }   // تجاوز كل الصلاحيات
```

فأي مستخدم يحمل دور `Admin` يتجاوز كل فحص صلاحية. **لم يكن هناك 403 على Admin
يومًا.** والصلاحية `positions.manage` لم تكن مُسندة **لأي دور** — فكل مستخدم غير
Admin كان يُرفض، وبمسار خطأ.

**لماذا يستحق الإصلاح رغم ذلك:** الحارس في `PositionsController` (الأسطر
17/31/69/104) يفرض صلاحية سمّاها الكود وهي غائبة عن الجدول. السلوك يعمل
**على Accident** عبر التجاوز. لو أُزيل التجاوز (وهو OOS-18) انهار فورًا.
الإصلاح ينقل السلوك من الصدفة إلى البيانات.

### المسار الفعلي

`/admin/positions` **غير موجود**. المسار الفعلي **`employees/positions`**
(`routes/web.php:68`) بأربعة مسارات فرعية.

### ما نُفِّذ

```sql
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, 23 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM role_permissions
                  WHERE role_id = 1 AND permission_id = 23);

UPDATE users SET permissions_version = permissions_version + 1;
```

| العنصر | قبل | بعد |
|---|---|---|
| صفوف `role_permissions` | 42 | **43** |
| صلاحيات Admin | 35 | **36** |
| صفوف `permission_id=23` | 0 | **1** (فريدة) |

### انحراف ثانٍ — عبارة `UPDATE users` زائدة

القياس كشف أن المحفّز `cd004_trg_role_permissions_ai` **يُكبِر
`permissions_version` تلقائيًا** لكل من يحمل الدور:

```sql
UPDATE users u JOIN user_roles ur ON ur.user_id = u.id
SET u.permissions_version = u.permissions_version + 1
WHERE ur.role_id = NEW.role_id;
```

فالعبارة الصريحة في خطة التنفيذ سبّبت **+2 بدل +1**. صُحّحت إلى +1.
**الآلية المعتمدة هي المحفّز لا التحديث اليدوي.**

### السيناريوهات الأربعة — كلّها مقيسة

| # | السيناريو | النتيجة | ما يثبته |
|---|---|---|---|
| 1 | Admin مع id=23 | **200** | الوصول يعمل |
| 2 | **Staff بلا صلاحية** | **403** | **الحراس يعمل فعليًا** |
| 3 | Admin مع إزالة id=23 | **200** | **أثر التجاوز مثبت** |
| 4 | Admin بعد الاستعادة | **200** | استُرجعت الحالة |

السيناريو 2 هو الوحيد الذي يثبت عمل الحارس. السيناريو 1 كان يمرّ **قبل** الإصلاح
أيضًا.

### إبطال الجلسات — مُثبت بعمليتين منفصلتين

الدالة `invalidateSessionIfPermissionsChanged()` تنتهي بـ`exit` بعد `header`، فلا
تعود أبدًا. لذلك قِستُها في عمليتين:

| العملية | إصدار الجلسة | إصدار القاعدة | `needRefresh` | السلوك |
|---|---|---|---|---|
| 1 (قديم) | 1 | 9 | **true** | إبطال + خروج ✓ |
| 2 (مطابق) | 9 | 9 | false | لا إبطال ✓ |

### سجل التدقيق

`Audit::log('PERMISSION_GRANTED_TO_ADMIN', 23, 'role_permissions', {...})` → السجل
**id=1003**.

**انحراف في التوقيع:** التوقيع الفعلي **موقعي**
(`log($action, $entity_id, $entity_type, $details)`) ولا يقبل معاملات مسماة، فالكود
المعتمد في الخطة (`permission_id: 23`) كان سيفشل بصمت — و`Audit::log` يبتلع
الاستثناء في `error_log`.

### الاختبارات

| الاختبار | يثبت |
|---|---|
| `testPositionsAccessForStaffWithoutPermission` | حارس Staff = 403 |
| `testAdminPermissionsArrayContainsPositionsManage` | المنح صار في مصفوفة الجلسة |

`AuthTest` 59 → **61** · المجموع 90 → **92** · فشل 0 · أخطاء 0 · `exit=0`.

### نسخة الرجوع

`_emergency/rollback/CD-007/2026-10-06/OOS-1/`
— **الرجوع المرجعي**: `rollback.sql` + `role_permissions_before.csv` +
`users_permissions_version_before.csv`.

> **تصحيح (2026-10-06):** اللقطة الكاملة كان اسمها `db_before.sql`، وهيSnapshot
> أُعيد إنشاؤها بعد إصلاح `OOS-9` — أي أنها **ليست** لقطة ما قبل `OOS-1`.
> أُعيدت تسميتها `db_snapshot_after_oos9.sql`. النسخة الأولى كانت تالفة
> (انظر قسم `OOS-9` أدناه: UTF-16 و`123` علامة استفهام)، وأُعيد إنشاؤها
> بترميز UTF-8 سليم لكنه **ما بعد** الإصلاحين. سبب عدم وجود لقطة صحيحة لما قبل
> `OOS-1`: إعادة التوليد وقعت بعد الترحيل، والقياسات المسبقة محفوظة في ملفَّي CSV.

---

---

## OOS-9 — صفوف `evaluations` يتيمة

**الحالة: مُغلق**

### السبب الجذري (مقيس)

`tests/cases/Core/AuthTest.php` ينظّف بيانات اختبار بحذف مستخدمين مع
`SET FOREIGN_KEY_CHECKS=0`. تعطيل الفحوص يجعل الحذف يتجاوز القيد
`eval_fk_creator` (نوع `RESTRICT`)، فتبقى مراجع في `evaluations.created_by_user_id`
تشير مستخدمين محذوفين.

### القياس

| المقياس | قبل | بعد |
|---|---|---|
| صفوف يتيمة | 9 | **0** |
| `created_by_user_id = 1` | 38 | **47** (+9 بالضبط) |
| إجمالي `evaluations` | 50 | 50 (ثابت) |
| مخالفة القيد | 9 | **0** |

الصفوف التسعة: المعرّفات `4`–`12`، كلها بتاريخ `2026-08-24 03:29:48`.
القيم القديمة: `4,5,6→8` · `7→7` · `8,11→12` · `9→11` · `10,12→16`.
تحقّق إضافي: الطوابع الزمنية والدرجات و`status` للصفوف التسعة سليمة.

### الترحيل

```sql
UPDATE evaluations SET created_by_user_id = 1
 WHERE created_by_user_id NOT IN (SELECT id FROM users);
```

صف واحد، بلا كود. **بلا** `permissions_version` (لا علاقة لـRBAC) و**بلا**
محفّزات (الموجودة على `user_roles` و`role_permissions` فقط، فلا معنى لإزاحتها).

### سجل التدقيق

`Audit::log('EVALUATIONS_RELINKED_TO_SYSADMIN', null, 'evaluations', {...})`
→ السجل **id=1018**، `entity_id=null`، و`details` فيها `count=9` ومعرّفات
الصفوف التسعة وقيمها القديمة.

### اكتشافان أثناء التنفيذ

**1) نسخة الاحتياطية الأولى تالفة — الفخ نفسه المسجَّل في §2.2.**

أُنشئت بإعادة توجيه PowerShell (`>`)، فتحوّل مخرج `mysqldump` من UTF-8 إلى
UTF-16 ومرّ النص بترميز الطرفية: **123** علامة استفهام و**صفر** محارف عربية —
نسخة غير صالحة للاسترجاع لبيانات عربية.

| | النسخة الأولى | الصحيحة |
|---|---|---|
| حجم | 1,957,478 بايت | **977,591 بايت** |
| محارف عربية | **0** | **80,399** |
| `?` | **123** | 123 (أصلية في البيانات) |
| أول 3 بايت | `FF FE 2D` (UTF-16) | `2D 2D 20` (`-- `) |

الإصلاح: `mysqldump --result-file=...` — كتابة ثنائية مباشرة بلا أنبوب ولا
وسيط. **التحقق:** استرجاع على قاعدة مؤقتة أعاد 41 جدولًا و50 صف `evaluations`
بلا خطأ. النسخة الصحيحة مُختبَرة، لا مفترضة.

**2) `rollback.sql` الأول يفشل فعليًا بخطأ `1452`.**

القيد `eval_fk_creator` من نوع `RESTRICT` يرفض إرجاع القيم إلى
`7/8/11/12/16` لأنها لم تعد موجودة. النسخة الأولى لم تكن قابلة للتنفيذ.

الإصلاح: `SET FOREIGN_KEY_CHECKS = 0` قبل التراجع و`= 1` بعده.
**اختبار فعلي** على قاعدة مؤقتة:

| القياس | القيمة المتوقعة | النتيجة |
|---|---|---|
| يتيمة بعد التراجع | 9 | **9** ✓ |
| `created_by = 1` | 38 | **38** ✓ |
| الإجمالي | 50 | **50** ✓ |
| القيم التسعة | مطابقة لـCSV | **مطابقة واحدًا واحدًا** ✓ |

### تصحيح التسمية

اللقطة الكاملة باسم `db_after_fix.sql` لا `db_before.sql`: أُعيد إنشاؤها **بعد**
الترحيل. **الرجوع المرجعي = `rollback.sql` + `orphan_evaluctions_before.csv`.**

### نسخة الرجوع

`_emergency/rollback/CD-007/2026-10-06/OOS-9/`
— `rollback.sql` (مُختبَر) · `orphan_evaluations_before.csv` (9 صفوف) ·
`all_evaluations_created_by_before.csv` (50 صفًا) · `db_after_fix.sql`

### الاختبارات

بلا تغيير كود. `tests/runner.php` = **92/92** · فشل 0 · أخطاء 0 · `exit=0`.

---

---

## OOS-13 — تدقيق فشل `updateRole`

**الحالة: مُغلق**

### السبب

`UserController::updateRole` كان يفشل بصمت بلا أثر قابل للتتبّع: عند إرسال
`role_id` غير موجود كان `User::updateRole` يُرجع `false` بعد rollback (سلوك
المودل معياري ومقصود منذ البند 9)، والمتحكّم يكتفي برسالة عامة. **القياس
قبل:** `SELECT COUNT(*) FROM audit_logs WHERE action='USER_ROLE_UPDATE_FAILED'`
= **0**.

### الإصلاح (في المتحكّم فقط — لا تعديل على `User::updateRole`)

```
try {
    if ($userModel->updateRole($userId, $roleId)) {
        // النجاح: USER_ROLE_UPDATE (القيم القديمة/الجديدة) كما كان
        ...
    } else {
        Audit::log('USER_ROLE_UPDATE_FAILED', $userId, 'users', [
            'role_id' => (int)$roleId,
            'reason'  => 'invalid_role_or_transaction_failed',
        ]);
        Flash::set('تعذّر تحديث دور المستخدم: الدور المحدد غير موجود.', 'danger');
    }
} catch (Exception $e) {
    Audit::log('USER_ROLE_UPDATE_FAILED', $userId, 'users', [
        'role_id' => (int)$roleId,
        'error'   => $e->getMessage(),
    ]);
    throw $e;
}
```

الشكل **موقّعي** (`log($action, $entity_id, $entity_type, $details)`) —
الدرس المستخرج من OOS-1.

### القياس

| المعيار | قبل | بعد |
|---|---|---|
| `USER_ROLE_UPDATE_FAILED` بعد فشل | 0 | **1** |
| `USER_ROLE_UPDATE` بعد فشل | — | بلا تغيير (7) |
| `USER_ROLE_UPDATE` بعد نجاح (ضبط موجب) | — | +1 (7 → 8) |
| `USER_ROLE_UPDATE_FAILED` بعد نجاح | — | 0 |

**فحص `details` الفعلي:** `{"role_id":999,"reason":"invalid_role_or_transaction_failed"}`
· الدور لم يُسنَد فعلًا (`user_roles` للمستهدف = 0) · **Flash واضحة:** `danger`
مع «تعذّر تحديث دور المستخدم: الدور المحدد غير موجود.» · ضبط موجب: الدور أُسند
(id=167) وFlash `success`.

### الاختبارات

اختبار جديد `testUpdateRoleFailureAuditLog` في
`tests/cases/Controllers/UserControllerTest.php` (بالعملية الفرعية لأن المتحكّم
ينتهي بـ`exit()`): `_FAILED`=1 بالتفاصيل، `USER_ROLE_UPDATE`=0 للمستهدف عند
الفشل. **93/93** · فشل 0 · أخطاء 0.

### نسخة الرجوع

`_emergency/rollback/CD-007/2026-10-12/OOS-13/`
— `UserController.pre-item13.php` · `User.pre-item13.php` (لا rollback DB —
لا ترحيل). الاسترجاع: إعادة الملفين + commit عكسي.

---

## OOS-18 — تجاوز `isAdmin()` في فحص الصلاحيات

**الحالة: مفتوح** — مُسجَّل هنا، ويُعالَج في **CD-008** بعد CP5.

`app/Core/Auth.php:88` — أي فحص صلاحية يُرجع `true` لأي مستخدم يحمل دور `Admin`
بغض النظر عن `role_permissions`.

**الأثر:** كل بنود OOS-2..7 (تسلسل الأدوار، مجموعات الصلاحيات، القوالب، العمليات
الجماعية، تقارير A2، `invited` + 2FA + NIST) تعتمد على دقة هذا الفحص.

**لماذا مؤجل:** بند **معماري** لا إصلاحًا سريعًا. إزالته تُبطل سلوكيات كثيرة
اعتمدت عليه بالصدفة؛ يحتاج تصميمًا وترتيب إعادة اختبار.

**القرار:** لا تعديل الآن على نطاق OOS-1. سُجّل رسميًا في
`CD-006_OUT_OF_SCOPE.md`.

---

## سجل الإغلاق

| التاريخ | البند | القرار | الدليل |
|---|---|---|---|
| 2026-10-06 | المرحلة 0 | معتمد | `de88f71` |
| 2026-10-06 | تصحيح عدد الملفات | معتمد | `e734501` |
| 2026-10-06 | **OOS-1** | **مُغلق** | `8ba0100` · 92/92 |
| 2026-10-06 | **OOS-9** | **مُغلق** | `d5646bb` · يتيمة 9→0 · Audit 1018 |
| 2026-10-12 | **OOS-13** | **مُغلق** | `fix(OOS-13)` · `_FAILED` 0→1 · 93/93 |

**البنود المتبقية:** `OOS-10` · `OOS-11` · `OOS-12` ·
`OOS-2…7` · **OOS-18** (CD-008) · ودراسة A3.