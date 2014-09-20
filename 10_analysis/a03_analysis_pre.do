
*****************************************************
* Define program
*****************************************************
/*
cap: program drop wraptitle
program define wraptitle, rclass

syntax , title(string)

		loc ll 32 //sets the length of the title
		
		di as result "`title'"
		loc len = length("`title'")
		di "`len'"
		loc newtitle
		
		if `len' > `ll' {
			loc pieces "`=ceil(`len'/`ll')'"
			forval p = 1/`pieces' {
				loc p`p' : piece `p' `ll' of "`title'", nobreak
				di "`p' - `p`p''"
				return local newtitle `" `title'  `"`p`p'' "'   "'
			}
		}
	
		*di `" `newtitle' "'
		
		*return local newtitle `"`" `newtitle' "'"'

end
*/		
		
*****************************************************
* Graph Options
*****************************************************

* Set globals for working in DOFILE
global FORMAT pdf
global SCHEME s2color 

* Choose format: pdf or png
loc format $FORMAT

* Choose color scheme: s2color or s2mono
loc scheme $SCHEME  
set scheme `scheme' 

* General Graph Options
#delimit ;
loc graphoptions1
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(45)) missing
		blabel(bar, color(gs14) position (inside) format(%9.0fc))
		;
loc graphoptions2
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(45)) missing
		blabel(bar, color(gs14) position (inside) orientation(vertical) format(%9.0fc))
		;		
#delimit cr


* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

*****************************************************
* Data preparation for graphs
*****************************************************

u "$CLEAN/tc_05(label)", clear

* Install value Labels
do "$DO/01b_all_value_labels.do"

la val id_period_mm months


* Limit to PBF districts
*****************************************************
keep if treatment==1
ta  id_district id_zone

* Drop non-eligble facilities (without preventative)
list id_phcu id_phcu_name if c0_section_skip==1
drop if c0_section_skip==1 
drop c0_section_skip

* PHCU count (after dropping non-eligble)
cb id_zone
ta id_period_mm id_zone // Pemba = 16, Unguja = 12

ta id_period_mm id_zone
la de zonel 1 "Mkoani (12/15 PHCUs)" 2 "West", replace 

* Drop Outpatient section
fn b*, remove(b07* b08*)
drop `r(varlist)'

* Short version 
la var c01_t "Penta 3"
la var c02_t "Tetanus vaccinations"
la var c03_t "ANC standard visits 4"
la var c04_g "1st ANC visit within 16 weeks"

la var c03_t "4 standard ANC visits"
la var c03_g "4 standard ANC visits evenly spaced"
la var c04_t "1st ANC visits"
la var c04_g "1st ANC visits within 16 weeks"

la var c05_t "PNC"
la var c06_t "Facility Deliveries"
la var c07_t "Family Planning consultation"
la var c08_t "Implant"
la var c09_t "Deworming (12-49 months old)"
la var c10_t "Vitamin A (6-49 months old)"
la var c11_t "Mosquito net for pregnant women"
la var b07_t "PMTCT"
la var b08_t "Voluntary HIV counselling & test"

tempfile graph_pre
sa `graph_pre', replace

*****************************************************
* Preventative  Analysis 
*****************************************************

u `graph_pre', clear

