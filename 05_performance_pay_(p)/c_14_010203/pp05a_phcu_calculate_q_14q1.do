/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Jun 4 2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set linesize 225

* Period name
loc period 14_010203

************************************************************************
* METHOD I: Performance Pay per Quarter
************************************************************************
/*
u "$CLEAN/performance pay/`period'/pp03_analysis(pay_m)", clear

fn *_pot
drop `r(varlist)' 

* Extract Local
fn pp_v_* pp_p_*, loc(varlist)

foreach var in `varlist' {
	loc newvar : subinstr loc var "_m_" "_q_"
	loc newvarlist `newvarlist' `newvar'

	di as result "`newvar' = `var'"
	
	bys id_phcu: egen temp = total(`var')
	bys id_phcu: egen `newvar' = max(temp)
	
	drop temp
}

* Drop obs
bys id_phcu: g n = _n
keep if n==1

* Drop vars
fn *, remove(id_phcu `newvarlist')
drop `r(varlist)'

* Save
ren pp* c_pp*
tempfile Method1
sa `Method1', replace

************************************************************************
* METHOD II: Performance Pay per Quarter
************************************************************************

u "$CLEAN/performance pay/`period'/pp02_analysis(pay_m)", clear
collapse (sum) `varlist', by(id_phcu)
ren *_m_* *_q_*
merge 1:1 id_phcu using "$CLEAN/PHCU_IDs", nogen
drop id1 id2 id3 id4
drop id_district_name id_zone_name
order id*

* Save
tempfile Method2
sa `Method2', replace

************************************************************************
* Compare Method I & II
************************************************************************

u `Method1', clear
merge 1:1 id_phcu using `Method2', nogen
order id* 

fn pp* 
foreach var in `r(varlist)' {
	compare `var' c_`var'
}
*/
************************************************************************
* METHOD III: Performance Pay per Quarter
************************************************************************

u "$CLEAN/performance pay/`period'/pp03(pay_m)", clear

drop *dif*

foreach var in pp_v_pif_total_m_tzs {
	egen pp_v_pif_13_070809_tzs=rowtotal(`var'_1307 `var'_1308 `var'_1309)
	egen pp_v_pif_13_101112_tzs=rowtotal(`var'_1310 `var'_1311 `var'_1312)
	egen pp_v_pif_14_010203_tzs=rowtotal(`var'_1401 `var'_1402 `var'_1403)
}

drop pp_v_pif_total_m_tzs*

* Total 
egen pp_v_pif_total_tzs = rowtotal(pp_v_pif_13_070809_tzs pp_v_pif_13_101112_tzs pp_v_pif_14_010203_tzs)

* Round
fn *tzs 
foreach var in `r(varlist)' {
	replace  `var' = round(`var',500)
}
/*
* Convert
foreach var in `r(varlist)' {
	g `var'_usd = `var'
	replace `var'_usd = `var'/1600
	ren *_tzs_usd *_usd
}
*/
// NEED TO INTIGRATE THE PRE-REFORMATING DATA IN (QUARTER 1 TO CALCULATE BONUS) 


************************************************************************
* Inspect data
************************************************************************

su pp*

************************************************************************
* Save
************************************************************************

qui compress
sa "$CLEAN/performance pay/`period'/pp05a_(pif_q)", replace


