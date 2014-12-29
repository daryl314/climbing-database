PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;

--
-- Table for climbing areas
--

CREATE TABLE areas (
  area_id   INTEGER PRIMARY KEY,
  area_name VARCHAR,
  location  VARCHAR
);

--
-- Table for climbing send types
--

CREATE TABLE ascent_styles (
  style_id    INTEGER PRIMARY KEY,
  style_name  VARCHAR
);
INSERT INTO "ascent_styles" VALUES(1,'redpoint');
INSERT INTO "ascent_styles" VALUES(2,'onsight');
INSERT INTO "ascent_styles" VALUES(3,'flash');

--
-- Table for climbing sends
--

CREATE TABLE ascents (
  id          INTEGER PRIMARY KEY,
  route_id    INTEGER,
  climber_id  INTEGER,
  style_id    INTEGER,
  send_date   VARCHAR,
  CONSTRAINT ascents_ibfk_1 FOREIGN KEY (route_id)    REFERENCES routes         (route_id),
  CONSTRAINT ascents_ibfk_2 FOREIGN KEY (climber_id)  REFERENCES climbers       (climber_id),
  CONSTRAINT ascents_ibfk_3 FOREIGN KEY (style_id)    REFERENCES ascent_styles  (style_id)
);

--
-- Table for cliffs within climbing areas
--

CREATE TABLE cliffs (
  cliff_id    INTEGER PRIMARY KEY,
  cliff_name  VARCHAR,
  area_id     INTEGER,
  CONSTRAINT cliffs_ibfk_1 FOREIGN KEY (area_id) REFERENCES areas (area_id)
);

--
-- Table of climbers
--

CREATE TABLE climbers (
  climber_id  INTEGER PRIMARY KEY,
  fname       VARCHAR,
  lname       VARCHAR,
  display     VARCHAR,
  enabled     INTEGER DEFAULT 1
);

--
-- Table with a selection of climbing grades
--

