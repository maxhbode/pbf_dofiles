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
loc period "`yy'_010203"

*************************************************************************
* Clean data
*************************************************************************

u "$TEMP/staffdata_14_010203", clear

* Rename
fn *
foreach var in `r(varlist)' {
	loc newvar=lower("`var'")
	ren `var' `newvar'
}
ren	name1				hw01_name_1
ren name2				hw02_name_2 
ren name3				hw03_name_3
ren surname 			hw04_name_sur
ren days*				hw07_daysworked*
ren rc*					hw09_reason_code*
ren bankaccountnumber 	hw11_account_number
ren bankname			hw13_bankname

* Order
order *, alpha
order id* hw*

* Destring
cb hw05_cadre_code
replace hw05_cadre_code = substr(hw05_cadre_code,-3,2)
cb hw05_cadre_code

fn id_hw hw05_cadre_code hw07_daysworked* hw09_reason_code*, loc(numeric)

foreach var in `numeric' {
	di as error "Destringing `var'"

	destring `var', replace
}

destring hw09_reason_code_3, replace force /// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

*************************************************************************
* Improve IDs
*************************************************************************

preserve
u "$CLEAN/PHCU_IDs", clear
drop id1 id2 id3 id4 id_d* id_z*
tempfile PHCU_IDs 
sa `PHCU_IDs', replace
restore

* Extract ID_PHCU
tostring id_hw, gen(id_hw_s)
g id_phcu=substr(id_hw_s,1,4)
destring id_phcu, replace
drop id_hw_s

* Merge in new IDs
drop id_phcu_name
sort id_phcu
merge m:1 id_phcu using `PHCU_IDs', nogen
order id*

*************************************************************************
* Label variables
*************************************************************************

la val hw05_cadre_code cadrecodel
codebook hw05_cadre_code, t(30)


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

replace hw13_bankname="PBZ Islamic Bank" if hw13_bankname=="PBZ islamic"

* #1 - Check bank account number length
g ba_length = length(hw11_account_number)
la var ba_length "Bank number length"

g ba_lengthcheck = 0 
replace ba_lengthcheck = 1 if ba_length==6 & hw13_bankname=="FBME B"
replace ba_lengthcheck = 1 if ba_length==10 & hw13_bankname=="NMB"
replace ba_lengthcheck = 1 if ba_length==11 & hw13_bankname=="Postal Bank"
replace ba_lengthcheck = 1 if ba_length==12 & hw13_bankname=="PBZ"
replace ba_lengthcheck = 1 if ba_length==12 & hw13_bankname=="NBC"
replace ba_lengthcheck = 1 if ba_length==14 & hw13_bankname=="PBZ Islamic Bank"

la var ba_lengthcheck "Bank number length correct"
la val ba_lengthcheck yesnol

cb ba_lengthcheck
ta hw13_bankname ba_lengthcheck, mi
ta ba_length ba_lengthcheck, mi

set linesize 225
list id_hw id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw11_account_number hw13_bankname ba_lengthcheck ba_length ///
	if ba_lengthcheck==0
assert ba_lengthcheck==1

* #2 - Starting Number 
g hw11_ba_first = substr(hw11_account_number,1,2)
bys hw13_bankname: ta hw11_ba_first

g ba_startnumber = 0 
replace ba_startnumber = 1 if inlist(hw11_ba_first,"03") & hw13_bankname=="FBME B"
replace ba_startnumber = 1 if inlist(hw11_ba_first,"22") & hw13_bankname=="NMB"
replace ba_startnumber = 1 if inlist(hw11_ba_first,"01") & hw13_bankname=="Postal Bank"
replace ba_startnumber = 1 if inlist(hw11_ba_first,"02","03","04","05") & hw13_bankname=="PBZ"
replace ba_startnumber = 1 if inlist(hw11_ba_first,"02") & hw13_bankname=="NBC"
replace ba_startnumber = 1 if inlist(hw11_ba_first,"51","52","53","54") & hw13_bankname=="PBZ Islamic Bank"

la var ba_startnumber "Bank number starting digits correct"
la val ba_startnumber yesnol

ta ba_startnumber 

bys hw13_bankname: ta hw11_ba_first if ba_startnumber==0
assert ba_startnumber==1

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

fn hw*, type(numeric) remove(*reason_code* *salarylevel*)
foreach var in `r(varlist)' {
	g mv_`var'=1 if `var'==.
	la val mv_`var' yesnol
	dropmiss mv_`var', force
	cap { 
		replace mv_`var'=0 if `var'!=.
		loc missingvar `missingvar' `var'
	}
}

cap {
	fn mv_*, loc(missing)
	egen missing = rowtotal(`r(varlist)')
	ta missing
}

*Setting value labels
run "$DO/01b_all_value_labels.do"

cb hw05_cadre_code
cb ba_lengthcheck	

preserve
	cap: keep if missing!=0 | ba_lengthcheck==0
	cap: keep if ba_lengthcheck==0
	keep id* id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur  ba_lengthcheck  `missing' `missingvar' 
	order id*  id_phcu_name hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur ba_lengthcheck  `missing' `missingvar' 
	drop id_phcu
	
	describe, s
	if `r(N)'==0 set obs 1
	export excel using "$ENTRY/14_010203_staff/report_missing_staffdata", ///
		replace firstrow(varlabels)
restore

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

cap: drop missing

compress
drop ba_length ba_lengthcheck
sa "$CLEAN/si02_14_0102003_DIRTY(cleaninputs)", replace


* Outsheet
la var id_phcu 				"PHCU ID"
la var id_phcu_name 		"PCHU name"
la var id_hw 				"Staff ID"
la var hw01_name_1 			"Name 1"
la var hw02_name_2 			"Name 2"
la var hw03_name_3 			"Name 3"
la var hw04_name_sur		"Sur Name"
la var hw05_cadre_code 		"Cadre"

la var hw07_daysworked_1 	"Jan: Days worked"
la var hw07_daysworked_2 	"Feb: Days worked"
la var hw07_daysworked_3	"Mar: Days worked"

drop hw09_reason_code_1 hw09_reason_code_2 hw09_reason_code_3
drop hw11_account_number hw13_bankname hw06_salarylevel hw11_ba_first ba_startnumber

export excel using "$VIEW/hr/staffdata_`period'", replace firstrow(varlabels)   
