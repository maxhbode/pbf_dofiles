
*******************************************************
* Importing staff data after Mary HR and Dhameera DHMT test
*******************************************************

* Import
foreach district in mkoani west {
	insheet using "$RAW/staff/20131106_stafflist_`district'.csv", c clear 
	sa "$RAW/staff/20131106_stafflist_`district'", replace
}

* Append districts
u "$RAW/staff/20131106_stafflist_mkoani", clear
ren sept september 
append using  "$RAW/staff/20131106_stafflist_west", gen(source)

g id_district_name="Mkoani" if source==0
replace id_district_name="West" if source==1
drop source 

describe, s

*******************************************************
* Drop variables
*******************************************************

* Process variables (Dhameera cleaning)
fn *old change_dhameera
drop `r(varlist)'

*******************************************************
* Drop observations
*******************************************************

* Remove permenantly
*------------------------------
set linesize 225
list *name comments_dhameera if remove_permenantly==1
drop if remove_permenantly==1
drop remove_permenantly

* Other problems
*------------------------------

list facility firstname secondname thirdname ///
	july august september ///
	comments_dhameera /// 
	if comments_dhameera!=""

describe, s

*******************************************************
* Labels
*******************************************************

la de yesnol 0 "no" 1 "yes", replace
la de yesnol 0 "no absenteeism" 1 "missed days" 2 "missed month", replace

*******************************************************
* Drop vars
*******************************************************

drop officeworkstationlatitude officeworkstationlongitude

*******************************************************
* String clearning 
*******************************************************

* Facility
replace facility = proper(facility)
g comments_max="DHMT" if facility=="Makombeni /Dhmt"
replace facility="Makombeni" if comments_max=="DHMT"

replace comments_max="Temp" if facility=="Kiwani/Temp"
replace facility="Kiwani" if comments_max =="Temp" 
 
replace facility="RCH Mkoani"  if facility=="Rch Mkoani" 
replace facility="Fuoni"  if facility=="Fujoni" 

* PROBLEM INDICATOR:
g problem_phcu = 0
replace problem_phcu = 1 if inlist(facility,"?","")
ta facility problem_phcu, mi

list *name* if problem_phcu ==1 /// DISCUSS WITH DHAMEERA !!!

* Names
fn *name
foreach var in `r(varlist)' {
	replace `var'=upper(`var')
	replace `var'="MOHAMED" if inlist(`var',"MOH'D","MOHD","MOHAMAD","NOH'D","MOHAMMED")
}

* Destring
*------------------------------

* Sex
replace sex="Male" if sex=="male"
sencode sex, replace

* Redefine value labels
recode sex (2=0)
la de sexl 0 "Female" 1 "Male"
la val sex sexl


*******************************************************
* Absenteeism
*******************************************************

* Months
ren july jul
ren august aug
ren september sep

foreach month in jul aug sep {
	ren `month' attend_`month'_c
	g attend_`month' = .
	replace attend_`month' = 0 if attend_`month'_c=="yes"
	replace attend_`month' = 2 if attend_`month'_c=="no"
	la val attend_`month' yesnol
	
	replace attend_`month'_c="" if attend_`month'!=.
}

order attend*, last


fn attend_*_c
foreach var in `r(varlist)' {
	replace `var'="" if `var'=="?"
	replace `var'="1" if `var'=="minus 1 day"
	replace `var'="2" if inlist(`var',"away 2 days","minus 2 days")
	replace `var'="3" if `var'=="minus 3 days"
	replace `var'="4" if `var'=="away 4 days"
	replace `var'="7" if `var'=="minus 1 week"
	replace `var'="8" if `var'=="minus 8 days"	
	replace `var'="14" if inlist(`var',"away for 2 weeks","minums 2 weeks")
	
	destring `var', replace
	ta 	`var', mi
}

ren attend*c attend*days

foreach month in jul aug sep {
	replace attend_`month' = 1 if attend_`month'_days!=.
}

