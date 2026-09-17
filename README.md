# Social Media Opinion Leaders and College Major Choice

Replication code for a difference-in-differences study of how one education
influencer's commentary moved college admission cutoffs in China. The paper
uses large language model APIs to convert several hundred hours of unstructured
speech into a score for each major category, then estimates the effect on
major-level admission outcomes for 118 universities, 2017 to 2025.

## Requirements

Stata 17 or later, with `reghdfe`, `ftools`, `estout`, `distinct` and
`honestdid` installed:

```stata
ssc install reghdfe
ssc install ftools
ssc install estout
ssc install distinct
net install honestdid, from("https://raw.githubusercontent.com/mcaceresb/stata-honestdid/main") replace
```

Python 3.11 or later, with `pandas`, `requests`, `geopandas`, `matplotlib`.

## How to run

1. Edit the two paths at the top of `config.do`: `root` is this repository,
   `raw` is wherever the source data sits.
2. Open `run_all.do`, edit the one path on line 6, and run it.
3. Run `python code/python/draw_maps.py` for Figure 7, after step 2 has
   produced `data/prov_density.csv`.

To run a single file on its own, run `config.do` first in the same Stata
session. The sub-files use `clear` rather than `clear all` so that the globals
survive.

## Layout

```
config.do                 paths, fixed effect set, figure colors
run_all.do                master file

code/build/
  01_cutoff_2025.do       provincial first-tier cutoffs for 2025
  02_panel.do             assemble the admission panel, 2017-2025
  03_sample.do            merge scores and covariates, define treatment and sample
  04_llm_scores.do        collapse the GPT-4o and DeepSeek scores to major level

code/tables/
  05_descriptives.do      coverage, panel balance, Table 1
  06_main.do              Tables 4 and 5
  07_robustness.do        Table 6, the DeepSeek treatment definition, enrolment quotas
  08_mechanisms.do        Tables 7 and 8, the intensity regressions, province correlations

code/figures/
  09_event_study.do       Figures 2 and 4
  10_honestdid.do         Figure 3
  11_dose.do              Figures 8 and 9
  12_llm_scores.do        Figure 5

code/python/
  fetch_scores.py         collect the additional 2024-2025 admission records
  probe_limit.py          measure the API rate limit before collecting
  draw_maps.py            Figure 7

data/                     intermediate datasets, written by the build
output/tables/            LaTeX tables
output/figures/           PDF and PNG figures
output/logs/              Stata logs
```

## Data

The raw data are not included. They are two scraped admission files, a set of
provincial records for 2017 to 2019, the language model scoring output, and
four small province-level files. Place them under the `raw` path set in
`config.do` with the filenames the build expects, which appear in `02_panel.do`
and `03_sample.do`.

## A note on variable names

Variable names and category values are left in Chinese where the source data
uses Chinese, since renaming them would only add a translation layer between the
code and the files it reads. All comments and output are in English. The ones
that appear most often are the first-tier cutoff score and the corresponding
provincial rank, the examination track, and provincial GDP.
