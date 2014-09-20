set linesize 225

u "$TEMP/de04_1112(manipulate)", clear

drop data*

keep id* d*

*******************************************************************************
* Reshape 
*******************************************************************************

loc varlist1 daysworkedx reason_code reason_comment mistake_correction 
loc varlist2 sid cadre_code comment corrects daysworked name1 name2 name3 namesur

*-----------------------------------------------------
* Rename for reshape 
*-----------------------------------------------------

ren *a_daysworked *a_daysworkedx

* Varlist 1
foreach var in `varlist1' {
	if "`var'"=="daysworkedx"			loc letter a 
	if "`var'"=="reason_code"			loc letter b
	if "`var'"=="reason_comment"		loc letter c 
	if "`var'"=="mistake_correction"	loc letter d 
	
	ren *`letter'_`var' *`var'
}

* Varlist 1 & 2
foreach var in `varlist1' `varlist2' {
	ren *`var' `var'_*
}	


ren *_d* *1*
ren *_ *
ren id1istrict id_district

*-----------------------------------------------------
* Reshape
*-----------------------------------------------------
reshape long `varlist1' `varlist2', i(id_phcu_ym) j(id_hw)

*-----------------------------------------------------
* Rename
*-----------------------------------------------------

foreach var in `varlist1' {
	ren `var' a_`var'
}

foreach var in `varlist2' {
	ren `var' hw_`var'
}

order id* a* hw* 

ren a_daysworkedx a_daysworked

*-----------------------------------------------------
* Create id_hw
*-----------------------------------------------------

replace id_hw = id_hw - 100

* String
tostring id_hw, g(id_hw_s2)
g id_hw_s = id_phcu_s + "-" + id_hw_s2
drop id_hw_s2

* Numeric
g sectiond = id_hw
replace id_hw = id_phcu*100+id_hw 
*replace id_hw_s = id_phcu_s 

*******************************************************************************
* Clean
*******************************************************************************

* Manually encode
g hw_changetype = . 
replace hw_changetype = 1 if hw_corrects=="New"
replace hw_changetype = 2 if hw_corrects=="Correction"  
la de changetypel 1 "New" 2 "Correction"
la val hw_changetype  changetypel
drop hw_corrects

*******************************************************************************
* Section A only
*******************************************************************************

* Section A
preserve
drop if sectiond>22
drop hw*
drop if a_daysworked==.d & a_reason_code==.d & a_mistake_correction==.d
sa "$TEMP/section_a", replace
restore 

* Section B
drop if sectiond<=22
drop a*
drop if hw_cadre_code>=. &  hw_daysworked>=. & hw_changetype>=.
ren hw_name* hw_name_* 
drop hw_sid
sa "$TEMP/section_b", replace

*******************************************************************************
* Merge with old data
*******************************************************************************

* Options: 20131106, 20131210
/*
u "$TEMP/test", clear
keep if id_period_mm==12
merge m:m id_hw using "$CLEAN/20131210_staff" 
order id* hw* a* sectiond _merge
drop if _merge==2 // FIX THE ONE ORDERLY OVER 23 (FUONI HAS MOST STAFF)
ta _merge
br if _merge==1


u "$TEMP/test", clear
keep if id_period_mm==11
merge m:m id_hw using "$CLEAN/20131106_staff" 
order id* hw* a* sectiond _merge
drop if _merge==2 // FIX THE ONE ORDERLY OVER 23 (FUONI HAS MOST STAFF)
ta _merge
br if _merge==1


u "$TEMP/test", clear
merge m:m id_hw using "$CLEAN/20131106_staff" 
*/

u "$TEMP/section_a", clear
merge m:m id_hw using "$CLEAN/20131210_staff"

ren hw_name_first	hw_name_1
ren hw_name_second	hw_name_2
ren hw_name_third 	hw_name_3
ren hw_name_sur		hw_name_sur
ren hw_jobid 		hw_cadre_code  
ren a_daysworked	hw_daysworked
ren a_reason_code 	hw_reason_code
ren a_reason_comment hw_reason_comment

*******************************************************************************
* Append New People
*******************************************************************************

append using "$TEMP/section_b"
g source = 0 
replace source = 1 if sectiond>=22
la de sourcel 0 "Old" 1 "New"
la val source sourcel 
ta source

*******************************************************************************
* Rename
*******************************************************************************

ren hw_name_1 				hw01_name_1
ren hw_name_2 				hw02_name_2
ren hw_name_3 				hw03_name_3
ren hw_name_sur				hw04_name_sur
ren hw_cadre_code			hw05_cadr_code
ren a_mistake_correction 	hw06_mistake
ren hw_daysworked			hw07_daysworked
ren hw_reason_code			hw10_reason_code
ren hw_reason_comment		hw09_reason_comment

ren hw_changetype source_changetype
ren hw_comment source_comment

/*
ren a_reason_code 			hw08_reason_code
ren a_reason_comment		hw09_reason_comment
*/


*******************************************************************************
* Save
*******************************************************************************




*******************************************************************************
* Outsheet
*******************************************************************************

* Rename
ren hw05_cadr_code hw05_cadre_code

foreach var in hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur {
	replace `var' = upper(`var')
}

* Order first
order *, alpha
order source*  id*
order _merge, last

* Drop vars
drop hw_incharge hw_jobid_s hw_salarylevel hw_sex sectiond hw_facilitytype
loc drop id_district_name id_district_name2 ///
	id_period_yyyy id_phcu_name_org	id_hw_s		id_phcu_s id_phcu_ym_s ///
	id_zone_name id_district	id_facility id_zone source
drop *merge
drop `drop'


* New vars
g confirm = "no"
g corrected = "no"
g account_number = "missing"
sdecode source_changetype, replace

* Order
order 	id_hw confirm correct source_changetype source_comment  hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur ///	
		hw05_cadre_code hw07_daysworked hw10_reason_code hw09_reason_comment hw06_mistake ///
		id_phcu	id_phcu_name	id_phcu_ym account_number

sort id_hw

* Staring loop	
levelsof id_phcu, loc(id_phcu)

foreach mm in 11 12 {
	di as result "`mm': `id_phcu'"

	foreach phcu in `id_phcu' {
		preserve	
	
		qui keep if id_phcu==`phcu' & id_period_mm==`mm'
		qui drop id_period_mm
	
		qui export excel using "$DESKTOP/staffdata/staffdata_2013_`mm'", ///
			firstrow(variables) sheetreplace  sheet("`phcu'") nolabel 	
	
		restore
	}
}

SSTOP
* Import 
foreach mm in 11 12 {
	foreach phcu in `id_phcu' {
		import excel using "$DESKTOP/staffdata/staffdata_2013_`mm'",  sheet("`phcu'") clear firstrow
		sa "$TEMP/temp_`mm'_`phcu'", replace
	}
}
