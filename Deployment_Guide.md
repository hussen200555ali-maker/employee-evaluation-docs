# دليل النشر (Deployment Guide) — نظام تقييم الموظفين

**الإصدار:** `v1.1.0` · **التاريخ:** 2026-11-03
**الجمهور:** مهندس النشر / مدير النظام لدى العميل
**الجمهور التقني:** تثبيت النظام على خادم العميل (On-Premise).

---

## 1) المتطلبات التقنية

| المكوّن | الحد الأدنى | المُختبر/الموصى به |
|---|---|---|
| نظام التشغيل | Windows Server / Linux | Windows (XAMPP) أو Linux (LAMP) |
| خادم الويب | Apache 2.4+ (مع `mod_rewrite`) | Apache 2.4 |
| PHP | 8.1+ | **8.2.x** |
| قاعدة البيانات | MariaDB 10.4+ / MySQL 8.0+ | **MariaDB 10.4.32** |
| الذاكرة (RAM) | 2 GB | 4 GB+ |

### إضافات PHP الإلزامية
`pdo_mysql` · `mbstring` · `gd` · `zip` · `dom` · `xml` · `intl` · `openssl` · `fileinfo` · `curl` · `iconv` · `json`

### حزم Composer (تُثبَّت عبر `composer install`)
`dompdf` · `mpdf` · `tcpdf` · `phpoffice/phpspreadsheet` · `phpoffice/phpword` · `khaled.alshamaa/ar-php`

---

## 2) خطوات التثبيت

### 2.1 نسخ ملفات المشروع
```bash
# على Linux
sudo mkdir -p /var/www/employee-evaluation
sudo cp -r ./employee-evaluation/* /var/www/employee-evaluation/
sudo chown -R www-data:www-data /var/www/employee-evaluation/storage
sudo chmod -R 775 /var/www/employee-evaluation/storage
```
> على Windows/XAMPP: يُنسخ المشروع إلى `C:\xampp\htdocs\employee-evaluation`.

### 2.2 تثبيت الاعتماديات
```bash
composer install --no-dev --optimize-autoloader
```

### 2.3 إنشاء قاعدة البيانات
```sql
CREATE DATABASE employee_evaluation_mvc
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2.4 استيراد المخطط والبيانات
**السيناريو أ — استيراد نسخة قاعدة بيانات معتمدة:**
```bash
mysql -u root -p employee_evaluation_mvc < employee_evaluation_mvc_pilot.sql
```
**السيناريو ب — تثبيت نظيف:** افتح `public/setup.php` (على XAMPP: `http://localhost/employee-evaluation/public/setup.php`) واتبع الخطوات الأربع. أدخل قاعدة بيانات جديدة وفارغة؛ يرفض المعالج أي قاعدة تحتوي جداول أو عروضاً. يستورد `setup/install_schema.sql` و`setup/install_seeds.sql`، ثم ينشئ حساب المدير ويضبط `config/database.php`. الحساب الأولي مطالب بتغيير كلمة المرور عند أول دخول، ويمنع `config/installed.lock` تشغيل المعالج مرة أخرى.

ملفا التثبيت يحتويان المخطط والبذور النظامية فقط، ولا يحتويان مستخدمين أو موظفين أو تقييمات. **لا تستخدم نسخة قاعدة البيانات الكاملة المحلية كملف تثبيت أو توزعها.** ملفات `setup/` و`database/` و`config/` محجوبة عن الوصول المباشر عبر Apache؛ أبقِ هذه الحماية مفعّلة. على خادم الويب، يظل توجيه Document Root إلى `public/` هو الخيار الموصى به.

### 2.5 ضبط الإعدادات
عدّل `config/database.php`:
```php
define('DB_HOST', 'localhost');
define('DB_USER', 'اسم_مستخدم_قاعدة_البيانات');
define('DB_PASS', 'كلمة_المرور');
define('DB_NAME', 'employee_evaluation_mvc');
define('DB_CHARSET', 'utf8mb4');
```
> `config/config.php` يكتشف `APP_URL` تلقائياً؛ لا حاجة لتعديله إلا إن كان النظام خلف Reverse Proxy (اضبط `Trusted Proxies` آنذاك).

