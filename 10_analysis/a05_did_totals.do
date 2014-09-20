
*****************************************************
* Graph Options
*****************************************************

* Set globals for working in DOFILE
global FORMAT pdf
global SCHEME s2color 

* Choose format: pdf or png
loc format $FORMAT

* Choose color scheme: s2color or s2mono
loc scheme $SCHEME  
set scheme `scheme' 

* Create folder name
if 		"`format'"=="pdf" 	loc formatf "high quality files"
else if "`format'"=="png"	loc formatf "image files"

if 		"`scheme'"=="s2color" 	loc schemef "color -"
else if "`scheme'"=="s2mono"	loc schemef "greyscale -"

loc folder "`schemef' `formatf' (`format')"

*****************************************************
* OPEN FILE
*****************************************************

u "$CLEAN/tc_05(label)", clear


keep id_period_ym treatment  treatment_temporal b00* b01* b02* c01* c04* c05*  c08*  c06* 
drop *_nv_* *_v_* *_g *_pct


bys treatment: su b00_t b01_t b02_t c01_t c04_t c05_t c06_t c08_t 

*----------------------------------------------------
* Label
*----------------------------------------------------

loc i = 1

forval y = 13/14 {

loc months `c(Mons)'
di "`months'"

	forval m = 1/12 {
		if `m'<10 loc m = "0`m'" 
	
		loc ym = `y'`m'	
		gettoken month months: months
		
		
		if `ym'<1307 	loc monthlist `monthlist' `ym' "`month' (BL)"
		else 			loc monthlist `monthlist' `ym' "`month'"
		
		if `ym'<1307 	loc monthlist2 `monthlist2' `i' "`month' `y'"
		else 			loc monthlist2 `monthlist2' `i' "`month' `y'"
	
		loc ++i
	}
}

*----------------------------------------------------
* Total variable
*----------------------------------------------------

keep id* *_t t*

* Collapse and reshape
fn c* b*, loc(varlist)
collapse (sum) `varlist', by(id_period_ym treatment  treatment_temporal)


reshape wide `varlist', i(id_period_ym  treatment_temporal)  j(treatment)

* Time issues 
di `"`monthlist2'"'
la de months2 `monthlist2'

sort id_period_ym 
g id_period_m = _n
replace id_period_m = id_period_m + 3
la val id_period_m  months2
la var id_period_m "Month"
cb id_period_m


*----------------------------------------------------
* Without ratios
*----------------------------------------------------




#delimit ;
twoway	(line b00_t0 id_period_m) 
		(line b00_t1 id_period_m),
		xlabel(4(1)18)
;
#delimit cr

stop

*----------------------------------------------------
* Create ratio
*----------------------------------------------------
foreach var in `varlist' {
	g `var' = `var'0/`var'1
}


* Extract value in 1306
foreach var in `varlist' {
preserve
	keep if id_period_ym==1306
	levelsof `var', loc(`var'_level_1306)
	di "``var'_level_1306'"
restore 	
}

foreach var in `varlist' {
	g `var'_ratio = round(`var'/``var'_level_1306'-1,0.00000000001)
}

drop *t0 *t1 *t
order *, alpha
order id* t*

#delimit ;
twoway	(line b01_t_ratio id_period_m) 
		(line b02_t_ratio id_period_m),
		ylabel(-5(1)5)
;
#delimit cr


#delimit ;
twoway	(line b00_t_ratio id_period_m) 
		(line b01_t_ratio id_period_m) 
		(line c01_t_ratio id_period_m) 
		(line c05_t_ratio id_period_m) 
		(line c06_t_ratio id_period_m) 
		(line c08_t_ratio id_period_m),
		ylabel(-5(1)5)
;
#delimit cr



la var c06_g_pct `" "Health Facility Delivery" "with treatment according to guidlines (%)" "'
la var c08_g_pct `" "Family Planning" "with treatment according to guidlines (%)" "'





