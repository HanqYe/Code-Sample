# Social Media Opinion Leaders and College Major Choice

Replication code for a difference-in-differences study of how one education
influencer's commentary moved college admission cutoffs in China. The paper
uses large language model APIs to convert several hundred hours of unstructured
speech into a score for each major category, then estimates the effect on
major-level admission outcomes for 119 universities, 2017 to 2025.

Author: Qiye Han, School of Economics, Renmin University of China.

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
  fetch_scores.py         collect the 2024-2025 admission records
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

`fetch_scores.py` collects the 2024 and 2025 admission records from the public
aggregation platform. It runs at a fixed low request rate rather than rotating
proxies, resumes from wherever it stopped, and backs off when the API returns
its throttling code. `probe_limit.py` measures the limit first: at the time of
collection the threshold was about sixty requests a minute and a block cleared
itself in roughly fifteen minutes, so the collector runs at one request every
1.5 seconds.

## A note on variable names

Variable names and category values are left in Chinese where the source data
uses Chinese, since renaming them would only add a translation layer between the
code and the files it reads. All comments and output are in English. The ones
that appear most often are the first-tier cutoff score and the corresponding
provincial rank, the examination track, and provincial GDP.

## Two things worth knowing

The scoring script that produced the DeepSeek scores drops evaluations above
5.5 for the journalism category only. That filter is inherited from the original
scoring code and is flagged in a footnote in the paper rather than silently kept
or silently removed.

Treatment is assigned at the level of the major category, and only three of the
forty categories in the estimation sample are treated. Standard errors in the
tables are heteroskedasticity-robust. Clustering at the major level gives a
coefficient of 0.0285 with a standard error of 0.0081 rather than 0.0020, and
randomization inference over which three majors are treated puts the estimate at
the ninetieth percentile of the placebo distribution. Neither is reported in the
current draft.
