
loc yy 13

set linesize 170

loc RECONCILE 1

* (1) Import data
* (2) Rename variables to match
* (3) Append all months 

************************************************************************
* (1) Import data
************************************************************************

if `RECONCILE'==1 {

* Months
forval m = 7/9 {
*foreach m in 9 {
if 		`m'<10  loc mm = "0`m'"
else if `m'>=10 loc mm = "`m'"

	
	*------------------------------------
	* 1st and 2nd entry
	forval i = 1/2 {
		di as error "month `m' - entry `i'"
		insheet using "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry`i'_trans.csv", clear name
		ren *_n *_N
		cap: drop *_ym
		sa "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry`i'_trans", replace
	}


	* Reconcile 1st and 2nd entry
	*------------------------------------
	* 1st and 2nd entry
	forval i = 1/2 {
		u "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry`i'_trans", clear
		run "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_report_corr`i'.do"
		sa "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry`i'_trans", replace
		
		nois di as error "$ENTRY/`mm'/dataentry_2013`mm'_entry`i'_trans"
	}
	
	*------------------------------------
	u "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry1_trans", clear
	#delimit ;
	cfout using "$ENTRY/`yy'_`mm'/dataentry_2013`mm'_entry2_trans", 
		id(id_phcu) upper 
		name("$ENTRY/`yy'_`mm'/dataentry_2013`mm'_report") replace ;
	#delimit cr
}

}

************************************************************************
* (2) Rename variables to match
************************************************************************

* July 2013
*------------------------------------

u "$ENTRY/`yy'_07/dataentry_201307_entry1_trans", clear
ren verification_period_m v04a_verification_period_mren verification_period_y v04b_verification_period_yren visit_date_d v05a_visit_date_dren visit_date_m v05b_visit_date_mren visit_date_y v05c_visit_date_y

* renumbering 
ren pm*_* b*_*
foreach i in 01 02 03 12 16 {
	ren b`i'* a`i'*
}

ren a16* a04*
ren a12* a05*

ren b04* b01*
ren b05* b02*
ren b06* b03*
ren b07* b04*
ren b08* b05*
ren b09* b06*
ren b10* b07*
ren b11* b08*
ren b13* b09*
ren b14* b10*
ren b15* b11*
ren b17* b12*

ren incharge_name g04_incharge_name
ren incharge_signature g04_incharge_signature 

order *, alpha
order id* v* a* b*

sa "$RAW/dataentry_201307", replace


* August 2013
*------------------------------------

u "$ENTRY/`yy'_08/dataentry_201308_entry1_trans", clear
ren verification_period_m v04a_verification_period_mren verification_period_y v04b_verification_period_yren visit_date_d v05a_visit_date_dren visit_date_m v05b_visit_date_mren visit_date_y v05c_visit_date_y

* renumbering 
ren pm*_* b*_*
foreach i in 01 02 03 12 16 {
	ren b`i'* a`i'*
}

ren a16* a04*
ren a12* a05*

ren b04* b01*
ren b05* b02*
ren b06* b03*
ren b07* b04*
ren b08* b05*
ren b09* b06*
ren b10* b07*
ren b11* b08*
ren b13* b09*
ren b14* b10*
ren b15* b11*
ren b17* b12*

ren incharge_name g04_incharge_name
ren incharge_signature g04_incharge_signature 

order *, alpha
order id* v* a* b*

sa "$RAW/dataentry_201308", replace

* September 2013
*------------------------------------

u "$ENTRY/`yy'_09/dataentry_201309_entry1_trans", clear

ren verification_period_m v04a_verification_period_mren verification_period_y v04b_verification_period_yren visit_date_d v05a_visit_date_dren visit_date_m v05b_visit_date_mren visit_date_y v05c_visit_date_y

ren visit_teammembers_name 	v07a_visit_enumerator_id
ren visit_teammembers_ids	v06a_visit_enumerators_name
ren visit_enumerator_id 	v07_visit_enumerator_id
ren visit_enumerators_name	v06_visit_enumerators_name

sa "$RAW/dataentry_201309", replace

************************************************************************
* (3) Append all months 
************************************************************************

u "$RAW/dataentry_201307", clear
g source = 7

forval m = 8/9 {
	di as error "month `m'"
	append using "$RAW/dataentry_20130`m'", gen(source_`m')
	replace source = `m' if source_`m'==1
	drop source_`m'
}

************************************************************************
* Save "clean" RAW data 
************************************************************************


ren *vita* *vitA*
order *, alpha
order id* v* a* b* d* g*  s*


compress
sa "$RAW/verification_2013q3", replace

