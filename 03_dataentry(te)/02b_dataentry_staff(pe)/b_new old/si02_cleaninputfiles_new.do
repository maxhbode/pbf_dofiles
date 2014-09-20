
loc SKIP=0 

*******************************************************
* Importing staff data after Mary HR and Dhameera DHMT test
*******************************************************

* Import
loc date 20131210
* Options: 20131106, 20131210
foreach district in mkoani west {
	insheet using "$RAW/staff/`date'_stafflist_`district'.csv", c clear 
	sa "$RAW/staff/`date'_stafflist_`district'", replace
}

* Append districts
u "$RAW/staff/`date'_stafflist_mkoani", clear
if `SKIP'==1 ren sept september 
append using  "$RAW/staff/`date'_stafflist_west", gen(source)

g id_district_name="Mkoani" if source==0
replace id_district_name="West" if source==1
drop source 

describe, s

*******************************************************
* Drop variables
*******************************************************

* Process variables (Dhameera cleaning)
if `SKIP'==1 fn *old change_dhameera
if `SKIP'==1 drop `r(varlist)'

*******************************************************
* Drop observations
*******************************************************

* Remove permenantly
*------------------------------
set linesize 225

if `SKIP'==1 	list *name comments_dhameera if remove_permenantly==1
if `SKIP'==1 	drop if remove_permenantly==1
if `SKIP'==1 	drop remove_permenantly

* Other problems
*------------------------------

list facility firstname secondname thirdname 

describe, s

*******************************************************
* Labels
*******************************************************

la de yesnol 0 "no" 1 "yes", replace
la de yesnol 0 "no absenteeism" 1 "missed days" 2 "missed month", replace

*******************************************************
* Drop vars
*******************************************************

if `SKIP'==1 	drop officeworkstationlatitude officeworkstationlongitude

*******************************************************
* String clearning 
*******************************************************

* Facility
replace facility = proper(facility)

replace facility="RCH Mkoani"  if facility=="Rch Mkoani" 


* Names
fn *name
foreach var in `r(varlist)' {
	replace `var'=upper(`var')
	replace `var'="MOHAMED" if inlist(`var',"MOH'D","MOHD","MOHAMAD","NOH'D","MOHAMMED")
}



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
ren * hw_*
ren hw_id_* id_*

* Job ID
cap: ren hw_positionjobid hw_jobid

order id* hw*

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
replace hw_jobid=`"Orderly"' if hw_jobid=="40"


# delimit ;
g hw_basicsalary =. ;
replace hw_basicsalary =7 if inlist(hw_jobid,"AMO") ;
replace hw_basicsalary =6 if inlist(hw_jobid,"Clinical Officer",
"Community Health Nurse","Dental Technician") ;
replace hw_basicsalary =5 if inlist(hw_jobid,"Pharm. Technician",
"Pharmacist","Nurse General", "Nurse Midwife","Nurse Psychiatrist",
"Health Officer","Lab. Technician") ;
replace hw_basicsalary=3 if inlist(hw_jobid,`"Public Health Nurse "B""',"PHNB") ;
replace hw_basicsalary=2 if inlist(hw_jobid,"Lab. Assistant",
"Health Assistant","MCH Aide","Pharm. Assistant","Pharm. Dispenser",
"Health Assistant","Dental Assistant") ;
replace hw_basicsalary =1 if inlist(hw_jobid,"Watchman","Support Staff",
"Special Gang","Orderly") ;
#delimit cr

ta hw_jobid  hw_basicsalary, mi


set linesize 200

ta hw_jobid if  hw_basicsalary==.

ta hw_jobid, mi

ren hw_jobid hw_jobid_s