* Drop variables
*fn *g *g_pct *v* *nv*, remove(c03_g c04_g)
*drop `r(varlist)' 

su c*

* Label variables

run "$DO/01b_all_value_labels.do"
la val id_period_ym id_period_yml
cb id_period_ym


*----------------------
* PER TOPIC
*----------------------

* Immunization
loc tetanus c02_t 

* Pregnancy
*loc pregnancy01 c03_t c03_g 

loc pregnancy1 c03_t c04_g c05_t 
loc pregnancy3 c04_g c05_t c01_t 
loc pregnancy4 c04_t c04_g 
loc pregnancy5 c05_t c05_g 




* Family planning
loc famplan c07_t c08_t 

* Nutrition
loc nutrition c09_t c10_t

* AIDS/HIV
loc hiv1 b07_t b08_t
loc hiv2 b08_t 

* Delivery
loc delivery1 c06_t c11_t c01_t
loc delivery2 c06_t
loc delivery3 c06_t c11_t

* Mosquito 
loc malaria c11_t


*-----------------------------------------------------------------------
* Starting Loop
*-----------------------------------------------------------------------

foreach variation in b  {
* b - both 
* c - comparison 
* w - west 
* m - mkoani

preserve
	loc titleadd

	if "`variation'"=="m" {
		keep if id_zone==1
		loc titleadd "in Mkoani"
	}
	else if "`variation'"=="w" {
		keep if id_zone==2
		loc titleadd "in West"
	}
	else if inlist("`variation'","b","c") {
		loc titleadd "in West and Mkoani"
	}

	foreach cluster in  pregnancy5 {
	* tetanus hiv1 hiv2 malaria  nutrition  delivery1 delivery2  pregnancy3 pregnancy4    famplan {
	
		if inlist("`cluster'","tetanus","hiv1","hiv2","malaria","nutrition")  loc IF "if id_period_ym>1305"
		else loc IF
		*** 
		
	
		di as error "`cluster'"
		su ``cluster'' if id_period_ym==1305 | id_period_ym==1304

	
		* ???
		loc varcount : word count ``cluster''
		di as error "`variation' - `varcount' - `cluster'"
		
		* Create legend & variable label
		loc i 0
		loc legend
		foreach var in ``cluster'' {
			loc ++i
			loc label `"`: var label `var''"'
			loc label `""`label'""'
			loc newlabel `i' `label'
			loc legend `legend' `newlabel' 
		}
		
		if `varcount'==1 {
			loc legendplug
			loc label1 `"`: var label ``cluster'''"'
			loc title "Headcount: `label1' `titleadd'"
		}
		
		else if `varcount'>1 {
			loc legendplug "legend(on order(`legend'))"
			loc label1 
			loc title "Headcounts `titleadd'"
		}
		
		
		*-----------------------------------------------------------------------
		* Wrap title
		*-----------------------------------------------------------------------
		
		loc ll 32 //sets the length of the title
		
		di as result "`title'"
		loc len = length("`title'")
		di "`len'"
		loc newtitle
		
		if `len' > `ll' {
			loc pieces "`=ceil(`len'/`ll')'"
			forval p = 1/`pieces' {
				loc p`p' : piece `p' `ll' of "`title'", nobreak
				di "`p' - `p`p''"
				loc newtitle `" `newtitle'  `"`p`p'' "'   "'
			}
		}
	
		di `" `newtitle' "'

		*-----------------------------------------------------------------------
		* Adding zone comparison and turning the time labels vertical
		*-----------------------------------------------------------------------
		if "`variation'"=="c" & `varcount'==1  {
			loc graphspec over(treatment_temporal) over(id_period_ym, label(angle(45))) over(id_zone) 
			loc graphoptions `graphoptions2'
		}
		if "`variation'"=="c" & `varcount'>1  {
			loc graphspec over(id_period_ym, label(angle(45))) over(id_zone)
			loc graphoptions `graphoptions2' 
		}

		if "`variation'"!="c" & `varcount'==1 {
			loc graphspec over(id_period_ym, label(angle(45))) over(treatment_temporal)  
			loc graphoptions `graphoptions1'   
		}		
		
		if "`variation'"!="c" & `varcount'>1 {
			loc graphspec over(id_period_ym, label(angle(45))) over(treatment_temporal) 
			loc graphoptions `graphoptions2' legend(on order(`legend'))		
		}
		
		graph bar (sum) ``cluster'' `IF', `graphspec' `graphoptions'  nofill ///
			ytitle(`newtitle') `legendplug' 
		graph export "$GRAPH/`folder'/preventative/topic_`cluster'_`variation'.`format'", replace 
	
	}  
	
	

restore	
}


/*
* Number of cases
fn c*
foreach var in `r(varlist)' { 
	loc label `"`: var label `var''"'

	graph bar (sum) `var', over(id_period_m)  ytitle("`label'") 	
	graph export "$GRAPH/preventative/pre_`var'.pdf",replace 
}	

*----------------------
* PER TREND
*----------------------

* Positive, Neutral, Negative Development
loc positive c07_t c08_t c09_t c10_t c11_t c12_t
loc neutral c01_t c02_t c03_t c05_t
loc negative c04_t c06_t c13_t

foreach cluster in positive negative neutral {

	* Create legend 
	loc i 0
	loc legend
	foreach var in ``cluster'' {
		loc ++i
		loc label `"`: var label `var''"'
		loc label `""`label'""'
		loc newlabel `i' `label'
		loc legend `legend' `newlabel' 
	}

	* Create graphs
	graph bar (sum) ``cluster'', over(id_period_m)  ///
	ytitle("Number of cases") legend(on order(`legend'))
	graph export "$GRAPH/preventative/pre_c_trend_`cluster'.pdf",replace 
}

*/

********************************************************************************
********************************************************************************
********************************************************************************

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


