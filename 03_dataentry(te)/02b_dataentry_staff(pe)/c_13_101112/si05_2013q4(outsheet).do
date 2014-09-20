
* Set period
loc yy 13	 
loc period "`yy'_101112"

*******************************************************************************
* Outsheet
*******************************************************************************

u "$CLEAN/si03_2013q4(reshape)", clear

*************************************************************************
* Outsheet
*************************************************************************

drop hw_salarylevel

foreach var in hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur {
	replace `var' = upper(`var')
}

* Order first
order *, alpha
order id*

* Staring loop	
levelsof id_phcu, loc(id_phcu)

sort id_phcu 

foreach phcu in `id_phcu' {
	preserve	

	qui keep if id_phcu==`phcu' 
	
*	g delete = 0

g cadre_code = hw05_cadre_code
order cadre_code, after(hw05_cadre_code)


* Label
la var id_phcu 				"PHCU ID"
la var id_phcu_name 		"PCHU name"
la var id_hw 				"Staff ID"
la var hw01_name_1 			"Name 1"
la var hw02_name_2 			"Name 2"
la var hw03_name_3 			"Name 3"
la var hw04_name_sur		"Sur Name"
la var hw05_cadre_code 		"Cadre"
la var cadre_code			"Cadre Code"
la var hw07_daysworked_10 	"Oct: Days worked"
la var hw07_daysworked_11 	"Nov: Days worked"
la var hw07_daysworked_12	"Dec: Days worked"

order id_phcu id_phcu_name id_hw
	
	qui export excel using "$VIEW/staff/staffdata_2013q4", ///
		firstrow(varlabels) sheetreplace  sheet("`phcu'") 	

	restore
}


export excel using "$VIEW/hr/staffdata_`period'", replace firstrow(varlabels)   


