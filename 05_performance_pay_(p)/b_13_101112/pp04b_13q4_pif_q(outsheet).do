/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Feb 2014
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


set linesize 225

************************************************************************
* 
************************************************************************

u "$TEMP/pp05bii", clear
fn id_hw hw*, remove(hw_r_bonus_tzs_13q4_round1k)
drop `r(varlist)'

bys id_phcu: egen pp_v_dif_total_q_tzs_round = total(hw_r_bonus_tzs_13q4_round1k)
bys id_phcu: g n = _n
keep if n==1
drop n hw_r_bonus_tzs_13q4_round1k

* Merge
merge 1:1 id_phcu using "$TEMP/pp04a_13q4(pif_q)", nogen

* Round
foreach var in pp_v_dif_total_q_tzs pp_v_phcu_q_tzs pp_v_pif_total_q_tzs {
	g `var'_r1k = round(`var',1000)
	drop `var'
}

compare pp_v_dif_total_q_tzs_round pp_v_dif_total_q_tzs_r1k
drop pp_v_dif_total_q_tzs_r1k
ren pp_v_dif_total_q_tzs_round pp_v_dif_total_q_tzs_r1k

* Sum
drop pp_v_phcu_q_tzs_r1k
egen pp_v_phcu_q_tzs_r1k = rowtotal(pp_v_dif_total_q_tzs_r1k pp_v_pif_total_q_tzs_r1k)

* Label vars

ren pp* pp*_13q4


************************************************************************
* Merge with old data 
************************************************************************

* Prep data
preserve
u "$CLEAN/pp05_13q3(pay_q)", clear
drop id_phcu_name id_phcu_s *_usd pp_phcu_total_q1_tzs
ren pp_total_q1_tzs pp_v_phcu_q_tzs_r1k_13q3
ren pp_pif_total_tzs pp_v_pif_total_q_tzs_r1k_13q3
ren pp_df_total_tzs pp_v_dif_total_q_tzs_r1k_13q3
fn pp* 
foreach var in `r(varlist)' {
	replace `var'= round(`var',1000)
}
sa "$TEMP/pp05_13q3(pp04b_13q4)", replace
restore

* Merge
merge 1:1 id_phcu using "$TEMP/pp05_13q3(pp04b_13q4)", nogen
foreach var in pp_v_dif_total_q_tzs_r1k pp_v_pif_total_q_tzs_r1k pp_v_phcu_q_tzs_r1k {
	egen `var'_13s2 = rowtotal(`var'_13q4 `var'_13q3)
}

foreach t in 13q4 13q3 13s2 {
	loc tt = upper("`t'")
	loc tt : subinstr loc tt "13" "2013 "

	la var pp_v_dif_total_q_tzs_r1k_`t'		"Discretionary PP, `tt'"
	la var pp_v_pif_total_q_tzs_r1k_`t'		"PHCU Account PP, `tt'"
	la var pp_v_phcu_q_tzs_r1k_`t' 			"Total PHCU PP, `tt'"
}

************************************************************************
* Outsheet 
************************************************************************

export excel using "$VIEW/performance pay/2013s1_pp_byfacility", replace firstrow(varlabels)

drop pp_v_phcu_q_tzs_r1k_13q3 pp_v_dif_total_q_tzs_r1k_13q3 pp_v_dif_total_q_tzs_r1k_13s2 pp_v_phcu_q_tzs_r1k_13s2
order pp_v_phcu_q_tzs_r1k_13q4 pp_v_dif_total_q_tzs_r1k_13q4 pp_v_pif_total_q_tzs_r1k_13s2 pp_v_pif_total_q_tzs_r1k_13q4 pp_v_pif_total_q_tzs_r1k_13q3, after(id_phcu_name)
export excel using "$VIEW/performance pay/2013q4_pp_byfacility", replace firstrow(varlabels)
