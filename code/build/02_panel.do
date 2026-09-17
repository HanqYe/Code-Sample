clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/02_panel.log", replace text

****************Historical first-tier cutoffs
import excel using "$raw/一本线各省历年.xlsx", clear first
drop if 年份 == .
rename 年份 year
rename 省份 province
tostring year, replace
tostring province, replace
gen category = 选科
replace category = "理科" if category == "物理类"
replace category = "文科" if category == "历史类"
replace category = "综合" if category == "不限"
gen local_match = year + "_" + province + "_" + category

*Ningxia has two rows per year and track, only one of which carries the rank
duplicates tag local_match, gen(dup)
drop if dup > 0 & missing(一本线排名)
drop dup
isid local_match

keep local_match 一本线分数 一本线排名

append using "$data/cutoff2025.dta"
isid local_match
save "$data/cutoff.dta", replace

****************Admission records scraped earlier, 2020-2024
insheet using "$raw/分数.csv", clear
rename name hightitle
keep hightitle spname year level2_name level3_name local_province_name local_type_name local_batch_name min min_section proscore school_id
tostring min min_section proscore school_id, replace force
gen src = 1
save "$data/scores_old.dta", replace

****************Admission records collected for this paper, 2024-2025
import delimited using "$raw/scores_2024_2026.csv", clear varnames(1) encoding("utf-8")
rename name hightitle
keep hightitle spname year level2_name level3_name local_province_name local_type_name local_batch_name min min_section proscore school_id
drop if year > 2025

*The older file was read with insheet, so min and its neighbours are strings there
tostring min min_section proscore school_id, replace force

gen src = 2

****************Combine, preferring the newer record where the two overlap
append using "$data/scores_old.dta"
tab year src

gen key = string(year) + "|" + school_id + "|" + local_province_name + "|" + local_type_name + "|" + spname
bysort key (src): keep if _n == _N
drop key src school_id

tab year

drop if local_province_name == "西藏"
drop if local_province_name == "新疆"
drop if level3_name == "--"
merge m:1 hightitle using "$raw/schoollistchoose.dta"
drop if _merge == 2
drop _merge
save "$data/scores_raw.dta", replace

****************Provincial records for 2017-2019
foreach k in 安徽 福建 甘肃 广东 广西 贵州 海南 河北 河南 黑龙江 湖北 湖南 吉林 江苏 江西 辽宁 内蒙古 青海 山东 山西 陕西 上海 四川 天津 云南 浙江 重庆 北京 {
	append using "$raw/补充分数线/`k'_full.dta", force
}

drop _merge
tab year

****************Sample restrictions
gen special_prov = inlist(local_province_name, "浙江", "上海", "北京", "天津", "山东", "海南")

*Fifth reform wave, first examined in 2025, so that year is not comparable with their own history
gen reform2025 = inlist(local_province_name, "山西", "内蒙古", "河南", "四川", "云南", "陕西", "青海", "宁夏")
drop if strpos(local_batch_name, "二") > 0
drop if strpos(spname, "中外合作") > 0
drop if strpos(spname, "国家专项") > 0
drop if strpos(spname, "马来西亚") > 0
gen min_num = real(min)
gen min_section_num = real(min_section)

gen category = local_type_name
replace category = "理科" if category == "物理类"
replace category = "文科" if category == "历史类"

tab category special_prov

****************Keep cells clearing above the first-tier line
gen year_str = string(year)
gen local_match = year_str + "_" + local_province_name + "_" + category
merge m:1 local_match using "$data/cutoff.dta"
keep if _merge == 3
drop _merge
drop if min_num < 一本线分数

****************One record per major and year, the lowest cutoff
gen province_university = level3_name + "_" + local_province_name + "_" + hightitle + "_" + category
egen prouni_id = group(province_university)
bysort prouni_id year (min_num): gen is_lowest = (_n == 1)
drop if is_lowest == 0
drop is_lowest

keep prouni_id province_university year hightitle spname level2_name level3_name local_province_name category f985 f211 proscore view_total min_num min_section_num special_prov reform2025 一本线分数 一本线排名

****************Normalised rank ratio
bysort year local_province_name category: egen max_rank = max(min_section_num)
gen ratio_num = min_section_num / max_rank

encode local_province_name, gen(province_num)
encode category,            gen(category_num)
encode hightitle,           gen(hightitle_num)
encode level3_name,         gen(level3_name_num)

****************Event time, 2017-2025
gen event_time = year - 2023
gen id = event_time + 7
gen event_time_1 = id == 1
gen event_time_2 = id == 2
gen event_time_3 = id == 3
gen event_time_4 = id == 4
gen event_time_5 = id == 5
gen event_time_6 = id == 6
gen event_time_7 = id == 7
gen event_time_8 = id == 8
gen event_time_9 = id == 9

compress
save "$data/panel.dta", replace

tab year special_prov
sum ratio_num min_num

log close
