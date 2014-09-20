
loc yy 13

*******************************************************************************
* Rename
*******************************************************************************

forval file = 1/2 {

	insheet using "$ENTRY/`yy'_10/data_entry_201310_entry`file'.csv", clear

	*-----------------------------------------------------
	* Replace values
	*-----------------------------------------------------

	if `file'==1 {
		replace b03avall=6 if v01healthfacilityname=="Kangani"
		replace xb01s06=61 if v01healthfacilityname=="Shidi"
		replace xb01g06=4  if v01healthfacilityname=="Shidi"
	}
	
	*-----------------------------------------------------
	* Rename
	*-----------------------------------------------------
	
	* General
	findname *
	foreach var in `r(varlist)' {
		loc varnew = lower("`var'")
		ren `var' `varnew'
	}
	
	
	* Change in access / !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	ren a07bpartographs a07bpartographsavailable
	ren a06aapisrequired a06aapirequired
	*ren xb0109 xb01t09
	
	* Genearl, more specific
	
	ren dataentryoperator* deo_*
	ren *comment *_comment
	
	ren *healthfacility* *_phcu_*
	ren *date* *_date*
	ren *eid* *_eid*
	ren *aid* *_aid*
	ren *month *_m
	ren *year *_y
	ren *name *_name
	ren *verification* *_verification*
	ren v07*enumerator_eid v06*_i_enumerator_eid
	ren v06*enumerator_name v06*_ii_enumerator_name
	ren v07ii*otheraffiliation* v07*_ii_otheraffiliation*
	ren v07i*aflliation* v07*_i_affiliation* // change mispelling in access
	
	ren a0*a*required a0*a_*_required
	

	
	ren a01stg 		a01b_stg_available
	ren a02malaria 	a02b_malaria_available
	ren a03imci		a03b_imci_available
	ren a04sti 		a04b_sti_available
	ren a05ipc 		a05b_ipc_available
	ren a06api		a06b_api_available
	ren a07bpartographsavailable a07b_partographs_available
	
	ren *nvall *_nv_t
	ren *nvsample *_nv_s
	ren *nvguidlines *_nv_g
	ren *vall *_v_t
	ren *vsample *_v_s
	ren *vguidlines *_v_g
	
	ren *t0* *_t0*
	ren *s0* *_s0*
	ren *g0* *_g0*
	
	
	ren *other* *_other*
	ren *signature *_signature
	ren *_id* *_id_*
	ren *id_ *id
	ren v02_phcu_id_* id_phcu_*
	

	* Genearl
	ren *__* *_*
	
	* Variable specific
	ren v03respondingphcurepresentati v03_phcu_responder
	ren a02amalaria_required a02a_malaria_required
	ren a06aa_pi_required 	a06a_api_required
	ren commentsinsectionb b07_comments_sectionb
	ren commentsinsectionc c14_comments_sectionc
	ren f01_eidofenumerator f01_eid
	ren f04idofincharge f04_sid
	
	ren f02_signature	f02_esignature 
	ren f03_date		f03_edate
	ren f05_signature 	f05_ssignature
	ren f06_date		f06_sdate

	
	* Rename
	
	ren xb01s_t09 xb01_s09
	ren xb01g_t09 xb01_g09
	
	ren xb02t_t09 xb02_t09
	ren xb02s_t09 xb02_s09
	ren xb02g_t09 xb02_g09
	ren xb06t_t09 xb06_t09
	ren xb06g_t09 xb06_g09
	
	
	*-----------------------------------------------------
	* ID
	*-----------------------------------------------------
	
	ren v01_phcu_name id_phcu_name
	
	g id_phcu = (id_phcu_zone*10 + id_phcu_district)*100 + id_phcu_facility
	foreach var in id_phcu_zone id_phcu_district id_phcu_facility {
		tostring `var', g(temp_`var')
	}
	g id_phcu_s = temp_id_phcu_zone + "-" + temp_id_phcu_district + "-" + temp_id_phcu_facility
	replace id_phcu_s = temp_id_phcu_zone + "-" + temp_id_phcu_district + "-0" + temp_id_phcu_facility if id_phcu_facility<10
	cb id_phcu
	
	drop temp*
	
	ren id_phcu_zone 		id_zone
	ren id_phcu_district 	id_district
	ren id_phcu_facility	id_facility

	*-----------------------------------------------------
	* Correct values 
	*-----------------------------------------------------

	fn b* c*, remove(*comment*)
	foreach var in `r(varlist)' {
		replace `var'=0 if `var'==-999
	}
	
	fn v*, type(string)
	foreach var in `r(varlist)' {
		replace `var'="-999" if `var'=="-995"
	}
		
	fn v*, type(numeric)
	foreach var in `r(varlist)' {
		replace `var'=-999 if `var'==-995
	}		
	
	fn *required 
	foreach var in `r(varlist)' {
		replace `var'=-999 if `var'==-998 & id_phcu<2000
	}
	
	*-----------------------------------------------------
	* Correct all values in both entries
	*-----------------------------------------------------
	
	do "$DO/02_treatment(t)/02_dataentry(te)/b_13_10_q4/deb01b_valuecorrections.do"

	
	drop deo* 
	
	*-----------------------------------------------------
	* Save
	*-----------------------------------------------------
	
	cap: tostring c14_comments_sectionc, replace
	compress
	sa "$ENTRY/`yy'_10/data_entry_201310_entry`file'", replace
}

*******************************************************************************
* CFOUT
*******************************************************************************

u "$ENTRY/`yy'_10/data_entry_201310_entry1", clear
cfout a* b* c* x* using "$ENTRY/`yy'_10/data_entry_201310_entry2", id(id_phcu) replace ///
		name("$ENTRY/`yy'_10/data_entry_201310_report_nostring") nostring


u "$ENTRY/`yy'_10/data_entry_201310_entry1", clear
cfout * using "$ENTRY/`yy'_10/data_entry_201310_entry2", id(id_phcu) replace ///
		name("$ENTRY/`yy'_10/data_entry_201310_report_string") string

*******************************************************************************
* Save
*******************************************************************************

sort id_phcu
order *, alpha
order id_phcu id_phcu_s id*
order v* f*, last
compress

sa "$TEMP/01_cfout_rename", replace


