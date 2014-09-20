
u "$TEMP/hr01(insheet)", clear
drop checknumber

******************************************************************************
* Rename
******************************************************************************

ren *name name_*
ren officeworkstationlocation id_district_name
ren dateofbirth dateofbirth_mdy

******************************************************************************
* Keep only PHCUs + Missing
******************************************************************************

ta facilitytype, mi
keep if inlist(facilitytype,"PHCU","PHCU+","")
ta facilitytype, mi // MISSING (!!!)

******************************************************************************
* Drop Death/Retired (employeestatus) 
* Drop Missing (employeestatus)
* Drop Old Applicant/Old Employee (employmentstatus)
******************************************************************************

ta employeestatus employmentstatus, mi

ta employeestatus, mi
drop if inlist(employeestatus,"Death","Retired","")
ta employeestatus, mi

ta employmentstatus, mi
drop if inlist(employmentstatus,"Old Applicant","Old Employee")
ta employmentstatus, mi
 
ta dateofbirth

******************************************************************************
* Rename
******************************************************************************

order id*
ren * hr_*
ren hr_id_* id_*
ren hr_facility id_phcu_name

******************************************************************************
* Manipulate
******************************************************************************

* Facility type
*--------------------------------------------
g hr_facility_type = 0
replace hr_facility_type = 1 if hr_facilitytype=="PHCU+"
la de facilitytypel 0 "PHCU" 1 "PHCU+"
la val hr_facility_type facilitytypel
drop 	hr_facilitytype 

* Age 
*--------------------------------------------
generate hr_age_201306=(mdy(6,1,2013) - hr_dateofbirth_mdy) / 365.25

* Cadre code
*--------------------------------------------
g hr_cadre_code=.replace hr_cadre_code = 10 if hr_positionjobid==`"MD"'replace hr_cadre_code = 20 if hr_positionjobid==`"AMO"'replace hr_cadre_code = 21 if hr_positionjobid==`"PHN "A""'replace hr_cadre_code = 30 if hr_positionjobid==`"Clinical Officer"'replace hr_cadre_code = 31 if hr_positionjobid==`"Community Health Nurs"'replace hr_cadre_code = 32 if hr_positionjobid==`"Dental Therapist"'replace hr_cadre_code = 40 if hr_positionjobid==`"Pharm. Technician"'replace hr_cadre_code = 41 if hr_positionjobid==`"Nurse General"'replace hr_cadre_code = 42 if hr_positionjobid==`"Nurse Midwife"'replace hr_cadre_code = 43 if hr_positionjobid==`"Nurse Psychiatrist"'replace hr_cadre_code = 44 if hr_positionjobid==`"Environmental Health Officer "'replace hr_cadre_code = 45 if hr_positionjobid==`"Lab. Technician"'replace hr_cadre_code = 46 if hr_positionjobid==`"Pharmacist"'replace hr_cadre_code = 47 if hr_positionjobid==`"Orthopaedic Technician"'replace hr_cadre_code = 50 if hr_positionjobid==`"PHN "B""'replace hr_cadre_code = 60 if hr_positionjobid==`"Lab. Assistant"'replace hr_cadre_code = 61 if hr_positionjobid==`"Mch Aide"'replace hr_cadre_code = 62 if hr_positionjobid==`"Pharm. Assistant"'replace hr_cadre_code = 63 if hr_positionjobid==`"Pharm. Dispenser"'replace hr_cadre_code = 64 if hr_positionjobid==`"Health Assistant"'replace hr_cadre_code = 65 if hr_positionjobid==`"Dental Assistant"'replace hr_cadre_code = 48 if hr_positionjobid==`"Health Officer"'replace hr_cadre_code = 49 if hr_positionjobid==`"Nutrition Officer"'replace hr_cadre_code = 70 if hr_positionjobid==`"Orderly"'replace hr_cadre_code = 70 if hr_positionjobid==`"Kitchen Attendant"'replace hr_cadre_code = 70 if hr_positionjobid==`"Special Gang"'replace hr_cadre_code = 70 if hr_positionjobid==`"Watchman"'replace hr_cadre_code = 70 if hr_positionjobid==`"Clerk"'replace hr_cadre_code = 70 if hr_positionjobid==`"Store Keeper"'replace hr_cadre_code = 70 if hr_positionjobid==`"Support Staff"'

la val hr_cadre_code cadrecodel
run "$DO/01b_all_value_labels.do"
cb hr_cadre_code
ta hr_positionjobid if hr_cadre_code==.

set linesize 225
ta hr_positionjobid hr_designationcadre

g hr_cadre_code_wide = round(hr_cadre_code/10,1)

sort hr_cadre_code_wide 
ta hr_designationcadre hr_cadre_code_wide 

ta hr_cadre_code_wide, mi

