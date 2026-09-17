clear
* Globals come from config.do, which run_all.do loads first.
* To run this file on its own, run config.do in the same session.

log using "$logs/01_cutoff_2025.log", replace text

****************Provincial first-tier cutoffs, 2025
* The category coding follows 02_panel.do, where the two tracks introduced by
* the reform are filed under the older humanities and science labels.
* Most provinces report the special-admission control line, which is the series
* their 2017-2024 values in the historical file are drawn from. Qinghai,
* Guangdong and the six comprehensive-track provinces report the undergraduate
* or first-band line instead, again matching their own history.
* Source: provincial examination authorities, checked against the 2024 values.

input str9 province str6 category int score
"云南"     "文科" 535
"云南"     "理科" 495
"吉林"     "文科" 493
"吉林"     "理科" 479
"四川"     "文科" 533
"四川"     "理科" 518
"宁夏"     "文科" 482
"宁夏"     "理科" 441
"安徽"     "文科" 515
"安徽"     "理科" 514
"山西"     "文科" 534
"山西"     "理科" 507
"广西"     "文科" 518
"广西"     "理科" 495
"江西"     "文科" 539
"江西"     "理科" 505
"河北"     "文科" 527
"河北"     "理科" 499
"河南"     "文科" 552
"河南"     "理科" 535
"湖北"     "文科" 536
"湖北"     "理科" 516
"湖南"     "文科" 503
"湖南"     "理科" 476
"甘肃"     "文科" 500
"甘肃"     "理科" 475
"贵州"     "文科" 517
"贵州"     "理科" 483
"辽宁"     "文科" 522
"辽宁"     "理科" 515
"重庆"     "文科" 515
"重庆"     "理科" 498
"陕西"     "文科" 497
"陕西"     "理科" 473
"黑龙江"   "文科" 480
"黑龙江"   "理科" 472
"江苏"     "文科" 537
"江苏"     "理科" 519
"福建"     "文科" 531
"福建"     "理科" 520
"内蒙古"   "文科" 523
"内蒙古"   "理科" 487
"青海"     "文科" 405
"青海"     "理科" 350
"广东"     "文科" 464
"广东"     "理科" 436
"北京"     "综合" 430
"上海"     "综合" 402
"天津"     "综合" 476
"浙江"     "综合" 490
"山东"     "综合" 521
"海南"     "综合" 480
end

gen local_match = "2025_" + province + "_" + category
rename score 一本线分数
gen 一本线排名 = .
keep local_match 一本线分数 一本线排名
isid local_match

save "$data/cutoff2025.dta", replace

count

log close
