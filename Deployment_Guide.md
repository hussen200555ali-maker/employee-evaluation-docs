# دليل النشر (Deployment Guide) — نظام تقييم الموظفين

**الإصدار:** `v0.1.0-pilot` · **التاريخ:** 2026-10-21
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
`dompdf` · `mpdf` · `tcpdf` · `phpoffice/phpspreadsheet` · `khaled.alshamaa/ar-php`

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
**السيناريو أ — استيراد نسخة العرض التجريبي (تتضمن البنية التأسيسية جاهزة):**
```bash
mysql -u root -p employee_evaluation_mvc < employee_evaluation_mvc_pilot.sql
```
**السيناريو ب — تثبيت نظيف:** استورد مخطط البنية (الجداول + العروض + الفهارس) من أحدث نسخة `mysqldump` للبنية، ثم طبّق ملفات الهجرة بالترتيب الزمني من `database/migrations/` (أهمها: `2026_10_19_CD008_reporting_views_fixed.sql` للعروض الثلاثة، و`2026_10_20_CD011_reporting_indexes.sql` للفهارس).

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
4. طبّق ملفات الهجرة الجديدة بالترتيب الزمني.
5. امسح مؤقتات mPDF الاختيارية: `app/storage/temp/mpdf/` (تُعاد بناؤها تلقائياً).

---

## 4) النسخ الاحتياطي والاسترجاع
- من الواجهة: *الإعدادات → النسخ الاحتياطي* (صلاحية `backup.manage`).
- يدوياً: `mysqldump -u root -p --single-transaction --routines --triggers employee_evaluation_mvc > backup.sql`
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

## 6) الحد التقني المعروف (OOS-20) — لأداء التقارير

**الوصف:** عرض التقارير `vw_evaluation_facts` مبنيّ على **مستوى الإجابة** (كل صف = إجابة معيار). هذا مثالي للاستعلامات **المفلترة** (فرع/قسم/سنة/قالب)، ويعمل في **1–11 ms** على حجم البيانات الحالي.

**الحد:** التجميعات **غير المفلترة** فوق حجم كبير جداً (اختُبر عند 500,000 صف) تحتاج ~3 ثوانٍ (فوق حد SLA البالغ 2 ثانية). الاستعلامات المفلترة بقيت دون الحد عبر فهارس CD-011.

**الأثر العملي:** منخفض جداً في المرحلة التجريبية (حجم بيانات واقعي صغير، والمستخدمون يطبّقون فلاتر غالباً).

**الحل المؤجّل (`OOS-20` — مستهدف `v0.2.0`):** إضافة طبقة **Query-result Cache** (مفتاح = الاستعلام + المعاملات، TTL قصير، وإبطال عند كتابة تقييم) أو عرض تجميع مسبق. لم يُنفَّذ الآن تجنّباً لمخاطر البيانات القديمة (Stale Data) قبل تسليم العميل الأول. التفاصيل في `Deferred_to_Post_Launch.md`.

---

## 7) قائمة تحقق ما قبل التسليم (Go-Live Checklist)
- [ ] PHP 8.2 + كل الإضافات المفعّلة.
- [ ] `composer install --no-dev` ناجح.
- [ ] قاعدة البيانات منشأة ومستوردة بالعروض الثلاثة والفهارس.
- [ ] `config/database.php` مضبوط.
- [ ] Document Root = `public/`.
- [ ] `storage/` و`storage/logs/` قابلة للكتابة.
- [ ] HTTPS مفعّل و`cookie_secure=1`.
- [ ] كلمة مرور `sysadmin` مغيّرة.
- [ ] نسخة احتياطية أولى مأخوذة.
- [ ] تشغيل `php tests/runner.php` = نجاح (للتأكد من سلامة البيئة).

*نهاية دليل النشر.*
