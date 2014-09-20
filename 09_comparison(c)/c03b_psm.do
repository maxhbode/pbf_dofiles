******************************************************************************
* Author: 	Max Bode
* Date:		June 19, 2014
* Purpose:	Do propensity score matching
******************************************************************************

global PSM "$DESKTOP/PSM"

clear
set more off
set graph on
set linesize 225
*capture log close

* Set programs
*-----------------------------------------------------
cap: program drop tc
program define tc 
	syntax namelist, prefix(string)
	g `namelist' = . 
	replace `namelist' = 99 if `prefix'_weight==. & `prefix'_treated==0
	replace `namelist' = 0 if `prefix'_weight>=0 & `prefix'_weight<.
	replace `namelist' = 1 if `prefix'_treated==1
	la var `namelist' "Treatment status" 
	la de tcl 99 "Other" 1 "Treatment" 0 "Control", replace
	la val `namelist' tcl2
	ta `namelist', mi
	list id_phcu id_phcu_name treatment_all `prefix'_pscore if `namelist'==.

end 

u "$CLEAN/$COMPARISON/c_01(prepare)", clear

******************************************************************************
* Inspect Variables
******************************************************************************

fn treatment_all phcu_catchmentpop hmis* hr*
outvarlist2 `r(varlist)' , su(N mean sd min p10 p50 p90 max) tex matrixname(table_summary)  ///
			filedirectory("$OUTPUTS/$COMPARISON/") ///
			outtableoptions(label nobox caption(Variable Inspection)) 

******************************************************************************
* Setting variables
******************************************************************************

* Set macros
*-----------------------------------------------------

* Set locals
loc treatment treatment_all

* Set exact matching
/*
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

codebook `xlistpsm_all'

******************************************************************************
* Showing probit
******************************************************************************

eststo clear

foreach xlist in 2 3 4  {
	di "`treatment' - `xlistpsm`xlist''"
	eststo: psmatch2 `treatment' `xlistpsm`xlist''
}

*ereturn list
#delimit ;
esttab using "$OUTPUTS/$COMPARISON/table_probit.tex", replace
	booktabs  longtable label
	cells(	"b(star) z "
			"se(par) p(par([ ]) fmt(%9.3f))")
	stats(N N_cdf r2_p ll, labels("N" "Determined Failures" "Pseudo R2" "Log likelihood")) 
	title("PSM Probit")
	drop(`missing' _cons)
	noconst 	
	star( * 0.1 ** 0.05 *** 0.01)
	substitute(
	"Treated             &                     &            &                     &            \\"
	""
	)
;
#delimit cr

******************************************************************************
* 1. PSM
******************************************************************************

* Random sorting 
set seed 8228973
gen rand = uniform()
sort rand

* Different Options
loc option1 nor
loc option2 rep1	
loc option3 rep2

loc r_`option1' 	noreplacement	// No replacement
loc r_`option2'		// replacement			 
loc r_`option3'		// replacement

loc k_`option1' 	1
loc k_`option2'		1 
loc k_`option3'		2

tempfile tempfile
sa `tempfile', replace

eststo clear

set linesize 225

* Option for exact matching
foreach exactmatching in off {
* on off 
*loc exact 
	
	u `tempfile', clear

	* Choose group of variables
	foreach option in `option2' {
		
		di as error "*** `option' - exact matching `exactmatching' ****"

		preserve 
			
			* Calculate Propensity Score + Match	
			*------------------------------------------------------------------

			* Exactmatching off
			if  "`exactmatching'"=="off" {
				psmatch2 `treatment' $xlistpsm, ///
					neighbor(2) caliper(.12)
					* `r_`option''
					* chose caliper in a way to include all facilities !!! 
			}
			
			* Exactmatching on
			else if "`exactmatching'"=="on" {
				g treatment_exactzone = .
				levels `exactmatch_var', local(gr)
				qui foreach j of local gr {
			
					#delimit ;
					psmatch2 `treatment' $xlistpsm if `exactmatch_var'==`j', 
						neighbor(`k_`option'') `r_`option''
						;
					#delimit cr
			   	 	replace treatment_exactzone = _treated if `exactmatch_var'==`j'	
				}
				drop _treated		
				ren treatment_exactzone _treated
			}

			* Checking caliber size
			codebook _pscore
			ta `treatment' _support, mi
			
			g t = 0 
			replace t =1 if _weight>0 & _weight<. 
			
			ta `treatment' t, mi

			* BIAS ANALYSIS - export graph 
			fn $xlistpsm, remove(mv*) loc(xlistpsm_nomv)

			cap: log close
			pstest_tex `xlistpsm_nomv', extracaption(" - Only matching variables") latex("$OUTPUTS/$COMPARISON/table_psmbalance_`option'_`exactmatching'")	
			pstest3 `xlistpsm_nomv', sum graph mweight(_weight)
			graph export "$OUTPUTS/$COMPARISON/graph_psm_os_`option'_`exactmatching'.pdf", replace

			pstest_tex `xlistpsm_all', mweight(_weight) extracaption(" - All baseline variables") latex("$OUTPUTS/$COMPARISON/table_psmbalance_all_`option'_`exactmatching'")	
			pstest3 `xlistpsm_all', mweight(_weight) sum graph
			graph export "$OUTPUTS/$COMPARISON/graph_psm_os_all_`option'_`exactmatching'.pdf", replace