g hw_jobid = .
replace hw_jobid = 20 if hw_jobid_s=="AMO"		replace hw_jobid = 30 if hw_jobid_s=="Clinical Officer" 		replace hw_jobid = 31 if hw_jobid_s=="Community Health Nurse"	
replace hw_jobid = 32 if hw_jobid_s=="Dental Technician"	replace hw_jobid = 40 if hw_jobid_s=="Pharm. Technician" 		replace hw_jobid = 41 if hw_jobid_s=="Nurse General" 		replace hw_jobid = 42 if hw_jobid_s=="Nurse Midwife" 		replace hw_jobid = 43 if hw_jobid_s=="Nurse Psychiatrist" replace hw_jobid = 44 if hw_jobid_s=="Health Officer" replace hw_jobid = 45 if hw_jobid_s=="Lab. Technician"
replace hw_jobid = 46 if hw_jobid_s=="Dental Therapist"
replace hw_jobid = 50 if hw_jobid_s==`"Public Health Nurse "B""'
replace hw_jobid = 60 if hw_jobid_s=="Lab. Assistant" 
replace hw_jobid = 61 if hw_jobid_s=="MCH Aide" 
replace hw_jobid = 62 if inlist(hw_jobid_s,"Pharm. Assistant","Pharmacist")
replace hw_jobid = 63 if hw_jobid_s=="Pharm. Dispenser"
replace hw_jobid = 64 if hw_jobid_s=="Health Assistant" 
replace hw_jobid = 65 if hw_jobid_s=="Dental Assistant" 
replace hw_jobid = 70 if inlist(hw_jobid_s,"Orderly","Special Gang","Watchman","Support Staff")

ta hw_jobid hw_jobid_s

* hw_jobid_s
*Dental Therapist

#delimit ;
la de cadrel 	20 "AMO"	30 "Clinical Officer" 	31 "Community Health Nurse"	32 "Dental Technician"	40 "Pharm. Technician" 	41 "Nurse General" 	42 "Nurse Midwife" 	43 "Nurse Psychiatrist" 	44 "Health Officer" 	45 "Lab. Technician"
	46 "Dental Therapist"	50 "Public Health Nurse B" 	60 "Lab. Assistant" 	61 "MCH Aide" 	62 "Pharm. Assistant,Pharmacist"	63 "Pharm. Dispenser"	64 "Health Assistant" 	65 "Dental Assistant" 	70 "Orderly (incl. Special Gang, Watchman, Support Staff"	80 "Other"
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
order problem*, last

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

* Last minute cleaning
*------------------------------
if `date'==20131210 {
ta hw_senioritylevel

g hw_incharge=0
replace hw_incharge=1 if hw_senioritylevel=="In-charge"
la de yesno_label 0 "no" 1 "yes"
la val hw_incharge yesno_label
ta hw_incharge
drop hw_senioritylevel
}

* Merge in IDs
*------------------------------
clonevar id_phcu_name_org = id_phcu_name
ren id_district_name id_district_name2

preserve
u "$CLEAN/PHCU_IDs", clear
replace id_phcu_name="Chuwini" if id_phcu_name=="Chuini"
replace id_phcu_name="Matrakta" if id_phcu_name=="Mbweni"
sa "$CLEAN/temp_PHCU_IDs", replace
restore 

merge m:1 id_phcu_name using "$CLEAN/temp_PHCU_IDs"
order id_phcu_name _merge id* 

sort id_phcu

list id_phcu_name if id_phcu==.
drop if id_phcu==.
* !!!!!!!!!!!!!!!!!!!!!!!!!!PROBLEM  !!!!!!!!!!!!!!!!

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
if `date'==20131210 {
clonevar hw_incharge_inverse = hw_incharge
recode hw_incharge_inverse (1=0) (0=1)
*sort id_phcu hw_incharge_inverse hw_jobid hw_name_sur
}

sort id_phcu hw_jobid  hw_name_sur
cap: sort id_phcu hw_incharge_inverse  hw_jobid  hw_name_sur
bys id_phcu: g n = _n
g id_hw = id_phcu*100 + n
tostring n, g(n2)
replace n2 = "0" + n2 if n<10
g id_hw_s = id_phcu_s + "-" + n2
cap: order id_hw id_hw_s hw_incharge
sort id_hw 
cb id_hw 
drop n n2

cb id_hw

*******************************************************

* Drop unnecessary
*------------------------------
drop id1 id2 id3 id4
fn problem_* 
drop `r(varlist)'

if `date'==20131210 {
	keep id_hw hw_incharge id_phcu_name id_district_name2 id_phcu_name_org id_district id_district_name id_phcu id_phcu_s id_zone id_zone_name hw_name_first hw_name_second hw_name_third hw_name_sur hw_salarylevel hw_facilitytype hw_jobid hw_jobid_s hw_sex
}

if `date'== 20131106 {
	keep id_hw id_phcu_name id_district_name2 id_phcu_name_org id_district id_district_name id_phcu id_phcu_s id_zone id_zone_name hw_name_first hw_name_second hw_name_third hw_name_sur hw_salarylevel hw_jobid hw_jobid_s hw_sex
}


*******************************************************
* Save WIDE
*******************************************************

order *, alpha
order hw_name_sur, after(hw_name_third)
order id_z* id_d* id_p* id_h* id* hw_name*

* Save
compress
sa "$CLEAN/`date'_staff", replace
di  "$CLEAN/`date'_staff"
sa "$CLEAN/`date'_staff_wide", replace

*br if hw_jobid==.


/*
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
drop id1 id2 id3 id4

keep id* hw* hw_name_first hw_name_second hw_name_third hw_name_sur

* Save
order id_hw id_hw_s
sort id_hw
sa "$CLEAN/`date'_staff_long", replace
