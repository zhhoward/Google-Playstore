## DROPPING UNNECESSARY COLUMNS

drop table ptest1;

create table ptest1
like google_raw;

insert into ptest1
select*from google_raw;

alter table ptest1
drop column `Android Ver`;

alter table ptest1
drop column `Current Ver`;

alter table ptest1
drop column `Last Updated`;

alter table ptest1
drop column `Category`;

## FIX INSTALLS FOR RANKING

update ptest1
set Installs=replace(Installs,',','');

update ptest1
set Installs=replace(Installs,'+','');

## DELETE DUPLICATES WITH SAME NAME, REMOVING LOWER INSTALL DUPLICATES PRE SPECIAL CHARACTERS

drop table ptest2;

create table ptest2
like ptest1;

alter table ptest2
add column count int;

insert into ptest2
	select*,row_number() over(partition by App order by Installs desc) as count
	from ptest1;
    
select*from ptest2
where count>1;   

delete from ptest2
where count>1;

alter table ptest2
drop column count;

## REPLACING NaN in Rating

select count(*)
from ptest2
where Rating='NaN';

update ptest2
set Rating=0
where Rating='NaN';

## DELETING APPS WITH 0 INSTALLS
delete from ptest2
where Rating>5;

delete from ptest2
where Installs=0;

##TRIMMING APP NAME AND CHECKING FOR MORE DUPLICATES

update ptest2
set App=Trim(App);

## ERASING SPECIAL CHARACTERS FOR EXPORTING

select App
from ptest2
where HEX(App) REGEXP '^(..)*(E[4-9])';

update ptest2
set App='Foreign App'
where HEX(App) REGEXP '^(..)*(E[4-9])';

select App
from ptest2
where HEX(App) REGEXP '^[\u1ec7]';

update ptest2
set App='Unknown'
where App='#NAME?';

update ptest2
set App='Unknown'
where HEX(App) REGEXP '^[\u1ec7]';

update ptest2
set App=REGEXP_REPLACE(App, '[^\\x20-\\x7E]', '');

## Splitting Genre Column

alter table ptest2
add column (Genre1 text, Genre2 text);

update ptest2
set Genre1=substring_index(Genres,';',1);

update ptest2
set Genre2=substring_index(Genres,';',-1);

alter table ptest2
drop column Genres;

select*from ptest2
where Genre1=Genre2;

update ptest2
set Genre2=''
where Genre1=Genre2;

##TRIM AGAIN AFTER REMOVING SPECIAL CHARACTERS

update ptest2
set App=Trim(App);

## DELETE DUPLICATES WITH SAME NAME, REMOVING LOWER INSTALL DUPLICATES POST SPECIAL CHARACTERS

drop table ptest3;

create table ptest3
like ptest2;

alter table ptest3
add column count int;

insert into ptest3
	select*,row_number() over(partition by App order by Installs desc) as count
	from ptest2;
    
select*from ptest3
where count>1 and App not like 'Unknown' and App not like 'Foreign App';   

delete from ptest3
where count>1 and App not like 'Unknown' and App not like 'Foreign App';

alter table ptest3
drop column count;

select count(*) as count, App
from ptest3
group by App
having count(*) > 1;

##FIXING PRICE FORMAT

update ptest3
set Price=replace(Price,'$','');

## FORMATTING SIZE COLUMN FOR MBs

alter table ptest3
rename column Size to Size_MB;

update ptest3
set Size_MB=replace(Size_MB,'M','');

update ptest3
set Size_MB=(replace(Size_MB,'k',''))/1000
where Size_MB like '%k%';

update ptest3
set Size_MB=0
where Size_MB like '%v%';

## CORRECT DATA TYPES

alter table ptest3
modify column Rating double;

alter table ptest3
modify column Reviews bigint;

alter table ptest3
modify column Size_MB double;

alter table ptest3
modify column Installs bigint;

alter table ptest3
modify column Price double;

## VALIDATING

select distinct(rating)
from ptest3;
select distinct(Size_MB)
from ptest3;
select distinct(Installs)
from ptest3;
select distinct(Type)
from ptest3;
select distinct(Price)
from ptest3;
select distinct(`Content Rating`)
from ptest3;
select distinct(Genre1)
from ptest3;
select distinct(Genre2)
from ptest3;

## CREATE CLEANED TABLE WITH PRIMARY KEY

drop table playstore_cleaned;

create table playstore_cleaned(
  ID				INT NOT NULL PRIMARY KEY
  ,App               VARCHAR(200) NOT NULL
  ,Rating          	DOUBLE NOT NULL
  ,Reviews          BIGINT NOT NULL
  ,Size_MB       	DOUBLE NOT NULL
  ,Installs         BIGINT NOT NULL
  ,Type             VARCHAR(4) NOT NULL
  ,Price            DOUBLE NOT NULL
  ,`Content Rating` VARCHAR(15)
  ,Genre1           VARCHAR(50) NOT NULL
  ,Genre2           VARCHAR(50) NOT NULL

)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into playstore_cleaned
select ID, App, Rating, Reviews, Size_MB, Installs, Type, Price, `Content Rating`, Genre1, Genre2
from ptest3;

drop table ptest1;
drop table ptest2;
drop table ptest3;


###################################
