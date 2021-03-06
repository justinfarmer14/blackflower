SET @provides_database_version = '1.9.0.0';
SET @requires_code_version = '1.9.0';

-- DROP DATABASE IF EXISTS cad;
-- DROP DATABASE IF EXISTS cadarchives;
-- CREATE DATABASE cad;
-- CREATE DATABASE cadarchives;
-- USE cad;

/* enum (reference) tables */

CREATE TABLE unit_roles (
        role       VARCHAR(20) not null primary key,
        color_name VARCHAR(20),
        color_html VARCHAR(20)
        );

CREATE TABLE status_options (
 	status  varchar(30) not null primary key
 );

CREATE TABLE incident_disposition_types (
 	disposition varchar(80) not null primary key
	);

CREATE TABLE incident_types (
	call_type	varchar(40) not null primary key
	);

        
CREATE TABLE incident_locks (
  lock_id            INTEGER NOT NULL AUTO_INCREMENT, 
  incident_id        INTEGER NOT NULL,
  user_id            INTEGER NOT NULL,
  timestamp          DATETIME NOT NULL,
  ipaddr             VARCHAR(80) NOT NULL,
  takeover_by_userid INTEGER,
  takeover_timestamp DATETIME,
  takeover_ipaddr    VARCHAR(80),
  session_id         VARCHAR(128),

  PRIMARY KEY        (lock_id),
  INDEX              (incident_id)
);


CREATE TABLE channels (
        channel_id      INTEGER NOT NULL AUTO_INCREMENT,
        channel_name    VARCHAR(40) NOT NULL,
        repeater        BOOL NOT NULL DEFAULT 0,
        available       BOOL NOT NULL DEFAULT 1,
        precedence      INTEGER NOT NULL DEFAULT 50,
        incident_id     INTEGER,
        staging_id      INTEGER,
        notes           VARCHAR(160),

        PRIMARY KEY     (channel_id),
        INDEX           (precedence,channel_name),
        INDEX           (incident_id),
        INDEX           (staging_id)
        );


INSERT INTO channels (channel_name, repeater, available, precedence) VALUES 
('Tac 11', 0, 1, 10),
('Tac 12', 1, 1, 10),
('Tac 13', 0, 1, 10),
('Fire Ground 1', 0, 1, 20),
('Fire Ground 2', 0, 1, 20),
('911', 1, 0, 97),
('Operations', 1, 0, 98),
('Admin', 1, 0, 99);


CREATE TABLE message_types (
  message_type varchar(20) not null primary key
  );

/* system control tables */

CREATE TABLE archive_master (
  tskey             VARCHAR(30) NOT NULL,
  ts                DATETIME NOT NULL,
  comment           VARCHAR(80),
  database_version  VARCHAR(20),
  requires_code_ver VARCHAR(20),

  PRIMARY KEY (tskey)
);

CREATE TABLE users (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  username      VARCHAR(20) NOT NULL,
  password      VARCHAR(64) NOT NULL,
  name          VARCHAR(40),
  access_level  INTEGER NOT NULL DEFAULT 1,
  access_acl    VARCHAR(20),
  timeout       INTEGER NOT NULL DEFAULT 300,
  preferences   TEXT,
  change_password  BOOL NOT NULL DEFAULT 0,
  locked_out            BOOL NOT NULL DEFAULT 0,
  failed_login_count    INT NOT NULL DEFAULT 0,
  last_login_time       DATETIME,

  PRIMARY KEY (id),
  INDEX (username)
);
/* data tables */

CREATE TABLE bulletins (
  bulletin_id   INTEGER NOT NULL AUTO_INCREMENT,
  bulletin_subject VARCHAR(160),
  bulletin_text TEXT,
  updated       DATETIME,
  updated_by    INTEGER,
  access_level  INTEGER,
  closed        BOOL NOT NULL DEFAULT 0,

  PRIMARY KEY (bulletin_id),
  INDEX (updated),
  INDEX (access_level),
  INDEX (closed)
);

CREATE TABLE bulletin_views (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  bulletin_id   INTEGER,
  user_id       INTEGER,
  last_read     DATETIME,

  PRIMARY KEY (id),
  INDEX (user_id, bulletin_id),
  INDEX (last_read)
);

CREATE TABLE bulletin_history (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  bulletin_id   INTEGER,
  action        ENUM('Created', 'Edited', 'Closed', 'Reopened'),
  updated       DATETIME,
  updated_by    INTEGER,

  PRIMARY KEY (id),
  INDEX (bulletin_id, updated)
);

