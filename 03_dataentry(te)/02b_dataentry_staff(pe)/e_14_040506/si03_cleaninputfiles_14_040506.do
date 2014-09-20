set linesize 225

*Setting value labels
run "$DO/01b_all_value_labels.do"

* Create PHCU locals
loc id_phcu = "$ID_PCHU"
di "`id_phcu'"

loc id_phcu_sin1 : subinstr loc id_phcu "1301 " ""
di "`id_phcu_sin1'"

* Set period
loc yy 14	 
loc period "`yy'_040506"


loc ASSERT 0

*************************************************************************
* Clean data
*************************************************************************

u "$TEMP/staffdata_`period'", clear

* Rename
fn *
foreach var in `r(varlist)' {
	loc newvar=lower("`var'")
	ren `var' `newvar'
}

ren *days* *days_
ren apr* *1
ren may* *2
ren jun* *3

ren	name1				hw01_name_1
ren name2				hw02_name_2 
ren name3				hw03_name_3
ren surname 			hw04_name_sur

ren days*				hw07_daysworked*
ren bankaccountnumber 	hw11_account_number
ren bank				hw13_bankname

ren cadre 				hw05_cadre_code		


*************************************************************************
* Improve IDs
*************************************************************************

preserve
u "$CLEAN/PHCU_IDs", clear

	drop id1 id2 id3 id4 id_d* id_z*
	tempfile PHCU_IDs 
	
	* Add Tasini
	describe, s
	loc N = `r(N)'+1
	set obs `N'
	replace id_phcu			= 1317		in `N'
	replace id_phcu_s		= "1-3-17"	in `N'
	replace id_phcu_name	= "Tasini"	in `N'
	
	
	sa `PHCU_IDs', replace
restore

* Merge in new IDs
drop phcuid zoneid
sort id_phcu
merge m:1 id_phcu using `PHCU_IDs', nogen 
order id*


* Order
order *, alpha
order id* hw* new*

*************************************************************************
* Label variables
*************************************************************************

run "$DO/01b_all_value_labels.do"

la val hw05_cadre_code cadrecodel
la val hw13_bankname bankl

codebook hw05_cadre_code hw13_bankname, t(30)

*************************************************************************
* Basicsalary
*************************************************************************
codebook hw05_cadre_code, t(30)

g hw06_salarylevel =.
replace hw06_salarylevel =7 if inlist(hw05_cadre_code,20,21)
replace hw06_salarylevel =6 if inlist(hw05_cadre_code,30,31,32)
replace hw06_salarylevel =5 if inlist(hw05_cadre_code,40,41,42,43,44,45)
replace hw06_salarylevel=3 if inlist(hw05_cadre_code,50)
replace hw06_salarylevel=2 if inlist(hw05_cadre_code,60,61,62,63,64,65)
replace hw06_salarylevel =1 if inlist(hw05_cadre_code,70)
ta  hw06_salarylevel, mi

*************************************************************************
* Account number checks
*************************************************************************

* #1 - Check bank account number length
g ba_length = length(hw11_account_number)
la var ba_length "Bank number length"

g ba_lengthcheck = 0 
replace ba_lengthcheck = 1 if ba_length==6 & hw13_bankname==5
replace ba_lengthcheck = 1 if ba_length==11 & hw13_bankname==4
replace ba_lengthcheck = 1 if ba_length==12 & hw13_bankname==1
replace ba_lengthcheck = 1 if ba_length==12 & hw13_bankname==3
replace ba_lengthcheck = 1 if ba_length==14 & hw13_bankname==2

la var ba_lengthcheck "Bank number length correct"
la val ba_lengthcheck yesnol

cb ba_lengthcheck
ta hw13_bankname ba_lengthcheck, mi
ta ba_length ba_lengthcheck, mi

set linesize 225
list id_hw id_phcu id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw11_account_number hw13_bankname ba_lengthcheck ba_length ///
	if ba_lengthcheck==0 

 
if `ASSERT'==1 assert ba_lengthcheck==1

g problem_ba_lengthcheck=0
replace problem_ba_lengthcheck=1 if ba_lengthcheck==0
la val problem_ba_lengthcheck yesnol
ta problem_ba_lengthcheck

* #2 - Starting Number 
g hw11_ba_first = substr(hw11_account_number,1,2)
bys hw13_bankname: ta hw11_ba_first

