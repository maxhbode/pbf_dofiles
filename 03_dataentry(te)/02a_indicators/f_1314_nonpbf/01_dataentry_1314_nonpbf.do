
set linesize 225

loc period 1314_nonpbf 

*******************************************************************************
* Import Data
*******************************************************************************

* First and Second Entry
forval ee = 1/2 {

	* Import
	*--------------------------------------	
	insheet using "$ENTRY/`period'/dataentry_`period'_entry`ee'.csv", clear comma
	
	
	* Dropmiss
	dropmiss, obs force
	dropmiss *, force
	
	* Create Entry indicator
	*--------------------------------------	
	g dataentryround = `ee'
	
	* Create PHCU ID
	*--------------------------------------
	g id_phcu = id1*1000+id2*100+id3
	duptest id_phcu
	drop id1 id2 id3
	order id_phcu id_phcu_name
	
	* Manual rename
	*--------------------------------------
	
	forval i = 1/12 {
		if `i'<10 loc i 0`i'
		
		ren *_`i' *_`i'_t
	} 

	
	
	ren b*_13_05_t b*_13_06_t
	ren b*_13_04_t b*_13_05_t
	ren b*_13_03_t b*_13_04_t

	ren *q1_* *010203_z*
	ren *q2_* *040506_z*
	ren *q3_* *070809_z*
	ren *q4_* *101112_z*

	foreach letter in t g zt zs zg {
		ren *13*_`letter' *`letter'_13*
		ren *14*_`letter' *`letter'_14*
	}
	
	


	* Section Skips
	drop s01
	*ren s01 b00_section_skip
	*ren s02 c00_section_skip 
	* MANUALLY CREATE SKIPS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	*keep id* b0`i'_t_13_03 b0`i'_t_13_04 b0`i'_t_13_05 b0`i'_t_13_030405 b0`i'_s_13_030405 b0`i'_`letter'_13_030405

	* Reshape	
	*--------------------------------------
	loc newvarlist	

	qui fn *13_04
	foreach var in `r(varlist)' {
		loc remove = substr("`var'",-6,.) 
		loc varnew = subinstr("`var'","`remove'","",1)
		loc newvarlist `varnew'_ `newvarlist'
	}	

	ren *13_* *13*
	ren *14_* *14*

	reshape long `newvarlist', i(id_phcu) j(id_period_ym)

	
	* Renaming 2.0
	*--------------------------------------
	ren *_ *
	
	foreach letter in zg zs zt {	
		forval i = 1/2 {
			g 			b0`i'_`letter'_quarter = .	
			replace 	b0`i'_`letter'_quarter = b0`i'_`letter'_13040506 if inlist(id_period_ym,1304,1305,1306)
			replace 	b0`i'_`letter'_quarter = b0`i'_`letter'_13070809 if inlist(id_period_ym,1307,1308,1309)
			replace 	b0`i'_`letter'_quarter = b0`i'_`letter'_13101112 if inlist(id_period_ym,1310,1311,1312)
			replace 	b0`i'_`letter'_quarter = b0`i'_`letter'_14010203 if inlist(id_period_ym,1401,1402,1403)
			replace 	b0`i'_`letter'_quarter = b0`i'_`letter'_14040506 if inlist(id_period_ym,1404,1405,1406)
			
			drop b0`i'_`letter'_13040506 b0`i'_`letter'_13070809 b0`i'_`letter'_13101112 b0`i'_`letter'_14010203 b0`i'_`letter'_14040506
		}
	}
	ren *zg_quarter *quarter_g 
	ren *zs_quarter *quarter_s
	ren *zt_quarter *quarter_t
	
	* Order
	order *, alpha
	order id* d* v*

	* Create Time IDs
	*--------------------------------------
	tostring id_period_ym, gen(id_period_ym_s)
	
	g id_period_yy = substr(id_period_ym_s,1,2)
	ta id_period_yy
	g id_period_mm = substr(id_period_ym_s,3,.)
	ta id_period_mm
		
	destring id_period_yy, replace
	destring id_period_mm, replace	
	
	* Create PHCU / MY
	*--------------------------------------
	tostring id_period_ym, replace
	tostring id_phcu, replace
	g id_phcu_ym = id_phcu + id_period_ym
	foreach var in id_period_ym id_phcu id_phcu_ym {
		destring `var', replace
	}
	duptest id_phcu_ym
		
	order id_phcu_ym id_phcu id_period_ym
	
	foreach var in id_phcu id_period_yy id_period_mm {
		tostring `var', gen(`var'_s)
	}
	g id_phcu_ym_s = id_phcu_s + "-" + id_period_yy_s + "-" + id_period_mm_s

	g id_zone_s = substr(id_phcu_s,1,1)
	g id_district_s = substr(id_phcu_s,2,1)
	g id_facility_s = substr(id_phcu_s,3,2)
	
	drop id_phcu_s
	g id_phcu_s = id_zone_s + "-" + id_district_s + "-" + id_district_s
	
	destring id_zone_s, g(id_zone)
	destring id_district_s, g(id_district)
	destring id_facility_s, g(id_facility)
	drop id_zone_s id_district_s id_facility_s

	* Save
	*--------------------------------------
	compress
	order id_phcu_ym id_phcu id* dm*  v04_visit_mdy
	tempfile `period'_dataentry_entry`ee'
	sa ``period'_dataentry_entry`ee'', replace
	
}

