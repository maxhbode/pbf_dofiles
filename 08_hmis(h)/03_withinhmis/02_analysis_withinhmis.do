set linesize 225

*************************************************************************
* Define macros
*************************************************************************


#delimit ;
loc graphoptions
		graphregion(fcolor(white) lcolor(white) ilcolor(white))
		xsize(9) ysize(5.5)
		ylabel(, angle(horizontal)) missing
		;
#delimit cr

*************************************************************************

cap: program drop prepost
program define prepost
g prepost = 0
replace prepost = 1 if id_period_yymm>1306
la de prepostl 0 "before" 1 "after"
la val prepost prepostl
end


*************************************************************************

u "$CLEAN/hmis/clean", clear
drop if id_period_yymm==1405

* OPD
*--------------------------------------------
/*
preserve
keep id* opd* treatment prepost
drop id_district_name	id_district_name_swahili id_period_ym


*graph bar (sum) opd_headcount_new, over(treatment) over(id_period_yymm)  ///
*	`graphoptions' ytitle("OPD headcount")


* Collapse
collapse (sum) opd_headcount_new, by(treatment id_period_yymm)
reshape wide opd_headcount_new, i(id_period_yymm) j(treatment)
prepost

* Graph 
g opd_headcount_new_all = opd_headcount_new1 + opd_headcount_new0
g opd_headcount_new_ratio = opd_headcount_new1*100/opd_headcount_new_all
graph bar opd_headcount_new_ratio, over(id_period_yymm) ///
	ytitle("OPD headcount treatment/control, %")
graph bar opd_headcount_new_ratio, over(prepost) ///
	ytitle("OPD headcount treatment/control, %") blabel(opd_headcount_new_ratio)
restore
*/
* ANC
*--------------------------------------------

* 1st visit before 16 weeks/overall first visits
g anc_1stvisitbefore16w_pct = anc_1stvisitbefore16/anc_visit1
bys treatment prepost: su anc_1stvisitbefore16w_pct
keep id* anc_1stvisitbefore16w_pct treatment 



collapse (mean) anc_1stvisitbefore16w_pct, by(treatment id_period_ym)
reshape wide anc_1stvisitbefore16w_pct, i(id_period_ym) j(treatment)
tsset id_period_ym

g n = _n
loc m1 1
loc m2 2
loc m3 3

g quarter=.
forval i = 1/6 {
	di `m1' `m2' `m3'
	replace quarter=`i' if inlist(n,`m1',`m2',`m3')
	
	loc m1 = `m1' + 3
	loc m2 = `m2' + 3
	loc m3 = `m3' + 3
}
drop n 
drop if quarter==6 

collapse (mean) anc_1stvisitbefore16w_pct*, by(quarter)


tsset quarter
twoway (tsline anc_1stvisitbefore16w_pct0) (tsline anc_1stvisitbefore16w_pct1), tline(3)
stop



stop
diff anc_1stvisitbefore16w_pct, period(prepost) treated(treatment) robust

clear 
set obs 2 
g id_t = 0 in 1
replace id_t = 1 in 2
g treatment = `r(mean_t0)' in 1 
replace treatment = `r(mean_t1)' in 2
g control = `r(mean_c0)' in 1
replace control = `r(mean_c1)' in 2
g treatmenteffect = .
replace treatmenteffect = `r(did)' in 2
  


  r(mean_t1) 

stop


* ANC Visit 4 / ANC Visit 1
g anc_visit4_pct = anc_visit4/anc_visit1
bys treatment prepost: su anc_visit4_pct

* FPL Implant insert 
*--------------------------------------------
bys treatment prepost: su fp_implantinsertion





