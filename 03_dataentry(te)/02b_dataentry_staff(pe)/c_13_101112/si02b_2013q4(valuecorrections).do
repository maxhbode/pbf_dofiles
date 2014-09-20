
*************************************************************************
* Correct Values
*************************************************************************
sort id_hw id_period_mm
/*
list id_hw id_phcu_name id_period_mm hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur ///
	hw05_cadre_code	hw07_daysworked if id_phcu==2611
*/

* Dropping Obs
drop if id_hw==260323
drop if id_hw==130402 & id_period_mm==10 & hw01_name_1=="FATMA"drop if id_hw==130402 & id_period_mm==11 & hw01_name_1=="FATMA"drop if id_hw==130703 & id_period_mm==10 & hw01_name_1=="MWANAISHA"drop if id_hw==131502 & id_period_mm==10 & hw01_name_1=="MWANAISHA"drop if id_hw==131625 & id_period_mm==10 & hw01_name_1=="SAFIA"drop if id_hw==131625 & id_period_mm==11 & hw01_name_1=="SAFIA"drop if id_hw==261001 & id_period_mm==10 & hw01_name_1=="SULEIMAN"drop if id_hw==130402 & id_period_mm==12 & hw01_name_1=="FATMA" // why are these not being dropped?drop if id_hw==130703 & id_period_mm==12 & hw01_name_1=="MWANAISHA" // why are these not being dropped?drop if id_hw==131502 & id_period_mm==12 & hw01_name_1=="MWANAISHA" // why are these not being dropped?drop if id_hw==261001 & id_period_mm==12 & hw01_name_1=="SULEIMAN" // why are these not being dropped?

* Correcting IDs
*-----------------------------------
replace	id_hw=261407	if	id_hw==261405	&	hw01_name_1=="MWANAIWANI"	&	id_period_mm==12replace	id_hw=261204	if	id_hw==261203	&	id_period_mm==11		replace	id_hw=261203	if	id_hw==261206	&	id_period_mm==11		replace	id_hw=261126	if	id_hw==261123	&	hw01_name_1=="ASMA"		&	id_period_mm==12
replace	id_hw=261125	if	id_hw==261126	&	hw01_name_1=="FATMA"	&	id_period_mm==12
replace	id_hw=261120	if	id_hw==261125	&	hw01_name_1=="FAIDA"	&	id_period_mm==12* replace	id_hw=261120	if	id_hw==261125	&	hw01_name_1=="FAIDA"		replace	id_hw=260532	if	id_hw==260527	&	hw01_name_1=="SAADA"		replace	id_hw=260531	if	id_hw==260525	&	hw01_name_1=="RAMLA"	&	id_period_mm==12replace	id_hw=260530	if	id_hw==260528	&	hw01_name_1=="MAKAME"		replace	id_hw=260530	if	id_hw==260527	&	hw01_name_1=="MAKAME "replace	id_hw=260525	if	id_hw==260524	&	hw02_name_2=="FADHIL"	&	id_period_mm==12replace	id_hw=260424	if	id_hw==260423	&	hw01_name_1=="FATHIYA"	&	id_period_mm==12replace	id_hw=260423	if	id_hw==260424	&	hw01_name_1=="MARYAM"	&	id_period_mm==12replace	id_hw=260308	if	id_hw==260306	&	hw01_name_1=="KOMBO"	&	id_period_mm==12replace	id_hw=260307	if	id_hw==260305	&	hw01_name_1=="KHADIJA"	&	id_period_mm==12replace	id_hw=260305	if	id_hw==260324	&	hw01_name_1=="KOMBO"	&	id_period_mm==11* replace	id_hw=131306	if	id_hw==131305	&	hw01_name_1=="SHARIFA"	&	id_period_mm==11 replace	id_hw=131206	if	id_hw==131223	&	hw01_name_1=="SAFIA"	&	id_period_mm==12replace	id_hw=130224	if	id_hw==130223	&	hw01_name_1=="OTHMANA"	&	id_period_mm==12
replace id_hw=130123 	if 	id_hw==130124 	& 	hw01_name_1=="BIMKUBWA"	& 	id_period_mm==12 	
replace id_hw=130124 	if 	id_hw==130123 	& 	hw01_name_1=="ALI"		& 	id_period_mm==12 
replace id_hw=131624 	if 	id_hw==131605 	& 	hw01_name_1=="FATMA"	& 	id_period_mm==12
replace id_hw=131603 	if 	id_hw==131623 	& 	hw01_name_1=="MAFUNDA"	& 	id_period_mm==11
replace id_hw=260723 	if 	id_hw== 260710 	& 	hw03_name_3=="SHUMBAGE"	& 	id_period_mm==12

