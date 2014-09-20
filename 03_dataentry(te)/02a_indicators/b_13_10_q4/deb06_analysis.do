

global GRAPH "$DESKTOP/test"
#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
		;
#delimit cr

u "$TEMP/03_datacheck", clear
ta  id_zone if id_period_m==10

la var b00_g "OPD Consultation, according to guidlines"la var b00_t "OPD Consultation, total"la var b03_g "OPD Consultation: STD, diabetes, hypertension, mental health, epilepsy, according to guidlines"la var b03_t "OPD Consultation: STD, diabetes, hypertension, mental health, epilepsy, total"la var b04_g "Minor surgery (including circumcision, incision, suturing), according to guidlines"la var b04_t "Minor surgery (including circumcision, incision, suturing), total"la var b05_t "Patients w 3 TB symptoms referred/tested, total"la var b06_g "Manual Vacuum Aspiration (MVA), according to guidlines"la var b06_t "Manual Vacuum Aspiration (MVA), total"la var c01_g "Children immunized against Penta 3, according to guidlines"la var c01_t "Children immunized against Penta 3, total"la var c02_t "Tetanus vaccination of girls 12+ yrs, total"la var c03_t "Antenatal Care (ANC) standard visits 4, total"la var c04_t "First ANC within 16 weeks, total"la var c05_g "Postnatal care, according to guidlines"la var c05_t "Postnatal care, total"la var c06_g "Health Facility Delivery, according to guidlines"la var c06_t "Health Facility Delivery, total"la var c07_t "Family Planning: consultation, total"la var c08_g "Family Planning: implant, according to guidlines"la var c08_t "Family Planning: implant, total"la var c09_t "12-49 monthers receiving 6 monthly deworming treatment, total"la var c10_t "Vitamin A  (6-49 months), total"la var c11_t "Pregnant women receiving a mosquito net, total"la var c12_t "Voluntary counselling & test for HIV (PITC, DCT), total"la var c13_t "PMTCT: HIV+ mothers and children treated, total"


order id* b0* c* v* f* 

*g b00_g_pct_lag = b00_g_pct(_1)


sa "$DESKTOP/pbf_livecollection", replace




/*
#delimit ;

	graph bar (mean) b00_g_pct, 
		 over(id_period_m) 
		ytitle("OPD cases according to guidelines, %") 
		ylabel(0(10)100) ymtick(0(10)100) 	
		legend(on order(1 "mean"))
		;
		#delimit cr
		
		stpp
*/

*****************************************************
* Outpatients  Analysis 
*****************************************************

* Outpatients 
bys id_period_m: su b00_g_pct
drop if inlist(id_phcu,1304,1306,1311,2604)
bys id_period_m: su b00_g_pct

ta id_zone

*-----------------------------------------------------
* Total numbers
*-----------------------------------------------------

*** TOTAL NUMBER OF PATIENTS BY ZONE***
bys id_period_m: su b00_t
bys id_zone: su b00_t if id_period_m==10

la de zonel 1 "Mkoani District, Pemba (12/16)" 2 "West District, Unguja (13/14)", replace 
graph bar (sum) b00_t, over(id_period_m) over(id_zone) `graphoptions'  ///
	ytitle(Total number of patients) legend(off) 
graph export "$GRAPH/OPD_totalbyzone.png", replace

*** QUALITY PCT BY AGE ***
graph bar (mean) b01_g_pct, over(id_period_m) `graphoptions' ///
	ytitle("OPD cases according to guidelines (%)") /// 
	legend(on order(1 "mean"))
graph  export "$GRAPH/OPD_qualitypct.png", replace

*** QUALITY PCT BY AGE ***
graph bar (p10) b01_g_pct (median) b01_g_pct (p90) b01_g_pct, over(id_period_m) `graphoptions' ///
	ytitle("OPD cases according to guidelines (%)") /// 
	legend(on order(1 "10th percentile" 2 "median" 3 "90th percentile"))
graph  export "$GRAPH/OPD_qualitypct_dist.png", replace

*** QUALITY PCT BY AGE ***
graph bar (mean) b01_g_pct b02_g_pct, over(id_period_m) `graphoptions'  ///
	 ytitle("Cases according to quality (%)") ///
	 ylabel(0(10)100) ymtick(0(10)100) ///
	 legend(on order(1 "Over 5" 2 "Under 5"))
graph  export "$GRAPH/OPD_qualitypctbyage.png", replace



/*

	
graph bar (mean) b01_g_pct (mean) b02_g_pct, over(id_period_m)


- URTI (AND SOME DIARRAY) GET ALMOST ALWAYS ANTIBIOTIC --> IMPROVEMENT NOW
 (200,000 URTI cases in 2012, almost all get antibitotic --> huge saving in drugs,
 antibiotic resistance) 


*/


*-----------------------------------------------------
* DOES THE PERCENTAGE OF QUALITY CASES LAST MONTH PREDICT THE NUMBER OF CLIENTS 
* NEXT MONTHS?
* CAUSUAL LINK I: Higher quality --> Better reputation --> More patients
* CAUSUAL LINK II: Pay for quantity --> Higher staff attendance / more attrative 
* --> More patients
*-----------------------------------------------------

xtset id_phcu id_period_m

foreach var in b00_g_pct  b00_g b00_t {
	g d_`var' = D.`var'
}
foreach var in b00_g_pct  b00_g b00_t {
	gen `var'_lag1 = `var'[_n-1]
}

set linesize 225
g d_b00_t_pct = d_b00_t/b00_t

reg d_b00_t_pct b00_g_lag1 b00_t_lag1
reg d_b00_t_pct b00_g_pct_lag1

* ROBUSTNESS: NO NON-LINERAITY 
reg d_b00_t_pct b00_g_pct_lag1 b00_t_lag1




*****************************************************
* Preventative  Analysis 
*****************************************************

/*
#delimit ;
graph bar (mean) c01_g_pct, ///
	over(id_period_m)
	ytitle("Penta 3, Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr

#delimit ;
graph bar (mean) c05_t c05_g, ///
	over(id_period_m)
	ytitle("PNC, Cases according to guildlines, %") 

	;
	
* (median) c05_t (p25) c05_t (p75) c05_t
graph bar (mean) c05_g c05_t (median) c05_g c05_t , ///
	over(id_period_m)
	ytitle("PNC, Cases according to guildlines, %") 

	;	
	
#delimit cr

#delimit ;
graph bar (mean)  c08_g_pct, ///
	over(id_period_m)
	ytitle("Implant, Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr

STOP



bys id_period_m: su c01_g_pct c05_g_pct c06_g_pct c08_g_pct

#delimit ;
graph bar (mean) c01_g_pct , ///
	over(id_period_m)
	ytitle("Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr

#delimit ;
graph bar (mean) c05_g_pct , ///
	over(id_period_m)
	ytitle("Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr

#delimit ;
graph bar (mean) c06_g_pct , ///
	over(id_period_m)
	ytitle("Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr

#delimit ;
graph bar (mean) c08_g_pct , ///
	over(id_period_m)
	ytitle("Cases according to guildlines, %") 
	ylabel(0(10)100) ymtick(0(10)100) 
	;
#delimit cr
*/


