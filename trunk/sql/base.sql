create table programs (
	program_id varchar(16) not null,
	title varchar(64) not null,
	subtitle varchar(128),
	description varchar(256),
	primary key (program_id)
);

create table schedule (
	schedule_id int not null auto_increment,
	program_id varchar(16) not null,
	station_id int not null,
	start_time varchar(32),
	duration varchar(16),
    primary key (schedule_id)
);

create table queue (
	queue_id int not null auto_increment,
	program_id varchar(16) not null,
	station_id int not null,
	start_time varchar(32),
	duration varchar(16),
	tuner int,
	primary key (queue_id)
);

create table recorded (
	record_id int not null auto_increment,
	program_id varchar(16) not null,
	station_id int not null,
	start_time varchar(32),
	duration varchar(16),
	primary key (record_id)
);

create table stations (
	station_id int not null,
	channel int not null,
	minor int not null,
	primary key (station_id)
);

create table tuners (
	tuner int not null,
	channel int not null,
	program int not null,
	number varchar(8) not null,
	name varchar(16) not null
);

create table favorites (
	favorite_id int not null auto_increment,
	program_id varchar(16) not null,
	station_id int not null,
	primary key (favorite_id)
);

create table prefs (
    name varchar(32) not null,
    value varchar(256) not null,
    primary key (name)
);

insert into prefs values ('root_dir', '/mnt/array1/share/nasdvr');
insert into prefs values ('data_dir', '/mnt/array1/share/nasdvr/dat');
insert into prefs values ('sd_username', '');
insert into prefs values ('sd_password', '');
insert into prefs values ('sd_url', 'http://docs.tms.tribune.com/tech/tmsdatadirect/schedulesdirect/tvDataDelivery.wsdl');
insert into prefs values ('hdhr_id', '');
insert into prefs values ('hdhr_config', '/usr/bin/hdhomerun_config');
insert into prefs values ('recording_dir', '/mnt/array1/share/recordings');
insert into prefs values ('sd_num_days', '14');
insert into prefs values ('tz_offset', '5');
insert into prefs values ('log_file', '/mnt/array1/share/nasdvr/log.txt');

