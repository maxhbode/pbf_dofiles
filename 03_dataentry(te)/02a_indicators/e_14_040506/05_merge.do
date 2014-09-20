
* Merge
u "$TEMP/ded04_bl_13_040506(manipulate)", clear
merge 1:1 id_phcu_ym using "$TEMP/ded04_14_040506(manipulate)", nogen

* Clean
drop id_period_q  id1 id2 id3  dataentryround  id_period_y dm* v*
order *, alpha
order id* 
order b0_section_skip, before(b00_g)
order c0_section_skip, after(b07_sectionb_comment)

* Label values not collected in baseline 
fn *_v_* *_nv_* ///
	b03_g	b03_t	b04_g	b04_t	b05_g	b05_t	b06_t ///
	c02_t	c03_g	c03_t c06_g c07_t	c08_g c09_t	c10_t	c11_t	c12_t	c13_t 

foreach var in `r(varlist)' {
	replace `var'=.z if `var'==. & `var' & id_period_yyyy==2013
}

* Save
compress
sa "$TEMP/05_merge(e_14_040506)", replace
sa "$TEMP/dee05(merge)", replace






						

		
