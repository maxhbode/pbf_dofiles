
**************************************************************************
* Preamble
**************************************************************************

set linesize 120

loc period 1314_nonpbf 

* Open
u "$CLEAN/de02_nonpbf_`period'(reconciled)", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

* Drop vars
drop id_period_mm_s id_period_yy_s id_period_ym

g id_period_yyyy=2000+id_period_yy

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
g b0_section_skip=0
*replace b0_section_skip=1 if inlist(id_phcu,1312)

* Section C
g c0_section_skip=0
*replace c0_section_skip=1 if inlist(id_phcu,2601,2612)

*-----------------------------------------------------
* Skips: Curative Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if b0_section_skip==1
fn b*, remove(b0_section_skip )
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
fn c*, remove(c0_section_skip )
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
fn b*, type(numeric) remove()
foreach var in `r(varlist)' {
	replace missing_b = missing_b+1 if `var'>=. & b0_section_skip==0
}
g missing_c = 0
fn c*, type(numeric) remove()
foreach var in `r(varlist)' {
	replace missing_c = missing_c+1 if `var'>=. & c0_section_skip==0
}

ta missing_b 
ta missing_c 

list id_phcu id_period_mm id_phcu_name  missing_b missing_c if missing_b>=1 | missing_c>=1 

*assert missing_b==0
*assert missing_c==0


preserve
	keep id_phcu id_period_mm id_phcu_name  missing_b missing_c 
	keep if missing_b>=1 | missing_c>=1 
	outsheet `r(varlist)' using "$ENTRY/`period'/problems_missing.csv", c replace
restore

drop missing_b missing_c

**************************************************************************
* Creating Basic Variables
**************************************************************************

*-----------------------------------------------------
* B01 & B02: Calculate "REAL G" from SG and S
*-----------------------------------------------------

ren b*_g b*_sg

forval i = 1/2 {
	g b0`i'_quarter_g = b0`i'_quarter_sg/b0`i'_quarter_s 
	replace b0`i'_quarter_g = 0 if b0`i'_quarter_s==0 & b0`i'_quarter_sg==0
	replace b0`i'_quarter_g = .d if b0_section_skip==1
}

* Drop S & SG (Sample & Sample Group) Variable
drop *_sg *_s 

*-----------------------------------------------------
* B00: Sum U5 & O5 together for B01 & B02
*-----------------------------------------------------

* Sum U5 & O5 together for B01 & B02
g b00_quarter_g = b01_quarter_g + b02_quarter_g
g b00_quarter_t = b01_quarter_t + b02_quarter_t
g b00_t = b01_t + b02_t

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

order *, alpha 
order id*

**************************************************************************
* Logical Value test
**************************************************************************

* (1) Negative Values in Indicators
fn b* c*, remove( *_skip)
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
		g `var'_problem_g=0
		replace `var'_problem_g=1 if `newvar'_g>`newvar'_t
		su `var'_problem_g
		loc errovalue = `r(mean)'
	}
	if `errovalue'>0 {
		di as error "ERROR: `var' has values where Guidline cases > Total cases"
		ta `var'_problem_g
		list id_phcu id_phcu_name id_period_mm `newvar'_g `newvar'_t if `var'_problem_g==1
	}
	if `errovalue'<=0 {
		drop `var'_problem_g
	}
}

g problem_g = 0
fn *problem_g
foreach var in `r(varlist)' {
	replace problem_g = 1 if `var'==1
	loc problemvar : subinstr loc var "_problem_g" ""
	loc problemvars `problemvars' `problemvar'
}

* Outsheet list of Problems	
preserve
keep if problem_g==1
keep id_phcu_ym id_phcu_name *problem_g `problemvars'
order *, alpha
order id_phcu_ym id_phcu_name
fn *, remove(problem_g)
outsheet `r(varlist)' using "$ENTRY/1314_nonpbf/problems_baseline.csv", c replace
restore

*******************************************************************************
* Extra section
*******************************************************************************


g b01_g = round(b01_t * b01_quarter_g,1)
g b02_g = round(b02_t * b02_quarter_g,1)
g b00_g = b01_g+b02_g

drop *quarter*

*******************************************************************************
* Check 
*******************************************************************************


g b01_g_pct = b01_g/b01_t
g b02_g_pct = b02_g/b02_t

list id_phcu id_period_mm id_phcu_name b01_g_pct if b01_g_pct >1 & b01_g_pct <.
list id_phcu id_phcu_name b02_g_pct if b02_g_pct >1 & b02_g_pct<.

assert b01_g_pct<=1 if b01_g_pct<. 
assert b02_g_pct<=1 if b02_g_pct<.

drop *pct


*******************************************************************************
* Treatment variables
*******************************************************************************
g treatment=0 
la var treatment "Treatment"
la val treatment yesnol

*******************************************************************************
* Save
*******************************************************************************

drop *problem*

sort id_phcu_ym
order *, alpha
order id_phcu_ym id* b* c* v* 
qui compress
sa "$TEMP/def02(manipulate)", replace
