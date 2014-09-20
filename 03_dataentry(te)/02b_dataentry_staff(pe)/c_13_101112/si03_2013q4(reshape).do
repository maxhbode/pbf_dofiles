
u "$TEMP/si02_2013q4(cleaninputs)", clear

*-----------------------------------------------------
* Last minute changes
*-----------------------------------------------------

replace hw05_cadre_code=32 if id_hw==260509 
replace hw05_cadre_code=45 if id_hw==261104

*************************************************************************
* Test
*************************************************************************

*Setting value labels
run "$DO/01b_all_value_labels.do"

la val hw05_cadre_code cadrecodel
codebook hw05_cadre_code, t(30)

* Outsheet problems with cadre code
preserve
	keep if inlist(id_hw,130105, 130106, 130107, 130110, 130123, 130124, 130401, 130402, 130504, 130601, 130703, 130823, 131023, 131206, 131502, 131603, 131625, 260102, 260203, 260301, 260304, 260423, 260503, 260508, 260509, 260516, 260518, 260522, 260531, 261001, 261004, 261104, 261201, 261203, 261204)

	clonevar cadre_code = hw05_cadre_code
	la val cadre_code cadrecodel
	
	sort id_hw
	keep id_hw id_phcu id_phcu_name id_period_mm hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur hw05_cadre_code cadre_code
	export excel using "$DESKTOP/cadre_code_problem.xls", replace firstrow(variables) nolabel
restore


*******************************************************************************
* Outsheet
*******************************************************************************
/*
* Order first
order *, alpha

sort id_hw

* Drop data
drop source_changetype source_comment
order *, alpha
order confirm corrected, last
order id*

drop hw11_account_number hw12_bankcode_number hw13_comment

sort id_hw

* Staring loop	
levelsof id_phcu, loc(id_phcu)

foreach mm in 11 12 {
	di as result "`mm': `id_phcu'"

	foreach phcu in `id_phcu' {
		preserve	
	
		qui keep if id_phcu==`phcu' & id_period_mm==`mm'
		qui drop id_period_mm
	
		qui export excel using "$DESKTOP/staffdata/newstaffdata_2013_`mm'", ///
			firstrow(variables) sheetreplace  sheet("`phcu'") nolabel 	
	
		restore
	}
}
*/

*************************************************************************
* Drop problems
*************************************************************************

*drop if inlist(id_hw,130105, 130106, 130107, 130110, 130123, 130124, 130401, 130402, 130504, 130601, 130703, 130823, 131023, 131206, 131502, 131603, 131625, 260102, 260203, 260301, 260304, 260423, 260503, 260508, 260509, 260516, 260518, 260522, 260531, 261001, 261004, 261104, 261201, 261203, 261204)

*drop if hw07_daysworked>=.
*drop if hw05_cadre_code>=. | hw05_cadre_code>70 | hw05_cadre_code<10

*************************************************************************
* Create New Individual ID
*************************************************************************

/*

bys id_hw: egen startdate=min(id_period_mm)

replace startdate = 1300+startdate

bys startdate: g n = _n

ren id_hw id_hw_old

sort hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur
g id_hw = startdate * 1000 + n
drop n


*/

*************************************************************************
* Unverified fix of values
*************************************************************************

list id_phcu id_phcu_name hw01* hw02* hw03* hw05_cadre_code if id_hw==261203 
replace hw05_cadre_code=70 if id_hw==261203 & id_period_mm==12

*************************************************************************
* Reshape
*************************************************************************

sort id_hw id_period_mm
order id* c*, last
order id_hw id_period_mm

*br id_hw id_period_mm hw01* hw02* hw03* hw04*
*keep id_hw id_period_mm hw07_daysworked hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur

drop confirm corrected id_phcu_s source_changetype source_comment id_phcu_ym hw13_comment* hw12_bankcode_number hw11_account_number
drop hw09_reason_code hw10_reason_comment

reshape wide hw07_daysworked, i(id_hw) j(id_period_mm) 


* hw09_reason_code hw10_reason_comment id_phcu
ren hw07_daysworked* hw07_daysworked_*

*************************************************************************
* Manipulate Values
*************************************************************************

*-----------------------------------------------------
* Days worked
*-----------------------------------------------------
fn hw07*
foreach var in `r(varlist)' {
	replace `var'=0 if `var'>=.
}

order id_hw id_phcu hw05* id_hw hw07* 

*-----------------------------------------------------
* Basicsalary
*-----------------------------------------------------
codebook hw05_cadre_code, t(30)

g hw_salarylevel =.
replace hw_salarylevel =7 if inlist(hw05_cadre_code,20,21)
replace hw_salarylevel =6 if inlist(hw05_cadre_code,30,31,32)
replace hw_salarylevel =5 if inlist(hw05_cadre_code,40,41,42,43,44,45)
replace hw_salarylevel=3 if inlist(hw05_cadre_code,50)
replace hw_salarylevel=2 if inlist(hw05_cadre_code,60,61,62,63,64,65)
replace hw_salarylevel =1 if inlist(hw05_cadre_code,70)
ta  hw_salarylevel, mi

/*
g hw_salarylevel =. ;
replace hw_salarylevel =7 if inlist(hw05_cadre_code,"AMO") ;
replace hw_salarylevel =6 if inlist(hw05_cadre_code,"Clinical Officer",
"Community Health Nurse","Dental Technician") ;
replace hw_salarylevel =5 if inlist(hw05_cadre_code,"Pharm. Technician",
"Pharmacist","Nurse General", "Nurse Midwife","Nurse Psychiatrist",
"Health Officer","Lab. Technician") ;
replace hw_salarylevel=3 if inlist(hw05_cadre_code,`"Public Health Nurse "B""') ;
replace hw_salarylevel=2 if inlist(hw05_cadre_code,"Lab. Assistant",
"Health Assistant","MCH Aide","Pharm. Assistant","Pharm. Dispenser",
"Health Assistant","Dental Assistant") ;
replace hw_salarylevel =1 if inlist(hw05_cadre_code,"Watchman","Support Staff",
"Special Gang","Orderly") ;
*/

*************************************************************************
* Changing values
*************************************************************************
	
replace hw07_daysworked_10=23 if id_hw==260301
replace hw07_daysworked_10=23 if id_hw==260302	
replace hw07_daysworked_10=23  if id_hw==260303	
replace hw07_daysworked_10=23 if id_hw==260304	
replace hw07_daysworked_10=23 if id_hw==260307	
replace hw07_daysworked_10=23 if id_hw==260308	

replace hw07_daysworked_11=21 if id_hw==260303
replace hw07_daysworked_12=20 if id_hw==260303

*************************************************************************
* Save
*************************************************************************

order id_hw id_phcu hw07* hw_salarylevel hw05_cadre_code
qui compress
sa "$CLEAN/si03_2013q4(reshape)", replace