/*
di as error "TEST 1"
di as error  "BEFORE: `meanbiasbef_1'"
di as error  "AFTER: `meanbiasaft_1'"
di "Bias increase: `diff_pct_1'"
di ""

di as error "TEST 2"
di as error  "BEFORE: `r(meanbiasbef)'"
di as error  "AFTER: `r(meanbiasaft)'"
loc diff_pct_2 = `r(meanbiasaft)'-`r(meanbiasbef)' 
loc diff_pct_2 = `diff_pct_2'/`r(meanbiasbef)'
di "Bias increase: `diff_pct_2'"
*/

			ren _* psm_`option'_`exactmatching'_*
			tc treatment_psm_`option'_`exactmatching', prefix(psm_`option'_`exactmatching')
	
			keep id_phcu psm_`option_`exactmatching''* treatment*
			drop treatment_all
			
			di as error "`option'_`exactmatching'"	
			tempfile `option'_`exactmatching'	
			sa ``option'_`exactmatching''
			
		restore 

		merge 1:1 id_phcu using ``option'_`exactmatching'', nogen	
		
	}
	
	* Reconcile psm options 
	/*
	compare psm_`option1'_pscore psm_`option2'_pscore
	*/
	clonevar psm_pscore = psm_`option2'_`exactmatching'_pscore
	drop psm_`option2'_`exactmatching'_pscore
	*drop psm_`option1'_pscore 
	
	
	* Compare the densities of the estimated propensity score over groups
	foreach option in all  psm_`option2'_`exactmatching'  {
	* psm_`option1' psm_`option3'
	preserve
		cap: drop if treatment_`option'==99
		*set trace on
		
		density2 psm_pscore, group(treatment_`option') 
		* saving(graph_psm2a_`option', replace)	

		graph export "$OUTPUTS/$COMPARISON/graph_psm2a_`option'.pdf", replace
		
		psgraph, treated(treatment_`option') pscore(psm_pscore) bin(50) 
		* saving(graph_psm2b_`option', replace)
		graph export "$OUTPUTS/$COMPARISON/graph_psm2b_`option'.pdf", replace	
	restore
	}
	
	tempfile `exactmatching'
	sa ``exactmatching'', replace
}

/*
u `on', clear
keep id_phcu *_on_* *_on
merge 1:1 id_phcu using `off', nogen
*/ 

******************************************************************************
* Save
******************************************************************************

drop pop09

order *, alpha
order id* treatment* psm* phcu* hmis*

compress

sa "$CLEAN/$COMPARISON/c_03b(psm)", replace




list id_phcu_name if psm_rep1_off_weight!=. & treatment_all==0
