
* old version
u "$RAW/verification_201307", clear
drop pm*
sa "$RAW/verification_201307_temp", replace

* new versions
insheet using "$RAW/july2013verification_wnumber.csv", clear
sa  "$RAW/july2013verification_wnumber", replace
insheet using "$RAW/july2013verification_wnumber.csv", clear
sa  "$RAW/july2013verification_wonumber", replace

* merge new versions
u  "$RAW/july2013verification_wnumber", clear
merge 1:1 id_phcu_name using "$RAW/july2013verification_wonumber", nogen
replace id_phcu_name="Kiembe Samaki" if id_phcu_name=="Kiembe Samake"
replace id_phcu_name="Kisuani" if id_phcu_name=="Kisauni"

* merge in old version
merge 1:1 id_phcu_name using "$RAW/verification_201307_temp", gen(merge_07)
* missing Makombeni

order *, alpha
order id* ve* vi* pm*

sort id_district_name id_phcu_name

ren *island* *zone*

sa "$RAW/verification_201307_temp", replace

