@echo off
REM ============================================================
REM   CD-020 — Sprint 0 Verification Script (Consolidated)
REM   Run on XAMPP (Windows) in the employee-evaluation repo root
REM   Output: paste everything between the ===== markers back
REM ============================================================
REM   Usage:
REM     1. Save this file as sprint0_verify.bat in C:\xampp\htdocs\employee-evaluation
REM     2. Open cmd, cd to that folder, run: sprint0_verify.bat
REM     3. Copy ALL output and send it back
REM ============================================================

setlocal enabledelayedexpansion
set DB=employee_evaluation_mvc
set MYSQL=C:\xampp\mysql\bin\mysql.exe
set MYSQLDUMP=C:\xampp\mysql\bin\mysqldump.exe
set PHP=C:\xampp\php\php.exe
set PASS=0
set FAIL=0

echo.
echo ############################################################
echo #  CD-020 SPRINT 0 — CONSOLIDATED VERIFICATION REPORT
echo #  Host: %COMPUTERNAME%
echo #  Date: %DATE% %TIME%
echo ############################################################
echo.

REM --- Section 1: Environment ---
echo ############################################################
echo #  SECTION 1: ENVIRONMENT
echo ############################################################
echo.
echo [1.1] PHP version:
%PHP% -v 2>&1 | findstr /R "PHP [0-9]"
echo.
echo [1.2] MySQL client version:
%MYSQL% --version 2>&1
echo.
echo [1.3] mysqldump version:
%MYSQLDUMP% --version 2>&1
echo.

REM --- Section 2: composer install ---
echo ############################################################
echo #  SECTION 2: COMPOSER INSTALL
echo ############################################################
echo.
echo [2.1] Running composer install --no-dev --optimize-autoloader...
call composer install --no-dev --optimize-autoloader 2>&1 | findstr /R "Installing Generating Nothing Package Loading"
if errorlevel 1 (
    echo RESULT[2.1]: FAIL - composer install error
    set /a FAIL+=1
) else (
    echo RESULT[2.1]: PASS
    set /a PASS+=1
)
echo.
echo [2.2] PHPWord installed version:
call composer show phpoffice/phpword 2>&1 | findstr /R "name versions"
echo.
echo [2.3] PhpSpreadsheet installed version:
call composer show phpoffice/phpspreadsheet 2>&1 | findstr /R "name versions"
echo.

REM --- Section 3: Apply migrations ---
echo ############################################################
echo #  SECTION 3: APPLY MIGRATIONS CD-016 / CD-017 / CD-018
echo ############################################################
echo.
echo [3.1] Applying CD-016 (evaluation foundation - SQL):
%MYSQL% -u root %DB% < database\migrations\2026_11_03_CD016_evaluation_foundation.sql 2>&1
if errorlevel 1 (
    echo RESULT[3.1]: FAIL
    set /a FAIL+=1
) else (
    echo RESULT[3.1]: PASS
    set /a PASS+=1
)
echo.
echo [3.2] Applying CD-017 (employee profile permission - SQL):
%MYSQL% -u root %DB% < database\migrations\2026_11_03_CD017_employee_profile_permission.sql 2>&1
if errorlevel 1 (
    echo RESULT[3.2]: FAIL
    set /a FAIL+=1
) else (
    echo RESULT[3.2]: PASS
    set /a PASS+=1
)
echo.
echo [3.3] Applying CD-018 (report snapshots - PHP):
%PHP% database\migrations\2026_11_03_CD018_report_snapshots.php 2>&1
if errorlevel 1 (
    echo RESULT[3.3]: FAIL
    set /a FAIL+=1
) else (
    echo RESULT[3.3]: PASS
    set /a PASS+=1
)
echo.

