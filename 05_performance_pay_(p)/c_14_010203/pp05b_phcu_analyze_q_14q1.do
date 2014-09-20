/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Jun 4 2014

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
#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
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

u "$CLEAN/performance pay/`period'/`period'/pp04a_(pif_q)", clear

#delimit ;
graph hbar pp_v_phcu_q_tzs6 pp_p_phcu_q_tzs6 if id_zone==1, over(id_phcu_name, 
	sort(pp_v_phcu_q_tzs6)) 
	ytitle(Million TZS) 
	legend(on order(1 "Verifiable" 2 "Potential (all quality)"))
	`graphoptions' ylabel(#10) ;
#delimit cr
* title(2014 Quarter 1: Performance Pay per Facility (Mkoani, Pemba))
graph export "$GRAPH/`folder'/performance pay/`period'/2014_q1_pp_byfacility_pemba.`format'", replace

#delimit ;
graph hbar pp_v_phcu_q_tzs6 pp_p_phcu_q_tzs6 if id_zone==2, over(id_phcu_name, 
	sort(pp_v_phcu_q_tzs6)) 
	ytitle(Million TZS) 
	legend(on order(1 "Verifiable" 2 "Potential (all quality)"))
	`graphoptions' ylabel(#10) ;
#delimit cr
* title(2014 Quarter 1: Performance Pay per Facility (West, Unguja)) 
graph export "$GRAPH/`folder'/performance pay/`period'/2014_q1_pp_byfacility_unguja.`format'", replace
	

