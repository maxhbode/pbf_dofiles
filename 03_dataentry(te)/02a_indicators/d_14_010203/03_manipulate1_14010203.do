
**************************************************************************
* Preamble
**************************************************************************

loc period 14_010203
set linesize 120

* Open
u "$TEMP/de03_`period'(renamed)", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

**************************************************************************
* Cleaning Indicators Only (Section B * C only)
**************************************************************************

*******************************************************************************
* Section skips
*******************************************************************************

*-----------------------------------------------------
* Fix Skips
*-----------------------------------------------------

* Section B
ren b00_section_skip b0_section_skip
recode b0_section_skip (0=.)
recode b0_section_skip (2=0)
la val b0_section_skip yesnol
ta b0_section_skip, mi // What is missing (previous 0)? !!!!!!!!!!!!!!!!!
ta id_phcu_name if b0_section_skip==0 // Dropping RCH Mkoani

replace b0_section_skip=0
replace b0_section_skip=1 if inlist(id_phcu,1312)

* Section C
ren c00_section_skip c0_section_skip
recode c0_section_skip (0=.)
recode c0_section_skip (2=0)
la val c0_section_skip yesnol
ta c0_section_skip, mi
ta id_phcu_name if c0_section_skip==0 // Dropping Beit-El-Raas & Matrakta

replace c0_section_skip=0
replace c0_section_skip=1 if inlist(id_phcu,2601,2612)

*-----------------------------------------------------
* Skips: Curative Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if b0_section_skip==1
fn b*, remove(b0_section_skip *comment)
foreach var in `r(varlist)' {
	replace `var'=.d if b0_section_skip==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_period_mm id_zone if b0_section_skip!=1 // Pemba = 15, Unguja = 14

*-----------------------------------------------------
* Skips: Preventative Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if c0_section_skip ==1
fn c*, remove(c0_section_skip *comment)
foreach var in `r(varlist)' {
	replace `var'=.d if c0_section_skip ==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_period_mm id_zone if c0_section_skip!=1 // Pemba = 16, Unguja = 12

**************************************************************************
* Missing data
**************************************************************************

fn *, type(numeric)
mvdecode `r(varlist)', mv(-999=.a \ -998=.b \ -997=.c \ -996=.d \ -995=.e)

g missing_b = 0
fn b*, type(numeric) remove(*comment)
foreach var in `r(varlist)' {
	replace missing_b = missing_b+1 if `var'>=. & b0_section_skip==0
}
g missing_c = 0
fn c*, type(numeric) remove(*comment)
foreach var in `r(varlist)' {
	replace missing_c = missing_c+1 if `var'>=. & c0_section_skip==0
}

ta missing_b 
ta missing_c 

list id_phcu id_period_mm id_phcu_name  missing_b missing_c if missing_b>=1 | missing_c>=1 

**************************************************************************
* Creating Basic Variables
**************************************************************************

*-----------------------------------------------------
* B01 & B02: Calculate "REAL G" from SG and S
*-----------------------------------------------------

* Rename "G" to "SG" 
forval var = 1/2 {
	ren b0`var'*_g b0`var'*_sg
}

* Generate "REAL G" (that is the constructed G)
foreach type in nv v {
	forval var = 1/2 {
		g b0`var'_`type'_g = (b0`var'_`type'_sg / b0`var'_`type'_s) * b0`var'_`type'_t
		replace b0`var'_`type'_g = 0 if b0`var'_`type'_s==0 & b0`var'_`type'_sg==0
		replace b0`var'_`type'_g = .d if b0_section_skip==1
	}
}

* Drop S & SG (Sample & Sample Group) Variable
drop *_sg *_s 

*-----------------------------------------------------
* B00: Sum U5 & O5 together for B01 & B02
*-----------------------------------------------------

* Sum U5 & O5 together for B01 & B02
foreach t1 in "nv_" "v_" {
	foreach t2 in t g {
		di as result "b00_`t1'`t2' created"
		g b00_`t1'`t2' = b01_`t1'`t2'+b02_`t1'`t2'
	}
}

order *, alpha
order id* b00* b01* b02*

/*
* Consider FUONI EXCEPTION (STILL THE SAME !!!!!!!!!!!!!!!!!!!!!!!!!!! )
fn b00*
foreach var in `r(varlist)' {
	loc suffix = substr("`var'",5,4)
	
	replace b00_`suffix' = b01_`suffix' if id_phcu_ym==26051411
	replace b01_`suffix' = .d if id_phcu_ym==26051411
	replace b02_`suffix' = .d if id_phcu_ym==26051411
}
*/

order b00*, after(b0_section_skip)

*-----------------------------------------------------
* All B & C variables: SUM V+NV
*-----------------------------------------------------

foreach section in b c {
if "`section'"=="b" loc range 0/8
if "`section'"=="c" loc range 1/11
		forval question = `range' {
		if `question'<10 loc question = "0`question'"
				 
		egen `section'`question'_t = ///
			rowtotal(`section'`question'_v_t `section'`question'_nv_t)
	
		cap: egen `section'`question'_g = ///
			rowtotal(`section'`question'_v_g `section'`question'_nv_g)
	}
}

**************************************************************************
* Logical Value test
**************************************************************************

* (1) Negative Values in Indicators
fn b* c*, remove(*_comment *_skip)
foreach var in `r(varlist)' {
	
	qui {
		g `var'_problem_neg=0
		replace `var'_problem_neg=1 if `var'<0
		su `var'_problem_neg
	}
	if `r(mean)'>0 {
		di as error  "`var' has negative values"
	}
	if `r(mean)'<=0 {
		drop `var'_problem_neg
	}
}

* (2) Guidline cases > Total cases 
fn *_g
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_g" ""
	qui {
		g `var'_problem_guideline=0
		replace `var'_problem_guideline=1 if `newvar'_g>`newvar'_t
		su `var'_problem_guideline
		loc errovalue = `r(mean)'
	}
	if `errovalue'>0 {
		di as error "ERROR: `var' has values where Guidline cases > Total cases"
		ta `var'_problem_guideline
		list id_phcu id_phcu_name id_period_mm `newvar'_g `newvar'_t if `var'_problem_guideline==1
	}
	if `errovalue'<=0 {
		drop `var'_problem_guideline
	}
}

g problem_guideline = 0
fn *problem_guideline
foreach var in `r(varlist)' {
	replace problem_guideline = 1 if `var'==1
	loc problemvar : subinstr loc var "_problem_guideline" ""
	loc problemvars `problemvars' `problemvar'
}

* Outsheet list of Problems	
preserve
keep if problem_guideline==1
keep id_phcu_ym id_phcu_name *problem_guideline `problemvars'
order *, alpha
order id_phcu_ym id_phcu_name
fn *, remove(problem_guideline)
*outsheet `r(varlist)' using "$DO/treatment/02a_DATAENTRY_PER(de_p)/d_14_010203/problems.csv", c replace
restore

*******************************************************************************
* Save
*******************************************************************************

sort id_phcu_ym
order *, alpha
order id_phcu_ym id* b* c* a* v* 
qui compress
sa "$TEMP/ded04(manipulate)", replace
