
**************************************************************************
* Graph Options
**************************************************************************

* Set globals for working in DOFILE
global FORMAT pdf
global SCHEME s2mono /* s2color */
* s2manual

* Choose format: pdf or png
loc format $FORMAT

* Choose color scheme: s2color or s2mono
loc scheme $SCHEME  
set scheme `scheme' 

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

di "`schemef' `formatf' (`format')"

**************************************************************************
* OPEN FILE
**************************************************************************

u "$CLEAN/tc_05(label)", clear

**************************************************************************
* Drop observations
**************************************************************************

* Dropping late-comers 
ta id_phcu_name if id_phcu==1317
drop if id_phcu==1317

**************************************************************************
* Drop variables only for b00, b01, b02
**************************************************************************

fn b00* b01* 
foreach var in `r(varlist)' {
	replace `var'=. if inlist(id_phcu,2707,2108,2119,2210,2704)
}


**************************************************************************
* Drop variables
**************************************************************************

keep id_phcu_name id_period_ym treatment  treatment_temporal ///
	b00* b01* b02* c01* c04* c05* c06* c08* ///
	b0_section_skip  c0_section_skip
*drop c04_t c04_g
drop *_nv_* *_v_* 




**************************************************************************
* Collapse variables 
**************************************************************************

drop *pct

* Collapse + Drop missing observations
foreach var in b00  b01  b02  c01  c04 c05  c06  c08 {
	
	* Missing values
	replace `var'_g=. if `var'_t>=. |`var'_g>=.
	replace `var'_t=. if `var'_t>=. | `var'_g>=.
	
	loc v = substr("`var'",1,1)
	replace `var'_t=.s if `v'0_section_skip==1
	replace `var'_g=.s if `v'0_section_skip==1

}

collapse (sum) b* c*,by(id_period_ym treatment  treatment_temporal)


* Calculate %
foreach var in b00  b01  b02  c01  c04 c05  c06  c08 {
	g `var'_g_pct = (`var'_g/`var'_t)*100

}

* Drop
drop *_g *_t
drop c06_g_pct	c08_g_pct
	
* Reshape
fn b* c* 
reshape wide `r(varlist)', i(id_period_ym  treatment_temporal)  j(treatment)

* Label variables
fn *1 
foreach var in `r(varlist)' {
	la var `var' "PBF" 
}
fn *0 
foreach var in `r(varlist)' {
	la var `var' "Non-PBF"
}

**************************************************************************
* Create smooth time variables
**************************************************************************

loc i = 1

forval y = 13/14 {

loc months `c(Mons)'
di "`months'"

	forval m = 1/12 {
		if `m'<10 loc m = "0`m'" 
	
		loc ym = `y'`m'	
		gettoken month months: months
		
		
		if `ym'<1307 	loc monthlist `monthlist' `ym' "`month' (BL)"
		else 			loc monthlist `monthlist' `ym' "`month'"
		
		if `ym'<1307 	loc monthlist2 `monthlist2' `i' "`month' `y'"
		else 			loc monthlist2 `monthlist2' `i' "`month' `y'"
	
		loc ++i
	}
}
	

di `"`monthlist2'"'
la de months2 `monthlist2'
	
sort id_period_ym 
g id_period_m = _n
replace id_period_m = id_period_m + 3
la val id_period_m  months2
la var id_period_m "Month"
cb id_period_m

su id_period_m
return list
loc min = `r(min)' 
loc max = `r(max)'
order id_period_m

**************************************************************************
* Step 1 in calculating DID impact at any given period
* Extract value from July 2013 for both treatment/control
**************************************************************************

preserve
	
	keep if id_period_ym==1306
	fn b* c*
	foreach var in `r(varlist)' {
		qui levelsof `var', loc(`var'_bllevel)
		
		di as result "test: `var'_bllevel"
		di as error "`var': ``var'_bllevel'"	
	}	
	
restore 

*----------------------------------------------------

