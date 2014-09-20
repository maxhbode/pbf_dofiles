/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Feb 2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


clear 
set more off
set linesize 225

run "$DO/01b_all_value_labels.do"

* Period name
loc yy 14	
loc m1 4
loc m2 5
loc m3 6
loc mm1 "04"
loc mm2 "05"
loc mm3 "06"
loc period "`yy'_`mm1'`mm2'`mm3'"

*---------------------------------------------------
* Parameters
*---------------------------------------------------

* Set Performance Pay base (TZS)
loc base=500

* DIF/PIF split
loc fundsplit = 0.2

* TZS/USD exchange rate
loc exchangerate = 1600

* Equity parameters 
loc cat1 = -.1
loc cat2 = 0
loc cat3 = .1
loc cat4 = .2
loc cat5 = .3

* Set Prices (based on multipliers) 

* Total (t)
loc b00_t =	0
loc b03_t =	`base' * 2.5
loc b04_t =	`base' * 2.5
loc b05_t =	`base' * 10
loc b06_t =	`base' * 10
loc b07_t =	`base' * 10 
loc b08_t =	`base' * 3.5
loc c01_t =	`base' * 2.5
loc c02_t =	`base' * 3
loc c05_t =	`base' * 1.5
loc c06_t =	`base' * 10
loc c07_t =	`base' * 4
loc c08_t =	`base' * 10
loc c09_t =	`base' * 1
loc c10_t =	`base' * 1
loc c11_t =	`base' * 1

* Guidlines (g)
loc b00_g =	`base' * 2
loc b03_g =	`b03_t' * 2
loc b04_g =	`b04_t' * 2
loc b05_g =	`b05_t' * 1.2
loc c01_g =	`c01_t' * 1.2
loc c03_g =	`base' * 12.5
loc c04_g =	`base' * 5
loc c05_g =	`c05_t' * 2
loc c06_g =	`c06_t' * 2
loc c08_g =	`c08_t' * 1.2

* Potential [p=t*(1+g)]
loc b00_p =	`base' * 3
loc b03_p =	`base' * 7.5
loc b04_p =	`base' * 7.5
loc b05_p =	`base' * 10
loc b06_p =	`base' * 22
loc c01_p =	`base' * 5.5
loc c02_p =	`base' * 3
loc c03_p = `base' * 12.5
loc c04_p = `base' * 5
loc c05_p = `base' * 4.5
loc c06_p = `base' * 30
loc c07_p = `base' * 4
loc c08_p = `base' * 22
loc c09_p = `base' * 1
loc c10_p = `base' * 1
loc c11_p = `base' * 1
loc b07_p = `base' * 10
loc b08_p = `base' * 3.5

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* SAVING PRICES FOR PRICING LIST

set obs 1

foreach sec in b c {
	forval i = 0/11 {
	if `i'<10 loc i = "0`i'"
	
		foreach type in g t {
			
			forval cat = 1/5 {
				
				if "``sec'`i'_`type''"!="" {
					g `sec'`i'_`type'_cat`cat' =  ``sec'`i'_`type''*(1+`cat`cat'')
					
					di as error `" ``sec'`i'_`type''*(1+`cat`cat'')"'
	
				}
				
			}
		}
	}
}


compress
sa "$CLEAN/pricelist(a04label)", replace


*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



u "$CLEAN/tc_05(label)", clear

*---------------------------------------------------
* Drop obs
*---------------------------------------------------

* Keep treatment only
drop if treatment==0

* Keep right period
keep if inlist(id_period_ym,`yy'0`m1',`yy'0`m2',`yy'0`m3')

*---------------------------------------------------
* Drop vars
*---------------------------------------------------
drop b01* b02* *pct 

*---------------------------------------------------
* Rename
*---------------------------------------------------

ren *nv_g *g_nv
ren *nv_t *t_nv
ren *v_g *g_v
ren *v_t *t_v
order *, alpha
order id_phcu* id_period* id*

*---------------------------------------------------
* Locals
*---------------------------------------------------

* Get quantity variables (removing once we don't pay for)
fn *_t, loc(vars_t) remove(c03_t c04_t)
loc vars_t_short : subinstr loc vars_t "_t" "", all

* Get quality variables
fn *_g, loc(vars_g)
loc vars_g_short : subinstr loc vars_g "_g" "", all

************************************************************************
* Calculating Performance Pay (PP)
************************************************************************

*---------------------------------------------------
* PP by Indicator per month (Total & Guidline)
*---------------------------------------------------

* Real (only verifiable)
foreach var in `vars_t' `vars_g' {
	foreach type in "_v" {

		di as result "`var'"
		di as result "g pp_`var'`type'=`var'`type'*``var''"

		g pp_`var'`type'=`var'`type'*``var''
		
		loc section = substr("`var'",1,1)
		replace pp_`var'`type'=.d if `section'0_section_skip==1
		
		loc label = `"PP - `: var label `var''"'
		la var pp_`var'`type' "`label'"
	}
}

