



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
	
	keep id_phcu id_phcu_name id_district

	tempfile temp
	sa `temp', replace
restore 

merge 1:1 id_phcu_name using `temp', nogen
 

* Catergories
ta cat
clonevar cat_name = cat
la de cat_namel 1 "very central" 2 "central" 3 "remote" 4 "very remote" 5 "extremly remote", replace
la val cat_name cat_namel
sdecode cat_name, replace

* Reduction
g cat_red = .
replace cat_red = -.1	if cat==1
replace cat_red = 0		if cat==2
replace cat_red = .1	if cat==3
replace cat_red = .2	if cat==4
replace cat_red = .3	if cat==5
 
g cat_red_pct = cat_red*100 
tostring cat_red_pct, replace
replace cat_red_pct = cat_red_pct+"%"

* Save
compress
order id*
sa "$CLEAN/phcuinfo_equitycat(02_phcu_equity)", replace


* Outsheet
drop id_phcu cat_red

sort cat
order cat cat_name

drop if id_district==26
