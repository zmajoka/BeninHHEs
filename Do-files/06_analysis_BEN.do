********************************************************************************
* EHCVM BENIN - ANALYSIS DO-FILE
********************************************************************************
* Purpose: Generate all analysis tables and export to Excel with separate tabs.
*          Sections 1-4 as specified in the Analysis Plan.
*
* Author:  Zaineb Majoka (mzaineb@worldbank.org). Based on Do-File for Senegal.
* Date:    April 2026
*
* INPUT:   ${final}/BEN_panel_2018_2021.dta
*
* OUTPUT:  ${output}/BEN_analysis.xlsx  (all tabs)
*          ${output}/hist_*.gph         (histograms)
*
* REFERENCE DO-FILES (from main branch):
*   - regressions.do        → regression specifications
*   - Add_gov_measures_and_TFP_estimates.do → TFP estimation
*   - descriptive_stats.do  → descriptive statistics layout
*
* NOTE ON LEVEL OF ANALYSIS
* -------------------------
* The panel dataset includes all individuals from the 2018 household roster.
* Three variables created in 05_create_panel_BEN.do allow changing the level of
* analysis:
*
*   is_entrepreneur     = 1 if individual was an entrepreneur in either wave.
*                         Use: keep if is_entrepreneur == 1
*
*   ent_status          = 4-category variable:
*                           1 = Not entrepreneur in either wave
*                           2 = Entrepreneur in 2018 only
*                           3 = Entrepreneur in 2021 only
*                           4 = Entrepreneur in both waves
*                         Use: keep if ent_status != 1 (drop non-entrepreneurs)
*
*   hh_has_enterprise   = 1 if any HH member was an entrepreneur in either wave.
*                         Use: keep if hh_has_enterprise == 1
*
* Entrepreneurs are identified at the individual level using nonag_id
* (grappe + menage + numind), matching the approach in set_up_data.do.
*
* KEY DIFFERENCES FROM SEN:
*   - GDP deflators: 101 (2018) and 105.2 (2021)
*   - Credit variables: hh_got_credit/ind_got_credit (not hh_has_loan/ind_has_loan)
*   - Location: Cotonou/Porto-Novo (not Dakar/Thiès)
*   - Fiscal ID label: NIF (not NINEA)
*   - Input: BEN_panel_2018_2021.dta / Output: BEN_analysis.xlsx
********************************************************************************

clear all
set more off
set matsize 5000

********************************************************************************
* PART 0: SET PATHS
********************************************************************************

* Main project directory — UPDATE THIS TO MATCH YOUR SETUP
global project "C:\Users\WB461621\OneDrive - WBG\SPJ\West Africa\Regional HH Enterprise Work"

* Data directories
global data_2018     "${project}/Data/BEN/2018"
global data_2021     "${project}/Data/BEN/2021"
global intermediate  "${project}/Data/BEN/Intermediate"
global output        "${project}/Output/BEN"
global final         "${project}/Data/BEN/Final"

capture mkdir "${output}"

* Excel output file
global xlout "${output}/BEN_analysis.xlsx"

* GDP Deflator values (2018 base year, source: WDI)
global gdpdef_2018 = 101
global gdpdef_2021 = 105.2


********************************************************************************
* PART 1: LOAD DATA AND CREATE REGRESSION VARIABLES
********************************************************************************

di as text _n "=============================================="
di as text "LOADING PANEL DATA AND CREATING VARIABLES"
di as text "=============================================="

use "${final}/BEN_panel_2018_2021.dta", clear

gen indweight2018 = hhweight_2018/hhsize_2018
gen indweight2021 = hhweight_2021/hhsize_2021

********************************************************************************
* PART 1a: Additional Summary Stats
********************************************************************************

* Access to credit and source of credit (individual level)
* NOTE: BEN uses hh_got_credit / ind_got_credit (not hh_has_loan / ind_has_loan)

