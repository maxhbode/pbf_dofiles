
u "$CLEAN/pp03a_13q4", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

*************************************************************************
* Round
*************************************************************************

g hw_r_bonus_tzs_13q4_round1k = round(hw_r_bonus_tzs_13q4,1000)

*************************************************************************
* Droping 
*************************************************************************

* Drop O's
list hw07_daysworked_10 hw07_daysworked_11 hw07_daysworked_12 if hw_r_bonus_tzs_11==0

* Sort
sort id_hw

* Drop
keep id*  ///	
	hw_r_bonus_tzs_10 hw_r_bonus_tzs_11 hw_r_bonus_tzs_12 ///
	hw_r_bonus_tzs_13q4 hw_r_bonus_tzs_13q4_round1k ///
	hw07_daysworked_10 hw07_daysworked_11 hw07_daysworked_12 hw_salarylevel ///
	hw05_cadre_code hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur ///
	BankAccountnumber Bankname RealizedBonusQ42013r_old Signature Signature_note

*************************************************************************
* Label
*************************************************************************

la var id_phcu 				"PHCU ID"
la var id_phcu_name 		"PCHU name"
la var id_hw 				"Staff ID"
la var hw01_name_1 			"Name 1"
la var hw02_name_2 			"Name 2"
la var hw03_name_3 			"Name 3"
la var hw04_name_sur		"Sur Name"
la var hw05_cadre_code 		"Cadre"
la var hw_salarylevel		"Salary Level"
la var hw07_daysworked_10 	"Oct: Days worked"
la var hw07_daysworked_11 	"Nov: Days worked"
la var hw07_daysworked_12	"Dec: Days worked"
la var id_zone				"Zone ID"
la var Signature_note		"Singature Note"

la var hw_r_bonus_tzs_13q4			"Realized Bonus, Q4 2013"
la var hw_r_bonus_tzs_13q4_round1k 	"Realized Bonus, Q4 2013 (rounded)"

*************************************************************************
* Order
*************************************************************************t

order id_zone id_phcu id_phcu_name id_hw ///
	hw01_name_1 hw02_name_2 hw03_name_3 ///
	hw04_name_sur hw_r_bonus_tzs_13q4_round1k ///
	hw07_daysworked_10 hw07_daysworked_11 hw07_daysworked_12 ///
	hw_r_bonus_tzs_10 hw_r_bonus_tzs_11 hw_r_bonus_tzs_12 hw_r_bonus_tzs_13q4 ///
	hw_salarylevel hw05_cadre_code id_zone
	
*************************************************************************
* Save
*************************************************************************

drop RealizedBonusQ42013r_old

sa "$TEMP/pp05bii", replace

export excel using "$VIEW/performance pay/2013q4_bonuses_determinents", replace firstrow(varlabels)
drop hw07_daysworked_10 hw07_daysworked_11 hw07_daysworked_12 hw_r_bonus_tzs_10 hw_r_bonus_tzs_11 hw_r_bonus_tzs_12 hw_r_bonus_tzs_13q4 hw_salarylevel hw05_cadre_code
export excel using "$VIEW/performance pay/2013q4_bonuses", replace firstrow(varlabels)

* By facility 
*------------------------------
preserve
collapse (sum) hw_r_bonus_tzs_13q4_round1k, by(id_phcu id_phcu_name)
la var hw_r_bonus_tzs_13q4_round1k "Total Bonus by PHCU"
export excel using "$VIEW/performance pay/2013q4_bonuses_sheetbyfacility", ///
	replace sheet(all) firstrow(varlabels)
restore

levelsof id_phcu, loc(phcu)
foreach phcu_i in `phcu' {
	preserve
	keep if id_phcu==`phcu_i'
	qui export excel using "$VIEW/performance pay/2013q4_bonuses_sheetbyfacility", ///
		firstrow(varlabels) sheetreplace  sheet("`phcu_i'") 	
	restore
}

* By bank
*------------------------------
preserve
collapse (sum) hw_r_bonus_tzs_13q4_round1k, by(Bankname)
la var hw_r_bonus_tzs_13q4_round1k "Total Bonus by Bank"
export excel using "$VIEW/performance pay/2013q4_bonuses_sheetbybank", ///
	replace sheet(all) firstrow(varlabels)
restore

sort id_phcu_name 

levelsof Bankname, loc(banks)
foreach b in `banks' {
	preserve
	keep if Bankname=="`b'"
	export excel using "$VIEW/performance pay/2013q4_bonuses_sheetbybank", ///
		sheetreplace sheet("`b'") firstrow(varlabels) 
	restore
}







