clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/09_event_study.log", replace text

****************Figure 2, baseline sample, 2022 omitted
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

*Specification one, treatment indicator as a control
reghdfe ratio_num DID_1 DID_2 DID_3 DID_4 DID_5 DID_7 DID_8 DID_9 treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
test DID_1 DID_2 DID_3 DID_4 DID_5

tempname p1
postfile `p1' int yr double b1 double se1 using "$data/es_s1.dta", replace
post `p1' (2017) (_b[DID_1]) (_se[DID_1])
post `p1' (2018) (_b[DID_2]) (_se[DID_2])
post `p1' (2019) (_b[DID_3]) (_se[DID_3])
post `p1' (2020) (_b[DID_4]) (_se[DID_4])
post `p1' (2021) (_b[DID_5]) (_se[DID_5])
post `p1' (2022) (0)         (0)
post `p1' (2023) (_b[DID_7]) (_se[DID_7])
post `p1' (2024) (_b[DID_8]) (_se[DID_8])
post `p1' (2025) (_b[DID_9]) (_se[DID_9])
postclose `p1'

*Specification two, major fixed effects instead
reghdfe ratio_num DID_1 DID_2 DID_3 DID_4 DID_5 DID_7 DID_8 DID_9, absorb($FE) vce(robust)
test DID_1 DID_2 DID_3 DID_4 DID_5
test DID_4 DID_5

tempname p2
postfile `p2' int yr double b2 double se2 using "$data/es_s2.dta", replace
post `p2' (2017) (_b[DID_1]) (_se[DID_1])
post `p2' (2018) (_b[DID_2]) (_se[DID_2])
post `p2' (2019) (_b[DID_3]) (_se[DID_3])
post `p2' (2020) (_b[DID_4]) (_se[DID_4])
post `p2' (2021) (_b[DID_5]) (_se[DID_5])
post `p2' (2022) (0)         (0)
post `p2' (2023) (_b[DID_7]) (_se[DID_7])
post `p2' (2024) (_b[DID_8]) (_se[DID_8])
post `p2' (2025) (_b[DID_9]) (_se[DID_9])
postclose `p2'

use "$data/es_s1.dta", clear
merge 1:1 yr using "$data/es_s2.dta", nogen

gen lo1 = b1 - 1.96*se1
gen hi1 = b1 + 1.96*se1
gen lo2 = b2 - 1.96*se2
gen hi2 = b2 + 1.96*se2

*Offset the two series slightly so the markers do not sit on top of each other
gen yr1 = yr - 0.06
gen yr2 = yr + 0.06

list yr b1 b2

twoway (rarea lo1 hi1 yr1, color("$BLUE%12") lwidth(none)) ///
       (rarea lo2 hi2 yr2, color("$ORANGE%12") lwidth(none)) ///
       (connected b1 yr1, lcolor("$BLUE") lwidth(medthick) msymbol(O) msize(medium) mcolor("$BLUE")) ///
       (connected b2 yr2, lcolor("$ORANGE") lwidth(medthick) msymbol(O) msize(medium) mcolor("$ORANGE")), ///
	yline(0, lpattern(dot) lcolor(gs6)) ///
	xline(2022.5, lpattern(dash) lcolor(gs8)) ///
	xlabel(2017(1)2025, labsize(small)) ///
	ylabel(, labsize(small) angle(0) grid glcolor(gs14) glwidth(vthin)) ///
	ytitle("Change in within-province rank ratio", size(small)) ///
	xtitle("") ///
	legend(order(3 "Treatment-group control" 4 "Major fixed effects") ///
	       position(6) rows(1) region(lstyle(none)) size(small)) ///
	graphregion(color(white)) plotregion(color(white) margin(medium)) ///
	ysize(4) xsize(6.5)

graph export "$figs/fig_es_ribbon.pdf", replace
graph export "$figs/fig_es_ribbon.png", replace width(2400)

****************Figure 4, all provinces reinstated
use "$data/analysis.dta", clear

