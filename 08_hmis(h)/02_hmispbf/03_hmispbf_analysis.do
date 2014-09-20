set linesize 225

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
		ylabel(, angle(horizontal)) missing
		blabel(bar, color(gs14) position (inside) format(%9.0fc))
		;
loc graphoptions1b
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(horizontal)) missing
		blabel(bar, color(gs14) position (inside) format(%9.1fc))
		;
loc graphoptions2
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(horizontal)) missing
		blabel(bar, color(gs14) position (inside) orientation(vertical) format(%9.0fc))
		;
loc graphoptions3
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(horizontal)) missing
		blabel(group, size(vsmall) color(orange) position(base))		
		;				

loc graphspec over(id_period_ym) over(treatment) nofill
		;
#delimit cr

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

*************************************************************************
* Comparison between HMIS and PBF data
*************************************************************************

foreach varcat in pnc1 pnc2 {
* opd sopd mva penta3 pnc1 pnc2 anc4 anc16 fpconsul implant

u "$CLEAN/hmis/clean_merge", clear

if inlist("`varcat'","opd","sopd","mva") {
	keep if b0_section_skip==0
}
else {
	keep if c0_section_skip==0
}

if "`varcat'"=="opd"	{
	local var_pbf	b000_t
	local var_hmis	hmis_opd_headcount_new
}
if "`varcat'"=="sopd"	{
	local var_pbf	b03_t
	local var_hmis	hmis_opd_special
}
if "`varcat'"=="mva"	{
	local var_pbf	b06_t 
	local var_hmis	hmis_mva 
}
if "`varcat'"=="penta3"	{
	local var_pbf	c01_t 
	local var_hmis	hmis_penta_dose3 
}
if "`varcat'"=="pnc1" {
	local var_pbf	c05_t
	local var_hmis	hmis_pnc_total
}
if "`varcat'"=="pnc2" {
	local var_pbf	c05_g
	local var_hmis	hmis_pnc_within2days
}
if "`varcat'"=="anc4"	{
	local var_pbf	c03_t 
	local var_hmis	hmis_anc_visit4 
}
if "`varcat'"=="anc16"	{
	local var_pbf	c04_g 
	local var_hmis	hmis_anc_1stvisitbefore16w 
}
if "`varcat'"=="fpconsul"	{
	local var_pbf	c07_t 
	local var_hmis	hmis_fp_headcount
}
if "`varcat'"=="implant"	{
	local var_pbf	c08_t 
	local var_hmis	hmis_fp_implantinsertion 
}

* Exctracting label
loc varlabel = `"`: var label `var_pbf''"'
loc varlabel : subinstr loc varlabel "PBF: " ""
di "`varlabel'"

	* CALCULATE: Missing data analysis
	*--------------------------------
	foreach var in `var_pbf' `var_hmis' {
		g mv_`var' = 0
		replace mv_`var'=1 if `var'>=.
		la val mv_`var' yesnol
		ta mv_`var' 
		list id_phcu id_phcu_name id_period_yyyy id_period_mm mv_`var' ///
			if mv_`var'==1
		ta id_period_ym if  mv_`var'==1
	}
	
	* GRAPH #1: Missing
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	di as error "GRAPH #1"
	
	#delimit ;
		graph bar (sum) mv_`var_pbf' mv_`var_hmis', 
			ytitle("Missing `varlabel': Mkoani & West") cw
			legend(on order(1 "PBF" 2 "HMIS")) 
			`graphspec' `graphoptions2' ;
	#delimit cr	
	graph export "$GRAPH/`folder'/pbf-hmis comparison/`varcat'_1_missing_by_ym.`format'",replace 
	
	* MANIPULATE: missing
	*--------------------------------
	g missing = 0
	replace missing =1 if mv_`var_pbf'==1 | mv_`var_hmis'==1
	ta missing
	dropmiss  `var_pbf' `var_hmis', force any obs
	ta missing
	drop missing

	* GRAPH #2: totals
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	di as error "GRAPH #2"

	#delimit ;
		graph bar (sum) `var_pbf' `var_hmis', 
			ytitle("`varlabel': Mkoani & West") cw
			legend(on order(1 "PBF" 2 "HMIS")) 
			`graphspec' `graphoptions2' ;
	#delimit cr
	graph export "$GRAPH/`folder'/pbf-hmis comparison/`varcat'_2_totals_by_ym.`format'",replace 	
	
	* COLLAPSE & CALCULATE: average monthly error 
	*--------------------------------		
	* ---> BE CAREFUL WITH MISSING WHEN YOU COLLAPSE
	preserve
	collapse (sum) `var_pbf' `var_hmis', by(id_period_ym treatment) 
	g `var_pbf'_diffpct = .
	replace `var_pbf'_diffpct = (`var_pbf'-`var_hmis')/`var_hmis'*100 ///
		if `var_pbf'<. & `var_hmis'<.

	* GRAPH #3: average error by Month
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	di as error "GRAPH #3"
	
	#delimit ;
	graph bar `var_pbf'_diffpct, 
		ytitle("Average monthly error: PBF/HMIS `varlabel' (%) - Mkoani & West") cw  
		`graphspec' `graphoptions1b' ;
	#delimit cr
	graph export "$GRAPH/`folder'/pbf-hmis comparison/`varcat'_3_avg_error_by_ym.`format'", replace 	
	restore 
	
	* CALCULATE: absolute montly error for sorting 
	*--------------------------------
	g `var_pbf'_diffpct = .
	replace `var_pbf'_diffpct = (`var_pbf'-`var_hmis')/`var_hmis'*100 ///
		if `var_pbf'<. & `var_hmis'<.
	
	g  `var_pbf'_diffpct_abs = abs(`var_pbf'_diffpct)
	bys id_phcu: egen `var_pbf'_diffpct_abssum = sum(`var_pbf'_diffpct_abs)
	
	* GRAPH #4: monthly error distribution:  pbf vs. hmis headcount
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			
	di as error "GRAPH #4"
	
	#delimit ;
	graph hbox `var_pbf'_diffpct, over(id_phcu_name, sort(`var_pbf'_diffpct_abssum)) `graphoptions3' ///
	 	ytitle("Monthly Error: PBF vs. HMIS `varlabel' (%) - Mkoani & West (06/'13-03/'14)") ///
	 	 cw ylabel(#10) ymtick(##10) ;
	#delimit cr
	* ylabel(-100(20)150) ymtick(##2)	
	graph export "$GRAPH/`folder'/pbf-hmis comparison/`varcat'_4_error_dist_by_phcu_ym.`format'", replace	
	
	* CALCUALTE: monthly average error rate - Percentage difference between PBF and HMIS
	*--------------------------------
	preserve
	collapse  `var_pbf' `var_hmis', by(id_phcu id_phcu_name)
	g `var_pbf'_diffpct = .
	replace `var_pbf'_diffpct = (`var_pbf'-`var_hmis')/`var_hmis'*100 ///
		if `var_pbf'<. & `var_hmis'<. 
	
	* GRAPH #5: average Monthly Error: PBF vs. HMIS headcount (%) - Mkoani & West (06/2013-03/2014)
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	di as error "GRAPH #5"
	
	#delimit ;
		graph hbar (mean) `var_pbf'_diffpct, 
			cw over(id_phcu_name, sort(`var_pbf'_diffpct) axis(off)) 
			ytitle("Average Monthly Error: PBF vs. HMIS `varlabel' (%) - Mkoani & West (06/2013-03/2014)") 
			ylabel(#10) ymtick(##10)
			`graphoptions3' ;
	#delimit cr
	*  ylabel(-30(5)10)  ymtick(##5)
	 graph export "$GRAPH/`folder'/pbf-hmis comparison/`varcat'_5_error_avg_by_phcu_ym.`format'", replace	
	restore

}
