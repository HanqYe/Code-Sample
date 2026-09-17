****************Master file
* Set the two paths in config.do, then run this file start to finish.
* Edit the line below to point at the repository.

clear all
do "E:/replication/major-choice-replication/config.do"

****************Build
do "$root/code/build/01_cutoff_2025.do"
do "$root/code/build/02_panel.do"
do "$root/code/build/03_sample.do"
do "$root/code/build/04_llm_scores.do"

****************Tables
do "$root/code/tables/05_descriptives.do"
do "$root/code/tables/06_main.do"
do "$root/code/tables/07_robustness.do"
do "$root/code/tables/08_mechanisms.do"

****************Figures
do "$root/code/figures/09_event_study.do"
do "$root/code/figures/10_honestdid.do"
do "$root/code/figures/11_dose.do"
do "$root/code/figures/12_llm_scores.do"

* Figure 7 is drawn in Python, after 08_mechanisms.do writes prov_density.csv:
*     python code/python/draw_maps.py
