-- CD-012 Phase 2: Purge operational/test data (Option 1: operational only)
-- Keeps foundation: roles, permissions, branches, departments, positions,
-- form_templates, training/course/workshop demo data, real users (sysadmin + real staff),
-- real employees EMP-001..EMP-018.
-- Backup taken before run: employee_evaluation_mvc_20261020_235913.sql

SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 1) Answers (children of evaluations) — all operational.
DELETE FROM evaluation_answers;

-- 2) Import batches/rows/errors — operational import test data.
DELETE FROM evaluation_import_row_errors;
DELETE FROM evaluation_import_rows;
DELETE FROM evaluation_import_batches;

-- 3) Evaluations — all operational.
DELETE FROM admin_report_evaluators;
DELETE FROM evaluations;

-- 4) Ephemeral CSRF tokens.
DELETE FROM csrf_tokens;

-- 5) Test users' dependents, then test users (ids 2094..2099).
DELETE FROM user_roles            WHERE user_id BETWEEN 2094 AND 2099;
DELETE FROM password_history      WHERE user_id BETWEEN 2094 AND 2099;
DELETE FROM notifications         WHERE user_id BETWEEN 2094 AND 2099;
DELETE FROM admin_notifications   WHERE user_id BETWEEN 2094 AND 2099;
DELETE FROM audit_logs            WHERE user_id BETWEEN 2094 AND 2099;
DELETE FROM users WHERE id BETWEEN 2094 AND 2099;

-- 6) Test/junk employees (Phase-5 P5-* and manual-test junk), after their dependents.
DELETE FROM employees
 WHERE emp_code LIKE 'P5-%'
    OR emp_code IN ('EMP-999','15555','256464','242452','124004','545454','434','55','232455');

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
