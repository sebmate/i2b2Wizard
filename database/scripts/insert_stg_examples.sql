-- Creates sample Staging Tables


  CREATE TABLE STG_OBSERVATIONS
   (	"CASENUM" VARCHAR2(10 BYTE), 
	"RECDATE" DATE, 
	"SYSABBR" VARCHAR2(20 BYTE), 
	"VALUE" VARCHAR2(20 BYTE)
   );


  CREATE TABLE STG_ONTOLOGY
   (	"LEVEL1" VARCHAR2(30 BYTE), 
	"LEVEL2" VARCHAR2(30 BYTE), 
	"LEVEL3" VARCHAR2(30 BYTE), 
	"VALUE" VARCHAR2(30 BYTE), 
	"SYSABBR" VARCHAR2(20 BYTE), 
	"CCODE" VARCHAR2(20 BYTE), 
	"DATATYPE" VARCHAR2(5 BYTE)
   );
 

  CREATE TABLE STG_PATIENTS 
   (	"PATNUM" VARCHAR2(20 BYTE), 
	"CASENUM" VARCHAR2(20 BYTE), 
	"GENDER" VARCHAR2(5 BYTE), 
	"AGE" VARCHAR2(5 BYTE)
   );

 
REM INSERTING into STG_OBSERVATIONS
Insert into STG_OBSERVATIONS (CASENUM,RECDATE,SYSABBR,VALUE) values ('999001',to_timestamp('01.01.10','DD.MM.RR HH24:MI:SSXFF'),'ATTRB_A_SEV','1');
Insert into STG_OBSERVATIONS (CASENUM,RECDATE,SYSABBR,VALUE) values ('999001',to_timestamp('01.01.10','DD.MM.RR HH24:MI:SSXFF'),'ATTRB_A_SUCC','Yes');
Insert into STG_OBSERVATIONS (CASENUM,RECDATE,SYSABBR,VALUE) values ('999001',to_timestamp('01.01.10','DD.MM.RR HH24:MI:SSXFF'),'ATTRB_A_DBL','Yes');
Insert into STG_OBSERVATIONS (CASENUM,RECDATE,SYSABBR,VALUE) values ('999001',to_timestamp('01.01.10','DD.MM.RR HH24:MI:SSXFF'),'ATTRB_A_STRT','04/05/2009');
Insert into STG_OBSERVATIONS (CASENUM,RECDATE,SYSABBR,VALUE) values ('999001',to_timestamp('01.01.10','DD.MM.RR HH24:MI:SSXFF'),'ATTRB_A_END','12/1/2009');

 
REM INSERTING into STG_ONTOLOGY
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Severity','1','ATTRB_A_SEV','SEV_A:1','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Severity','2','ATTRB_A_SEV','SEV_A:2','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Severity','3','ATTRB_A_SEV','SEV_A:3','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Success','Yes','ATTRB_A_SUCC','SUCC_A:YES','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Success','No','ATTRB_A_SUCC','SUCC_A:NO','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Double Dose','Yes','ATTRB_A_DBL','DBL_A:YES','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Double Dose','No','ATTRB_A_DBL','DBL_A:NO','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','Start of Therapy',null,'ATTRB_A_STRT','THER_A:ST','D');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Special Treatment','End of Therapy',null,'ATTRB_A_END','THER_A:END','D');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Injury','1','ATTRB_B_SEV','INJ_B:1','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Injury','2','ATTRB_B_SEV','INJ_B:2','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Injury','3','ATTRB_B_SEV','INJ_B:3','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Success','Yes','ATTRB_B_SUCC','SUCC_B:YES','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Success','No','ATTRB_B_SUCC','SUCC_B:NO','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Patient Responsive','Yes','ATTRB_B_DBL','RESP_B:YES','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Patient Responsive','No','ATTRB_B_DBL','RESP_B:NO','S');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','Start of Therapy',null,'ATTRB_B_STRT','THER_B:ST','D');
Insert into STG_ONTOLOGY (LEVEL1,LEVEL2,LEVEL3,VALUE,SYSABBR,CCODE,DATATYPE) values ('HIS','Experimental Therapy','End of Therapy',null,'ATTRB_B_END','THER_B:END','D');


REM INSERTING into STG_PATIENTS
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10001','999001','F','17');
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10002','999002','M','20');
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10003','999003','F','23');
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10004','999004','M','26');
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10005','999005','F','29');
Insert into STG_PATIENTS (PATNUM,CASENUM,GENDER,AGE) values ('10006','999006','M','32');
