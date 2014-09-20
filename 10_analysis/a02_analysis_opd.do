*****************************************************
* Graph Options
*****************************************************

* Set globals for working in DOFILE
global FORMAT pdf
global SCHEME s2color 

* Choose format: pdf or png
loc format $FORMAT

* Choose color scheme: s2color or s2mono
loc scheme $SCHEME  
set scheme `scheme' 

* General Graph Options
#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(45)) missing
		blabel(bar, color(gs14) position (inside) orientation(vertical)  format(%9.0fc))
		;
loc graphspec over(id_period_ym, label(angle(45))) over(treatment_temporal) nofill
		;
#delimit cr		

*  label(angle(45))) 
		
		
#delimit cr

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

*****************************************************
* Define program
*****************************************************

cap: program drop relabel_opdvars
program relabel_opdvars, rclass

la var b00_g "OPD, according to guidlines"
la var b00_t "OPD"
la var b01_g "Quality: OPD over 5"
la var b01_t "OPD over 5"
la var b02_g "Quality: OPD under 5"
la var b02_t "OPD under 5"
la var b03_g "Quality: STD, diabetes, hypertension, mental health, epilepsy"
la var b03_t "STD, diabetes, hypertension, mental health, epilepsy"
la var b04_g "Quality: Minor surgery"
la var b04_t "Minor surgery"
la var b05_g "Quality: MVA"
la var b05_t "MVA"
la var b06_t "Patients w 3 TB symptoms referred/tested"

* Labelling (nv/v) variables
foreach type in nv v {
	fn *_`type'_*, remove(*_pct)
	foreach var in `r(varlist)' {
		loc oldvar : subinstr loc var "_`type'" "
		loc utype = upper("`type'")
		loc label `"`utype': `: var label `oldvar''"'
		la var `var' "`label'"
		di "`label'"
	}
}	

* Labelling percentage (pct) variables
fn *_g_pct
foreach var in `r(varlist)' {
	loc oldvar : subinstr loc var "_pct" ""
	di "`oldvar'"
	loc label `"`: var label `oldvar'' (%)"'
	
	la var `var' "`label'"
	di "`label'"
}


end 

*****************************************************
* Merge in missing data
*****************************************************

u "$CLEAN/tc_05(label)", clear



* Limit to PBF districts
*****************************************************
keep if treatment==1
ta  id_district id_zone

* Redo dates
*****************************************************

g date_ym =  ym(id_period_yyyy,id_period_mm)
format date_ym  %tm
tsset id_phcu date_ym
 
 
*****************************************************
*****************************************************
*****************************************************



*br id* b* if inlist(id_phcu,1304,1306,1311,2604) & b00_g==. & b0_section_skip!=1 

/*
ta id_period_ym if inlist(id_phcu,1304,1306,1311,2604) & b00_g==. & b0_section_skip!=1

preserve
u "$CLEAN/dea02(rename)", clear
keep if inlist(id_phcu,1304,1306,1311,2604)
sa "$TEMP/temp", replace
restore

merge 1:1 id_phcu_ym using "$TEMP/temp"
*/

bys id_period_ym: su b00_nv_g_pct b00_v_g_pct

bys id_period_ym: su b02_nv_g_pct b02_v_g_pct
bys id_period_ym: su b03_nv_g_pct b03_v_g_pct


ttest b00_nv_g_pct == b00_v_g_pct, level(60)
ttest b02_nv_g_pct == b02_v_g_pct, level(60)
ttest b03_nv_g_pct == b03_v_g_pct, level(60)

/*
br id* b01_t b02_t 
codebook b01_t b02_t
collapse (sum) b01_t b02_t, by(id_period_ym)
*/

*****************************************************
* Data preparation for graphs
*****************************************************

*----------------------------------
* Install value Labels
*----------------------------------
do "$DO/01b_all_value_labels.do"

*----------------------------------
* Label variables
*----------------------------------
qui relabel_opdvars
la val id_period_ym months

*----------------------------------
* Drop Preventative section
*----------------------------------
drop c*

*----------------------------------
* Dropping facilities with incomplete data (!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!)
* - TEMPORARY MEASURE
*----------------------------------
ta id_period_ym id_zone if b0_section_skip!=1 // Pemba = 12/15, Unguja = 13/14


ta id_period_ym id_zone if b0_section_skip!=1 // Pemba = 12/15, Unguja = 13/14

la de zonel 1 "Mkoani" 2 "West", replace 

*----------------------------------
* Create growth variable
*----------------------------------
g b00_g_pct_lag = b00_g_pct[_n-1]
*br b00_g_pct_lag b00_g_pct
order b00_g_pct b00_g_pct_lag
*br b00_g_pct b00_g_pct_lag
g b00_g_pct_growth = (b00_g_pct-b00_g_pct_lag)/b00_g_pct_lag


