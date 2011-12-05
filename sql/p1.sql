alter table recorded add column deleted tinyint(1) default 0;

insert into prefs values ('recording_url', 'http://192.168.3.10:81/recordings');