REM --- Section 4: Verify new tables ---
echo ############################################################
echo #  SECTION 4: VERIFY NEW TABLES
echo ############################################################
echo.
echo [4.1] Tables matching grading_scales / report_snapshot:
%MYSQL% -u root %DB% -N -e "SHOW TABLES LIKE 'grading_scales'; SHOW TABLES LIKE 'report_snapshots'; SHOW TABLES LIKE 'report_snapshot_counters';" 2>&1
echo.
echo [4.2] grading_scales row count (expected: 5):
%MYSQL% -u root %DB% -N -e "SELECT COUNT(*) FROM grading_scales;" 2>&1
echo.
echo [4.3] grading_scales contents:
%MYSQL% -u root %DB% -e "SELECT scale_name, grade_label, min_value, max_value, numeric_value FROM grading_scales ORDER BY sort_order;" 2>&1
echo.

REM --- Section 5: Verify 6 triggers ---
echo ############################################################
echo #  SECTION 5: VERIFY TRIGGERS (expected: 6)
echo ############################################################
echo.
echo [5.1] All triggers in information_schema:
%MYSQL% -u root %DB% -e "SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING, EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='%DB%' ORDER BY TRIGGER_NAME;" 2>&1
echo.
echo [5.2] Trigger count (expected: 6):
%MYSQL% -u root %DB% -N -e "SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='%DB%';" 2>&1
echo.

REM --- Section 6: Verify new columns ---
echo ############################################################
echo #  SECTION 6: VERIFY NEW COLUMNS
echo ############################################################
echo.
echo [6.1] evaluations columns (evaluation_type, final_grade_label, final_grade_value):
%MYSQL% -u root %DB% -N -e "SHOW COLUMNS FROM evaluations LIKE 'evaluation_type'; SHOW COLUMNS FROM evaluations LIKE 'final_grade_label'; SHOW COLUMNS FROM evaluations LIKE 'final_grade_value';" 2>&1
echo.
echo [6.2] form_templates columns (evaluation_mode, evaluation_frequency):
%MYSQL% -u root %DB% -N -e "SHOW COLUMNS FROM form_templates LIKE 'evaluation_mode'; SHOW COLUMNS FROM form_templates LIKE 'evaluation_frequency';" 2>&1
echo.

REM --- Section 7: Verify new permissions ---
echo ############################################################
echo #  SECTION 7: VERIFY NEW PERMISSIONS
echo ############################################################
echo.
echo [7.1] Permissions grading_scales.manage and employees.profile:
%MYSQL% -u root %DB% -e "SELECT id, name, description FROM permissions WHERE name IN ('grading_scales.manage','employees.profile');" 2>&1
echo.

REM --- Section 8: Immutability test ---
echo ############################################################
echo #  SECTION 8: IMMUTABILITY TEST (UPDATE must FAIL with 45000)
echo ############################################################
echo.
echo [8.1] Insert test snapshot:
%MYSQL% -u root %DB% -e "INSERT INTO report_snapshots (report_number, employee_id, created_by_user_id, snapshot_json) VALUES ('ER-TEST-00000001', (SELECT id FROM employees LIMIT 1), (SELECT id FROM users LIMIT 1), '{\"\"test\"\":true}');" 2>&1
echo.
echo [8.2] Attempt UPDATE on snapshot (EXPECTED TO FAIL with error 1644/45000):
%MYSQL% -u root %DB% -e "UPDATE report_snapshots SET snapshot_json='{\"\"hacked\"\":true}' WHERE report_number='ER-TEST-00000001';" 2>&1
echo   ^> If you see "Report snapshots are immutable" or error 1644 above, that is SUCCESS.
echo.
echo [8.3] Attempt DELETE on snapshot (EXPECTED TO FAIL):
%MYSQL% -u root %DB% -e "DELETE FROM report_snapshots WHERE report_number='ER-TEST-00000001';" 2>&1
echo   ^> If you see "Report snapshots are immutable" or error 1644 above, that is SUCCESS.
echo.
echo [8.4] Cleanup test row (via direct DBA bypass - temporary disable trigger):
echo   (Skipping auto-cleanup; if test row remains it is harmless - it has TEST in serial)
echo.

