
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

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

*****************************************************
* OPEN FILE
*****************************************************

u "$CLEAN/tc_05(label)", clear


keep id_period_ym treatment  treatment_temporal b00* b01* b02* c01* c04* c05* 
drop *_nv_* *_v_* *_g *_t

*----------------------------------------------------
* Label
*----------------------------------------------------

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


*----------------------------------------------------
* Select variables
*----------------------------------------------------

fn c*pct b*pct, loc(varlist_pct)
fn c* b*, loc(varlist_t) remove(c*pct b*pct)

la var b00_g_pct `" "OPD consultations" "with treatment according to guidlines (%)" "'
la var b01_g_pct `" "OPD consultations: 5 and above" "with treatment according to guidlines (%)" "'
la var b02_g_pct `" "OPD consultations: under 5" "with treatment according to guidlines (%)" "'
la var c01_g_pct `" "Children immunized with Penta 3" "with treatment according to guidlines (%)" "'
la var c04_g_pct `" "1st ANC visits within 16 weeks" "with treatment according to guidlines (%)" "'
la var c05_g_pct `" "Postnatal care" "with treatment according to guidlines (%)" "'

*----------------------------------------------------
* Imapct 
*----------------------------------------------------

* Extract value in 1307
preserve

	keep id* t* b00_g_pct b01_g_pct b02_g_pct c01_g_pct c05_g_pct

	fn b* c*, loc(varlist)
	
	collapse (mean) `varlist', by(id_period_ym treatment  treatment_temporal)
	reshape wide `varlist', i(id_period_ym  treatment_temporal)  j(treatment)
	
	
	keep if id_period_ym==1307
	foreach var in `varlist' {
		foreach t in 0 1 {
			qui levelsof `var'`t', loc(`var'`t'_bllevel)
			di "`var'`t': ``var'`t'_bllevel'"	
		}
	}	
	
restore 

*----------------------------------------------------




foreach var in  b00_g_pct b01_g_pct b02_g_pct c01_g_pct c05_g_pct {



/*
	*-----------------------------------------------------------------------
	* Wrap title
	*-----------------------------------------------------------------------
	
	loc ll 32 //sets the length of the title
	
	
	di as result "`title'"
	loc len = length("`title'")
	di "`len'"
	loc newtitle
	
	if `len' > `ll' {
		loc pieces "`=ceil(`len'/`ll')'"
		forval p = 1/`pieces' {
			loc p`p' : piece `p' `ll' of "`title'", nobreak
			di "`p' - `p`p''"
			loc newtitle `" `newtitle'  `"`p`p'' "'   "'
		}
	}

	di `" `newtitle' "'
*/

preserve

di as result "`var'"
loc title `"`: var label `var''"' 


*----------------------------------------------------
* PREP GRAPH
*----------------------------------------------------

	collapse (mean) `var', by(id_period_ym treatment  treatment_temporal)
	
	reshape wide `var', i(id_period_ym  treatment_temporal)  j(treatment)
	
	* Label variables
	la var `var'1 "PBF" 
	la var `var'0 "Non-PBF"
	
	* Time issues 
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


	* Difference
	di "``var'1_bllevel'"
	
	g  `var'_imp=(`var'1-``var'1_bllevel')-(`var'0-``var'0_bllevel')

	replace `var'_imp = 0 if id_period_ym<1307
	la var `var'_imp "PBF Impact (DID)"
	
	*----------------------------------------------------
	* GRAPH
	*----------------------------------------------------
	
	#delimit ;
	twoway 
		(area `var'_imp id_period_m, fcolor(cranberry) fintensity(60) lcolor(white))
		(connected `var'0 id_period_m, lcolor(navy) mcolor(navy)) 
		(connected `var'1 id_period_m, mcolor(cranberry) lcolor(cranberry)),	
		ytitle(`title', size(medium)) 
		ylabel("0(10)100", labels labsize(medlarge) angle(horizontal) glpattern(dash) gmin gmax) 
		xtitle("", size(zero))
		xlabel(4(1)18, labels labsize(medlarge) angle(forty_five) valuelabel) 
		xline(6, lwidth(thick) lpattern(vshortdash) lcolor(black)) 
		legend(rows(1) region(lcolor(white) lpattern(solid))) 
		scheme(`scheme')  graphregion(fcolor(white)) xsize(9) ysize(4.95) 
	;
	#delimit cr
	
	graph export "$GRAPH/`folder'/nonpbf/`var'.`format'", replace 

	*----------------------------------------------------

restore
	
}	