foreach var in b00_g_pct {
	*b00_g_pct b01_g_pct b02_g_pct c01_g_pct {

*----------------------------------------------------
* Title
*----------------------------------------------------

if 		"`var'"=="b00_g_pct" loc title = `" "OPD consultations" "with treatment according to guidlines (%)" "'
else if "`var'"=="b01_g_pct" loc title `" "OPD consultations: 5 and above" "with treatment according to guidlines (%)" "'
else if "`var'"=="b02_g_pct" loc title `" "OPD consultations: under 5" "with treatment according to guidlines (%)" "'
else if "`var'"=="c01_g_pct" loc title `" "Penta 3 course finished within 4 months" "as % of all children immunized" "'
else if "`var'"=="c04_g_pct" loc title `" "1st ANC visits within 16 weeks" "as % of all 1st ANC visits" "'
else if "`var'"=="c05_g_pct" loc title `" "Postnatal care in 48 hours" "as % of all PNC visits" "'
*else if "`var'"=="c06_g_pct" loc title `" "Health Facility Delivery" "with treatment according to guidlines (%)" "'
*else if "`var'"=="c08_g_pct" loc title `" "Family Planning" "with treatment according to guidlines (%)" "'


preserve

*----------------------------------------------------
* Step 2 in calculating DID impact at any given period
* Due DID subtraction
*----------------------------------------------------
	
	* Difference-in-Difference substraction
	g  `var'_imp=(`var'1-``var'1_bllevel')-(`var'0-``var'0_bllevel')

	replace `var'_imp = 0 if id_period_ym<1307

	la var `var'_imp "PBF Impact (DID)"
	
	*----------------------------------------------------
	* GRAPH
	*----------------------------------------------------
	
	#delimit ;
	twoway 
		(area `var'_imp id_period_m, fcolor(cranberry) fintensity(20) lcolor(white))
		(connected `var'0 id_period_m, lcolor(navy) mcolor(navy)) 
		(connected `var'1 id_period_m, mcolor(cranberry) lcolor(cranberry)),	
		ytitle(`title', size(medium)) 
		ylabel(0(10)100, labels labsize(medlarge) angle(horizontal) glpattern(dash) gmin gmax) 
		xtitle("", size(zero))
		xlabel(4(1)18, labels labsize(medlarge) angle(forty_five) valuelabel) 
		xline(7, lwidth(thick) lpattern(vshortdash) lcolor(black)) 
		legend(rows(1) region(lcolor(white) lpattern(solid))) 
		scheme(`scheme')  graphregion(fcolor(white)) xsize(9) ysize(4.95) 
	;
	#delimit cr
	
	
	graph export "$DESKTOP/test.pdf", replace 
	
	graph export "$GRAPH/`folder'/nonpbf/`var'.`format'", replace 

	*----------------------------------------------------

restore
	
}	



*----------------------------------------------------
* Total variable
*----------------------------------------------------
/*
keep id* *_t t*

* Collapse and reshape
fn c* b*, loc(varlist)
collapse (sum) `varlist', by(id_period_ym treatment  treatment_temporal)
reshape wide `varlist', i(id_period_ym  treatment_temporal)  j(treatment)

* Time issues 
di `"`monthlist2'"'
la de months2 `monthlist2'

sort id_period_ym 
g id_period_m = _n
replace id_period_m = id_period_m + 3
la val id_period_m  months2
la var id_period_m "Month"
cb id_period_m



* Create ratio
*----------------------------------------------------
foreach var in `varlist' {
	g `var' = `var'0/`var'1
}


* Extract value in 1306
foreach var in `varlist' {
preserve
	keep if id_period_ym==1306
	levelsof `var', loc(`var'_level_1306)
	di "``var'_level_1306'"
restore 	
}

foreach var in `varlist' {
	g `var'_ratio = round(`var'/``var'_level_1306'-1,0.00000000001)
}

drop *t0 *t1 *t
order *, alpha
order id* t*

#delimit ;
twoway	(line b01_t_ratio id_period_m) 
		(line b02_t_ratio id_period_m),
		ylabel(-5(1)5)
;
#delimit cr


#delimit ;
twoway	(line b00_t_ratio id_period_m) 
		(line b01_t_ratio id_period_m) 
		(line c01_t_ratio id_period_m) 
		(line c05_t_ratio id_period_m) 
		(line c06_t_ratio id_period_m) 
		(line c08_t_ratio id_period_m),
		ylabel(-5(1)5)
;
#delimit cr


*/





