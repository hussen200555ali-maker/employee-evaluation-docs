# الوثيقة 10 — الأداء والنسخ الاحتياطي وواجهة API

| بند | البيان |
|---|---|
| **اسم الوثيقة** | الأداء والنسخ الاحتياطي وواجهة API |
| **الإصدار** | v1.0 |
| **التاريخ** | 2026-09-15 |
| **مُعدّ الوثيقة** | كبير المطورين |
| **حالة الاعتماد** | قيد الاعتماد |
| **مرجع الإعداد** | التوجيه الاستشاري CD-001 |

---

## 1. النسخ الاحتياطي

### أنواع النسخ
| النوع | المسار | الوصف |
|---|---|---|
| كامل | `backup/full` | SQL كامل مضغوط gz |
| تزايدي | `backup/incremental` | تزايدي منذ آخر نسخة |
| محسّن | `backup/optimized` | ضغط/تحسين |
| ذكي | `backup/smart` | مزيج وفق الإعدادات |

### المكونات البرمجية
| الكلاس | الدور |
|---|---|
| `BackupManager` | التنفيذ والتخزين والتحميل والاستعادة |
| `BackupEncryption` | **AES-256-GCM** (توليد مفاتيح وإدارتها) |
| `BackupMonitor` | مراقبة الصحة والقرص |
| `BackupOptimizer` | تحسين الحجم/الفهرس |
| `BackupScheduler` (+`_fixed`) | جدولة دورية (cron CLI) |
| `BackupLog` / `BackupSetting` | السجل والإعدادات |

### واجهات
- لوحات: `backup/dashboard` (pro)، `backup/settings` + `settings/save`.
- صحة: `backup/verify`, `backup/health`, `backup/health/reports`, `backup/check-disk`.
- تشفير: `backup/encryption`, `generate-key`, `keys`, `delete-key`.
- جدولة: `scheduler-status`, `setup-scheduler`, `remove-scheduler`, `test-scheduler`.
- API: `api/backup/stats`, `api/backup/progress/:id`, `api/backup/quick-action`.

### أرقام حية
| الجدول | الصفوف |
|---|---|
| `backup_logs` | 3 |
| `backup_health_logs`, `backup_settings`, `backup_encryption_keys` | موجودة |
| الملفات الفعلية | `backups/*.sql.gz` (آخرها 2026-09-01/02) |

> **ملاحظة أمنية:** مجلد `backups/` يقع داخل جذر الويب ويُحمَّل عبر مسار عام — انظر وثيقة 13.

---

## 2. واجهة REST API (v1)

| المسار | الوظيفة |
|---|---|
| `api/v1/health` | فحص صحة الخدمة |
| `api/v1/employees` (+`:id`) | قائمة/تفاصيل الموظف |
| `api/v1/evaluations` (+`:id`) | قائمة/تفاصيل تقييم |

- **التأمين:** مصادقة عبر `X-API-Key` (نموذج `ApiKey`).
- **ملاحظة هجرات:** جدول `api_keys` خارج `db_live_schema.sql` (وثيقة 08/11).

---

## 3. وحدة التحليل والأداء (`AnalysisController` — 13 مسارًا)

| المجال | المسارات |
|---|---|
| لوحات | `analysis/dashboard`, `analysis/insights`, `analysis/index` |
| تقارير | `analysis/report`, `analysis/employee/:id` |
| تصدير | `analysis/export`, `export/excel`, `export/excel-employees`, `export/optimized` |
| طباعة PDF | `analysis/print`, `analysis/print/level`, `analysis/exportPdfWithCharts` |
| تخزين مؤقت | `analysis/cache/clear` |

- توليد PDF بالرسوم عبر `PdfReportBuilder` (+`pdf-export-enhancer.js`).
- تصميم Enterprise مع 4 KPIs لوحة سنوية (navy/gold) — `docs/ENTERPRISE_PERFORMANCE_VIEW.md`.

---

## 4. الأداء والضبط

| البند | القيمة/المرجع |
|---|---|
| حد الذاكرة | **2048M** (`config/config.php` — القيمة المعتمدة بند 6، بعد أن كانت 4096M) |
| مهلة التنفيذ | 600 ثانية |
| فهارس | `_emergency/perf_indexes.sql` (إضافات أداء) |
| اختبارات | `docs/Statistics_Performance_Testing_Report.md`، `heavy_queries_test.php`، `query_analyzer.php`، `realtime_monitor.php`، `stress_test_fixed.php`، `simple_memory_test_singleton.php` |

---

## 5. نِسَب الجاهزية (موجبة لوثيقة 03)

| الوحدة | % |
|---|---|
| النسخ الاحتياطي | ~90% |
| REST API | ~85% |
| التقارير (موحدة/إحصائية/إدارية) | ~85% |
| ملفات الأداء | ~85% |
| PDF التصدير | ~80% |

---

**نهاية الوثيقة 10 — الأداء والنسخ الاحتياطي وواجهة API**