gen DID_1 = treat1 * event_time_1
gen DID_2 = treat1 * event_time_2
gen DID_3 = treat1 * event_time_3
gen DID_4 = treat1 * event_time_4
gen DID_5 = treat1 * event_time_5
gen DID_7 = treat1 * event_time_7
gen DID_8 = treat1 * event_time_8
gen DID_9 = treat1 * event_time_9

reghdfe ratio_num DID_1 DID_2 DID_3 DID_4 DID_5 DID_7 DID_8 DID_9 treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
test DID_1 DID_2 DID_3 DID_4 DID_5

tempname a1
postfile `a1' int yr double b1 double se1 using "$data/es_all_s1.dta", replace
post `a1' (2017) (_b[DID_1]) (_se[DID_1])
post `a1' (2018) (_b[DID_2]) (_se[DID_2])
post `a1' (2019) (_b[DID_3]) (_se[DID_3])
post `a1' (2020) (_b[DID_4]) (_se[DID_4])
post `a1' (2021) (_b[DID_5]) (_se[DID_5])
post `a1' (2022) (0)         (0)
post `a1' (2023) (_b[DID_7]) (_se[DID_7])
post `a1' (2024) (_b[DID_8]) (_se[DID_8])
post `a1' (2025) (_b[DID_9]) (_se[DID_9])
postclose `a1'

reghdfe ratio_num DID_1 DID_2 DID_3 DID_4 DID_5 DID_7 DID_8 DID_9, absorb($FE) vce(robust)
test DID_1 DID_2 DID_3 DID_4 DID_5

tempname a2
postfile `a2' int yr double b2 double se2 using "$data/es_all_s2.dta", replace
post `a2' (2017) (_b[DID_1]) (_se[DID_1])
post `a2' (2018) (_b[DID_2]) (_se[DID_2])
post `a2' (2019) (_b[DID_3]) (_se[DID_3])
post `a2' (2020) (_b[DID_4]) (_se[DID_4])
post `a2' (2021) (_b[DID_5]) (_se[DID_5])
post `a2' (2022) (0)         (0)
post `a2' (2023) (_b[DID_7]) (_se[DID_7])
post `a2' (2024) (_b[DID_8]) (_se[DID_8])
post `a2' (2025) (_b[DID_9]) (_se[DID_9])
postclose `a2'

use "$data/es_all_s1.dta", clear
merge 1:1 yr using "$data/es_all_s2.dta", nogen

gen lo1 = b1 - 1.96*se1
gen hi1 = b1 + 1.96*se1
gen lo2 = b2 - 1.96*se2
gen hi2 = b2 + 1.96*se2
gen yr1 = yr - 0.06
gen yr2 = yr + 0.06

list yr b1 b2

twoway (rarea lo1 hi1 yr1, color("$BLUE%12") lwidth(none)) ///
       (rarea lo2 hi2 yr2, color("$ORANGE%12") lwidth(none)) ///
       (connected b1 yr1, lcolor("$BLUE") lwidth(medthick) msymbol(O) msize(medium) mcolor("$BLUE")) ///
       (connected b2 yr2, lcolor("$ORANGE") lwidth(medthick) msymbol(O) msize(medium) mcolor("$ORANGE")), ///
	yline(0, lpattern(dot) lcolor(gs6)) ///
	xline(2022.5, lpattern(dash) lcolor(gs8)) ///
	xlabel(2017(1)2025, labsize(small)) ///
	ylabel(, labsize(small) angle(0) grid glcolor(gs14) glwidth(vthin)) ///
	ytitle("Change in within-province rank ratio", size(small)) ///
	xtitle("") ///
	legend(order(3 "Treatment-group control" 4 "Major fixed effects") ///
	       position(6) rows(1) region(lstyle(none)) size(small)) ///
	graphregion(color(white)) plotregion(color(white) margin(medium)) ///
	ysize(4) xsize(6.5)

graph export "$figs/fig_es_allprov.pdf", replace
graph export "$figs/fig_es_allprov.png", replace width(2400)

log close
