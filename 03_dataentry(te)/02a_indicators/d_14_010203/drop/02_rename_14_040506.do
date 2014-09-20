
loc yy 14
loc mm1 04 
loc mm2 05
loc mm3 06
loc period `yy'_`mm1'`mm2'`mm3'

*******************************************************************************
* Rename
*******************************************************************************

u "$CLEAN/de02_`period'(reconciled)", clear

* General
*--------------------------------
findname *
foreach var in `r(varlist)' {
	loc varnew = lower("`var'")
	ren `var' `varnew'
}

* Section B & C
*--------------------------------
ren *nv* *_nv*
ren *v* *_v*
ren *_n_v* *_nv*

* General, more specific
*--------------------------------
ren *_r *_required
ren *_a *_available
ren *_c *_comment

* Section Skips
ren s01 b00_section_skip
ren s02 c00_section_skip

* Comments
ren b09_comment b09_sectionb_comment
ren c12_comment c12_sectionc_comment

* General
*--------------------------------
ren *__* *_*

*******************************************************************************
* Last minute changes
*******************************************************************************

* Drop vars
drop id_period_mm_s id_period_yy id_period_yy_s id_period_ym

*******************************************************************************
* Save
*******************************************************************************

order id* v* a* b* c* dm*
compress
sa "$TEMP/de03_`period'(renamed)", replace


