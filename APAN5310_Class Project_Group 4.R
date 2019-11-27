# Before start, please download the files in reference table to populate the database
# Remember to set con to corresponding dbname, user, pw if you are using codio box
rm(list = ls())
require('RPostgreSQL')
drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, dbname = 'test',
                 host = 'localhost', port = 5432,
                 user = 'test', password='test')

#### Establish the database ####

stmt = "
DROP TABLE Entity_SBA_Business_Types;
DROP TABLE Entity_NAICS_Exception;
DROP TABLE Entity_PSC;
DROP TABLE Entity_NAICS;
DROP TABLE Entity_Business_Type;
DROP TABLE Entity_Registration;
DROP TABLE SBA_Business_Types;
DROP TABLE NAICS_Exceptions;
DROP TABLE PSC;
DROP TABLE NAICS;
DROP TABLE Business_Types;
DROP TABLE Physical_Addresses;
DROP TABLE Purpose_of_Registration;
DROP TABLE SAM_Extract;
DROP TABLE DUNS;

CREATE TABLE DUNS(
DUNS char(9),
CAGE char(5),
primary key (DUNS)
);

CREATE TABLE SAM_Extract(
SAM_Extract_Code char(1), 
SAM_Extract_Description text,
primary key (SAM_Extract_Code),
check (SAM_Extract_Code in ('A','E','1','2','3','4'))
);

CREATE TABLE Purpose_of_Registration(
Purpose_of_Registration_Code char(2), 
Purpose_of_Registration_Description varchar(30),
primary key (Purpose_of_Registration_Code),
check (Purpose_of_Registration_Code in ('Z1','Z2','Z3','Z4','Z5'))
);

CREATE TABLE Physical_Addresses(
Physical_AddressID varchar(10),
Address_Line_One varchar(150), 
Address_Line_Two varchar(150), 
City varchar(40), 
Province_State varchar(55), 
Zip varchar(50), 
Zip_Four numeric(4), 
Country_Code varchar(3), 
Congressional_District char(2),
primary key (Physical_AddressID)
);

CREATE TABLE Business_Types(
BusinessTypeID char(2),
Business_Type_Description text,
primary key (BusinessTypeID)
);

CREATE TABLE NAICS(
NAICSID char(6), 
NAICS_Description text,
primary key (NAICSID)
);

CREATE TABLE PSC(
PSCID char(4),
PSC_Description text,
primary key (PSCID)
);

CREATE TABLE NAICS_Exceptions(
NAICS_ExceptionCode char(6), 
NAICS_Exception_Description text,
primary key (NAICS_ExceptionCode),
foreign key (NAICS_ExceptionCode) references NAICS (NAICSID) 
);

CREATE TABLE SBA_Business_Types(
SBA_Business_TypeID char(2), 
SBA_Business_Type_Name varchar(50),
primary key (SBA_Business_TypeID)
);

CREATE TABLE Entity_Registration(
EntityID bigint, 
DUNS char(9) NOT NULL,
DODAAC varchar(9),
SAM_Extract_Code char(1),
Purpose_of_Registration_Code char(2), 
Initial_Registration_Date date, 
Expiration_Date date, 
Last_Update_Date date, 
Activation_Date date, 
Legal_Business_Name varchar(120) NOT NULL, 
DBA_Name varchar(120), 
Company_Division_Number varchar(10),
Company_Division varchar(60),
Physical_AddressID varchar(10) default NULL,
Business_Start_Date date, 
Fiscal_Year_Close_Date char(4), 
Corporate_url varchar(200), 
Entity_Structure varchar(2), 
State_of_Incorporation varchar(2), 
Country_of_Incorporation varchar(3), 
Credit_Card_Usage char(1), 
Correspondence_Flag char(1), 
Debt_Subject_to_Offset_Flag char(1), 
Exclusion_Status_Flag char(1), 
No_Public_Display_Flag varchar(4),
primary key (EntityID),
foreign key (DUNS) references DUNS,
foreign key (SAM_Extract_Code) references SAM_Extract,
foreign key (Purpose_of_Registration_Code) references Purpose_of_Registration,
foreign key (Physical_AddressID) references Physical_Addresses, 
check (SAM_Extract_Code in ('A','E','1','2','3','4','')),
check (Purpose_of_Registration_Code in ('Z1','Z2','Z3','Z4','Z5','')),
check (Credit_Card_Usage in ('Y','N','')),
check (Correspondence_Flag in ('M','F','E','')),
check (Debt_Subject_to_Offset_Flag in ('Y','N','')),
check (Exclusion_Status_Flag in ('D','')),
check (No_Public_Display_Flag in ('NPDY',''))
);

