
**************************************************************************
* Graph Options
**************************************************************************

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
* Drop variables
**************************************************************************

keep id_phcu_name id_period_ym treatment  treatment_temporal ///
	c07_t c08_t  
	
keep if treatment==1

**************************************************************************
* Collapse variables 
**************************************************************************


collapse (sum) c07_t c08_t , by(id_period_ym  treatment_temporal)



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


la var c07_t "Family Planning consultation"
la var c08_t "Implant"



*----------------------------------------------------

*c08_t

*twoway (connected c07_t id_period_m) (lfit c07_t id_period_m, range(5 18))
	
	*----------------------------------------------------
	* GRAPH
	*----------------------------------------------------
	
	replace c07_t  = . if id_period_ym<1306
	*keep if id_period_ym>1305
	
	#delimit ;
	twoway 
		(scatter c07_t id_period_m, mcolor(cranberry) lcolor(cranberry))
		(lfit c07_t id_period_m, lcolor(cranberry) lpattern(dash) range(6 18))
		(scatter c08_t id_period_m, mcolor(navy) lcolor(navy))
		(lfit c08_t id_period_m, lcolor(navy) lpattern(dash) range(4 18)),

		ytitle("Case headcount in Mkoani & West", size(medium)) 
		
		xtitle("", size(zero))
		xlabel(4(1)18, labels labsize(medlarge) angle(forty_five) valuelabel) 
		xline(7, lwidth(thick) lpattern(vshortdash) lcolor(black)) 
		legend(rows(1) region(lcolor(white) lpattern(solid))) 
		scheme(`scheme')  graphregion(fcolor(white)) xsize(9) ysize(4.95) 
	;
	#delimit cr