CREATE TABLE messages (
	oid	int not null auto_increment primary key,
	ts	datetime not null,
	unit	varchar(20),
	message	varchar(255) not null,
	deleted bool not null default 0,
	creator varchar(20),
  message_type varchar(20),

  INDEX (deleted),
  INDEX (unit)
	);

CREATE TABLE units (
	unit	        VARCHAR(20) NOT NULL PRIMARY KEY,
	status	        VARCHAR(30),
	status_comment  VARCHAR(255),
	update_ts       DATETIME,
	-- role	        SET('Fire', 'Medical', 'Comm', 'MHB', 'Admin', 'Law Enforcement', 'Other'),
	role            VARCHAR(20),
	type	        SET('Unit', 'Individual', 'Generic'),
	personnel       VARCHAR(100),
	assignment      VARCHAR(20),
        personnel_ts	DATETIME,
	location	VARCHAR(255),
	location_ts	DATETIME,
	notes		VARCHAR(255),
	notes_ts	DATETIME,

  INDEX (status, type)
	);


CREATE TABLE unit_incident_paging (
  row_id        INT NOT NULL AUTO_INCREMENT,
  unit          VARCHAR(20) NOT NULL,
  to_pager_id   INT NOT NULL,  -- deprecated as of 1.7 integration with paging 3.0
  to_person_id  INT NOT NULL,

  PRIMARY KEY (row_id),
  INDEX (unit)
  );


CREATE TABLE unit_assignments (
  assignment      VARCHAR(20),
  description     VARCHAR(40),
  display_class   VARCHAR(80),
  display_style   TEXT,

  PRIMARY KEY (assignment)
  );


CREATE TABLE staging_locations (
   staging_id   int not null auto_increment,
   location     varchar(80),
   created_by   varchar(80),
   time_created   datetime not null,
   time_released  datetime,
   staging_notes   TEXT,

  PRIMARY KEY (staging_id)
);


CREATE TABLE unit_staging_assignments (
   staging_assignment_id        int not null auto_increment ,
   staged_at_location_id        int not null,
   unit_name                    varchar(20),
   time_staged                  datetime not null,
   time_reassigned              datetime,
   
  PRIMARY KEY (staging_assignment_id),
  INDEX(staged_at_location_id),
  INDEX(unit_name)

);


CREATE TABLE incidents (
	incident_id	int not null auto_increment primary key,
        call_number     varchar(40),
	call_type	varchar(40),
	call_details	varchar(80),
	ts_opened	datetime not null,
	ts_dispatch	datetime,
	ts_arrival	datetime,
	ts_complete	datetime,
	location	varchar(80),
	location_num	varchar(15),
	reporting_pty	varchar(80),
	contact_at	varchar(80),
	disposition	varchar(80),
	primary_unit	varchar(20),
	updated datetime not null,
	duplicate_of_incident_id int null,
        incident_status ENUM('New', 'Open', 'Dispositioned', 'Closed'),

  INDEX (incident_status),
  INDEX (ts_opened)
	);

CREATE TABLE incident_notes (
	note_id		int not null auto_increment primary key,
	incident_id	int not null,
	ts		datetime not null,
	unit		varchar(20),
	message		varchar(255) not null,
	deleted		bool not null default 0,
	creator varchar(20),

  INDEX (incident_id, deleted)
	);

CREATE TABLE incident_units (
	uid int not null auto_increment primary key,
	incident_id	int not null,
	unit		varchar(20) not null,
	dispatch_time datetime,  /* TODO: not null */
	arrival_time datetime,
        transport_time datetime,
        transportdone_time datetime,
	cleared_time datetime,
	is_primary bool,  /* deprecated 1.8.0: unused */
  is_generic bool, /* deprecated 1.8.0: unused */

  INDEX (incident_id, cleared_time),
  INDEX (dispatch_time)
	);


CREATE TABLE unit_filter_sets (
  idx               INT NOT NULL AUTO_INCREMENT,
  filter_set_name   VARCHAR(80) NOT NULL,
  row_description   VARCHAR(80) NOT NULL,
  row_regexp        VARCHAR(255) NOT NULL,

  PRIMARY KEY (idx),
  INDEX (filter_set_name)
);

CREATE TABLE deployment_history (
  idx               INT NOT NULL AUTO_INCREMENT,
  schema_load_ts    DATETIME NOT NULL,
  update_ts         TIMESTAMP,
  database_version  VARCHAR(20) NOT NULL,
  requires_code_ver VARCHAR(20) NOT NULL,
  mysql_user        VARCHAR(255),
  host              VARCHAR(255),  -- supplied from OS
  uid               INT,           -- supplied from OS
  user              VARCHAR(8),    -- MySQL CURRENT_USER() function
  cwd               VARCHAR(255),  -- supplied from OS

  PRIMARY KEY (idx)
);


