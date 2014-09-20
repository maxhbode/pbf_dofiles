


import excel using "$RAW/hr/HR Export 13-03-2013.xlsx", firstrow sheet(Active) clear
drop U

fn *
foreach var in `r(varlist)' {
	loc newvar=lower("`var'")
	ren `var' `newvar'
}

compress
sa "$TEMP/hr01(insheet)", replace

