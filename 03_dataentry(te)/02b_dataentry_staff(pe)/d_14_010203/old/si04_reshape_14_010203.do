
u "$TEMP/si02_14_0102003(cleaninputs)", clear

*************************************************************************
* Reshape
*************************************************************************
/*
sort id_hw id_period_mm
order id* c*, last
order id_hw id_period_mm

*br id_hw id_period_mm hw01* hw02* hw03* hw04*
*keep id_hw id_period_mm hw07_daysworked hw01_name_1 hw02_name_2 hw03_name_3 hw04_name_sur

drop confirm corrected id_phcu_s source_changetype source_comment id_phcu_ym hw13_comment* hw12_bankcode_number hw11_account_number
drop hw09_reason_code hw10_reason_comment

reshape wide hw07_daysworked, i(id_hw) j(id_period_mm) 


* hw09_reason_code hw10_reason_comment id_phcu
ren hw07_daysworked* hw07_daysworked_*

*************************************************************************
* Manipulate Values
*************************************************************************

*-----------------------------------------------------
* Days worked
*-----------------------------------------------------

fn hw07*
foreach var in `r(varlist)' {
	replace `var'=0 if `var'>=.
}

order id_hw id_phcu hw05* id_hw hw07* 
*/


*************************************************************************
* Save
*************************************************************************

order *, alpha
order id_hw id_phcu id*
qui compress
sa "$CLEAN/soi03_2013q4(reshape)", replace


