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
loc ov_b13 =	`base' * 3.952380952

* Quality (gv)
loc gv_a01 =	`ov_a01' * 2loc gv_a02 =	`ov_a02' * 2loc gv_a03 =	`ov_a03' * 2loc gv_a05 =	`ov_a05' * 1.2loc gv_b01 =	`ov_b01' * 1.2loc gv_b03 =	`ov_b03' * 1.5loc gv_b05 =	`ov_b05' * 2loc gv_b06 =	`ov_b06' * 2loc gv_b08 =	`ov_b08' * 1.2

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

* Calculate subsidy by category
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

* Total subsidy by indicator (Quality and Quantity combined)
*---------------------------------------------------
foreach var in `ov_sectionab' {
	g 		pp_`var'_total = pp_`var'_ov 
}
foreach var in `gv_sectionab' {
	replace pp_`var'_total = pp_`var'_ov +  pp_`var'_gv
}

bys v04a_period_m: su pp_a01_opd_newconsul_total

* Total subsidy per PHCU per month
*---------------------------------------------------
fn pp*total
egen pp_phcu_total_m_tzs = rowtotal(`r(varlist)')
bys id_phcu: egen temp = sum(pp_phcu_total_m_tzs)
bys id_phcu: egen pp_phcu_total_q1_tzs = max(temp)
drop temp

/*
keep id_phcu id_phcu_name v04a_period_m a*ov b*ov a*gv b*gv pp*
keep if id_phcu==2611
*/

order id* v* a*ov b*ov a*gv b*gv pp*ov pp*gv pp*total  pp_phcu_total*


stop
* Total for 1st quarter
*---------------------------------------------------

* drop vars
drop a* b* v*
keep id* pp_phcu_total_q1_tzs

* drop obs
bys id_phcu: g n = _n
drop if n!=1
drop n

* order / sort
order id* pp_phcu_total_q1_tzs
sort id_phcu_ym

* usd equivilant
g pp_phcu_total_q1_usd = pp_phcu_total_q1_tzs/1600

