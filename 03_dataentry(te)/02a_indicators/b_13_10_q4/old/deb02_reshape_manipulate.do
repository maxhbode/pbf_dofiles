**************************************************************************
* Preamble
**************************************************************************

set linesize 225

* Open
u  "$TEMP/01_cfout_rename", clear

* ERROR (IN SURVEY FORM)
replace xb01_s09=61 if id_phcu==1310
replace xb01_s09=63 if id_phcu==1310

* Install value Labels
run "$DO/01b_all_value_labels.do"

*******************************************************************************
* Cleaning 
*******************************************************************************
*******************************************************************************
* Panel (Section B * C only)
*******************************************************************************

*******************************************************************************
* Renaming for reshape
*******************************************************************************
ren c* c*_10
ren b* b*_10
ren xb* b*
ren xc* c*

foreach i in 6 7 8 9 {
	ren *0`i' *_0`i'
}

foreach section in b c {
	cap: ren `section'*a_v* 	`section'*_v*
	cap: ren `section'*b_v* 	`section'*_v*
	cap: ren `section'*c_v* 	`section'*_v*
	cap: ren `section'*c_nv* 	`section'*_nv*
	cap: ren `section'*d_nv* 	`section'*_nv*
	cap: ren `section'*e_nv* 	`section'*_nv*
	cap: ren `section'*f_nv* 	`section'*_nv*
}	


* Standarize Oct names
foreach letter in t s g {
	cap: ren b*_*_`letter'_10 b*_`letter'_*_10 
	cap: ren c*_*_`letter'_10 c*_`letter'_*_10
}

*******************************************************************************
* Save panel vars
*******************************************************************************

* Save panel vars
fn a* v* *comment* f*, loc(panelsvars)

* Save panel vars
preserve
compress
keep id* `panelsvars'
sa "$TEMP/oct_wide", replace
restore

* Drop panelvars
drop `panelsvars'
fn id*, remove(id_phcu id_phcu_name id_zone)
drop `r(varlist)'

*******************************************************************************
* Missing values
*******************************************************************************

fn *, type(numeric)
mvdecode `r(varlist)', mv(-999=.a \ -998=.b \ -997=.c \ -996=.d \ -995=.e)

*******************************************************************************
* Section skips
*******************************************************************************

*-----------------------------------------------------
* Fix Skips
*-----------------------------------------------------

* Section B
g b0_section_skip=0
replace b0_section_skip=1 if inlist(id_phcu,1312)
la val b0_section_skip yesnol

* Section C
g c0_section_skip=0
replace c0_section_skip=1 if inlist(id_phcu,2601,2612)
la val c0_section_skip yesnol

*-----------------------------------------------------
* Skips: OPD Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if b0_section_skip==1
fn b*, remove(b0_section_skip)
foreach var in `r(varlist)' {
	replace `var'=.d if b0_section_skip==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_zone if b0_section_skip!=1 // Pemba = 15, Unguja = 14

*-----------------------------------------------------
* Skips: Preventative Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if c0_section_skip ==1
fn c*, remove(c0_section_skip)
foreach var in `r(varlist)' {
	replace `var'=.d if c0_section_skip ==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_zone if c0_section_skip!=1 // Pemba = 16, Unguja = 12


*-----------------------------------------------------
* DATA MANIPULATION
*-----------------------------------------------------

*-----------------------------------------------------
* B01 & B02: Calculate "REAL G" from SG and S
*-----------------------------------------------------

* Rename "FAKE G"
foreach m in 06 07 08 09 v_10 nv_10 {
	forval var = 1/2 {
		ren b0`var'_g_`m' b0`var'_sg_`m' 
	}
}

* Generate "REAL G" 
foreach m in 06 07 08 09 v_10 nv_10 {
	forval var = 1/2 {
		g b0`var'_g_`m' 	= (b0`var'_sg_`m' / b0`var'_s_`m') * b0`var'_t_`m'
		*g b0`var'_g_`m'_pct = (b0`var'_sg_`m' / b0`var'_s_`m')
		replace b0`var'_g_`m' = 0 if b0`var'_s_`m'==0 & b0`var'_sg_`m'==0
		replace b0`var'_g_`m' = .d if b0_section_skip==1				
	}
}

* DROP ALL THE SAMPLING VARS
fn b*_s_* b*_sg_*
drop `r(varlist)'

*-----------------------------------------------------
* B00: Sum U5 & O5 together for B01 & B02
*-----------------------------------------------------

* Sum U5 & O5 together for B01 & B02
foreach m in 06 07 08 09 v_10 nv_10 {
	foreach type in t g {
		di as result "b00_`type'_`m' created"
		g b00_`type'_`m' = b01_`type'_`m' + b02_`type'_`m'
	}
}



