clear
set more off
set linesize 225
*capture log close

******************************************************************************
* Author: 	Max Bode
* Date:		June 11, 2014
* Purpose:	Randomly select 18% of the sample in each district for control data collection
******************************************************************************

global COMPARISON "06_comparison(c)"
global OUTPUTS "$DATA/outputs"

u "$GENERAL/phcu_info/phcu_info_clean", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

******************************************************************************
* 1. Select N per district
******************************************************************************

preserve

* Create PHCU count
bys id_district: g phcu_n = _N

* Keep obs
bys id_district: g n = _n
keep if n==1

* Keep variables
keep id* pop* phcu_n 
drop id_z* id_phcu*

egen poptotal=total(pop09)
g popweight=pop09/poptotal

loc small	20
loc medium	25
loc large 	30

foreach name in small medium large {
	g sample_bydistrict_`name'_n = round(popweight*``name'',1)
	egen sample_total_`name'_n = total(sample_bydistrict_`name'_n)
	g sample_bydistrict_`name'_pct = sample_bydistrict_`name'_n/phcu_n 
}
sort sample_bydistrict_small_n

sort id_district
levelsof id_district, loc(district_id)

di "`sample_small'"

foreach size in small medium large {
	forval i = 1/8 {
		loc new = sample_bydistrict_`size'_n in `i'
		di "`new'"
		loc sample_`size' `sample_`size'' `new'
		
		loc newd = id_district in `i'
		loc sample_`size'_d `sample_`size'_d' [N=`new' in id_district=`newd']
	}

}

restore

******************************************************************************
* 2. Randomization: Sampling with frequency weights
******************************************************************************

bys id_district: g n = _n

* Set up randomization
set seed 8228973
gen rand = uniform()

*--------------------------------------------------------
* Method #1: By population per district
*--------------------------------------------------------
* Creating 3 different sized treatment samples whereas the large ones contain the smaller ones
* Selecting PHCUs based on number of selecetions
*--------------------------------------------------------

* Put observations in a (stable) random order
sort id_district rand, stable

label de treatmentl 2 "Non-Comparison" 1 "Treatment" 0 "Comparison" 

foreach size in large medium small {
	g treatment_`size' = 2
	
	di "`sample_`size''"
	di `"`sample_`size'_d'"'
	
	foreach district in `district_id' {
		gettoken N sample_`size' : sample_`size'
	
		di as result "[N=`N' in id_district=`district']"
		bys rand: replace treatment_`size' = 0 if n <= `N' & id_district==`district'	
	
	}
	
	ta treatment_`size'
	la val treatment_`size' treatmentl
	loc propersize = proper("`size'")
	la var treatment_`size' "`propersize' treatment group"
	bys id_district: ta treatment_`size'
}

* Look at the facilities in treatments
sort id_district treatment_large treatment_medium treatment_small id_phcu
bys id_district: list id_phcu_name treatment* if treatment_large==0

*--------------------------------------------------------
* Method #2: Fixed # per districts 
*--------------------------------------------------------

loc phcunumber = 2

* Put observations in a (stable) random order
sort id_district rand, stable

g treatment_district_n = 2
bys id_district: replace treatment_district_n = 0 if _n<=`phcunumber'
la val treatment_district_n treatmentl
ta id_district treatment_district_n

* Look at the facilities in treatment
sort id_district id_phcu
list id_district id_phcu_name if treatment_district_n==0

*--------------------------------------------------------
* Method #3: Fixed % per district 
*--------------------------------------------------------

loc phcupct = .20

* Put observations in a (stable) random order
sort id_district rand, stable

g treatment_district_pct = 2
bys id_district: replace treatment_district_pct = 0 if _n<=`phcupct'*_N
la val treatment_district_pct treatmentl
ta id_district treatment_district_pct

* Look at the facilities in treatment
sort id_district id_phcu
list id_district id_phcu_name if treatment_district_pct==0



******************************************************************************
* 4. Verify stratification on balanced continous
******************************************************************************

set linesize 225
eststo: estpost tabulate hmis_phcu_plus treatment_small, chi2
esttab , cells("N chis2 p")
ereturn list


loc phcupct = `phcupct'*100



loc toprow  `"&Comparison 	& Treatment 		&  Difference 	&   \\ & N, Mean (sd) & N, Mean (sd)		& N, Mean (sd)	& p-value, [t-stat]  \\"'

loc var_distinct hmis_phcu_24hours hmis_phcu_delivery hmis_phcu_plus hmis_phcu_source

fn hmis*, loc(vars_continous) remove(`var_distinct' hmis_mva)

foreach size in large medium small district_n district_pct {
loc t treatment_`size'

	loc sizename : subinstr loc size "_" " ", all
	loc sizename = proper("`sizename'")
	loc sizename : subinstr loc sizename "N" "`phcunumber' PHCUs per district", all
	loc sizename : subinstr loc sizename "Pct" "`phcupct'% PHCUs per district", all
	la var treatment_`size' "Treatment Method: `sizename'"
	loc caption `"`: var label `t''"'

	* Export top and bottom files 
	#delimit ;
	tablewraplong, 
		dir("$OUTPUTS/$COMPARISON/") 
		ccount(5) 
		caption(`caption') 
		toprow(`toprow')
		notes("standard errors in () parentheses; t statistics in [] parentheses \sym{*} p<0.1, \sym{**} p<0.05, \sym{***} p<0.01") 
		;
	#delimit cr


	preserve
	eststo clear
	keep if `t'!=2
	ta `t', mi
	eststo: quietly estpost2 ttest `vars_continous', by(`t')
	
	* stats(N_1 N_2 count))
	
	#delimit ;
	esttab using "$OUTPUTS/$COMPARISON/table_treatment_`size'.tex", replace 
		booktabs  longtable
		fragment
		topfile("$OUTPUTS/$COMPARISON/topfile.tex")
		bottomfile("$OUTPUTS/$COMPARISON/bottomfile.tex")
		noobs nonumbers nomtitles nodepvars
		cells(
			"mu_1(fmt(%9.3f)) mu_2(fmt(%9.3f)) b(star fmt(%9.3f)) p(fmt(%9.3f))"
			"sd_1(par fmt(%9.3f)) sd_2(par fmt(%9.3f)) se(par fmt(%9.3f))  t(par([ ]) fmt(%9.3f))"
			"N_1(fmt(%9.0f)) N_2(fmt(%9.0f)) count(fmt(%9.0f))"
		) 
		
		label  
		substitute(
			"&mu_1/sd_1/N_1&mu_2/sd_2/N_2&  b/se/count         &         p/t\\"
			""
			"\midrule" "\midrule \midrule"
			)	
		star(* 0.1 ** 0.05 *** 0.01)  ;
	#delimit cr
	
	restore
}

