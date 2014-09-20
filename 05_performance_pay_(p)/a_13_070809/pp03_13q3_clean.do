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
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set more off
set linesize 100

u "$CLEAN/de02(clean)", clear

* load value labels
include  "$DO/01b_all_value_labels"

************************************************************************
* Fixes that should be done earlier
************************************************************************

* (1) 
drop id_phcu_s // corrupted !!!

* (2) Fixing Fuoni


sort id_phcu


************************************************************************
* Create locals
************************************************************************

fn *_t, remove(*_nv_* *_v_*)
foreach var in `r(varlist)' {
	loc names = substr("`var'",1,3)
	di "`names'"
	loc indicatornames `indicatornames' `names'
}

di "`indicatornames'"

************************************************************************
* Select observations for PP calculations
************************************************************************

keep if inlist(id_period_mm,10,11,12)
cb id_period_mm

************************************************************************
* Select variables for PP calculations
************************************************************************

fn *_v_t, remove(*_nv_*) loc(total)
fn *_v_g, remove(*_nv_*) loc(quality)

keep id* `total' `quality'

************************************************************************
* Check for missing values
************************************************************************

foreach var in `total' `quality' {
	cb `var'
}


************************************************************************
* (0x) Save
************************************************************************

preserve
*keep id*  v04a_period_m
*d*
order *, alpha
order id*
keep if id_period_mm==9
drop id_phcu_ym id_zone id_zone_name v04a_period_m id_phcu id_district id_district_name
*export excel "$DESKTOP/staff_sep_4mary.xlsx", replace
sa "$TEMP/staff_data_sep", replace
restore

drop d*

qui compress
sa "$TEMP/pp03_clean", replace

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* Basis of the ID:
Categories are sorted alphabetically:
ID = Island ID [1,2] + District ID [1,6] by Island + PHUC ID by District




************************************************************************
* (01) Dates
************************************************************************

bys period_m: su pm01or_opd_newconsul_N pm01ov_opd_newconsul_N
bys period_m: su pm01gr_opd_newconsul_N pm01gv_opd_newconsul_N

bys period_m: su pm01or_opd_newconsul_N pm01gr_opd_newconsul_N

* training (verified)
bys period_m: su pm01ov_opd_newconsul_N pm01gv_opd_newconsul_N

*g test2 = pm01or_opd_newconsul_N/pm01ov_opd_newconsul_N

g testo =pm01gv_opd_newconsul_N/pm01ov_opd_newconsul_N



/*
* ---------- phone numbers  -------------*
* overview, verified (number of phone numbers improved). 
* 150 cases in Aug, 105 cases in July --> 30% improvment
ttest pm01ov_opd_newconsul_N, by(period_m) level(90)
*-ttest test2, by(period_m) level(90)

* ---------- verification -------------*
ttest testo, by(period_m) level(90)
* 31% of the cases with phone numbers followed the guidlines in July 
* 40% of the cases with phone numbers followed the guidlines in August
* That's a 22.5 % increase (almost 25 %) 
by period_m: list id_district id_phcu_name  testo, noobs

su testo


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
