
set linesize 225

loc yy 14
loc mm1 04 
loc mm2 05
loc mm3 06
loc period `yy'_`mm1'`mm2'`mm3'

*******************************************************************************
* Import Data
*******************************************************************************

* First and Second Entry
forval ee = 1/2 {

	* Import
	*--------------------------------------	
	insheet using "$ENTRY/`period'/dataentry_`period'_entry`ee'.csv", clear comma
	
	* Create Entry indicator
	*--------------------------------------	
	g dataentryround = `ee'
	
	* Create PHCU ID
	*--------------------------------------
	g id_phcu = id1*1000+id2*100+id3
	duptest id_phcu
	
	* Manual rename
	*--------------------------------------
	ren *1401* *1404*
	ren *1402* *1405*
	ren *1403* *1406*
	
	ren *`yy'`mm1'_* **_`yy'_`mm1'
	ren *`yy'`mm2'_* **_`yy'_`mm2'
	ren *`yy'`mm3'_* **_`yy'_`mm3'
	
	* Section Skips
	ren s01 b00_section_skip
	ren s02 c00_section_skip

	* Comments
	ren b09_c b07_sectionb_comment
	ren c14_c c14_sectionc_comment

	* Drop this data
	drop s_* 
		
	* Reshape	
	*--------------------------------------
	loc newvarlist	

	qui fn *_`mm1'
	foreach var in `r(varlist)' {
		loc remove = substr("`var'",-3,3) 
		loc varnew = subinstr("`var'","`remove'","",1)
		loc newvarlist `varnew'_0 `newvarlist'
	}
	di "`newvarlist' "

	reshape long `newvarlist', i(id_phcu) j(id_period_mm)
	ren *_14_0 *

	* Create Month ID
	*--------------------------------------
	g id_period_yy = `yy'
	g id_period_yyyy = 2000 + id_period_yy
	g id_period_ym = id_period_yy*100 + id_period_mm
	ta id_period_ym

	
	ta id_period_ym

	
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

	* Tostring numeric "String" variables 	 
	/*
	fn NONE
		loc vars `r(varlist)' d25namesur d25corrects d26namesur d26corrects 
		
	foreach var in  `vars'   {
		cap: tostring `var', replace 
	}
	
	findname *, type(string)
	foreach var in `r(varlist)' {
		replace `var'="" if `var'=="."
	}
	
		
	* Data type		
	fn a*c
	foreach var in `r(varlist)' {
		tostring `var', replace
	}
	*/
	
	* Manaual corrections
	*--------------------------------------	
	replace id_phcu_name="Mwambe" if id_phcu_name=="Muambe"
	*replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit - El - Raas"
	replace id_phcu_name="Chuwini" if id_phcu_name=="Chuini"
	
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
	
	fn *, remove(*_comment dm* dataentryround) loc(varlist)
	cfout `varlist'  using ``period'_dataentry_entry2',  ///
		id(id_phcu_ym_s) `type'  ///
		name("$ENTRY/`period'/dataentry_`date'_report_`type'") replace
}

u ``period'_dataentry_entry1', clear
fn c* b*, loc(varlist) remove( *_comment dm* dataentryround)
cfout `r(varlist)' using ``period'_dataentry_entry2',  ///
	id(id_phcu_ym_s)  nostring ///
	name("$ENTRY/`period'/dataentry_`date'_report_meat") replace		


* TEMPORARY CORRECTION OF WRONG VALUE
*******************************************************************************	
	
u ``period'_dataentry_entry2', clear	
	
ta id_phcu_name c00_section_skip if   c00_section_skip!=1		
recode c00_section_skip (2=0)

*******************************************************************************
* Save
*******************************************************************************

compress
sa "$CLEAN/de02_`period'(reconciled)", replace


