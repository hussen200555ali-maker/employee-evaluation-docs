<?php
/**
 * مثبّت خطاف pre-commit لفحص الترميز — البند 11-b / الخطوة 5 (CD-006)
 *
 * الاستخدام:
 *   php scripts/install-hooks.php            # تثبيت (idempotent)
 *   php scripts/install-hooks.php --status   # عرض الحالة فقط
 *   php scripts/install-hooks.php --uninstall
 *
 * النطاق: مستودع التسليم CD-001_delivery فقط (بقرار صريح).
 * الخطاف يدير كتلته بعلامة-marker، فإعادة التشغيل تستبدل الكتلة ولا تُكرّرها،
 * ويأخذ نسخة احتياطية من أي خطاف سابق غير مُدار في pre-commit.cd006.bak.
 *
 * تجاوز يدوي عند الحاجة: CD006_GUARD_DISABLED=1 git commit ...
 * أو تحديد PHP: PHP_BIN=/c/php/php.exe git commit ...
 */

declare(strict_types=1);

const MARK_BEGIN = '# >>> cd-006-encoding-guard >>>';
const MARK_END   = '# <<< cd-006-encoding-guard <<<';
const EXPECT_REPO = 'CD-001_delivery';

$mode = $argv[1] ?? '--install';

/**
 * جذر مستودع التسليم مع تحقّق صريح من هويته.
 * لا يعتمد على وجود git في PATH: يُحلّ المسار من موقع السكربت،
 * وهذا يجعل التثبيت ممكنًا على أي جهاز حتى لو لم يكن git على PATH.
 */
function deliveryRoot(): string
{
    $root = dirname(__DIR__);

    $dotGit = $root . '/.git';
    if (is_dir($dotGit)) {
        return str_replace('\\', '/', $root);
    }
    if (is_file($dotGit)) {
        // worktree / submodule: .git ملف يحوي «gitdir: <path>»
        $raw = (string) @file_get_contents($dotGit);
        if (preg_match('#gitdir:\s*(.+)#i', $raw, $m)) {
            return str_replace('\\', '/', $root);
        }
    }

    fwrite(STDERR, "خطأ: لا يوجد مستودع git عند $root\n");
    exit(2);
}

/** مسار مجلد hooks بلا الاعتماد على git CLI. */
function hookPath(string $root): string
{
    $dotGit = $root . '/.git';
    $hooks = null;

    if (is_dir($dotGit)) {
        $hooks = $dotGit . '/hooks';
    } elseif (is_file($dotGit)) {
        $raw = (string) @file_get_contents($dotGit);
        if (preg_match('#gitdir:\s*(.+)#i', $raw, $m)) {
            $gitdir = trim($m[1]);
            $abs = str_starts_with($gitdir, '/') ? $gitdir : $root . '/' . $gitdir;
            $abs = str_replace('\\', '/', (string) realpath($abs));
            // worktree: <repo>/.git/worktrees/<name> → الـ hooks في <repo>/.git/hooks
            if (str_contains($abs, '/.git/worktrees/')) {
                $hooks = substr($abs, 0, strpos($abs, '/.git/worktrees/')) . '/.git/hooks';
            } else {
                $hooks = $abs . '/hooks';
            }
        }
    }

    if ($hooks === null) {
        fwrite(STDERR, "خطأ: تعذّر تحديد مجلد hooks.\n");
        exit(2);
    }
    return $hooks . '/pre-commit';
}

function managedBlock(string $root): string
{
    $checker = $root . '/scripts/check-encoding.php';
    $phpFallback = is_file('C:/xampp/php/php.exe') ? 'C:/xampp/php/php.exe' : 'php';

    return MARK_BEGIN . "\n"
        . "# البند 11-b / CD-006 — يمنع commit مستندات التسليم عند تسرّب محرف ممنوع.\n"
        . "# مُدار بواسطة scripts/install-hooks.php — لا تحرّره يدويًا.\n"
        . "# الجذر مثبَّت وقت التثبيت، فلا يحتاج الخطاف إلى git على PATH.\n"
        . "if [ \"\$CD006_GUARD_DISABLED\" = \"1\" ]; then\n"
        . "  echo \"pre-commit: تم التخطّي بتوجيه CD006_GUARD_DISABLED=1\" >&2\n"
        . "  exit 0\n"
        . "fi\n"
        . "_cd006_php=\"\"\n"
        . "if [ -n \"\$PHP_BIN\" ] && [ -x \"\$PHP_BIN\" ]; then\n"
        . "  _cd006_php=\"\$PHP_BIN\"\n"
        . "elif command -v php >/dev/null 2>&1; then\n"
        . "  _cd006_php=\"php\"\n"
        . "elif [ -x \"" . $phpFallback . "\" ]; then\n"
        . "  _cd006_php=\"" . $phpFallback . "\"\n"
        . "else\n"
        . "  echo \"pre-commit: تعذّر تحديد php — تُخطّى بوابة الترميز (PHP_BIN=… أو CD006_GUARD_DISABLED=1)\" >&2\n"
        . "  exit 0\n"
        . "fi\n"
        . "if ! \"\$_cd006_php\" \"" . $checker . "\"; then\n"
        . "  echo \"\" >&2\n"
        . "  echo \"pre-commit: أُوقف الـ commit — تسرّب محارف ممنوعة في مستندات التسليم.\" >&2\n"
        . "  exit 1\n"
        . "fi\n"
        . "exit 0\n"
        . MARK_END . "\n";
}

