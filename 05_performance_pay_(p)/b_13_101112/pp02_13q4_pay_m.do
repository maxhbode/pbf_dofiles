/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Feb 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


set linesize 225

*---------------------------------------------------
* Graph Options
*---------------------------------------------------

* Stop graphs
loc GRAPHS 0

* Choose format: pdf or png
loc format png

* Choose color scheme: s2color or s2mono
loc scheme s2color 
set scheme `scheme'  

* General Graph Options
#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
		;
#delimit cr

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"


*---------------------------------------------------
* Parameters
*---------------------------------------------------

* Set Performance Pay base (TZS)
loc base=500

* DIF/PIF split
loc fundsplit = 0.2

* TZS/USD exchange rate
loc exchangerate = 1600

* Graphs
loc format pdf

* Set Prices (based on multipliers) 

* Total (t)
loc b00_t =	`base' * 1loc b03_t =	`base' * 2.5loc b04_t =	`base' * 2.5
loc b05_t =	`base' * 10
loc b06_t =	`base' * 10loc c01_t =	`base' * 2.5loc c02_t =	`base' * 3loc c03_t =	`base' * 12.5loc c04_t =	`base' * 5loc c05_t =	`base' * 1.5loc c06_t =	`base' * 10loc c07_t =	`base' * 4loc c08_t =	`base' * 10loc c09_t =	`base' * 1
loc c10_t =	`base' * 1loc c11_t =	`base' * 1
loc c12_t =	`base' * 3.5
loc c13_t =	`base' * 10 

* Guidlines (g)
loc b00_g =	`b00_t' * 2loc b03_g =	`b03_t' * 2loc b04_g =	`b04_t' * 2loc b06_g =	`b06_t' * 1.2loc c01_g =	`c01_t' * 1.2loc c05_g =	`c05_t' * 2loc c06_g =	`c06_t' * 2loc c08_g =	`c08_t' * 1.2

* Potential [p=t*(1+g)]
loc b00_p =	`base' * 3loc b03_p =	`base' * 7.5loc b04_p =	`base' * 7.5loc b05_p =	`base' * 10loc b06_p =	`base' * 22loc c01_p =	`base' * 5.5loc c02_p =	`base' * 3loc c03_p = `base' * 12.5loc c04_p = `base' * 5loc c05_p = `base' * 4.5loc c06_p = `base' * 30loc c07_p = `base' * 4loc c08_p = `base' * 22loc c09_p = `base' * 1loc c10_p = `base' * 1loc c11_p = `base' * 1loc c12_p = `base' * 3.5loc c13_p = `base' * 10

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set more off
set linesize 100

u "$CLEAN/a03(label)", clear

run "$DO/01b_all_value_labels.do"
la val id_period_mm months

************************************************************************
* Prep
************************************************************************

*---------------------------------------------------
* Drop vars
*---------------------------------------------------
drop id_district 
drop b01* b02*

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

fn *_t, loc(vars_t)
loc vars_t_short : subinstr loc vars_t "_t" "", all
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
stop


* Full potential (all quality)
foreach var in `vars_t_short' {

	di `" g pp_`var'_p=`var'_t*``var'_p' "'
	g pp_`var'_p=`var'_t*``var'_p'
	
	loc section = substr("`var'",1,1)
	replace pp_`var'_p=.d if `section'0_section_skip==1
	
	loc label = `"Potential PP - `: var label `var''"'
	la var pp_`var'_p "`label'"
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

fn 		pp*_p
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
sa "$CLEAN/pp02_13q4(pay_m)", replace


************************************************************************
* Graph
************************************************************************


if `GRAPHS'==0 STOP

* Install value Labels
run "$DO/01c_valuelabels_graphs.do"

*over(id_zone)

sort pp_r_phcu_m
#delimit ;
graph hbar pp_r_phcu_m if id_zone==1, 
	over(id_phcu_name, sort(pp_r_phcu_m)) ytitle("Realized PP/Potential PP (all quality), %") 
	title(Realized as percentage of Potential Performance Pay)  
	`graphoptions' ;
#delimit cr
graph  export "$GRAPH/`folder'/performance pay/potentialvsreal_usd.`format'", replace

#delimit ;
graph bar (mean) pp_v_phcu_m_usd  pp_p_phcu_m_usd, over(id_period_mm) over(id_zone) 
	ytitle(USD) title(Average PHCU Performance Pay)
	`graphoptions'  legend(on order(1 "Verifiable" 2 "Potential (all quality)"))
	;
#delimit cr
graph  export "$GRAPH/`folder'/performance pay/potentialvsreal_usd.`format'", replace

#delimit ;
graph bar (mean)  pp_v_phcu_m_tzs  pp_p_phcu_m_tzs, over(id_period_mm)  over(id_zone) 
	ytitle(TZS) title(Average PHCU Performance Pay)
	legend(on order(1 "Verifiable" 2 "Potential (all quality)")) `graphoptions' 
	;
#delimit cr
graph  export "$GRAPH/`folder'/performance pay/potentialvsreal_tzs.`format'", replace

#delimit ;
graph bar (mean) pp_r_phcu_m, over(id_period_mm) over(id_zone) 
	yscale(range(0 100)) ytitle(%) ylabel(#10) `graphoptions' 
	title(Average Verifiable/Potential Performance Pay)
	;
#delimit cr
graph  export "$GRAPH/`folder'/performance pay/potentialvsreal_ratio.`format'", replace


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/