g ba_startnumber = 0 
replace ba_startnumber = 1 if inlist(hw11_ba_first,"03") & hw13_bankname==5
replace ba_startnumber = 1 if inlist(hw11_ba_first,"01") & hw13_bankname==4
replace ba_startnumber = 1 if inlist(hw11_ba_first,"02","03","04","05") & hw13_bankname==1
replace ba_startnumber = 1 if inlist(hw11_ba_first,"02") & hw13_bankname==3
replace ba_startnumber = 1 if inlist(hw11_ba_first,"51","52","53","54") & hw13_bankname==2

la var ba_startnumber "Bank number starting digits correct"
la val ba_startnumber yesnol

ta ba_startnumber 

bys hw13_bankname: ta hw11_ba_first if ba_startnumber==0
list id_hw id_phcu id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw11_account_number hw13_bankname ba_length ///
	if ba_startnumber!=1

	
g problem_ba_startnumber=0
replace problem_ba_startnumber=1 if ba_startnumber!=1
la val problem_ba_startnumber yesnol
ta problem_ba_startnumber

if `ASSERT'==1 assert ba_startnumber==1

*************************************************************************
* Outsheet trouble
*************************************************************************

fn hw*, type(string) remove(*name_sur*)
foreach var in `r(varlist)' {
	g mv_`var'=1 if `var'==""
	la val mv_`var' yesnol
	dropmiss mv_`var', force
	cap { 
		replace mv_`var'=0 if `var'!=""
		loc missingvar `missingvar' `var'
	} 
}

fn hw*, type(numeric) remove(*salarylevel*)
foreach var in `r(varlist)' {
	g mv_`var'=1 if `var'==.
	la val mv_`var' yesnol
	dropmiss mv_`var', force
	cap { 
		replace mv_`var'=0 if `var'!=.
		loc missingvar `missingvar' `var'
	}
}

	
g mv_token = 0
fn mv_*, loc(missing)
egen missing = rowtotal(`r(varlist)')
ta missing
fn mv_*, loc(missing)


*Setting value labels
run "$DO/01b_all_value_labels.do"

cb hw05_cadre_code
cb ba_lengthcheck	

drop id_hw_short


preserve
	drop id_hw_new

	cap: keep if missing!=0 | ba_lengthcheck==0 | problem_ba_startnumber==1 | problem_ba_lengthcheck==1

	keep id* id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur  hw05_cadre_code hw11_account_number hw13_bankname ba_lengthcheck problem* `missing' `missingvar' 	
	
	order id*  id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur hw05_cadre_code hw11_account_number hw13_bankname ba_lengthcheck  problem* `missing' `missingvar' 
	
	drop id_phcu
	
	describe, s
	if `r(N)'==0 set obs 1
	export excel using "$ENTRY/`period'_staff/`period'_report_missing_staffdata", ///
		replace firstrow(varlabels)
restore

drop mv_token

cap: drop  missing 
drop problem* ba* hw11_ba_first new_staff_time_q_s	new_staff_time_yy_s

*************************************************************************
* People we forgot last time
*************************************************************************

drop new_staff

sort id_hw_new
merge 1:1 id_hw_new using "$ENTRY/`period'_staff/missed_staff.dta", nogen

* Treat days worked
replace days_14_010203 = 0 if days_14_010203==.
replace days_14_010203 = round(days_14_010203/3,1)
forval i = 1/3 {
	replace hw07_daysworked_`i'=hw07_daysworked_`i'+days_14_010203
}

drop forgot days_14_010203

*************************************************************************
* Outsheet 
*************************************************************************

/*
export excel using "$VIEW/2014_010203_performancepay_new.xls", ///
	replace sheet(all) firstrow(varlabels)

sort PCHUname 

levelsof hw13_bankname, loc(banks)
foreach b in `banks' {
	preserve
	keep if hw13_bankname=="`b'"
	export excel using "$DATA/2013q4_performancepay_new.xls", ///
		sheetreplace sheet("`b'") firstrow(varlabels) 
	restore
}
*/

*************************************************************************
* Save
*************************************************************************

compress
drop new_staff_time_q new_staff_time_yy
sa "$CLEAN/si03_`period'(cleaninputs)", replace

* Outsheet
* Label
la var id_phcu 				"PHCU ID"
la var id_phcu_name 		"PCHU name"
la var id_hw 				"Staff ID"
la var hw01_name_1 			"Name 1"
la var hw02_name_2 			"Name 2"
la var hw03_name_3 			"Name 3"
la var hw04_name_sur		"Sur Name"
la var hw05_cadre_code 		"Cadre"

drop hw06_salarylevel
drop hw11_account_number hw13_bankname
export excel using "$VIEW/hr/staffdata_`period'", replace firstrow(varlabels)   