* total costs 1st quarter
foreach currency in usd tzs {
	bys id_phcu:  g temp = sum(pp_phcu_total_q1_`currency')
	bys id_phcu:  egen pp_total_q1_`currency' = max(temp)
	drop temp
}

su pp_phcu_total_q1_usd
su pp_total_q1_usd

* Performance Improvement Fund / Discretionary Fund 
*---------------------------------------------------
loc fundsplit = 0.2

foreach currency in usd tzs {
	g pp_pif_total_`currency' 	= `fundsplit'		* pp_total_q1_`currency'
	g pp_df_total_`currency' 	= (1-`fundsplit')	* pp_total_q1_`currency'
}


drop id_phcu_ym id_phcu_ym_s

************************************************************************
* (0x) Save
************************************************************************

qui compress
sa "$TEMP/subsidybyphcu(s_phcu_04)", replace

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* Basis of the ID:
Categories are sorted alphabetically:
ID = Island ID [1,2] + District ID [1,6] by Island + PHUC ID by District


/*


* Calculating subsidy for each indicator and each reporting type (verified, reported)
forval i = 1/17 {
	loc zero 0
	if `i'>9 loc zero
	loc i = "`zero'`i'"
	
	foreach letter in or ov gr gv gp {
		if "`letter'"=="or" | "`letter'"=="ov"							loc multiplier 1
		else if "`letter'"=="gr" | "`letter'"=="gv" | "`letter'"=="gp"	loc multiplier 2
		
		if 		"`letter'"=="or"	loc label "overall, reported"
		else if "`letter'"=="ov"	loc label "overall, verified"
		else if "`letter'"=="gr" 	loc label "guidlines, reported"
		else if "`letter'"=="gv"	loc label "guidlines, verified"
		else if "`letter'"=="gp"	loc label "guidlines, potential"
			
		cap { // you need to cap this because the variables aren't balanced
			fn pm`i'`letter'*
			loc var = "`r(varlist)'" 
			
			loc varnew : subinstr loc var  "pm`i'`letter'" ""
			loc varnew : subinstr loc varnew "_N" "_tzs"
		
			g s_`letter'_`i'`varnew'=`var'*`pm`i''*`multiplier'	
			replace s_`letter'_`i'`varnew'=0 if s_`letter'_`i'`varnew'==.		
			*loc varlabel = `"`: var label `var''"'		
			la var s_`letter'_`i'`varnew' "PHCU subsidy, `label'"	
		}	
	}
}

* Summing up o+g for each indicator
forval i = 1/17 {
	loc zero 0
	if `i'>9 loc zero
	loc i = "`zero'`i'"
	
	fn pm`i'or*
	loc var = "`r(varlist)'" 
	
	loc varnew : subinstr loc var  "pm`i'or" ""
	cap: loc varnew : subinstr loc varnew "_N" "_tzs"
	
	* REPORTED, VERIFIED
	foreach letter in r v {
	if 		"`letter'"=="r" loc varlabel "reported"
	else if "`letter'"=="v" loc varlabel "verified"
		
		
		g s_`letter'_`i'`varnew' = s_o`letter'_`i'`varnew'+s_g`letter'_`i'`varnew'
		la var s_`letter'_`i'`varnew'  "PHCU subsidy, `varlabel'"	
	}
	
	* POTENTIAL
	di "s_`letter'_`i'`varnew'"
	g s_p_`i'`varnew' = s_gp_`i'`varnew'+s_ov_`i'`varnew'
	la var s_p_`i'`varnew'  "PHCU subsidy, potential"
}

fn pm*gp_*
drop `r(varlist)'


* Calculate total subsidy
*---------------------------------------------------
foreach letter in or ov gr gv r v  {
	egen s_`letter'_total=rowtotal(s_`letter'_*_tzs)
	egen s_`letter'_avg=rowmean(s_`letter'_*_tzs)
}


* Pecentage attainment of possible
*---------------------------------------------------
forval i = 1/20 {
	loc zero 0
	if `i'>9 loc zero
	loc i = "`zero'`i'"
	
	di "`i'"
	
	qui fn s`i'ov*, loc(var)
	loc varend : subinstr loc var "s`i'ov_" ""
	cap loc varcore : subinstr loc varend "_tzs" ""
		
		g s`i'_o_`varcore'_pct = s`i'ov_`varend'/s`i'or_`varend'
		g s`i'_g_`varcore'_pct = s`i'gv_`varend'/s`i'gr_`varend'
}

************************************************************************
* (02) Summary stats
************************************************************************

*outvarlist2 s19ov_total s19or_total s19o_total_pct s19r_total_pct, su(mean min p25 p50 p75 max) 
*outvarlist2 s*pct, su(mean min p25 p50 p75 max) 

*bys id_phcu_name: su s19ov_total s19or_total

bys verification_period_m: su pm01or_opd_newconsul_N pm01ov_opd_newconsul_N
bys verification_period_m: su pm01gr_opd_newconsul_N pm01gv_opd_newconsul_N

g testo2 = pm01ov_opd_newconsul_N/pm01or_opd_newconsul_N
su testo2

* Conclusion #1: 
*-----------------------------
* --> reported many more phone numbers overall and in OPD
* from 16% to 67%
ttest s19o_total_pct, by(verification_period_m) level(90)

*===========================================
* SUBSIDY STATS
*===========================================

* Conclusion #2: 
*-----------------------------
* --> much higher potential mean subsidy due to more phone numbers
ttest s20o_avg_pct, by(verification_period_m) level(99.9)
* from 16% to 67% at 99.9% statistical significant level

ttest s01o_opd_newconsul_pct, by(verification_period_m) level(99.9)
* from 16% to 50% at 99.9% statistical significant level

*/
/* Conclusion #3: 
*-----------------------------
We cannot say anything about changes in quality because
we didn't measure quality well in the July. Therefore,
I only have levels to report on. */ 
/*
bys verification_period_m: su pm01ov_opd_newconsul_N  pm01gv_opd_newconsul_N

g test3 = pm01gv_opd_newconsul_N/pm01ov_opd_newconsul_N
su test3
* --> 40 % of OPD (that have a phone number) follow the guidelines 
 

bys verification_period_m: su s19or_total s19ov_total
bys verification_period_m: su s19gr_total s19gv_total
bys verification_period_m: su s19o_total_pct s19g_total_pct




* Conclusion #2:
*-----------------------------





*/


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
