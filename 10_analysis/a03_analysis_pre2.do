
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
* Pre Posts
*-----------------------------------------------------------------------

	
keep if inlist(id_period_mm,4,5,6)
la de id_period_mm_prepostl 4 "April" 5 "May" 6 "June"
la val  id_period_mm id_period_mm_prepostl
codebook id_period_mm

drop id_district id_period_ym id_period_ym_s id_phcu_ym id_phcu_ym_s id_zone	



*-----------------------------------------------------------------------
* Delivery Pre Post
*-----------------------------------------------------------------------
/*
preserve 
	keep id* c06_t
	
	reshape wide c06_t, i(id_phcu id_period_mm) j(id_period_yyyy)
	
	la var c06_t2013 "Before (2013)"
	la var c06_t2014 "After (2014)"
	
	#delimit ;
	graph bar (sum) c06_t2013 c06_t2014, over(id_period_mm)  
				yscale(off) 
			graphregion(fcolor(white)  lcolor(white) ilcolor(white))
			xsize(9) ysize(5.5) 
			blabel(bar, color(gs14)  size(medlarge) position (inside)  format(%9.0fc))
			legend(order(1 "Before (2013)" 2 "After (2014)" ) rows(1))
			note("Note: Delivery Facilities in PBF districts: Fuoini, Chukwani, Kengeja, Bogoa (and Kiwani)", size(medsmall))
			;	
	#delimit cr
	
	graph export "$GRAPH/`folder'/preventative/topic_delivery_prepost.`format'", replace 
		
restore 	
*/
*-----------------------------------------------------------------------
* ANC within 16 weeks
*-----------------------------------------------------------------------
	

*preserve 
	keep id* c04_g_pct	
	
	reshape wide c04_g_pct, i(id_phcu id_period_mm) j(id_period_yyyy)
	
	la var c04_g_pct2013 "Before (2013)"
	la var c04_g_pct2014 "After (2014)"
	
	#delimit ;
	graph bar (sum) c04_g_pct2013 c04_g_pct2014, over(id_period_mm)  
				yscale(off) 
			graphregion(fcolor(white)  lcolor(white) ilcolor(white))
			xsize(9) ysize(5.5) 
			blabel(bar, color(gs14)  size(medlarge) position (inside)  format(%9.0fc))
			legend(order(1 "Before (2013)" 2 "After (2014)" ) rows(1))
			legend(order(1 "Before (2013)" 2 "After (2014)" ) rows(1))
			;	
	#delimit cr
	
	graph export "$GRAPH/`folder'/preventative/topic_anc1st_prepost.`format'", replace 
		
	collapse c04_g_pct2013 c04_g_pct2014
	
	g diff = (c04_g_pct2014-c04_g_pct2013)/c04_g_pct2013
	list diff	
		
restore 
	