* Consider FUONI EXCEPTION
fn b00*
foreach var in `r(varlist)' {
	loc suffix = substr("`var'",5,4)
	
	replace b00_`suffix' = b01_`suffix' if id_phcu==2605
	replace b01_`suffix' = .d if id_phcu==2605
	replace b02_`suffix' = .d if id_phcu==2605
}


*-----------------------------------------------------
* All B & C variables: SUM V+NV
*-----------------------------------------------------

foreach section in b c {
if "`section'"=="b" loc range 0/6
if "`section'"=="c" loc range 1/13
		forval question = `range' {
		if `question'<10 loc question = "0`question'"
				
		egen `section'`question'_t_10 = ///
			rowtotal(`section'`question'_t_v_10 `section'`question'_t_nv_10)
	
		cap: egen `section'`question'_g_10 = ///
			rowtotal(`section'`question'_g_v_10 `section'`question'_g_nv_10)
	}
}


order *, alpha
order id* b*skip b* c*skip c*

*-----------------------------------------------------
* Rename NV/V
*-----------------------------------------------------
ren *t_v* *v_t*
ren *g_v* *v_g*
ren *t_nv* *nv_t*
ren *g_nv* *nv_g*

**************************************************************************
* Reshape long
**************************************************************************

forval i = 6/9 {	
	ren *_0`i' *_`i'
}

* Reshape
qui findname *_10

foreach var in `r(varlist)' {
	
	loc var : subinstr loc var "_10" ""
	loc var "`var'_"
	loc varlist `var' `varlist' 
}
loc varlist `varlist'
di "`varlist'"

reshape long `varlist', i(id_phcu) j(id_period_mm) 


ren *_ *
la val id_period_mm months

**************************************************************************
* New Unique ID
**************************************************************************

g id_period_yyyy = 2013
g id_period_yy = 13

foreach var in id_phcu id_period_yy id_period_mm {
	tostring `var', gen(`var'_s)

}

replace id_period_mm_s = "0"+id_period_mm_s if id_period_mm<10

g id_phcu_ym_s = id_phcu_s +"_"+ id_period_yy_s+"_"+ id_period_mm_s
g id_phcu_ym = id_phcu_s+ id_period_yy_s+ id_period_mm_s
destring  id_phcu_ym, replace
format %20.0f id_phcu_ym
codebook id_phcu_ym
order id_phcu_ym*


drop id_phcu_s id_period_yy_s id_period_mm_s

order *, alpha
order id* b*skip b* c*skip c*


*******************************************************************************
* Value corrections
* Based on a recollection of data (Sep 2014)
*******************************************************************************


replace b01_v_t=147		if id_phcu_ym==26041307  
replace b01_v_g=35/68	if id_phcu_ym==26041307    
replace b01_nv_t=122	if id_phcu_ym==26041307   
replace b01_nv_g=7/15 	if id_phcu_ym==26041307  
replace b02_v_t=87  	if id_phcu_ym==26041307   
replace b02_v_g=25/54  	if id_phcu_ym==26041307  
replace b02_nv_t=56 	if id_phcu_ym==26041307  
replace b02_nv_g=3/11 	if id_phcu_ym==26041307 

replace b01_t = b01_v_t+b01_nv_t	if id_phcu_ym==26041307 
replace b02_t = b02_v_t+b02_nv_t	if id_phcu_ym==26041307 
replace b01_g = b01_v_g+b01_nv_g	if id_phcu_ym==26041307 
replace b02_g = b02_v_g+b02_nv_g	if id_phcu_ym==26041307 

replace b00_t = b01_t + b02_t		if id_phcu_ym==26041307 
replace b00_g = b01_g + b02_g		if id_phcu_ym==26041307 

*******************************************************************************
* Value corrections
* Based on a manual check
*******************************************************************************

