clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/07_robustness.log", replace text

****************Table 6, dropping STEM majors and the years before 2018
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1
keep if year >= 2018
keep if average_rank < 7

count

eststo clear
eststo r1: reghdfe ratio_num DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo r2: reghdfe ratio_num DID,        absorb($FE) vce(robust)
eststo r3: reghdfe min_num   DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
eststo r4: reghdfe min_num   DID,        absorb($FE) vce(robust)

esttab r1 r2 r3 r4 using "$tables/table6_nostem.tex", replace ///
	b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
	keep(DID treat1) ///
	mtitles("Rank ratio" "Rank ratio" "Min. score" "Min. score") ///
	coeflabels(DID "Treat $\times$ Post" treat1 "Treat") ///
	stats(N r2, labels("Observations" "R-squared") fmt(0 3)) ///
	booktabs nonotes label

esttab r1 r2 r3 r4, b(4) se(4) keep(DID treat1) stats(N r2)

****************Treatment defined on the DeepSeek scores instead
use "$data/analysis.dta", clear
keep if special_prov == 0
keep if keepA == 1

drop treat1 DID
merge m:1 level3_name using "$data/score_dpsk.dta"
keep if _merge == 3
drop _merge

gen treat1 = dpsk <= 3
gen DID = treat1 * post

tab level3_name if treat1 == 1
sum dpsk, detail

reghdfe ratio_num DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
reghdfe ratio_num DID,        absorb($FE) vce(robust)
reghdfe min_num   DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
reghdfe min_num   DID,        absorb($FE) vce(robust)

****************Enrolment quotas, to check that supply did not move
import delimited using "$raw/计划.csv", clear varnames(1) encoding("utf-8")
keep year level3_name local_province_name local_type_name name num local_batch_name spname
destring year num, replace force
tab year

*Same cleaning as the admission panel
drop if local_province_name == "西藏"
drop if local_province_name == "新疆"
drop if level3_name == "--"
drop if strpos(local_batch_name, "二") > 0
drop if strpos(spname, "中外合作") > 0
drop if strpos(spname, "国家专项") > 0
drop if strpos(spname, "马来西亚") > 0

gen category = local_type_name
replace category = "理科" if category == "物理类"
replace category = "文科" if category == "历史类"

drop if missing(num)

rename name hightitle
collapse (sum) num, by(year hightitle level3_name local_province_name category)
count

merge m:1 level3_name using "$data/scores_major.dta"
keep if _merge == 3
drop _merge

merge m:1 hightitle using "$raw/schoollistchoose.dta"
keep if _merge == 3
drop _merge

gen special_prov = inlist(local_province_name, "浙江", "上海", "北京", "天津", "山东", "海南")
gen reform2025 = inlist(local_province_name, "山西", "内蒙古", "河南", "四川", "云南", "陕西", "青海", "宁夏")
gen keepA = !(reform2025 == 1 & year == 2025)

gen treat1 = average_rank <= 3
gen post   = year >= 2023
gen DID    = treat1 * post

encode local_province_name, gen(province_num)
encode category,            gen(category_num)
encode hightitle,           gen(hightitle_num)
encode level3_name,         gen(level3_name_num)

gen lnnum = ln(num)

keep if special_prov == 0
keep if keepA == 1
count
tab treat1

reghdfe num   DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
reghdfe num   DID,        absorb($FE) vce(robust)
reghdfe lnnum DID treat1, absorb(province_num#year#category_num hightitle_num#year) vce(robust)
reghdfe lnnum DID,        absorb($FE) vce(robust)

tabstat num, by(treat1) statistics(N mean sd p50) format(%9.1f)

log close