* Correcting names	
*-----------------------------------
replace hw01_name_1="ASHA" 		if id_hw==130110 	& 	id_period_mm==12replace hw03_name_3="AHMED" 	if id_hw==130110 	& 	id_period_mm==12
replace hw04_name_sur="OTHMAN" 	if 	id_hw==130107 	& 	id_period_mm==12		replace	hw04_name_sur="SHEHE"	if	id_hw==130823	&	id_period_mm==11		replace	hw04_name_sur="SHEHE"	if	id_hw==130823	&	id_period_mm==10		replace	hw04_name_sur="OMAR"	if	id_hw==131023	&	id_period_mm==12
replace hw03_name_3="MOHAMED" 	if 	id_hw==130124 	& 	id_period_mm==12
replace hw03_name_3="MOHAMED" 	if 	id_hw==131603 	& 	id_period_mm==11		replace	hw04_name_sur="NASIB"	if	id_hw==260525	&	inlist(id_period_mm,10,11)		replace	hw04_name_sur="MJUME"	if	id_hw==261204	&	id_period_mm==11		replace	hw04_name_sur="KHATIBU"	if	id_hw==260307	&	id_period_mm==10		replace	hw04_name_sur="KHAMIS"	if	id_hw==130124	&	id_period_mm==12	
replace	hw04_name_sur="KHAMIS"	if	id_hw==131624	&	inlist(id_period_mm,10,11)replace	hw04_name_sur="KAI"		if	id_hw==131206	&	id_period_mm==10
replace	hw02_name_2="KHERI"		if	id_hw==130123	&	id_period_mm==12	
replace	hw04_name_sur="KHERI"	if	id_hw==130123	&	id_period_mm==12	replace	hw03_name_3="SHUMBAGE"	if	id_hw==260723	&	id_period_mm==11		replace	hw03_name_3="SHUMBAGE"	if	id_hw==260723	&	id_period_mm==10			
replace	hw03_name_3="SHABANI"	if	inlist(id_hw,260604,260625)replace	hw03_name_3="MZEE"		if	id_hw==261108	&	inlist(id_period_mm,10,11)		replace	hw03_name_3="JUMA"		if	id_hw==260525	&	inlist(id_period_mm,10,11)		replace	hw03_name_3="AME"		if	id_hw==260530	&	id_period_mm==10		replace	hw03_name_3="ABDALLA"	if	id_hw==261204	&	id_period_mm==12		replace	hw02_name_2="SADIF"		if	id_hw==261120	&	id_period_mm==12		replace	hw02_name_2="MOHAMED"	if	id_hw==260307	&	id_period_mm==10replace	hw02_name_2="IBRAHIM"	if	id_hw==261108	&	inlist(id_period_mm,10,11)		replace	hw01_name_1="ZUHURA"	if	inlist(id_hw,260625,260604)	replace	hw01_name_1="RAHDHIA"	if	id_hw==261103	&	id_period_mm==11		replace	hw01_name_1="MWANAJUMA"	if	id_hw==260525	&	id_period_mm==12		replace	hw01_name_1="KADURA"	if	id_hw==130823	&	id_period_mm==12		replace	hw01_name_1="JOHANNA"	if	id_hw==260402	&	id_period_mm==12		*replace	hw02_name_2="ABDALLA"	if	id_hw==131306	&	id_period_mm==11		