stop


******************************************************************************
* 4. Verify stratification on balanced continous
******************************************************************************

set linesize 225

	* Export top and bottom files 
	#delimit ;
	tablewraplong, 	dir($TABLES/tables_input) suffix(reg_cs_12) 
					ccount(`ccount') 
					caption(Endogeneity Test) 
					toprow(`toprow')
					notes(Standard errors in parentheses with \sym{*} 
						indicating significance at 10%, \sym{**} at 5%, 
						and \sym{***} at 1%. All reported standard error 
						use the robust or sandwich estimator of variance. 
						Demographic controls (muslim dummy and respondent age)
						and 800x800m\textsuperscript{2} 
						spatial raster fixed effects are included in all 
						specifications.) ;
	#delimit cr
	


loc var_distinct hmis_phcu_24hours hmis_phcu_delivery hmis_phcu_plus hmis_phcu_source

fn hmis*, loc(vars_continous) remove(`var_distinct' hmis_mva)

foreach size in large medium small district_n district_pct {
loc t treatment_`size'

	preserve
	eststo clear
	keep if `t'!=2
	ta `t', mi
	eststo: quietly estpost2 ttest `vars_continous', by(`t')
	
	* stats(N_1 N_2 count))
	
	#delimit ;
	esttab using "$OUTPUTS/$COMPARISON/table_treatment_`size'.tex", replace 
		booktabs  longtable
		fragment
		topfile("$OUTPUTS/$COMPARISON/tex_ttables_topfile.tex")
		bottomfile("$OUTPUTS/$COMPARISON/tex_ttables_bottomfile.tex")
		noobs nonumbers nomtitles nodepvars
		cells(
			"mu_1(fmt(%9.3f)) mu_2(fmt(%9.3f)) b(star fmt(%9.3f)) p(fmt(%9.3f))"
			"sd_1(par fmt(%9.3f)) sd_2(par fmt(%9.3f)) se(par fmt(%9.3f))  t(par([ ]) fmt(%9.3f))"
			"N_1(fmt(%9.0f)) N_2(fmt(%9.0f)) count(fmt(%9.0f))"
		) 
		
		label  
		addnotes(
			"standard errors in () parentheses; t statistics in [] parentheses" 
			"* p<0.1, ** p<0.05, *** p<0.01") 
		substitute(
			"&mu_1/sd_1/N_1&mu_2/sd_2/N_2&  b/se/count         &         p/t\\"
			""
			"\midrule" "\midrule \midrule"
			)	
		star(* 0.1 ** 0.05 *** 0.01)  ;
	#delimit cr
	
	restore
}

