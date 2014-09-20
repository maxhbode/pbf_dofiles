

set linesize 225

loc yy 13
loc mm1 04 
loc mm2 05
loc mm3 06
loc period bl_`yy'_`mm1'`mm2'`mm3'

*******************************************************************************
* Import Data
*******************************************************************************

* First and Second Entry
forval ee = 1/2 {

	* Import
	*--------------------------------------	
	insheet using "$ENTRY/14_040506/dataentry_14_040506_entry`ee'.csv", clear comma

	* Create Entry indicator
	*--------------------------------------	
	g dataentryround = `ee'
	
	* Create PHCU ID
	*--------------------------------------
	g id_phcu = id1*1000+id2*100+id3
	duptest id_phcu

	* Drop this data
	*--------------------------------------	
	fn b* c*, remove (b09_c c14_c)
	drop `r(varlist)'
	
	* Manual rename
	*--------------------------------------
	ren s_* *
	ren *_q_* *_g_*
	ren *apr *13_04
	ren *may *13_05
	ren *jun *13_06
	ren *_all 		*_13_040506_t
	ren *_ag 		*_13_040506_g
	ren *_sample 	*_13_040506_s

	* Section Skips
	ren s01 b00_section_skip
	ren s02 c00_section_skip

	* Comments
	ren b09_c b07_sectionb_comment
	ren c14_c c14_sectionc_comment
		
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
	ren *_`yy'_0 *

	* Create Month ID
	*--------------------------------------
	g id_period_yy = `yy'
	g id_period_yyyy = 2000 + id_period_yy
	g id_period_ym = id_period_yy*100 + id_period_mm
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
		name("$ENTRY/14_040506/dataentry_bl_`date'_report_`type'") replace
}

u ``period'_dataentry_entry1', clear
fn c* b*, loc(varlist) remove( *_comment dm* dataentryround)
cfout `r(varlist)' using ``period'_dataentry_entry2',  ///
	id(id_phcu_ym_s)  nostring ///
	name("$ENTRY/14_040506/dataentry_bl_`date'_report_meat") replace		
	
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