* PROBLEM INDICATORS
g problem_absenteeism=0
foreach month in jul aug sep {
	replace problem_absenteeism=1 if attend_`month'==.
}

ta attend_jul problem_absenteeism, mi
ta attend_aug problem_absenteeism, mi
ta attend_sep problem_absenteeism, mi

order problem*, last

*******************************************************
* Rename
*******************************************************

* name
ren firstname name_first
ren secondname name_second
ren thirdname name_third
ren surname name_sur

* ID
ren facility id_phcu_name

* All
fn sex name* payrollnumber positionjobid attend*
foreach var in `r(varlist)' {
	ren `var' hw_`var'
}

* Job ID
ren hw_positionjobid hw_jobid

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
             
             
Dental Assistant   --> 2 (Assistant)
Dental Technician --> 6 ( Clinical Officer)
PHNB -  --> CATEGORY 3 (own cat)
MEDICAL OFFICER = AMO?

Public Health Nurse B 
             
******************************************************/


replace hw_jobid=proper(hw_jobid)
replace hw_jobid="Community Health Nurse" if inlist(hw_jobid,"Community Health Nurs","Chn")
replace hw_jobid="MCH Aide" if inlist(hw_jobid,"Mch Aide")
replace hw_jobid="AMO" if inlist(hw_jobid,"Amo","Medical Officer")
replace hw_jobid=`"Public Health Nurse "B""' if inlist(hw_jobid,"Phnb")

# delimit ;
g hw_basicsalary =. ;
replace hw_basicsalary =7 if inlist(hw_jobid,"AMO") ;
replace hw_basicsalary =6 if inlist(hw_jobid,"Clinical Officer",
"Community Health Nurse","Dental Technician") ;
replace hw_basicsalary =5 if inlist(hw_jobid,"Pharm. Technician",
"Pharmacist","Nurse General", "Nurse Midwife","Nurse Psychiatrist",
"Health Officer","Lab. Technician") ;
replace hw_basicsalary=3 if inlist(hw_jobid,`"Public Health Nurse "B""') ;
replace hw_basicsalary=2 if inlist(hw_jobid,"Lab. Assistant",
"Health Assistant","MCH Aide","Pharm. Assistant","Pharm. Dispenser",
"Health Assistant","Dental Assistant") ;
replace hw_basicsalary =1 if inlist(hw_jobid,"Watchman","Support Staff",
"Special Gang","Orderly") ;
#delimit cr

set linesize 200

ta hw_jobid if  hw_basicsalary==.

ta hw_jobid, mi

ren hw_jobid hw_jobid_s

