clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/08_mechanisms.log", replace text

****************Table 7, by university tier
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

tab f985, missing
tab f211, missing

reghdfe ratio_num DID if f985 == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if f985 == 2, absorb($FE) vce(robust)
reghdfe ratio_num DID if f211 == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if f211 == 2, absorb($FE) vce(robust)

*The reported difference comes from the pooled sample with treatment interacted with tier
gen byte d985 = (f985 == 1) if !missing(f985)
gen byte d211 = (f211 == 1) if !missing(f211)

gen DID_985   = DID    * d985
gen treat_985 = treat1 * d985
gen DID_211   = DID    * d211
gen treat_211 = treat1 * d211

reghdfe ratio_num DID DID_985 treat_985, absorb($FE) vce(robust)
test DID_985 = 0

reghdfe ratio_num DID DID_211 treat_211, absorb($FE) vce(robust)
test DID_211 = 0

*Treated share by tier, to show the contrast is not compositional
tabstat treat1, by(f985) statistics(mean N)
tabstat treat1, by(f211) statistics(mean N)

****************Table 8 panel A, by admission competition
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

reghdfe ratio_num DID if high_invo == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if mid_invo  == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if low_invo  == 1, absorb($FE) vce(robust)

gen DID_high   = DID    * high_invo
gen treat_high = treat1 * high_invo

reghdfe ratio_num DID DID_high treat_high if high_invo == 1 | low_invo == 1, absorb($FE) vce(robust)
test DID_high = 0

****************Table 8 panel B, by influencer audience density
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

reghdfe ratio_num DID if high_den == 0, absorb($FE) vce(robust)
reghdfe ratio_num DID if high_den == 1, absorb($FE) vce(robust)

gen DID_den   = DID    * high_den
gen treat_den = treat1 * high_den

reghdfe ratio_num DID DID_den treat_den, absorb($FE) vce(robust)
test DID_den = 0

gen DDD      = density * treat1 * post
gen den_post = density * post
gen den_trt  = density * treat1

reghdfe ratio_num DDD DID den_post den_trt treat1, absorb($FE) vce(robust)

****************Same splits with the six provinces reinstated
use "$data/analysis.dta", clear
keep if keepA == 1

reghdfe ratio_num DID if high_invo == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if mid_invo  == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if low_invo  == 1, absorb($FE) vce(robust)
reghdfe ratio_num DID if high_den == 0, absorb($FE) vce(robust)
reghdfe ratio_num DID if high_den == 1, absorb($FE) vce(robust)

****************Intensity within the negative range, reported in the text
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1
keep if average_rank <= 4

tabstat average_rank, by(level3_name) statistics(N mean min max) format(%9.2f)

gen S_post = average_rank * post
gen t      = year - 2022
gen S_trend = average_rank * t

reghdfe ratio_num S_post, absorb($FE) vce(robust)
reghdfe ratio_num S_post S_trend, absorb($FE) vce(robust)

****************Province-level correlations behind the maps
use "$raw/involution_rate.dta", clear
gen rate = real(substr(involution_rate, 1, length(involution_rate) - 1)) / 100
gen bkrate = real(substr(本科率, 1, length(本科率) - 1)) / 100
gen exam = real(subinstr(高考人数, "万", "", .))
keep province rate bkrate exam
merge 1:1 province using "$raw/density.dta"
keep if _merge == 3
drop _merge

gen shanhe = inlist(province, "山东", "山西", "河南", "河北")

corr density rate
corr density exam

tabstat density rate, by(shanhe) statistics(N mean sd min max) format(%9.3f)

export delimited using "$data/prov_density.csv", replace

log close
