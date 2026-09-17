clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/11_dose.log", replace text

****************Figure 9, one coefficient per score bin
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

gen score_bin = ceil(average_rank)
tab score_bin

*Major fixed effects would absorb the score variation the figure is meant to show
reghdfe ratio_num ib7.score_bin##i.post, absorb(province_num#year#category_num hightitle_num#year) vce(robust)

tempname pf
postfile `pf' int bin double b double se using "$data/dose.dta", replace
post `pf' (3) (_b[3.score_bin#1.post]) (_se[3.score_bin#1.post])
post `pf' (4) (_b[4.score_bin#1.post]) (_se[4.score_bin#1.post])
post `pf' (5) (_b[5.score_bin#1.post]) (_se[5.score_bin#1.post])
post `pf' (6) (_b[6.score_bin#1.post]) (_se[6.score_bin#1.post])
post `pf' (7) (0)                      (0)
post `pf' (8) (_b[8.score_bin#1.post]) (_se[8.score_bin#1.post])
post `pf' (9) (_b[9.score_bin#1.post]) (_se[9.score_bin#1.post])
postclose `pf'

use "$data/dose.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
list

twoway (rbar lo hi bin, barwidth(0.06) color("$ORANGE%30")) ///
       (scatter b bin, msymbol(O) msize(medlarge) mcolor("$ORANGE")), ///
	yline(0, lpattern(dot) lcolor(gs6)) ///
	xlabel(3 "2-3" 4 "3-4" 5 "4-5" 6 "5-6" 7 "6-7" 8 "7-8" 9 "8-9", labsize(small) noticks) ///
	xscale(range(2.6 9.4)) ///
	ylabel(, labsize(small) angle(0) grid glcolor(gs14) glwidth(vthin)) ///
	ytitle("Post-2023 change in rank ratio", size(small)) ///
	xtitle("Language model score of major", size(small)) ///
	legend(off) ///
	graphregion(color(white)) plotregion(color(white) margin(medium)) ///
	ysize(4) xsize(6.5)

graph export "$figs/fig_dose_fine.pdf", replace
graph export "$figs/fig_dose_fine.png", replace width(2400)

****************Figure 8, the score gradient within the negative range
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1
keep if average_rank <= 4

sum average_rank, detail

gen S_1 = average_rank * event_time_1
gen S_2 = average_rank * event_time_2
gen S_3 = average_rank * event_time_3
gen S_4 = average_rank * event_time_4
gen S_5 = average_rank * event_time_5
gen S_7 = average_rank * event_time_7
gen S_8 = average_rank * event_time_8
gen S_9 = average_rank * event_time_9

reghdfe ratio_num S_1 S_2 S_3 S_4 S_5 S_7 S_8 S_9, absorb($FE) vce(robust)

test S_1 S_2 S_3 S_4 S_5
test S_4 S_5

tempname pd
postfile `pd' int yr double b double se using "$data/es_dose4.dta", replace
post `pd' (2017) (_b[S_1]) (_se[S_1])
post `pd' (2018) (_b[S_2]) (_se[S_2])
post `pd' (2019) (_b[S_3]) (_se[S_3])
post `pd' (2020) (_b[S_4]) (_se[S_4])
post `pd' (2021) (_b[S_5]) (_se[S_5])
post `pd' (2022) (0)       (0)
post `pd' (2023) (_b[S_7]) (_se[S_7])
post `pd' (2024) (_b[S_8]) (_se[S_8])
post `pd' (2025) (_b[S_9]) (_se[S_9])
postclose `pd'

use "$data/es_dose4.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
list

twoway (rarea lo hi yr, color("$ORANGE%15") lwidth(none)) ///
       (connected b yr, lcolor("$ORANGE") lwidth(medthick) ///
                        msymbol(O) msize(medium) mcolor("$ORANGE")), ///
	yline(0, lpattern(dot) lcolor(gs6)) ///
	xline(2022.5, lpattern(dash) lcolor(gs8)) ///
	xlabel(2017(1)2025, labsize(small)) ///
	ylabel(, labsize(small) angle(0) grid glcolor(gs14) glwidth(vthin)) ///
	ytitle("Change in rank ratio per point of score", size(small)) ///
	xtitle("") ///
	legend(off) ///
	graphregion(color(white)) plotregion(color(white) margin(medium)) ///
	ysize(4) xsize(6.5)

graph export "$figs/fig_es_dose4.pdf", replace
graph export "$figs/fig_es_dose4.png", replace width(2400)

log close
