**************************************************************************
* Preamble
**************************************************************************

set linesize 225
u "$CLEAN/tc_04(manipulate)", clear

*******************************************************************************
* Labelling Variables
*******************************************************************************

fn *
foreach var in `r(varlist)' {
	la var `var' ""
}

la var b00_g "OPD Consultation, according to guidlines"
la var b00_t "OPD Consultation"
la var b01_g "OPD Consultation over 5, according to guidlines"
la var b01_t "OPD Consultation over 5"
la var b02_g "OPD Consultation under 5, according to guidlines"
la var b02_t "OPD Consultation under 5"
la var b03_g "OPD Consultation: STD, diabetes, hypertension, mental health, epilepsy, according to guidlines"
la var b03_t "OPD Consultation: STD, diabetes, hypertension, mental health, epilepsy"
la var b04_g "Minor surgery (including circumcision, incision, suturing), according to guidlines"
la var b04_t "Minor surgery (including circumcision, incision, suturing)"
la var b05_g "Manual Vacuum Aspiration (MVA), according to guidlines"
la var b05_t "Manual Vacuum Aspiration (MVA)"
la var b06_t "Patients w 3 TB symptoms referred/tested"
la var b07_t "PMTCT: HIV+ mothers and children treated"
la var b08_t "Voluntary counselling & test for HIV (PITC, DCT)"
la var c01_g "Children immunized against Penta 3, according to guidlines"
la var c01_t "Children immunized against Penta 3"
la var c02_t "Tetanus vaccination of girls 12+ yrs"
la var c03_t "4 standard ANC visits"
la var c03_g "4 standard ANC visits spaced 6 weeks apart"
la var c04_t "1st ANC visits"
la var c04_g "1st ANC visits within 16 weeks"
la var c05_g "Postnatal care, according to guidlines"
la var c05_t "Postnatal care"
la var c06_g "Health Facility Delivery, according to guidlines"
la var c06_t "Health Facility Delivery"
la var c07_t "Family Planning: consultation"
la var c08_g "Family Planning: implant, according to guidlines"
la var c08_t "Family Planning: implant"
la var c09_t "12-49 monthers receiving 6 monthly deworming treatment"
la var c10_t "Vitamin A  (6-49 months)"
la var c11_t "Mosquito net for pregnant women"

* Labelling (nv/v) variables
foreach type in nv v {
	fn *_`type'_*, remove(*_pct)
	foreach var in `r(varlist)' {
		loc oldvar : subinstr loc var "_`type'" "
		loc utype = upper("`type'")
		loc label `"`utype': `: var label `oldvar''"'
		la var `var' "`label'"
		di "`label'"
	}
}	

* Labelling percentage (pct) variables
fn *_g_pct
foreach var in `r(varlist)' {
	loc oldvar : subinstr loc var "_pct" ""
	di "`oldvar'"
	loc label `"`: var label `oldvar'' (%)"'
	
	la var `var' "`label'"
	di "`label'"
}

* Other labels
la var id_phcu "Facility ID"
*la var id_phcu_s "Facility ID"
la var id_phcu_name "Facility Name"

la var id_period_mm "Verification Period, Month"	
la var id_period_yyyy "Verification Period, Year"
la var id_district "District"
la var b0_section_skip "Section skip B"
la var c0_section_skip "Section skip C"

* Treatment 
la var treatment        	"Treatment" 
la var treatment_temporal	"Treatment (temporal)"

*******************************************************************************
* Apply Value Labels
*******************************************************************************

replace id_district = id_zone*10+id_district

* Install value Labels
do "$DO/01b_all_value_labels.do"

la val id_period_ym id_period_yml
la val id_district districtl

cb id_district
la val id_period_ym monthl
la val id_zone zonel
la de treatment_temporall 0 "Before PBF" 1 "After PBF", replace

*******************************************************************************
* Drop variables
*******************************************************************************

drop id_period_yy /* not consistent */
drop *_merge

replace id_phcu_name="Mbweni Matrekta" if id_phcu_name=="Matrakta"

*******************************************************************************
* Save
*******************************************************************************

order *, alpha
order id* 
qui compress
sa "$CLEAN/a05(label)", replace
sa "$CLEAN/tc_05(label)", replace


*******************************************************************************


	keep if treatment==1		
	*g c04_g_pct = c04_g/c04_t
	replace 	 c04_g_pct = . if c04_g>=. | c04_t>=.
	bys id_period_ym: su c04_g_pct
