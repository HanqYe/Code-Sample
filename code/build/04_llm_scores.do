clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/04_llm_scores.log", replace text

****************DeepSeek scores, collapsed to one row per major
use "$raw/rank.dta", clear
bysort level3_name: keep if _n == 1
keep level3_name average_rank
rename average_rank dpsk
save "$data/score_dpsk.dta", replace

****************GPT-4o scores, with the number of evaluations each major received
use "$raw/rank1.dta", clear
bysort level3_name: gen nev = _N
bysort level3_name: keep if _n == 1
keep level3_name average_rank nev
rename average_rank gpt

merge 1:1 level3_name using "$data/score_dpsk.dta"
drop _merge
save "$data/scores_both.dta", replace

corr gpt dpsk
count if !missing(gpt) & !missing(dpsk)

****************The 40 categories that survive into the estimation sample
use "$data/analysis.dta", clear
bysort level3_name: keep if _n == 1
keep level3_name
merge 1:1 level3_name using "$data/scores_both.dta"
keep if _merge == 3
drop _merge

count
corr gpt dpsk
gsort gpt
list level3_name gpt dpsk nev, sep(0) noobs

log close
