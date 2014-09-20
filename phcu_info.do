



insheet using "$RAW/equity/equity_scores_final_readable.csv", c clear names

* Manipualte 
replace id_phcu_name = itrim(trim(proper(id_phcu_name)))
replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit El Ras"
replace id_phcu_name="RCH Mkoani" if id_phcu_name=="Rch Mkoani"
replace id_phcu_name="Mbweni Matrekta" if id_phcu_name=="Matrakta"

g cat = .
forval i = 1/5 {
	replace cat = `i' if cat_`i'==1
}
ta cat, mi

* Drop 
drop cat_*




* Get ID
preserve 
	u "$GENERAL/phcu_info/phcu_info_clean_2014", clear
	keep if inlist(id_district,13,26)
	ta id_district_name  
	
	keep id_phcu id_phcu_name

	tempfile temp
	sa `temp', replace
restore 

merge 1:1 id_phcu_name using `temp', nogen
 


* Save
compress
order id*
sa "$CLEAN/phcuinfo_equitycat", replace


