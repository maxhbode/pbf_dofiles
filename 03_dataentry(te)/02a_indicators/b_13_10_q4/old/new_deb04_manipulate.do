
*******************************************************************************
* DATA MANIPULATION
*******************************************************************************

*-----------------------------------------------------
* B01 & B02: Calculate "REAL G" from SG and S
*-----------------------------------------------------

* Rename "FAKE G"
foreach m in 06 07 08 09 v_10 nv_10 {
	forval var = 1/2 {
		ren b0`var'_g_`m' b0`var'_sg_`m' 
	}
}

* Generate "REAL G" 
foreach m in 06 07 08 09 v_10 nv_10 {
	forval var = 1/2 {
		g b0`var'_g_`m' 	= (b0`var'_sg_`m' / b0`var'_s_`m') * b0`var'_t_`m'
		*g b0`var'_g_`m'_pct = (b0`var'_sg_`m' / b0`var'_s_`m')
		replace b0`var'_g_`m' = 0 if b0`var'_s_`m'==0 & b0`var'_sg_`m'==0
		replace b0`var'_g_`m' = .d if b0_section_skip==1				
	}
}

* DROP ALL THE SAMPLING VARS
fn b*_s_* b*_sg_*
drop `r(varlist)'

*-----------------------------------------------------
* B00: Sum U5 & O5 together for B01 & B02
*-----------------------------------------------------

* Sum U5 & O5 together for B01 & B02
foreach m in 06 07 08 09 v_10 nv_10 {
	foreach type in t g {
		di as result "b00_`type'_`m' created"
		g b00_`type'_`m' = b01_`type'_`m' + b02_`type'_`m'
	}
}



* Consider FUONI EXCEPTION
fn b00*
foreach var in `r(varlist)' {
	loc suffix = substr("`var'",5,4)
	
	replace b00_`suffix' = b01_`suffix' if id_phcu==2605
	replace b01_`suffix' = .d if id_phcu==2605
	replace b02_`suffix' = .d if id_phcu==2605
}


*-----------------------------------------------------
* All B & C variables: SUM V+NV
*-----------------------------------------------------

foreach section in b c {
if "`section'"=="b" loc range 0/6
if "`section'"=="c" loc range 1/13
		forval question = `range' {
		if `question'<10 loc question = "0`question'"
				
		egen `section'`question'_t_10 = ///
			rowtotal(`section'`question'_t_v_10 `section'`question'_t_nv_10)
	
		cap: egen `section'`question'_g_10 = ///
			rowtotal(`section'`question'_g_v_10 `section'`question'_g_nv_10)
	}
}


order *, alpha
order id* b*skip b* c*skip c*
