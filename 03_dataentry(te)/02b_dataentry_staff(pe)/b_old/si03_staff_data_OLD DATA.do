
************************************************************************
* (01) Clean Staff data
************************************************************************

* Clean staff
*---------------------------------------------------

u "$TEMP/staff", clear
drop staffappraisalscore retentionfactor timeadjustsment totalpointsearned // drop bad weighting vars

* Rename
*------------------------------
ren *name name_*
ren designationcadre cadre

fn sex name* dateofbirth cadre employmentstatus nationality residence ///
employeestatus payrollnumber positionjobid department basicsalary
foreach var in `r(varlist)' {
	ren `var' hw_`var'
}
ren officeworkstationlocation id_district_name2

ren facilitytype phcu_type
ren officeworkstation* phcu_*
ren facility id_phcu_name

* Merge in IDs
*------------------------------
replace id_phcu_name=proper(id_phcu_name)

replace id_phcu_name="Beit El Ras" if id_phcu_name=="Beit-El-Raas"
replace id_phcu_name="Miangani" if id_phcu_name=="Mtangani"
replace id_phcu_name="Mwambe" if id_phcu_name=="Muambe"
replace id_phcu_name="Kisuani" if id_phcu_name=="Kisauni"
replace id_phcu_name="Matrakta" if id_phcu_name=="Mbweni" // assumption !!!! 
replace id_phcu_name="Fuoni" if  id_phcu_name=="Fujoni" 

merge m:1 id_phcu_name using "$CLEAN/PHCU_IDs"
order id_phcu_name _merge id* 
sort id_phcu_name 
list _merge id_phcu_name   if _merge!=3
drop if _merge!=3 // WHAT ARE THESE 8 OBS?!?!!?
drop _merge

* Check
compare id_district_name2  id_district_name
drop id_district_name2

* HW ID
*------------------------------
gsort - id_phcu hw_basicsalary
bys id_phcu: g n = _n
g id_hw = id_phcu*100 + n
tostring n, g(n2)
replace n2 = "0" + n2 if n<10
g id_hw_s = id_phcu_s + "-" + n2
cb id_hw 
drop n n2


* String cleaning
*------------------------------
fn hw_name_*
foreach var in `r(varlist)' {
	replace `var'=upper(`var')
	replace `var'="MOHAMED" if `var'=="MOH'D"
}

* Destring
*------------------------------

* Special encode
sort hw_cadre
foreach var in  hw_positionjobid  phcu_type  hw_employmentstatus hw_sex hw_employeestatus  {
	sencode `var', replace
}

* Redefine value labels
recode hw_sex (2=0)
la de hw_sexl 0 "Female" 1 "Male"
la val hw_sex hw_sexl

* Dates 
*------------------------------
g hw_birth_mdy = date(hw_dateofbirth,"DM19Y")
format %td hw_birth_mdy
drop hw_dateofbirth
order hw_birth_mdy, after(hw_sex)

sort id_phcu hw_name_sur
order *, alpha 
order id_hw* id_* phcu* hw*

* Save
*------------------------------

sort id_hw_s hw_positionjobid
sa "$CLEAN/staff", replace


