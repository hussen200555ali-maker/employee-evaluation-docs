# CD-004 — المرحلة 5: نسخة احتياطية كاملة ومسارات التراجع

**التاريخ:** 2026-09-21 | **المعتمد:** كبير المستشارين (إذن المرحلة 5 كاملة)

## 1) ما تُحمى هنا

| المكوّن | المسار | الحجم / ملاحظات |
|---|---|---|
| نسخة DB كاملة (mysqldump) | `storage/backups/CD-004/phase5/employee_evaluation_mvc_phase5.sql` | كاملة (من ضمنها رويتينات + مشغّلات + أحداث) — 944,479 بايت |
| نسخة كود اجتراف قبل المرحلة 5 | `storage/backups/CD-004/phase5/code/` | `app/ config/ routes/ public/ cron/ database/ tests/(bootstrap,runner,lib)` + `CD-004_IMPLEMENTATION.md` + `CD-004_Execution_Plan.md` + `CD-004_OUT_OF_SCOPE.md` + `CHANGELOG.md` |

> ملاحظة: `vendor/` مستبعدة (تُعاد عبر `composer install`)، و`storage/logs` و`backups` مستثناة لتجنّب التداخل.

## 2) بيانات الاختبار (قابلة للإنشاء والإزالة)

| الوصف | الملف |
|---|---|
| إنشاء بيانات المرحلة 5 (6 مستخدمين + 10 موظفين + تعيين أدوار) | الجذر: `temp/phase5_seed.sql` (و`CD-001_delivery/phase5/Phase5_Test_Users.md` يوثّق الحسابات) |
| إزالة بيانات المرحلة 5 بالكامل | `temp/phase5_cleanup.sql` |

علامات التمييز للكشف/الإزالة: أسماء المستخدمين `test_`…، رموز الموظفين `P5-EMP-%`. تُستخدم **3 فروع و7 أقسام** البنية الرسمية الحية نفسها (لا تُنشأ فروع/أقسام جديدة).

## 3) مسارات التراجع (Restore Paths)

1. **تراجع قاعدة البيانات:** `mysql -u root employee_evaluation_mvc < storage/backups/CD-004/phase5/employee_evaluation_mvc_phase5.sql` (تستعيد حالة ما قبل المرحلة 5؛ يُفضَّل DROP database + CREATE + استيراد للتخلّص من أي بقايا).
2. **تراجع الكود:** استبدال أي ملف ملموس بنسخته من `storage/backups/CD-004/phase5/code/` (clone of جذر المشروع) — التطبيق لا git.
3. **الوثائق (حزمة CD-001):** `CD-001_delivery` مستودع git → `git revert <commit>` أو `git reset` للـ commits الخاصة بالمرحلة 5 (`Phase5_*.md`).
4. **بيانات الاختبار:** تشغيل `temp/phase5_cleanup.sql` يزيل المستخدمين/الموظفين/تعيينات الأدوار/الإشعارات/سجلات الدخول المرتبطة (نمط TEMP جدول لتجنّب ERROR 1442 مع مشغّلات بند 8).
5. **قاعدة الاسترجاع (من خطة CD-004 §5):** استرجاع كامل للمرحلة خلال يوم العمل إذا فشل اختبار القبول/الانحدار؛ متابعة من آخر نقطة اعتماد.

## 4) ضبط قبل التنفيذ
- Apache + MySQL على XAMPP (جذر التطبيق `<xampp>/htdocs/employee-evaluation`)، الوصول الحي: `http://localhost/employee-evaluation/`.
- مُستخدمو البذور جاهزون (راجع `Phase5_Test_Users.md`).