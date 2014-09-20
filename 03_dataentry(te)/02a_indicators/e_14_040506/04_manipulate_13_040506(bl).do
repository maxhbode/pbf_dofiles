
**************************************************************************
* Preamble
**************************************************************************

set linesize 225

loc yy 13
loc mm1 04 
loc mm2 05
loc mm3 06
loc period bl_`yy'_`mm1'`mm2'`mm3'

* Open
u "$CLEAN/de02_`period'(reconciled)", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

* Drop vars
drop id_period_mm_s id_period_yy id_period_yy_s id_period_ym

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
ta b0_section_skip, mi 
ta id_phcu_name if b0_section_skip==0 // Dropping values of RCH Mkoani

replace b0_section_skip=0
replace b0_section_skip=1 if inlist(id_phcu,1312)

* Section C
ren c00_section_skip c0_section_skip
recode c0_section_skip (0=.)
recode c0_section_skip (2=0)
la val c0_section_skip yesnol
ta c0_section_skip, mi
ta id_phcu_name if c0_section_skip==0 // Dropping values of Beit-El-Raas & Matrakta

replace c0_section_skip=0
replace c0_section_skip=1 if inlist(id_phcu,2601,2612)
ta id_phcu_name if c0_section_skip==1

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

* assert missing_b==0 & missing_c==0 // PROBLEM WITH MISSING DATA IN KIZIMIBANI !!!!!!!!!!!!!
* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
drop missing_b missing_c

**************************************************************************
* Creating Basic Variables
**************************************************************************

ren b01 b01_t 
ren b02 b02_t 

*-----------------------------------------------------
* B01 & B02: Calculate "REAL G" from SG and S
*-----------------------------------------------------

ren b*_g b*_sg

forval i = 1/2 {
	g b0`i'_13_040506_g = b0`i'_13_040506_sg/b0`i'_13_040506_s 
	replace b0`i'_13_040506_g = 0 if b0`i'_13_040506_s==0 & b0`i'_13_040506_sg==0
	replace b0`i'_13_040506_g = .d if b0_section_skip==1
}

* Drop S & SG (Sample & Sample Group) Variable
drop *_sg *_s 

*-----------------------------------------------------
* B00: Sum U5 & O5 together for B01 & B02
*-----------------------------------------------------

* Sum U5 & O5 together for B01 & B02
g b00_13_040506_g = b01_13_040506_g + b02_13_040506_g
g b00_13_040506_t = b01_13_040506_t + b02_13_040506_t
g b00_t = b01_t + b02_t

order *, alpha
order id* b00* b01* b02*



* Consider FUONI EXCEPTION: No distinction between B01 & B02
replace b00_13_040506_g	= b01_13_040506_g	if id_phcu==2605
replace b00_13_040506_t	= b01_13_040506_t	if id_phcu==2605
replace b00_t			= b01_t				if id_phcu==2605

foreach var in b01_13_040506_g	b01_13_040506_t	b01_t	b02_13_040506_g	b02_13_040506_t	b02_t {
	replace `var' = .d 			if id_phcu==2605
}

order *, alpha 
order id*

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
outsheet `r(varlist)' using "$ENTRY/14_040506/problems_baseline.csv", c replace
restore

*******************************************************************************
*  Creating constructed monthly quality measures
*******************************************************************************

forval i = 0/2 {
	g b0`i'_g = round(b0`i'_t * b0`i'_13_040506_g,1)
}
replace b00_g = b01_g+b02_g if id_phcu!=2605 /* Inverse of Fuoni exception */
replace b01_g = .d if id_phcu==2605
replace b02_g = .d if id_phcu==2605

drop *13_040506*

*******************************************************************************
* Check 
*******************************************************************************


g b01_g_pct = b01_g/b01_t
g b02_g_pct = b02_g/b02_t

list id_phcu id_period_mm id_phcu_name b01_g_pct if b01_g_pct >1
list id_phcu id_phcu_name b02_g_pct if b02_g_pct >1

drop *pct

*******************************************************************************
* Save
*******************************************************************************

drop *problem*

sort id_phcu_ym
order *, alpha
order id_phcu_ym id* b* c* v* 
qui compress
sa "$TEMP/ded04_`period'(manipulate)", replace
