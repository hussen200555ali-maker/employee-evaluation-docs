<?php
/**
 * فحص ترميز مستندات التسليم وكود التطبيق — البند 11-b (CD-006) / OOS-11 / OOS-12
 *
 * الاستخدام:
 *   php scripts/check-encoding.php [--path=delivery|app|all] [--warn-only] [<path> ...]
 *
 *   --path=delivery   (افتراضي) مستندات التسليم: CD-001_delivery/*.md + <appRoot>/CHANGELOG.md
 *   --path=app        كود التطبيق: <appRoot>/app/** /*.php + *.inc + *.phtml
 *   --path=all        كلا النطاقين (للاستخدام اليدوي فقط — لا يستخدمه خطاف)
 *   --warn-only       لا يُرجع exit=1 أبدًا (تقرير فقط للاستخدام اليدوي)
 *   <path> ...        ملف/مجلد صريح (يتجاوز --path) — يُوسَّع المجلد تكراريًا
 *
 * القرار المعماري (المستشار 2026-10-19): النطاق منفصل لكل مستودع، بلا مسارات مطلقة:
 *   خطاف التسليم  → `php scripts/check-encoding.php --path=delivery`
 *   خطاف التطبيق  → `php ../CD-001_delivery/scripts/check-encoding.php --path=app`
 *
 * مجموعة الكشف (كما اعتمدها المستشار):
 *   CJK      U+4E00–U+9FFF
 *   Kana     U+3040–U+30FF
 *   Hangul   U+AC00–U+D7AF
 *   Cyrillic U+0400–U+04FF
 *   U+FFFD   محرف الاستبدال — أُضيف في OOS-11
 * + التحقق من صلاحية UTF-8.
 * + فحص BOM (إلزامي — OOS-11): UTF-8 (EF BB BF) · UTF-16 LE (FF FE) · UTF-16 BE (FE FF).
 *
 * الاستثناء الوحيد (allowlist): مكتبة طرف ثالث `app/Libraries/pChart/**`.
 *   - مجموعات U+FFFD/الترميز: تُعفى كل امتدادات pChart (طرف ثالث موثّق).
 *   - فحص BOM: يُعفى داخل pChart للملفات **غير التنفيذية** فقط (.log/.txt/.md/…).
 *     ملفات pChart التنفيذية (.php) لا تُعفى من BOM (كارثية: headers already sent).
 *     (مُثبت: pChart .php خالية من BOM — OOS-11.)
 *
 * المخرجات: 0 = نظيف · 1 = تسرّب (إلا مع --warn-only) · 2 = خطأ استخدام.
 *
 * التشغيل على ويندوز:  C:\xampp\php\php.exe scripts\check-encoding.php
 * أو عبر متغيّر البيئة PHP_BIN، أو `php` إن كان في PATH.
 */

declare(strict_types=1);

$deliveryDir = dirname(__DIR__);        // CD-001_delivery
$appRoot     = dirname($deliveryDir);   // جذر التطبيق (employee-evaluation)

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

/** امتدادات الملفات النصية عند توسيع مجلد صريح. */
const TEXT_EXTENSIONS = [
    'php', 'phtml', 'inc', 'md', 'txt', 'js', 'mjs', 'css', 'html', 'htm',
    'json', 'csv', 'log', 'cmd', 'bat', 'ps1', 'sql', 'yml', 'yaml', 'ini', 'xml',
];

/** امتدادات كود التطبيق عند `--path=app`. */
const APP_EXTENSIONS = ['php', 'inc', 'phtml'];

const VALID_SCOPES = ['delivery', 'app', 'all'];

/** @return bool هل الامتداد ضمن القائمة؟ */
function hasExtension(string $path, array $extensions): bool
{
    return in_array(strtolower(pathinfo($path, PATHINFO_EXTENSION)), $extensions, true);
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
    return !hasExtension($path, EXECUTABLE_EXTENSIONS);
}

/** @return array<int,string> كل الملفات ذات الامتدادات المطلوبة تحت مجلد (تكراريًا). */
function collectRecursive(string $dir, array $extensions): array
{
    if (!is_dir($dir)) {
        return [];
    }
    $out = [];
    $it = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS)
    );
    foreach ($it as $f) {
        if ($f->isFile() && hasExtension($f->getPathname(), $extensions)) {
            $out[] = $f->getPathname();
        }
    }
    return $out;
}

/** نطاق التسليم: مستندات التسليم + سجل جذر التطبيق (موقع التلف التاريخي). */
function scopeDelivery(string $deliveryDir, string $appRoot): array
{
    $files = glob($deliveryDir . '/*.md') ?: [];
    $rootChangelog = $appRoot . '/CHANGELOG.md';
    if (is_file($rootChangelog)) {
        $files[] = $rootChangelog;
    }
    return $files;
}

/** نطاق التطبيق: app/** /*.php + *.inc + *.phtml (allowlist pChart يبقى مطبَّقًا). */
function scopeApp(string $appRoot): array
{
    return collectRecursive($appRoot . '/app', APP_EXTENSIONS);
}

/**
 * يحلّل الوسائط.
 * @return array{0:string,1:bool,2:array<int,string>} [النطاق، warnOnly، المسارات الصريحة]
 */
function parseOptions(array $argv): array
{
    $scope = 'delivery';
    $warnOnly = false;
    $explicit = [];
    foreach (array_slice($argv, 1) as $a) {
        if (str_starts_with($a, '--path=')) {
            $scope = substr($a, 7);
        } elseif ($a === '--warn-only') {
            $warnOnly = true;
        } elseif ($a === '-h' || $a === '--help') {
            fwrite(STDOUT, "Usage: php check-encoding.php [--path=delivery|app|all] [--warn-only] [<path> ...]\n");
            exit(0);
        } else {
            $explicit[] = $a;
        }
    }
    return [$scope, $warnOnly, $explicit];
}

/** @return array<int,string> المسارات المفحوصة */
function targetFiles(string $deliveryDir, string $appRoot, string $scope, array $explicit): array
{
    $files = [];

    if ($explicit !== []) {
        foreach ($explicit as $p) {
            $abs = realpath($p);
            if ($abs === false) {
                fwrite(STDERR, "  ! مسار غير موجود: $p\n");
                continue;
            }
            if (is_dir($abs)) {
                $files = array_merge($files, collectRecursive($abs, TEXT_EXTENSIONS));
            } elseif (is_file($abs)) {
                $files[] = $abs;
            }
        }
    } else {
        if ($scope === 'delivery' || $scope === 'all') {
            $files = array_merge($files, scopeDelivery($deliveryDir, $appRoot));
        }
        if ($scope === 'app' || $scope === 'all') {
            $files = array_merge($files, scopeApp($appRoot));
        }
    }

    $files = array_values(array_unique($files));
    sort($files);
    return $files;
}

[$scope, $warnOnly, $explicit] = parseOptions($argv);

if (!in_array($scope, ['delivery', 'app', 'all'], true)) {
    fwrite(STDERR, "  ! نطاق غير معروف: --path=$scope (المسموح: delivery|app|all)\n");
    exit(2);
}

$files = targetFiles($deliveryDir, $appRoot, $scope, $explicit);
if ($files === []) {
    fwrite(STDERR, "لا توجد ملفات للفحص (--path=$scope).\n");
    exit(2);
}

echo "فحص ترميز — البند 11-b · النطاق: $scope\n";
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

if ($warnOnly) {
    echo "النتيجة: تسرّب محارف/BOM (وضع --warn-only) ⚠\n";
    exit(0);
}

echo "النتيجة: تسرّب محارف/BOM ممنوعة ✘\n";
exit(1);
