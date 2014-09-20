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
loc period 14_010203

************************************************************************
* Outsheet before leave
************************************************************************

u "$CLEAN/performance pay/`period'/pp04a_(pif_q)", clear

drop id_phcu_name
la var pp_v_dif_total_q_tzs 	"Bonus"
la var pp_v_phcu_q_tzs 			"Facility" 
la var pp_v_pif_total_q_tzs 	"Total"
order id_zone id_phcu pp_v_pif_total_q_tzs pp_v_dif_total_q_tzs pp_v_phcu_q_tzs 
export excel using "$VIEW/performance pay/`period'/pp_summary_byfacility_preround", sheetmodify   firstrow(varlabels)
