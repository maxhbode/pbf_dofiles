
******************************************************************************
* Limit to one period
******************************************************************************

u "$CLEAN/a04(label)", clear
cb id_period_ym

* Keep outcome variables of interest
keep id_phcu id_period_ym b00_g_pct

* Reshape for Pre-Post substraction
keep if inlist(id_period_ym,1306,1403)
reshape wide b00_g_pct, i(id_phcu) j(id_period_ym)

g b00_d_ppt = b00_g_pct1403-b00_g_pct1306
g b00_d_pct = (b00_g_pct1403-b00_g_pct1306)/b00_g_pct1306
drop b00_g_pct1403 b00_g_pct1306

* Drop facilities for which we have no baseline
drop if b00_d_pct==.

* Label
la var b00_d_ppt "OPD Quality growth" 
la var b00_d_pct "OPD Quality growth" 

* Save
compress
tempfile pbfdata
sa `pbfdata', replace

******************************************************************************
* Merge in PBF data
******************************************************************************
*drop treatment

u "$CLEAN/$COMPARISON/c_02b(psm)", clear
drop id_period_*

merge 1:m id_phcu using `pbfdata'

ta _merge if treatment_all==1
list id_phcu id_phcu_name if _merge==2
drop if id_phcu==1312
drop if _merge==1

******************************************************************************
* Setting variables
******************************************************************************

* Set macros
*-----------------------------------------------------

* Set locals

/* Set exact matching
loc exactmatch_var hr_phcu_plus
recode hr_phcu_plus (0=2)
ta hr_phcu_plus  
*/
* Set Independent Variables 

* hr_phcu_plus
#delimit ;
loc basic
	phcu_catchmentpop id_zone 
;	
loc hmis
	hmis_opd_headcount_new_3m_bp
	hmis_sopd_hypertension_new_3m


	hmis_anc_visit_41_r_6m mv_hmis_anc_visit_41_r_6m
	hmis_fp_headcount_3m_bp  hmis_fp_implantinsertion_3m_bp 	
;	
loc hrlist
	hr_staff_n_bp 
	hr_age_201306_avg    
;

loc leftover
	hmis_sopd_hypertension_new_3m_bp

	hmis_pnc_48hrs_3m  	
	hmis_anc1stvisit_b16w_3m_r 
 	hmis_sopd_epilepsy_new_3m  
	hmis_fp_headcount_3m 
	hmis_fp_implantinsertion_3m 
 	hmis_sopd_diabetis_new_3m 
 	hmis_sopd_sti_new_3m
 	
 	hr_staff_male_r
 	hr_staff_n
 	
	hmis_del_facilitydelivery_3m_bp  
;

# delimit cr
/*
 Little impact: 	hmis_penta_dose_ratio_6m 
  mv_hmis_pnc_48hrs_3m
   mv_hmis_anc1stvisit_b16w_3m_r

*/

* Set final selection
loc xlistpsm1 `basic'
loc xlistpsm2 `basic' `hmis'
loc xlistpsm3 `basic' `hrlist'
loc xlistpsm4 `basic' `hmis' `hrlist'
fn `xlistpsm4' `leftover', loc(xlistpsm_all) remove(mv_*)

global xlistpsm `xlistpsm4' 


set linesize 100
fn mv*, loc(missing) remove(mv_hmis_anc1stvisit_b16w_3m_r mv_hmis_pnc_48hrs_3m) 

******************************************************************************
* Regression 
******************************************************************************

loc outcome b00_d_ppt
*b00_g_pct b00_d_pct

eststo clear

foreach xlist in 2 3 4  {
	di "`treatment' - `xlistpsm`xlist''"
	eststo: reg `outcome' `xlistpsm`xlist''
}

*ereturn list
#delimit ;
esttab using "$OUTPUTS/$COMPARISON/table_outcome.tex", replace
	booktabs  longtable label
	cells(	"b(star)" "se(par)")
	stats(N F r2 r2_a, labels("N" "F" "R2" "Adjusted R2")) 
	title("Matching variables on Outcome within Treated")
	drop(`missing' _cons)
	star( * 0.1 ** 0.05 *** 0.01)
	substitute(
	"&\multicolumn{1}{c}{OPD Quality growth}&\multicolumn{1}{c}{OPD Quality growth}&\multicolumn{1}{c}{OPD Quality growth}\\"
	"&\multicolumn{3}{c}{PPT change in OPD Consultation, according to guidlines (\%)} \\"
	"&        b/se         &        b/se         &        b/se         \\"
	""
	)
;
#delimit cr

*! IT'S BECAUSE THE STATA IS MISSING THAT I'M LOSING OBS
*drop _*


stop

