/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (Maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Sep 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

INSTRUCTIONS:
* RUN THIS FILE BEFORE EVERY STATA SESSION.
* RUN THE OUTRO FILE AFTER EVERY STATA SESSION.
* NOTE, THE INTRO DOFILES IN THE SUBFOLDERS ARE ALL JUST A SHORTCUT TO THE 
"01 INTRO.DO" FILE IN THE ROOT FOLDER. THEREFORE, EDITING ONE EDITS ALL.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OVERVIEW:
	(1) Define Globals
		* Set Directory
			* Parent folders
			* Data folders
			* Do-file folders
			* Truecrypt drives (for windows mac compatability)
	(2) Define other global		
		* Missing values
		* Create time stamp
	(4) Install programs
		Installs all programs in "dofiles/00 adofiles" automatically"
	(7) Write all master files and back up all dofiles 
	(8) Back up all dofiles 
	(9) Temporary programs
	(10) Mount ALL truecrypt volumes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/	

*clear all
macro drop _all
cap log close
set more off
set logtype text, permanently
set linesize 100

*************************************************************************
* Command Bridge 
*************************************************************************

* BACK-UP DOFILES AND CREATE MASTER DOFILES
*------------------------------------------------------
loc BACKUP 	0
di `BACKUP'
* IF BACKUP==1 it creates backup of all dofiles
loc MASTER	0
* IF MASTER==1 it creates master dofiles for all dofile subfolder

* Truecrypt mounting on/off
*------------------------------------------------------
loc TRUECRYPT 0
* IF TRUECRYPT==1 this d ofile opens all truecrypt files.
* IF TRUECRYPT==0 this dofile SKIPS opening all truecrypt files.
if "`1'" != "" loc TRUECRYPT "`1'"
	* this argument is being passed on from the master files if they are run.

loc INSTALLADO 0
loc INSTALLSSC 0
* IF INSTALLSSC==1 this dofile installs user-written programs that are online
* IF INSTALLSSC==0 this dofile SKIPS installing user-written programs that are online 

*************************************************************************
* (1) Define directory globals
*************************************************************************

* Set directory: Parent folders	
* -----------------------------------------------------------
if c(os) == "Windows" {	
	if c(username) == "mbode" {
		global DROPBOX	"C:/Users/`c(username)'/Documents/Dropbox"
		global DESKTOP	"C:/Users/`c(username)'/Desktop"
		global TC		"C:/Program Files/TrueCrypt"	
	}
	else {
		global DROPBOX 	"C:/Users/`c(username)'/Dropbox"
		global DESKTOP	"C:/Users/`c(username)'/Desktop"
		global TC		"C:/Program Files/TrueCrypt"	
	}	
}
else if c(os) == "MacOSX" {
	if c(username) == "Maxbode" {
		global DROPBOX 	"/Users/`c(username)'/Dropbox"		
		global DESKTOP	"/Users/`c(username)'/Desktop"
		global TC		"/Applications"		
	}
	else {
		global DROPBOX 	"/Users/`c(username)'/Dropbox"
		global DESKTOP	"/Users/`c(username)'/Desktop"
		global TC		"/Applications"		
	}	
}

global SMZ		"$DROPBOX/SMZ_MoH"
global PBF	 	"$SMZ/PBF General/PBF"
global ANALYSIS	"$DROPBOX/SMZ_MoH/PBF General/analysis"
global RESULTS	"$PBF/analysis outputs"

* Set directory: Data folders
* -----------------------------------------------------------
global RAW	 	"$ANALYSIS/data_raw"
global BACKUP  	"$ANALYSIS/data_raw_backup"
global ENTRY 	"$ANALYSIS/data_entry"
global CLEAN	"$ANALYSIS/data_clean"
global TEMP  	"$ANALYSIS/data_temp"
global ENTRY	"$ANALYSIS/data_entry"
global GENERAL	"$ANALYSIS/data_general"

global VIEW 	"$RESULTS/data_view"
global OUTPUTS 	"$RESULTS/outputs"
global GRAPH 	"$RESULTS/graphs"

global TOOLS	"$PBF/field tools"
global SURVEY	"$PBF/field tools/verification performance"

* Sub-sections
* -----------------------------------------------------------
global COMPARISON "06_comparison(c)"

* Set directory: DO/ADO-File folders (text files, tf)
* -----------------------------------------------------------
global DO		"$ANALYSIS/dofiles"
global DO_B		"$ANALYSIS/dofiles_backup"
global ADO	 	"$DROPBOX/statadir_mb"


global SUB_PCHU	"02_subsidy_phcu_(s_phcu)"
global SUB_CAP	"03_subsidy_capita_(s_cap)"



* Other globals
* -----------------------------------------------------------
global ID_PCHU 1301 1302 1303 1304 1305 1306 1307 1308 1309 1310 1311 1312 1313 1314 1315 1316 2601 2602 2603 2604 2605 2606 2607 2608 2609 2610 2611 2612 2613 2614

loc dofiledir 	"SUB_PCHU SUB_CAP"
/*
* Set directory: TrueCrypt Volumes
* -----------------------------------------------------------
global RAW_PII	"$RAW/raw.tc"

* Set directory: Output folders
* -----------------------------------------------------------
global OUTPUT_TEX 	"$ANALYSIS/output_tex"
global OUTPUT_GIS	"$ANALYSIS/output_gis"

global TABLES 		"$PBF/tables"
global PAPER 		"$PBF/paper/tables"

* Set directory: Log files
* -----------------------------------------------------------
global CMFLOG	"$ANALYSIS/log_cmd"
global LOG		"$ANALYSIS/log_normal"
*/
*************************************************************************
* (2) Define other global
*************************************************************************

* Define value labels and missing value global
* ----------------------------------------------------------
*run "$DO/01b_all_value_labels.do"

* Create Time Stamp
* -----------------------------------------------------------
loc time_h = substr("`c(current_time)'",1,2)
loc time_m = substr("`c(current_time)'",4,2)
loc time_s = substr("`c(current_time)'",-2,.)
loc date_y = substr("`c(current_date)'",-4,.)
loc date_m = substr("`c(current_date)'",4,3)
loc date_d = substr("`c(current_date)'",1,2)

global D = "`date_y'`date_m'`date_d'"
global DH = "`date_y'`date_m'`date_d'_`time_h'hrs"
global DHMS = "`date_y'`date_m'`date_d'_`time_h'_`time_m'_`time_s'"
global T = "`time_h'_`time_m'"
/*
* PII variables
* -----------------------------------------------------------
#delimit ;
global PII 	 ;
#delimit cr
*/
* View globals
* -----------------------------------------------------------
macro dir

*************************************************************************
* (3) Change system directory
*************************************************************************

if ( c(username) != "mbode" & c(os) == "Windows" ) | ( c(username) != "Maxbode" & c(os) == "MacOSX" )  {
	run "$DROPBOX/statadir_mb/personal/profile.do"
}

*sysdir set PERSONAL "C:\Users\mbode\Documents\Dropbox\EPoD\Projects\SEWA Bank Personal\analysis\tf_adofiles"

*************************************************************************
* (4) Install programs
*************************************************************************

* Install own .ado files
* -----------------------------------------------------------
if `INSTALLADO'==1 {

loc AD02 "$ADO"
di as result "`AD02'"

*-------  Install PLUS ados -------*
loc adoplusfolders_temp : dir "`AD02'/plus" dirs "*"

foreach letter in `adoplusfolders_temp' {
	if "`letter'"!="_"  {
		loc ado `letter'
		loc adoplusfolders `adoplusfolders' `ado' 
	}
}
di "`adoplusfolders'"

