-- =====================================================
-- LEGISLATION SYSTEM DATABASE TABLES
-- =====================================================
-- Run this SQL to create the tables needed for the legislation system

-- Create laws table
CREATE TABLE IF NOT EXISTS `government_laws` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `title` varchar(200) NOT NULL,
    `description` text NOT NULL,
    `status` enum('proposed','active','vetoed','failed') DEFAULT 'proposed',
    `created_by_cid` varchar(50) NOT NULL,
    `created_by_name` varchar(100) NOT NULL,
    `created_by_job` varchar(50) NOT NULL,
    `created_date` datetime DEFAULT current_timestamp(),
    `end_time` datetime DEFAULT NULL,
    `passed_date` datetime DEFAULT NULL,
    `veto_date` datetime DEFAULT NULL,
    `veto_by_cid` varchar(50) DEFAULT NULL,
    `veto_by_name` varchar(100) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `status` (`status`),
    KEY `created_by_cid` (`created_by_cid`),
    KEY `created_date` (`created_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create law votes table
CREATE TABLE IF NOT EXISTS `government_law_votes` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `law_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `name` varchar(100) NOT NULL,
    `vote` enum('yes','no') NOT NULL,
    `voted_date` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `law_citizen_unique` (`law_id`, `citizenid`),
    KEY `law_id` (`law_id`),
    KEY `citizenid` (`citizenid`),
    CONSTRAINT `fk_law_votes_law` FOREIGN KEY (`law_id`) REFERENCES `government_laws` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create indexes for better performance
CREATE INDEX idx_laws_status_created ON government_laws(status, created_date DESC);
CREATE INDEX idx_votes_law_vote ON government_law_votes(law_id, vote);