* Correcting Cadre Code
replace hw05_cadre_code=45 if id_hw==130105 & id_period_mm==10 & hw01_name_1=="MOHAMED"replace hw05_cadre_code=45 if id_hw==130105 & id_period_mm==11 & hw01_name_1=="MOHAMED"replace hw05_cadre_code=45 if id_hw==130105 & id_period_mm==12 & hw01_name_1=="MOHAMED"replace hw05_cadre_code=45 if id_hw==130106 & id_period_mm==10 & hw01_name_1=="MASOUD"replace hw05_cadre_code=45 if id_hw==130106 & id_period_mm==12 & hw01_name_1=="MASOUD"replace hw05_cadre_code=45 if id_hw==130107 & id_period_mm==10 & hw01_name_1=="WAHABIA"replace hw05_cadre_code=45 if id_hw==130107 & id_period_mm==11 & hw01_name_1=="WAHABIA"replace hw05_cadre_code=45 if id_hw==130107 & id_period_mm==12 & hw01_name_1=="WAHABIA"replace hw05_cadre_code=61 if id_hw==130110 & id_period_mm==10 & hw01_name_1=="ASHA"replace hw05_cadre_code=61 if id_hw==130110 & id_period_mm==11 & hw01_name_1=="ASHA"replace hw05_cadre_code=61 if id_hw==130110 & id_period_mm==12 & hw01_name_1=="ASHA"replace hw05_cadre_code=44 if id_hw==130123 & id_period_mm==10 & hw01_name_1=="BIMKUBWA"replace hw05_cadre_code=44 if id_hw==130123 & id_period_mm==11 & hw01_name_1=="BIMKUBWA"replace hw05_cadre_code=44 if id_hw==130123 & id_period_mm==12 & hw01_name_1=="BIMKUBWA"replace hw05_cadre_code=45 if id_hw==130124 & id_period_mm==10 & hw01_name_1=="ALI"replace hw05_cadre_code=45 if id_hw==130124 & id_period_mm==11 & hw01_name_1=="ALI"replace hw05_cadre_code=45 if id_hw==130124 & id_period_mm==12 & hw01_name_1=="ALI"replace hw05_cadre_code=43 if id_hw==130401 & id_period_mm==10 & hw01_name_1=="AMOUR"replace hw05_cadre_code=43 if id_hw==130401 & id_period_mm==11 & hw01_name_1=="AMOUR"replace hw05_cadre_code=43 if id_hw==130401 & id_period_mm==12 & hw01_name_1=="AMOUR"replace hw05_cadre_code=50 if id_hw==130504 & id_period_mm==10 & hw01_name_1=="ZAINAB"replace hw05_cadre_code=50 if id_hw==130504 & id_period_mm==11 & hw01_name_1=="ZAINAB"replace hw05_cadre_code=50 if id_hw==130504 & id_period_mm==12 & hw01_name_1=="ZAINAB"replace hw05_cadre_code=43 if id_hw==130601 & id_period_mm==10 & hw01_name_1=="ALI"replace hw05_cadre_code=43 if id_hw==130601 & id_period_mm==11 & hw01_name_1=="ALI"replace hw05_cadre_code=43 if id_hw==130601 & id_period_mm==12 & hw01_name_1=="ALI"replace hw05_cadre_code=50 if id_hw==130823 & id_period_mm==10 & hw01_name_1=="KADURA"replace hw05_cadre_code=50 if id_hw==130823 & id_period_mm==11 & hw01_name_1=="KADURA"replace hw05_cadre_code=50 if id_hw==130823 & id_period_mm==12 & hw01_name_1=="KADURA"replace hw05_cadre_code=44 if id_hw==131023 & id_period_mm==10 & hw01_name_1=="HASSAN"replace hw05_cadre_code=44 if id_hw==131023 & id_period_mm==11 & hw01_name_1=="HASSAN"replace hw05_cadre_code=44 if id_hw==131023 & id_period_mm==12 & hw01_name_1=="HASSAN"replace hw05_cadre_code=50 if id_hw==131206 & id_period_mm==10 & hw01_name_1=="SAFIA"replace hw05_cadre_code=50 if id_hw==131206 & id_period_mm==12 & hw01_name_1=="SAFIA"replace hw05_cadre_code=50 if id_hw==131603 & id_period_mm==10 & hw01_name_1=="MAFUNDA"replace hw05_cadre_code=50 if id_hw==131603 & id_period_mm==11 & hw01_name_1=="MAFUNDA"replace hw05_cadre_code=50 if id_hw==131603 & id_period_mm==12 & hw01_name_1=="MAFUNDA"replace hw05_cadre_code=50 if id_hw==260102 & id_period_mm==10 & hw01_name_1=="FATMA"replace hw05_cadre_code=50 if id_hw==260102 & id_period_mm==12 & hw01_name_1=="FATMA"replace hw05_cadre_code=50 if id_hw==260203 & id_period_mm==10 & hw01_name_1=="MWASHAMBA"replace hw05_cadre_code=50 if id_hw==260203 & id_period_mm==11 & hw01_name_1=="MWASHAMBA"replace hw05_cadre_code=50 if id_hw==260203 & id_period_mm==12 & hw01_name_1=="MWASHAMBA"replace hw05_cadre_code=43 if id_hw==260301 & id_period_mm==10 & hw01_name_1=="ABDALLA"replace hw05_cadre_code=43 if id_hw==260301 & id_period_mm==11 & hw01_name_1=="ABDALLA"replace hw05_cadre_code=43 if id_hw==260301 & id_period_mm==12 & hw01_name_1=="ABDALLA"replace hw05_cadre_code=50 if id_hw==260304 & id_period_mm==10 & hw01_name_1=="SIAJABU"replace hw05_cadre_code=50 if id_hw==260304 & id_period_mm==11 & hw01_name_1=="SIAJABU"replace hw05_cadre_code=50 if id_hw==260304 & id_period_mm==12 & hw01_name_1=="SIAJABU"replace hw05_cadre_code=50 if id_hw==260503 & id_period_mm==10 & hw01_name_1=="MOSI"replace hw05_cadre_code=50 if id_hw==260503 & id_period_mm==11 & hw01_name_1=="MOSI"replace hw05_cadre_code=50 if id_hw==260503 & id_period_mm==12 & hw01_name_1=="MOSI"replace hw05_cadre_code=32 if id_hw==260508 & id_period_mm==10 & hw01_name_1=="KHADIJA"replace hw05_cadre_code=32 if id_hw==260508 & id_period_mm==11 & hw01_name_1=="KHADIJA"replace hw05_cadre_code=32 if id_hw==260508 & id_period_mm==12 & hw01_name_1=="KHADIJA"replace hw05_cadre_code=32 if id_hw==260509 & id_period_mm==10 & hw01_name_1=="ZAINA"replace hw05_cadre_code=32 if id_hw==260509 & id_period_mm==12 & hw01_name_1=="ZAINA"replace hw05_cadre_code=50 if id_hw==260516 & id_period_mm==10 & hw01_name_1=="SALMA"replace hw05_cadre_code=50 if id_hw==260516 & id_period_mm==11 & hw01_name_1=="SALMA"replace hw05_cadre_code=50 if id_hw==260516 & id_period_mm==12 & hw01_name_1=="SALMA"replace hw05_cadre_code=70 if id_hw==260518 & id_period_mm==10 & hw01_name_1=="MARYAM"replace hw05_cadre_code=70 if id_hw==260518 & id_period_mm==11 & hw01_name_1=="MARYAM"replace hw05_cadre_code=70 if id_hw==260518 & id_period_mm==12 & hw01_name_1=="MARYAM"replace hw05_cadre_code=70 if id_hw==260522 & id_period_mm==10 & hw01_name_1=="BURHAN"replace hw05_cadre_code=70 if id_hw==260522 & id_period_mm==11 & hw01_name_1=="BURHAN"replace hw05_cadre_code=70 if id_hw==260522 & id_period_mm==12 & hw01_name_1=="BURHAN"replace hw05_cadre_code=70 if id_hw==260531 & id_period_mm==10 & hw01_name_1=="RAMLA"replace hw05_cadre_code=70 if id_hw==260531 & id_period_mm==12 & hw01_name_1=="RAMLA"replace hw05_cadre_code=50 if id_hw==261004 & id_period_mm==10 & hw01_name_1=="MARYAM"replace hw05_cadre_code=50 if id_hw==261004 & id_period_mm==11 & hw01_name_1=="MARYAM"replace hw05_cadre_code=50 if id_hw==261004 & id_period_mm==12 & hw01_name_1=="MARYAM"replace hw05_cadre_code=45 if id_hw==261104 & id_period_mm==10 & hw01_name_1=="MWANAJUMA"replace hw05_cadre_code=45 if id_hw==261104 & id_period_mm==12 & hw01_name_1=="MWANAJUMA"replace hw05_cadre_code=41 if id_hw==261201 & id_period_mm==10 & hw01_name_1=="SALMA"replace hw05_cadre_code=41 if id_hw==261201 & id_period_mm==11 & hw01_name_1=="SALMA"replace hw05_cadre_code=41 if id_hw==261201 & id_period_mm==12 & hw01_name_1=="SALMA"replace hw05_cadre_code=70 if id_hw==261203 & id_period_mm==10 & hw01_name_1=="AISHA"replace hw05_cadre_code=70 if id_hw==261203 & id_period_mm==11 & hw01_name_1=="AISHA"replace hw05_cadre_code=64 if id_hw==261203 & id_period_mm==12 & hw01_name_1=="AISHA"replace hw05_cadre_code=64 if id_hw==261204 & id_period_mm==11 & hw01_name_1=="KHAMIS"replace hw05_cadre_code=64 if id_hw==261204 & id_period_mm==12 & hw01_name_1=="KHAMIS"replace hw05_cadre_code=70 if id_hw==260423 & id_period_mm==10 & hw01_name_1=="MARYAM"replace hw05_cadre_code=70 if id_hw==260423 & id_period_mm==11 & hw01_name_1=="MARYAM"replace hw05_cadre_code=70 if id_hw==260423 & id_period_mm==12 & hw01_name_1=="MARYAM"

