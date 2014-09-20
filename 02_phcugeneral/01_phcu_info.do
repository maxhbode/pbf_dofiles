* Install value Labels
run "$DO/01b_all_value_labels.do"

u "$GENERAL/phcu_info/phcu_info_raw.dta", clear

*----------------------------------------------------
* IDs
*----------------------------------------------------

* Create Zone ID
g id_zone = .
replace id_zone=1 if inlist(id_district_name,"Chakechake","Micheweni","Mkoani","Wete")
replace id_zone=2 if inlist(id_district_name,"Central","North A","North B","South","Urban","West")
la var id_zone "Zone ID"
la de zonel 1 "Pemba" 2 "Unguja"
la val id_zone zonel
decode id_zone, g(id_zone_name)

cb id_zone

* Create District ID
g id_district = .
replace id_district = 11 if id_district_name=="Chakechake" 
replace id_district = 12 if id_district_name=="Micheweni"
replace id_district = 13 if id_district_name=="Mkoani"
replace id_district = 14 if id_district_name=="Wete"
replace id_district = 21 if id_district_name=="Central"
replace id_district = 22 if id_district_name=="North A"
replace id_district = 23 if id_district_name=="North B"
replace id_district = 24 if id_district_name=="South"
replace id_district = 25 if id_district_name=="South"
replace id_district = 26 if id_district_name=="West"
replace id_district = 27 if id_district_name=="Urban"
la var id_district "District ID"
la val id_district districtl

* Create PHCU ID
replace id_phcu_name="Bogoa" if id_phcu_name=="Bogowa"
sort id_district  id_phcu_name, stable
by id_district: g id_phcu = _n
replace id_phcu = id_district*100 + id_phcu
cb id_phcu

* Recoding id_phcu because of error in intiral creating, see below (FIXED ERROR)
recode id_phcu (1309 = 1310) (1310 = 1309)

* Merging with OLD IDs7
preserve
u "$CLEAN/PHCU_IDs", clear
replace id_phcu_name="Mbweni Matrekta" if id_phcu_name=="Matrakta"
replace id_phcu_name="Chukwani Maternity Home" if id_phcu_name=="Chukwani"
ren * i_*
ren i_id_phcu id_phcu
tempfile temp
sa `temp', replace
restore

merge 1:1 id_phcu using `temp', nogen
drop i_id_district i_id_district_name i_id_phcu_s i_id_zone i_id_zone_name ///
	i_id1 i_id2 i_id3 i_id4

* FIXED ERROR
list id_phcu id_phcu_name i_id_phcu_name if inlist(id_phcu,1309,1310)
drop i_id_phcu_name	

order id_phcu id_zone* id_district*

*----------------------------------------------------
* Merge with SKIPS
*----------------------------------------------------
merge 1:1 id_phcu using "$CLEAN/skips", nogen
g activity = 0
replace activity = 1 if b0_section_skip==1
replace activity = 2 if c0_section_skip==1
la de acitivtyl 0 "All" 1 "Preventative Only" 2 "Curative Only"
la val activity acitivtyl
ta activity  b0_section_skip 
ta activity  c0_section_skip
drop b0_section_skip c0_section_skip

*----------------------------------------------------
* Merge with GIS
*----------------------------------------------------
preserve 
u "$GENERAL/phcu_info/phcu_info_gis", clear
drop if gps_latitude==. | gps_longitude==.

replace id_phcu_name = proper(id_phcu_name)

replace id_phcu_name="Beit-El-Ras" if id_phcu_name=="Beit-El-Raas"
replace id_phcu_name="Bumbwini Misufini" if id_phcu_name=="Bumbwini"
replace id_phcu_name="Fuoni Kibondeni" if id_phcu_name=="Fuoni K"
replace id_phcu_name="Jangombe Matarumbeta" if id_phcu_name=="Jang'Ombe"
replace id_phcu_name="Jendele" if id_phcu_name=="Jedele"
replace id_phcu_name="Kiomba Mvua" if id_phcu_name=="Kiomba M"
replace id_phcu_name="Mbweni Matrekta" if id_phcu_name=="Mbweni"
replace id_phcu_name="Kijini" if id_phcu_name=="Kijiji"

format %10.0f gps_latitude	gps_longitude

sa "$TEMP/phcu_info_gis", replace
restore 


replace id_phcu_name="Chukwani" if id_phcu_name=="Chukwani Maternity Home"
replace id_phcu_name = proper(id_phcu_name)

merge 1:1 id_phcu_name using "$TEMP/phcu_info_gis", gen(gis_merge)

ta id_zone gis_merge

sort id_phcu_name 

order gis_merge, after(id_phcu_name)
sort gis_merge




*----------------------------------------------------
* Merge with population data
*----------------------------------------------------

merge m:1 id_district_name using ///
	"$SMZ/data/pop by district 2009/pop_by_district_2009", nogen

*----------------------------------------------------
* Rename 
*----------------------------------------------------
ren activity phcu_activity
ren catchmentarea_population phcu_catchmentpop


*----------------------------------------------------
* Replace
*----------------------------------------------------

	replace id_phcu_name="Beit-El-Raas" if id_phcu_name=="Beit-El-Ras"
	replace id_phcu_name="RCH Mkoani" if id_phcu_name=="Rch Mkoani"

*----------------------------------------------------
* Label
*----------------------------------------------------
la var id_district_name "District name"
la var id_phcu "PHCU ID"
la var id_phcu_name "PHCU name"
la var id_zone_name "Zone name" 
la var phcu_activity "PHCU Activity"
la var phcu_catchmentpop "Population in Catchment Area"
la var facility_type "Facility Type"

*----------------------------------------------------
* Order & Sort
*----------------------------------------------------
order *, alpha
order id_zone* id_district* id_phcu* phcu_* facility_type
sort id_phcu
compress
sa "$GENERAL/phcu_info/phcu_info_clean", replace


*----------------------------------------------------
* Update - New facility 
*----------------------------------------------------

describe, short
loc N = `r(N)'+1
set obs `N'

replace id_phcu=1317 in `N'
replace id_zone=1  in `N'
replace id_phcu_name="Tasini" in `N'
replace id_zone=1 in `N'
replace id_district=13 in `N'
replace id_phcu=1317 in `N'

br if id_phcu==1317


sa "$GENERAL/phcu_info/phcu_info_clean_2014", replace

*----------------------------------------------------
* Outsheet
*----------------------------------------------------
foreach var in id_zone id_district id_phcu {
	tostring `var', replace
}

export excel using "$GENERAL/phcu_info/phcu_info_clean",  firstrow(varlabels) replace


* Special
keep if inlist(id_district,13,26)
export excel using "$GENERAL/phcu_info/pbf_phcu_info_clean", firstrow(varlabels) replace