foreach letter in `adoplusfolders' {
	
	loc plusados : dir `"`AD02'/plus/`letter'"' files "*.ado"
	local plusados : subinstr local plusados  ".ado" "", all
	
	di as result `"`AD02'/plus/`letter'"'
	di as result `"`plusados'"'
	
	*do "$ADO/personal/install_all_ado_files_part1" 

	foreach ado in `plusados' {
		run "$ADO/personal/install_all_ado_files_part2.do" "`ado'" "`AD02'/plus/`letter'"
		di as result "Installation of {cmd:`ado'} complete."
	}
	
	/*
	foreach ado in `plusados' {
		di as text "`ado'"
		cap: run "`AD02'/plus/`letter'/`ado'"
	}
	*/
}

*------- Install PERSONAL ados -------*
do "$ADO/personal/install_all_ado_files_part1" "`AD02'/personal/"
}

* Install user-written .ado files
* -----------------------------------------------------------
if `INSTALLSSC'==1 {

	foreach X in estout texify sencode sdecode  mergeall truecrypt  findname  cfout {
		ssc install `X', replace
	}
	
	* ssc install dropmiss has to be done manually (- net search dm89_1 -)
	net search dm89_1
}

*************************************************************************
* (7) Write all master files and back up all dofiles 
*************************************************************************

* Create master dofiles
if `MASTER'==1 {
	foreach X in `dofiledir' {
		master `X'
	}
}

*************************************************************************
* (8) Back up all dofiles 
*************************************************************************

* Run master dofiles with COPY=1 and RUN=0
if `BACKUP'==1 {
	foreach X in `dofiledir' {
		loc lX = lower("`X'")
		di "$DO/$`X'/`lX'_02_master.do"	
		run "$DO/$`X'/`lX'_02_master.do"
	}
}

*************************************************************************
* (9) Temporary programs
*************************************************************************

* create folder with dofile structure
* -----------------------------------------------------------
/*
loc foldername templete
cap: rmdir "$ANALYSIS/`foldername'"
mkdir "$ANALYSIS/`foldername'"
foreach folder in `dofiledir' {
	mkdir "$ANALYSIS/`foldername'/$`folder'"
}
*/
*************************************************************************
* (10) Mount ALL truecrypt volumes
*************************************************************************

if `TRUECRYPT'==1 {
	loc drives y
	
	foreach drive in `drives' {
		if 			"`drive'"=="y" loc filename TEMP_PII
		else if 	"`drive'"=="v" loc filename CLEAN_PII
		else if 	"`drive'"=="z" loc filename RAW_PII
		else if 	"`drive'"=="w" loc filename PII_CLEAN
		else if 	"`drive'"=="t" loc filename RAW_TD
	
		etruecrypt, drive(`drive') mount replace off(`TRUECRYPT') progdir("$TC") filename("$`filename'")
	}
	*etruecrypt, drive(u) mount replace off(`TRUECRYPT') progdir("$TC") filename("$RAW_CHAWL_PII")	
}

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
