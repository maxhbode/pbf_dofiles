set linesize 225

*Setting value labels
run "$DO/01b_all_value_labels.do"

* Create PHCU locals
loc id_phcu = "$ID_PCHU"
di "`id_phcu'"

loc id_phcu_sin1 : subinstr loc id_phcu "1301 " ""
di "`id_phcu_sin1'"

*************************************************************************
* Import and Append by Month
*************************************************************************
forval m = 10/12 {

	* Import all facilities, at all months
	foreach phcu in `id_phcu' {
	
		import excel using "$RAW/staff/20140212_staffdata_2013_`m' copy.xls", clear firstrow sheet("`phcu'")

		* Drop Empty Observations
		dropmiss, obs force
		
		*di as error "`m' - `phcu'"
		
		* Fix IDs
		drop id_phcu id_phcu_ym
		g id_phcu = `phcu'
		g id_phcu_ym =  `phcu'*10000+1300+`m'
		
		* Save
		sa "$TEMP/staffdata_2013_`m'_`phcu'", replace
	
	}	
	
	* Append within month
	u "$TEMP/staffdata_2013_`m'_1301", clear
	
	foreach phcu in `id_phcu_sin1' {

		append using  	"$TEMP/staffdata_2013_`m'_`phcu'"
		
		*erase 			"$TEMP/staffdata_2013_`m'_`phcu'"

	}
	
	g id_period_mm=`m'
	sa "$TEMP/staffdata_2013_`m'", replace
		
	codebook id_phcu, t(30)
}

*************************************************************************
* Rundimentary pre-merge clean
*************************************************************************
forval m = 10/12 {
	u "$TEMP/staffdata_2013_`m'", clear
	
	order id*

	* Rename
	cap: ren bankcode		bankcode_number

	* Drop Empty Observations
	dropmiss, obs force
	
	* Drop/Rename vars in specific months
	if `m'==10 {
		drop S 
		rename T comment
	}

	if `m'==11 {
		drop S
	}

	sa "$TEMP/clean_staffdata_2013_`m'", replace
}


*************************************************************************
* Append months
*************************************************************************

u "$TEMP/clean_staffdata_2013_10", clear
append using "$TEMP/clean_staffdata_2013_11"
append using "$TEMP/clean_staffdata_2013_12"

ta id_period_mm, mi

sa "$TEMP/clean_staffdata_2013_q4", replace

*************************************************************************
* Clean data
*************************************************************************

u "$TEMP/clean_staffdata_2013_q4", clear

* Rename
ren account_number 		hw11_account_number
ren bankcode_number		hw12_bankcode_number
ren comment 			hw13_comment
ren hw09_reason_comment	hw10_reason_comment
ren hw10_reason_code	hw09_reason_code

* Order
order *, alpha
order id* c* s* hw*

* String values in Numeric variables
replace hw11_account_number="" if hw11_account_number=="missing"
replace hw09_reason_code="" if inlist(hw09_reason_code,"996","999")
replace hw10_reason_comment="UNKNOWN" if hw09_reason_code=="UNKOWN"
replace hw09_reason_code="8" if hw09_reason_code=="UNKOWN"


* Destring
loc numeric id_hw hw05_cadre_code	hw06_mistake  hw07_daysworked	///
	hw09_reason_code hw11_account_number hw12_bankcode_number


foreach var in `numeric' {
	di as error "Destringing `var'"

	destring `var', replace
}

* Encode
foreach var in confirm	corrected source_changetype {
	replace `var' = trim(upper(`var'))	
}

replace source_changetype="NEW" if source_changetype=="ADDED"
replace source_changetype="CORRECTION" if source_changetype=="NAME CORRECTED"
replace confirm="NO" if source_changetype=="DELETE"
replace source_comment="CADRE" if source_changetype=="CARDE"
replace source_changetype="NEW" if corrected=="NEW"
replace corrected="" if corrected=="NEW"
replace source_changetype="" if inlist(source_changetype,"DELETE","CARDE")

foreach var in confirm	corrected source_changetype {
	sencode `var', replace	
	cb `var'
}

* Temporarily drop variables
drop hw06_mistake

*************************************************************************
* Drop staff that needs to be dropped
*************************************************************************

cb confirm
ta id_period_mm confirm, mi
drop if confirm==1
* & (id_period_mm==11 | id_period_mm==12)
drop if hw01_name_1==""

*************************************************************************
* Improve IDs
*************************************************************************

preserve
u "$CLEAN/PHCU_IDs", clear
drop id1 id2 id3 id4 id_d* id_z*
sa "$TEMP/PHCU_IDs", replace
restore

drop id_phcu_name
sort id_phcu
merge m:1 id_phcu using  "$TEMP/PHCU_IDs", nogen
order id*

*************************************************************************
* Correct Values
*************************************************************************

* All values
do "$DO/02_DATAENTRY(de)/staffinfo(si)/si02b_2013q4(valuecorrections)"


* Account numbers
ta hw13_comment
g hw13_comment_c = 0
replace hw13_comment_c = 1 if hw13_comment!=""
replace hw13_comment_c = 0 if hw13_comment=="on study fail to get account number"
la de hw13_comment_cl 0 "Normal" 1 "Starts with 0"
la val hw13_comment_c hw13_comment_cl
ta hw13_comment hw13_comment_c, mi 

*tostring hw12_bankcode_number 


stop


/*
order id_hw id_period_mm hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur
sort id_hw
br if id_phcu==2611
*/


*************************************************************************
* Save
*************************************************************************

compress
sa "$TEMP/si02_2013q4(cleaninputs)", replace



