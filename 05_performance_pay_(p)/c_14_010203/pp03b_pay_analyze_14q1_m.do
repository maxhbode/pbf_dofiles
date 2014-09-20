/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Feb 2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set linesize 225

* Install value Labels
run "$DO/01c_valuelabels_graphs.do"

* Period name
loc period 14_010203

*---------------------------------------------------
* Graph Options
*---------------------------------------------------

* Stop graphs
loc GRAPHS 0

* Choose format: pdf or png
loc format pdf

* Choose color scheme: s2color or s2mono
loc scheme s2color 
set scheme `scheme'  

* General Graph Options

* General Graph Options
#delimit ;
loc graphoptions1
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(horizontal)) missing
		blabel(bar, color(gs14) position (inside) format(%9.0fc))
		;
loc graphoptions2
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5) 
		ylabel(, angle(horizontal)) missing
		blabel(bar, color(gs14) position (inside) orientation(vertical) format(%9.0fc))
		;
#delimit cr

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

************************************************************************
* Graph
************************************************************************

u "$CLEAN/performance pay/`period'/pp03_analysis(pay_m)", clear

sort pp_r_phcu_m

#delimit ;
* GRAPH #1 ;
graph hbar pp_r_phcu_m if id_zone==1, 
	over(id_phcu_name, sort(pp_r_phcu_m)) ytitle("Realized PP/Potential PP (all quality), %") 
	title(Realized as percentage of Potential Performance Pay)  
	`graphoptions1' ;
di "$GRAPH/`folder'/performance pay/`period'/m_potentialvsreal_usd.`format'" ;
graph  export "$GRAPH/`folder'/performance pay/`period'/pay_m_1_potentialvsreal_pct.`format'", replace ;

* GRAPH #2 ;
graph bar (mean) pp_v_phcu_m_usd  pp_p_phcu_m_usd, over(id_period_ym, label(angle(forty_five))) over(id_zone) 
	ytitle(USD) title(Average PHCU Performance Pay)
	`graphoptions2'  legend(on order(1 "Verifiable" 2 "Potential (all quality)"))
	;
graph  export "$GRAPH/`folder'/performance pay/`period'/pay_m_2_potentialvsreal_usd.`format'", replace ;

* GRAPH #3 ;
graph bar (mean)  pp_v_phcu_m_tzs  pp_p_phcu_m_tzs, over(id_period_ym, label(angle(forty_five))) over(id_zone) 
	ytitle(TZS) title(Average PHCU Performance Pay)
	legend(on order(1 "Verifiable" 2 "Potential (all quality)")) `graphoptions2' 
	;
graph  export "$GRAPH/`folder'/performance pay/`period'/pay_m_3_potentialvsreal_tzs.`format'", replace ;

* GRAPH #4 ;
graph bar (mean) pp_r_phcu_m, over(id_period_ym, label(angle(forty_five))) over(id_zone) 
	yscale(range(0 100)) ytitle(%) ylabel(#10) `graphoptions2' 
	title(Average Verifiable/Potential Performance Pay)
	;
graph  export "$GRAPH/`folder'/performance pay/`period'/pay_m_4_potentialvsreal_ratio.`format'", replace ;
#delimit cr

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Notes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
