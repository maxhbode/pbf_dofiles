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
loc yy 14
loc period 14_010203
loc m1 1
loc m2 2
loc m3 3
loc ym1 `yy'01
loc ym2 `yy'02
loc ym3 `yy'03
loc mm1 "Jan"
loc mm2 "Feb"
loc mm3 "Mar"

*************************************************************************
* Merge Performance with Staff Data
*************************************************************************

u "$CLEAN/performance pay/`period'/pp03(pay_m)", clear
sort id_phcu_name
drop pp_*pif*

list id_phcu id_phcu_name  if inlist(id_phcu,1309,1310) 

merge 1:m id_phcu using "$CLEAN/si02_14_0102003_DIRTY(cleaninputs)"
list id_phcu id_phcu_name if _merge!=3
assert _merge==3
cap: drop _merge

order *, alpha
order id*

*************************************************************************
* Drop all periods
*************************************************************************

* SALARY WEIGHTING CHANGED EFFECTIVE 2014 01/02/03
drop pp_*_13*

*************************************************************************
* Set salary weights
*************************************************************************

drop hw06_salarylevel
g hw06_salarylevel = .
replace hw06_salarylevel=1		if hw05_cadre_code<. & hw05_cadre_code>=70
replace hw06_salarylevel=2		if hw05_cadre_code<70 & hw05_cadre_code>=50
replace hw06_salarylevel=2.5 	if hw05_cadre_code<50 & hw05_cadre_code>=40
replace hw06_salarylevel=2.8 	if hw05_cadre_code<40 & hw05_cadre_code>=30
replace hw06_salarylevel=3 		if hw05_cadre_code<30 & hw05_cadre_code>=20 


/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
replace hw07_daysworked_1 = 1
replace hw07_daysworked_2 = 1
replace hw07_daysworked_3 = 1
*/

*************************************************************************
* Create S/A (salary/attendance) weight
*************************************************************************

forval i = `m1'/`m3' {

	* Monthly S/A input by individual
	g hw_sainput_byi_`i' = hw07_daysworked_`i'* hw06_salarylevel

	* Sum of S/A weight by PHCU
	bys id_phcu: egen hw_sainput_byf_`i' = total(hw_sainput_byi_`i')
	
	* S/A weight by individual
	g hw_saweight_byi_`i' = hw_sainput_byi_`i'/hw_sainput_byf_`i'
	
	* Sum of S/A weights by facility
	bys id_phcu: egen hw_saweight_byf_`i' = total(hw_saweight_byi_`i')
	qui su hw_saweight_byf_`i'
	
	if `r(mean)'!=1 {
		di as error "ERROR: hw_saweight_byf_`i'=`r(mean)'!=1
		ta hw_saweight_byf_`i'
		list id_phcu  hw_saweight_byf_`i' if hw_saweight_byf_`i'!=1 & (hw_saweight_byf_`i'>1.01 | hw_saweight_byf_`i'<0.999 )
		// only individual in 1 month
	}
	else {
		di as result "hw_saweight_byf_`i'=`r(mean)'"
	}
	
	drop hw_sainput*  hw_saweight_byf*
} 

order id_hw id_phcu hw_saweight_byi_*

*************************************************************************
* Create S/A (salary/attendance) weight - same attendance 
*************************************************************************

forval i = `m1'/`m3' {

	* Monthly S/A input by individual
	g hw_sainput_byi_p_`i' = hw06_salarylevel

	* Sum of S/A weight by PHCU
	bys id_phcu: egen hw_sainput_byf_p_`i' = total(hw_sainput_byi_p_`i')
	
	* S/A weight by individual
	g hw_saweight_byi_p_`i' = hw_sainput_byi_p_`i'/hw_sainput_byf_p_`i'
	
	* Sum of S/A weights by facility
	bys id_phcu: egen hw_saweight_byf_p_`i' = total(hw_saweight_byi_p_`i')
	qui su hw_saweight_byf_p_`i'
	
	if `r(mean)'!=1 {
		di as error "ERROR: hw_saweight_byf_p_`i'=`r(mean)'!=1
		ta hw_saweight_byf_p_`i'
		list id_phcu  hw_saweight_byf_p_`i' if hw_saweight_byf_p_`i'!=1 & (hw_saweight_byf_p_`i'>1.01 | hw_saweight_byf_p_`i'<0.999 )
		// only individual in 1 month
	}
	else {
		di as result "hw_saweight_byf_p_`i'=`r(mean)'"
	}
	
	drop hw_sainput*  hw_saweight_byf_p*
} 

order id_hw id_phcu hw_saweight_byi_p*

