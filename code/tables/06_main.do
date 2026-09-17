clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/06_main.log", replace text

****************Table 4, baseline, excluding the six early-reform provinces
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

eststo clear
eststo t4c1: reghdfe ratio_num DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo t4c2: reghdfe ratio_num DID,        absorb($FE) vce(robust)
eststo t4c3: reghdfe min_num   DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo t4c4: reghdfe min_num   DID,        absorb($FE) vce(robust)

esttab t4c1 t4c2 t4c3 t4c4 using "$tables/table4_main.tex", replace ///
	b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
	keep(DID treat1) ///
	mtitles("Rank ratio" "Rank ratio" "Min. score" "Min. score") ///
	coeflabels(DID "Treat $\times$ Post" treat1 "Treat") ///
	stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
	booktabs nonotes label

esttab t4c1 t4c2 t4c3 t4c4, b(4) se(4) keep(DID treat1) stats(N r2)

****************Table 5, the six provinces reinstated
use "$data/analysis.dta", clear

eststo clear
eststo t5c1: reghdfe ratio_num DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo t5c2: reghdfe ratio_num DID,        absorb($FE) vce(robust)
eststo t5c3: reghdfe min_num   DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo t5c4: reghdfe min_num   DID,        absorb($FE) vce(robust)

esttab t5c1 t5c2 t5c3 t5c4 using "$tables/table5_allprov.tex", replace ///
	b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
	keep(DID treat1) ///
	mtitles("Rank ratio" "Rank ratio" "Min. score" "Min. score") ///
	coeflabels(DID "Treat $\times$ Post" treat1 "Treat") ///
	stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
	booktabs nonotes label

esttab t5c1 t5c2 t5c3 t5c4, b(4) se(4) keep(DID treat1) stats(N r2)

log close
