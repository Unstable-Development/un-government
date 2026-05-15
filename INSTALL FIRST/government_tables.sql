-- =====================================================
-- UN-GOVERNMENT DATABASE TABLES
-- =====================================================
-- Run this SQL file to create all required tables

-- =====================================================
-- GOVERNMENT VOTES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_votes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `type` varchar(50) NOT NULL,
  `created_by_cid` varchar(50) NOT NULL,
  `created_by_name` varchar(100) NOT NULL,
  `created_by_job` varchar(100) NOT NULL,
  `options` text NOT NULL COMMENT 'JSON array of vote options',
  `status` enum('active','ended') DEFAULT 'active',
  `passed` tinyint(1) DEFAULT NULL,
  `total_votes` int(11) DEFAULT 0,
  `results` text DEFAULT NULL COMMENT 'JSON of vote results',
  `end_time` datetime NOT NULL,
  `created_date` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `type` (`type`),
  KEY `created_by_cid` (`created_by_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- GOVERNMENT VOTE RECORDS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_vote_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vote_id` int(11) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `option` varchar(100) NOT NULL,
  `voted_date` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `vote_id` (`vote_id`),
  KEY `citizenid` (`citizenid`),
  UNIQUE KEY `unique_vote` (`vote_id`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- GOVERNMENT APPOINTMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_appointments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vote_id` int(11) DEFAULT NULL COMMENT 'If appointment required confirmation',
  `citizenid` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `job` varchar(50) NOT NULL,
  `job_label` varchar(100) NOT NULL,
  `appointed_by_cid` varchar(50) NOT NULL,
  `appointed_by_name` varchar(100) NOT NULL,
  `status` enum('pending','approved','denied','removed') DEFAULT 'pending',
  `removed_reason` text DEFAULT NULL,
  `removed_date` datetime DEFAULT NULL,
  `created_date` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `status` (`status`),
  KEY `vote_id` (`vote_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- GOVERNMENT BUDGET TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_budget` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `department` varchar(50) NOT NULL,
  `balance` decimal(15,2) NOT NULL DEFAULT 0.00,
  `last_allocation` datetime DEFAULT NULL,
  `updated_date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `department` (`department`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert initial department budgets
INSERT INTO `government_budget` (`department`, `balance`) VALUES
('executive', 50000.00),
('cityhall', 100000.00),
('treasury', 80000.00),
('legal', 120000.00),
('health', 70000.00),
('transport', 90000.00),
('parks', 40000.00),
('publicworks', 60000.00),
('legislative', 70000.00)
ON DUPLICATE KEY UPDATE balance = balance;

-- =====================================================
-- GOVERNMENT TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `department` varchar(50) NOT NULL,
  `type` enum('allocation','withdrawal','transfer','payment') NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `description` text NOT NULL,
  `authorized_by_cid` varchar(50) NOT NULL,
  `authorized_by_name` varchar(100) NOT NULL,
  `recipient` varchar(100) DEFAULT NULL,
  `transaction_date` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `department` (`department`),
  KEY `type` (`type`),
  KEY `transaction_date` (`transaction_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- GOVERNMENT INSPECTION HISTORY TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `government_inspection_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document_id` varchar(50) DEFAULT NULL COMMENT 'Reference to custom_documents',
  `inspection_type` enum('health','safety') NOT NULL,
  `business_name` varchar(255) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `inspector_cid` varchar(50) NOT NULL,
  `inspector_name` varchar(100) NOT NULL,
  `score` int(11) DEFAULT NULL,
  `grade` varchar(10) DEFAULT NULL,
  `passed` tinyint(1) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `inspection_date` timestamp DEFAULT CURRENT_TIMESTAMP,
  `next_inspection_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `business_name` (`business_name`),
  KEY `inspection_type` (`inspection_type`),
  KEY `inspector_cid` (`inspector_cid`),
  KEY `document_id` (`document_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 'UN-Government database tables created successfully!' AS message;
