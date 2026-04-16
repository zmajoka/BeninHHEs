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
