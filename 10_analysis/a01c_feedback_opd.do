

*****************************************************
* Define macros
*****************************************************


#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
		;
#delimit cr


*****************************************************
* Data preparation for graphs
*****************************************************

u "$CLEAN/tc_05(label)", clear
keep if inlist(id_period_ym,1401,1403,1404,1405,1406)
keep if id_zone==2

*************************************************************************
/*
br *_v_g_pct
fn *_v_g_pct
foreach var in `r(varlist)' {
	bys id_period_mm: egen `var'_m = median(`var')
}
*/
/*
preserve

fn *_g 
foreach var in `r(varlist)' {
	replace `var' = round(`var',1)
}

fn *_g_pct 
*_g_pct_m
foreach var in `r(varlist)' {
	replace `var' = round(`var',.2)
}

fn *_t *_v_t *_v_g *_v_g_pct , remove(*_nv_*)
keep id_phcu id_phcu_name id_period_mm `r(varlist)'

ren *_g* *_tg*
order *, alpha
order id*
ren *_tg* *_g*

sort id_phcu

reshape wide b* c* ,  i(id_phcu) j(id_period_mm)

tostring id_phcu, g(id_phcu_s)
g id1 = substr(id_phcu_s,1,1)
g id2 = substr(id_phcu_s,2,1)
g id3 = substr(id_phcu_s,3,1)
g id4 = substr(id_phcu_s,4,1)
drop id_phcu_s


order id_phcu id_phcu_name id*

export excel using "$DESKTOP/performance.csv", ///
		 firstrow(variables) replace
		 
restore

*************************************************************************		 

levelsof id_phcu, loc(id_phcu) 
foreach phcu in `id_phcu' {
	preserve
	keep if id_phcu==`phcu'

	
	#delimit ;
	export excel using "$DESKTOP/performance_byfacility.csv",
		 firstrow(varlabels) sheetreplace  sheet("`phcu'") ;
	#delimit cr
	
	levelsof id_phcu, loc(id_phcu) 
	restore
}
*/
*************************************************************************	

fn id* b*_v_* b0_section_skip c*_v_* c0_section_skip
keep `r(varlist)'

fn b* 
foreach var in `r(varlist)' {

	* Get sum 
	sort id_period_mm
	ren `var' temp_`var'
	qui bys id_phcu: egen `var' = total(temp_`var')
	qui bys id_phcu: replace `var' = `var'/3	
	replace `var' = . if b0_section_skip==1
	drop temp_`var'

}

fn c* 
foreach var in `r(varlist)' {

	* Get sum 
	sort id_period_mm
	ren `var' temp_`var'
	bys id_phcu: egen `var' = total(temp_`var')
	replace `var' = . if c0_section_skip==1
	drop temp_`var'

}

sort id_period_mm
bys id_phcu: g n = _n
keep if n==1	

drop id_period_mm

foreach letter in b c {
fn `letter'*
foreach var in `r(varlist)' {
	* Getting the rank
	gsort  - `var'
	g `var'_n = _n  if `letter'0_section_skip!=1
	egen `var'_N = max(`var'_n) if `letter'0_section_skip!=1
	tostring `var'_n, replace
	tostring `var'_N, replace
	g `var'_rank = `var'_n + "/" + `var'_N
	drop `var'_N
	
	* Getting the median
	egen `var'_p50 = median(`var')
	
	
}
}




keep id* *_v_g*
drop b01* b02*

order *, alpha
order id*
sort id_district

fn b00_v_g_pct_rank
*fn b00_v_g_pct_rank_n 
*drop b06*

fn *pct
foreach var in `r(varlist)' {
	di as error "`var'"
	
	loc var : subinstr loc var "_pct" ""

	preserve
	
	tostring `var'_pct_n, replace
	
	keep id_phcu_name `var'_pct `var'_pct_rank  `var'_pct  `var'_pct_n
	
	order `var'_pct_rank id_phcu_name `var'_pct 
	
	sort `var'_pct_n
	drop `var'_pct_n
	
	drop if `var'_pct==0
	
	export excel using "$DESKTOP/`var'.csv", replace 

	restore
}

*************************************************************************	
stop




* Install value Labels
do "$DO/01b_all_value_labels.do"
la val id_period_mm months



/*
bys id_period_mm: egen b00_g_pct_median = median(b00_g_pct) 
bys id_period_mm: egen b00_g_pct_p75 = pctile(b00_g_pct), p(75)   
bys id_period_mm: egen b00_g_pct_p25 = pctile(b00_g_pct), p(25)  
*/


bys id_period_mm: su b00_g_pct b00_g_pct_median if id_phcu==1301

set linesize 225
bys id_period_mm: su b00_g_pct, detail



graph bar b00_g_pct b00_g_pct_p25  b00_g_pct_median b00_g_pct_p75 if id_phcu==1301, ///
	over(id_period_mm) `graphoptions' ///
	legend(on order(1 "1301" 2 "Median"))


stop

*****************************************************
* OPD graphs: AVERAGE BY FACILITY & MONTH
*****************************************************

* Open
*----------------------------------
u "$TEMP/graph_opd", clear

* Graphs
*----------------------------------

*** Overall OPD cases ***
#delimit ;
	graph bar (mean) b00_t, 
		over(id_period_mm) 
		ytitle("Average number of OPD cases per facility")
		`graphoptions' ;
#delimit cr
	
graph export "$GRAPH/curative/opd_b00_t_perfacility_bym.pdf", replace 

/*
*** Overall OPD cases according to guidlines ***
#delimit ;
	graph bar (mean) b00_g_pct, 
		 over(id_period_m) 
		ytitle("OPD cases according to guidelines, %") 
		ylabel(0(10)100) ymtick(0(10)100) 	
		legend(on order(1 "Average per facility"))
	;
#delimit cr
*/ 
graph export "$GRAPH/curative/opd_b00_g_pct_perfacility_bym.pdf",replace 

