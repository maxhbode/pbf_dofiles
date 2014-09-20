
*----------------------------------------------------------------------
*  Define value labels
*----------------------------------------------------------------------

* Missing value global
#delimit ;
global missing 	"
				.a "not applicable (.a -999)" 
				.b "not available (.b -998)" 
				.c "not reported by PHCU (.c -997)" 
				.d "not reported by enumerator (.d -996)" 
				" ;
#delimit cr

#delimit ;
la de missingl 		$missing, replace ;
la de mvl 			0 "ok" 
					1 "missing", replace ;
la de yesnol 		0 "No" 
					1 "Yes" 
					$missing, replace ;	
la de zonel			1 "Pemba" 
					2 "Unguja"
					$missing, replace ;
la de districtl 	3 "Mkoani" 
					6 "West"
					$missing, replace ;							
#delimit cr


* Periods
forval y = 13/14 {

loc months `c(Mons)'
di "`months'"

	forval m = 1/12 {
		if `m'<10 loc m = "0`m'" 
	
		loc ym = `y'`m'	
		gettoken month months: months
		
		
		if `ym'<1307 	loc monthlist `monthlist' `ym' "`month' (BL)"
		else 			loc monthlist `monthlist' `ym' "`month'"
	}
}

di `"`monthlist'"'
la de months `monthlist', replace

* HOW HIGH IS A PUBLIC HEALTH NURSE?
#delimit ;
la de cadrecodel 
	10	"MD"
	20	"AMO"
	21 	"Public Health Nurse A" 
	30	"Clinical Officer" 	
	31	"Community Health Nurse"
	32 	"Dental Therapist"		
	33 	"Public Health Nurse A" 
	40	"Pharm. Technician" 
	41	"Nurse General" 
	42	"Nurse Midwife" 
	43	"Nurse Psychiatrist" 	
	44	"Environmental Health Officer" 	
	45	"Lab. Technician" 
	50	"Public Health Nurse B"	
	60	"Lab. Assistant" 
	61	"MCH Aide" 
	62	"Pharm. Assistant" 
	63	"Pharm. Dispenser" 
	64	"Health Assistant" 
	65	"Dental Assistants" 			
	70	"Orderly/SG/Watchman", replace ;
#delimit cr 