* Fixing up string
fn *, type(string)
foreach var in `r(varlist)' {
	replace `var' = trim(`var')
}

*************************************************************************
* Correcting Values After Review by PHCUs
*************************************************************************



set linesize 225

*ta id_period_mm
*ta id_phcu, mi
*stop


* Drop obs
#delimit ;
drop if inlist(id_hw,	130223,130408,130410,130604,130705,130904,
						131504,131623,131626,131627,260305,260306,
						260511,260603,261129,261115,260606,260528,
						261312,261313,261314,261315,261406,260511,
						260528,260529,130203,131105
						);
#delimit cr
* Chambani
replace hw07_daysworked=23 	if id_hw==130201 & id_period_mm==10
replace hw07_daysworked=23	if id_hw==130202 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==130202 & id_period_mm==12

* Kengeja
replace hw05_cadre_code=41 	if id_hw==130401
replace hw07_daysworked=23	if id_hw==130401 & id_period_mm==10
replace hw07_daysworked=0	if id_hw==130406 & id_period_mm==10
replace hw07_daysworked=23	if id_hw==130409 & id_period_mm==12

* Mtangani
replace hw07_daysworked=14	if id_hw==130902 & id_period_mm==11
replace hw07_daysworked=15	if id_hw==130905 & id_period_mm==11

