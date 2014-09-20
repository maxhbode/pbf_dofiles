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

*************************************************************************
* Reshape wide
*************************************************************************

u "$CLEAN/performance pay/`period'/pp03a_foranalysis(dif_q)", clear
 
*************************************************************************
* Analysis
*************************************************************************

g hw_r_bonus_tzs3_13q4=hw_r_bonus_tzs_13q4/10^3
g hw_p_bonus_tzs3_13q4=hw_p_bonus_tzs_13q4/10^3

sort id_phcu  hw_salarylevel

*--------------------------------------------
* Proportion: PBF Bonus vs. Salary
*--------------------------------------------

la de salarylevell 7 "Advanced Diploma" 6 "Diploma (Prescriber)" ///
	5 "Diploma" 3 "Certificate (PHNB)" 2 "Certificate" 1 "(Below) Form IV"
la val hw_salarylevel salarylevell

g hw_startingsalary_byq=.
replace hw_startingsalary_byq=934000*3 if inlist(hw05_cadre_code,20,21)replace hw_startingsalary_byq=465000*3 if inlist(hw05_cadre_code,30,31,32)replace hw_startingsalary_byq=299000*3 if inlist(hw05_cadre_code,40,41,42,43,44,45)replace hw_startingsalary_byq=209000*3 if inlist(hw05_cadre_code,50,60,61,62,63,64,65)replace hw_startingsalary_byq=160500*3 if inlist(hw05_cadre_code,70)

g hw_bonussalaryratio = hw_r_bonus_tzs_13q4*100/hw_startingsalary_byq
la var hw_bonussalaryratio "Bonus as proportion of starting salary (%)"

bys hw_salarylevel: su hw_bonussalaryratio

*loc note "Advanced Diploma: AMO, PHNA; Diploma (Prescriber): CO, CHN, Dental Technician; Diploma:  Pharm. Technician, N. General, N. Midwife, N. Psychiatrist, EHO, Lab. Technician"


graph hbox hw_bonussalaryratio, over(hw_salarylevel, descending) ///
	title("2013 Q4: Bonus as proportion of starting salary (%)") ///
	`graphoptions'  

graph hbox hw_bonussalaryratio, over(hw05_cadre_code, descending)  ///
	title("2013 Q4: Bonus as proportion of starting salary (%)") ///
	`graphoptions' 

*--------------------------------------------
* Percentage of facility income allocated to individual by cadre
*--------------------------------------------
graph hbar (mean) hw_r_bonus_tzs3_13q4 hw_p_bonus_tzs3_13q4, over(hw_salarylevel)  ///
	ytitle(Thousand TZS) `graphoptions' ///	legend(on order(1 "Realized average bonus" 2 "Potential average bonus")) ///
	title("2014 Q1 - Average Performance Pay per Salary Level")
graph  export "$GRAPH/`folder'/performance pay/`period'/bonus_bysalarylevel.`format'", replace

*--------------------------------------------
* Realized vs. Potential Income by cadre
*--------------------------------------------
graph hbar (mean) hw_r_bonus_tzs3_13q4 hw_p_bonus_tzs3_13q4,  ///
	over(hw05_cadre_code) ///
	ytitle(Thousand TZS) `graphoptions' ///
	legend(on order(1 "Realized average bonus" 2 "Potential average bonus")) 
*title("2014 Q1 - Average Performance Pay per Cadre")
graph  export "$GRAPH/`folder'/performance pay/`period'/bonus_bycadre.`format'", replace		
	
graph hbar (mean) hw_r_bonus_tzs3_13q4 hw_p_bonus_tzs3_13q4 if id_zone==1,  ///
	over(hw05_cadre_code)  ///
	ytitle(Thousand TZS) `graphoptions' ///
	legend(on order(1 "Realized average bonus" 2 "Potential average bonus")) 
*title("2014 Q1 - Average Performance Pay per Cadre")
graph  export "$GRAPH/`folder'/performance pay/`period'/bonus_bycadre_pemba.`format'", replace		

graph hbar (mean) hw_r_bonus_tzs3_13q4 hw_p_bonus_tzs3_13q4 if id_zone==2, ///
	over(hw05_cadre_code)  ///
	ytitle(Thousand TZS) `graphoptions' ///
	legend(on order(1 "Realized average bonus" 2 "Potential average bonus")) 
*title("2014 Q1 - Average Performance Pay per Cadre")
graph  export "$GRAPH/`folder'/performance pay/`period'/bonus_bycadre_unguja.`format'", replace		
	