CREATE TABLE Entity_Business_Type(
EntityID bigint, 
BusinessTypeID char(2),
primary key (EntityID, BusinessTypeID),
foreign key (EntityID) references Entity_Registration,
foreign key (BusinessTypeID) references Business_Types
);

CREATE TABLE Entity_NAICS(
EntityID bigint, 
NAICSID char(6),
primary key (EntityID, NAICSID),
foreign key (EntityID) references Entity_Registration,
foreign key (NAICSID) references NAICS
);

CREATE TABLE Entity_PSC(
EntityID bigint, 
PSCID char(4),
primary key (EntityID, PSCID),
foreign key (EntityID) references Entity_Registration,
foreign key (PSCID) references PSC
);

CREATE TABLE Entity_NAICS_Exception(
EntityID bigint, 
NAICS_ExceptionCode char(6),
primary key (EntityID, NAICS_ExceptionCode),
foreign key (EntityID) references Entity_Registration,
foreign key (NAICS_ExceptionCode) references NAICS_Exceptions
);

CREATE TABLE Entity_SBA_Business_Types(
EntityID bigint, 
SBA_Business_TypeID char(2),
primary key (EntityID, SBA_Business_TypeID),
foreign key (EntityID) references Entity_Registration,
foreign key (SBA_Business_TypeID) references SBA_Business_Types
);
"
dbGetQuery(con, stmt)

setwd("/Users/Yoga/Desktop/Reference Table")

#### Populate the database ####
install.packages("readxl")
library(readxl)
install.packages("dplyr")
library(dplyr)
SAM <- data.frame(read_excel('SAM_Project.xls'))
BT <- data.frame(read_excel('Business_Types.xls'))
NAICS <- read.csv('NAICS.csv',header = TRUE)
NAICS_E <- read.csv('NAICS_Exception.csv',header = TRUE)
PSC <- read.csv('PSC.csv',header = TRUE)
POR <- read.csv('Purpose_of_Registration.csv',header = TRUE)
SAM_E <- read.csv('SAM_Extract.csv',header = TRUE)
SBABT <- read.csv('SBA_Business_Types.csv',header = TRUE)

# DUNS table:
duns <- SAM[c('DUNS','CAGE')]
colnames(duns) <-c('duns','cage')
rnum <- as.numeric(rownames(unique(duns['duns'])))
duns <- duns[rnum,]
dbWriteTable(con, name="duns", value=duns, row.names=FALSE, append=TRUE)

# SAM_Extract Table:
colnames(SAM_E) <-c('sam_extract_code','sam_extract_description')
dbWriteTable(con, name="sam_extract", value=SAM_E, row.names=FALSE, append=TRUE)

# Purpose_of_Registration Table:
colnames(POR) <-c('purpose_of_registration_code','purpose_of_registration_description')
dbWriteTable(con, name="purpose_of_registration", value=POR, row.names=FALSE, append=TRUE)

