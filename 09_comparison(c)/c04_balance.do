
set linesize 225

******************************************************************************
* Set macros
******************************************************************************

/* Set Independent Variables 
#delimit ;
loc vars_distinct 
	hmis_phcu_24hours hmis_phcu_delivery 
	hmis_phcu_plus hmis_phcu_source ;
#delimit cr
fn phcu_catchmentpop hmis* , loc(vars_continous) remove(`vars_distinct' hmis_mva)
*/
* Set Independent Variables 
# delimit ;
loc xlistin

	phcu_catchmentpop
	id_zone
	hr_phcu_plus

	hr_staff_n_bp
	hr_cadre_code_low_n
	hr_cadre_code_mid_n 
	hr_cadre_code_top_n	
	hr_age_201306_avg    

	hmis_opd_headcount_new_3m
	hmis_opd_headcount_new_3m_bp
	hmis_sopd_hypertension_new_3m_bp
	
	hmis_pnc_48hrs_3m   
	hmis_anc1stvisit_b16w_3m_r 
	hmis_anc_visit_41_r_6m
	
	hmis_phcu_delivery
	hmis_del_facilitydelivery_3m  
	hmis_del_facilitydelivery_6m 	
	hmis_del_facilitydelivery_3m_bp 
	 
	hmis_fp_headcount_3m_bp 
	hmis_fp_implantinsertion_3m_bp 
 
 	hr_staff_n
 	hr_staff_n_bp
 	hr_cadre_code_low 
	hr_cadre_code_mid 
	hr_cadre_code_top 
 
	hr_facility_type	
	
	hr_age_201306_avg
	
	hr_staff_male_ratio
;
#delimit cr

******************************************************************************
* Merge randomization (2a) and PSM (2b) data
******************************************************************************

u "$CLEAN/$COMPARISON/c_02a(randomization)", clear
fn *, remove(id_phcu treatment_*)
drop `r(varlist)'
merge 1:1 id_phcu using "$CLEAN/$COMPARISON/c_02b(psm)"
order id* treatment*

foreach size in large medium small district_n district_pct {
	replace treatment_`size'=1 if _merge==2
	ta treatment_`size'
}
drop _merge


* Relabel
la var treatment_district_n "Stratisfied Randomization - 2 PHCUs per district"
la var treatment_district_pct "Stratisfied Randomization - 20% of PHCUs per district" 
la var treatment_large "Randomization - Large sample"
la var treatment_medium "Randomization - Medium sample"
la var treatment_small "Randomization - Small sample"
*la var treatment_psm_nor "Propensity Score Matching - Without replacement"
*la var treatment_psm_rep1_on "Propensity Score Matching - With replacement (k=1) - exact matching"
la var treatment_psm_rep1_off "Propensity Score Matching - With replacement (k=1) "
*la var treatment_psm_rep2 "Propensity Score Matching - With replacement (k=2)"

******************************************************************************
* Verify balance
******************************************************************************

/*
eststo: estpost tabulate hmis_phcu_plus `treatment', chi2
esttab , cells("N chis2 p")
ereturn list
*/

* psm_rep2 psm_nor psm_rep1_on psm_rep1_off

la var treatment_all "All Facilities" 

loc toprow_all `"&Treated 	& Non-treated		&  Difference 	&   \\ & N, Mean (sd) & N, Mean (sd)		& N, Mean (sd)	& p-value, [t-stat]  \\"'
loc toprow_psm_rep1_off all  `"&Treated 	& Control		&  Difference 	&   \\ & N, Mean (sd) & N, Mean (sd)		& N, Mean (sd)	& p-value, [t-stat]  \\"'

foreach size in all psm_rep1_off all  {
* psm_rep1_on psm_rep1_off large medium small district_n district_pct {	
* psm_nor psm_rep large medium small district_n district_pc
	loc t treatment_`size'

	* Caption
	loc caption `"`: var label `t''"'	
	loc caption "Treatment Method: `caption'"

	di as result "`caption'"

	preserve
	
	if "`size'"=="psm_nor" | "`size'"=="psm_rep" {
		foreach var in $xlistpsm {
			loc varlabel = `"`: var label `var''"'
			loc varlabel = "`varlabel' \dag{}"
			la var `var' "`varlabel'"
			
		loc extranote `"\dag{} Marked variables used in Propensity Score Matching"'
		}
	}
	else {
		loc extranote 
	}

		eststo clear
		
		* Drop non-comparison. non treatment observatons
		keep if `t'!=99 & `t'!=.
		ta `t', mi

		eststo: quietly estpost2 ttest `xlistin', by(`t')
		


	* Putting obs as stats into bottom line
	mat list e(N_1)
	
	mat B = e(N_1)
	loc N_1 =  B[1,1]
	
	mat B = e(N_2)
	loc N_2 =  B[1,1]
	
	loc N = `e(N)'


	* Export top and bottom files 
	#delimit ;
	tablewraplong2, 
		dir("$OUTPUTS/$COMPARISON/") 
		ccount(5) 
		caption(`caption') 
		toprow(`toprow_`size'')
		bottomrow(`"Observations &  `N_2' & `N_1' &  `N' & \\"')
		notes("standard errors in () parentheses; t statistics in [] parentheses \sym{*} p<0.1, \sym{**} p<0.05, \sym{***} p<0.01 \\ `extranote'") 
		;
	#delimit cr

	
		* stats(N_1 N_2 count))
		
		#delimit ;
		esttab using "$OUTPUTS/$COMPARISON/table_treatment_`size'.tex", replace 
			booktabs  longtable
			fragment
			topfile("$OUTPUTS/$COMPARISON/topfile.tex")
			bottomfile("$OUTPUTS/$COMPARISON/bottomfile.tex")
			noobs nonumbers nomtitles nodepvars
			cells(
				"mu_2(fmt(%9.3f))		mu_1(fmt(%9.3f))  		b(star fmt(%9.3f)) 	p(fmt(%9.3f))"
				"sd_2(par fmt(%9.3f))	sd_1(par fmt(%9.3f)) 	se(par fmt(%9.3f))  t(par([ ]) fmt(%9.3f))"
			) 
			label  
			substitute(
				"&   mu_2/sd_2&   mu_1/sd_1&        b/se         &         p/t\\"
				""
				"\midrule" "\midrule \midrule"
				)	
			star(* 0.1 ** 0.05 *** 0.01)  ;
		#delimit cr
		
	restore


}

* 				"N_2(fmt(%9.0f)) 		N_1(fmt(%9.0f))			count(fmt(%9.0f))"

