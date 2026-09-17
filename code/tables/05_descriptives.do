clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/05_descriptives.log", replace text

****************Coverage at each stage of the build
use "$data/scores_raw.dta", clear
count
tab year

use "$data/panel.dta", clear
count
distinct hightitle
distinct level3_name
distinct local_province_name
distinct prouni_id
tab year

use "$data/analysis.dta", clear
count
count if special_prov == 0 & keepA == 1
distinct hightitle
distinct level3_name
distinct province

****************How balanced the panel is
bysort prouni_id: gen nyr = _N
tab nyr

****************Table 1, admission outcomes by institutional tier
use "$data/analysis.dta", clear
gen tier = 1 if f985 == 1
replace tier = 2 if f985 == 2 & f211 == 1
replace tier = 3 if f985 == 2 & f211 == 2
tab tier, missing

keep if special_prov == 0 & keepA == 1
bysort tier hightitle: gen firstu = _n == 1
tabstat ratio_num min_num, by(tier) statistics(mean) format(%9.3f)
tabstat ratio_num min_num, statistics(mean) format(%9.3f)
table tier, statistic(sum firstu)

****************Observations per year under each sample definition
use "$data/analysis.dta", clear
gen s1 = special_prov == 0 & keepA == 1
gen s2 = keepA == 1
gen s3 = 1

table year, statistic(sum s1) statistic(sum s2) statistic(sum s3)

****************Estimation sample descriptives
keep if special_prov == 0 & keepA == 1
tabstat ratio_num min_num average_rank involution density, statistics(N min mean sd p25 p50 p75 max) columns(statistics) format(%9.3f)

log close
