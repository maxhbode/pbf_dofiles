loc yy 13

set linesize 225
loc period 1112
* v01healthfacilityname

*******************************************************************************
* Import Data
*******************************************************************************

* First Entry
forval ee = 1/2 {

	* Month
	forval mm = 10/12 {

		* Import
		insheet using "$ENTRY/`yy'_`period'/2013`mm'_dataentry_entry`ee'.csv", clear comma
		
		* Create Entry indicator
		g dataentryround = `ee'
		
		* Manual ID correction
		cap: replace v02healthfacilityidfacility=10 if v01healthfacilityname=="KOMBENI"
		
		* Create PHCU ID
		drop id
		g id_phcu = v02healthfacilityidzone*1000+v02healthfacilityiddistrict*100+v02healthfacilityidfacility
		*ta id_phcu
		
		* Create Month ID
		g id_period_mm = `mm'
		g id_period_yy = 13
		g id_period_yyyy = 2000 + id_period_yy
		g id_period_ym = id_period_yy*100 + id_period_mm
		ta id_period_ym
			
		* Create PHCU / MY
		g id_phcu_ym = id_phcu*10000 + id_period_ym
		foreach var in id_phcu id_period_yy id_period_mm {
			tostring `var', gen(`var'_s)
		}
		g id_phcu_ym_s = id_phcu_s + "-" + id_period_yy_s + "-" + id_period_mm_s


		g id_zone_s = substr(id_phcu_s,1,1)
		g id_district_s = substr(id_phcu_s,2,1)
		g id_facility_s = substr(id_phcu_s,3,2)
		
		drop id_phcu_s
		g id_phcu_s = id_zone_s + "-" + id_district_s + "-" + id_district_s
		
		destring id_zone_s, g(id_zone)
		destring id_district_s, g(id_district)
		destring id_facility_s, g(id_facility)
		drop id_zone_s id_district_s id_facility_s

		* Tostring numeric "Sting" variables 
		 
		fn v06ii* v07ii* *comment* *comment
 		loc vars `r(varlist)' d25namesur d25corrects d26namesur d26corrects 
 		
		foreach var in  `vars'   {
			cap: tostring `var', replace 
		}
		
		findname *, type(string)
		foreach var in `r(varlist)' {
			replace `var'="" if `var'=="."
		}

		* Save
		order id_phcu_ym id_phcu id*
		sa "$TEMP/2013`mm'_dataentry_entry`ee'", replace
		
	}
}

*******************************************************************************
* Append 
*******************************************************************************

* First Entry
forval ee = 1/2 {
	u "$TEMP/201311_dataentry_entry`ee'", clear

	* Month
	*forval mm = 12 {

		* Append
		qui append using "$TEMP/201312_dataentry_entry`ee'"
	
	*}
	
	* Check unqiue ID
	di ""
	di as input "*** 2013`period'_dataentry_entry`ee' ***"
	qui duplicates tag id_phcu_ym, g(dtag)
	list dataentryround id_phcu_ym id_phcu id_period_mm v01healthfacilityname if dtag==1 
	
	* Save
	sort id_phcu_ym
	qui compress
	sa "$TEMP/2013`period'_dataentry_entry`ee'", replace
}

*******************************************************************************
* Compare
*******************************************************************************


* TEMPORARILY DROP SECTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
forval ee = 1/2 {
	u "$TEMP/2013`period'_dataentry_entry`ee'", clear

	list v01healthfacilityname id_phcu id_period_mm dataentry* if id_phcu_ym==26111310
	
	fn *comment* *comment
	drop `r(varlist)'
	drop v06* v07*
	drop dataentry*
	
	sa "$TEMP/temp_2013`period'_dataentry_entry`ee'", replace
	
}

* CFOUT

