u "$TEMP/s_phcu03_clean", clear

************************************************************************
* Quick analysis
************************************************************************

keep id_phcu v04a_verification_period_m a01* id_zone id_phcu_name id_zone_name

*br id_zone_name id_phcu_name v04a_verification_period_m  id_zone_name a01*

keep id_phcu v04a_verification_period_m a01* id_zone id_phcu_name
sort id_phcu v04a_verification_period_m

g a01_ratio = a01ov_opd_newconsul_N/a01gv_opd_newconsul_N

* ALL PHCUs
*-----------------------------------

* Number of OPD verified cases, ALL PHCUs
bys v04a_verification_period_m: su a01ov_opd_newconsul_N

* Number of cases according to guidlines, ALL PHCUs
bys v04a_verification_period_m: su a01gv_opd_newconsul_N

* Ratio, ALL PHCUs
bys v04a_verification_period_m: su a01_ratio

* BALANCED DATA PHCUs
*-----------------------------------
preserve 

bys id_phcu: g n = _n if a01gv_opd_newconsul_N>=. 
bys id_phcu: egen n_a01gv = max(n)
drop n

bys id_phcu: g n = _n if a01ov_opd_newconsul_N>=. 
bys id_phcu: egen n_a01ov = max(n)
drop n

drop if n_a01gv!=. | n_a01ov!=. 

* Number of OPD verified cases, BALANCED DATA PHCUs
bys id_zone  v04a_verification_period_m: su a01ov_opd_newconsul_N

* Number of cases according to guidlines, BALANCED DATA PHCUs
bys id_zone  v04a_verification_period_m: su a01gv_opd_newconsul_N

restore

preserve
bys id_phcu: g n = _n if a01_ratio>=. 
bys id_phcu: egen n_a01ratio = max(n)
drop n

drop if n_a01ratio!=.

* Ratio, BALANCED DATA PHCUs
bys v04a_verification_period_m: su a01_ratio
restore




STOP
