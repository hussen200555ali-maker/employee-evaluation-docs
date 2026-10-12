<?php
/**
 * فحص ترميز مستندات التسليم — البند 11-b / الخطوة 4 (CD-006)
 *
 * الاستخدام:
 *   php scripts/check-encoding.php                 # فحص النطاق الافتراضي
 *   php scripts/check-encoding.php <path> [...]     # ملف/مجلد (يُوسَّع المجلد تكراريًا)
 *
 * النطاق الافتراضي: CD-001_delivery/*.md + CHANGELOG.md (مستند التسليم).
 * عند تمرير مجلد، تُجمع الملفات النصية داخله تكراريًا (بحسب الامتداد).
 *
 * مجموعة الكشف (كما اعتمدها المستشار):
 *   CJK      U+4E00–U+9FFF
 *   Kana     U+3040–U+30FF
 *   Hangul   U+AC00–U+D7AF
 *   Cyrillic U+0400–U+04FF
 *   U+FFFD   محرف الاستبدال — أُضيف في OOS-11 (كان خارج النطاق بحكم القرار)
 * + التحقق من صلاحية UTF-8.
 * + فحص BOM (إلزامي بلا استثناء — OOS-11):
 *   UTF-8 BOM (EF BB BF) · UTF-16 LE (FF FE) · UTF-16 BE (FE FF)
 *
 * الاستثناء الوحيد (allowlist): مكتبة طرف ثالث `app/Libraries/pChart/**`.
 *   - مجموعة U+FFFD/الترميز: تُعفى كل امتدادات pChart (طرف ثالث موثّق — 17 حالة).
 *   - فحص BOM: يُعفى داخل pChart للملفات **غير التنفيذية** فقط (.log/.txt/.md/…).
 *     ملفات pChart التنفيذية (.php) **لا تُعفى** من BOM (كارثية: headers already
 *     sent)؛ أي حالة تُدرَج ضمن OOS-12. (مُثبت: pChart .php خالية من BOM — OOS-11.)
 *
 * المخرجات: 0 = نظيف · 1 = تسرّب · 2 = خطأ استخدام.
 *
 * التشغيل على ويندوز:  C:\xampp\php\php.exe scripts\check-encoding.php
 * أو عبر متغيّر البيئة PHP_BIN، أو `php` إن كان في PATH.
 */

declare(strict_types=1);

$repoRoot = dirname(__DIR__); // مستودع التسليم
$delivery = dirname($repoRoot); // جذر المشروع

/** @var array<string,array{0:string,1:string}> مجموعات الكشف المحظورة */
const FORBIDDEN_RANGES = [
    'CJK'      => ['\x{4E00}', '\x{9FFF}'],
    'Kana'     => ['\x{3040}', '\x{30FF}'],
    'Hangul'   => ['\x{AC00}', '\x{D7AF}'],
    'Cyrillic' => ['\x{0400}', '\x{04FF}'],
    'FFFD'     => ['\x{FFFD}', '\x{FFFD}'],
];

/** مكتبة طرف ثالث موثّقة (CD-007 / OOS-11). */
const PCHART_DIR = 'app/Libraries/pChart/';

/**
 * امتدادات تنفيذية: BOM فيها كارثي (headers already sent)، فلا تُعفى أبدًا —
 * حتى داخل pChart. تُدرَج أي حالة BOM في pChart/`.php` ضمن OOS-12.
 */
const EXECUTABLE_EXTENSIONS = ['php', 'phtml', 'inc'];

/** امتدادات الملفات النصية عند توسيع المجلدات. */
const TEXT_EXTENSIONS = [
    'php', 'phtml', 'inc', 'md', 'txt', 'js', 'mjs', 'css', 'html', 'htm',
    'json', 'csv', 'log', 'cmd', 'bat', 'ps1', 'sql', 'yml', 'yaml', 'ini', 'xml',
];

/** @return bool هل الامتداد نصيًا؟ */
function isTextFile(string $path): bool
{
    return in_array(strtolower(pathinfo($path, PATHINFO_EXTENSION)), TEXT_EXTENSIONS, true);
}