preserve
sort hhid hh_got_credit_2018 hh_has_enterprise_2018
collapse (first) hh_got_credit_2018 hh_has_enterprise_2018 hhweight, by(hhid)
collapse hh_got_credit_2018 [pweight=hhweight], by(hh_has_enterprise_2018)
outsheet using "$output\credit_access_hh2018.xls", replace
restore

preserve
sort hhid hh_got_credit_2021 hh_has_enterprise_2021
collapse (first) hh_got_credit_2021 hh_has_enterprise_2021 hhweight, by(hhid)
collapse hh_got_credit_2021 [pweight=hhweight], by(hh_has_enterprise_2021)
outsheet using "$output\credit_access_hh2021.xls", replace
restore

preserve
collapse ind_got_credit_2018 [pweight=indweight2018], by(ent_2018)
outsheet using "$output\credit_access_ind_2018.xls", replace
restore

preserve
collapse ind_got_credit_2021 [pweight=indweight2021], by(ent_2021)
outsheet using "$output\credit_access_ind_2021.xls", replace
restore

* Main source of credit

gen byte total = 1
label variable total "All entrepreneurs"

tabout hh_main_credit_source_2018 total if hh_has_enterprise_2018 ==1 [iweight=hhweight_2018] using "$output\Results.xls", replace c(freq col row) format(0c 1p 1p) layout(cb) style(xls) h1("Source of credit, 2018")
tabout hh_main_credit_source_2021 total if hh_has_enterprise_2021 ==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) style(xls) h1("Source of credit, 2021")

* Sector by location

tabout sector_2018 location_2018 if hh_has_enterprise_2018 ==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Sector of enterprise by location, 2018")
tabout sector_2021 location_2021 if hh_has_enterprise_2021 ==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Sector of enterprise by location, 2021")

*------------------------------------------------------------------------------
* 1.1: Log transformations matching regressions.do
*------------------------------------------------------------------------------

* Log profit: floor at 0 (matching regressions.do: max(log(x), 0))
capture drop lnprofit_2018 lnprofit_2021
gen lnprofit_2018 = max(log(profit_2018), 0) if profit_2018 < .
gen lnprofit_2021 = max(log(profit_2021), 0) if profit_2021 < .

* Log capital: floor at 0
capture drop lnvalue_total_2018 lnvalue_total_2021
gen lnvalue_total_2018 = max(log(value_total_2018), 0) if value_total_2018 < .
gen lnvalue_total_2021 = max(log(value_total_2021), 0) if value_total_2021 < .

*------------------------------------------------------------------------------
* 1.2: Recode variables for regressions (matching regressions.do exactly)
*------------------------------------------------------------------------------

* Age categories (from regressions.do)
capture drop age_cat_2018
recode age_2018 (15/29=1 "15-29") (30/44=2 "30-44") (45/64=3 "45-64") ///
    (64/120=4 "65+"), gen(age_cat_2018)

* Education categories (3 categories, from regressions.do)
capture drop educ_2018
recode educ_hi_2018 (1=1 "Less than primary") (3=2 "Less than Secondary") ///
    (4/9 = 3 "Secondary+"), gen(educ_2018)
replace educ_2018 = 1 if educ_scol_2018 == 1
replace educ_2018 = 3 if educ_scol_2018 > 1 & educ_scol_2018 < .

capture drop educ_2021
recode educ_hi_2021 (1=1 "Less than primary") (3=2 "Less than Secondary") ///
    (4/9 = 3 "Secondary+"), gen(educ_2021)
replace educ_2021 = 1 if educ_scol_2021 == 1
replace educ_2021 = 3 if educ_scol_2021 > 1 & educ_scol_2021 < .

* Per capita consumption quintiles
capture drop pcexpQ_2018
xtile pcexpQ_2018 = pcexp_2018 [aw=hhweight_2018], nq(5)

