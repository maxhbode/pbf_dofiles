


***************************************************************************
* Insheet + Append
***************************************************************************

u "$CLEAN/a04(label)", clear
replace id_phcu_name="Chuini" if id_phcu_name=="Chuwini"
replace id_phcu_name="Muambe" if id_phcu_name=="Mwambe"
levelsof id_phcu_name, loc(id_phcu)
di `"`id_phcu'"'
clear

forval v = 1/2 {	
	loc i = 0
	foreach phcu in `id_phcu' {
		loc ++i
		loc phcu = `"`phcu'"'
		import excel using "$ENTRY/14_010203_staff/staffdata_14_010203_entry`v'", ///
			firstrow  sheet(`"`phcu'"') clear
		tempfile temp`i'
		cap: g id_phcu_name=""
		replace id_phcu_name="`phcu'"
		
		
		replace BankAccountnumber = subinstr(BankAccountnumber,"~","",1)

		
		*fn *, type(numeric)
		cap {
		fn *comment*
		foreach var in `r(varlist)' {
			tostring `var', replace
			replace `var'="" if `var'=="."
		}
		}
		cap: destring rc_1, replace
		
		cap: ren day_3 days_3
		cap: ren Comment comment
		
		sa `temp`i'', replace
	}
	
	u `temp1', clear
	forval file = 2/`i' {
		append using `temp`file''
	}
	
	replace id_phcu_name="Chuwini" if id_phcu_name=="Chuini"
	replace id_phcu_name="Mwambe" if id_phcu_name=="Muambe"
	
	* Getting ride of blindes
	duptest id_hw, noassert
	cap: drop if dup_id_hw!=0 & Name1==""
	cap: drop dup_id_hw 
 	
 	* Trim string
 	fn *, type(string)
 	foreach var in `r(varlist)' {
 		replace `var'=trim(itrim(`var'))
 	}
 	
 	* Drop comment for now
 	drop comment
 	
	compress
	order id_phcu id_hw
	
	tempfile staffdata_14_010203_entry`v'
	sa `staffdata_14_010203_entry`v'', replace
}

***************************************************************************
* Reconcile
***************************************************************************

u `staffdata_14_010203_entry1', clear
cfout using `staffdata_14_010203_entry2', id(id_hw) ///
	name("$ENTRY/14_010203_staff/report_reconcile") replace

***************************************************************************
* Reconcile
***************************************************************************

u `staffdata_14_010203_entry1', clear /// assuming this is ok. 


compress
sa "$TEMP/staffdata_14_010203", replace




