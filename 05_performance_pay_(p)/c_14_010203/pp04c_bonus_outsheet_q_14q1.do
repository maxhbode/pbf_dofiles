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
loc period 14_010203
loc period2 14_040506
loc m1 1
loc m2 2
loc m3 3
loc m4 4
loc m5 5
loc m6 6
loc ym1 `yy'01
loc ym2 `yy'02
loc ym3 `yy'03
loc mm1 "Jan"
loc mm2 "Feb"
loc mm3 "Mar"
loc mm4 "Apr"
loc mm5 "May"
loc mm6 "Jun"

***********************************************************************
* Export Outsheet
***********************************************************************



* Open
u "$CLEAN/performance pay/`period'/pp04a_foroutsheeting(dif_q)", clear

*drop if id_phcu==2614 // WITHOUT SHAKANI 
*loc special _noshakani
*loc special _shakanionly

order *, alpha
order id_zone id_phcu id_hw 

export excel using "$VIEW/performance pay/`period'/bonuses_determinents`special'", replace firstrow(varlabels)

*export excel using "$VIEW/performance pay/`period'/bonuses", replace firstrow(varlabels)
drop hw06_salarylevel hw07_daysworked* 

* For data entry next period (by facility)
*-----------------------------------------------------
g Cadre = hw05_cadre_code 
order Cadre, before(hw05_cadre_code)

g Bank = .
replace Bank=1 if hw13_bankname=="PBZ"
replace Bank=2 if hw13_bankname=="PBZ Islamic Bank"
replace Bank=3 if hw13_bankname=="NBC"
replace Bank=4 if hw13_bankname=="Postal Bank"
replace Bank=5 if hw13_bankname=="FBME B"  

tostring hw11_account_number, replace
replace hw11_account_number = "~" + hw11_account_number

forval i = `m4'/`m6' {
	g days_`i'=.
	la var days_`i' "`mm`i'' - days worked"
	g reason_`i'=. 
	la var reason_`i' "`mm`i'' - reason"
}
g comment = ""
order hw11_account_number Bank, last

levelsof id_phcu, loc(phcu)
foreach phcu_i in `phcu' {
	preserve
	drop pp_v_bonus_tzs_14_010203_mia5 hw13_bankname 
	
	keep if id_phcu==`phcu_i'
	qui export excel using "$VIEW/staff/`period2'_staffdata", ///
		firstrow(varlabels) sheetreplace  sheet("`phcu_i'") 
	restore
}

drop id_zone days* reason*  hw05_cadre_code

* By facility 
*------------------------------
preserve
collapse (sum) pp_v_bonus_tzs_14_010203_mia5, by(id_phcu)
la var pp_v_bonus_tzs_14_010203_mia5 "Total Bonus by PHCU"
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

preserve
collapse (sum) pp_v_bonus_tzs_14_010203_mia5, by(hw13_bankname)
la var pp_v_bonus_tzs_14_010203_mia5 "Total Bonus by Bank"
export excel using "$VIEW/performance pay/`period'/bonuses_sheetbybank`special'", ///
	replace sheet(all) firstrow(varlabels)
restore

sort id_phcu

levelsof hw13_bankname, loc(banks)
foreach b in `banks' {
	preserve
	keep if hw13_bankname=="`b'"
	export excel using "$VIEW/performance pay/`period'/bonuses_sheetbybank`special'", ///
		sheetreplace sheet("`b'") firstrow(varlabels) 
	restore
}