* Firm age categories (from regressions.do)
capture drop firm_age_2018
recode year_est_2018 (1940/1999.5=1 "<2000") (2000/2009=2 "2000-2009") ///
    (2010/2014 = 3 "2010-2014") (2015/2019 = 4 "2015-2019"), gen(firm_age_2018)

* Non-HH employee categories (from regressions.do)
capture drop emp_cat_2018
recode num_emp_2018 (0=0 "0") (1=1 "1") (2/100=2 "2+"), gen(emp_cat_2018)

* HH employee categories (from regressions.do)
capture drop emphh_cat_2018
recode num_hhemp_2018 (0=0 "0") (1=1 "1") (2/100=2 "2+"), gen(emphh_cat_2018)

* Ethnicity: replace missing with 99 (from regressions.do)
replace ethnie_2018 = 99 if ethnie_2018 == .

*------------------------------------------------------------------------------
* 1.3: Create derived variables needed for regressions
*------------------------------------------------------------------------------

* Internet alias (source variable is has_internet_2018, rename for consistency)
capture drop internet_2018
gen internet_2018 = has_internet_2018

*------------------------------------------------------------------------------
* 1.4: Additional variables needed for analysis
*------------------------------------------------------------------------------

* Number of HH members in wage jobs (for transition analysis)
foreach yr in 2018 2021 {
    capture drop has_wage_job_`yr'
    gen byte has_wage_job_`yr' = (activity_type_`yr' == 2)
    bysort hhid: egen n_hh_wage_`yr' = total(has_wage_job_`yr')
    label variable n_hh_wage_`yr' "Number of HH members in wage jobs (`yr')"
    drop has_wage_job_`yr'
}

* Formal enterprise dummy: meets all three definitions
foreach yr in 2018 2021 {
    gen byte formal_all3_`yr' = (firm_keeps_accounts_`yr' == 1 & ///
        firm_has_fisc_id_`yr' == 1 & firm_in_trade_register_`yr' == 1) ///
        if ent_`yr' == 1
    label variable formal_all3_`yr' "Formal by all 3 definitions (`yr')"
}


********************************************************************************
* PART 2: TFP ESTIMATION (preserve/restore)
********************************************************************************

di as text _n "=============================================="
di as text "ESTIMATING TFP"
di as text "=============================================="

preserve

* Keep only panel enterprises (in both waves)
keep if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1

* Create enterprise identifier
gen str ent_id = string(grappe) + "_" + string(menage) + "_" + string(numind)

* Keep needed variables
keep ent_id grappe menage numind hhweight_2018 ///
    revenue_2018 revenue_2021 value_total_2018 value_total_2021 ///
    expenses_2018 expenses_2021 val_hired_labor_2018 val_hired_labor_2021

* Expand to long format (2 obs per enterprise)
expand 2, gen(_copy)
bysort ent_id (_copy): gen year = _n - 1

* Create production function variables
gen val_output = .
replace val_output = revenue_2018     if year == 0
replace val_output = revenue_2021     if year == 1

gen val_capital = .
replace val_capital = value_total_2018 if year == 0
replace val_capital = value_total_2021 if year == 1

gen val_inter_good = .
replace val_inter_good = expenses_2018 if year == 0
replace val_inter_good = expenses_2021 if year == 1

gen val_hired_labor = .
replace val_hired_labor = val_hired_labor_2018 if year == 0
replace val_hired_labor = val_hired_labor_2021 if year == 1

* Log transformations (using log(1+x) as in TFP do-file)
foreach var in val_output val_capital val_inter_good val_hired_labor {
    gen log_`var' = log(1 + `var')
}

* Translog terms (squared and interactions)
gen l_cap_squared        = log_val_capital * log_val_capital
gen l_intergood_squared  = log_val_inter_good * log_val_inter_good
gen l_labor_squared      = log_val_hired_labor * log_val_hired_labor
gen l_cap_l_intergood    = log_val_capital * log_val_inter_good
gen l_cap_l_labor        = log_val_capital * log_val_hired_labor
gen l_labor_l_intergood  = log_val_hired_labor * log_val_inter_good

