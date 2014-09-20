
u "$CLEAN/1q02(rehape_manipulate)", clear

*****************************************************
* Individual PHCUs OPD corrections 
*****************************************************
/*
*** *** *** B01 & B02 missing (!) *** *** ***
*** NO REASON ***
JUNE PROBLEM:
*- Kengeja (1304) is only in August
*- Mwambe (1311) B02 guidline is missing in June/July/August
*- Chukwani (2604) June/July B01 is missing

NO JUNE PROBLEM: 
*- Kiwani (1306) BO2 is mising in Sep


*** FOR A REASON ***
*- Fuoni (2605) B02 is missing because B01 and B02 are in one registry
replace b00_t=b01_t if id_phcu==2605 
replace b00_g=b01_g if id_phcu==2605

foreach var in b01_t b01_g b02_t b02_g {
	replace `var'=.b if id_phcu==2605 
}

*- RCH Mkoani has no outpatients
foreach var in  b00_t b00_g b01_t b01_g b02_t b02_g {
	replace `var'=.d if id_phcu==1312
}

* INSPECTING MISSING OUTPATIENT DATA
sort id_phcu_name id_period_m
bys id_phcu_name: list id_phcu id_period_m b00_t b00_g b01_t b01_g b02_t b02_g ///
	if  b00_t>=. | b00_g>=. | b01_t>=. | b01_g>=. | b02_t>=. | b02_g>=.




g sample_opd = 1
replace sample_opd = 0 if inlist(id_phcu,1304,1311,2604,1306)
ta sample_opd
*/

*****************************************************
* Individual PHCUs delivery
*****************************************************
/*
foreach phcu in 1312 1315 1316 {
	foreach var in c06_t c06_g {
		replace `var'=0 if id_phcu==`phcu'
	}
}
*/
* INSPECTING MISSING DELIVERY DATA
sort id_phcu_name id_period_m
bys id_phcu_name: list id_phcu id_period_m c06_t c06_g  ///
	if c06_g>=. | c06_t>=.

* INSPECTING ALL DELIVERY DATA
sort id_phcu_name id_period_m
bys id_phcu_name: list id_phcu id_period_m c06_t c06_g  if c06_t!=0 & c06_t<.

bys id_phcu_name: list id_phcu id_period_m c06_t c06_g ///
	 if inlist(id_phcu,1301,1304,1306,2603,2604,2605,2606)
	 
/* 
REGULAR DELIVERY FACILITIES:
- BOGOA
- CHUKWANI
- FUONI
- KENGEJA

IRREGULAR DELIVERY FACILITIES: 
- FUONI KIBONDENI (1 in Oct)
- KIWANI (3 in Oct) 
*/

*****************************************************
* PNC - INVESTIGATING THE AUG JOB
*****************************************************

bys id_period_m: su c05_g_pct

g problem = 0
replace problem = 1 if c05_g_pct>=.  
bys id_phcu: egen problem_phcu = max(problem)
	
ta problem_phcu


bys id_period_m: su c05_g_pct if problem_phcu==0


sort id_phcu id_period_m
bys id_phcu_name: list id_phcu id_period_m c05_t  c05_g c05_g_pct if problem_phcu==0


*****************************************************
* Last minutes renaming
*****************************************************

ren id_period_m	id_period_mm
ren id_period_y id_period_yyyy

*****************************************************
* Save
*****************************************************

sa "$TEMP/1q03(datacheck)", replace

drop sample_opd problem*
order id* a* b* c* v* f* 
