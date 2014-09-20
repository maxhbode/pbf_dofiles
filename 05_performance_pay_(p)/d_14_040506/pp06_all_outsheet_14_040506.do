/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT: 		PBF, Zanzibar, TZ
ORGANIZATION:	MoH, SMZ
PURPOSE: 		Calculate PBS subsidies
PROGRAMMER:		Max Bode, Economist (maxbode.moh.smz@gmail.com)
LAST MODIFIED: 	Jun 4 2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTROL PANEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set linesize 225

* Period name
loc yy 14
loc period 14_040506
loc m1 4
loc m2 5
loc m3 6
loc ym1 `yy'04
loc ym2 `yy'05
loc ym3 `yy'06
loc mm1 "Apr"
loc mm2 "May"
loc mm3 "Jun"

************************************************************************
* Prepare
************************************************************************

* OPEN STAFF DATA
u "$CLEAN/performance pay/`period'/pp04a_foroutsheeting(dif_q)", clear
fn id_zone  hw*, remove(pp_v_bonus_tzs_`period'_mia5)
drop `r(varlist)' id_hw id_hw_new_s


* Change id
replace id_hw_new = id_hw_new -  id_phcu*100000 
codebook id_hw_new
replace id_hw_new=19998 if id_hw_new==-260499799
replace id_hw_new=19999 if id_hw_new==-130399798
bys id_phcu: g n = _n
drop id_hw_new

* Reshape 
reshape wide pp_v_bonus_tzs_`period'_mia5, i(id_phcu) j(n)

fn pp_v_bonus_tzs_`period'_mia5*, loc(varlist)
egen pp_v_bonus_tzs_`period'_mia5 = rowtotal(`varlist')
drop `varlist' 

* OPEN PERFORMANCE IMPROVEMENT FUND DATA 
merge 1:1 id_phcu using "$CLEAN/performance pay/`period'/pp05a_(pif_q)"
ta id_phcu_name if _merge!=3
assert _merge==3
drop _merge

drop id_phcu_name id_zone

order *, alpha
order id*

ren pp_v_bonus_tzs_`period'_mia5 pp_v_bonus_`period'_tzs

************************************************************************
* Outsheet 
************************************************************************

* Label
la var pp_v_bonus_14_040506_tzs	"Bonus"
la var pp_v_pif_14_040506_tzs	"Facility"

* Total column
egen total = rowtotal(pp_v_pif_14_040506_tzs pp_v_bonus_14_040506_tzs)
la var total "TOTAL" 

* Total row
describe, s
loc N = `r(N)'+1
set obs `N'
sdecode id_phcu, replace
replace id_phcu="TOTAL" in `N'

foreach var in  pp_v_bonus_14_040506_tzs pp_v_pif_14_040506_tzs total {
	g sum_`var'=sum(`var')
	replace `var' = sum_`var' in `N'
	drop sum_`var'
	format %9.0f `var'
}

* Outsheet
export excel using "$VIEW/performance pay/`period'/pp_byfacility_piftotal", firstrow(varlabels) replace