*************************************************************************
* Calculate Bonus
*************************************************************************

* Per Month
forval i = `m1'/`m3' {
	loc ii = 140`i'
	g pp_v_bonus_tzs_`ii'=hw_saweight_byi_`i'*pp_v_dif_tzs_`ii'
	la var pp_v_bonus_tzs_`ii' "Realized Bonus, `ii'"
	
	*g hw_p_bonus_tzs_`ii'=hw_saweight_byi_p_`i'*pp_p_phcu_m_tzs_`ii'
	*la var hw_p_bonus_tzs_`ii' "Potential Bonus, `ii'"	
}


egen pp_v_bonus_tzs_`period' = rowtotal(pp_v_bonus_tzs_`ym1' pp_v_bonus_tzs_`ym2' pp_v_bonus_tzs_`ym3')
g pp_v_bonus_usd_`period' = pp_v_bonus_tzs_`period'/1600
*egen hw_p_bonus_tzs_13q4 = rowtotal(hw_p_bonus_tzs_`m1' hw_p_bonus_tzs_`m2' hw_p_bonus_tzs_`m3')
*g hw_p_bonus_usd_13q4 = hw_p_bonus_tzs_13q4/1600

order id* pp_v_* 
*hw_p_*

* Check bonuses
su pp_v_bonus_tzs_14_010203 pp_v_bonus_usd_14_010203

*************************************************************************
* Drop empty rows
*************************************************************************

list id_phcu_name hw01* hw02* hw03* if hw07_daysworked_`m1'==0 & hw07_daysworked_`m2'==0 & hw07_daysworked_`m3'==0
drop if hw07_daysworked_`m1'==0 & hw07_daysworked_`m2'==0 & hw07_daysworked_`m3'==0

*************************************************************************
* Round
*************************************************************************

g pp_v_bonus_tzs_14_010203_mia5 = round(pp_v_bonus_tzs_14_010203,1000)

* Impact of rounding
egen sum1 = total(pp_v_bonus_tzs_14_010203)
egen sum2 = total(pp_v_bonus_tzs_14_010203_mia5)
g diff = sum1 - sum2 
replace diff = round(diff,1)
di "Raw: " sum1 " - Rounded: " sum2 " Difference: " diff
drop sum1 sum2 diff

*************************************************************************
* Label
*************************************************************************

la var id_phcu 				"PHCU ID"
la var id_phcu_name 		"PCHU name"
la var id_hw 				"Staff ID"
la var hw01_name_1 			"Name 1"
la var hw02_name_2 			"Name 2"
la var hw03_name_3 			"Name 3"
la var hw04_name_sur		"Sur name"
la var hw05_cadre_code 		"Cadre"
la var hw06_salarylevel		"Salary Level"
la var hw07_daysworked_`m1' "`mm1' - days worked"
la var hw07_daysworked_`m2' "`mm2' - days worked"
la var hw07_daysworked_`m3'	"`mm3' - days worked"
la var id_zone				"Zone ID"
*la var Signature_note		"Singature Note"

la var pp_v_bonus_tzs_14_010203			"Bonus, 20`yy' `mm1'-`mm3'"
la var pp_v_bonus_tzs_14_010203_mia5 	"Bonus, 20`yy' `mm1'-`mm3' (rounded)"

*************************************************************************
* Sort & Order
*************************************************************************

sort id_hw

order *, alpha
order id_zone id_phcu id_phcu_name id_hw ///
	hw0*name* hw04_name_sur ///
	hw05_cadre_code hw06_salarylevel  ///
	pp_v_bonus_tzs_14_010203_mia5 hw07_* pp_v_bonus*


*************************************************************************
* Manual change (due to request mistake)
*************************************************************************

replace pp_v_bonus_tzs_14_010203_mia5=pp_v_bonus_tzs_14_010203_mia5+1000 if id_hw==261405
replace pp_v_bonus_tzs_14_010203_mia5=pp_v_bonus_tzs_14_010203_mia5-1000 ///
if inlist(id_hw,130501,130502,130503,130504,130505)

*************************************************************************
* Save for Analysis
*************************************************************************

* Drop
drop id_phcu_s ba_startnumber hw11_ba_first 

* Save
compress
sa "$CLEAN/performance pay/`period'/pp03a_foranalysis(dif_q)", replace

*************************************************************************
* Save for Outsheeting 
*************************************************************************

* Drop
drop *weight* *reason* *`ym1' *`ym2' *`ym3' id_phcu_name ///
	pp_v_bonus_tzs_`period'	*_usd_*  

* Save 
compress
sa "$CLEAN/performance pay/`period'/pp04a_foroutsheeting(dif_q)", replace