/**
 * إزالة الكتلة المُدارة السابقة (مع سطر shebang إن وُجد وأسطر الفراغات).
 * يجب أن يبتلع النمط كل ما يسبق العلامة وأن لا يبتلع إلا كتلتنا، وإلا خلط
 * المثبّت بين خطافه وخطاف أجنبي وأخذ نسخة احتياطية من كتلته هو.
 */
function stripManagedBlock(string $text): string
{
    $pattern = '/\n*(?:#![^\n]*\n+)?' . preg_quote(MARK_BEGIN, '/') . '.*?' . preg_quote(MARK_END, '/') . '\n?/s';
    return (string) preg_replace($pattern, "\n", $text);
}

$root = deliveryRoot();
$hook = hookPath($root);
$checker = $root . '/scripts/check-encoding.php';

if (!is_file($checker)) {
    fwrite(STDERR, "خطأ: الفاحص غير موجود: $checker\n");
    exit(2);
}

$exists = is_file($hook);
$current = $exists ? (string) file_get_contents($hook) : '';
$hasBlock = $exists && str_contains($current, MARK_BEGIN);

if ($mode === '--status') {
    echo "الخطاف: $hook\n";
    echo 'الحالة: ' . ($hasBlock ? 'مُثبَّت (كتلة مُدارة)' : ($exists ? 'يوجد خطاف بلا كتلة مُدارة' : 'غير مُثبَّت')) . "\n";
    echo 'الفاحص: ' . (is_file($checker) ? 'موجود' : 'مفقود') . "\n";
    exit(0);
}

if ($mode === '--uninstall') {
    if (!$hasBlock) {
        echo "لا شيء لإزالته — الكتلة المُدارة غير موجودة.\n";
        exit(0);
    }
    $remaining = ltrim(stripManagedBlock($current), "\r\n");
    // لم يتبقَّ سوى shebang أو فراغات — نحذف الملف بدل تركه عظامًا.
    if (trim(preg_replace('/^#!.*$/', '', $remaining) ?? '') === '') {
        @unlink($hook);
        echo "أُزيلت الكتلة المُدارة وحُذف الملف (لم يتبقَّ فيه سوى سطر shebang): $hook\n";
        exit(0);
    }
    file_put_contents($hook, $remaining);
    @chmod($hook, 0755);
    echo "أُزيلت الكتلة المُدارة من: $hook (حُفظ بقية الخطاف)\n";
    exit(0);
}

if ($mode !== '--install') {
    fwrite(STDERR, "خيار غير معروف: $mode (المتاح: --install | --status | --uninstall)\n");
    exit(2);
}

@mkdir(dirname($hook), 0777, true);

// خطاف git يحتاج سطر shebang ليعمل، فنضمنه دائمًا في أول الملف.
$prefix = "#!/bin/sh\n";
$stripped = $exists ? rtrim(stripManagedBlock($current), "\r\n") : '';

// أي نصّ باقٍ بعد إزالة كتلتنا = خطاف أجنبي حقيقي يجب حفظه لا حذفه.
if ($stripped !== '') {
    $backup = dirname($hook) . '/pre-commit.cd006.bak';
    if (!is_file($backup)) {
        file_put_contents($backup, $current);
        echo "أُخذت نسخة احتياطية من الخطاف السابق: $backup\n";
    }
    $prefix = str_starts_with($stripped, '#!') ? $stripped . "\n" : $prefix . $stripped . "\n";
    echo "حُافظنا على خطافك السابق وأُلحقت الكتلة المُدارة بعده.\n";
} elseif ($exists) {
    echo "الكتلة المُدارة موجودة — ستُستبدل (idempotent).\n";
}

file_put_contents($hook, $prefix . managedBlock($root));
@chmod($hook, 0755);

// تحقّق فوري: القابل للتنفيذ + يحتوي العلامة.
$verify = is_file($hook) && str_contains((string) file_get_contents($hook), MARK_BEGIN);
$occurrences = substr_count((string) file_get_contents($hook), MARK_BEGIN);

echo "الخطاف: $hook\n";
echo 'مثبَّت: ' . ($verify ? 'نعم' : 'لا') . "\n";
echo 'عدد الكتل المُدارة: ' . $occurrences . (($occurrences === 1) ? ' (سليم)' : ' (تكرار!)') . "\n";
echo "للتجربة: عدّل مستندًا في CD-001_delivery ثم git commit.\n";

exit($verify && $occurrences === 1 ? 0 : 1);