### 2.6 ضبط جذر الويب (Document Root)
وجّه Document Root إلى مجلد `public/` — **وليس** جذر المشروع (لإخفاء `app/` و`config/` و`vendor/`).
```
DocumentRoot "/var/www/employee-evaluation/public"
<Directory "/var/www/employee-evaluation/public">
    AllowOverride All
    Require all granted
</Directory>
```
> على XAMPP المحلي يكفي رابط `http://localhost/employee-evaluation/public`.

### 2.7 الصلاحيات
```
storage/            -> قابلة للكتابة (سجلات، نسخ احتياطي، مؤقتات)
storage/logs/       -> قابلة للكتابة (php-error.log)
public/uploads/     -> قابلة للكتابة (إن وُجد رفع ملفات)
```

---

## 3) الترقية (Upgrade)
1. نسخة احتياطية كاملة لقاعدة البيانات + مجلد `storage/`.
2. اسحب الإصدار الجديد (`git fetch && git checkout <tag>`).
3. `composer install --no-dev` إن تغيّرت الاعتماديات.
4. طبّق ملفات الهجرة الجديدة بالترتيب الزمني، بما فيها هجرة اللقطات الثابتة عند الترقية إلى v1.1.0.
5. امسح مؤقتات mPDF الاختيارية: `app/storage/temp/mpdf/` (تُعاد بناؤها تلقائياً).

---

## 4) النسخ الاحتياطي والاسترجاع
- من الواجهة: *الإعدادات → النسخ الاحتياطي* (صلاحية `backup.manage`).
- يدوياً: `mysqldump -u root -p --single-transaction --routines --triggers --result-file="backup.sql" employee_evaluation_mvc`
- الاسترجاع: `mysql -u root -p employee_evaluation_mvc < backup.sql`

---

## 5) الأمان في الإنتاج
| البند | الإجراء |
|---|---|
| HTTPS | فعّل TLS ثم اضبط `session.cookie_secure = 1` في `config/config.php:50`. |
| كلمة مرور `sysadmin` | **غيّرها فوراً** عند أول دخول. |
| مستخدمو قاعدة البيانات | أنشئ مستخدماً مخصّصاً بصلاحيات محدودة بدل `root`. |
| إظهار الأخطاء | `config/config.php` مضبوط بالفعل على `display_errors=0` (`DEBUG_MODE=false`). |
| المسارات الحساسة | احمِ `app/` و`config/` و`vendor/` خارج جذر الويب (راجع 2.6). |
| نسخ احتياطي مجدول | فعّل النسخ اليومي عبر Cron/مهمة مجدولة. |

---

## 6) تقارير الموظفين والتنبيهات المعروفة

- تقارير v1.1.0 تُنشأ من ملف الموظف وتحفظ كنسخ ثابتة؛ لا يمكن تعديل اللقطة أو حذفها. تُنتج ملفات PDF وExcel وWord من النسخة المحفوظة.
- أزيلت في CD-015 منظومة التقارير الإدارية القديمة وعروضها؛ لا تعتمد إجراءات النشر على `vw_evaluation_facts` أو العروض القديمة.
- **OOS-21:** إصدار PhpSpreadsheet المقفل قد يتأثر بثلاثة تنبيهات أمنية موثقة في `Deferred_to_Post_Launch.md`. وفق قرار Pilot، لا تُحدّث الحزمة ضمن هذا الإصدار؛ الترقية والتدقيق مخططان لـ `v0.2.0`.

---

## 7) قائمة تحقق ما قبل التسليم (Go-Live Checklist)
- [ ] PHP 8.2 + كل الإضافات المفعّلة.
- [ ] `composer install --no-dev` ناجح.
- [ ] قاعدة البيانات منشأة، والهجرات المطلوبة مطبقة بالترتيب، بما فيها هجرة CD-018 للقطات.
- [ ] `config/database.php` مضبوط.
- [ ] Document Root = `public/`.
- [ ] `storage/` و`storage/logs/` قابلة للكتابة.
- [ ] HTTPS مفعّل و`cookie_secure=1`.
- [ ] كلمة مرور `sysadmin` مغيّرة.
- [ ] نسخة احتياطية أولى مأخوذة.
- [ ] تشغيل `php tests/runner.php` = نجاح (للتأكد من سلامة البيئة).
- [ ] تنفيذ UAT v1.1.0 وتوثيق الاعتماد قبل إطلاق النسخة.

*نهاية دليل النشر.*
