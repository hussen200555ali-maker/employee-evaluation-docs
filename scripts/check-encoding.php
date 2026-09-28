<?php
/**
 * فحص ترميز مستندات التسليم — البند 11-b / الخطوة 4 (CD-006)
 *
 * الاستخدام:
 *   php scripts/check-encoding.php                 # فحص النطاق الافتراضي
 *   php scripts/check-encoding.php <file> [<file>]# فحص ملفات محددة
 *
 * النطاق الافتراضي: CD-001_delivery/*.md + CHANGELOG.md (مستند التسليم).
 *
 * مجموعة الكشف (كما اعتمدها المستشار):
 *   CJK      U+4E00–U+9FFF
 *   Kana     U+3040–U+30FF
 *   Hangul   U+AC00–U+D7AF
 *   Cyrillic U+0400–U+04FF
 * + التحقق من صلاحية UTF-8.
 *
 * خارج النطاق بحكم القرار: محرف الاستبدال U+FFFD (فجوة معروفة موثّقة في CP3).
 *
 * المخرجات: 0 = نظيف، 1 = تسرّب.
 *
 * التشغيل على ويندوز:  C:\xampp\php\php.exe scripts\check-encoding.php
 * أو عبر متغيّر البيئة PHP_BIN، أو `php` إن كان في PATH.
 */

declare(strict_types=1);

$repoRoot = dirname(__DIR__); // مستودع التسليم
$delivery = dirname($repoRoot); // جذر المشروع

/** مجموعة المحارف الممنوعة. */
const FORBIDDEN_RANGES = [
    'CJK'      => ['\x{4E00}', '\x{9FFF}'],
    'Kana'     => ['\x{3040}', '\x{30FF}'],
    'Hangul'   => ['\x{AC00}', '\x{D7AF}'],
    'Cyrillic' => ['\x{0400}', '\x{04FF}'],
];

/** @return array<int,string> المسارات المفحوصة */
function targetFiles(array $argv, string $repoRoot, string $delivery): array
{
    $explicit = array_slice($argv, 1);
    if ($explicit !== []) {
        $out = [];
        foreach ($explicit as $p) {
            $abs = realpath($p);
            if ($abs === false || !is_file($abs)) {
                fwrite(STDERR, "  ! ملف غير موجود: $p\n");
                continue;
            }
            $out[] = $abs;
        }
        return $out;
    }

    $files = glob($repoRoot . '/*.md') ?: [];
    // CHANGELOG.md في جذر التطبيق مشمول صراحةً (وهو موقع التلف التاريخي)
    $rootChangelog = $delivery . '/CHANGELOG.md';
    if (is_file($rootChangelog)) {
        $files[] = $rootChangelog;
    }
    return $files;
}

$files = targetFiles($argv, $repoRoot, $delivery);
if ($files === []) {
    fwrite(STDERR, "لا توجد ملفات للفحص.\n");
    exit(2);
}

echo "فحص ترميز مستندات التسليم — البند 11-b\n";
echo "المجموعة: CJK + Kana + Hangul + Cyrillic (U+FFFD خارج النطاق بحكم القرار)\n";
echo str_repeat('-', 62) . "\n";

$leaks = 0;
$lines = 0;

foreach ($files as $file) {
    $text = @file_get_contents($file);
    if ($text === false) {
        fwrite(STDERR, "  ! تعذّرت القراءة: $file\n");
        $leaks++;
        continue;
    }

    $problems = [];

    if (!mb_check_encoding($text, 'UTF-8')) {
        $problems[] = 'الملف ليس UTF-8 صالحًا';
    }

    $fileLines = file($file, FILE_IGNORE_NEW_LINES);
    if ($fileLines === false) {
        $fileLines = [];
    }

    foreach ($fileLines as $n => $line) {
        $lines++;
        foreach (FORBIDDEN_RANGES as $label => [$from, $to]) {
            $rx = '/[' . $from . '-' . $to . ']/u';
            if (preg_match_all($rx, $line, $m) && $m[0] !== []) {
                $uniq = array_values(array_unique($m[0]));
                $cp = array_map(static fn($c) => 'U+' . strtoupper(dechex(mb_ord($c, 'UTF-8'))), $uniq);
                $problems[] = sprintf(
                    'سطر %d [%s]: %s',
                    $n + 1,
                    $label,
                    implode(' ', $cp)
                );
            }
        }
    }

    $rel = str_replace(['\\', '/'], '/', $file);
    $rel = preg_replace('#^.*/employee-evaluation/#', '', $rel);

    if ($problems === []) {
        printf("  [نظيف]  %-46s %d سطر\n", $rel, count($fileLines));
    } else {
        printf("  [تسرّب] %s\n", $rel);
        foreach ($problems as $p) {
            echo "            - $p\n";
            $leaks++;
        }
    }
}

echo str_repeat('-', 62) . "\n";
printf("فُحص %d ملفًا / %d سطرًا — التسرّب: %d\n", count($files), $lines, $leaks);

if ($leaks === 0) {
    echo "النتيجة: نظيف ✔\n";
    exit(0);
}

echo "النتيجة: تسرّب محارف ممنوعة ✘\n";
exit(1);
