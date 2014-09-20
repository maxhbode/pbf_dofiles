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

* Install value Labels
run "$DO/01b_all_value_labels.do"

* Period name
loc yy 14
loc period 14_040506
loc m1 4
loc m2 5
loc m3 6
loc ym1 `yy'04
loc ym2 `yy'05
loc ym3 `yy'06
loc mm1 "Apr"
loc mm2 "May"
loc mm3 "Jun"

***********************************************************************
* Export Outsheet
***********************************************************************

* Open
u "$CLEAN/performance pay/`period'/pp04a_foroutsheeting(dif_q)", clear

*drop if id_phcu==2614 // WITHOUT SHAKANI 
*loc special _noshakani
*loc special _shakanionly

la var id_hw_new_s "Staff ID (new)"

order *, alpha
order id_zone id_phcu id_hw*
drop id_hw_new id_hw

export excel using "$VIEW/performance pay/`period'/bonuses_determinents`special'", replace firstrow(varlabels)

drop hw06_salarylevel hw07_daysworked* 

* For data entry next period (by facility)
*-----------------------------------------------------
g Cadre = hw05_cadre_code 
order Cadre, before(hw05_cadre_code)

sdecode hw13_bankname, replace

tostring hw11_account_number, replace
replace hw11_account_number = "~" + hw11_account_number

forval i = `m1'/`m3' {
	g days_`i'=.
	la var days_`i' "`mm`i'' - days worked"
	g reason_`i'=. 
	la var reason_`i' "`mm`i'' - reason"
}
g comment = ""
order hw11_account_number, last

levelsof id_phcu, loc(phcu)
foreach phcu_i in `phcu' {
	preserve
	drop pp_v_bonus_tzs_`period'_mia5 hw13_bankname 
	
	keep if id_phcu==`phcu_i'
	qui export excel using "$VIEW/staff/`period2'_staffdata", ///
		firstrow(varlabels) sheetreplace  sheet("`phcu_i'") 
	restore
}

drop id_zone days* reason*  hw05_cadre_code

drop id_hw* comment 

order pp_v_bonus_tzs_14_040506_mia5	hw13_bankname hw11_account_number , last


la var id_phcu "PHCU" 



* By facility 
*------------------------------
preserve
	collapse (sum) pp_v_bonus_tzs_`period'_mia5, by(id_phcu)
	la var pp_v_bonus_tzs_`period'_mia5 "Total Bonus by PHCU"
	
	* Total row
	describe, s
	loc N = `r(N)'+1
	set obs `N'
	sdecode id_phcu, replace
	replace id_phcu="TOTAL" in `N'
	g s_pp_v_bonus_tzs_`period'_mia5=sum(pp_v_bonus_tzs_`period'_mia5)
	replace pp_v_bonus_tzs_`period'_mia5 = s_pp_v_bonus_tzs_`period'_mia5 in `N'
	drop s_pp_v_bonus_tzs_`period'_mia5
	format %9.0f pp_v_bonus_tzs_`period'_mia5

	export excel using "$VIEW/performance pay/`period'/bonuses_sheetbyfacility`special'", ///
		replace sheet(all) firstrow(varlabels)
		
restore

levelsof id_phcu, loc(phcu)
foreach phcu_i in `phcu' {
	preserve
	keep if id_phcu==`phcu_i'
	qui export excel using "$VIEW/performance pay/`period'/bonuses_sheetbyfacility`special'", ///
		firstrow(varlabels) sheetreplace  sheet("`phcu_i'") 
	restore
}

* By bank
*------------------------------

drop Cadre id_phcu

preserve

	collapse (sum) pp_v_bonus_tzs_`period'_mia5, by(hw13_bankname)
	la var pp_v_bonus_tzs_`period'_mia5 "Total Bonus by Bank"
	
	* Total row
	describe, s
	loc N = `r(N)'+1
	set obs `N'
	replace hw13_bankname="TOTAL" in `N'
	g s_pp_v_bonus_tzs_`period'_mia5=sum(pp_v_bonus_tzs_`period'_mia5)
	replace pp_v_bonus_tzs_`period'_mia5 = s_pp_v_bonus_tzs_`period'_mia5 in `N'
	drop s_pp_v_bonus_tzs_`period'_mia5
	format %9.0f pp_v_bonus_tzs_`period'_mia5
	
	export excel using "$VIEW/performance pay/`period'/bonuses_sheetbybank`special'", ///
		replace sheet(all) firstrow(varlabels)
			
restore



levelsof hw13_bankname, loc(banks)
foreach b in `banks' {
	preserve
	keep if hw13_bankname=="`b'"
	export excel using "$VIEW/performance pay/`period'/bonuses_sheetbybank`special'", ///
		sheetreplace sheet("`b'") firstrow(varlabels) 
	restore
}