/** @return string|null وصف BOM إن وُجد، وإلا null. */
function bomLabel(string $bytes): ?string
{
    if (strlen($bytes) >= 3 && substr($bytes, 0, 3) === "\xEF\xBB\xBF") {
        return 'UTF-8 BOM (EF BB BF)';
    }
    if (strlen($bytes) >= 2 && substr($bytes, 0, 2) === "\xFF\xFE") {
        return 'UTF-16 LE BOM (FF FE)';
    }
    if (strlen($bytes) >= 2 && substr($bytes, 0, 2) === "\xFE\xFF") {
        return 'UTF-16 BE BOM (FE FF)';
    }
    return null;
}

/** @return bool هل الملف داخل مكتبة pChart (طرف ثالث)? */
function isPchart(string $path): bool
{
    return str_contains(str_replace('\\', '/', $path), PCHART_DIR);
}

/**
 * إعفاء BOM: داخل pChart للملفات **غير التنفيذية فقط** (.log/.txt/.md/…).
 * ملفات pChart التنفيذية (.php) لا تُعفى من فحص BOM (شرط OOS-11 الإضافي).
 */
function isPchartBomAllowed(string $path): bool
{
    if (!isPchart($path)) {
        return false;
    }
    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    return !in_array($ext, EXECUTABLE_EXTENSIONS, true);
}

/** @return array<int,string> المسارات المفحوصة */
function targetFiles(array $argv, string $repoRoot, string $delivery): array
{
    $explicit = array_slice($argv, 1);
    if ($explicit !== []) {
        $out = [];
        foreach ($explicit as $p) {
            $abs = realpath($p);
            if ($abs === false) {
                fwrite(STDERR, "  ! مسار غير موجود: $p\n");
                continue;
            }
            if (is_dir($abs)) {
                $it = new RecursiveIteratorIterator(
                    new RecursiveDirectoryIterator($abs, FilesystemIterator::SKIP_DOTS)
                );
                foreach ($it as $f) {
                    if ($f->isFile() && isTextFile($f->getPathname())) {
                        $out[] = $f->getPathname();
                    }
                }
                continue;
            }
            if (is_file($abs)) {
                $out[] = $abs;
            }
        }
        sort($out);
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

echo "فحص ترميز المستندات/الملفات — البند 11-b\n";
echo "المجموعة: CJK + Kana + Hangul + Cyrillic + U+FFFD · وفحص BOM (UTF-8/UTF-16)\n";
echo str_repeat('-', 62) . "\n";

$leaks = 0;
$lines = 0;

foreach ($files as $file) {
    $raw = @file_get_contents($file);
    if ($raw === false) {
        fwrite(STDERR, "  ! تعذّرت القراءة: $file\n");
        $leaks++;
        continue;
    }

    $problems = [];

    // 1) فحص BOM. يُعفى داخل pChart للملفات غير التنفيذية فقط.
    $bom = bomLabel($raw);
    if ($bom !== null && !isPchartBomAllowed($file)) {
        $problems[] = 'BOM: ' . $bom;
    }

    // ملفات UTF-16 صالحة للكشف بالـBOM؛ فحص الأسطر عليها غير ذي معنى.
    $isUtf16 = $bom !== null && str_starts_with($bom, 'UTF-16');
    $inPchart = isPchart($file);

    $fileLines = $isUtf16 ? [] : (file($file, FILE_IGNORE_NEW_LINES) ?: []);

    if (!$isUtf16) {
        // 2) صلاحية UTF-8. pChart طرف ثالث بترميز قديم → يُعفى (U+FFFD فكّ قسري).
        if (!mb_check_encoding($raw, 'UTF-8') && !$inPchart) {
            $problems[] = 'الملف ليس UTF-8 صالحًا';
        }

        foreach ($fileLines as $n => $line) {
            $lines++;
            foreach (FORBIDDEN_RANGES as $label => [$from, $to]) {
                if ($inPchart) {
                    continue; // كل مجموعات pChart مُعفاة (طرف ثالث موثّق)
                }
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

echo "النتيجة: تسرّب محارف/BOM ممنوعة ✘\n";
exit(1);