/* Insert default long-lived values into reference tables *****************/

INSERT INTO incident_disposition_types VALUES ('Completed');
INSERT INTO incident_disposition_types VALUES ('Medical Transported');
INSERT INTO incident_disposition_types VALUES ('Other');
INSERT INTO incident_disposition_types VALUES ('Released AMA');
INSERT INTO incident_disposition_types VALUES ('Transferred to Agency');
INSERT INTO incident_disposition_types VALUES ('Transferred to Rangers');
INSERT INTO incident_disposition_types VALUES ('Treated And Released');
INSERT INTO incident_disposition_types VALUES ('Unable To Locate');
INSERT INTO incident_disposition_types VALUES ('Unfounded');
INSERT INTO incident_disposition_types VALUES ('Duplicate');

INSERT INTO incident_types VALUES ('COURTESY TRANSPORT');
INSERT INTO incident_types VALUES ('FIRE');
INSERT INTO incident_types VALUES ('LAW ENFORCEMENT');
INSERT INTO incident_types VALUES ('ILLNESS');
INSERT INTO incident_types VALUES ('INJURY');
INSERT INTO incident_types VALUES ('MENTAL HEALTH');
INSERT INTO incident_types VALUES ('PUBLIC ASSIST');
INSERT INTO incident_types VALUES ('TRAFFIC CONTROL');
INSERT INTO incident_types VALUES ('TRAINING');
INSERT INTO incident_types VALUES ('RANGERS');
INSERT INTO incident_types VALUES ('OTHER');

INSERT INTO message_types VALUES ('Swim');
INSERT INTO message_types VALUES ('Run');
INSERT INTO message_types VALUES ('Bike');
INSERT INTO message_types VALUES ('DNF');
INSERT INTO message_types VALUES ('DQ');
INSERT INTO message_types VALUES ('Other');

INSERT INTO status_options VALUES ('Attached to Incident');  -- Magic string
INSERT INTO status_options VALUES ('Staged At Location');    -- Magic string
INSERT INTO status_options VALUES ('Available On Pager');
INSERT INTO status_options VALUES ('Busy');
INSERT INTO status_options VALUES ('In Service');
INSERT INTO status_options VALUES ('Off Comm');
INSERT INTO status_options VALUES ('Off Duty');
INSERT INTO status_options VALUES ('Out Of Service');
INSERT INTO status_options VALUES ('Off Duty; On Pager');

INSERT INTO unit_roles (role, color_name, color_html) VALUES 
('Medical', 'Blue', 'Blue'),
('Fire', 'Red', 'Red'),
('MHB', 'Green', 'Green'),
('Comm', 'Purple', 'Purple'),
('Admin', 'Orange', 'darkorange'),
('Law Enforcement', 'Brown', 'brown'),
('Other', 'Black', 'Black');

INSERT INTO unit_assignments (assignment, description, display_class, display_style) VALUES
('BC', 'Battalion Chief', 'iconyellow', NULL),
('IC', 'Incident Commander', 'iconwhite', NULL),
('ODC', 'Operations Duty Chief', 'iconwhite', NULL),
('FDC', 'Fire Duty Chief', 'iconred', NULL),
('MDC', 'Medical Duty Chief', 'iconblue', NULL),
('ADC', 'Assistant Medical Duty Chief', 'iconblue', NULL),
('SDC', 'Support Duty Chief', 'icongray', NULL),
('CDC', 'Comm Duty Chief', 'iconpurple', NULL),
('OC', 'On-Call', 'icongray', NULL),
('S', 'Supervisor', 'icongray', NULL),
('FS', 'Field Supervisor', 'icongray', NULL),
('MHDC', 'Mental Health Duty Chief', 'icongreen', NULL),
('L2000', 'Legal 2000 On-Call', 'icongreen', NULL),  
('CRC', 'Child Respite Center On-Call', 'icongreen', NULL);


INSERT INTO channels (channel_name, repeater, available, precedence) VALUES 
('Tac 11', 0, 1, 10),
('Tac 12', 1, 1, 10),
('Tac 13', 0, 1, 10),
('Fire Ground 1', 0, 1, 20),
('Fire Ground 2', 0, 1, 20),
('911', 1, 0, 97),
('Operations', 1, 0, 98),
('Admin', 1, 0, 99);

INSERT INTO deployment_history (schema_load_ts, database_version, requires_code_ver, mysql_user) VALUES (NOW(), @provides_database_version, @requires_code_version, CURRENT_USER());
