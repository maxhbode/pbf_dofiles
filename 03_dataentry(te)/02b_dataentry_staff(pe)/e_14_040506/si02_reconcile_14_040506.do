

loc yy 14	 
loc period "`yy'_040506"

if "`period'"=="`yy'_010203" loc quarter 1
else if "`period'"=="`yy'_040506" loc quarter 2
else if "`period'"=="`yy'_070809" loc quarter 3
else if "`period'"=="`yy'_101112" loc quarter 4

***************************************************************************
* Insheet + Append
***************************************************************************

* Extract Facility Names for insheeting of excel sheets
u "$CLEAN/a05(label)", clear
keep if treatment==1


levelsof id_phcu, loc(id_phcu)
di `"`id_phcu'"'


* Looping over 1st and 2nd entry
forval v = 1/2 {	

	* Import all sheets 
	*---------------------------------------
	loc i = 0
	foreach phcu in `id_phcu' {
	di as result "Imported PHCU=`phcu' from entry `v'"
		
		*qui {
		* Dropmiss observations with no data
		
		* Import file 
		loc phcu = `"`phcu'"'		
		import excel using "$ENTRY/`period'_staff/staffdata_`period'_entry`v'.xls", ///
			firstrow  sheet(`"`phcu'"') clear
				
		* Drop emptry rows		
		dropmiss *, obs force
				
		* Creat ID variable
		g id_phcu=.
		replace id_phcu=`phcu'
		
		* Rename ID
		ren StaffID id_hw
		
		* Time worker was added to facility 
		g new_staff_time_yy = 13
		replace new_staff_time_yy = `yy' if id_hw<1000
		g new_staff_time_q = 0
		replace new_staff_time_q = `quarter' if id_hw<1000
		ta  new_staff_time_yy new_staff_time_q
	
		* Newbie worker ID
		g new_staff = 0
		replace new_staff = 1 if id_hw<1000	
		la val new_staff yesnol
		
		g id_hw_short=id_hw-100 if new_staff==1

		replace id_hw_short=id_hw-(id_phcu*100) if id_hw>1000
		ta id_hw_short
		
		loc tostring id_phcu new_staff_time_yy new_staff_time_q id_hw_short
		foreach var in `tostring' {
			tostring `var', g(`var'_s)
		}
		
		order id_phcu new_staff_time_yy new_staff_time_q id_hw_short
		*g id_hw_new = id_phcu*100000+new_staff_time_yy*1000+new_staff_time_q*100+id_hw_short

		

		
		g id_hw_new_s = id_phcu_s+"_"+new_staff_time_yy_s+"_"+new_staff_time_q_s+"_"+id_hw_short_s
		replace id_hw_new_s = id_phcu_s+"_"+new_staff_time_yy_s+"_"+new_staff_time_q_s+"_0"+id_hw_short_s if id_hw_short<10
		
		g id_hw_new = id_phcu_s+new_staff_time_yy_s+new_staff_time_q_s+id_hw_short_s
		replace id_hw_new = id_phcu_s+new_staff_time_yy_s+new_staff_time_q_s+"0"+id_hw_short_s if id_hw_short<10
		destring id_hw_new, replace
		format %20.0f id_hw_new
	
		order id_hw_new* 
		ta id_hw_new

		drop id_phcu_s	 id_hw_short_s 			
		
		* Save
		loc ++i
		tempfile temp`i'
		sa `temp`i'', replace
		}
	
		
	* Appending among different sheets (facilities)
	*---------------------------------------
	u `temp1', clear
	forval file = 2/`i' {
		append using `temp`file'', force
	}

	* Rename
	ren I cadre_name		
	
	* Fix Bank account number
	replace BankAccountnumber = subinstr(BankAccountnumber,"~","",1)	
	
	* Getting ride of emptry rows
	duptest id_hw, noassert
	cap: list id_phcu Name1 Name2 Name3 if dup_id_hw!=0 & Name1==""
	cap: drop if dup_id_hw!=0 & Name1=="" & Name2=="" & Name3==""
	cap: drop dup_id_hw
	
	 list if id_hw==.
	 drop if id_hw==.

 	* Trim string
 	fn *, type(string)
 	foreach var in `r(varlist)' {
 		replace `var'=trim(itrim(`var'))
 	}
 
 	* Drop comment for now
	findname *comment* *reason* cadre_name
 	drop `r(varlist)'

	* Save
	compress
	order id_phcu id_hw
	tempfile staffdata_`period'_entry`v'
	sa `staffdata_`period'_entry`v'', replace
	
	
}


***************************************************************************
* Reconcile
***************************************************************************

loc date $D

u `staffdata_`period'_entry1', clear
cfout using `staffdata_`period'_entry2', id(id_hw_new_s) ///
	name("$ENTRY/`period'_staff/`date'_report_reconcile") replace

	
***************************************************************************
* Reconcile
***************************************************************************

u `staffdata_`period'_entry1', clear /// assuming this is ok. 


compress
sa "$TEMP/staffdata_`period'", replace