g hw_jobid = .
replace hw_jobid = 20 if hw_jobid_s=="AMO"		replace hw_jobid = 30 if hw_jobid_s=="Clinical Officer" 		replace hw_jobid = 31 if hw_jobid_s=="Community Health Nurse"	
replace hw_jobid = 32 if hw_jobid_s=="Dental Technician"	replace hw_jobid = 40 if hw_jobid_s=="Pharm. Technician" 		replace hw_jobid = 41 if hw_jobid_s=="Nurse General" 		replace hw_jobid = 42 if hw_jobid_s=="Nurse Midwife" 		replace hw_jobid = 43 if hw_jobid_s=="Nurse Psychiatrist" replace hw_jobid = 44 if hw_jobid_s=="Health Officer" replace hw_jobid = 45 if hw_jobid_s=="Lab. Technician"
replace hw_jobid = 50 if hw_jobid_s==`"Public Health Nurse "B""'
replace hw_jobid = 60 if hw_jobid_s=="Lab. Assistant" 
replace hw_jobid = 61 if hw_jobid_s=="MCH Aide" 
replace hw_jobid = 62 if inlist(hw_jobid_s,"Pharm. Assistant","Pharmacist")
replace hw_jobid = 63 if hw_jobid_s=="Pharm. Dispenser"
replace hw_jobid = 64 if hw_jobid_s=="Health Assistant" 
replace hw_jobid = 65 if hw_jobid_s=="Dental Assistant" 
replace hw_jobid = 70 if inlist(hw_jobid_s,"Orderly","Special Gang","Watchman","Support Staff")
replace hw_jobid = 80 if inlist(hw_jobid_s,"Rch Co Dhmt","?")

#delimit ;
la de cadrel 	20 "AMO"	30 "Clinical Officer" 	31 "Community Health Nurse"	32 "Dental Technician"	40 "Pharm. Technician" 	41 "Nurse General" 	42 "Nurse Midwife" 	43 "Nurse Psychiatrist" 	44 "Health Officer" 	45 "Lab. Technician"	50 "Public Health Nurse B" 	60 "Lab. Assistant" 	61 "MCH Aide" 	62 "Pharm. Assistant,Pharmacist"	63 "Pharm. Dispenser"	64 "Health Assistant" 	65 "Dental Assistant" 	70 "Orderly (incl. Special Gang, Watchman, Support Staff"	80 "Other"
	; 
#delimit cr

ta hw_jobid hw_basicsalary, mi
list hw_jobid_s hw_jobid hw_basicsalary  if hw_jobid==. | hw_basicsalary==.

la val hw_jobid cadrel
codebook hw_jobid, t(30)

* PROBLEM POSITIONS:
g problem_position=0
replace problem_position=1 if inlist(hw_jobid,80)

*******************************************************
* Cleaning hw_salarylevel
*******************************************************
order *, alpha
order hw_name_sur, after(hw_name_third)
order id* hw_name*
order comments* problem*, last

ren hw_basicsalary hw_salarylevel

replace hw_salarylevel=5 if   hw_jobid==43

* Check
set linesize 220
ta hw_jobid hw_salarylevel, mi

* PROBLEM INDICATOR
g problem_salarylevel = 0
replace problem_salarylevel = 1 if hw_jobid==52 | hw_salarylevel==.
ta problem_salarylevel

*******************************************************
* IDs
*******************************************************

* Merge in IDs
*------------------------------
clonevar id_phcu_name_org = id_phcu_name
ren id_district_name id_district_name2
merge m:1 id_phcu_name using "$CLEAN/PHCU_IDs"
order id_phcu_name _merge id* 

compare id_district_name id_district_name2
replace id_district_name2 = proper(id_district_name2)
list id_phcu_s id_district_name id_district_name2 if id_district_name!=id_district_name2

sort id_phcu_name 
set linesize 200
list _merge id_phcu_name id_phcu_name_org if _merge==1
list _merge id_phcu_name id_phcu_name_org if _merge==2
*drop if _merge!=3 // WHAT ARE THESE 4 OBS?!?!!?
ren _merge problem_merge

* HW ID
*------------------------------
sort id_phcu hw_jobid  hw_name_sur
bys id_phcu: g n = _n
g id_hw = id_phcu*100 + n
tostring n, g(n2)
replace n2 = "0" + n2 if n<10
g id_hw_s = id_phcu_s + "-" + n2
cb id_hw 
drop n n2

cb id_hw

*******************************************************
* Save WIDE
*******************************************************

order *, alpha
order hw_name_sur, after(hw_name_third)
order id_z* id_d* id_p* id_h* id* hw_name*
order comments* problem*, last

* Save
compress
sa "$CLEAN/staff", replace
sa "$CLEAN/staff_wide", replace

*******************************************************
* Save LONG
*******************************************************
drop if id_hw==.

compare id_phcu_name_org id_phcu_name
drop id_phcu_name_org

compare id_district_name id_district_name2
drop id_district_name2

* Reshape long
*------------------------------
drop comments* problem* id1 id2 id3 id4

keep id* hw* hw_name_first hw_name_second hw_name_third hw_name_sur
drop *days
ren *aug* *08*
ren *jul* *07*
ren *sep* *09*

reshape long hw_attend_0, i(id_hw) j(t_period)
ren hw_attend_0 hw_attend

* Create ID for merging
*------------------------------
g id_phcu_ym = id_phcu*10000 + 1300 + t_period

* Save
order id_phcu_ym
sa "$CLEAN/staff_long", replace
