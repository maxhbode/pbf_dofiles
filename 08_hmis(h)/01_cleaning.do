
*************************************************************************
* Import and temporary save
*************************************************************************

foreach sheet in delivery special_opd ANC PNC OPD FP Penta MVA  {

	import excel using "$RAW/hmis/phcu_bydistrict.xls", sheet(`sheet') firstrow clear
	tempfile `sheet'

	* Drop vars that have only missing values
	*------------------------------------------------------
	dropmiss, force	
	
	* Time ID
	*------------------------------------------------------
	split Period
	ren Period id_period_s
	ren Period1 id_period_mm_s
	ren Period2 id_period_yyyy_s
	
	// creturn list
	
	loc months `c(Months)'
	di "`months'"
	/*
	forval mm = 1/12 {
		di `mm'
	}
	*/
	
	g id_period_mm=.
	replace id_period_mm=1 if id_period_mm_s=="January"
	replace id_period_mm=2 if id_period_mm_s=="February" 
	replace id_period_mm=3 if id_period_mm_s=="March"
	replace id_period_mm=4 if id_period_mm_s=="April"
	replace id_period_mm=5 if id_period_mm_s=="May"
	replace id_period_mm=6 if id_period_mm_s=="June"
	replace id_period_mm=7 if id_period_mm_s=="July"
	replace id_period_mm=8 if id_period_mm_s=="August"
	replace id_period_mm=9 if id_period_mm_s=="September"
	replace id_period_mm=10 if id_period_mm_s=="October"
	replace id_period_mm=11 if id_period_mm_s=="November"
	replace id_period_mm=12 if id_period_mm_s=="December"
	ta id_period_mm, mi
	drop id_period_mm_s
	tostring id_period_mm, gen(id_period_mm_s)
	
	g id_period_ym = id_period_yyyy_s + id_period_mm_s
	replace id_period_ym = id_period_yyyy_s + "0" + id_period_mm_s if id_period_mm<10
	destring id_period_yyyy_s, gen(id_period_yyyy)
	
	order id_period*
	drop id_period_yyyy_s
	
	* Merge with PCHU info data (incl. ID)
	*------------------------------------------------------
	ren Organisationunit id_phcu_name
	replace id_phcu_name = subinstr(id_phcu_name," PCHU","",1)
	replace id_phcu_name = subinstr(id_phcu_name," PHCU+","",1)
	replace id_phcu_name = subinstr(id_phcu_name," PHCU","",1)
	replace id_phcu_name = itrim(trim(id_phcu_name))
	replace id_phcu_name = "Bogoa" if id_phcu_name=="Bogowa"
	replace id_phcu_name = "Bwefum" if id_phcu_name=="Bwefumu"
	
	merge m:1 id_phcu_name using "$CLEAN/phcu_information"
	ta id_phcu_name if _merge==1
	drop if _merge==1 // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	ta _merge
	drop _merge 
	
	order *, alpha
	order id*
	order id_phcu* id_period*
	
	* Generate Unique ID: PHCU-Time 
	*------------------------------------------------------	
	tostring id_phcu, gen(id_phcu_s)
	g id_phcu_ym = id_phcu_s + id_period_ym
	destring id_phcu_ym, replace
	format %10.0f id_phcu_ym 
	duptest id_phcu_ym
	drop id_*_s
	order id_phcu_ym 
		
	g id_period_yymm = substr(id_period_ym,2,.)
	destring id_period_yymm, replace
	destring id_period_ym, replace
	
	sa `sheet', replace
	
	
}

u special_opd, clear
foreach sheet in ANC PNC OPD FP Penta MVA delivery {
	merge 1:1 id_phcu_ym using `sheet', nogen
}

*************************************************************************
* Name and Label
*************************************************************************

fn *, remove(id*)
foreach var in `r(varlist)' {
	loc newvar = lower("`var'")
	ren `var' `newvar'
}


ren totalheadcounts_new 	opd_headcount_new

ren totalheadcount_stiatte	sopd_sti_new
ren hypertension_new		sopd_hypertension_new
ren epilepsy_new 			sopd_epilepsy_new
ren diabetis_new			sopd_diabetis_new

ren headcount_fp_25yrs 		fp_headcount_25yrs 
ren headcount_fp_1524yrs 	fp_headcount_1524yrs
ren implanoninsertion		fp_implantinsertion

ren postnatal* 				pnc_*
ren anc*					anc_*
ren anc_4visit anc_visit4

ren penta*dose penta*
ren penta* penta_dose*

ren manualvacuumaspiration mva

ren deliveriesinward_totalnumbe del_facilitydelivery_total
ren deliverymother20years 		del_facilitydelivery_u20	
ren deliverymother35years		del_facilitydelivery_o35	

*************************************************************************
* Clean values
*************************************************************************

fn *, remove(id*)
foreach var in `r(varlist)' {
	destring `var', replace
}

su del_facilitydelivery_total

*************************************************************************
* Manipulation: New variables
*************************************************************************

g anc_visit1 = anc_1stvisitafter16w + anc_1stvisitbefore16w

*************************************************************************
* Treatment/Control
*************************************************************************

* PHCUs 
g treatment=0
replace treatment=1 if inlist(id_district,13,27)

* Time 
g prepost = 0
replace prepost = 1 if id_period_ym>201306

*************************************************************************
* Save
*************************************************************************
	
sort id_phcu_ym
order *, alpha
order id_phcu* id_period* id* treatment prepost opd* sopd* mva anc* pnc* fp* penta*

sa "$CLEAN/hmis/clean", replace

