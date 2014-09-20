set linesize 225

*******************************************************************************
* Put file names into locals
*******************************************************************************
loc 13_q4		"dea02(rename)"
loc 13_q4_10	"deb02(reshape_manipulate_valuefix)" /*06-10/2013 */
loc 13_1112 	"dec04(manipulate)" /* 11,12/2013 */
loc 14_010203	"ded04(manipulate)" /* 01-03/2014 */
loc 14_040506	"dee05(merge)" /* 04-06/2013 & 04-06/2014 */
loc 1314_nonpbf "def02(manipulate)" /* non-pbf data */ 

*******************************************************************************
* Temporarily delete vars other than Section B and C 
*******************************************************************************

*******************************************************************************
* Prepare for appending
*******************************************************************************

foreach file in `13_q4' `13_q4_10' `13_1112' `14_010203' `14_040506' `1314_nonpbf' {
	di as error "`file'"

	u "$TEMP/`file'", clear
	
	
	cap: g treatment=1 
	cap: la var treatment "Treatment"
	cap: la val treatment yesnol

	
	keep id* b* c* treatment
	cap: drop *comment* 
	cap: drop *problem*
	order id* b* c*
	loc tempfile = substr("`file'",1,3)

	*-----------------------------------------------------
	* Making Time ID
	*-----------------------------------------------------
	cap: drop id_period_ym
	g id_period_ym = id_period_yyyy*100+id_period_mm-200000
	la val id_period_ym  id_period_yml
	cb  id_period_ym
	
	* Save
	*-----------------------------------------------------
	compress
	tempfile temp_`tempfile'
	sa `temp_`tempfile'', replace

}


*******************************************************************************
* Inspect dea
*******************************************************************************

/*
u  `temp_dea', clear

keep id_phcu id_phcu_name id_period_ym c05_v_g c05_v_t
order id*

g c05_v_g_pct = c05_v_g/c05_v_t 
replace c05_v_g_pct = .z if c05_v_g>=. | c05_v_t>=.
*/

*******************************************************************************
* Renaming variables (so they match each other across time) 
*******************************************************************************

*-----------------------------------------------------
* 11,12/2013 +  01-03/2014
*-----------------------------------------------------

foreach file in temp_deb temp_dec {
	u ``file'', clear
	
	ren c12* b08*
	ren c13* b07*
	ren c04*t c04*g
	ren b06* b99*
	ren b05* b06*
	ren b99* b05*
	
	order *, alpha
	order id*
	sa ``file'', replace	
}


*-----------------------------------------------------
* 04-06/2013 & 04-06/2014
*-----------------------------------------------------

u  `temp_dee', clear

ren c12* b07*
ren c13* b08* 	
order *, alpha

* Drop new PHCU from baseline
ta id_phcu_name if id_phcu==1317
drop if id_period_ym<1400 & id_phcu==1317
ta id_period_ym  if id_phcu==1317

order id*
sa  `temp_dee', replace

*-----------------------------------------------------
* Non-PBF
*-----------------------------------------------------

u `temp_def', clear 

ren c05* c08*
ren c04* c06*
ren c03* c05*
ren c02* c04*

sa `temp_def', replace

*-----------------------------------------------------
* Checks
*-----------------------------------------------------
*u `temp_deb', clear /* b01-b08,  c01-c11 */
*u `temp_dec', clear /* b01-b08,  c01-c11 */
*u `temp_ded', clear /* b01-b08,  c01-c11 */
*u `temp_dee', clear /* b01-b08,  c01-c11 */
*u `temp_def', clear /* b01-b02,  c01-c08 */

*******************************************************************************
* Merge 1 period from 2 datasets
*******************************************************************************

* Select 1306 observations from dee
*-----------------------------
u `temp_dee', clear  

ta id_period_ym
keep if id_period_ym==1306 
fn b* c*
dropmiss `r(varlist)', force
fn b* c*, loc(dee) 

tempfile temp_dee_1306
sa `temp_dee_1306', replace

* Select 1306 observations from deb
*-----------------------------
u `temp_deb', clear 

ta id_period_ym

keep if id_period_ym==1306 

codebook c03*

* Drop variables found in dee
fn b00*  b01*  b02*  c01* c04*  c05* c06* c08* *skip, remove(*_nv_* *_v_* )
drop  `r(varlist)'

tempfile temp_deb_1306
sa `temp_deb_1306', replace

* Merge
*-----------------------------
u `temp_deb_1306', clear   /*06-10/2013 */
drop b* c01* c04* c05* c06* c08*

merge 1:1 id_phcu using `temp_dee_1306' /* 04-06/2013 & 04-06/2014 */

compress
tempfile temp_de_merge1306
sa `temp_de_merge1306', replace


/* INVESTIGATING DIFFERENCE BETWEEN TWO VERSION OF 1306
*-----------------------------
u `temp_deb', clear 

ta id_period_ym
keep if id_period_ym==1306 
fn b00*  b01*  b02*  c01*  c02*  c03*  c04*  c05* c06* c08*
keep id* `r(varlist)'
fn *_nv_* *_v_* 
drop `r(varlist)'

ren b* o_b*
ren c* o_c* 

tempfile temp_deb_1396
sa `temp_deb_1396', replace

*-----------------------------
u `temp_dee_1396', clear
merge 1:1 id_phcu using  `temp_deb_1396'
list id_phcu_name if _merge==1


drop c0_* b0_*

foreach var in b00_g b00_t b01_g b01_t b02_g b02_t c01_g c01_t c05_g c05_t c06_t c08_t {
	su o_`var' `var' if o_`var'<. & `var'<.
	
	g `var'_d = (o_`var'-`var')/o_`var'
	su `var'_d
}


* Difference of sum
fn *b00_g *b00_t *b01_g *b01_t *b02_g *b02_t *c01_g *c01_t *c05_g *c05_t *c06_t *c08_t
collapse (sum) `r(varlist)'


di as error "Headcounts"
foreach var in b00_t b01_t b02_t c01_t c05_t c06_t c08_t {

	su o_`var' `var' if o_`var'<. & `var'<.
	
	g `var'_d = (o_`var'-`var')/o_`var'
	su `var'_d
}

di as error "Quality"
foreach var in b00_g b01_g b02_g c01_g c05_g  {

	
	su o_`var' `var' if o_`var'<. & `var'<.
	
	g `var'_d = (o_`var'-`var')/o_`var'
	su `var'_d
}
*/


*******************************************************************************
* Open and append files
*******************************************************************************

*-----------------------------------------------------
* Open: 06-10/2013
*-----------------------------------------------------

u `temp_deb', clear
drop if id_period_ym==1306 /* collected twice and merging it in separate */ 



*-----------------------------------------------------
* Append: 11,12/2013
*-----------------------------------------------------

append using `temp_dec'

*-----------------------------------------------------
* Append 01-03/2014
*-----------------------------------------------------
append using `temp_ded' /* (b00-b08) (c01-c09) */

*-----------------------------------------------------
* Append 04-05/2013 & 04-06/2014
*-----------------------------------------------------

append using `temp_dee'
drop if id_period_ym==1306 /* collected twice and merging it in separate */ 

*-----------------------------------------------------
* Append 06/2013 
*-----------------------------------------------------

append using `temp_de_merge1306'
ta id_period_ym



*-----------------------------------------------------
* Append with q4 live data
*-----------------------------------------------------
*append using `temp_dea'

*-----------------------------------------------------
* Append non-pbf data
*-----------------------------------------------------

append using `temp_def'

ta treatment

fn b00* b01* b02* c01* c04* c05* c06* c08*, remove(*_v_* *_nv_* c06_g)

bys id_period_ym: su `r(varlist)'  

*************************************************************************
* Merge: variable name fix
*************************************************************************

* Added variable field
foreach type in _v_ _nv_ {
	replace c04`type't = .f 		if id_period_yyyy<2014
	replace c03`type'g = .f 		if id_period_yyyy<2014
	
}

*************************************************************************
* Fix ID_PHCU_YM
*************************************************************************

codebook id_phcu_ym

drop *_s id_phcu_ym
foreach var in id_phcu id_period_ym {
	tostring `var', gen(`var'_s)
}

g id_phcu_ym_s = id_phcu_s +"_"+ id_period_ym_s
g id_phcu_ym = id_phcu_s + id_period_ym_s
destring  id_phcu_ym, replace
codebook id_phcu_ym
order id_phcu_ym*


*bys id_phcu: su  b00_g_pct if id_period_ym==1304 & treatment==1


*************************************************************************
* Recollected missing data
*************************************************************************

* Kengeja
replace b01_t=291 if id_phcu==1304 & id_period_ym==1307
replace b01_t=178 if id_phcu==1304 & id_period_ym==1308
replace b01_t=247 if id_phcu==1304 & id_period_ym==1309

replace b02_t=272 if id_phcu==1304 & id_period_ym==1307
replace b02_t=125 if id_phcu==1304 & id_period_ym==1308
replace b02_t=144 if id_phcu==1304 & id_period_ym==1309

replace b01_g=26/87*b01_t if id_phcu==1304 & id_period_ym==1307
replace b01_g=22/71*b01_t if id_phcu==1304 & id_period_ym==1308
replace b01_g=56/75*b01_t if id_phcu==1304 & id_period_ym==1309

replace b02_g=13/78*b02_t if id_phcu==1304 & id_period_ym==1307
replace b02_g=8/56*b02_t if id_phcu==1304 & id_period_ym==1308
replace b02_g=6/60*b02_t if id_phcu==1304 & id_period_ym==1309

* Kiwani
replace b02_t=86 if id_phcu==1306 & id_period_ym==1309
replace b02_g=44/53*b02_t if id_phcu==1306 & id_period_ym==1309

* Mwambe 
replace b02_t=129 if id_phcu==1311 & id_period_ym==1307
replace b02_g=3/61*b02_t if id_phcu==1311 & id_period_ym==1307

replace b02_t=64 if id_phcu==1311 & id_period_ym==1308
replace b02_g=1/41*b02_t if id_phcu==1311 & id_period_ym==1308

* Calc b00
replace b00_g = b01_g+b02_g if inlist(id_phcu,1304,1306,1311)
replace b00_t = b01_t+b02_t if inlist(id_phcu,1304,1306,1311)

codebook b00_t b00_g b01_t b01_g b02_t b02_g if inlist(id_phcu,1304,1306,1311)

list id_phcu id_phcu_name id_period_ym b02_g if b02_g>=. & inlist(id_phcu,1304,1306,1311)

*******************************************************************************
* Save
*******************************************************************************

drop id_phcu_s id_period_q id_period_y id1 id2 id3 id_facility

sort  id_phcu_ym
order  *, alpha
order id_phcu_ym id_phcu id_phcu_name  ///
	id_zone id_district id_period_mm id_period_yyyy id_period_ym 
order b0_* b* c0_* c*, last
qui compress
sa "$CLEAN/tc_02(merge)", replace