* Full potential (all quality)
foreach var in `vars_t_short' {

	di `" g pp_`var'_p=`var'_t*``var'_p' "'
	g pp_`var'_pot=`var'_t*``var'_p'
	
	loc section = substr("`var'",1,1)
	replace pp_`var'_pot=.d if `section'0_section_skip==1
	
	loc label = `"Potential PP - `: var label `var'_t'"'
	di "`label'"
	la var pp_`var'_pot "`label'"
	
}

*---------------------------------------------------
* PP by Indicator per month (Total & Guidline combined)
*---------------------------------------------------
/*
foreach var in `vars_g_short' {
	foreach type in "" "_v" {
		
		g pp_`var'`type'=pp_`var'_t`type'+pp_`var'_g`type'

		loc section = substr("`var'",1,1)
		replace pp_`var'`type'=.d if `section'0_section_skip==1
		
	}
}
*/

*---------------------------------------------------
* Performance Pay per PHCU per month
*---------------------------------------------------

fn 		pp*_pot
egen 	pp_p_phcu_m_tzs = rowtotal(`r(varlist)')
g 		pp_p_phcu_m_usd = pp_p_phcu_m_tzs/`exchangerate'

fn 		pp*v
egen 	pp_v_phcu_m_tzs = rowtotal(`r(varlist)')
g 		pp_v_phcu_m_usd = pp_v_phcu_m_tzs/`exchangerate'

*---------------------------------------------------
* Percentage of verifiable/potential 
*---------------------------------------------------

g pp_r_phcu_m=(pp_v_phcu_m_tzs/pp_p_phcu_m_tzs)*100

*---------------------------------------------------
* Performance Improvement Fund / Discretionary Fund 
*---------------------------------------------------

foreach currency in usd tzs {
	g pp_v_pif_total_m_`currency' = `fundsplit'		* pp_v_phcu_m_`currency'
	g pp_v_dif_total_m_`currency' = (1-`fundsplit')	* pp_v_phcu_m_`currency'
}

************************************************************************
* Label Variables
************************************************************************

la var pp_p_phcu_m_tzs "Potential PP per month, TZS"
la var pp_p_phcu_m_usd "Potential PP per month, USD"
la var pp_v_phcu_m_tzs "PP per month, TZS"
la var pp_v_phcu_m_usd "PP per month, USD"

la var pp_v_pif_total_m_tzs "Performance Improvement fund per month, TZS"
la var pp_v_pif_total_m_usd "Performance Improvement fund per month, USD"
la var pp_v_dif_total_m_tzs "Discretionary fund per month, TZS"
la var pp_v_dif_total_m_usd "Discretionary fund per month, TZS"

************************************************************************
* Save
************************************************************************

keep id* pp*

order *, alpha
order pp_v_* pp_p_* pp_v_dif* pp_v_pif* 
order id*
order id_phcu

qui compress
sa "$CLEAN/performance pay/`period'/pp03_analysis(pay_m)", replace

*************************************************************************
* Reshape wide
*************************************************************************

keep id_phcu id_phcu_name id_period_ym id_zone pp_v_*_tzs
drop pp_v_phcu_m_tzs
ren pp* pp*_

reshape wide pp_v_dif_*_ pp_v_pif_*_ , i(id_phcu) j(id_period_ym)
ren pp_v_dif_total_m_tzs* pp_v_dif_tzs*

order *, alpha
order id_phcu id_phcu_name id_zone

*************************************************************************
* Merge in equity file
*************************************************************************

* Merge
merge 1:1 id_phcu_name using "$CLEAN/phcuinfo_equitycat"
ta id_phcu_name if _merge!=3
assert _merge==3
cap: drop _merge

*************************************************************************
* Calculate equity adjustment
*************************************************************************

g cat_per = .
forval i = 1/5 {
	replace cat_per = `cat`i'' if cat==`i'
}

fn pp*
foreach var in `r(varlist)' {
	g `var'_eq=`var'* (1+cat_per)
	compare `var'_eq `var'
	qui drop `var'
	qui ren `var'_eq `var'
}
drop cat cat_per

*************************************************************************
* Save 
*************************************************************************

compress
sa "$CLEAN/performance pay/`period'/pp03(pay_m)", replace

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/



