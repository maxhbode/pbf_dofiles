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
cap: program drop tc2
program define tc2
	syntax namelist, weight(string) treated(string) pscore(string)
	g `namelist' = . 
	replace `namelist' = 99 if `weight'==. & `treated'==0
	replace `namelist' = 0 if `weight'>=0 & `weight'<.
	replace `namelist' = 1 if `treated'==1
	la var `namelist' "Treatment status" 
	la de tcl 99 "Other" 1 "Treatment" 0 "Control", replace
	la val `namelist' tcl
	ta `namelist', mi
	list id_phcu id_phcu_name treatment_all `pscore' if `namelist'==.

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
loc exactmatch_var hr_phcu_plus
recode hr_phcu_plus (0=2)
ta hr_phcu_plus  

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
fn `xlistpsm4' `leftover', loc(xlistpsmall) remove(mv_*)

global xlistpsm `xlistpsm_all' 


set linesize 100
fn mv*, loc(missing) remove(mv_hmis_anc1stvisit_b16w_3m_r mv_hmis_pnc_48hrs_3m) 

******************************************************************************
* Linear: Regression and Score
******************************************************************************

eststo clear

loc i = 1
foreach xlist in 2 3 4 all {
	di "`treatment' - `xlistpsm`xlist''"
	*eststo: psmatch2 `treatment' `xlistpsm`xlist''
	
	* Do Regression
	eststo: reg `treatment' `xlistpsm`xlist''
	
	* Save Score
	predict linear_score_`xlist', xb
	ren _* linear_*_`xlist'
	ren *est_est`i'* *estmissing*
	bys treatment_all: su linear_score_`xlist' // checking that treatment is higher 
	
	* Save regression
	#delimit ;
	esttab, 
		stats(N r2 r2_a, labels("N" "R2 Adjusted" "R2"))  
		star( * 0.1 ** 0.05 *** 0.01) 
		noconst 
	;
	#delimit cr 
	
	loc ++i
}

******************************************************************************
* Linear matching methods 
******************************************************************************


set linesize 225
*------------------------------------------------------------------------
* LINEAR METHOD #1: USING TOP 30 MATCHING
*------------------------------------------------------------------------
*g linear_weight=1 if linear_score_2>

loc xlist all	// selecting variables
loc top 28		// selecting number of variables 

gsort + treatment_all  - linear_score_`xlist'  
g n = _n 
replace n = . if treatment_all==1

g linear_weight_top_`xlist'=. 
* replace linear_weight_top_`xlist'=0 if linear_score_`xlist'<. 
replace linear_weight_top_`xlist'=1 if n<=`top' | treatment_all==1
ta linear_weight_top_`xlist' treatment_all, mi

drop n

order treatment_all, last
ta linear_weight_top_`xlist'

g support=1
replace support=0 if id_phcu==2603

drop if support==0

* Tables & graphs 
*-------------------------------------------------------------
pstest_tex `xlistpsm`xlist'', treated(treatment_all) mweight(linear_weight_top_`xlist') ///
	extracaption(" - Linear, top") latex("$OUTPUTS/$COMPARISON/table_psmbalance_linear_top")	
pstest3 `xlistpsm`xlist'', treated(treatment_all) mweight(linear_weight_top_`xlist') sum graph
graph export "$OUTPUTS/$COMPARISON/graph_psm_os_linear_top.pdf", replace

* Create treatment_linear_`xlist'
*-------------------------------------------------------------
tc2 treatment_linear_`xlist', weight(linear_weight_top_`xlist') treated(treatment_all) pscore(linear_score_`xlist')

* Create more graphs
*-------------------------------------------------------------
loc i = 1
foreach option in   all  linear_`xlist' {
* psm_`option1' psm_`option3'
preserve
	cap: drop if treatment_`option'==99
	*set trace on
	
	density2 linear_score_`xlist', group(treatment_`option') 
	* saving(graph_psm2a_`option', replace)	
	graph export "$OUTPUTS/$COMPARISON/graph_psm2a_linear_top_`option'.pdf", replace
	
	psgraph, treated(treatment_`option') pscore(linear_score_`xlist') bin(50) 
	* saving(graph_psm2b_`option', replace)
	graph export "$OUTPUTS/$COMPARISON/graph_psm2b_linear_top_`option'.pdf", replace
	
restore
loc ++i
}

stop

*------------------------------------------------------------------------
* LINEAR METHOD #2: CLOSET NEIGHBOR
*------------------------------------------------------------------------
/*
set linesize 225
loc xlist all

* Creating match
*-------------------------------------------------------------
psmatch2 treatment_all, neighbor(3) pscore(linear_score_`xlist')
ren _weight linear_weight_nn_`xlist'

* Tables & graphs 
*-------------------------------------------------------------
pstest_tex `xlistpsm`xlist'', treated(treatment_all) mweight(linear_weight_nn_`xlist') ///
	extracaption(" - Linear, top") latex("$OUTPUTS/$COMPARISON/table_psmbalance_linear_nn")	
pstest3 `xlistpsm`xlist'', treated(treatment_all) mweight(linear_weight_nn_`xlist') sum graph
graph export "$OUTPUTS/$COMPARISON/graph_psm_os_linear_nn.pdf", replace

* Create treatment_linear_`xlist'
*-------------------------------------------------------------
tc2 treatment_linear_nn_`xlist', weight(linear_weight_nn_`xlist') treated(treatment_all) pscore(linear_score_`xlist')

* Create more graphs
*-------------------------------------------------------------
foreach option in all linear_nn_`xlist'  {
* psm_`option1' psm_`option3'
preserve
	cap: drop if treatment_`option'==99
	*set trace on
	
	density2 linear_score_`xlist', group(treatment_`option') 
	* saving(graph_psm2a_`option', replace)	
	graph export "$OUTPUTS/$COMPARISON/graph_psm2a_linear_nn_`option'.pdf", replace
	
	psgraph, treated(treatment_`option') pscore(linear_score_`xlist') bin(50) 
	* saving(graph_psm2b_`option', replace)
	graph export "$OUTPUTS/$COMPARISON/graph_psm2b_linear_nn_`option'.pdf", replace	
restore
}
*/
******************************************************************************
* Save
******************************************************************************

compress
sa "$CLEAN/$COMPARISON/c_03c(linear)", replace

stop

list id_phcu_name if linear_weight_top_all!=. & treatment_all==0

ta id_zone 


list id_phcu_name if linear_weight_nn_all!=.  & treatment_all==0