CREATE TABLE grades (
  grade_id    INTEGER PRIMARY KEY,
  grade       VARCHAR,
  grade_sort  REAL,
  grade_class VARCHAR,
  system      VARCHAR
);
INSERT INTO "grades" VALUES(1,'VB',-1.0,'Boulder','V');
INSERT INTO "grades" VALUES(2,'V0',0.0,'Boulder','V');
INSERT INTO "grades" VALUES(3,'V1',1.0,'Boulder','V');
INSERT INTO "grades" VALUES(4,'V2',2.0,'Boulder','V');
INSERT INTO "grades" VALUES(5,'V3',3.0,'Boulder','V');
INSERT INTO "grades" VALUES(6,'V4',4.0,'Boulder','V');
INSERT INTO "grades" VALUES(7,'V5',5.0,'Boulder','V');
INSERT INTO "grades" VALUES(8,'V6',6.0,'Boulder','V');
INSERT INTO "grades" VALUES(9,'V7',7.0,'Boulder','V');
INSERT INTO "grades" VALUES(10,'V8',8.0,'Boulder','V');
INSERT INTO "grades" VALUES(11,'V9',9.0,'Boulder','V');
INSERT INTO "grades" VALUES(12,'V10',10.0,'Boulder','V');
INSERT INTO "grades" VALUES(13,'V11',11.0,'Boulder','V');
INSERT INTO "grades" VALUES(14,'V12',12.0,'Boulder','V');
INSERT INTO "grades" VALUES(15,'V13',13.0,'Boulder','V');
INSERT INTO "grades" VALUES(16,'V14',14.0,'Boulder','V');
INSERT INTO "grades" VALUES(17,'V15',15.0,'Boulder','V');
INSERT INTO "grades" VALUES(18,'V16',16.0,'Boulder','V');
INSERT INTO "grades" VALUES(19,'5.0',500.0,'Route','YDS');
INSERT INTO "grades" VALUES(20,'5.1',501.0,'Route','YDS');
INSERT INTO "grades" VALUES(21,'5.2',502.0,'Route','YDS');
INSERT INTO "grades" VALUES(22,'5.3',503.0,'Route','YDS');
INSERT INTO "grades" VALUES(23,'5.4',504.0,'Route','YDS');
INSERT INTO "grades" VALUES(24,'5.5',505.0,'Route','YDS');
INSERT INTO "grades" VALUES(25,'5.6',506.0,'Route','YDS');
INSERT INTO "grades" VALUES(26,'5.7',507.0,'Route','YDS');
INSERT INTO "grades" VALUES(27,'5.8',508.0,'Route','YDS');
INSERT INTO "grades" VALUES(28,'5.9',509.0,'Route','YDS');
INSERT INTO "grades" VALUES(29,'5.10a',510.1,'Route','YDS');
INSERT INTO "grades" VALUES(30,'5.10a/b',510.15,'Route','YDS');
INSERT INTO "grades" VALUES(31,'5.10b',510.2,'Route','YDS');
INSERT INTO "grades" VALUES(32,'5.10b/c',510.25,'Route','YDS');
INSERT INTO "grades" VALUES(33,'5.10c',510.3,'Route','YDS');
INSERT INTO "grades" VALUES(34,'5.10c/d',510.35,'Route','YDS');
INSERT INTO "grades" VALUES(35,'5.10d',510.4,'Route','YDS');
INSERT INTO "grades" VALUES(36,'5.10d/11a',510.75,'Route','YDS');
INSERT INTO "grades" VALUES(37,'5.11a',511.1,'Route','YDS');
INSERT INTO "grades" VALUES(38,'5.11a/b',511.15,'Route','YDS');
INSERT INTO "grades" VALUES(39,'5.11b',511.2,'Route','YDS');
INSERT INTO "grades" VALUES(40,'5.11b/c',511.25,'Route','YDS');
INSERT INTO "grades" VALUES(41,'5.11c',511.3,'Route','YDS');
INSERT INTO "grades" VALUES(42,'5.11c/d',511.35,'Route','YDS');
INSERT INTO "grades" VALUES(43,'5.11d',511.4,'Route','YDS');
INSERT INTO "grades" VALUES(44,'5.11d/12a',511.75,'Route','YDS');
INSERT INTO "grades" VALUES(45,'5.12a',512.1,'Route','YDS');
INSERT INTO "grades" VALUES(46,'5.12a/b',512.15,'Route','YDS');
INSERT INTO "grades" VALUES(47,'5.12b',512.2,'Route','YDS');
INSERT INTO "grades" VALUES(48,'5.12b/c',512.25,'Route','YDS');
INSERT INTO "grades" VALUES(49,'5.12c',512.3,'Route','YDS');
INSERT INTO "grades" VALUES(50,'5.12c/d',512.35,'Route','YDS');
INSERT INTO "grades" VALUES(51,'5.12d',512.4,'Route','YDS');
INSERT INTO "grades" VALUES(52,'5.12d/13a',512.75,'Route','YDS');
INSERT INTO "grades" VALUES(53,'5.13a',513.1,'Route','YDS');
INSERT INTO "grades" VALUES(54,'5.13a/b',513.15,'Route','YDS');
INSERT INTO "grades" VALUES(55,'5.13b',513.2,'Route','YDS');
INSERT INTO "grades" VALUES(56,'5.13b/c',513.25,'Route','YDS');
INSERT INTO "grades" VALUES(57,'5.13c',513.3,'Route','YDS');
INSERT INTO "grades" VALUES(58,'5.13c/d',513.35,'Route','YDS');
INSERT INTO "grades" VALUES(59,'5.13d',513.4,'Route','YDS');
INSERT INTO "grades" VALUES(60,'5.13d/14a',513.75,'Route','YDS');
INSERT INTO "grades" VALUES(61,'5.14a',514.1,'Route','YDS');
INSERT INTO "grades" VALUES(62,'5.14a/b',514.15,'Route','YDS');
INSERT INTO "grades" VALUES(63,'5.14b',514.2,'Route','YDS');
INSERT INTO "grades" VALUES(64,'5.14b/c',514.25,'Route','YDS');
INSERT INTO "grades" VALUES(65,'5.14c',514.3,'Route','YDS');
INSERT INTO "grades" VALUES(66,'5.14c/d',514.35,'Route','YDS');
INSERT INTO "grades" VALUES(67,'5.14d',514.4,'Route','YDS');
INSERT INTO "grades" VALUES(68,'5.14d/15a',514.75,'Route','YDS');
INSERT INTO "grades" VALUES(69,'5.15a',515.1,'Route','YDS');
INSERT INTO "grades" VALUES(70,'5.15a/b',515.15,'Route','YDS');
INSERT INTO "grades" VALUES(71,'5.15b',515.2,'Route','YDS');
INSERT INTO "grades" VALUES(72,'5.15b/c',515.25,'Route','YDS');
INSERT INTO "grades" VALUES(73,'5.15c',515.3,'Route','YDS');
INSERT INTO "grades" VALUES(74,'5.15c/d',515.35,'Route','YDS');
INSERT INTO "grades" VALUES(75,'5.15d',515.4,'Route','YDS');
INSERT INTO "grades" VALUES(76,'5a',507.0,'Route','French');
INSERT INTO "grades" VALUES(77,'5b',508.0,'Route','French');
INSERT INTO "grades" VALUES(78,'5c',509.0,'Route','French');
INSERT INTO "grades" VALUES(79,'6a',510.1,'Route','French');
INSERT INTO "grades" VALUES(80,'6a+',510.2,'Route','French');
INSERT INTO "grades" VALUES(81,'6b',510.3,'Route','French');
INSERT INTO "grades" VALUES(82,'6b+',510.4,'Route','French');
INSERT INTO "grades" VALUES(83,'6c',511.1,'Route','French');
INSERT INTO "grades" VALUES(84,'6c+',511.25,'Route','French');
INSERT INTO "grades" VALUES(85,'7a',511.4,'Route','French');
INSERT INTO "grades" VALUES(86,'7a+',512.1,'Route','French');
INSERT INTO "grades" VALUES(87,'7b',512.2,'Route','French');
INSERT INTO "grades" VALUES(88,'7b+',512.3,'Route','French');
INSERT INTO "grades" VALUES(89,'7c',512.4,'Route','French');
INSERT INTO "grades" VALUES(90,'7c+',513.1,'Route','French');
INSERT INTO "grades" VALUES(91,'8a',513.2,'Route','French');
INSERT INTO "grades" VALUES(92,'8a+',513.3,'Route','French');
INSERT INTO "grades" VALUES(93,'8b',513.4,'Route','French');
INSERT INTO "grades" VALUES(94,'8b+',514.1,'Route','French');
INSERT INTO "grades" VALUES(95,'8c',514.2,'Route','French');
INSERT INTO "grades" VALUES(96,'8c+',514.3,'Route','French');
INSERT INTO "grades" VALUES(97,'9a',514.4,'Route','French');
INSERT INTO "grades" VALUES(98,'9a+',515.1,'Route','French');
INSERT INTO "grades" VALUES(99,'9b',515.2,'Route','French');
INSERT INTO "grades" VALUES(100,'9b+',515.3,'Route','French');
INSERT INTO "grades" VALUES(101,'9c',515.4,'Route','French');
INSERT INTO "grades" VALUES(102,'5.10',510.25,'Route','YDS');
INSERT INTO "grades" VALUES(103,'5.11',511.25,'Route','YDS');
INSERT INTO "grades" VALUES(104,'5.12',512.25,'Route','YDS');
INSERT INTO "grades" VALUES(105,'5.13',513.25,'Route','YDS');
INSERT INTO "grades" VALUES(106,'5.14',514.25,'Route','YDS');

