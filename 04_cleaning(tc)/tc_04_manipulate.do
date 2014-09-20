**************************************************************************
* Preamble
**************************************************************************

set linesize 225
u "$CLEAN/tc_03(clean)", clear

*******************************************************************************
* DATA MANIPULATION: GUIDLINE percentage
*******************************************************************************

* GUESSES TO REAL VALUE (MAX) !!!! CHECK !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
replace c04_t=50 if id_phcu_ym==14031405
replace c05_g=0 if id_phcu_ym==13011309  

fn *_g
foreach var in `r(varlist)' {
	loc letter = substr("`var'",1,1)
	loc newvar : subinstr loc var "_g" ""

	* Generate Variable
	di as result "`newvar'_g_pct created"
	g `newvar'_g_pct = (`newvar'_g/`newvar'_t)*100 
	replace `newvar'_g_pct = .x if `newvar'_g>=. | `newvar'_t>=.
	replace `newvar'_g_pct = .h if `letter'0_section_skip==1 /* service not offered by PHCU (.h) */
	replace `newvar'_g_pct = .y if `newvar'_g==0 & `newvar'_t==0
	
	
	* Inspect missing values
	qui {
		g mv_`newvar' = 0
		di "replace mv_`newvar' = 1 if `newvar'_g>=. | `newvar'_t>=."
		replace mv_`newvar' = 3 if `newvar'_g_pct>=.	
		replace mv_`newvar' = 1 if `newvar'_g>=. | `newvar'_t>=.
		replace mv_`newvar' = 2 if `letter'0_section_skip==1
	}
	ta id_period_mm mv_`newvar', mi
	qui drop mv_`newvar'


	* Check values of 100%
	list id_phcu_ym_s id_phcu_name `newvar'_g_pct `newvar'_g `newvar'_t if `newvar'_g_pct>100 &  `newvar'_g_pct<.
	su `newvar'_g_pct
*	assert `r(max)'<101

}


* MISSING C05 data
preserve
keep if treatment==1
g mv = 0
replace mv = 1 if c05_g_pct>=. & c05_g_pct!=.y & c05_g_pct!=.h
list id_phcu id_period_ym id_phcu_name c05_g c05_t c05_g_pct  if mv==1
restore

* Outliers
preserve
keep if treatment==1
bys id_period_ym: su c05_g_pct

keep id_phcu id_period_ym id_phcu_name c05_g c05_t c05_g_pct
sort id_phcu

drop c05_g c05_t
reshape wide c05_g_pct, j(id_period_ym) i(id_phcu)
restore

*******************************************************************************
* treatment_temporal variable
*******************************************************************************

g treatment_temporal = 1
replace treatment_temporal = 0 if inlist(id_period_mm,4,5,6) & id_period_yyyy==2013
la de treatment_temporall 0 "Baseline" 1 "treatment_temporal"
la val treatment_temporal treatment_temporall 


* Timespec
g time_cat = .
replace time_cat = 13030406 if inlist(id_period_mm,4,5,6) & id_period_yyyy==2013
replace time_cat = 13070809 if inlist(id_period_mm,7,8,9) & id_period_yyyy==2013
replace time_cat = 13101112 if inlist(id_period_mm,10,11,12) & id_period_yyyy==2013
replace time_cat = 14010203 if inlist(id_period_mm,1,2,3) & id_period_yyyy==2014
replace time_cat = 14040506 if inlist(id_period_mm,4,5,6) & id_period_yyyy==2014
replace time_cat = 14070809 if inlist(id_period_mm,7,8,9) & id_period_yyyy==2014
replace time_cat = 14101112 if inlist(id_period_mm,10,11,12) & id_period_yyyy==2014
format %12.0f time_cat

la de quarter 13030406 "Q4 2013" 13070809 "Q1 2013" 13101112 "Q2 2013" ///
	14010203 "Q3 2014" 14040506 "Q4 2014" 14070809 "Q1 2014"  14101112 "Q2 2014"
la val time_cat quarter
cb time_cat


*******************************************************************************
* Save
*******************************************************************************

compress
sa "$CLEAN/tc_04(manipulate)", replace



	
