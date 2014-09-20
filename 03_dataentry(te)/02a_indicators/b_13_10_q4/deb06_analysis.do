

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

la var b00_g "OPD Consultation, according to guidlines"


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