/*
* Number of health staff by cadre
bys id_phcu: g phcu_staff_N = _N
su phcu_staff_N
bys hw_salarylevel: su phcu_staff_N

*br id_hw hw_positionjobid  id_phcu_name  id_phcu verification_period_m hw_salary_pctofphcu hw_salarylevel phcu_totalsalary

* Bonus per health worker per month
*---------------------------------------
foreach currency in tzs usd {
	g hw_bonus_m_`currency' = hw_salary_pctofphcu*pp_df_total_m_`currency'
	g hw_bonus_adjusted_m_`currency' = hw_salary_pctofphcu_adjusted*pp_df_total_m_`currency'
}

* Bonus per health worker per quarter
*---------------------------------------
foreach currency in tzs usd {
if "`currency'"=="tzs" loc round 1
if "`currency'"=="usd" loc round 0.01

	bys id_hw: g temp_hw_bonus_q_`currency'=sum(hw_bonus_m_`currency')
	bys id_hw: egen hw_bonus_q_`currency'=max(temp_hw_bonus_q_`currency')
	
	bys id_hw: g temp_hw_bonus_adjusted_q_`currency'=sum(hw_bonus_adjusted_m_`currency')
	bys id_hw: egen hw_bonus_adjusted_q_`currency'=max(temp_hw_bonus_adjusted_q_`currency')	
	
	replace hw_bonus_q_`currency' = round(hw_bonus_q_`currency',`round')
	replace hw_bonus_adjusted_q_`currency' = round(hw_bonus_adjusted_q_`currency',`round')
}

bys id_hw: g n = _n
drop if n!=1

keep id* *bonus_q* *bonus_adjusted_q* hw_salarylevel hw_name* hw_jobid
drop temp*

* Bonus / Salary test 
*---------------------------------------
sort id_phcu hw_salarylevel
*br id_phcu id_phcu_name hw_cadre hw_salarylevel hw_salary_pctofphcu hw_bonus_usd pp_df_total_usd
set linesize 200

univar hw_bonus_q_usd
*univar hw_bonus_q_usd, byvar(hw_salarylevel)

bys hw_salarylevel: su hw_bonus_q_usd
bys id_zone: su hw_bonus_q_usd

bys hw_salarylevel: su hw_bonus_adjusted_q_usd
bys id_zone: su hw_bonus_adjusted_q_usd

la de salarylevell 7 "AMO" 6 "CO, CHN" 5 "Nurses" 3 "PHNB" 2 "Med. Assistance" 1 "Non-med. staff"
la val hw_salarylevel salarylevell

format hw_bonus_adjusted_q_tzs %15.0fc
graph hbar (median) hw_bonus_adjusted_q_tzs, over(hw_salarylevel)  ///
	ytitle(TZS) ylabel(, angle(horizontal)) ///
	xsize(9) ysize(5.5) graphregion(fcolor(white) lcolor(none) ilcolor(none)) ///
	legend(on order(1 "average bonus per cadre")) ///
	title("1st Quarter Performance Pay per Cadre Level")
	
graph  export "$GRAPH/performance_pay_bonus.png", replace


* hw_bonus_q_tzs


* Export to excel
*---------------------------------------
* ONLY PRINT PEMBA
*keep if id_zone==1
ta id_zone_name
drop id_zone id_zone_name

sort id_phcu id_hw hw_salarylevel
fn id_phcu_name id_phcu_s hw_name* hw_jobid  hw_bonus_q_tzs hw_bonus_q_usd  hw_bonus_adjusted_q_tzs hw_bonus_adjusted_q_usd , loc(vars) 
keep `vars'
order `vars'
export excel using "$ANALYSIS/outputs/payments/bonuses_q1", replace nolabel firstrow(var) 

drop *usd 
foreach var in hw_bonus_q_tzs hw_bonus_adjusted_q_tzs {
	replace `var' = round(`var',100)
}

* Calcuate change need
g temp_bill_10000 = hw_bonus_adjusted_q_tzs/10000
g bill_10000 = round(temp_bill_10000,1)
replace bill_10000 = bill_10000-1 if bill_10000>temp_bill_10000
g newvalue1 = hw_bonus_q_tzs - bill_10000*10000

loc i=1
foreach val in 5000 1000 500 100 {
	
	g temp_bill_`val' = newvalue`i'/`val'
	g bill_`val' = round(temp_bill_`val',1)
	replace bill_`val' = bill_`val'-1 if bill_`val'>temp_bill_`val'
	loc j = `i' + 1
	g newvalue`j' = newvalue`i' - bill_`val'*`val'
	loc ++i
}

drop temp* newvalue*

export excel using "$ANALYSIS/outputs/payments/bonuses_q1_tzsonlyround", replace nolabel firstrow(var) 



