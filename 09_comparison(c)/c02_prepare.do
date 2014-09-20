clear
set more off
set linesize 225
*capture log close

******************************************************************************
* Author: 	Max Bode
* Date:		June 11, 2014
* Purpose:	Prepare data for control selection + balance checks
******************************************************************************

u "$GENERAL/phcu_info/phcu_info_clean", clear

******************************************************************************
* 1. Select Facilities
******************************************************************************

* Drop districtless Observations
list id_phcu_name id_district if id_district==.
drop if id_district==.

******************************************************************************
* 2. Set Treatment
******************************************************************************

* Drop West & Mkoani (treatment)
g treatment=0
replace treatment=1 if inlist(id_district,13,26)
ta id_district treatment

******************************************************************************
* 3. Merge with HMIS data
******************************************************************************

preserve
	u  "$CLEAN/hmis/clean", clear
	
	* Drop variables
	drop treatment prepost

	* Rename 
	ren * hmis_*
	ren hmis_id_* id_*

	* Drop observations
	cb id_period_ym
	drop if id_period_ym>201306
	
	tempfile hmis
	sa `hmis', replace
restore


merge 1:m id_phcu using `hmis', gen(merge_hmis) /// WHY IS MAKOBA AND SHARIMOYO NOT IN HMIS

ta id_phcu_name if merge_hmis==1
*drop if merge_hmis==1
ta id_district if merge_hmis==2 /// this is what we want!

* Drop non-comparison group, non-treatment facilities
foreach var in treatment {
	di as result "`var'"
	replace `var'=1 if inlist(id_district,13,26)
	la val `var' treatmentl
	ta id_district `var' , mi
}


******************************************************************************
* 4. fix string dummies
******************************************************************************

foreach var in phcu_24hours phcu_delivery phcu_plus {
	g hr_`var'=.
	replace hr_`var'=0 if hmis_`var'=="NO"
	replace hr_`var'=1 if hmis_`var'=="YES"
	la val hr_`var' yesnol
	drop hmis_`var'
}

******************************************************************************
* 5. Merge with HR data
******************************************************************************

merge m:m id_phcu using "$CLEAN/08_hr/hr_clean_forbalance", gen(merge_hr_2)
ta id_phcu_name if merge_hr_2==2


******************************************************************************
* 6. Select HMIS variables for balance checks
******************************************************************************

* WE SHOULD CONTROL FOR CATHCMENT AREA IN GENERAL IF THE TWO DIFFER - phcu_catchmentpop

* 6 MONTH TOTALS 
* -------------------------------------------------------------

* 6 MONTH TOTALS OF ANC4 / ANC1 
foreach var in hmis_anc_visit4 hmis_anc_visit1 {
	bys id_phcu: egen `var'_6m = total(`var')
}
ren hmis_anc_*_6m hmis_anc_6m_*
compare hmis_anc_6m_visit1  hmis_anc_6m_visit4
g hmis_anc_visit_41ratio_6m =  hmis_anc_6m_visit4/hmis_anc_6m_visit1
ta hmis_anc_visit_41ratio_6m if id_period_ym==201306 // FLAG TO SELE (!)

g problem_hmis_anc_visit41=0
replace problem_hmis_anc_visit41=1 if hmis_anc_visit_41ratio_6m>1.1

* Penta 3 
foreach var in hmis_penta_dose1 hmis_penta_dose2 hmis_penta_dose3 {
	bys id_phcu: egen `var'_6m = total(`var')
}

compare hmis_penta_dose1_6m hmis_penta_dose3_6m


g hmis_penta_dose_6m_r =   hmis_penta_dose3_6m/hmis_penta_dose1_6m
ta hmis_penta_dose_6m_r if id_period_ym==201306 // FLAG TO SELE (!)
inspect  hmis_penta_dose_6m_r if id_period_ym==201306

g problem_penta_dose = 0
replace problem_penta_dose = 1 if hmis_penta_dose_6m_r>1.1


ta problem_penta_dose if id_period_ym==201306

ta problem_penta_dose problem_hmis_anc_visit41 if id_period_ym==201306

* Deliveries 
*--------------------------------------------

ren hmis_del_facilitydelivery_total  hmis_del_facilitydelivery

bys id_phcu: egen hmis_del_facilitydelivery_6m = total(hmis_del_facilitydelivery)

g hmis_phcu_delivery = 0
replace hmis_phcu_delivery = 1 if hmis_del_facilitydelivery_6m>0 

la var hr_phcu_delivery "HR Delivery Binary"
la var hmis_phcu_delivery "HMIS Delivery Binary"


ta hmis_phcu_delivery  hr_phcu_delivery if id_period_ym==201306

