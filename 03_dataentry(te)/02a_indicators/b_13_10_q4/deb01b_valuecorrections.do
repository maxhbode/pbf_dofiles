

* (1) Normal differences
* (2) Ex-post correction to id_phcu==2607   
* (3) Missed id_phcu==2611 in one entry 

* (1) Normal differences


* (2) Ex-post correction
replace xb01_t06=321 if id_phcu==2607   
replace xb01_s06=62  if id_phcu==2607      
replace xb01_g06=7   if id_phcu==2607    
replace xb01_t08=315 if id_phcu==2607    
replace xb01_s08=65  if id_phcu==2607     
replace xb01_g08=9   if id_phcu==2607     
replace xb01_t07=215 if id_phcu==2607    
replace xb01_s07=49  if id_phcu==2607    
replace xb01_g07=26  if id_phcu==2607   
replace xb01_t09=210 if id_phcu==2607     
replace xb01_s09=46  if id_phcu==2607   
replace xb01_g09=36  if id_phcu==2607  

* (3) Missed id_phcu==2611 in one entry
replace a01a_stg_required=1 if id_phcu==2611