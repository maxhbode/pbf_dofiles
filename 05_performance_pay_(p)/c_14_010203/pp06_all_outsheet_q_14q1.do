/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Jun 4 2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set linesize 225

* Period name
loc period 14_010203

************************************************************************
* Prepare
************************************************************************

* OPEN STAFF DATA
u "$CLEAN/performance pay/`period'/pp04a_foroutsheeting(dif_q)", clear
fn id_zone  hw*, remove(pp_v_bonus_tzs_14_010203_mia5)
drop `r(varlist)'

replace id_hw = id_hw -  id_phcu*100 
*ren pp_v_bonus_tzs_14_010203_mia5_r1k pp_v_bonus_tzs_14_010203_mia5
reshape wide pp_v_bonus_tzs_14_010203_mia5, i(id_phcu) j(id_hw)

fn pp_v_bonus_tzs_14_010203_mia5*, loc(varlist)
egen pp_v_bonus_tzs_14_010203_mia5 = rowtotal(`varlist')
drop `varlist' 

* OPEN PERFORMANCE IMPROVEMENT FUND DATA 
merge 1:1 id_phcu using "$CLEAN/performance pay/`period'/pp05a_(pif_q)", nogen
drop id_phcu_name id_zone

* Drop wrong old data
drop pp_v_pif_total_tzs 
drop pp_v_pif_13_070809_tzs 

/* Sum
drop pp_v_phcu_q_tzs_r1k
egen pp_v_phcu_q_tzs_r1k = rowtotal(pp_v_dif_total_q_tzs_r1k pp_v_pif_total_q_tzs_r1k)
*/

order id_phcu

************************************************************************
* Merge with old data 
************************************************************************

* Prep data
preserve
u "$CLEAN/pp05_13q3(pay_q)", clear
drop id_phcu_name id_phcu_s *_usd *phcu_total* *_df_total_* pp_total_q1_tzs
ren pp_pif_total_tzs pp_v_pif_13_070809_tzs
fn pp* 
foreach var in `r(varlist)' {
	replace `var'= round(`var',500)
}
sa "$TEMP/pp05_13q3(pp04b_13q4)", replace
restore

* Merge
merge 1:1 id_phcu using "$TEMP/pp05_13q3(pp04b_13q4)", nogen
ren pp_v_bonus_tzs_14_010203_mia5 pp_v_bonus_14_010203_tzs

order *, alpha
order id*

* Summing up Different PIF Figures
egen pp_v_pif_total = rowtotal(pp_v_pif_13_070809 pp_v_pif_13_101112 pp_v_pif_14_010203)

/*
foreach t in 13q4 13q3 13s2 {
	loc tt = upper("`t'")
	loc tt : subinstr loc tt "13" "2013 "

	la var pp_v_dif_total_q_tzs_r1k_`t'		"Discretionary PP, `tt'"
	la var pp_v_pif_total_q_tzs_r1k_`t'		"PHCU Account PP, `tt'"
	la var pp_v_phcu_q_tzs_r1k_`t' 			"Total PHCU PP, `tt'"
}
*/

************************************************************************
* Outsheet 
************************************************************************

export excel using "$VIEW/performance pay/`period'/pp_byfacility_piftotal", cell(A3) sheetmodify 
* firstrow(varlabels)

drop pp_v_pif_13_070809_tzs pp_v_pif_13_101112_tzs pp_v_pif_total

export excel using "$VIEW/performance pay/`period'/pp_byfacility", replace firstrow(varlabels)