#delimit ;
list id_phcu_name hmis_del_facilitydelivery_6m hr_phcu_delivery hmis_phcu_delivery if id_period_ym==201306 &
	((hmis_phcu_delivery==1 & hr_phcu_delivery==0) | (hmis_phcu_delivery==0 & hr_phcu_delivery==1))
	;
#delimit cr

drop hmis_del_facilitydelivery_o35  hmis_del_facilitydelivery_u20  


* Family Planning Headcount (total)
* -------------------------------------------------------------
egen hmis_fp_headcount = rowtotal (hmis_fp_headcount_1524yrs hmis_fp_headcount_25yrs)


* Total of 3 months 
* -------------------------------------------------------------
ren *before* *b*
ren *after* *a*

* Restrict to one pre period
keep if inlist(id_period_ym,201304,201305,201306)
ta id_period_ym

* Total of last 3 months
fn hmis_*, remove(hr_* hmis_*6m* hmis_penta* merge_hmis hmis_phcu_delivery) type(numeric)
foreach var in `r(varlist)' {
	bys id_phcu: egen `var'_3m = total(`var')
}

* RATIOS
* -------------------------------------------------------------

* PERCENTAGE OF ANC 1stvisitafter 16w + 1stvisitbefore 16 w
egen hmis_anc_1stvisit_3m = rowtotal(hmis_anc_1stvisita16w_3m hmis_anc_1stvisitb16w_3m)
g hmis_anc1stvisit_b16w_3m_r = hmis_anc_1stvisitb16w_3m/hmis_anc_1stvisit_3m
su hmis_anc1stvisit_b16w_3m_r

* PERCENTAGE OF PNC WITHIN 48 HOURS
loc list hmis_pnc_2942days_3m hmis_pnc_37days_3m hmis_pnc_828days_3m hmis_pnc_within2days_3m
egen hmis_pnc_3m = rowtotal(`list')
g hmis_pnc_48hrs_3m_r = hmis_pnc_within2days_3m/hmis_pnc_3m
g hmis_pnc_37days_3m_r = hmis_pnc_37days_3m/hmis_pnc_3m
g hmis_pnc_24weeks_3m_r = hmis_pnc_828days_3m/hmis_pnc_3m
g hmis_pnc_after1month_3m_r = hmis_pnc_2942days_3m/hmis_pnc_3m

su hmis_pnc*_r

* Keep only HMIS 6m & 3m variables
* -------------------------------------------------------------
fn hmis_*, remove(hmis*_r hr_* hmis*6m hmis*3m merge_hmis hmis_phcu_delivery) type(numeric)
drop `r(varlist)' 

* Keep only 1 pre period
* -------------------------------------------------------------
keep if id_period_ym==201306
ta id_period_ym

******************************************************************************
* 7. Drop irrelevant variables
******************************************************************************

fn hmis*r
#delimit ;
loc xlistout
	hmis_fp_headcount_1524yrs_3m 
	hmis_fp_headcount_25yrs_3m 
	hmis_pnc_after1month_3m_r
	hmis_pnc_24weeks_3m_r
	hmis_pnc_37days_3m_r 
	hmis_mva_3m 	
	hmis_phcu_source_3m 
	hmis_penta_dose2_6m
	hmis_penta_dose3_6m 
	hmis_penta_dose1_6m 			
	hmis_pnc_within2days_3m 	
	hmis_pnc_2942days_3m 
	hmis_pnc_37days_3m 
	hmis_pnc_3m 
	hmis_pnc_828days_3m 
	hmis_anc_1stvisit_3m 
	hmis_anc_1stvisita16w_3m 
	hmis_anc_1stvisitb16w_3m 
	hmis_anc_visit1_3m 
	hmis_anc_visit4_3m 	
;
#delimit cr 

drop `xlistout'

******************************************************************************
* 8. Relabel
******************************************************************************
/*
* Relabel variables 
*la var hmis_anc_visit1 "ANC 1 visit"
fn * 
foreach var in `r(varlist)' {
	
	loc label `"`: var label `var''"'
	loc newlabel : subinstr loc label "_" " ", all
	loc newlabel : subinstr loc newlabel "- " "-"
	loc newlabel : subinstr loc newlabel " -" "-"
	loc newlabel : subinstr loc newlabel "yrs" " years"
	loc newlabel : subinstr loc newlabel "Postnatal" "PNC"
	loc newlabel = itrim(trim("`newlabel'"))
	
	la var `var' "`newlabel'"
}
*/
******************************************************************************
* Label all variables
******************************************************************************

ren treatment treatment_all
la var treatment_all "Treated"

la var    phcu_catchmentpop               	"PHCU catchment area"

la var    hmis_opd_headcount_new_3m       	"HMIS - New OPD Headcount (3m)"

