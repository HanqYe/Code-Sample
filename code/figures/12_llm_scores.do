clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

global GREEN "106 168 79"

log using "$logs/12_llm_scores.log", replace text

****************Figure 5, GPT-4o against DeepSeek with marginal histograms
use "$data/scores_both.dta", clear
keep if !missing(gpt) & !missing(dpsk)
count
corr gpt dpsk

gen above = dpsk > gpt
sum above
sum gpt dpsk

twoway (function y = x, range(0 10) lcolor(gs10) lwidth(thin)) ///
       (scatter dpsk gpt, msymbol(O) msize(small) mcolor("$GREEN%70")), ///
	xlabel(0(2)10, labsize(small)) ylabel(0(2)10, labsize(small) angle(0)) ///
	xscale(range(0 10)) yscale(range(0 10)) ///
	xtitle("GPT-4o score", size(small)) ytitle("DeepSeek score", size(small)) ///
	legend(off) aspectratio(1) ///
	graphregion(color(white)) plotregion(color(white)) ///
	name(mainsc, replace)

twoway histogram gpt, width(0.5) start(0) fcolor("$GREEN%45") lcolor(white) lwidth(vthin) ///
	xscale(range(0 10) off) xlabel(0(2)10, nolabels noticks) ///
	ylabel(, nolabels noticks) ytitle("") ///
	fysize(22) ///
	graphregion(color(white)) plotregion(color(white)) ///
	name(topH, replace)

twoway histogram dpsk, width(0.5) start(0) horizontal fcolor("$GREEN%45") lcolor(white) lwidth(vthin) ///
	yscale(range(0 10) off) ylabel(0(2)10, nolabels noticks) ///
	xlabel(, nolabels noticks) xtitle("") ///
	fxsize(22) ///
	graphregion(color(white)) plotregion(color(white)) ///
	name(rightH, replace)

graph combine topH mainsc rightH, ///
	holes(2) cols(2) imargin(zero) ///
	graphregion(color(white)) ///
	xsize(5) ysize(5)

graph export "$figs/fig_model_scatter.pdf", replace
graph export "$figs/fig_model_scatter.png", replace width(2000)

log close
