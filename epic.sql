-- MySQL dump 10.13  Distrib 5.1.52, for unknown-linux-gnu (x86_64)
--
-- Host: localhost    Database: epic
-- ------------------------------------------------------
-- Server version	5.1.52-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `epichandles`
--

DROP TABLE IF EXISTS `epichandles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `epichandles` (
  `epichandle_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `handle` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`epichandle_id`),
  UNIQUE KEY `handle` (`handle`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `epichandles`
--

LOCK TABLES `epichandles` WRITE;
/*!40000 ALTER TABLE `epichandles` DISABLE KEYS */;
INSERT INTO `epichandles` VALUES (22,'10916/SARA');
/*!40000 ALTER TABLE `epichandles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `epicvalues`
--

DROP TABLE IF EXISTS `epicvalues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `epicvalues` (
  `epicvalue_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `epichandle_id` bigint(20) NOT NULL,
  `idx` int(11) NOT NULL,
  `epictype` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `data` blob,
  `ttl_type` smallint(6) DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `refs` blob,
  `admin_read` tinyint(1) DEFAULT NULL,
  `admin_write` tinyint(1) DEFAULT NULL,
  `pub_read` tinyint(1) DEFAULT NULL,
  `pub_write` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`epicvalue_id`),
  UNIQUE KEY `epichandle_id` (`epichandle_id`,`idx`),
  KEY `idx` (`idx`),
  KEY `epictype` (`epictype`),
  KEY `timestamp` (`timestamp`)
) ENGINE=MyISAM AUTO_INCREMENT=66 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `epicvalues`
--

LOCK TABLES `epicvalues` WRITE;
/*!40000 ALTER TABLE `epicvalues` DISABLE KEYS */;
INSERT INTO `epicvalues` VALUES (64,22,1,'URL','http://www.sara.nl/',0,86400,1325847528,'',1,1,1,0),(65,22,100,'HS_ADMIN','ó\0\0\0\n0.NA/10916\0\0\0È\0\0',0,86400,1325847528,'',1,1,1,0);
/*!40000 ALTER TABLE `epicvalues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `handles`
--

DROP TABLE IF EXISTS `handles`;
/*!50001 DROP VIEW IF EXISTS `handles`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `handles` (
  `handle` varchar(255),
  `idx` int(11),
  `type` varchar(255),
  `data` blob,
  `ttl_type` smallint(6),
  `ttl` int(11),
  `timestamp` int(11),
  `refs` blob,
  `admin_read` tinyint(1),
  `admin_write` tinyint(1),
  `pub_read` tinyint(1),
  `pub_write` tinyint(1)
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `handles_attic`
--

DROP TABLE IF EXISTS `handles_attic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `handles_attic`
--

LOCK TABLES `handles_attic` WRITE;
/*!40000 ALTER TABLE `handles_attic` DISABLE KEYS */;
/*!40000 ALTER TABLE `handles_attic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nas`
--

DROP TABLE IF EXISTS `nas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nas` (
  `na` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `na_id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`na_id`),
  UNIQUE KEY `na` (`na`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nas`
--

LOCK TABLES `nas` WRITE;
/*!40000 ALTER TABLE `nas` DISABLE KEYS */;
INSERT INTO `nas` VALUES ('0.NA/10916',3);
/*!40000 ALTER TABLE `nas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `handles`
--

/*!50001 DROP TABLE IF EXISTS `handles`*/;
/*!50001 DROP VIEW IF EXISTS `handles`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_bin */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`epic`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `handles` AS select `epichandles`.`handle` AS `handle`,`epicvalues`.`idx` AS `idx`,`epicvalues`.`epictype` AS `type`,`epicvalues`.`data` AS `data`,`epicvalues`.`ttl_type` AS `ttl_type`,`epicvalues`.`ttl` AS `ttl`,`epicvalues`.`timestamp` AS `timestamp`,`epicvalues`.`refs` AS `refs`,`epicvalues`.`admin_read` AS `admin_read`,`epicvalues`.`admin_write` AS `admin_write`,`epicvalues`.`pub_read` AS `pub_read`,`epicvalues`.`pub_write` AS `pub_write` from (`epichandles` join `epicvalues` on((`epichandles`.`epichandle_id` = `epicvalues`.`epichandle_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-01-06 12:46:20