# Physical_Addresses Table:
pa <- SAM[c('Address_Line_One','Address_Line_Two','City','Province_State','Zip','Zip_Four','Country_Code','Congressional_District')]
colnames(pa) <-c('address_line_one','address_line_two','city','province_state','zip','zip_four','country_code','congressional_district')
pa <- unique(pa)
pa$physical_addressid <- 1:nrow(pa)
dbWriteTable(con, name="physical_addresses", value=pa, row.names=FALSE, append=TRUE)
new <- SAM[,'Address_Line_One']
new[] <- lapply(SAM[,'Address_Line_One'], function(x) pa$physical_addressid[match(x, pa$address_line_one)]) 
SAM$physical_addressid <- as.numeric(new)

# Business_Types Table:
colnames(BT) <- c('businesstypeid','business_type_description')
dbWriteTable(con, name="business_types", value=BT, row.names=FALSE, append=TRUE)

# NAICS Table:
colnames(NAICS) <- c('naicsid','naics_description')
dbWriteTable(con, name="naics", value=NAICS, row.names=FALSE, append=TRUE)

# PSC Table:
colnames(PSC) <- c('pscid','psc_description')
dbWriteTable(con, name="psc", value=PSC, row.names=FALSE, append=TRUE)

# NAICS_Exceptions Table:
colnames(NAICS_E) <- c('naics_exception_description','naics_exceptioncode')
dbWriteTable(con, name="naics_exceptions", value=NAICS_E, row.names=FALSE, append=TRUE)

# SBA_Business_Types Table:
colnames(SBABT) <- c('sba_business_typeid','sba_business_type_name')
dbWriteTable(con, name="sba_business_types", value=SBABT, row.names=FALSE, append=TRUE)

# Entity_Registration Table:
SAM$entityid <- 1:nrow(SAM)
colnames(SAM) <- tolower(colnames(SAM))
ER <- SAM[c('entityid', 'duns', 'dodaac', 'sam_extract_code', 'purpose_of_registration_code', 'initial_registration_date', 'expiration_date', 'last_update_date', 'activation_date', 'legal_business_name', 'dba_name', 'company_division_number','company_division', 'physical_addressid', 'business_start_date', 'fiscal_year_close_date', 'corporate_url', 'entity_structure', 'state_of_incorporation', 'country_of_incorporation', 'credit_card_usage', 'correspondence_flag', 'debt_subject_to_offset_flag', 'exclusion_status_flag', 'no_public_display_flag' )]

dbWriteTable(con, name="entity_registration", value=ER, row.names=FALSE, append=TRUE)

# Entity_Business_Type Table:
EBT <- SAM[c('entityid','business_type')]
b_types <- strsplit(as.character(EBT$business_type), split = "~", fixed=TRUE)
EBT <- data.frame(entityid = rep(EBT$entityid, sapply(b_types, length)),businesstypeid = unlist(b_types))
dbWriteTable(con, name="entity_business_type", value=EBT, row.names=FALSE, append=TRUE)

# Entity_NAICS Table:
EN <- na.omit(SAM[c('entityid','naics_code')])
n_codes <- strsplit(as.character(EN$naics_code), split = "~", fixed=TRUE)
EN <- data.frame(entityid = rep(EN$entityid, sapply(n_codes, length)), naicsid = substr(unlist(n_codes),1,6))
dbWriteTable(con, name="entity_naics", value=EN, row.names=FALSE, append=TRUE)

# Entity_PSC Table:
EP <- na.omit(SAM[c('entityid','psc_code')])
p_codes <- strsplit(as.character(EP$psc_code), split = "~", fixed=TRUE)
EP <- data.frame(entityid = rep(EP$entityid, sapply(p_codes, length)), pscid = unlist(p_codes))
dbWriteTable(con, name="entity_psc", value=EP, row.names=FALSE, append=TRUE)

# Entity_NAICS_Exception Table:
ENE <- na.omit(SAM[c('entityid','naics_exception_string')])
ne_codes <- strsplit(as.character(ENE$naics_exception_string), split = "~", fixed=TRUE)
ENE <- data.frame(entityid = rep(ENE$entityid, sapply(ne_codes, length)), naics_exceptioncode = substr(unlist(ne_codes),1,6))
dbWriteTable(con, name="entity_naics_exception", value=ENE, row.names=FALSE, append=TRUE)

