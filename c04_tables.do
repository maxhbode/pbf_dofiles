

u "$CLEAN/$COMPARISON/c_02b(psm)", clear

fn psm*

ta psm_rep1_off_weight treatment_all, mi


ta id_district treatment_psm_rep1_off 
tabout id_district treatment_psm_rep1_off ///
	using "$OUTPUTS/$COMPARISON/table_tabout_district.tex", replace bt  style(tex) ///
			format(0c) 

ta id_zone treatment_psm_rep1_off 
tabout id_zone treatment_psm_rep1_off  ///
	using "$OUTPUTS/$COMPARISON/table_tabout_zone.tex", replace bt  style(tex) ///
		format(0c)

* Apply labels
labmask psm_rep1_off_id, values(id_phcu_name)

codebook psm_rep1_off_id
fn psm*_n*, remove(psm*_nn)
foreach var in `r(varlist)' {
	la val `var' psm_rep1_off_id
}

* See matching
set linesize 225

list id_zone id_district id_phcu_name ///
	psm_rep1_off_n1  psm_rep1_off_n2  psm_rep1_off_n3 ///
	if treatment_all==1 & psm_rep1_off_weight!=.
	
list id_zone id_district id_phcu_name  ///
		psm_rep1_off_weight ///
	if treatment_all==0 & psm_rep1_off_weight!=.


* id_zone id_district id_phcu_name


outvarlist id_phcu_name psm_rep1_off_weight psm_rep1_off_n1  psm_rep1_off_n2  psm_rep1_off_n3, re(name varlabel)

la var psm_rep1_off_weight   "Weight of matched controls"    
la var psm_rep1_off_n1       "NN nr. 1"  
la var psm_rep1_off_n2       "NN nr. 2"  
la var psm_rep1_off_n3       "NN nr. 3"

#delimit ;
export excel id_phcu_name psm_rep1_off_n1  psm_rep1_off_n2  psm_rep1_off_n3
	using "$OUTPUTS/$COMPARISON/table_phcus_treatment"
	if  treatment_psm_rep1_off==1,
	replace firstrow(varlabels) 
;	

export excel id_phcu_name psm_rep1_off_weight
	using "$OUTPUTS/$COMPARISON/table_phcus_comparison" 
	if  treatment_psm_rep1_off==0, 
	replace firstrow(varlabels) 	
;
#delimit cr	
	
	* 2014201415
