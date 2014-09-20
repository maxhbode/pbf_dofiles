
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
				.f "not in form at time (.f -995)" 
				.e "PHCU not yet operational (.e)"
				.h "service not offered by PHCU (.g)"
				" ;
#delimit cr

#delimit ;
la de missingl 		$missing, replace ;
la de mvl 			0 "ok (0)" 
					1 "missing (1)", replace ;
la de yesnol 		0 "no (0)" 
					1 "yes (1)" 
					$missing, replace ;	
la de zonel			1 "Pemba (1)" 
					2 "Unguja (2)"
					$missing, replace ;
la de districtl 	3 "Mkoani (pop: 121,346)" 
					6 "West (pop: 140,864)"
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

* Month perfect
foreach yy in 13 14 {
	tokenize `c(Mons)'
	forval m = 1/12 {
		loc mm = "`m'"
		if `m'<10 {
			loc mm = "0`m'"
		}
		
		loc id_period_ym_label `id_period_ym_label' `yy'`mm' "``m'' `yy'"
		/*
		if `yy'==13 & `mm'<=6 {
			loc id_period_ym_label `id_period_ym_label' `yy'`mm' "``m'' `yy' (bl)"
		}
		*/
	}
}
di `"`id_period_ym_label'"'
la de id_period_yml `id_period_ym_label', replace

* HOW HIGH IS A PUBLIC HEALTH NURSE?
#delimit ;
la de cadrecodel 
	10	"MD (10)"
	20	"AMO (20)"
	21 	"Public Health Nurse A (21)" 
	30	"Clinical Officer (30)" 	
	31	"Community Health Nurse (31)"
	32 	"Dental Therapist (32)"	
	40	"Pharm. Technician (40)" 
	41	"Nurse General (41)" 
	42	"Nurse Midwife (42)" 
	43	"Nurse Psychiatrist (43)" 	
	44	"Environmental Health Officer (44)" 	
	45	"Lab. Technician (45)" 
	50	"Public Health Nurse B (50)"	
	60	"Lab. Assistant (60)" 
	61	"MCH Aide (61)" 
	62	"Pharm. Assistant (62)" 
	63	"Pharm. Dispenser (63)" 
	64	"Health Assistant (64)" 
	65	"Dental Assistant (65)" 			
	70	"Orderly/SG/Watchman (70)"
	, replace ;

la de districtl 
	11 "Chakechake" 
	12 "Micheweni"
	13 "Mkoani"
	14 "Wete"
	21 "Central"
	22 "North A"
	23 "North B"
	24 "South"
	25 "South"
	26 "West"
	27 "Urban"
	, replace ;

	
la de bankl
	1 "PBZ"
	2 "PBZ Islamic"
	3 "NBC"
	4 "Postal Bank"
	5 "FBME"
	, replace ;	
	
#delimit cr 