* Panel setup
encode ent_id, gen(hhid_num)
sort hhid_num year
xtset hhid_num year

* Fixed effects regression (translog production function)
global tfp_regressors log_val_capital log_val_inter_good log_val_hired_labor ///
    l_cap_squared l_intergood_squared l_labor_squared ///
    l_cap_l_intergood l_cap_l_labor l_labor_l_intergood

xtreg log_val_output $tfp_regressors [pw=hhweight_2018], fe vce(cluster grappe)

* Export TFP production function estimates
* Capture r(table) before putexcel set clears r() results
matrix results = r(table)'

putexcel set "${xlout}", sheet("TFP_Estimates") replace
putexcel B1 = "TFP Production Function Estimates (Fixed Effects)"
putexcel B3 = "Variable" C3 = "Coefficient" D3 = "Std Error" E3 = "P-value"
matrix coef = results[1..., 1]
matrix se   = results[1..., 2]
matrix pval = results[1..., 4]

putexcel B4 = matrix(coef), rownames nformat("0.000")
putexcel D4 = matrix(se), nformat("0.000")

* Add p-values
local nrows = rowsof(results)
forvalues i = 1/`nrows' {
    local pv = results[`i', 4]
    local row = `i' + 3
    putexcel E`row' = `pv', nformat("0.000")
}

* Predict TFP residual
predict tfp, e

* Save TFP values per enterprise-year
keep grappe menage numind year tfp
reshape wide tfp, i(grappe menage numind) j(year)
rename tfp0 tfp_2018
rename tfp1 tfp_2021

tempfile tfp_data
save `tfp_data'

restore

* Merge TFP back into main dataset
merge m:1 grappe menage numind using `tfp_data', nogenerate

* TFP increased dummy
gen byte tfp_increased = (tfp_2021 > tfp_2018) ///
    if !missing(tfp_2018) & !missing(tfp_2021)
label variable tfp_increased "TFP increased between 2018 and 2021"


********************************************************************************
* PART 3: SECTION 1 — INTRODUCTION
********************************************************************************

di as text _n "=============================================="
di as text "SECTION 1: INTRODUCTION"
di as text "=============================================="

