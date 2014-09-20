

u "$TEMP/subsidybyphcu(s_phcu_04)", clear

/******************************************************
* Bonus per worker
*******************************************************

* Pay scale vs. Cadre
*------------------------------
      Position Job ID | B. Salary |     Total
----------------------+-----------+----------

                  AMO |         7 |         1 
                  
     Clinical Officer |         6 |         1 
Community Health Nurs |         6 |         8 

    Pharm. Technician |         5 |         2 
           Pharmacist |         5 |         1
        Nurse General |         5 |         2 
        Nurse Midwife |         5 |        16 
   Nurse Psychiatrist |         5 |         8            
       Health Officer |         5 |         7 
      Lab. Technician |         5 |         9        
       
       Lab. Assistant |         2 |         1 
             Mch Aide |         2 |         8 
     Pharm. Assistant |         2 |         2 
     Pharm. Dispenser |         2 |         3 
     Health Assistant |         2 |         1 
          
              Orderly |         1 |        40
         Special Gang |         1 |         1 
        Support Staff |         1 |         2 
             Watchman |         1 |         3 
******************************************************/


* Merge
*---------------------------------------

u "$TEMP/pay_m(s_phcu_04)", clear

g id_period_m = substr(id_phcu_ym_s,11,2)
destring id_period_m, replace
g id_zone = substr(id_phcu_ym_s,1,1)
destring id_zone, replace



/*
* ONLY DO UNGUJA

keep if id_zone==2
ta id_zone
drop id_zone
*/
sort id_phcu_ym_s
*br id_phcu_ym_s pp_phcu_total_m_tzs pp_df_total_m_tzs pp_pif_total_m_tzs  
*if id_phcu_s=="1-3-07" 
*!!!!!!!!!!!!!!!!!!!


merge 1:m id_phcu_ym using  "$CLEAN/staff_long", nogen

* ONLY DO UNGUJA
*keep if id_zone==2
ta id_zone
drop id_zone

ta hw_jobid

* Order Sort
sort id_hw
order id* id_hw* t_period

* Attendance by facility
replace hw_attend=0 if id_hw==130802 & t_period==7
replace hw_attend=2 if id_hw==130704 & t_period==7

set linesize 225
sort id_phcu_name  id_hw
*br id_phcu id_phcu_name t_period id_hw  hw_name_first hw_name_second hw_name_third ///
*	hw_name_sur hw_name_sur hw_jobid_s hw_salarylevel  hw_attend, nolabel



*!!!!!!!!!!!!!!!!!!!


* Drop vars
*---------------------------------------
drop pp_a* pp_b* hw_sex

* Percentage of facility income allocated to individual:
*---------------------------------------
clonevar hw_salarylevel_org = hw_salarylevel
replace hw_salarylevel= hw_salarylevel
bys id_phcu_ym: g temp_phcu_totalsalary = sum(hw_salarylevel)
bys id_phcu_ym: egen phcu_totalsalary = max(temp_phcu_totalsalary)
g hw_salary_pctofphcu = hw_salarylevel/phcu_totalsalary

* test (adding all percentages together)
bys id_phcu_ym: g temp_test = sum(hw_salary_pctofphcu)
bys id_phcu_ym: egen temp_test2 = max(temp_test)
bys id_phcu_ym: replace temp_test2 = round(temp_test2,.00000000000001)
ta temp_test2 // --> test past if all == 1
drop temp*

* Percentage of facility income allocated to individual:
* ADJUSTED FOR ABSTENTISM 
*---------------------------------------
g multiplier = 0 
replace multiplier = 1 if hw_attend==0 | hw_attend==1

g hw_salarylevel_adjusted = hw_salarylevel*multiplier
bys id_phcu_ym: g temp_phcu_totalsalary_adjusted = sum(hw_salarylevel_adjusted)
bys id_phcu_ym: egen phcu_totalsalary_adjusted = max(temp_phcu_totalsalary_adjusted)
g hw_salary_pctofphcu_adjusted = hw_salarylevel_adjusted/phcu_totalsalary_adjusted

ta phcu_totalsalary_adjusted 

* test (adding all percentages together)
bys id_phcu_ym: g temp_test = sum(hw_salary_pctofphcu_adjusted)
bys id_phcu_ym: egen temp_test2 = max(temp_test)
bys id_phcu_ym: replace temp_test2 = round(temp_test2,.00000000000001)
ta temp_test2 // --> test past if all == 1
drop temp* // --> WHOLE HEALTH FACILITIES MISSED MONTHS AT A TIME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

* Making some observations 
*---------------------------------------
sort id_phcu  hw_salary_pctofphcu

* Percentage of facility income allocated to individual by cadre
bys hw_salarylevel: su hw_salary_pctofphcu // the low % for AMCs is a product of staff/patient ratio

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

/*
sort id_phcu id_hw t_period
br id_phcu id_hw t_period hw_bonus*_m_tzs multiplier hw_salary_pctofphcu_adjusted hw_salary_pctofphcu
*/

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


STOP

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