* Muambe
replace hw07_daysworked=10	if id_hw==131102 & id_period_mm==11

* Wambaa
replace hw07_daysworked=0	if id_hw==131624 & id_period_mm==11

* Beit-El-Raas
replace hw02_name_2="SADIK"		if id_hw==260123
replace hw04_name_sur="MABURA"	if id_hw==260123

* Chuini
replace hw07_daysworked=22	if id_hw==260307 & id_period_mm==12

* Chukwani
replace hw07_daysworked=23	if id_hw==260405 & id_period_mm==10
replace hw07_daysworked=23	if id_hw==260405 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==260409 & id_period_mm==11

* Fuoni
replace hw07_daysworked=23	if id_hw==260501 & id_period_mm==10
replace hw07_daysworked=23	if id_hw==260507 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==260509 & id_period_mm==11
replace hw07_daysworked=13	if id_hw==260516 & id_period_mm==11
replace hw07_daysworked=14	if id_hw==260519 & id_period_mm==11
replace hw07_daysworked=0	if id_hw==260519 & id_period_mm==12
replace hw07_daysworked=13	if id_hw==260525 & id_period_mm==11
replace hw07_daysworked=14	if id_hw==260527 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==260531 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==260532 & id_period_mm==12

* Kiembe Samaki
replace hw04_name_sur="MGANGA"	if id_hw==260701
replace hw04_name_sur="RHAMIS"	if id_hw==260706
replace hw03_name_3="SHUMBAGI"	if id_hw==260711
replace hw07_daysworked=23	if id_hw==260706 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==260708 & id_period_mm==10
replace hw07_daysworked=0	if id_hw==260708 & id_period_mm==11

* Kizimbani
replace hw04_name_sur="ALI"	if id_hw==260904

* Kombeni
replace hw04_name_sur="ABDALLA"	if id_hw==261023
replace hw04_name_sur="KASSIM"	if id_hw==261024

* Magogoni
replace hw03_name_3="SULEIMAN"	if id_hw==261102
replace hw01_name_1="RADHIA"	if id_hw==261103
replace hw05_cadre_code=21 		if id_hw==261103

replace hw07_daysworked=23	if id_hw==261104 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==261105 & id_period_mm==12
replace hw07_daysworked=22	if id_hw==261111 & id_period_mm==11
replace hw07_daysworked=23	if id_hw==261111 & id_period_mm==12
replace hw07_daysworked=23	if id_hw==261119 & id_period_mm==12

* Fuoni Kibondeni  
replace hw04_name_sur="KASSIM"	if id_hw==260604 

* Check
sort id_hw id_period_mm
list id_hw id_phcu_name id_period_mm hw01_name_1	hw02_name_2	hw03_name_3	hw04_name_sur ///
	hw05_cadre_code	hw07_daysworked if id_phcu==2611, separator(3) 
	