stop


/*
 		cells("b(star fmt(%9.3f))" "se(par fmt(%9.3f))") 
		label se nonotes nonumbers  nomtitles replace
		starlevels(* 0.1 ** 0.05 *** 0.01)
 */



******************************************************************************
stop

stop
reg opd_headcount_new  treatment_small
ttest opd_headcount_new, by(treatment_small)

corr_table_ttest opd_headcount_new, indvar(treatment_small) 
esttab

stop
foreach size in district_pct {
* large medium small district_n

	replace treatment_`size'=0 if treatment_`size'==.
	*bys id_district: su treatment_`size'
	
	bys treatment_`size': su opd_headcount_new
	
	ttest opd_headcount_new, by(treatment_`size')
	
	di "N_Control `r(N_1)'"
	di "N_Treatment `r(N_2)'"
	di "P-value `r(p)'"
	di "SE `r(se)'"
	di "Mean_Control `r(mu_1)'"
	di "Mean_Treatment `r(mu_2)'"
	di "SD_Control `r(sd_1)'"
	di "SD_Treament `r(sd_2)'"
	
	
	
	
	/*
		esttab using "$TABLES/tables_crosssection_et/endogeneitytest_`outcomes'_transposed.tex", 
		topfile($TABLES/tables_input/topfile_reg_cs_12.tex)
		bottomfile($TABLES/tables_input/bottomfile_reg_cs_12.tex)				
		cells("b(star fmt(%9.3f))" "se(par fmt(%9.3f))") 
		label se nonotes nonumbers  nomtitles replace
		starlevels(* 0.1 ** 0.05 *** 0.01)
		booktabs fragment	
		stats(N depmean,
			label("Observations" "Mean")
			fmt(%9.0f %9.2f)
		)
		drop(`controls' _cons)
		substitute(
			"&        b/se   \\" ""
			"&        b/se" ""
			
					"&        b/se   &        b/se   &        b/se   &        b/se   &        b/se   &        b/se   &        b/se   &        b/se   &        b/se   \\" ""
					) ;
	
	copy 
		"$TABLES/tables_crosssection_et/endogeneitytest_`outcomes'_transposed.tex"
		"$PAPER/tables_crosssection_et/endogeneitytest_`outcomes'_transposed.tex",
		replace ;
	*/
	
}

STOP
* Balancing across districts and zone
ta id_district treatment_large, mi row col // WHAT'S THE . ?
ta id_zone treatment_large, mi row col

* Balancing across population
bys treatment_large: su opd_headcount_new
stop
* Facility Type: PHCU vs. PHCU+
ta facility_type treatment, mi row col

* Balacing across Catchment areas
bys treatment: su phcu_catchmentpop 

stop
* Export relevant part for verification
preserve 
sort id_zone id_district, stable // the stable option is very important for reproducibility
keep if treatment == 1
export excel id_zone id_district id_phcu_name using ///
	"$DO/performance verification control/random_phcu_sample", ///
	replace firstrow(varlabels)      
restore



