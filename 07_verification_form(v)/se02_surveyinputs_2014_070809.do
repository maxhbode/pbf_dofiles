

*u "$CLEAN/20131210_staff_wide", clear

*outvarlist *, re(name)

u "$CLEAN/si02_14_0102003_DIRTY(cleaninputs)", clear


* Generate id_zone
*-----------------------------------
tostring id_phcu, gen(id_zone)
replace id_zone = substr(id_zone,1,1)
destring id_zone, replace

* Rename vars
*-----------------------------------
ren hw01_name_1 	hw_name_first
ren hw02_name_2 	hw_name_second
ren hw03_name_3 	hw_name_third
ren hw04_name_sur 	hw_name_sur
ren hw05_cadre_code	hw_jobid  	

* Drop vars
*-----------------------------------
drop *daysworked* *reason_code*
drop hw11_account_number hw13_bankname ba_startnumber hw11_ba_first id_phcu_s hw06_salarylevel
* need id_zone

* Health Worker ID and name
*-----------------------------------

* Job ID
tostring hw_jobid, force replace
g hw_jobid1 = substr(hw_jobid,1,1)
g hw_jobid2 = substr(hw_jobid,2,1)
drop hw_jobid  

* HW ID
tostring id_hw, g(id_hw_s)
g id1 = substr(id_hw_s,1,1)
g id2 = substr(id_hw_s,2,1)
g id3 = substr(id_hw_s,3,1)
g id4 = substr(id_hw_s,4,1)


* Get cut-off value for number of staff in facility
*-----------------------------------

bys id_phcu: g staff_N = _N

ta id_phcu_name if staff_N>20

* Rename
*-----------------------------------
ren hw_name_* hw_n*
order id* hw_nfirst hw_nsecond hw_nthird  hw_nsur hw_jobid1 hw_jobid2
ren *first *1
ren *second *2
ren *third *3 
ren *sur *4   
ren hw_* hw_*_
ren *jobid* *j*

ren hw_* h*

*************************************************************************
* Reshape
*************************************************************************
drop id_hw_s id_hw

bys id_phcu: g id_hw_n = _n

qui su id_hw_n
di `r(max)'
assert `r(max)'==25 // testing that we have the right amount of people in questionaire

*destring hid_, generate(id_hw)
fn h*, loc(varlist)
reshape wide `varlist', i(id_phcu id_zone) j(id_hw_n)


*************************************************************************
* New facility
*************************************************************************

order id*

describe, short
loc N = `r(N)'+1
set obs `N'

replace id_phcu=1317 in `N'
replace id_zone=1  in `N'
replace id_phcu_name="Tasini" in `N'
replace id1="1" in `N'
replace id2="3" in `N'
replace id3="1" in `N'
replace id4="7" in `N'
replace staff_N=19 in `N'


*************************************************************************
* Merge
*************************************************************************

* PHCU money

preserve
insheet using "$DESKTOP/pp_piftotal.csv", clear c
drop v3
tempfile temp_piftotal
sa `temp_piftotal', replace
restore

merge 1:1 id_phcu using `temp_piftotal'
list id_phcu _merge if _merge!=3
drop _merge

* Merge Price & Equity Category data 
preserve
	u "$CLEAN/pricelist_14_070809(a04label)", clear
	merge 1:m cat using "$CLEAN/phcuinfo_equitycat(02_phcu_equity)"
	drop if _merge==1
	assert _merge!=2
	drop _merge
	tempfile temp
	sa `temp', replace
restore

merge 1:1 id_phcu using `temp'
list id_phcu_name _merge if _merge!=3
*assert _merge==3
drop _merge

* Limit Printing
*-----------------------------------

* BY ZONE: PEMBA (1) / Unguja (2)
*keep if id_zone==1

* BY FACILITY: 
list id_phcu id_phcu_name, noobs

*drop if inlist(id_phcu,2605,2611,2603,2604,2612,2607,2601,2613)
list id_phcu id_phcu_name, noobs

* Save & Export
*-----------------------------------

ta id_zone
drop id_zone

* BLANKS
describe, s
loc N = `r(N)'+1
set obs `N'

* Month specific variables !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
g y = 2014
g mm1 = "July"
g mm2 = "August"
g mm3 = "September"
g m1 = substr(mm1,1,3)
g m2 = substr(mm2,1,3)
g m3 = substr(mm3,1,3)
g q = m1 + "-" + m3
* ---> WE NEED TO CHECK PUBLIC HOLIDAYS!!!!
g d1 = 22 // 23 WEEK DAYS
g d2 = 21 // 20 WEEK DAYS
g d3 = 22 // 21 WEEK DAYS




* Save by facility size
qui compress
order *, alpha
order id_* id* q y m1 m2 m3 mm1 mm2 mm3 d1 d2 d3 cat* 

foreach type in small big {
if 		"`type'"=="small"	loc sign <
else if "`type'"=="big"		loc sign >

	preserve
	
		keep if staff_N`sign'20
		drop staff_N

		sa "$TEMP/staff_forsurvey", replace
		export excel using "$SURVEY/1 forms/2014_070809/PHCUinfo_`type'.xlsx", replace firstrow(var) nolabel

	restore
}


FINISHED

/*

* STAFF DATA FROM SEPTEMBER
u "$TEMP/staff_data_sep", clear

fn d*, type(string)
foreach var in `r(varlist)' {
	replace `var'="" if inlist(`var',"-999","-998","-997","-996")
}

fn d*, type(numeric)
foreach var in `r(varlist)' {
	replace `var'=. if inlist(`var',-999,-998,-997,-996)
}

sa "$TEMP/staff_data_sep2", replace

* MERGE 
*-----------------------------------

u "$CLEAN/PHCU_IDs", clear
keep id_phcu_name id_phcu_s id1 id2 id3 id4

merge 1:1 id_phcu_s using "$TEMP/staff_data_sep2", nogen

ren *healthworker_* **
ren d*name d*na
ren d*account d*ac
ren d*cadre d*ca
ren d*phone d*ph

sort d01a_id

replace d03c_ca="Ordley" if id_phcu_s=="1-3-05"
replace d03c_ca="Orderly" if id_phcu_s=="1-3-15"		
replace d03a_id="103" if id_phcu_s=="1-3-05"
replace d03a_id="103" if id_phcu_s=="1-3-15"
destring d03a_id, replace

fn *, type(numeric)
foreach var in `r(varlist)' {
	format `var' %16.0f
}

fn d*ac 
foreach var in `r(varlist)' {
	cap: format `var' %16.0f
	cap: destring `var', force replace
	*tostring `var', generate(`var'_temp)
	*forval i = 1/13 {
	*	g `var'`i'= substr("`var'_temp",`i',1)
	*}
}
*/



 
