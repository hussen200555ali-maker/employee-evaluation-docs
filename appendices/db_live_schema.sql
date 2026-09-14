/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admin_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('schedule_deadline','schedule_overdue','report_submitted','report_approved','report_rejected') NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `related_report_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `admin_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admin_report_evaluators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `evaluation_id` int(11) NOT NULL,
  `evaluator_id` int(11) NOT NULL,
  `assigned_at` datetime DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_eval_report` (`evaluation_id`,`evaluator_id`),
  KEY `evaluator_id` (`evaluator_id`),
  CONSTRAINT `admin_report_evaluators_ibfk_1` FOREIGN KEY (`evaluation_id`) REFERENCES `evaluations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `admin_report_evaluators_ibfk_2` FOREIGN KEY (`evaluator_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admin_schedules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL,
  `entity_type` enum('branch','department','organization') NOT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `period_type` enum('daily','weekly','monthly','quarterly','semiannual','annual') NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `admin_schedules_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `form_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL COMMENT 'معرف المستخدم الذي قام بالإجراء (NULL إذا كان الإجراء من النظام)',
  `action` varchar(100) NOT NULL COMMENT 'وصف الإجراء (مثل: USER_LOGIN)',
  `entity_type` varchar(50) DEFAULT NULL COMMENT 'اسم الجدول الذي تأثر بالإجراء',
  `entity_id` int(11) DEFAULT NULL COMMENT 'معرف السجل الذي تأثر',
  `details` text DEFAULT NULL COMMENT 'تفاصيل إضافية عن الإجراء (مثل القيم القديمة والجديدة)',
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=467 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='سجل تدقيق لجميع العمليات المهمة في النظام.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backup_encryption_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `backup_id` int(11) DEFAULT NULL,
  `key_name` varchar(100) DEFAULT NULL,
  `encrypted_key` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_bek_backup` (`backup_id`),
  CONSTRAINT `fk_bek_backup` FOREIGN KEY (`backup_id`) REFERENCES `backup_logs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backup_health_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `check_type` varchar(50) DEFAULT NULL,
  `status` enum('healthy','warning','critical') DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `checked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backup_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings_id` int(11) DEFAULT NULL,
  `backup_name` varchar(255) NOT NULL,
  `backup_type` varchar(50) NOT NULL DEFAULT 'full',
  `file_path` text DEFAULT NULL,
  `status` enum('in_progress','success','failed') NOT NULL DEFAULT 'in_progress',
  `progress` int(11) NOT NULL DEFAULT 0,
  `file_size` bigint(20) unsigned DEFAULT NULL,
  `tables_count` int(11) DEFAULT NULL,
  `execution_time` int(11) DEFAULT NULL,
  `is_encrypted` tinyint(1) NOT NULL DEFAULT 0,
  `encryption_key` varchar(500) DEFAULT NULL,
  `is_compressed` tinyint(1) NOT NULL DEFAULT 0,
  `compression_ratio` decimal(5,2) DEFAULT NULL,
  `integrity_hash` varchar(128) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_blog_status_date` (`status`,`created_at`),
  KEY `fk_blog_settings` (`settings_id`),
  KEY `fk_blog_user` (`created_by`),
  CONSTRAINT `fk_blog_settings` FOREIGN KEY (`settings_id`) REFERENCES `backup_settings` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_blog_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backup_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `backup_type` varchar(50) NOT NULL DEFAULT 'full',
  `schedule_type` varchar(20) NOT NULL DEFAULT 'manual',
  `schedule_time` time NOT NULL DEFAULT '02:00:00',
  `schedule_day` tinyint(3) unsigned DEFAULT NULL,
  `retention_days` int(11) NOT NULL DEFAULT 30,
  `encryption_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `compression_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `last_backup` datetime DEFAULT NULL,
  `next_backup` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_bsettings_user` (`created_by`),
  CONSTRAINT `fk_bsettings_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `branches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'اسم الفرع (مثل: فرع الرياض)',
  `location` text DEFAULT NULL COMMENT 'وصف موقع الفرع',
  `manager_id` int(11) DEFAULT NULL COMMENT 'معرف الموظف الذي يدير هذا الفرع',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_branch_manager` (`manager_id`),
  CONSTRAINT `fk_branch_manager` FOREIGN KEY (`manager_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن معلومات الفروع المختلفة للشركة.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `course_catalog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL COMMENT 'عنوان الدورة الرسمي',
  `description` text DEFAULT NULL COMMENT 'وصف مختصر للدورة وأهدافها',
  `category` varchar(100) DEFAULT NULL COMMENT 'تصنيف الدورة (إدارية, فنية, سلامة, ...)',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `title` (`title`),
  KEY `fk_course_catalog_user` (`created_by`),
  CONSTRAINT `fk_course_catalog_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `course_evaluations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `course_id` int(11) NOT NULL,
  `expected_attendees` int(11) NOT NULL COMMENT 'عدد الحضور المفترض',
  `actual_attendees` int(11) NOT NULL COMMENT 'عدد الحضور الفعلي',
  `program_regularity_weighted_score` decimal(4,2) NOT NULL COMMENT 'درجة انتظام البرنامج (المدخلة مباشرة من 0.00 إلى 30.00)',
  `participant_comprehension_weighted_score` decimal(4,2) NOT NULL COMMENT 'درجة استيعاب المشاركين (المدخلة مباشرة من 0.00 إلى 20.00)',
  `final_score` decimal(5,2) DEFAULT NULL COMMENT 'النتيجة النهائية المجمعة',
  `notes` text DEFAULT NULL,
  `evaluated_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `course_id` (`course_id`),
  KEY `evaluated_by` (`evaluated_by`),
  CONSTRAINT `course_evaluations_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `training_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `course_evaluations_ibfk_2` FOREIGN KEY (`evaluated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_eval_training_course` FOREIGN KEY (`course_id`) REFERENCES `training_courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `criteria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL COMMENT 'معرف القالب الذي ينتمي إليه هذا المعيار.',
  `criterion_name` varchar(255) NOT NULL COMMENT 'اسم المعيار الرئيسي (مثل: جودة العمل، المهارات القيادية).',
  `criterion_description` text DEFAULT NULL COMMENT 'وصف إضافي للمعيار لتوضيح ما يقيسه.',
  `criterion_weight` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT 'الوزن النسبي للمعيار في إجمالي درجة الاستمارة.',
  `override_summary_settings` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'هل هذا المعيار يتجاوز إعدادات الملخص الافتراضية؟ (1=نعم).',
  `summary_configuration` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'إعدادات أعمدة الملخص المخصصة لهذا المعيار فقط (إذا كان التجاوز فعالاً).' CHECK (json_valid(`summary_configuration`)),
  `order_index` int(11) DEFAULT 0 COMMENT 'لتحديد ترتيب ظهور المعايير في الاستمارة.',
  PRIMARY KEY (`id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `criteria_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `form_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن المعايير الرئيسية التي تتكون منها كل استمارة.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `criteria_sections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `criterion_id` int(11) NOT NULL COMMENT 'معرف المعيار الذي يتبعه هذا القسم.',
  `section_name` varchar(255) NOT NULL COMMENT 'اسم القسم أو السؤال الفعلي (مثل: الدقة في إنجاز المهام).',
  `section_description` text DEFAULT NULL COMMENT 'وصف إضافي للقسم أو إرشادات للمقيّم.',
  `evaluation_type` enum('percentage','numeric','grade','boolean','scale','text','multiple_choice','formula','auto','helper') NOT NULL DEFAULT 'percentage',
  `evaluation_options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'يخزن خيارات التقييم كـ JSON (لأنواع مثل grade و multiple_choice).' CHECK (json_valid(`evaluation_options`)),
  `min_value` decimal(10,2) DEFAULT NULL COMMENT 'القيمة الدنيا للحقول الرقمية أو المقياس.',
  `max_value` decimal(10,2) DEFAULT NULL COMMENT 'القيمة القصوى للحقول الرقمية أو المقياس.',
  `section_weight` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT 'الوزن النسبي للقسم داخل معياره الأب.',
  `allow_notes` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'هل يُسمح للمقيّم بإضافة ملاحظات نصية لهذا القسم؟ (1=نعم).',
  `notes_required` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'هل الملاحظات إجبارية إذا تم السماح بها؟ (1=نعم).',
  `notes_placeholder` varchar(255) DEFAULT NULL COMMENT 'النص التلميحي الذي يظهر في حقل الملاحظات.',
  `formula_config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'إعدادات الصيغة الحسابية' CHECK (json_valid(`formula_config`)),
  `order_index` int(11) DEFAULT 0 COMMENT 'ترتيب ظهور الأقسام داخل المعيار.',
  PRIMARY KEY (`id`),
  KEY `criterion_id` (`criterion_id`),
  CONSTRAINT `criteria_sections_ibfk_1` FOREIGN KEY (`criterion_id`) REFERENCES `criteria` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=130 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن الأقسام التفصيلية والأسئلة الفعلية لكل معيار.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `csrf_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token` varchar(191) NOT NULL,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_csrf_token_user` (`token`,`user_id`),
  KEY `idx_csrf_expires` (`expires_at`),
  KEY `fk_csrf_user` (`user_id`),
  CONSTRAINT `fk_csrf_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `departments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'اسم القسم (مثل: المبيعات، الدعم الفني)',
  `branch_id` int(11) DEFAULT NULL COMMENT 'معرف الفرع الذي يتبعه القسم. إذا كان NULL، فهو قسم مركزي يتبع الشركة الأم.',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `branch_id` (`branch_id`),
  CONSTRAINT `departments_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن معلومات الأقسام داخل الفروع أو الشركة الأم.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_code` varchar(50) NOT NULL COMMENT 'الرقم الوظيفي الفريد للموظف',
  `full_name` varchar(255) NOT NULL COMMENT 'الاسم الكامل للموظف',
  `nickname` varchar(255) DEFAULT NULL COMMENT '???? ?? ??? ?????? (???????)',
  `personal_email` varchar(255) DEFAULT NULL COMMENT 'البريد الإلكتروني الشخصي للموظف (للتواصل غير الرسمي)',
  `phone` varchar(20) DEFAULT NULL COMMENT 'رقم هاتف الموظف',
  `join_date` date DEFAULT NULL COMMENT 'تاريخ انضمام الموظف للشركة',
  `department_id` int(11) DEFAULT NULL COMMENT 'معرف القسم الذي يعمل به الموظف',
  `branch_id` int(11) DEFAULT NULL COMMENT 'معرف الفرع الذي يعمل به الموظف',
  `manager_id` int(11) DEFAULT NULL COMMENT 'معرف المدير المباشر للموظف (علاقة ذاتية)',
  `position_id` int(11) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'هل الموظف حالي في الشركة (1=نعم, 0=لا)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `emp_code` (`emp_code`),
  UNIQUE KEY `personal_email` (`personal_email`),
  KEY `department_id` (`department_id`),
  KEY `branch_id` (`branch_id`),
  KEY `manager_id` (`manager_id`),
  KEY `position_id` (`position_id`),
  CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `employees_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `employees_ibfk_3` FOREIGN KEY (`manager_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL,
  CONSTRAINT `employees_ibfk_4` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يحتوي على بيانات الموارد البشرية للموظفين (كيانات تنظيمية).';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `evaluation_id` int(11) NOT NULL,
  `section_id` int(11) NOT NULL,
  `raw_value` text DEFAULT NULL,
  `normalized_score` decimal(5,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `evaluation_id` (`evaluation_id`),
  KEY `section_id` (`section_id`),
  CONSTRAINT `ans_fk_evaluation` FOREIGN KEY (`evaluation_id`) REFERENCES `evaluations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ans_fk_section` FOREIGN KEY (`section_id`) REFERENCES `criteria_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=568 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation_import_batches` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uploaded_by_user_id` int(11) NOT NULL,
  `original_filename` varchar(255) NOT NULL,
  `status` enum('previewed','committing','completed','failed') NOT NULL DEFAULT 'previewed',
  `total_rows` int(10) unsigned NOT NULL DEFAULT 0,
  `valid_rows` int(10) unsigned NOT NULL DEFAULT 0,
  `invalid_rows` int(10) unsigned NOT NULL DEFAULT 0,
  `summary_json` longtext DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `committed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_import_batch_user_status` (`uploaded_by_user_id`,`status`),
  CONSTRAINT `fk_import_batch_user` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation_import_row_errors` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `batch_id` bigint(20) unsigned NOT NULL,
  `import_row_id` bigint(20) unsigned DEFAULT NULL,
  `source_row_number` int(10) unsigned NOT NULL,
  `error_code` varchar(80) NOT NULL,
  `error_message` varchar(500) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_import_error_batch` (`batch_id`,`source_row_number`),
  KEY `fk_import_error_row` (`import_row_id`),
  CONSTRAINT `fk_import_error_batch` FOREIGN KEY (`batch_id`) REFERENCES `evaluation_import_batches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_import_error_row` FOREIGN KEY (`import_row_id`) REFERENCES `evaluation_import_rows` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1849 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation_import_rows` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `batch_id` bigint(20) unsigned NOT NULL,
  `source_row_number` int(10) unsigned NOT NULL,
  `payload_json` longtext NOT NULL,
  `is_valid` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('valid','invalid','committed','skipped') NOT NULL DEFAULT 'valid',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_import_batch_row` (`batch_id`,`source_row_number`),
  CONSTRAINT `fk_import_row_batch` FOREIGN KEY (`batch_id`) REFERENCES `evaluation_import_batches` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1079 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation_schedules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL,
  `entity_type` enum('branch','department') NOT NULL,
  `unit_id` int(11) NOT NULL,
  `periodicity` enum('daily','weekly','monthly','quarterly','semiannual','annual','custom') NOT NULL,
  `title` varchar(255) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_schedule` (`template_id`,`entity_type`,`unit_id`,`periodicity`,`start_date`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `evaluation_schedules_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `form_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `evaluation_schedules_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL,
  `entity_type` enum('employee','course','workshop','branch','department','admin') NOT NULL DEFAULT 'employee',
  `entity_id` int(11) DEFAULT NULL,
  `context_type` enum('course','workshop') DEFAULT NULL,
  `context_id` int(11) DEFAULT NULL,
  `schedule_id` int(11) DEFAULT NULL,
  `status` enum('draft','pending_review','approved','completed','archived','expired') NOT NULL DEFAULT 'draft',
  `evaluation_date` date NOT NULL,
  `evaluated_employee_id` int(11) DEFAULT NULL,
  `evaluator_employee_id` int(11) DEFAULT NULL,
  `entity_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`entity_snapshot`)),
  `actual_force` int(11) DEFAULT NULL COMMENT 'القوة الفعلية',
  `applied_force` int(11) DEFAULT NULL COMMENT 'القوة المطبقه',
  `compliance_rate` decimal(5,2) DEFAULT NULL COMMENT 'نسبة المطابقة',
  `evaluator_name` varchar(255) DEFAULT NULL,
  `evaluator_title` varchar(255) DEFAULT NULL,
  `employee_name` varchar(255) NOT NULL,
  `employee_code` varchar(50) NOT NULL,
  `nickname` varchar(255) DEFAULT NULL,
  `branch_name` varchar(255) NOT NULL,
  `department_name` varchar(255) NOT NULL,
  `position_name` varchar(255) NOT NULL,
  `notes` text DEFAULT NULL,
  `report_title` varchar(255) DEFAULT NULL,
  `period_type` varchar(50) DEFAULT NULL,
  `period_start` date DEFAULT NULL,
  `period_end` date DEFAULT NULL,
  `final_score` decimal(5,2) DEFAULT NULL,
  `created_by_user_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `template_id` (`template_id`),
  KEY `evaluated_employee_id` (`evaluated_employee_id`),
  KEY `evaluator_employee_id` (`evaluator_employee_id`),
  KEY `created_by_user_id` (`created_by_user_id`),
  KEY `idx_entity` (`entity_type`,`entity_id`),
  KEY `idx_context` (`context_type`,`context_id`),
  KEY `idx_schedule` (`schedule_id`),
  CONSTRAINT `eval_fk_creator` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `eval_fk_evaluated` FOREIGN KEY (`evaluated_employee_id`) REFERENCES `employees` (`id`),
  CONSTRAINT `eval_fk_evaluator` FOREIGN KEY (`evaluator_employee_id`) REFERENCES `employees` (`id`),
  CONSTRAINT `eval_fk_template` FOREIGN KEY (`template_id`) REFERENCES `form_templates` (`id`),
  CONSTRAINT `fk_eval_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `evaluation_schedules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `form_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) NOT NULL COMMENT 'الاسم الرئيسي للاستمارة الذي يظهر للمستخدم.',
  `template_description` text DEFAULT NULL COMMENT 'وصف مختصر للغرض من هذه الاستمارة.',
  `target_position_id` int(11) DEFAULT NULL COMMENT 'معرف المنصب الذي يستهدفه هذا القالب',
  `target_type` enum('employee','employee_in_course','employee_in_workshop','course','workshop','unit','admin') DEFAULT 'employee',
  `target_entity_id` int(11) DEFAULT NULL,
  `unit_scope` enum('branch','department') DEFAULT NULL,
  `template_category` varchar(100) DEFAULT 'عام' COMMENT 'فئة الاستمارة لتصنيفها (مثال: أكاديمي، سلوكي).',
  `evaluation_nature` enum('standalone','cumulative') DEFAULT 'standalone' COMMENT 'طبيعة التقييم: standalone (تقييم فردي) أو cumulative (تقييم تجميعي متكرر).',
  `header_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'مصفوفة JSON بأسماء الحقول التي ستظهر في رأس كل تقييم (مثل: student_name, class_section).' CHECK (json_valid(`header_fields`)),
  `default_summary_configuration` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'إعدادات أعمدة الملخص الافتراضية التي ستطبق على كل المعايير.' CHECK (json_valid(`default_summary_configuration`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'هل الاستمارة نشطة ويمكن استخدامها (1=نعم, 0=لا).',
  `created_by` int(11) DEFAULT NULL COMMENT 'معرف المستخدم الذي أنشأ القالب.',
  `updated_by` int(11) DEFAULT NULL COMMENT 'معرف المستخدم الذي قام بآخر تحديث.',
  `version` int(11) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_target_position` (`target_position_id`),
  KEY `idx_target` (`target_type`,`target_entity_id`),
  CONSTRAINT `fk_template_to_position` FOREIGN KEY (`target_position_id`) REFERENCES `positions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `form_templates_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `form_templates_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن التصميم الأساسي والإعدادات العامة لكل استمارة تقييم.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'المستخدم الذي سيتلقى الإشعار',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('info','success','warning','danger') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT 0 COMMENT 'هل تمت قراءة الإشعار',
  `related_url` varchar(500) DEFAULT NULL COMMENT 'رابط متعلق بالإشعار',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن الإشعارات المرسلة للمستخدمين.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_resets` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL COMMENT 'التوكن الآمن المرسل للمستخدم',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يخزن طلبات استعادة كلمة المرور بشكل مؤقت وآمن.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT 'اسم الصلاحية البرمجي (مثل: employees.create)',
  `description` text DEFAULT NULL COMMENT 'وصف لما تسمح به هذه الصلاحية',
  `category` varchar(100) DEFAULT 'عام' COMMENT 'لتصنيف الصلاحيات (مثل: الموظفين، التقارير)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يُعرّف الأفعال المحددة التي يمكن القيام بها داخل النظام.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL COMMENT 'مثال: مدير فرع, موظف مبيعات, فني دعم',
  `category` enum('manager','deputy','staff','other') NOT NULL COMMENT 'فئة المنصب لتسهيل الفلترة',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rating_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(100) NOT NULL,
  `min_score` decimal(5,2) NOT NULL,
  `max_score` decimal(5,2) NOT NULL,
  `color` varchar(20) NOT NULL DEFAULT '#0d5e52',
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_template_columns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_template_id` int(11) NOT NULL,
  `source_type` varchar(20) NOT NULL COMMENT 'template أو criterion',
  `source_id` int(11) NOT NULL,
  `weight` decimal(5,2) NOT NULL DEFAULT 100.00,
  `order_index` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_rtc_template` (`report_template_id`,`order_index`),
  CONSTRAINT `fk_rtc_template` FOREIGN KEY (`report_template_id`) REFERENCES `report_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) NOT NULL,
  `courses_weight` decimal(5,2) NOT NULL DEFAULT 0.00,
  `workshops_weight` decimal(5,2) NOT NULL DEFAULT 0.00,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `role_permissions` (
  `role_id` int(11) NOT NULL COMMENT 'معرف الدور',
  `permission_id` int(11) NOT NULL COMMENT 'معرف الصلاحية',
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `permission_id` (`permission_id`),
  CONSTRAINT `role_permissions_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `role_permissions_ibfk_2` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='جدول ربط بين الأدوار والصلاحيات.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT 'اسم الدور (مثل: Admin, HR)',
  `description` text DEFAULT NULL COMMENT 'وصف لمسؤوليات الدور',
  `is_system_role` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'هل هذا دور أساسي لا يمكن حذفه؟ (1=نعم)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يُعرّف الأدوار الوظيفية المختلفة في النظام.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `settings` (
  `setting_key` varchar(100) NOT NULL COMMENT 'مفتاح الإعداد (مثل: system_name)',
  `setting_value` text DEFAULT NULL COMMENT 'قيمة الإعداد',
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='لتخزين إعدادات النظام العامة بشكل مرن.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `template_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL,
  `version_number` int(11) NOT NULL,
  `structure_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `version_description` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `fk_version_template` FOREIGN KEY (`template_id`) REFERENCES `form_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `training_courses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `catalog_id` int(11) NOT NULL,
  `description` text DEFAULT NULL COMMENT 'وصف مختصر لأهداف ومحتوى الدورة',
  `branch_id` int(11) DEFAULT NULL COMMENT 'معرف الفرع المستهدف (إن وجد)',
  `department_id` int(11) DEFAULT NULL COMMENT 'معرف القسم المستهدف (إن وجد)',
  `start_date` date NOT NULL COMMENT 'تاريخ بدء الدورة',
  `end_date` date NOT NULL COMMENT 'تاريخ انتهاء الدورة',
  `status` enum('scheduled','ongoing','completed','canceled') NOT NULL DEFAULT 'scheduled' COMMENT 'حالة الدورة',
  `created_by` int(11) DEFAULT NULL COMMENT 'معرف المستخدم الذي أضاف الدورة',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `branch_id` (`branch_id`),
  KEY `department_id` (`department_id`),
  KEY `created_by` (`created_by`),
  KEY `fk_course_catalog` (`catalog_id`),
  CONSTRAINT `fk_course_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_course_catalog` FOREIGN KEY (`catalog_id`) REFERENCES `course_catalog` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_course_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_course_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='جدول لتخزين الدورات التدريبية المخطط لها والمنفذة';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `training_workshops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `branch_id` int(11) NOT NULL,
  `department_id` int(11) DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `status` enum('scheduled','ongoing','completed','canceled') DEFAULT 'scheduled',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `catalog_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `branch_id` (`branch_id`),
  KEY `department_id` (`department_id`),
  KEY `fk_workshop_catalog` (`catalog_id`),
  CONSTRAINT `fk_workshop_catalog` FOREIGN KEY (`catalog_id`) REFERENCES `workshop_catalog` (`id`),
  CONSTRAINT `training_workshops_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `training_workshops_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_roles` (
  `user_id` int(11) NOT NULL COMMENT 'معرف المستخدم',
  `role_id` int(11) NOT NULL COMMENT 'معرف الدور',
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_roles_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='جدول ربط بين المستخدمين والأدوار.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL COMMENT 'اسم المستخدم الفريد لتسجيل الدخول',
  `email` varchar(255) NOT NULL COMMENT 'البريد الإلكتروني الرسمي (لتسجيل الدخول واستعادة كلمة المرور)',
  `password_hash` varchar(255) NOT NULL COMMENT 'كلمة المرور المشفرة',
  `employee_id` int(11) DEFAULT NULL COMMENT 'يربط حساب المستخدم بموظف. إذا كان NULL، فهو مستخدم غير موظف (مثل مدير النظام).',
  `status` enum('active','suspended','invited') NOT NULL DEFAULT 'active' COMMENT 'حالة حساب المستخدم',
  `last_login_at` timestamp NULL DEFAULT NULL COMMENT 'آخر تاريخ تم فيه تسجيل الدخول',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `employee_id` (`employee_id`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='يحتوي على حسابات الوصول للنظام. يفصل بين هوية الموظف وحساب الوصول.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `workshop_catalog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_workshop_created_by` (`created_by`),
  CONSTRAINT `fk_workshop_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `workshop_evaluations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workshop_id` int(11) NOT NULL COMMENT 'مرجع إلى training_workshops.id',
  `expected_attendees` int(11) DEFAULT 0,
  `actual_attendees` int(11) DEFAULT 0,
  `attendance_score` decimal(8,2) DEFAULT 0.00 COMMENT 'جزء الحضور (محسوب من 0 إلى 80)',
  `program_regularity_weighted_score` decimal(8,2) DEFAULT 0.00 COMMENT 'انتظام البرنامج (من 0 إلى 20)',
  `final_score` decimal(8,2) DEFAULT 0.00 COMMENT 'المجموع النهائي (من 0 إلى 100)',
  `notes` text DEFAULT NULL,
  `evaluated_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_workshop_eval_workshop` (`workshop_id`),
  CONSTRAINT `fk_workshop_eval_workshop` FOREIGN KEY (`workshop_id`) REFERENCES `training_workshops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
