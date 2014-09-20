
**************************************************************************
* Preamble
**************************************************************************

set linesize 250
u "$CLEAN/tc_02(merge)", clear

* Install value Labels
run "$DO/01b_all_value_labels.do"

*******************************************************************************
* Cleaning String
*******************************************************************************

* Facility names: 
preserve
keep if inlist(id_phcu,1311,2601,2603,2608)
bys id_phcu: ta id_phcu_name 
restore


replace id_phcu_name="Chuini" if id_phcu_name=="Chuwini"
replace id_phcu_name="Kisauni" if id_phcu_name=="Kisuani"
replace id_phcu_name="Kizimbani" if id_phcu_name=="Kizimkazi"
replace id_phcu_name="Beit-El-Raas" if inlist(id_phcu_name,"Beit El Ras","Beit-el-Raas")
replace id_phcu_name="Zingwe Zingwe" if id_phcu_name=="Zingwe zingwe"

ta id_phcu_name



*******************************************************************************
* Time ID check 
*******************************************************************************

ta id_period_ym 
ta id_period_ym if id_phcu==1317  // PHCU is new

*******************************************************************************
* Section skips
*******************************************************************************

*-----------------------------------------------------
* Fix Skips
*-----------------------------------------------------

* Section B
list id_phcu id_phcu_name if b0_section_skip==2 // Dropping RCH Mkoani
replace b0_section_skip=0
replace b0_section_skip=1 if inlist(id_phcu,1312)
la val b0_section_skip yesnol

* Section C
list id_phcu id_phcu_name if c0_section_skip==2 // Dropping Beit-El-Raas & Matrakta
replace c0_section_skip=0
replace c0_section_skip=1 if inlist(id_phcu,2601,2612)
la val c0_section_skip yesnol

*-----------------------------------------------------
* Skips: OPD Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if b0_section_skip==1
fn b*, remove(b0_section_skip)

foreach var in `r(varlist)' {
	replace `var'=.d if b0_section_skip==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_period_mm id_zone if b0_section_skip!=1 // Pemba = 15, Unguja = 14

*-----------------------------------------------------
* Skips: Preventative Section
*-----------------------------------------------------

* Set value to "not applicable" for non-eligble facilities (without OPD)
ta id_phcu_name if c0_section_skip ==1
fn c*, remove(c0_section_skip)
foreach var in `r(varlist)' {
	replace `var'=.d if c0_section_skip ==1
}

* PHCU count (without non-eligble)
cb id_zone
ta id_period_mm id_zone if c0_section_skip!=1 // Pemba = 16, Unguja = 12


*******************************************************************************
* Preparation
*******************************************************************************


/* Label PBCU - doesn't work as it relies on sorting 
foreach zone in 1 2 {
	preserve
	keep if id_zone==`zone'
	sort id_phcu
	levelsof id_phcu, loc(id_phcu)
	levelsof id_phcu_name, loc(id_phcu_name)
	
	foreach level in `id_phcu' {
		gettoken name id_phcu_name : id_phcu_name
		loc phculabel`zone' `phculabel`zone''  `level' "`name' (`level')"
	}
	restore	
}


loc phculabel `phculabel1' `phculabel2'


la de phculabel `phculabel'
la val id_phcu phculabel
*/

replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit-el-Raas" 

labmask id_phcu, values(id_phcu_name) lblname(phculabel)

* Define Label
#delimit ;
la de mv_special_l 
	0 "no missing"
	1 "missing"
	2 "not applicable (.a -999)" 
	3 "not available (.b -998)" 
	4 "not reported by PHCU (.c -997)" 
	5 "not reported by enumerator (.d -996)"
	6 "never collected (.f)"
	7 "not collected in recollection exercise (.g)"
	, replace ;
#delimit cr

/******************************************************************************
* Correct missing value labels
*******************************************************************************

Equiviliants
New Form	Old Form		Comment
*----------------------------------------------------------------------
-			live_b01_r_t 	Total number of cases (filled by PHCU!)
-			live_b01_r_g  	Total number of cases with qualtiy (filled by PHCU)
b01_t 		live_b01_t 		Total number of cases (filled by verification team)	from 09/13 on only
b01_v_t		live_b01_v_t	Verfiable total
b01_v_g 	live_b01_v_g 	Verifiable with quality
b01_g 		-
b01_nv_g 	-	
b01_nv_t 	-					*/

fn b03_v* b04_v* b03_t* b04_t* 
foreach var in `r(varlist)' {
	replace `var'=.g if `var'==.
}
fn b03_nv* b04_nv* b03_g* b04_g* 
foreach var in `r(varlist)' {
	replace `var'=.f if `var'==.
}

*******************************************************************************
* Save
*******************************************************************************

qui compress
sa "$CLEAN/tc_03(clean)", replace


