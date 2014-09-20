/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Sep 2013

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OVERVIEW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

(01) ...
	

m	or	overall - (self)reporteda	ov	overall - verified	gr	followed guidelines - (self)reported	gv	followed guidelines - verified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set more off
set linesize 100

u "$RAW/verification_201307_temp", clear
ren *_n *_N

sort id_phcu_ym
append using "$RAW/verification_201308"
order *, alpha
order id* ve* vi* pm*

/*
fn pm*or_*

forval i = 1/18 {
	loc zero 0
	if `i'>9 loc zero
	loc i = "`zero'`i'"
	
	qui fn pm`i'or*
	loc var = "`r(varlist)'"
	
	loc varnew : subinstr loc var  "pm`i'or_" ""
	di "`varnew'"

	qui g pm`i'gr_`varnew'=. 
	qui g pm`i'gv_`varnew'=. 

	loc varlabel = `"`: var label `var''"'
	la var pm`i'gr_`varnew' "`varlabel', followed guidelines - (self)reported"		
	la var pm`i'gv_`varnew' "`varlabel', followed guidelines - verified"

	la var pm`i'or_`varnew' "`varlabel', overall - (self)reported"	
	la var pm`i'ov_`varnew' "`varlabel', overall - verified"			
}

order pm*, alpha after(visit_teamleader_name)
*/
************************************************************************
* Merge 
************************************************************************

*É

*===========================================================
* (01.a) ...
*===========================================================

* ...
*---------------------------------------------------

************************************************************************
* (0x) Save
************************************************************************

qui compress
sa "$TEMP/s_phcu02_merge", replace

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* Basis of the ID:
Categories are sorted alphabetically:
ID = Island ID [1,2] + District ID [1,6] by Island + PHUC ID by District


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