g hr_cadre_code_top = 0
replace hr_cadre_code_top = 1 if inlist(hr_cadre_code_wide,2,3)
g hr_cadre_code_mid = 0
replace hr_cadre_code_mid = 2 if inlist(hr_cadre_code_wide,4) 
g hr_cadre_code_low = 0
replace hr_cadre_code_low = 3 if inlist(hr_cadre_code_wide,5,6)


drop hr_cadre_code_wide 

******************************************************************************
* Merge with overall PHCU data
******************************************************************************

order id_phcu_name

replace id_phcu_name=itrim(trim(proper(id_phcu_name)))

replace id_phcu_name="Bandarini" if id_phcu_name=="Bandarini Phcu"
replace id_phcu_name="Beit-El-Ras" if id_phcu_name=="Beit-El-Raas"
replace id_phcu_name="Mwambe" if id_phcu_name=="Muambe"
replace id_phcu_name="Mbweni Matrekta" if id_phcu_name=="Mbweni"
replace id_phcu_name="Jangombe Matarumbeta" if id_phcu_name=="Jang'Ombe"
replace id_phcu_name="Maziwang'Ombe" if id_phcu_name=="Maziwa Ngombe" 
replace id_phcu_name="Mzambarauni Takao" if id_phcu_name=="Mzambarauni" 
replace id_phcu_name="Shumba Viamboni" if id_phcu_name=="Shumba-Viamboni" 
replace id_phcu_name="Mkia Wa Ngombe" if id_phcu_name=="Mkia Wa Ng'Ombe" 
replace id_phcu_name="Maziwa Ngombe" if id_phcu_name=="Maziwang'Ombe" 
replace id_phcu_name="Minungwini" if id_phcu_name=="Kiuyu Minungwini" 
replace id_phcu_name="Makoba" if id_phcu_name=="Bumbwini Makoba" 
replace id_phcu_name="" if id_phcu_name=="" 

cb id_phcu_name

merge m:1 id_phcu_name using "$GENERAL/phcu_info/phcu_info_clean", gen(merge_hr)
drop gis_merge gps_latitude gps_longitude pop09 phcu_activity phcu_catchmentpop

ta id_phcu_name if merge_hr==1
list id_phcu id_phcu_name if merge_hr==2

list id_phcu_name merge_hr if id_phcu_name=="Chuini"


drop if merge_hr==1
ren merge_hr  merge_hr
//// BIG PROBLEM WITH MERGE HERE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

* Facility type problem !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ta hr_facility_type  facility_type if merge_hr==3

******************************************************************************
* Save with people
******************************************************************************

sort id_phcu_name

order id* hr_facility* hr_name* hr_positionjobid hr_designationcadre hr_dateofbirth_mdy hr_sex
order hr_employ* hr_residence hr_nationality hr_officeworkstation*, last

compress

sa "$CLEAN/08_hr/hr_clean", replace


******************************************************************************
* Save again
******************************************************************************

* Drop
*--------------------------------------------
#delimit ;
drop 
	hr_nationality 	hr_residence
	hr_officeworkstationlatitude hr_officeworkstationlongitude 
	hr_name_first hr_name_second hr_name_third hr_name_sur
	hr_employeestatus hr_employmentstatus 
	hr_payrollnumber hr_department
	hr_positionjobid hr_designationcadre hr_dateofbirth_mdy
	;
#delimit cr
drop facility_type // dropping here because it's in merging document

* Number of staff per facility
*--------------------------------------------
bys id_phcu_name: g hr_staff_n = _N


* Sex
ren hr_sex hr_sex_s
g hr_sex = .
replace hr_sex=0 if hr_sex_s=="Female"
replace hr_sex=1 if hr_sex_s=="Male"
la de sexl 0 "Female" 1 "Male"
la val hr_sex sexl
drop hr_sex_s

bys id_phcu_name: egen hr_staff_male_n = total(hr_sex)

recode hr_sex (0=1) (1=0)
bys id_phcu_name: egen hr_staff_female_n = total(hr_sex)
recode hr_sex (0=1) (1=0)

egen hr_sex_total = rowtotal(hr_staff_male_n hr_staff_female_n)

g hr_staff_male_ratio = hr_staff_male_n/hr_sex_total 

drop hr_staff_male_n hr_staff_female_n hr_sex_total

* Age
bys id_phcu_name: egen hr_age_201306_avg = mean(hr_age_201306)

* Cadre
foreach var in hr_cadre_code_top hr_cadre_code_mid hr_cadre_code_low {
	bys id_phcu_name: egen `var'_n = total(`var')
	drop `var'
}

drop hr_sex hr_age_201306 hr_cadre_code

* Keep individuals
*--------------------------------------------


bys id_phcu_name: g n = _n
keep if n==1
drop n

* Save
*--------------------------------------------

keep id_* hr* merge*
order *, alpha
order id_phcu id* hr* merge*

sa "$CLEAN/08_hr/hr_clean_forbalance", replace



