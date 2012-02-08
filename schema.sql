SET character_set_client=utf8;
SET character_set_connection=utf8;
SET character_set_database=utf8;
SET character_set_results=utf8;
SET character_set_server=utf8;
SET collation_connection=utf8_bin;
SET collation_database=utf8_bin;
SET collation_server=utf8_bin;


DROP TABLE IF EXISTS `epic_handles`;
CREATE TABLE `epic_handles` (
  `epic_handle_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `handle` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`epic_handle_id`),
  UNIQUE KEY `handle` (`handle`)
) ENGINE=MyISAM AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;


LOCK TABLES `epic_handles` WRITE;
INSERT INTO `epic_handles` VALUES (1,'10916/SARA');
UNLOCK TABLES;


DROP TABLE IF EXISTS `epic_values`;
CREATE TABLE `epic_values` (
  `epic_value_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `epic_handle_id` bigint(20) NOT NULL,
  `idx` int(11) NOT NULL,
  `epic_type` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `data` blob,
  `ttl_type` smallint(6) DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `refs` blob,
  `admin_read` tinyint(1) DEFAULT NULL,
  `admin_write` tinyint(1) DEFAULT NULL,
  `pub_read` tinyint(1) DEFAULT NULL,
  `pub_write` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`epic_value_id`),
  UNIQUE KEY `epic_handle_id` (`epic_handle_id`,`idx`),
  KEY `idx` (`idx`),
  KEY `epic_type` (`epic_type`),
  KEY `timestamp` (`timestamp`)
) ENGINE=MyISAM AUTO_INCREMENT=64 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;


LOCK TABLES `epic_values` WRITE;
INSERT INTO `epic_values` VALUES (1,1,1,'URL','http://www.sara.nl/',0,86400,1325847528,'',1,1,1,0),(2,1,100,'HS_ADMIN','ó\0\0\0\n0.NA/10916\0\0\0È\0\0',0,86400,1325847528,'',1,1,1,0);
UNLOCK TABLES;


DROP TABLE IF EXISTS `handles_attic`;
CREATE TABLE `handles_attic` (
  `handle` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  `idx` int(11) NOT NULL,
  `type` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `data` blob,
  `ttl_type` smallint(6) DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `refs` blob,
  `admin_read` tinyint(1) DEFAULT NULL,
  `admin_write` tinyint(1) DEFAULT NULL,
  `pub_read` tinyint(1) DEFAULT NULL,
  `pub_write` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`handle`,`idx`),
  KEY `idx` (`idx`),
  KEY `type` (`type`),
  KEY `timestamp` (`timestamp`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;


DROP TABLE IF EXISTS `nas`;
CREATE TABLE `nas` (
  `na` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `na_id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`na_id`),
  UNIQUE KEY `na` (`na`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
INSERT INTO `nas` (`na`) VALUES ('0.NA/10916');

DROP VIEW IF EXISTS `handles`;
CREATE
  ALGORITHM=UNDEFINED
  SQL SECURITY INVOKER
  VIEW `handles` AS SELECT
    `handle`,
    `idx`,
    `epic_type` AS `type`,
    `data`,
    `ttl_type`,
    `ttl`,
    `timestamp`,
    `refs`,
    `admin_read`,
    `admin_write`,
    `pub_read`,
    `pub_write`
  FROM `epic_handles` NATURAL JOIN `epic_values`;


DELIMITER ;;


DROP PROCEDURE IF EXISTS `delete_handle`;;
CREATE PROCEDURE `delete_handle`(
  `p_handle` VARCHAR(255) CHARACTER SET utf8
)
BEGIN
  DECLARE l_epic_handle_id BIGINT;
  SELECT `epic_handle_id` INTO l_epic_handle_id FROM `epic_handles` WHERE `handle` = p_handle;
  DELETE FROM `epic_handles` WHERE `epic_handle_id` = l_epic_handle_id;
  DELETE FROM `epic_values` WHERE `epic_handle_id` = l_epic_handle_id;
END;;


DROP PROCEDURE IF EXISTS `delete_all_handles`;;
CREATE PROCEDURE `delete_all_handles`()
BEGIN
  DELETE FROM `epic_handles`;
  DELETE FROM `epic_values`;
END;;


DROP PROCEDURE IF EXISTS `create_handle`;;
CREATE PROCEDURE `create_handle`(
  `p_handle` VARCHAR(255) CHARACTER SET utf8,
  `p_idx` INT4,
  `p_epic_type` VARCHAR(255) CHARACTER SET utf8,
  `p_data` BLOB,
  `p_ttl_type` INT2,
  `p_ttl` INT4,
  `p_timestamp` INT4,
  `p_refs` BLOB,
  `p_admin_read` BOOL,
  `p_admin_write` BOOL,
  `p_pub_read` BOOL,
  `p_pub_write` BOOL
)
BEGIN
  DECLARE l_epic_handle_id BIGINT;
  INSERT IGNORE INTO `epic_handles` (`handle`) VALUES (p_handle);
  SELECT `epic_handle_id` INTO l_epic_handle_id FROM `epic_handles` WHERE `handle` = p_handle;
  INSERT INTO `epic_values` (
    `epic_handle_id`,
    `idx`,
    `epic_type`,
    `data`,
    `ttl_type`,
    `ttl`,
    `timestamp`,
    `refs`,
    `admin_read`,
    `admin_write`,
    `pub_read`,
    `pub_write`
  ) VALUES (
    l_epic_handle_id,
    `p_idx`,
    `p_epic_type`,
    `p_data`,
    `p_ttl_type`,
    `p_ttl`,
    `p_timestamp`,
    `p_refs`,
    `p_admin_read`,
    `p_admin_write`,
    `p_pub_read`,
    `p_pub_write`
  );
END;;


DROP PROCEDURE IF EXISTS `modify_value`;;
CREATE PROCEDURE `modify_value`(
  `p_epic_type` VARCHAR(255) CHARACTER SET utf8,
  `p_data` BLOB,
  `p_ttl_type` INT2,
  `p_ttl` INT4,
  `p_timestamp` INT4,
  `p_refs` BLOB,
  `p_admin_read` BOOL,
  `p_admin_write` BOOL,
  `p_pub_read` BOOL,
  `p_pub_write` BOOL,
  `p_handle` VARCHAR(255) CHARACTER SET utf8,
  `p_idx` INT4
)
BEGIN
  UPDATE `handles` SET
    `type` = `p_epic_type`,
    `data` = `p_data`,
    `ttl_type` = `p_ttl_type`,
    `ttl` = `p_ttl`,
    `timestamp` = `p_timestamp`,
    `refs` = `p_refs`,
    `admin_read` = `p_admin_read`,
    `admin_write` = `p_admin_write`,
    `pub_read` = `p_pub_read`,
    `pub_write` = `p_pub_write`
  WHERE `handle` = `p_handle` AND `idx` = `p_idx`;
END;;


DELIMITER ;