replace c05_nv_g=1 if id_phcu_ym==13011310
replace c05_v_g=1 if id_phcu_ym==13011310
replace c05_v_g=0 if id_phcu_ym==13021310
replace c05_v_g=0 if id_phcu_ym==13031310
replace c05_nv_g=0 if id_phcu_ym==13041310
replace c05_nv_t=0 if id_phcu_ym==13041310
replace c05_v_g=10 if id_phcu_ym==13041310
replace c07_nv_t=0 if id_phcu_ym==13041310
replace c05_v_g=0 if id_phcu_ym==13051310
replace c05_v_g=0 if id_phcu_ym==13071310
replace c09_nv_t=44 if id_phcu_ym==13071310
replace c10_nv_t=44 if id_phcu_ym==13071310
replace c11_nv_t=0 if id_phcu_ym==13071310
replace c12_nv_t=0 if id_phcu_ym==13071310
replace c13_nv_t=0 if id_phcu_ym==13071310
replace c05_v_g=0 if id_phcu_ym==13081310
replace b05_nv_t=0 if id_phcu_ym==13091310
replace b06_v_t=0 if id_phcu_ym==13091310
replace c05_v_g=0 if id_phcu_ym==13091310
replace c12_nv_t=0 if id_phcu_ym==13091310
replace c12_v_t=0 if id_phcu_ym==13091310
replace b01_v_t=54 if id_phcu_ym==13111310
replace b02_v_t=49 if id_phcu_ym==13111310
replace c05_nv_g=0 if id_phcu_ym==13111310
replace c05_v_g=0 if id_phcu_ym==13111310
replace c02_nv_t=0 if id_phcu_ym==13121310
replace c05_nv_g=0 if id_phcu_ym==13121310
replace c05_v_g=0 if id_phcu_ym==13121310
replace c08_v_g=0 if id_phcu_ym==13121310
replace c05_nv_g=0 if id_phcu_ym==13131310
replace c05_v_g=0 if id_phcu_ym==13131310
replace c07_nv_t=0 if id_phcu_ym==13131310
replace c12_nv_t=0 if id_phcu_ym==13131310
replace c13_nv_t=0 if id_phcu_ym==13131310
replace c05_nv_g=0 if id_phcu_ym==13141310
replace c05_v_g=0 if id_phcu_ym==13141310
replace b05_nv_t=0 if id_phcu_ym==13151310
replace c05_nv_g=0 if id_phcu_ym==13151310
replace c05_v_g=1 if id_phcu_ym==13151310
replace c05_nv_g=0 if id_phcu_ym==13161310
replace c05_v_g=0 if id_phcu_ym==13161310
replace c05_v_g=0 if id_phcu_ym==26021310
replace c05_nv_g=0 if id_phcu_ym==26041310
replace c05_v_g=0 if id_phcu_ym==26041310
replace b05_nv_t=0 if id_phcu_ym==26051310
replace c03_nv_t=0 if id_phcu_ym==26051310
replace c08_nv_g=0 if id_phcu_ym==26051310
replace c08_nv_t=0 if id_phcu_ym==26051310
replace c08_v_g=0 if id_phcu_ym==26051310
replace c12_nv_t=0 if id_phcu_ym==26051310
replace c05_nv_g=0 if id_phcu_ym==26071310
replace c05_v_g=0 if id_phcu_ym==26071310
replace b05_nv_t=0 if id_phcu_ym==26081310
replace c05_v_g=0 if id_phcu_ym==26081310
replace c05_nv_g=0 if id_phcu_ym==26091310
replace c05_v_g=0 if id_phcu_ym==26091310
replace c05_nv_g=0 if id_phcu_ym==26111310
replace c05_v_g=0 if id_phcu_ym==26111310
replace c05_nv_g=0 if id_phcu_ym==26141310

**************************************************************************
* Missing data
**************************************************************************


/*
g missing_b = 0
fn b*, type(numeric)
foreach var in `r(varlist)' {
	replace missing = 1 if `var'>=. & b0_section_skip==0
}
g missing_c = 0
fn c*, type(numeric)
foreach var in `r(varlist)' {
	replace missing_c = 1 if `var'>=. & c0_section_skip==0
}

ta missing_b 
ta missing_c 

list id_phcu id_phcu_name id_period_mm if missing_b==1 // Ok, Fuoni till Nov is special case !
list id_phcu id_phcu_name id_period_mm if missing_c==1
*/
**************************************************************************
* Logical Value test
**************************************************************************

* (1) Negative Values in Indicators
fn b* c*
foreach var in `r(varlist)' {
	
	qui {
		g `var'_problem_neg=0
		replace `var'_problem_neg=1 if `var'<0
		su `var'_problem_neg
		loc errovalue = `r(mean)'
	}
	if `errovalue'>0 {
		di as error  "`var' has negative values"
		list id_phcu id_phcu_name `var' if `var'_problem_neg==1
	}
	if `errovalue'<=0 {
		drop `var'_problem_neg
	}
}

* (2) Guidline cases > Total cases 
fn *_g
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_g" ""
	qui {
		g `var'_problem_guideline=0
		replace `var'_problem_guideline =1 if `newvar'_g>`newvar'_t
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
outsheet `r(varlist)' using "$DESKTOP/problems_2013q1.csv", c replace
restore


*******************************************************************************
* Remerge with dataset 
*******************************************************************************

merge m:1 id_phcu using "$TEMP/oct_wide", nogen

*******************************************************************************
* Save
*******************************************************************************

sort id_phcu_ym
order *, alpha
order id_phcu_ym id* b* c* a* v* f*
sa "$TEMP/deb02(reshape_manipulate)", replace