--
-- Table of routes
--

CREATE TABLE routes (
  route_id  INTEGER PRIMARY KEY,
  name      VARCHAR,
  grade_id  INTEGER,
  cliff_id  INTEGER,
  CONSTRAINT routes_ibfk_1 FOREIGN KEY (grade_id) REFERENCES grades (grade_id),
  CONSTRAINT routes_ibfk_2 FOREIGN KEY (cliff_id) REFERENCES cliffs (cliff_id)
);

--
-- Climbing ticklist (not currently used)
--

CREATE TABLE ticklist (
  ticklist_id INTEGER PRIMARY KEY,
  climber_id  INTEGER,
  route_id    INTEGER,
  disabled    INTEGER,
  CONSTRAINT ticklist_ibfk_1 FOREIGN KEY (climber_id) REFERENCES climbers (climber_id),
  CONSTRAINT ticklist_ibfk_2 FOREIGN KEY (route_id)   REFERENCES routes   (route_id)
);

--
-- View for route data
--

CREATE VIEW RouteData AS
SELECT
  routes.route_id     AS route_id,
  routes.name         AS Route,
  grades.grade        AS Grade,
  cliffs.cliff_name   AS Cliff,
  areas.area_name     AS Area,
  grades.grade_sort   AS GradeSort,
  grades.grade_class  AS RouteType
FROM routes
NATURAL JOIN grades
NATURAL JOIN cliffs
NATURAL JOIN areas;

--
-- View for sends
--

CREATE VIEW Sends AS
SELECT
  RouteData.Route,
  RouteData.Grade,
  ascent_styles.style_name  AS Style,
  ascents.send_date         AS SendDate,
  RouteData.Cliff,
  RouteData.Area,
  RouteData.GradeSort,
  RouteData.RouteType
FROM ascents
NATURAL JOIN RouteData
NATURAL JOIN climbers
NATURAL JOIN ascent_styles
WHERE climbers.display = 'Daryl'
ORDER BY SendDate DESC;

--
-- View for best route sends
--

CREATE VIEW TopRoutes AS
SELECT Route, Grade, Style, SendDate
FROM Sends
WHERE RouteType = 'Route'
ORDER BY GradeSort DESC
LIMIT 10;

--
-- View for best bouldering sends
--

CREATE VIEW TopBoulders AS
SELECT Route, Grade, Style, SendDate
FROM Sends
WHERE RouteType = 'Boulder'
ORDER BY GradeSort DESC
LIMIT 10;

--
-- View for ticklist data
--

CREATE VIEW vwTickList AS
SELECT
Route,
Grade,
Cliff,
Area,
RouteType,
route_id IN (
  SELECT route_id FROM ascents NATURAL JOIN climbers WHERE climbers.display = 'Daryl'
) AS Sent
FROM ticklist
NATURAL JOIN climbers
NATURAL JOIN RouteData
WHERE ticklist.disabled = 0 AND climbers.display = 'Daryl';

--
-- Commit transaction
--

COMMIT;
