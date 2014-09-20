
local PV "performance verification"

u "$CLEAN/tc_05(label)", clear

*******************************************************************************
* Prepare Outsheet
*******************************************************************************

* Turn to string (so formatting stays in final document)
tostring id_period_yyyy, replace

* Drop variables
fn id* time_cat, remove(id_phcu id_period_yyyy id_period_mm  id_district id_phcu_name)
drop `r(varlist)'
*drop *problem


* Round variables
fn *, type(numeric) remove(id* *skip)
foreach var in `r(varlist)' {
	replace `var' = round(`var',.01)
}

* Tostring
g id_period_mm2= id_period_mm
drop id_period_mm
tostring id_period_mm2, g(id_period_mm)
drop id_period_mm2
order id_period_mm, after(id_phcu)
tostring id_phcu, replace

* Sort
destring id_period_yyyy, replace
destring id_period_mm, replace

sort id_phcu id_period_yyyy id_period_mm	

* Order
order *, alpha
order id_phcu_name id_phcu id_period_yyyy id_period_mm  id_district treatment* *section_skip

* Save 
tempfile temp
sa `temp', replace

*******************************************************************************
* Outsheet
*******************************************************************************

* Get date date
loc date "$D"
loc date : subinstr loc date " " "", all
di "`date'"

* Outsheet variable list with names
outvarlist *, filename("$VIEW/`PV'/`date'_retrospective") excel report(name varlabel)

* Outsheet variable list with names
preserve
	drop *pct
	outvarlist *, filename("$VIEW/`PV'/`date'_retrospective_raw") excel report(name varlabel)
restore

* Outsheet data 
foreach section in b c  {
	preserve
	
	* Take 1 section at a time
	u `temp', clear
	keep id* treat* `section'*
	loc section = upper("`section'")
	tempfile temp`section'
	sa `temp`section'', replace
	
	*----
	
	u `temp`section'', clear
	* Outsheet labels
	export excel using "$VIEW/`PV'/`date'_retrospective",  firstrow(varlabels) sheetmodify cell(A1) sheet("section`section'")	
	* Outsheet data (and overwrite everything put labels from above)
	export excel using "$VIEW/`PV'/`date'_retrospective",  firstrow(variables) sheetmodify cell(A2) sheet("section`section'")
	
	*----
	
	u `temp`section'', clear
	fn *_pct
	drop `r(varlist)'
	
	* Outsheet labels
	export excel using "$VIEW/`PV'/`date'_retrospective_raw",  firstrow(varlabels) sheetmodify cell(A1) sheet("section`section'")	
	* Outsheet data (and overwrite everything put labels from above)
	export excel using "$VIEW/`PV'/`date'_retrospective_raw",  firstrow(variables) sheetmodify cell(A2) sheet("section`section'")

	*----	

	u `temp`section'', clear
	fn *_v_* *_nv_*
	drop `r(varlist)'

	* Outsheet labels
	export excel using "$VIEW/`PV'/`date'_retrospective_total",  firstrow(varlabels) sheetmodify cell(A1) sheet("section`section'")	
	* Outsheet data (and overwrite everything put labels from above)
	export excel using "$VIEW/`PV'/`date'_retrospective_total",  firstrow(variables) sheetmodify cell(A2) sheet("section`section'")

	*----
	
	u `temp`section'', clear
	fn *_pct
	drop `r(varlist)'
	fn id* *_v*
	keep `r(varlist)'

	* Outsheet labels
	export excel using "$VIEW/`PV'/`date'_retrospective_verifiable",  firstrow(varlabels) sheetmodify cell(A1) sheet("section`section'")	
	* Outsheet data (and overwrite everything put labels from above)
	export excel using "$VIEW/`PV'/`date'_retrospective_verifiable",  firstrow(variables) sheetmodify cell(A2) sheet("section`section'")
		
	
	restore
}

