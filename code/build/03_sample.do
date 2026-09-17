clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/03_sample.log", replace text

****************Language model scores, collapsed to one row per major
use "$raw/rank1.dta", clear
bysort level3_name: keep if _n == 1
isid level3_name
count
save "$data/scores_major.dta", replace

use "$data/panel.dta", clear
merge m:1 level3_name using "$data/scores_major.dta"
tab level3_name if _merge == 1
keep if _merge == 3
drop _merge

****************Provincial GDP
gen gdp_merge = string(year) + local_province_name
merge m:1 gdp_merge using "$raw/gdp.dta"
drop if _merge == 2
rename GDP地区生产总值亿元 GDP
drop _merge

****************Admission competition and influencer audience density
rename local_province_name province
merge m:1 province using "$raw/involution_rate.dta"
drop if _merge == 2
drop _merge
merge m:1 province using "$raw/density.dta"
drop if _merge == 2
drop _merge

gen involution = real(substr(involution_rate, 1, length(involution_rate) - 1)) / 100
tab involution_rate if missing(involution)

****************Treatment
gen treat1 = average_rank <= 3
gen treat2 = average_rank > 3 & average_rank <= 7
gen treat3 = average_rank > 7
gen post   = year >= 2023
gen DID    = treat1 * post

tab treat1 post

****************Drop cells containing an outlier by the interquartile rule
bysort province_num category hightitle level3_name: egen q1 = pctile(ratio_num), p(25)
bysort province_num category hightitle level3_name: egen q3 = pctile(ratio_num), p(75)
gen iqr = q3 - q1
gen outlier = ratio_num < q1 - 1.5 * iqr | ratio_num > q3 + 1.5 * iqr
bysort province_num category hightitle level3_name: egen has_outlier = max(outlier)
drop if has_outlier == 1
drop q1 q3 iqr outlier has_outlier

****************Drop thinly observed major categories
egen freq = count(level3_name), by(level3_name)
drop if freq <= 2000
drop freq

****************Competition and density groups
gen high_invo = involution <= 0.20
gen mid_invo  = involution >  0.20 & involution <= 0.35
gen low_invo  = involution >  0.35
gen high_den  = density >= 5

*Baseline drops 2025 for the eight fifth-wave reform provinces
gen keepA = !(reform2025 == 1 & year == 2025)
tab year keepA

compress
save "$data/analysis.dta", replace

count
count if special_prov == 0
tab year special_prov
tabstat ratio_num min_num average_rank involution density, statistics(N min mean sd p25 p50 p75 max) columns(statistics) format(%9.3f)

log close