REM --- Section 9: Tests ---
echo ############################################################
echo #  SECTION 9: TEST SUITE (expected: 109 passed, 0 failed)
echo ############################################################
echo.
echo [9.1] Running php tests\runner.php:
%PHP% tests\runner.php 2>&1
echo.
echo RESULT[9.1]: see output above (look for "passed" / "failed" / "errors")
echo.

REM --- Section 10: Encoding gate ---
echo ############################################################
echo #  SECTION 10: ENCODING GATE (expected: exit 0)
echo ############################################################
echo.
echo [10.1] Running check-encoding.php --path=app:
if exist ..\employee-evaluation-docs\scripts\check-encoding.php (
    %PHP% ..\employee-evaluation-docs\scripts\check-encoding.php --path=app 2>&1
) else (
    echo NOTE: check-encoding.php not found at ..\employee-evaluation-docs\scripts\
    echo       Trying docs repo scripts path...
    %PHP% ..\employee-evaluation-docs\scripts\check-encoding.php --path=app 2>&1
)
echo RESULT[10.1]: exit code = %errorlevel%
echo.

REM --- Section 11: Backup ---
echo ############################################################
echo #  SECTION 11: MYSQLDUMP BACKUP
echo ############################################################
echo.
if not exist backups mkdir backups
set TS=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%
set TS=%TS: =0%
set BACKUPFILE=backups\sprint0_backup_%TS%.sql
echo [11.1] Running mysqldump to %BACKUPFILE%:
%MYSQLDUMP% -u root --routines --triggers --single-transaction --default-character-set=utf8mb4 --result-file="%BACKUPFILE%" %DB% 2>&1
if errorlevel 1 (
    echo RESULT[11.1]: FAIL - mysqldump error
    set /a FAIL+=1
) else (
    echo RESULT[11.1]: PASS
    set /a PASS+=1
)
echo.
echo [11.2] Backup file size:
dir "%BACKUPFILE%" 2>&1 | findstr /R "sprint0_backup"
echo.
echo [11.3] CREATE TABLE count in backup (expected: many):
findstr /C:"CREATE TABLE" "%BACKUPFILE%" 2>nul | find /C "CREATE TABLE"
echo.
echo [11.4] CREATE TRIGGER count in backup (expected: 6 or more with comments):
findstr /C:"CREATE TRIGGER" "%BACKUPFILE%" 2>nul | find /C "CREATE TRIGGER"
echo.
echo [11.5] report_snapshots table present in backup:
findstr /C:"report_snapshots" "%BACKUPFILE%" 2>nul | find /C "report_snapshots"
echo.

REM --- Section 12: Git state ---
echo ############################################################
echo #  SECTION 12: GIT STATE
echo ############################################################
echo.
echo [12.1] Current HEAD (code):
git rev-parse HEAD 2>&1
git log --oneline -1 2>&1
echo.
echo [12.2] Working tree status:
git status --short 2>&1
echo   ^> (empty above = clean)
echo.

REM --- Summary ---
echo ############################################################
echo #  SPRINT 0 VERIFICATION SUMMARY
echo ############################################################
echo.
echo   Automated PASS count: %PASS%
echo   Automated FAIL count: %FAIL%
echo.
echo   MANUAL REVIEW REQUIRED for:
echo     - [9.1]  test suite output (look for "109 passed")
echo     - [10.1] encoding exit code (look for "0")
echo     - [4.2]  grading_scales count (look for "5")
echo     - [5.2]  trigger count (look for "6")
echo     - [8.2]  immutability error (look for "immutable" / 1644)
echo     - [11.2] backup file size (look for ^> 50000 bytes)
echo.
echo ############################################################
echo #  END OF REPORT — copy everything above and send it back
echo ############################################################

endlocal
