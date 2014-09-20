
set linesize 225
loc period 14_010203
* v01healthfacilityname

*******************************************************************************
* Import Data
*******************************************************************************

* First and Second Entry
forval ee = 1/2 {

	* Import
	insheet using "$ENTRY/`period'/`period'_dataentry_entry`ee'.csv", clear comma

	* Create Entry indicator
	g dataentryround = `ee'

	* Manual ID correction
	cap: replace id1=1 if id1==10
	cap: replace id3=16 if id3==1165
	sort id1 id2 id3
	
	* Create PHCU ID
	g id_phcu = id1*1000+id2*100+id3
	duptest id_phcu

	* Reshape
	ren *_14* *_*
	ren *_01_* **_01
	ren *_02_* **_02
	ren *_03_* **_03
	
	loc newvarlist	

	qui fn *_01
	foreach var in `r(varlist)' {
		loc remove = substr("`var'",-3,3) 
		loc varnew = subinstr("`var'","`remove'","",1)
		loc newvarlist `varnew'_0 `newvarlist'
	}
	di "`newvarlist' "

	reshape long `newvarlist', i(id_phcu) j(id_period_mm)
	ren *_0 *

	* Create Month ID
	g id_period_yy = 14
	g id_period_yyyy = 2000 + id_period_yy
	g id_period_ym = id_period_yy*100 + id_period_mm
	ta id_period_ym

	* Create PHCU / MY
	g id_phcu_ym = id_phcu*10000 + id_period_ym
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

	* Tostring numeric "Sting" variables 	 
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
	*/
		
	* Data type		
	fn a*c
	foreach var in `r(varlist)' {
		tostring `var', replace
	}

	* Save
	order id_phcu_ym id_phcu id* dm*  v04_visit_mdy
	tempfile `period'_dataentry_entry`ee'
	sa ``period'_dataentry_entry`ee'', replace

}

*******************************************************************************
* Compare
*******************************************************************************

loc date = "$D"

* TEMPORARILY DROP SECTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
forval ee = 1/2 {
	u ``period'_dataentry_entry`ee'', clear

	fn a* c12_c b09_c dm* dataentryround
	drop `r(varlist)'
	
	tempfile temp_`period'_dataentry_entry`ee'
	sa `temp_`period'_dataentry_entry`ee'', replace
	
}

* CFOUT
foreach type in "upper string" "nostring" {
	u `temp_`period'_dataentry_entry1', clear
	
	cfout using `temp_`period'_dataentry_entry2',  ///
		id(id_phcu_ym_s) `type'  ///
		name("$ENTRY/`period'/dataentry_`date'_report_`type'") replace
		
}

u `temp_`period'_dataentry_entry1', clear
fn c* b*, loc(varlist)
cfout `r(varlist)' using `temp_`period'_dataentry_entry2',  ///
	id(id_phcu_ym_s)  nostring ///
	name("$ENTRY/`period'/dataentry_`date'_report_meat") replace		

*******************************************************************************
* Value corrections based on manual check
*******************************************************************************

forval ee = 1/2 {
	u ``period'_dataentry_entry`ee'', clear
	
	replace id_phcu_name="Mwambe" if id_phcu_name=="Muambe"
	*replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit - El - Raas"
	replace id_phcu_name="Chuwini" if id_phcu_name=="Chuini"
	
	sa `temp_`period'_dataentry_entry`ee'_clean', replace
}


* DECIDED TO MAKE B04 IPC QUALITY = 0 IN 2608
replace b04v_g=0 if id_period_mm==3

* Insert c03=0 in Fuoni
fn c03* 
foreach var in `r(varlist)' {
	replace `var'=0 if id_phcu==2605
}

* Insert deliviers into Fuoni
replace c06v_g  = round(23/60*53,1) if id_phcu==2605 & id_period_mm==1
replace c06v_g  = round(11/50*64,1) if id_phcu==2605 & id_period_mm==2
replace c06v_g  = round(9/34*51,1)  if id_phcu==2605 & id_period_mm==3
replace c06nv_g = .d if id_phcu==2605
list id_phcu id_period_mm c06* if id_phcu==2605

*******************************************************************************
* Save
*******************************************************************************

compress
sa "$CLEAN/de02_`period'(reconciled)", replace