foreach type in "upper string" "nostring" {
	u "$TEMP/temp_2013`period'_dataentry_entry1", clear
	
	cfout using "$TEMP/temp_2013`period'_dataentry_entry2",  ///
		id(id_phcu_ym_s) `type'  ///
		name("$ENTRY/`yy'_`period'/dataentry_2013101112_report_`type'") replace
		
}
	u "$TEMP/temp_2013`period'_dataentry_entry1", clear
	fn c* b*, loc(varlist)
	cfout `r(varlist)' using "$TEMP/temp_2013`period'_dataentry_entry2",  ///
		id(id_phcu_ym_s)  nostring ///
		name("$ENTRY/`yy'_`period'/dataentry_2013101112_report_meat") replace		


*******************************************************************************
* Value corrections based on manual check
*******************************************************************************

forval ee = 1/2 {
	u "$TEMP/2013`period'_dataentry_entry`ee'", clear
	
	replace c08bvguidlines=-999 if id_phcu_ym_s=="1301-13-11"	replace b05dnvall=-999 if id_phcu_ym_s=="1301-13-12"	replace b06avall=-999 if id_phcu_ym_s=="1301-13-12"	replace b06cvguidlines=-999 if id_phcu_ym_s=="1301-13-12"	replace c05dnvguidlines=-999 if id_phcu_ym_s=="1301-13-12"	replace c08avall=7 if id_phcu_ym_s=="1301-13-12"	replace c10avall=11 if id_phcu_ym_s=="1302-13-11"	replace c11avall=0 if id_phcu_ym_s=="1302-13-11"	replace b05avall=-999 if id_phcu_ym_s=="1305-13-12"	replace b05dnvall=-999 if id_phcu_ym_s=="1305-13-12"	replace c06dnvguidlines=0 if id_phcu_ym_s=="1305-13-12"	replace b04cvguidlines=-999 if id_phcu_ym_s=="1306-13-12"	replace c10avall=15 if id_phcu_ym_s=="1308-13-12"	replace b03cvguidlines=6 if id_phcu_ym_s=="1310-13-12"	replace b02cvguidlines=38 if id_phcu_ym_s=="1311-13-12"	replace c05dnvguidlines=-999 if id_phcu_ym_s=="1312-13-11"	replace b04dnvall=-999 if id_phcu_ym_s=="1313-13-11"	replace b04fnvguidlines=-999 if id_phcu_ym_s=="1313-13-11"	replace c08bvguidlines=-999 if id_phcu_ym_s=="1314-13-11"	replace b02cvguidlines=51 if id_phcu_ym_s=="1314-13-12"	replace b03cvguidlines=19 if id_phcu_ym_s=="1315-13-11"	replace b04dnvall=-999 if id_phcu_ym_s=="1315-13-11"	replace b04fnvguidlines=-999 if id_phcu_ym_s=="1315-13-11"	replace c01avall=7 if id_phcu_ym_s=="1315-13-11"	replace b06avall=0 if id_phcu_ym_s=="2601-13-11"	replace b06cvguidlines=0 if id_phcu_ym_s=="2601-13-11"	replace b06dnvall=0 if id_phcu_ym_s=="2601-13-11"	replace b06fnvguidlines=0 if id_phcu_ym_s=="2601-13-11"	replace b05avall=-999 if id_phcu_ym_s=="2602-13-11"	replace b05dnvall=-999 if id_phcu_ym_s=="2602-13-11"	replace b03cvguidlines=10 if id_phcu_ym_s=="2605-13-11"	replace b06fnvguidlines=0 if id_phcu_ym_s=="2605-13-11"	replace b01fnvguidlines=49 if id_phcu_ym_s=="2606-13-12"	replace c01cnvall=40 if id_phcu_ym_s=="2606-13-12"	replace c03cnvall=1 if id_phcu_ym_s=="2606-13-12"	replace c04cnvall=3 if id_phcu_ym_s=="2607-13-11"	replace c11avall=0 if id_phcu_ym_s=="2607-13-11"	replace c08bvguidlines=0 if id_phcu_ym_s=="2609-13-12"	replace c08dnvguidlines=0 if id_phcu_ym_s=="2609-13-12"	replace b01bvsample=49 if id_phcu_ym_s=="2610-13-12"	replace b05dnvall=-999 if id_phcu_ym_s=="2611-13-11"	replace c13avall=1 if id_phcu_ym_s=="2611-13-11"	replace b01fnvguidlines=7 if id_phcu_ym_s=="2614-13-11"	replace b06fnvguidlines=0 if id_phcu_ym_s=="2614-13-12"
	
	sa "$TEMP/temp_2013`period'_dataentry_entry`ee'_clean", replace
}

u "$TEMP/temp_2013`period'_dataentry_entry1_clean", clear
fn c* b* d*, loc(varlist)
cfout `r(varlist)' using "$TEMP/temp_2013`period'_dataentry_entry2_clean",  ///
	id(id_phcu_ym_s) nostring ///
	name("$ENTRY/`yy'_`period'/dataentry_2013101112_report_cleanmeat") replace		

ta id_period_mm id_zone



*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

loc period 1112


forval ee = 1/2 {
	u "$TEMP/2013`period'_dataentry_entry`ee'", clear
	
	fn d*, type(numeric) loc(numeric)
	foreach var in `r(varlist)' {
		tostring `var', replace 
	}
	
	replace d08breasoncode="5" if id_phcu_ym_s=="1304-13-12"	replace d02creasoncomment="HAYUPO" if id_phcu_ym_s=="1304-13-12"	replace d06creasoncomment="RETURN FROM LEAVE 23/07/0213" if id_phcu_ym_s=="1304-13-12"	replace d08creasoncomment="HAYUPO AMEHAMISHWA" if id_phcu_ym_s=="1304-13-12"	replace d03creasoncomment="MATENITY LEAVE" if id_phcu_ym_s=="1305-13-12"	replace d03creasoncomment="IS NOT WORKING HERE" if id_phcu_ym_s=="1307-13-12"	replace d02creasoncomment="UNGUJA" if id_phcu_ym_s=="1308-13-12"	replace d23namesur="SHEHE" if id_phcu_ym_s=="1308-13-12"	replace d01creasoncomment="2DAYS A WEEK CHAMBANI" if id_phcu_ym_s=="1309-13-11"	replace d02creasoncomment="IS NOT WORKING THERE ANY MORE" if id_phcu_ym_s=="1309-13-12"	replace d05creasoncomment="IS NOT WORKING HERE" if id_phcu_ym_s=="1309-13-12"	replace d05breasoncode="-999" if id_phcu_ym_s=="1310-13-12"	replace d23name3="MOH'D" if id_phcu_ym_s=="1310-13-12"	replace d23name2="ABDULLA" if id_phcu_ym_s=="1312-13-12"	replace d02creasoncomment="LIKIZO" if id_phcu_ym_s=="1313-13-12"	replace d02creasoncomment="UNGUJA" if id_phcu_ym_s=="1315-13-12"	replace d05breasoncode="-999" if id_phcu_ym_s=="1316-13-12"	replace d01creasoncomment="SHE SORK IS TWO FACILITIES" if id_phcu_ym_s=="2601-13-12"	replace d04creasoncomment="MGONJWA" if id_phcu_ym_s=="2601-13-12"	replace d05dmistakecorrection="2" if id_phcu_ym_s=="2606-13-12"	replace d04creasoncomment="MAGOGONI" if id_phcu_ym_s=="2608-13-12"	replace d23name1="ZAHIDA" if id_phcu_ym_s=="2610-13-12"	replace d24name1="MARYAM" if id_phcu_ym_s=="2611-13-12"	replace d24name3="SHEKHA" if id_phcu_ym_s=="2613-13-12"	replace d01adaysworked="0" if id_phcu_ym_s=="1301-13-12"	replace d10dmistakecorrection="2" if id_phcu_ym_s=="1301-13-12"	replace d23name1="OTHMAN" if id_phcu_ym_s=="1302-13-12"	replace d23cadrecode="50" if id_phcu_ym_s=="1308-13-12"	replace d23comment="FROM 18 NOV" if id_phcu_ym_s=="1308-13-12"	replace d08adaysworked="0" if id_phcu_ym_s=="2607-13-12"	replace d10creasoncomment="""" if id_phcu_ym_s=="1301-13-12"	replace d03dmistakecorrection="2" if id_phcu_ym_s=="1309-13-12"	replace d23name1="MOHAMMED" if id_phcu_ym_s=="1316-13-12"	replace d18creasoncomment="""" if id_phcu_ym_s=="2611-13-12"	replace d18breasoncode="5" if id_phcu_ym_s=="2611-13-12"	replace d06breasoncode="4" if id_phcu_ym_s=="1301-13-11"	replace d08breasoncode="-999" if id_phcu_ym_s=="1301-13-11"	replace d12breasoncode="-996" if id_phcu_ym_s=="1301-13-11"	replace d13breasoncode="-996" if id_phcu_ym_s=="1301-13-11"	replace d14breasoncode="-996" if id_phcu_ym_s=="1301-13-11"	replace d15breasoncode="-996" if id_phcu_ym_s=="1301-13-11"	replace d01creasoncomment="""" if id_phcu_ym_s=="1301-13-11"	replace d03creasoncomment="""" if id_phcu_ym_s=="1301-13-11"	replace d06creasoncomment="""" if id_phcu_ym_s=="1301-13-11"	replace d10creasoncomment="""" if id_phcu_ym_s=="1301-13-11"	replace d23namesur="KHAMIS" if id_phcu_ym_s=="1301-13-11"	replace d24name3="MOHAMED" if id_phcu_ym_s=="1301-13-11"	replace d25comment="ADDED 3RD NAME" if id_phcu_ym_s=="1301-13-11"	replace d26name1="WAHABIA" if id_phcu_ym_s=="1301-13-11"	replace d26name2="ABASS" if id_phcu_ym_s=="1301-13-11"	replace d26corrects="CORRECTION" if id_phcu_ym_s=="1301-13-11"	replace d26comment="CORRECTED SUR NAME" if id_phcu_ym_s=="1301-13-11"	replace d23sid="4" if id_phcu_ym_s=="1302-13-11"	replace d23name1="HABIBA" if id_phcu_ym_s=="1302-13-11"	replace d23name2="MOHAMED" if id_phcu_ym_s=="1302-13-11"	replace d23name3="OTHMAN" if id_phcu_ym_s=="1302-13-11"	replace d23namesur="HAJI" if id_phcu_ym_s=="1302-13-11"	replace d23cadrecode="50" if id_phcu_ym_s=="1302-13-11"	replace d23daysworked="23" if id_phcu_ym_s=="1302-13-11"	replace d23corrects="NEW" if id_phcu_ym_s=="1302-13-11"	replace d04breasoncode="-999" if id_phcu_ym_s=="1304-13-11"	replace d01breasoncode="-996" if id_phcu_ym_s=="1305-13-11"	replace d02breasoncode="-996" if id_phcu_ym_s=="1305-13-11"	replace d05breasoncode="-996" if id_phcu_ym_s=="1305-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="1306-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="1307-13-11"	replace d02breasoncode="-999" if id_phcu_ym_s=="1307-13-11"	replace d04breasoncode="8" if id_phcu_ym_s=="1307-13-11"	replace d05adaysworked="-996" if id_phcu_ym_s=="1308-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="1308-13-11"	replace d02breasoncode="5" if id_phcu_ym_s=="1308-13-11"	replace d03breasoncode="-999" if id_phcu_ym_s=="1308-13-11"	replace d05dmistakecorrection="-996" if id_phcu_ym_s=="1308-13-11"	replace d04adaysworked="18" if id_phcu_ym_s=="1310-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="1310-13-11"	replace d02breasoncode="-999" if id_phcu_ym_s=="1310-13-11"	replace d04breasoncode="-999" if id_phcu_ym_s=="1310-13-11"	replace d05breasoncode="-996" if id_phcu_ym_s=="1310-13-11"	replace d23cadrecode="44" if id_phcu_ym_s=="1310-13-11"	replace d23daysworked="10" if id_phcu_ym_s=="1310-13-11"	replace d03breasoncode="-999" if id_phcu_ym_s=="1312-13-11"	replace d01creasoncomment="MARIE STOP" if id_phcu_ym_s=="1312-13-11"	replace d06dmistakecorrection="-996" if id_phcu_ym_s=="1312-13-11"	replace d23sid="-996" if id_phcu_ym_s=="1312-13-11"	replace d05creasoncomment="WORKING AT KENGEJA" if id_phcu_ym_s=="1313-13-11"	replace d02breasoncode="-999" if id_phcu_ym_s=="1315-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="1316-13-11"	replace d02breasoncode="-999" if id_phcu_ym_s=="1316-13-11"	replace d04breasoncode="-999" if id_phcu_ym_s=="1316-13-11"	replace d23name3="MOHAMMED" if id_phcu_ym_s=="1316-13-11"	replace d23comment="BACK FROM STUDY LEAVE" if id_phcu_ym_s=="1316-13-11"	replace d25name1="SAFIA" if id_phcu_ym_s=="1316-13-11"	replace d25name2="ABDALLA" if id_phcu_ym_s=="1316-13-11"	replace d25name3="MAKAME" if id_phcu_ym_s=="1316-13-11"	replace d01breasoncode="-999" if id_phcu_ym_s=="2602-13-11"	replace d03breasoncode="-999" if id_phcu_ym_s=="2602-13-11"	replace d04breasoncode="-999" if id_phcu_ym_s=="2602-13-11"	replace d23name3="MOHAMMED" if id_phcu_ym_s=="2603-13-11"	replace d23comment="N/S CARDE" if id_phcu_ym_s=="2603-13-11"	replace d24name2="KHERI" if id_phcu_ym_s=="2603-13-11"	replace d05adaysworked="0" if id_phcu_ym_s=="2604-13-11"	replace d05breasoncode="5" if id_phcu_ym_s=="2604-13-11"	replace d23name1="MARYAM" if id_phcu_ym_s=="2604-13-11"	replace d25namesur="MWADINI" if id_phcu_ym_s=="2604-13-11"	replace d01adaysworked="-996" if id_phcu_ym_s=="2605-13-11"	replace d18adaysworked="0" if id_phcu_ym_s=="2605-13-11"	replace d18breasoncode="3" if id_phcu_ym_s=="2605-13-11"	replace d07creasoncomment="LONG COURCE TRAINING" if id_phcu_ym_s=="2605-13-11"	replace d14creasoncomment="KIVUNGE HOSPITAL" if id_phcu_ym_s=="2605-13-11"	replace d15creasoncomment="LONG COURCE TRAINING" if id_phcu_ym_s=="2605-13-11"	replace d21creasoncomment="UNKNOWN" if id_phcu_ym_s=="2605-13-11"	replace d01dmistakecorrection="2" if id_phcu_ym_s=="2605-13-11"	replace d23name1="SALMA" if id_phcu_ym_s=="2605-13-11"	replace d10breasoncode="-996" if id_phcu_ym_s=="2607-13-11"	replace d08creasoncomment="need discussion - between 2 days in a week" if id_phcu_ym_s=="2607-13-11"	replace d23name3="SHUMBAGI" if id_phcu_ym_s=="2607-13-11"	replace d03creasoncomment="Fuoni PHCU" if id_phcu_ym_s=="2608-13-11"	replace d02creasoncomment="CHUINI" if id_phcu_ym_s=="2609-13-11"	replace d04breasoncode="-999" if id_phcu_ym_s=="2610-13-11"	replace d01creasoncomment="SUSPENDED" if id_phcu_ym_s=="2610-13-11"	replace d06adaysworked="19" if id_phcu_ym_s=="2612-13-11"	replace d06creasoncomment="IS A VOLUNTARY RETIRED WORKES" if id_phcu_ym_s=="2612-13-11"	replace d06dmistakecorrection="-996" if id_phcu_ym_s=="2612-13-11"
	
	foreach var in `numeric' {
		destring `var', replace 
	}
	
	sa "$TEMP/temp_2013`period'_dataentry_entry`ee'_clean", replace
}


*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

u "$TEMP/temp_2013`period'_dataentry_entry1_clean", clear
fn d*, loc(varlist)
cfout `r(varlist)' using "$TEMP/temp_2013`period'_dataentry_entry2_clean",  ///
	id(id_phcu_ym_s) u ///
	name("$ENTRY/`yy'_`period'/dataentry_2013101112_report_sectiond") replace		


*******************************************************************************
* Last minute changes
*******************************************************************************

u "$TEMP/temp_2013`period'_dataentry_entry1_clean", clear
ren v01healthfacilityname id_phcu_name

*******************************************************************************
* Save
*******************************************************************************

compress
sa "$CLEAN/de02_2013_`period'(reconciled)", replace

di "de02_2013_`period'(reconciled)"