* % of HHs operating at least one enterprise
tabout hh_has_enterprise_2018 total [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% of HHs with an enterprise, 2018")
tabout hh_has_enterprise_2021 total [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% of HHs with an enterprise, 2021")

putexcel set "${xlout}", sheet("S1_Introduction") modify
putexcel B1 = "Section 1: Introduction"
putexcel B2 = "Household Enterprises in Benin, 2018 and 2021"

*--- % of HH operating at least 1 enterprise ---
putexcel B4 = "Indicator" C4 = "2018" D4 = "2021"

* 2018: total number of enterprises within a household
bysort hhid: egen num_enterprise_2018 = total(ent_2018) if ent_2018==1
replace num_enterprise_2018=0 if ent_2018==0

* 2018: average number of enterprises per household, among those with an enterprise
preserve
sort hhid num_enterprise_2018 ent_2018
collapse (first) num_enterprise_2018 ent_2018 hhweight, by(hhid)
collapse num_enterprise_2018 if ent_2018==1 [pweight=hhweight]
outsheet using "$output/av_enterprises2018.xls", replace
restore

* 2018: HH with at least 1 enterprise
preserve
keep if in_2018 == 1
bysort hhid: keep if _n == 1
sum hh_has_enterprise_2018 [aw=hhweight]
local pct_hh_ent_2018 = r(mean) * 100
restore

* 2021: total number of enterprises within a household
bysort hhid: egen num_enterprise_2021 = total(ent_2021) if ent_2021==1
replace num_enterprise_2021=0 if ent_2021==0

* 2021: average number of enterprises per household, among those with an enterprise
preserve
sort hhid num_enterprise_2021 ent_2021
collapse (first) num_enterprise_2021 ent_2021 hhweight, by(hhid)
collapse num_enterprise_2021 if ent_2021==1 [pweight=hhweight]
outsheet using "$output/av_enterprises2021.xls", replace
restore

* 2021: HH with at least 1 enterprise
preserve
    keep if in_2021 == 1
    bysort hhid: keep if _n == 1
    sum hh_has_enterprise_2021 [aw=hhweight_2021]
    local pct_hh_ent_2021 = r(mean) * 100
restore

putexcel B5 = "% of HH operating at least 1 enterprise"
putexcel C5 = `pct_hh_ent_2018', nformat("0.0")
putexcel D5 = `pct_hh_ent_2021', nformat("0.0")

* Number of enterprises per household — categories 1, 2, 3+
foreach yr in 2018 2021 {
    gen byte n_ent_cat_`yr' = .
    replace n_ent_cat_`yr' = 1 if num_enterprise_`yr' == 1
    replace n_ent_cat_`yr' = 2 if num_enterprise_`yr' == 2
    replace n_ent_cat_`yr' = 3 if num_enterprise_`yr' >= 3 & !missing(num_enterprise_`yr')
    label variable n_ent_cat_`yr' "Enterprise count category (`yr')"
}

label define n_ent_cat_lbl 1 "1" 2 "2" 3 "3+"
label values n_ent_cat_2018 n_ent_cat_lbl
label values n_ent_cat_2021 n_ent_cat_lbl

tabout n_ent_cat_2018 total [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Number of enterprises per hh, 2018")
tabout n_ent_cat_2021 total [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Number of enterprises per hh, 2021")

*--- Average enterprise size (employees) ---
putexcel B7 = "Average Enterprise Size"

* Total employees (family + non-family, excl. proprietor)
putexcel B8 = "Total employees (family + non-family)"
sum total_emp_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C8 = `_mean', nformat("0.00")
sum total_emp_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D8 = `_mean', nformat("0.00")

* Family employees
putexcel B9 = "Family employees"
sum num_hhemp_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C9 = `_mean', nformat("0.00")
sum num_hhemp_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D9 = `_mean', nformat("0.00")

* Non-family employees
putexcel B10 = "Non-family employees"
sum num_emp_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C10 = `_mean', nformat("0.00")
sum num_emp_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D10 = `_mean', nformat("0.00")

* % with 0 non-family employees
putexcel B11 = "% with 0 non-family employees"
gen byte _zero_emp_2018 = (num_emp_2018 == 0) if ent_2018 == 1
sum _zero_emp_2018 [aw=hhweight_2018] if ent_2018 == 1
putexcel C11 = (r(mean) * 100), nformat("0.0")
gen byte _zero_emp_2021 = (num_emp_2021 == 0) if ent_2021 == 1
sum _zero_emp_2021 [aw=hhweight_2021] if ent_2021 == 1
putexcel D11 = (r(mean) * 100), nformat("0.0")

* % with 1 or more non-family employees
putexcel B12 = "% with 1+ non-family employees"
gen byte _oneplus_emp_2018 = (num_emp_2018 >= 1 & !missing(num_emp_2018)) if ent_2018 == 1
sum _oneplus_emp_2018 [aw=hhweight_2018] if ent_2018 == 1
putexcel C12 = (r(mean) * 100), nformat("0.0")
gen byte _oneplus_emp_2021 = (num_emp_2021 >= 1 & !missing(num_emp_2021)) if ent_2021 == 1
sum _oneplus_emp_2021 [aw=hhweight_2021] if ent_2021 == 1
putexcel D12 = (r(mean) * 100), nformat("0.0")

* % with 2 or more non-family employees
putexcel B13 = "% with 2+ non-family employees"
gen byte _twoplus_emp_2018 = (num_emp_2018 >= 2 & !missing(num_emp_2018)) if ent_2018 == 1
sum _twoplus_emp_2018 [aw=hhweight_2018] if ent_2018 == 1
putexcel C13 = (r(mean) * 100), nformat("0.0")
gen byte _twoplus_emp_2021 = (num_emp_2021 >= 2 & !missing(num_emp_2021)) if ent_2021 == 1
sum _twoplus_emp_2021 [aw=hhweight_2021] if ent_2021 == 1
putexcel D13 = (r(mean) * 100), nformat("0.0")

drop _zero_emp_* _oneplus_emp_* _twoplus_emp_*

*--- 1b: HH enterprise ownership by location ---
* % of households with at least 1 enterprise, Urban vs Rural, 2018 & 2021

preserve
keep if ent_2018==1
tabout ent_2018 rural_2018 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Enterprise by location 2018")
restore

preserve
keep if ent_2021==1
tabout ent_2021 rural_2021 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Enterprise location 2021")
restore

*--- 1c: Composition of all employment excluding agriculture ---
* All workers (15-64), including no activity

tabout activity_type_2018 total if sector_work_2018!=1 & working_age_2018==1 [iweight=indweight2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Non-ag Activity Type for 15-64, 2018")
tabout activity_type_2021 total if sector_work_2021!=1 & working_age_2021==1 [iweight=indweight2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Non-ag Activity Type for 15-64, 2021")

* Activity type excluding no activity
tabout emp_type_2018 total if sector_work_2018!=1 & working_age_2018==1 [iweight=indweight2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Non-ag Activity Type 15-64, excluding no activity, 2018")
tabout emp_type_2021 total if sector_work_2021!=1 & working_age_2021==1 [iweight=indweight2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("Non-ag Activity Type 15-64 excluding no activity, 2021")


********************************************************************************
* PART 4: SECTION 2 — STYLIZED FACTS ON THE PROFILE
********************************************************************************

di as text _n "=============================================="
di as text "SECTION 2: PROFILE"
di as text "=============================================="

*--- 2a: Formality shares ---

tabout firm_keeps_accounts_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% keeping written accounts, 2018")
tabout firm_keeps_accounts_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% keeping written accounts, 2021")

* NOTE: BEN fiscal ID is NIF (not NINEA as in SEN)
tabout firm_has_fisc_id_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% with fiscal ID NIF, 2018")
tabout firm_has_fisc_id_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1("% with fiscal ID NIF, 2021")

tabout firm_in_trade_register_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(% registered in trade register, 2018)
tabout firm_in_trade_register_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(% registered in trade register, 2021)

tabout formal_all3_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(% meeting all 3 definitions, 2018)
tabout formal_all3_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(% meeting all 3 definitions, 2021)

*--- 2b: Non-family employees change ---
putexcel set "${xlout}", sheet("S2_Profile") modify
putexcel B1 = "Section 2: Stylized Facts on the Profile"

putexcel B3 = "Non-Family Employee Changes (Panel Enterprises)"
putexcel B4 = "Indicator" C4 = "Value"

* Average non-family employees in 2018 (panel enterprises)
sum num_emp_2018 [aw=hhweight_2018] if ent_status==4
local _mean = r(mean)
putexcel B5 = "Avg non-family employees in 2018"
putexcel C5 = `_mean', nformat("0.00")

* Average non-family employees in 2021 (panel enterprises)
sum num_emp_2021 [aw=hhweight_2021] if ent_status==4
local _mean = r(mean)
putexcel B6 = "Avg non-family employees in 2021"
putexcel C6 = `_mean', nformat("0.00")

* Number and share that increased
count if change_num_emp > 0 & change_num_emp < . & ent_status==4
local n_increased = r(N)
putexcel B7 = "N enterprises that increased non-family employees"
putexcel C7 = `n_increased'

sum change_num_emp [aw=hhweight_2018] if ent_status==4
local n_total = r(N)

gen byte emp_increased = (change_num_emp > 0) if ent_status==4 & !missing(change_num_emp)
sum emp_increased [aw=hhweight_2018] if ent_status==4
local _mean = r(mean) * 100
putexcel B8 = "Share that increased non-family employees (%)"
putexcel C8 = `_mean', nformat("0.0")

*--- 2c: Sector of operation ---
tabout sector_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Sector of HHE, 2018)
tabout sector_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Sector of HHE, 2021)

*--- 2d: Gender of entrepreneurs ---
tabout sexe_2018 total if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Gender of entrepreneur, 2018)
tabout sexe_2021 total if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Gender of entrepreneur, 2021)

*--- 2e: Sector distribution by gender ---
tabout sexe_2018 sector_2018 if ent_2018==1 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Gender/Sector of entrepreneur, 2018)
tabout sexe_2021 sector_2021 if ent_2021==1 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(Gender/Sector of entrepreneur, 2021)

*--- 2f: HH enterprise ownership across welfare quintiles ---
preserve
    bysort hhid: keep if _n == 1
    tabout hh_has_enterprise_2018 welfare_quintile_2018 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(HH enterprise by quintile, 2018)
    tabout hh_has_enterprise_2021 welfare_quintile_2021 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(HH Enterprise by quintile, 2021)
restore

*--- 2g: Profiles of HE vs Wage Workers ---

* 2018
preserve
    keep if in_2018 == 1 & age_2018 >= 15 & age_2018 < .
    gen byte worker_type = .
    replace worker_type = 1 if ent_2018 == 1           // HE
    replace worker_type = 2 if activity_type_2018 == 2 // Wage
    keep if inlist(worker_type, 1, 2)
    label define wtype 1 "HE" 2 "Wage"
    label values worker_type wtype

    tabout worker_type sexe_2018    [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by gender, 2018)
    tabout worker_type rural_2018   [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by urban/rural, 2018)
    tabout worker_type location_2018 [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by location, 2018)
    tabout worker_type educ_2018    [iweight=hhweight_2018] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by education, 2018)
restore

* 2021
preserve
    keep if in_2021 == 1 & age_2021 >= 15 & age_2021 < .
    gen byte worker_type = .
    replace worker_type = 1 if ent_2021 == 1           // HE
    replace worker_type = 2 if activity_type_2021 == 2 // Wage
    keep if inlist(worker_type, 1, 2)
    label define wtype 1 "HE" 2 "Wage"
    label values worker_type wtype

    tabout worker_type sexe_2021    [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by gender, 2021)
    tabout worker_type rural_2021   [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by urban/rural, 2021)
    tabout worker_type location_2021 [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by location, 2021)
    tabout worker_type educ_2021    [iweight=hhweight_2021] using "$output\Results.xls", append c(freq col row) format(0c 1p 1p) layout(cb) h1(entrepreneur vs. wage by education, 2021)
restore


********************************************************************************
* PART 5: SECTION 3 — PERFORMANCE (DESCRIPTIVE)
********************************************************************************

di as text _n "=============================================="
di as text "SECTION 3: PERFORMANCE (DESCRIPTIVE)"
di as text "=============================================="

putexcel set "${xlout}", sheet("S3_Performance") modify
putexcel B1 = "Section 3: Stylized Facts on Performance"

*--- 3a: Average profits ---
putexcel B3 = "Profits" C3 = "2018" D3 = "2021"

putexcel B4 = "Average monthly profit (CFA)"
sum profit_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C4 = `_mean', nformat("#,##0")
sum profit_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D4 = `_mean', nformat("#,##0")

*--- 3b: Profit categories ---
putexcel B6 = "Profit Distribution (%)" C6 = "2018" D6 = "2021"

* 2018
sum hhweight_2018 if ent_2018 == 1 & profit_2018 < 0
local w_neg = r(sum)
sum hhweight_2018 if ent_2018 == 1 & profit_2018 == 0
local w_zero = r(sum)
sum hhweight_2018 if ent_2018 == 1 & profit_2018 > 0 & profit_2018 < .
local w_pos = r(sum)
local w_all = `w_neg' + `w_zero' + `w_pos'

putexcel B7 = "Negative/loss"
putexcel C7 = (`w_neg'/`w_all'*100), nformat("0.0")
putexcel B8 = "Zero profits"
putexcel C8 = (`w_zero'/`w_all'*100), nformat("0.0")
putexcel B9 = "Positive profits"
putexcel C9 = (`w_pos'/`w_all'*100), nformat("0.0")

* 2021
sum hhweight_2021 if ent_2021 == 1 & profit_2021 < 0
local w_neg = r(sum)
sum hhweight_2021 if ent_2021 == 1 & profit_2021 == 0
local w_zero = r(sum)
sum hhweight_2021 if ent_2021 == 1 & profit_2021 > 0 & profit_2021 < .
local w_pos = r(sum)
local w_all = `w_neg' + `w_zero' + `w_pos'

putexcel D7 = (`w_neg'/`w_all'*100), nformat("0.0")
putexcel D8 = (`w_zero'/`w_all'*100), nformat("0.0")
putexcel D9 = (`w_pos'/`w_all'*100), nformat("0.0")

*--- 3c: Profit growth (panel enterprises) ---
putexcel B11 = "Profitability Over Time (Panel Enterprises)"
putexcel B12 = "Indicator" C12 = "Value"

* Average real profit in 2018 and 2021
putexcel B13 = "Average real profit 2018 (CFA)"
sum profit_real_2018 [aw=hhweight_2018] if ent_status==4
local _mean = r(mean)
putexcel C13 = `_mean', nformat("#,##0")

putexcel B14 = "Average real profit 2021 (CFA, 2018 prices)"
sum profit_real_2021 [aw=hhweight_2018] if ent_status==4
local _mean = r(mean)
putexcel C14 = `_mean', nformat("#,##0")

* Average annual growth rate of profits
* Annual growth = ((profit_2021_real / profit_2018)^(1/3) - 1) for 3-year gap
gen annual_growth_profit = .
replace annual_growth_profit = ((profit_real_2021 / profit_real_2018)^(1/3) - 1) ///
    if profit_real_2018 > 0 & profit_real_2021 > 0 & ///
    ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1

putexcel B15 = "Average annual growth rate of profits"
sum annual_growth_profit [aw=hhweight_2018]
local _mean = r(mean)
putexcel C15 = `_mean', nformat("0.000")

* Share with annual growth > 10%
gen byte growth_gt10 = (annual_growth_profit > 0.10) if !missing(annual_growth_profit)
putexcel B16 = "Share with annual profit growth > 10% (%)"
sum growth_gt10 [aw=hhweight_2018]
local _mean = r(mean)
putexcel C16 = (`_mean' * 100), nformat("0.0")

*--- 3d: Internet and electricity access ---
putexcel B18 = "Internet and Electricity Access" C18 = "2018 (%)" D18 = "2021 (%)"

putexcel B19 = "Share with internet access"
sum has_internet_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C19 = (`_mean' * 100), nformat("0.0")
sum has_internet_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D19 = (`_mean' * 100), nformat("0.0")

putexcel B20 = "Share with electricity"
sum has_electricity_2018 [aw=hhweight_2018] if ent_2018 == 1
local _mean = r(mean)
putexcel C20 = (`_mean' * 100), nformat("0.0")
sum has_electricity_2021 [aw=hhweight_2021] if ent_2021 == 1
local _mean = r(mean)
putexcel D20 = (`_mean' * 100), nformat("0.0")