# Entity_SBA_Business_Types Table:
ESBT <- na.omit(SAM[c('entityid','sba_business_type')])
sba_types <- strsplit(as.character(ESBT$sba_business_type), split = "~", fixed=TRUE)
ESBT <- data.frame(entityid = rep(ESBT$entityid, sapply(sba_types, length)), sba_business_typeid = substr(unlist(sba_types),1,2))
dbWriteTable(con, name="entity_sba_business_types", value=ESBT, row.names=FALSE, append=TRUE)

#### Start the 10 Analytical Procedure ####

#### Query 1: Segment the entities registered by state or congressional district.  
stmt = "
CREATE VIEW entity_state_cd AS
SELECT er.duns, er.legal_business_name, er.corporate_url, pa.address_line_one,
pa.address_line_two, pa.city, pa.province_state, pa.zip, pa.zip_four, pa.congressional_district
FROM entity_registration er NATURAL JOIN physical_addresses pa
WHERE er.physical_addressid = pa.physical_addressid;
"
dbGetQuery(con, stmt)

# Example for state of Virginia.  
# The province_state value could be an input variable instead of hard-coded for an application

stmt = "
SELECT *
FROM entity_state_cd
WHERE province_state = 'VA'  
ORDER BY city ASC;
"
dbGetQuery(con, stmt)

# Example for congressional district NY-01.
# The province_state and congressional_district values could be input variables instead of hard-coded for an application 

stmt = "
SELECT *
FROM entity_state_cd
WHERE province_state = 'NY' AND congressional_district = '01'
ORDER BY city ASC;
"
dbGetQuery(con, stmt)

#### Query 2: Volume of entities registered by congressional district.  
stmt = "
CREATE VIEW entity_cd AS
SELECT pa.province_state, pa.congressional_district, COUNT(er.entityid)
FROM entity_registration er NATURAL JOIN physical_addresses pa
WHERE er.physical_addressid = pa.physical_addressid
GROUP BY pa.province_state, pa.congressional_district 
ORDER BY COUNT(er.entityid) DESC;

SELECT * 
FROM entity_cd;
"
dbGetQuery(con, stmt)

#### Query 3: Volume of entities registered by busines type. 
stmt = "
CREATE VIEW business_types_report AS
SELECT bt.businesstypeid, bt.business_type_description, COUNT(ebt.entityid) AS entity_count
FROM entity_registration er NATURAL JOIN entity_business_type ebt NATURAL JOIN business_types bt
WHERE er.entityid = ebt.entityid AND ebt.businesstypeid = bt.businesstypeid
GROUP BY bt.businesstypeid, bt.business_type_description
ORDER BY COUNT(ebt.entityid) DESC;

SELECT * 
FROM business_types_report;
"
dbGetQuery(con, stmt)

#### Query 4: Volumne of entities by SBA business type.  
stmt = "
CREATE VIEW sba_business_types_report AS
SELECT sbt.sba_business_typeid, sbt.sba_business_type_name, COUNT(esbt.entityid) AS entity_count
FROM entity_registration er NATURAL JOIN entity_sba_business_types esbt NATURAL JOIN sba_business_types sbt
WHERE er.entityid = esbt.entityid AND esbt.sba_business_typeid = sbt.sba_business_typeid
GROUP BY sbt.sba_business_typeid, sbt.sba_business_type_name
ORDER BY COUNT(esbt.entityid) DESC;

SELECT * 
FROM sba_business_types_report;
"
dbGetQuery(con, stmt)

#### Query 5: NAICS view table for analysts.  Cross reference entities and NAICS codes.
stmt = "
CREATE VIEW naics_view AS
SELECT er.duns, er.legal_business_name, n.naicsid, n.naics_description
FROM entity_registration er NATURAL JOIN entity_naics en NATURAL JOIN naics n
WHERE er.entityid = en.entityid AND en.naicsid = n.naicsid
ORDER BY n.naicsid ASC;