la var    hmis_anc_visit_41ratio_6m       	"HMIS - ANC 4th visits, \% (6m)"
la var    hmis_anc1stvisit_b16w_3m_r  		"HMIS - ANC before 16 weeks, \% (3m)"
la var    hmis_pnc_48hrs_3m_r		       	"HMIS - PNC within 48 hours, \% (3m)"
la var    hmis_sopd_hypertension_new_3m   	"HMIS - New Hypertension (3m)"
la var    hmis_sopd_epilepsy_new_3m       	"HMIS - New Epilepsy (3m)"
la var    hmis_sopd_diabetis_new_3m       	"HMIS - New Diabetis (3m)"
la var    hmis_sopd_sti_new_3m            	"HMIS - New STI (3m)"
la var    hmis_fp_headcount_3m            	"HMIS - Family Planning headcount (3m)"
la var    hmis_fp_implantinsertion_3m     	"HMIS - Implant insertion (3m)"
la var    hmis_penta_dose_6m_r		  		"HMIS - Penta 3 ratio"
la var    hmis_del_facilitydelivery_6m 		"HMIS - Facility Deliveries (6m)"
la var    hmis_del_facilitydelivery_3m 		"HMIS - Facility Deliveries (3m)"
la var	  hmis_phcu_delivery	 			"HMIS - Delivery Facility"

la var    hr_staff_n                      	"HR - Number of staff"
la var    hr_cadre_code_low_n				"HR - Cadre: Low"	             
la var    hr_cadre_code_mid_n             	"HR - Cadre: Medium"
la var    hr_cadre_code_top_n             	"HR - Cadre: Top"
la var    hr_facility_type                	"HR - Facility Type"
la var    hr_age_201306_avg               	"HR - Average age of staff (June 2013)"
la var    hr_staff_male_ratio            	"HR - Percentage of clinical male staff members"

la var	  hr_phcu_24hours  		"HR - 24 Hours PHCU"
la var    hr_phcu_delivery		"Delivery PHCU"
la var	  hr_phcu_plus			"PHCU+"

fn hmis_* hr_*
outvarlist `r(varlist)'


* Install value Labels
run "$DO/01b_all_value_labels.do"

******************************************************************************
* Merge check
******************************************************************************

set linesize 225
list id_phcu id_phcu_name merge_hr merge_hr_2 merge_hmis if merge_hr!=3 | merge_hr_2!=3 | merge_hmis!=3


******************************************************************************
* Open 
******************************************************************************

g hmis_headcount_bypop = hmis_opd_headcount_new_3m/phcu_catchmentpop
*hmis_sopd_hypertension_new_3m/hmis_opd_headcount_new_3m

fn hmis_sopd*
foreach var in `r(varlist)'  {
	di as error "`var'"
	su `var'
	inspect `var'
}

* PROBLEM
ta hr_facility_type  hr_phcu_plus 
* 	hr_phcu_plus

* Drop some vars
drop gps*


*loc xlist `var_distinct' `vars_continous'



*outvarlist $xlistpsm 

******************************************************************************
*  Manipulate Variables
******************************************************************************

* Drop 
drop hmis_penta_dose_6m_r hmis_headcount_bypop

* MISSING OR INFEASIBLE VALUES
*---------------------------------------	
ren *ratio_* *_r_*

fn *_r_6m *_r, loc(ratio)
outvarlist `ratio', re(name varlabel) su(min max) 

foreach var in `ratio' {

	mvgen2 `var'  if `var'>1.2 | `var'>=.

	replace `var'=0 if mv_`var'==1
	replace `var'=1 if `var'>1
	di as error "mv_`var'"
	
	
}
outvarlist `ratio', re(name varlabel) su(min max) 

ta mv_hmis_anc_visit_41_r_6m  mv_hmis_anc1stvisit_b16w_3m_r 
ta mv_hmis_anc_visit_41_r_6m mv_hmis_pnc_48hrs_3m_r

* Ratios over catchment population
*---------------------------------------	
foreach var in hmis_fp_headcount_3m hmis_fp_implantinsertion_3m   hr_staff_n hmis_del_facilitydelivery_3m hmis_opd_headcount_new_3m hmis_sopd_hypertension_new_3m   {
	*clonevar `var'_bp = `var'
	g `var'_bp = `var'/phcu_catchmentpop
	loc label `"`: var label `var''"'
	la var `var'_bp "`label' / CP"
}
/*
foreach var in hr_cadre_code_low  hr_cadre_code_mid hr_cadre_code_top {
	g `var'_ratio = `var'/phcu_catchmentpop
	loc label `"`: var label `var''"'
	la var `var'_ratio "`label' ratio"	
}
*/

******************************************************************************
* Fix variables
******************************************************************************

* Making it a proper dummy
recode id_zone (2=0)
cb id_zone

******************************************************************************
* Save
******************************************************************************

* Install value Labels
run "$DO/01b_all_value_labels.do"

order *, alpha
order id* phcu* treatment

compress
sa "$CLEAN/$COMPARISON/c_01(prepare)", replace