* Save
*----------------------------------
tempfile graph_opd
sa `graph_opd', replace

*****************************************************
* OPD graphs: AVERAGE BY FACILITY & MONTH
*****************************************************

* Open
*----------------------------------
u `graph_opd', clear

run "$DO/01b_all_value_labels.do"
la val id_period_ym id_period_yml
cb id_period_ym

*****************************************************
* OPD graphs: BY FACILITY
*****************************************************

* Graphs
*----------------------------------

*** Overall OPD cases ***
#delimit ;
	graph bar (mean) b00_t, 
		ytitle("Facilty average of OPD headcount")
		`graphspec' `graphoptions' ;
#delimit cr

di "`graphspec' `graphoptions'"

graph export "$GRAPH//`folder'/curative/opd_b00_t_perfacility.`format'", replace 

*** Overall OPD cases according to guidlines, DISTRIBUTION ***
graph bar (p10) b00_g_pct (median) b00_g_pct (p90) b00_g_pct, ///
	`graphspec' `graphoptions' ///
	ytitle("OPD cases according guidlines (%)") /// 
	legend(on order(1 "10th percentile" 2 "median" 3 "90th percentile")) 
graph  export "$GRAPH/`folder'/curative/opd_b00_g_pct_distribution.`format'", replace

*****************************************************
* OPD graphs: OVERALL BY MONTH
*****************************************************

* Open and Collapse
*----------------------------------
u `graph_opd', clear
collapse (sum) b*, by(id_period_ym treatment_temporal)
relabel_opdvars

* Calculate overall GUIDLINE percentage
*----------------------------------
drop *pct
fn *_g
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_g" ""
	
	di as result "*** `newvar' ***"
	
	g `newvar'_g_pct = `newvar'_g/`newvar'_t
	g `newvar'_problem = 0
	replace `newvar'_problem = 1 if `newvar'_g_pct>1 & `newvar'_g_pct<.
	ta `newvar'_problem
}


* Delete problem
drop *problem

* x*100 % for display
fn *_pct 
foreach var in `r(varlist)' {
	replace `var' = `var'*100
}

* Graphs
*----------------------------------

*<<<<<<<<<<<<<<General OPD>>>>>>>>>>>>>>*

*** Overall OPD cases per month ***
graph bar (mean) b00_t, `graphspec' /// 
	ytitle("OPD headcount: West & Mkoani") `graphoptions' 
graph export "$GRAPH/`folder'/curative/opd_b00_t_overall.`format'", replace 

***  "NV vs. V" OPD cases per month ***
g b00_v_t_pct = (b00_v_t/(b00_nv_t+b00_v_t))*100
graph bar (mean) b00_v_t_pct, `graphspec' /// 
	ytitle("Percetange of verfiable OPD cases") `graphoptions' 
graph export "$GRAPH/`folder'/curative/opd_b00_verfiable_overall.`format'", replace 

*** Overall OPD cases according to guidlines ***
graph bar (mean) b00_g_pct, `graphspec' /// 
	ytitle("OPD cases  according to guidelines, %")  ///
	ylabel(0(10)100) ymtick(0(10)100) 	`graphoptions' 
graph export "$GRAPH/`folder'/curative/opd_b00_g_pct_overall.`format'", replace 

*** QUALITY PCT BY AGE ***
graph bar (mean) b01_g_pct b02_g_pct, `graphspec' `graphoptions'  ///
	 ytitle("OPD cases  according guidlines (%)") ///
	 ylabel(0(10)100) ymtick(0(10)100) ///
	 legend(on order(1 "Over 5" 2 "Under 5"))
graph  export "$GRAPH/`folder'/curative/opd_b01_g_pct_b02_g_pct.`format'", replace

*<<<<<<<<<<<<<<Special OPD>>>>>>>>>>>>>>*