*** Overall OPD cases according to guidlines, DISTRIBUTION ***
graph bar (p10) b00_g_pct (median) b00_g_pct (p90) b00_g_pct, ///
	over(id_period_m) `graphoptions' ///
	ytitle("OPD cases according to guidelines (%)") /// 
	legend(on order(1 "10th percentile" 2 "median" 3 "90th percentile"))
graph  export "$GRAPH/curative/opd_b00_g_pct_distribution_bym.pdf", replace



***************************************************** EXPERIMENTING 
u "$TEMP/graph_opd", clear

foreach i in 10 50 90 {
	u "$TEMP/graph_opd", clear
	collapse (p`i') b00_g_pct, by(id_period_mm)
	ren b00_g_pct p`i'
	g p`i'_ppt = (p`i'-p`i'[_n-1])
	* /p`i'[_n-1]
	sa "$TEMP/p`i'", replace
}

u "$TEMP/p10", clear
foreach i in 50 90 {
	merge 1:1 id_period_mm using "$TEMP/p`i'", nogenerate
}

drop if id_period_mm==6
*twoway (bar p10_change id_period_mm) (bar p50_change id_period_mm) (bar p90_change id_period_mm)

graph bar (mean) p10_ppt p50_ppt p90_ppt, over(id_period_m)

*****************************************************


*****************************************************
* OPD graphs: OVERALL BY MONTH
*****************************************************

* Open and Collapse
*----------------------------------
u "$TEMP/graph_opd", clear
collapse (sum) b*, by(id_period_mm)


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


* Label variables
*----------------------------------
qui relabel_opdvars


* Graphs
*----------------------------------

*<<<<<<<<<<<<<<Overall OPD>>>>>>>>>>>>>>*

***  "NV vs. V" OPD cases per month ***
g b00_v_t_pct = (b00_v_t/(b00_nv_t+b00_v_t))*100
graph bar (mean) b00_v_t_pct, /// 
	 over(id_period_m) ///
	ytitle("Percetange of verfiable OPD cases") `graphoptions' 
graph export "$GRAPH/curative/opd_b00_verfiable_overall_bym.pdf", replace 


*** Overall OPD cases per month ***
graph bar (mean) b00_t, /// 
	 over(id_period_m) ///
	ytitle("Number of OPD cases in West and Mkoani") `graphoptions' 
graph export "$GRAPH/curative/opd_b00_t_overall_bym.pdf", replace 

*** Overall OPD cases according to guidlines ***
graph bar (mean) b00_g_pct, ///
	 over(id_period_m)  /// 
	ytitle("OPD cases according to guidelines, %")  ///
	ylabel(0(10)100) ymtick(0(10)100) 	`graphoptions' 
graph export "$GRAPH/curative/opd_b00_g_pct_overall_bym.pdf", replace 

*** QUALITY PCT BY AGE ***
graph bar (mean) b01_g_pct b02_g_pct, over(id_period_m) `graphoptions'  ///
	 ytitle("OPD cases according to quality (%)") ///
	 ylabel(0(10)100) ymtick(0(10)100) ///
	 legend(on order(1 "Over 5" 2 "Under 5"))
graph  export "$GRAPH/curative/opd_b01_g_pct_ b02_g_pct.pdf", replace

*<<<<<<<<<<<<<<Special OPD>>>>>>>>>>>>>>*
/*
*** Overall Special OPD cases per month ***
foreach i in 3 4 5 6 {
	loc ytitle `"`: var label b0`i'_t'"'
	
	di as result "`ytitle'"
	graph bar (mean) b0`i'_t, /// 
		 over(id_period_m) /// 
		ytitle("`ytitle'") `graphoptions' 
	graph export "$GRAPH/curative/opd_b0`i'_t_overall_bym.pdf", replace 
}

foreach i in 3 4 6 {
	loc ytitle `"`: var label b0`i'_g_pct'"'	
	di as error "ytitle -`ytitle'"
	graph bar (mean) b0`i'_g_pct, /// 
		 over(id_period_m) ///
		ytitle("`ytitle'") `graphoptions' 
	graph export "$GRAPH/curative/opd_b0`i'_g_pct_overall_bym.pdf", replace 
	
}
*/
*****************************************************
* OPD graphs: OVERALL BY MONTH & DISTRICT
*****************************************************

* Open and Collapse
*----------------------------------
u "$TEMP/graph_opd", clear
collapse (sum) b*, by(id_period_mm id_zone)
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
graph bar (mean) b00_t, ///
	over(id_period_m) over(id_zone) `graphoptions'   ///
	ytitle("Number of OPD cases in West and Mkoani") 

graph export "$GRAPH/curative/opd_b00_g_pct_overall_bym_byz.pdf",replace 



*** Overall OPD cases per month and district ***
graph bar (mean) b00_g_pct, ///
	over(id_period_m) over(id_zone) `graphoptions'   ///
	ytitle("Percentage of OPD cases in West and Mkoani") 


graph export "$GRAPH/curative/opd_b00_g_pct_overall_bym_byd.pdf",replace 

*****************************************************
* Regressions 
*****************************************************
/*
*-----------------------------------------------------
* DOES THE PERCENTAGE OF QUALITY CASES LAST MONTH PREDICT THE NUMBER OF CLIENTS 
* NEXT MONTHS?
* CAUSUAL LINK I: Higher quality --> Better reputation --> More patients
* CAUSUAL LINK II: Pay for quantity --> Higher staff attendance / more attrative 
* --> More patients
*-----------------------------------------------------

xtset id_phcu id_period_m

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
