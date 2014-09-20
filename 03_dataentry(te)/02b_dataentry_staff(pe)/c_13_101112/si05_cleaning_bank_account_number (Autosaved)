
set linesize 225

*-----------------------------------------
* Merge Pemba and Unguja
*-----------------------------------------

tempfile Pemba	

import excel using "$RAW/staff/bank_accountnumber_2013q4.xls", ///
	clear sheet(Pemba) firstrow
	dropmiss *, obs force
g id_zone="Pemba"
sa `Pemba', replace
describe, short

import excel using "$RAW/staff/bank_accountnumber_2013q4.xls", ///
	clear sheet(Unguja) firstrow	
dropmiss *, obs force
g id_zone="Unguja"
describe, short

append using `Pemba'
cap: drop K
describe, short

*-----------------------------------------
* Order
*-----------------------------------------

order StaffID

*-----------------------------------------
* Drop observations 
*-----------------------------------------

* Drop totals
drop if inlist(RealizedBonusQ42013rounded,20308000,30049000, 29903000)

* --- Corrections already happend in original ---*
* Kiembe Samaki: Delete ATKA 
* Magogoni: Only 1 Makame Handu
* Chuidni: Delete Fatma Abdalla Othman
* Kumbeni: Delete Suleiman Said

/* don't delete this observation
list StaffID PCHUname Name1 Name2 Name3 SurName BankAccountnumber Bankname ///
	if PCHUname=="Magogoni" & Name1=="OMAR" &Name2=="PANDU"
drop if StaffID==261114 
*/

*-----------------------------------------
* Signature
*-----------------------------------------

g Signature_note=""

replace Signature=1
replace Signature=0 if StaffID==260103
la de yesnol 0 "No" 1 "Yes"
la val Signature yesnol
cb Signature

replace Signature_note="Sick, out of country" if StaffID==260103

list StaffID PCHUname Name1 Name2 Name3 if Signature==0

*-----------------------------------------
* Clean data
*-----------------------------------------

replace BankAccountnumber="035063" if StaffID==261003   

replace PCHUname = trim(PCHUname)

* Checking length of Bank account number
replace Bankname = trim(Bankname)
ta Bankname

g ba_length = length(BankAccountnumber)
ta ba_length

ta ba_length Bankname, mi

g ba_lengthcheck = 0 
replace ba_lengthcheck = 1 if ba_length==6 & Bankname=="FBME B"
replace ba_lengthcheck = 1 if ba_length==10 & Bankname=="NMB"
replace ba_lengthcheck = 1 if ba_length==11 & Bankname=="Postal Bank"
replace ba_lengthcheck = 1 if ba_length==12 & Bankname=="PBZ"
replace ba_lengthcheck = 1 if ba_length==12 & Bankname=="NBC"
replace ba_lengthcheck = 1 if ba_length==14 & Bankname=="PBZ Islamic Bank"

ta Bankname ba_lengthcheck

set linesize 225
list PCHUname  StaffID Name1 Name2 Name3 BankAccountnumber Bankname ba_lengthcheck ba_length if ba_lengthcheck==0

*if ba_length== & Bankname=="FBME B"

*-----------------------------------------
* Rename old variables  
*-----------------------------------------

ren RealizedBonusQ42013rounded RealizedBonusQ42013r_old

*-----------------------------------------
* Save 
*-----------------------------------------

compress

export excel using "$DATA/2013q4_performancepay_new.xls", ///
	replace sheet(all) firstrow(varlabels)

sort PCHUname 

levelsof Bankname, loc(banks)
foreach b in `banks' {
	preserve
	keep if Bankname=="`b'"
	export excel using "$DATA/2013q4_performancepay_new.xls", ///
		sheetreplace sheet("`b'") firstrow(varlabels) 
	restore
}


ren StaffID id_hw
drop ba_length ba_lengthcheck
sa "$DATA/2013q4_performancepay_new", replace