*** Overall Special OPD cases per month ***
foreach i in 3 4 5 6 {
	
	loc ytitle `"`: var label b0`i'_t'"'
	loc ytitle "Overall: `ytitle'"
	graph bar (sum) b0`i'_t,  `graphspec' /// 
		ytitle("`ytitle'") `graphoptions' 		
	graph export "$GRAPH/`folder'/curative/opd_b0`i'_t_sum_overall.`format'", replace 
		
	loc ytitle `"`: var label b0`i'_t'"'
	loc ytitle "Facility average: `ytitle'"
	di as result "`ytitle'"
	
	graph bar (mean) b0`i'_t,  `graphspec' /// 
		ytitle("`ytitle'") `graphoptions' 
	graph export "$GRAPH/`folder'/curative/opd_b0`i'_t_avg_overall.`format'", replace 	

}

foreach i in 3 4 5 {
	loc ytitle `"`: var label b0`i'_g_pct'"'	
	graph bar (mean) b0`i'_g_pct,  `graphspec' /// 
		ytitle("`ytitle'") `graphoptions' 
	graph export "$GRAPH/`folder'/curative/opd_b0`i'_g_pct_overall.`format'", replace 
	
}

*****************************************************
* OPD graphs: OVERALL BY MONTH & DISTRICT
*****************************************************

* Open and Collapse
*----------------------------------
u `graph_opd', clear
collapse (sum) b*, by(id_period_ym id_zone treatment_temporal)
relabel_opdvars

* Calculate overall GUIDLINE percentage
*----------------------------------
drop *pct
fn *_g
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_g" ""
	
	di as result "*** `newvar' ***"
	
	g `newvar'_g_pct = `newvar'_g/`newvar'_t
	g `newvar'_problem = 0
	replace `newvar'_problem = 1 if `newvar'_g_pct>1 & `newvar'_g_pct<.
	ta `newvar'_problem
}


* Delete problem
drop *problem

* x*100 % for display
fn *_pct 
foreach var in `r(varlist)' {
	replace `var' = `var'*100
}


* Graphs
*----------------------------------

*** Overall OPD cases per month and district ***
graph bar (mean) b00_t, `graphoptions'   ///
	over(treatment_temporal)  over(id_period_ym, label(angle(vertical))) over(id_zone)  ///
	ytitle("Total number of OPD cases") 
graph export "$GRAPH/`folder'/curative/opd_b00_t_overall_byd.`format'",replace 

*over(id_period_ym, label(angle(vertical))) nofill

*** Overall OPD cases per month and district ***
graph bar (mean) b00_g_pct, `graphoptions'   ///
	over(treatment_temporal)  over(id_period_ym, label(angle(vertical))) over(id_zone) ///
	ytitle("Percentage of OPD cases in West and Mkoani") 
graph export  "$GRAPH/`folder'/curative/opd_b00_g_pct_overall_byd.`format'",replace 

*****************************************************
* Things that never materialized 
*****************************************************

/* EXCLUDED BECAUSE IT IS AVG. OF FACILITIES: WE NEED FROM TOTAL
*** Overall OPD cases according to guidlines ***
#delimit ;
	graph bar (mean) b00_g_pct, 
		 over(id_period_ym) 
		ytitle("OPD cases according to guidelines, %") 
		ylabel(0(10)100) ymtick(0(10)100) 	
		legend(on order(1 "Average per facility"))
	;
#delimit cr
graph export "$GRAPH/`folder'/curative/opd_b00_g_pct_perfacility.`format'",replace 
*/
/***************************************************** EXPERIMENTING 
u `graph_opd', clear

foreach i in 10 50 90 {
	u "$TEMP/`graph_opd'", clear
	collapse (p`i') b00_g_pct, by(id_period_ym)
	ren b00_g_pct p`i'
	g p`i'_ppt = (p`i'-p`i'[_n-1])
	* /p`i'[_n-1]
	sa "$TEMP/p`i'", replace
}

u "$TEMP/p10", clear
foreach i in 50 90 {
	merge 1:1 id_period_ym using "$TEMP/p`i'", nogenerate
}

drop if id_period_ym==6
*twoway (bar p10_change id_period_ym) (bar p50_change id_period_ym) (bar p90_change id_period_ym)
graph bar (mean) p10_ppt p50_ppt p90_ppt, over(id_period_ym)
*/


*****************************************************
* Regressions 
*****************************************************
/*
*-----------------------------------------------------
* DOES THE PERCENTAGE OF QUALITY cases LAST MONTH PREDICT THE NUMBER OF CLIENTS 
* NEXT MONTHS?
* CAUSUAL LINK I: Higher quality --> Better reputation --> More patients
* CAUSUAL LINK II: Pay for quantity --> Higher staff attendance / more attrative 
* --> More patients
*-----------------------------------------------------

xtset id_phcu id_period_ym

foreach var in b00_g_pct  b00_g b00_t {
	g d_`var' = D.`var'
}
foreach var in b00_g_pct  b00_g b00_t {
	gen `var'_lag1 = `var'[_n-1]
}

set linesize 225
g d_b00_t_pct = d_b00_t/b00_t

reg d_b00_t_pct b00_g_lag1 b00_t_lag1
reg d_b00_t_pct b00_g_pct_lag1

* ROBUSTNESS: NO NON-LINERAITY 
reg d_b00_t_pct b00_g_pct_lag1 b00_t_lag1

*/
