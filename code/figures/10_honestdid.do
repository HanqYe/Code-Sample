clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/10_honestdid.log", replace text

****************Figure 3, Rambachan and Roth relative-magnitudes sensitivity
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

gen DID_1 = treat1 * event_time_1
gen DID_2 = treat1 * event_time_2
gen DID_3 = treat1 * event_time_3
gen DID_4 = treat1 * event_time_4
gen DID_5 = treat1 * event_time_5
gen DID_7 = treat1 * event_time_7
gen DID_8 = treat1 * event_time_8
gen DID_9 = treat1 * event_time_9

reghdfe ratio_num DID_1 DID_2 DID_3 DID_4 DID_5 DID_7 DID_8 DID_9, absorb($FE) vce(robust)

mat list e(b)

honestdid, pre(1/5) post(6/8) mvec(0(0.25)2) alpha(0.05)

honestdid, pre(1/5) post(6/8) mvec(0(0.25)2) alpha(0.05) coefplot ///
	xtitle("M") ytitle("95% robust CI") ///
	graphregion(color(white)) plotregion(color(white))

graph export "$figs/fig_honestdid.pdf", replace
graph export "$figs/fig_honestdid.png", replace width(2400)

log close
