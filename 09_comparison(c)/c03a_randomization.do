clear
set more off
set linesize 225
*capture log close

******************************************************************************
* Author: 	Max Bode
* Date:		June 11, 2014
* Purpose:	Randomly select 18% of the sample in each district for control data collection
******************************************************************************

u "$CLEAN/$COMPARISON/c_01(prepare)", clear

label de treatmentl 99 "Non-Comparison" 1 "Treatment" 0 "Comparison" 


******************************************************************************
* 1. Keep potential comparison districts only
******************************************************************************

* Drop West & Mkoani (treatment)
drop if inlist(id_district,13,26)
ta id_district treatment

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
	set linesize 49
	di "`sample_large_d'"

restore

set linesize 225
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

foreach size in large medium small {
	g treatment_`size' = 99
	
	di "`sample_`size''"
	di as error `"`sample_`size'_d'"'
/// ERROR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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

g treatment_district_n = 99
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

g treatment_district_pct = 99
bys id_district: replace treatment_district_pct = 0 if _n<=`phcupct'*_N
la val treatment_district_pct treatmentl
ta id_district treatment_district_pct

* Look at the facilities in treatment
sort id_district id_phcu
list id_district id_phcu_name if treatment_district_pct==0

******************************************************************************
* Save
******************************************************************************

drop pop09

order *, alpha
order id* treatment phcu* hmis* 

compress
sa "$CLEAN/$COMPARISON/c_02a(randomization)", replace