SELECT * 
FROM naics_view
LIMIT 100;
"
dbGetQuery(con, stmt)

#### Query 6: PSC view table for analysts.  Cross reference entities and PSC codes.
stmt = "
CREATE VIEW psc_view AS
SELECT er.duns, er.legal_business_name, p.pscid, p.psc_description
FROM entity_registration er NATURAL JOIN entity_psc ep NATURAL JOIN psc p
WHERE er.entityid = ep.entityid AND ep.pscid = p.pscid
ORDER BY p.pscid ASC;

SELECT * 
FROM psc_view
LIMIT 100;
"
dbGetQuery(con, stmt)

#### Query 7: Business types view table for analysts.  Cross reference entities and business types. 
stmt = "
CREATE VIEW business_types_view AS
SELECT er.duns, er.legal_business_name, bt.businesstypeid, bt.business_type_description
FROM entity_registration er NATURAL JOIN entity_business_type ebt NATURAL JOIN business_types bt
WHERE er.entityid = ebt.entityid AND ebt.businesstypeid = bt.businesstypeid 
ORDER BY bt.businesstypeid ASC;

SELECT * 
FROM business_types_view
LIMIT 100;
"
dbGetQuery(con, stmt)

#### Query 8: SBA business types view table for analysts.  Cross reference entities and SBA business types. 
stmt = "
CREATE VIEW sba_business_types_view AS
SELECT er.duns, er.legal_business_name, sbt.sba_business_typeid, sbt.sba_business_type_name
FROM entity_registration er NATURAL JOIN entity_sba_business_types esbt NATURAL JOIN sba_business_types sbt
WHERE er.entityid = esbt.entityid AND esbt.sba_business_typeid = sbt.sba_business_typeid 
ORDER BY sbt.sba_business_typeid ASC;

SELECT * 
FROM sba_business_types_view
LIMIT 100;
"
dbGetQuery(con, stmt)

#### Query 9: PSC/NAICS combination report for most frequently used combinations.
stmt = "
CREATE VIEW psc_naics_combos AS
SELECT p.pscid, p.psc_description, n.naicsid, n.naics_description, COUNT(entityid) AS combo_count
FROM psc p NATURAL JOIN entity_psc ep NATURAL JOIN 
entity_registration er NATURAL JOIN entity_naics en NATURAL JOIN naics n
WHERE er.entityid = en.entityid AND en.naicsid = n.naicsid 
AND er.entityid = ep.entityid AND ep.pscid = p.pscid
GROUP BY p.pscid, p.psc_description, n.naicsid, n.naics_description
ORDER BY COUNT(entityid) DESC;

SELECT * 
FROM psc_naics_combos
WHERE combo_count > 1;
"
dbGetQuery(con, stmt)

#### Query 10: SBA business types/business types combination report for most frequently occurring combinations.  
stmt = "
CREATE VIEW sba_and_business_types_combos AS
SELECT bt.businesstypeid, bt.business_type_description, sbt.sba_business_typeid, sbt.sba_business_type_name,
COUNT(entityid) AS combo_count
FROM business_types bt NATURAL JOIN entity_business_type ebt NATURAL JOIN entity_registration er
NATURAL JOIN entity_sba_business_types esbt NATURAL JOIN sba_business_types sbt
WHERE er.entityid = ebt.entityid AND ebt.businesstypeid = bt.businesstypeid AND
er.entityid = esbt.entityid AND esbt.sba_business_typeid = sbt.sba_business_typeid
GROUP BY sbt.sba_business_typeid, sbt.sba_business_type_name, bt.businesstypeid, bt.business_type_description
ORDER BY COUNT(entityid) DESC;

SELECT *
FROM sba_and_business_types_combos;
"
dbGetQuery(con, stmt)



