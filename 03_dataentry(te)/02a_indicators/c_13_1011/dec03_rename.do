loc period 1112

*******************************************************************************
* Rename
*******************************************************************************

u "$TEMP/de02_2013_`period'(reconciled)", clear
drop dtag

* General
*--------------------------------
findname *
foreach var in `r(varlist)' {
	loc varnew = lower("`var'")
	ren `var' `varnew'
}

* Genearl, more specific
*--------------------------------
ren *comment *_comment

* Change in access / !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*--------------------------------
ren a07bpartographs a07bpartographsavailable
ren a06aapisrequired a06aapirequired

* Section V
*--------------------------------
ren v*healthfacility* v*_phcu_*
ren v*date* v*_date*
ren v*eid* v*_eid*
ren v*aid* v*_aid*
ren v*month v*_m
ren v*year v*_y
ren v*name v*_name
ren v*verification* v*_verification*
ren v*aflliation* v*affiliation* // change mispelling in access

forval i = 6/7 {
	ren v0`i'ii* 	v0`i'_ii_*
	ren v0`i'i* 	v0`i'_i_*
	
	foreach l in a b c d e f {
		ren v0`i'_*i_`l'* v0`i'_*i_`l'_*
	}
}
ren *otherenumerator_name *enumerator_name_other
ren *otheraffiliation_name *affiliation_name_other

ren v03facilityrepresentativesid v03_phcu_responder

* Section A
*--------------------------------
forval i = 1/7 {
	ren a0`i'a* a0`i'_b_*
	ren a0`i'b* a0`i'_b_*
	ren a0`i'c* a0`i'_c*
}
ren a*required a*_required
ren a*available a*_available

* Section B
*--------------------------------
forval i = 1/6 {
	if `i'<10 loc zero 0
	else loc zero
	
	ren b`zero'`i'* b`zero'`i'_*
}

* Section C
*--------------------------------
forval i = 1/13 {
	if `i'<10 loc zero 0
	else loc zero
	
	ren c`zero'`i'* c`zero'`i'_*
}

* Section B/C 
*--------------------------------

* Section Skips
ren s01sectionbskip b00_section_skip
ren s02sectioncskip c00_section_skip

* Comments
ren commentsinsectionb c07_section_comments
ren commentsinsectionc c13_section_comments

* Section D
*--------------------------------
forval i = 1/26 {
	if `i'<10 loc zero 0
	else loc zero
	
	ren d`zero'`i'* d`zero'`i'_*
}

foreach string in daysworked reason code mistake correction {
	ren d*`string'* d*_`string'*
}


* Section F
*--------------------------------
forval i = 1/6 {
	ren f0`i'* f0`i'_*
}

ren f01_eidofenumerator f01_eid
ren f02_signature		f02_esignature 
ren f03_date			f03_edate
ren f04_idofincharge	f04_sid
ren f05_signature 		f05_ssignature
ren f06_date			f06_sdate

* General
*--------------------------------
ren *nvall *_nv_t
ren *nvsample *_nv_s
ren *nvguidlines *_nv_g
ren *vall *_v_t
ren *vsample *_v_s
ren *vguidlines *_v_g

ren *other* *_other*
ren *__* *_*

* Remove surveying orientation -letters- 
foreach section in b c {
	cap: ren `section'*a_v* 	`section'*v*
	cap: ren `section'*b_v* 	`section'*v*
	cap: ren `section'*c_v* 	`section'*v*
	cap: ren `section'*c_nv* 	`section'*nv*
	cap: ren `section'*d_nv* 	`section'*nv*
	cap: ren `section'*e_nv* 	`section'*nv*
	cap: ren `section'*f_nv* 	`section'*nv*
}	

*******************************************************************************
* Last minute changes
*******************************************************************************

* Drop vars
drop id_period_mm_s id_period_yy id_period_yy_s id_period_ym

* Last minutes value correction: (via call from subira, read from form)
replace b01_nv_g=3 if id_phcu==2612 & id_period_mm==12
replace b01_nv_t=3 if id_phcu==2612 & id_period_mm==12

*******************************************************************************
* Save
*******************************************************************************

order id* a* b* c* d* f* v*
compress
sa "$TEMP/de03_1112(renamed)", replace