*******************************************************************************
* Compare
*******************************************************************************

loc date = "$D"

* CFOUT
foreach type in "upper string" "nostring" {
	u ``period'_dataentry_entry1', clear
	
	fn *, remove( dm* dataentryround) loc(varlist)
	cfout `varlist'  using ``period'_dataentry_entry2',  ///
		id(id_phcu_ym_s) `type'  ///
		name("$ENTRY/`period'/dataentry_`date'_report_`type'") replace
}

u ``period'_dataentry_entry1', clear
fn c* b*, loc(varlist) remove(  dm* dataentryround)
cfout `r(varlist)' using ``period'_dataentry_entry2',  ///
	id(id_phcu_ym_s)  nostring ///
	name("$ENTRY/`period'/dataentry_`date'_report_meat") replace		


*******************************************************************************	
*******************************************************************************	
*******************************************************************************	
	
u ``period'_dataentry_entry1', clear


*******************************************************************************	
* Quarter measure
*******************************************************************************		

g id_quarter=.
replace id_quarter=1 if inlist(id_period_ym,1304,1305,1306) 
replace id_quarter=2 if inlist(id_period_ym,1307,1308,1309) 
replace id_quarter=3 if inlist(id_period_ym,1310,1311,1312) 
replace id_quarter=4 if inlist(id_period_ym,1401,1402,1403) 
replace id_quarter=5 if inlist(id_period_ym,1404,1405,1406)

ta id_quarter, mi
	
	
*******************************************************************************	
* Correction of bad data collection
*******************************************************************************		
	
* New data collected by mary
g temp1 = b01_quarter_g/b01_quarter_s

list id_phcu_name id_period_ym temp1 b01_quarter_t b01_quarter_s  b01_quarter_g  if id_phcu==2208

*----------------------------
* Nungwi
*----------------------------

* 2013 Apr-Jun --- ??????
replace b01_quarter_s=. if inlist(id_period_ym,1304,1305,1306) & id_phcu==2208
replace b01_quarter_g=. if inlist(id_period_ym,1304,1305,1306) & id_phcu==2208

* 2013	Jul-Sep	37/73
replace b01_quarter_g=37 if inlist(id_period_ym,1307,1308,1309) & id_phcu==2208
replace b01_quarter_s=73 if inlist(id_period_ym,1307,1308,1309) & id_phcu==2208

* 2013	OctÐDec	26/93
replace b01_quarter_g=26 if inlist(id_period_ym,1310,1311,1312) & id_phcu==2208
replace b01_quarter_s=93 if inlist(id_period_ym,1310,1311,1312) & id_phcu==2208

* 2014	JanÐMar	33/80
replace b01_quarter_g=33 if inlist(id_period_ym,1401,1402,1403) & id_phcu==2208
replace b01_quarter_s=80 if inlist(id_period_ym,1401,1402,1403) & id_phcu==2208

* 2014	Apr-Jun	57/116
replace b01_quarter_g=57 if inlist(id_period_ym,1404,1405,1406) & id_phcu==2208
replace b01_quarter_s=116 if inlist(id_period_ym,1404,1405,1406) & id_phcu==2208

g temp2 = b01_quarter_g/b01_quarter_s
list id_phcu_name id_period_ym temp2 b01_quarter_t b01_quarter_s  b01_quarter_g  if id_phcu==2208


preserve
	keep if id_phcu==2208
	collapse (mean) temp1 temp2, by(id_quarter)
	g diff=temp2-temp1
	drop temp2 temp1 diff
restore 





*******************************************************************************
* Save
*******************************************************************************

compress
sa "$CLEAN/de02_`period'(reconciled)", replace


