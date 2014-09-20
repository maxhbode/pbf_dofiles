set linesize 225

*************************************************************************
* Define macros
*************************************************************************


#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
		;
#delimit cr

*************************************************************************

cap: program drop prepost
program define prepost
g prepost = 0
replace prepost = 1 if id_period_yymm>1306
la de prepostl 0 "before" 1 "after"
la val prepost prepostl
end

*************************************************************************

u "$CLEAN/hmis/clean", clear

*************************************************************************
* Merge with PBF data
*************************************************************************

* Correct ID
g id_period_yy = id_period_yyyy - 2000
ta id_period_yy

drop id_phcu_ym
g id_phcu_ym = id_phcu*10000 + id_period_yy*100 + id_period_mm 

replace id_period_ym = (id_period_yyyy - 2000)*100 + id_period_mm 
ta id_period_ym
la val id_period_ym id_period_yml

* Limit sample to Mkoani and West
keep if inlist(id_district,13,26)
ta id_district
cb id_district

* Drop unusual PHCUs
drop if inlist(id_phcu_name,`"Chumbuni"',`"Jangombe Matarumbeta"',`"Kidongo Chekundu"',`"Kidutani"',`"Kwamtipura"',`"Mpendae"',`"Rahaleo"',`"Sebleni"')

* Limit sample to period
keep if id_period_ym>=1306 & id_period_ym<=1403  

* Rename variables
fn *, remove(id*)
foreach var in `r(varlist)' {
	ren `var' hmis_`var'
}

tempfile 
sa temp_hmisclean, replace


* Last minute change
u "$CLEAN/a04(label)", clear
replace id_phcu_name="Kizimbani" if id_phcu_name=="Kizimkazi"
replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit El Ras"
tempfile temp_a03
sa temp_a03, replace

* Merge
u temp_hmisclean, clear
order id_phcu_ym
merge 1:1 id_phcu_ym using temp_a03
ta id_phcu_name if _merge==2 // what's up with RCH Mkoani
drop if _merge==2
drop _merge

*************************************************************************
* Last miniteclearning
*************************************************************************

foreach var in hmis_phcu_delivery hmis_phcu_24hours {
	sencode `var', replace
	recode `var' (2=0)
	la val `var' yesnol
	ta `var', mi
}


*************************************************************************
* Manipulate data
*************************************************************************
set linesize 80

#delimit ;
* OPD tatal ; 
egen b000_t = rowtotal(
	b00_t
	b03_t
	), missing ;
* PNC within 48 hours ;
egen hmis_pnc_total = rowtotal(
	hmis_pnc_2942days hmis_pnc_828days 
	hmis_pnc_37days hmis_pnc_within2days
	), missing ;

mvgen hmis_pnc_total if hmis_pnc_total>=. ;

* OPD Special (Note: no mental health) ; 
egen hmis_opd_special = rowtotal(
	hmis_sopd_sti_new 
	hmis_sopd_hypertension_new 
	hmis_sopd_epilepsy_new 
	hmis_sopd_diabetis_new
	), missing ;
codebook hmis_opd_special ;
* Family Planning Consultation ;
egen hmis_fp_headcount = rowtotal(
	hmis_fp_headcount_25yrs 
	hmis_fp_headcount_1524yrs
	), missing ;
#delimit cr

*************************************************************************
* Label 
*************************************************************************

la var b000_t "PBF: OPD headcount" 
la var b03_t "PBF: Special OPD headcount"
la var b06_t "PBF: MVA headcount"
la var c01_t "PBF: Penta 3 headcount"
la var c03_t "PBF: ANC Standard 4"
la var c04_g "PBF: 1st ANC within 16w"
la var c05_t "PBF: PNC headcount"
la var c05_g "PBF: PNC 48hrs headcount"
la var c07_t "PBF: Family Planning consultations"
la var c08_t "PBF: Implant insertion"

la var hmis_opd_headcount_new		"HMIS: OPD headcount" 
la var hmis_opd_special				"HMIS: Special OPD headcount"
la var hmis_mva 					"HMIS:MVA headcount"
la var hmis_penta_dose3 			"HMIS:Penta 3 headcount"
la var hmis_anc_visit4 				"HMIS:ANC Standard 4"
la var hmis_anc_1stvisitbefore16w	"HMIS:1st ANC within 16w"
la var hmis_pnc_total				"HMIS:PNC headcount"
la var hmis_pnc_within2days			"HMIS:PNC 48hrs headcount"
la var hmis_fp_headcount			"HMIS:Family Planning consultations"
la var hmis_fp_implantinsertion		"HMIS:Implant insertion"


*************************************************************************
* Last minute fix 
*************************************************************************

* !!!!!!!!!!! NEEDS TO BE MOVED for other data too

replace c04_g = c04_t 	if id_period_ym<1401
replace c04_t = . 		if id_period_ym<1401

*************************************************************************
* Drop 
*************************************************************************

#delimit ; 
loc vars treatment id_zone id_district id_phcu_name* id_phcu_ym id_phcu id_district id_zone id_period_ym id_period_yyyy id_period_mm  
  	b000_t	hmis_opd_headcount_new	b03_t	hmis_opd_special	b06_t 	hmis_mva 	c01_t 	hmis_penta_dose3 	c05_t	hmis_pnc_total	c05_g	hmis_pnc_within2days	c03_t 	hmis_anc_visit4 	c04_g	hmis_anc_1stvisitbefore16w 	c07_t 	hmis_fp_headcount	c08_t 	hmis_fp_implantinsertion 
	b0_section_skip  c0_section_skip
;
#delimit cr

keep `vars'
order `vars'
compress
export excel using "$VIEW/HMIS/comparisondata", replace firstrow(varlabels)



*************************************************************************
* Save
*************************************************************************

compress
sa "$CLEAN/hmis/clean_merge", replace

