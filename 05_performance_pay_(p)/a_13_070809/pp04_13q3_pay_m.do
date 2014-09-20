/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Sep 2013

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OVERVIEW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

(01) ...
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

* Set Performance Pay base (TZS)
*---------------------------------------------------
loc base=448

* Set Multipliers 
*---------------------------------------------------

* Quantity (OV)
loc ov_a01 =	`base' * 1loc ov_a02 =	`base' * 2.375loc ov_a03 =	`base' * 2.625
loc ov_a04 =	`base' * 10.375
loc ov_a05 =	`base' * 10
loc ov_b01 =	`base' * 2.625loc ov_b02 =	`base' * 2.75loc ov_b03 =	`base' * 4.75loc ov_b04 =	`base' * 4.875loc ov_b05 =	`base' * 1.25loc ov_b06 =	`base' * 10.125loc ov_b07 =	`base' * 4loc ov_b08 =	`base' * 10.25loc ov_b09 =	`base' * 1.25/2
loc ov_b10 =	`base' * 1.25/2loc ov_b11 =	`base' * 1.125
loc ov_b12 =	`base' * 3.5
loc ov_b13 =	`base' * 10.375
/// M: 3.952380952  

* Quality (gv)
loc gv_a01 =	`ov_a01' * 2loc gv_a02 =	`ov_a02' * 2loc gv_a03 =	`ov_a03' * 2loc gv_a05 =	`ov_a05' * 1.2loc gv_b01 =	`ov_b01' * 1.2loc gv_b03 =	`ov_b03' * 1.5
* MISTAKE? WE DON'T HAVE A GUIDLINE THERE DO WE?loc gv_b05 =	`ov_b05' * 2loc gv_b06 =	`ov_b06' * 2loc gv_b08 =	`ov_b08' * 1.2

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set more off
set linesize 100

u "$TEMP/s_phcu03_clean", clear

drop id_zone id_zone_name id_district id_district_name

* Get locals of all section a & b variables for quality and quantity subsection
*---------------------------------------------------
foreach suffix in ov gv {
	qui fn a*_`suffix' b*_`suffix'
	foreach var in `r(varlist)' {
		loc suf : subinstr loc var "_`suffix'" ""
		loc `suffix'_sectionab  ``suffix'_sectionab' `suf'
	}
	
	di as error "`suffix'"
	di `"``suffix'_sectionab'"'
}

************************************************************************
* (01) Calculating Performance Pay by PHCU
************************************************************************
/*
* Clone variable: Guidlines followed, potential (gp) = Overall, reported (ov)
fn a*_ov b*_ov
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_ov" "_gp"
	clonevar `newvar' = `var'
}
*/

* Hypothetical values
*---------------------------------------------------
/*
fn *gv
foreach var in `r(varlist)' {
	loc newvar : subinstr loc var "_gv" ""
	replace `newvar'_gv = `newvar'_ov*0.8
}
*/

* Calculate Performance Pay by category
*---------------------------------------------------

* Quantity & Quality subsidy

foreach type in ov gv {
di as error "`type'"
di as error "**************"

	foreach var in ``type'_sectionab' {
		loc i = substr("`var'",1,3)
		di as result "`type'_`i': ``type'_`i'' TZS"
	
		g pp_`var'_`type'=`var'_`type'*``type'_`i''	
	}	
}	

* Total Performance Pay by indicator per month (Quality and Quantity combined)
*---------------------------------------------------
foreach var in `ov_sectionab' {
	g 		pp_`var'_total = pp_`var'_ov 
}
foreach var in `gv_sectionab' {
	replace pp_`var'_total = pp_`var'_ov +  pp_`var'_gv
}

bys v04a_period_m: su pp_a01_opd_newconsul_total

* Total Performance Pay per PHCU per month
*---------------------------------------------------
keep id* pp*total
sort id_phcu_ym
fn pp*total, loc(total)
egen pp_phcu_total_m_tzs = rowtotal(`total')
g pp_phcu_total_m_usd = pp_phcu_total_m_tzs/1600


* Performance Improvement Fund / Discretionary Fund 
*---------------------------------------------------
loc fundsplit = 0.2

foreach currency in usd tzs {
	g pp_pif_total_m_`currency' = `fundsplit'	* pp_phcu_total_m_`currency'
	g pp_df_total_m_`currency' 	= (1-`fundsplit')	* pp_phcu_total_m_`currency'
}

************************************************************************
* (0x) Save
************************************************************************

order pp_df* pp_pif*, after(id_phcu_ym_s)
order pp_a* pp_b*, last
qui compress
sa "$TEMP/pay_m(s_phcu_04)", replace

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


collapse (sum) pp*
list pp_phcu_total*usd pp_pif_*usd pp_df_*usd
