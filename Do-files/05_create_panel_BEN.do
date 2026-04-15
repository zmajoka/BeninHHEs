********************************************************************************
* EHCVM BENIN - PANEL DATA: MERGE 2018 AND 2021
********************************************************************************
* Purpose: Create a panel dataset by merging 2018 and 2021 cleaned data.
*          Includes all variables specified in the Analysis Plan.
*
* Author:  Zaineb Majoka (mzaineb@worldbank.org). Based on Do-File for Senegal.
* Date:    April 2026
*
* INPUT:   ${intermediate}/BEN_2018_cleaned.dta
*          ${intermediate}/BEN_2021_cleaned.dta
*
* OUTPUT:  ${final}/BEN_panel_2018_2021.dta
*
* NOTES:
*   - Unit of observation: individual (numind) within household (grappe+menage)
*   - HH matching uses grappe + menage (same EA and household number)
*   - Individual matching uses grappe + menage + numind, with gender/age checks
*   - All year-specific variables carry _2018 or _2021 suffixes
*   - Panel-level variables (transitions, changes) have no suffix
*
* KEY DIFFERENCES FROM SEN:
*   - GDP deflators: 101 (2018) and 105.2 (2021)
*   - Enterprise screening files: s10_1_me_ben2018 / s10a_me_ben2021
*   - Credit variables: ind_got_credit/hh_got_credit (not ind_has_loan/hh_has_loan)
*   - BEN 2021: departement (not region) for location; from welfare file
*   - Output: BEN_panel_2018_2021.dta
********************************************************************************

clear all
set more off

********************************************************************************
* PART 0: SET PATHS
********************************************************************************

* Main project directory
global project "C:\Users\WB461621\OneDrive - WBG\SPJ\West Africa\Regional HH Enterprise Work"

* Data directories
global data_2018     "${project}/Data/BEN/2018"
global data_2021     "${project}/Data/BEN/2021"
global intermediate  "${project}/Data/BEN/Intermediate"
global output        "${project}/Output/BEN"
global final         "${project}/Data/BEN/Final"

* Create directories if needed
capture mkdir "${final}"
capture mkdir "${output}"

* GDP Deflator values (2018 base year)
* Source: WDI
global gdpdef_2018 = 101
global gdpdef_2021 = 105.2
* NOTE: GDP deflator is a broader economy-wide price index that covers all
* goods and services produced in the economy, including investment goods and
* government spending, not just consumer goods. For firm-level data (revenue
* and costs), it tends to be a more neutral and representative deflator than CPI.
*
* Formula for real values:
* Real Value (2018 prices) = Nominal Value × (Deflator_2018 / Deflator_2021)

********************************************************************************
* PART 1: PREPARE 2018 DATA - Rename all variables with _2018 suffix
********************************************************************************

di as text _n "=============================================="
di as text "STEP 1: Preparing 2018 data"
di as text "=============================================="

use "${intermediate}/BEN_2018_cleaned.dta", clear

* ----- Identification variables: keep as-is for merging -----
* grappe, menage, numind will be used as merge keys

* ----- Create hhid consistently -----
capture drop hhid
gen long hhid = grappe * 1000 + menage
label variable hhid "Household ID (grappe*1000 + menage)"

* ----- Variables already suffixed with _2018 in cleaning do-file -----
* sexe_2018, age_2018, educ_hi_2018, alfab_2018, educ_scol_2018
* activ7j_2018, hcsp_2018, hhweight_2018, ethnie_2018

* ----- Rename non-suffixed variables to add _2018 -----

* Enterprise indicators
capture rename ent_2018 ent_2018  // already named

* Individual characteristics
rename zae zae_2018
rename milieu milieu_2018
capture rename lien lien_2018

* Enterprise variables (only exist for entrepreneurs)
foreach v in proprietor_id nonag_id is_proprietor {
    capture rename `v' `v'_2018
}

* Enterprise performance
foreach v in revenue expenses profit value_total value_machines ///
    value_vehicles value_furniture value_other owns_assets ///
    val_hired_labor max_rev_by_owner {
    capture rename `v' `v'_2018
}

* Enterprise characteristics
foreach v in num_emp num_emp_tot num_emp_child ent_child_emp ///
    num_hhemp hires_nonhh_workers num_hhemp_cat ///
    no_wages_paid place financing year_est ///
    firm_keeps_accounts firm_has_fisc_id ///
    firm_in_trade_register firm_cnps_registered ///
    legal_form cooperative is_highest_revenue sector ///
    share_revenue_resale share_revenue_processed share_revenue_services ///
    N_enterprises_hh multiple_enterprises {
    capture rename `v' `v'_2018
}

* Problem variables
foreach letter in a b c d e f g h i j k l m n o {
    capture rename s10q45`letter' s10q45`letter'_2018
}

* Employment variables
foreach v in employed unemployed in_labor_force working_age ///
    sector_work emp_type formal public_employer ///
    days_worked_month hours_worked_day hours_worked_month months_worked ///
    salary_month bonus_month benefits_inkind_month food_value_month ///
    total_comp_month has_secondary_job ///
    days_worked_month_sec hours_worked_day_sec hours_worked_month_sec ///
    salary_month_sec bonus_month_sec benefits_inkind_month_sec ///
    food_value_month_sec total_comp_month_sec total_emp_income_month {
    capture rename `v' `v'_2018
}

* Section 4 raw variables (keep for reference)
foreach v of varlist s04q* {
    capture rename `v' `v'_2018
}

* Household head variables
foreach v in hgender hage hmstat hreligion hnation halfab ///
    heduc hdiploma hhandig hactiv7j hactiv12m hbranch hsectins hcsp {
    capture rename `v' `v'_2018
}

* Household characteristics
foreach v in hhweight hhsize eqadu1 eqadu2 region ///
    logem mur toit sol ///
    eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
    ordure toilet eva_toi eva_eau ///
    tv fer frigo cuisin ordin decod car superf ///
    grosrum petitrum porc lapin volail ///
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth {
    capture rename `v' `v'_2018
}

* Rename household electricity to has_electricity
capture rename elec_ac_2018 has_electricity_2018

* Welfare variables
foreach v in dali dnal dtot pcexp zzae zref def_spa def_temp {
    capture rename `v' `v'_2018
}

* Credit variables
* NOTE: BEN uses ind_got_credit/hh_got_credit (not ind_has_loan/hh_has_loan as in SEN)
foreach v in ind_got_credit ind_credit_source ind_credit_amount ///
    ind_has_outstanding ind_num_outstanding ///
    hh_got_credit hh_num_with_credit hh_main_credit_source ///
    hh_total_credit_amount hh_has_outstanding hh_total_outstanding ///
    hh_formal_credit hh_informal_credit ///
    hh_credit_bank hh_credit_mfi hh_credit_coop hh_credit_tontine {
    capture rename `v' `v'_2018
}

* Remittance variables
foreach v in hh_remit_total_annual hh_remit_from_abroad hh_received_remittances {
    capture rename `v' `v'_2018
}

* Bank account variable
capture rename has_bank has_bank_2018

* Location classification
capture rename location location_2018

* Credit section raw variables
foreach v of varlist s06q* {
    capture rename `v' `v'_2018
}

* Section 10 raw variables (enterprise detail)
foreach v of varlist s10q* {
    capture rename `v' `v'_2018
}

* Internet access: has_internet_2018 already created from ehcvm_individu in 03_clean_2018_BEN.do
capture rename has_internet has_internet_2018

drop if missing(grappe) | missing(menage) | missing(numind)

* Keep track of which year
gen byte in_2018 = 1
label variable in_2018 "Individual observed in 2018"

* Household head dummy (based on relationship to head variable, lien == 1)
gen byte is_hh_head_2018 = (lien_2018 == 1)
label variable is_hh_head_2018 "Is household head in 2018"

* Enterprise household dummy
bysort hhid: egen byte hh_has_enterprise_2018 = max(ent_2018)
label variable hh_has_enterprise_2018 "Household has at least one enterprise in 2018"

* ----- Merge enterprise screening data for enterprise-type dummies -----
* Source: s10_1_me_ben2018 (HH-level screening: s10q02-s10q10)
preserve
    use "${data_2018}/s10_1_me_ben2018.dta", clear
    * Create enterprise-type dummies from screening questions
    * s10q02=food, s10q03=confection, s10q04=construction, s10q05=commerce,
    * s10q06=liberal profession, s10q07=services, s10q08=restaurant,
    * s10q09=rental, s10q10=other non-agricultural
    foreach v in s10q02 s10q03 s10q04 s10q05 s10q06 s10q07 s10q08 s10q09 s10q10 {
        replace `v' = 0 if `v' != 1
    }
    rename s10q02 ent_food_2018
    rename s10q03 ent_confection_2018
    rename s10q04 ent_construct_2018
    rename s10q05 ent_commerce_2018
    rename s10q06 ent_liberal_2018
    rename s10q07 ent_services_2018
    rename s10q08 ent_restaurant_2018
    rename s10q09 ent_rental_2018
    rename s10q10 ent_other_2018
    keep grappe menage ent_food_2018 ent_confection_2018 ent_construct_2018 ///
        ent_commerce_2018 ent_liberal_2018 ent_services_2018 ///
        ent_restaurant_2018 ent_rental_2018 ent_other_2018
    duplicates drop grappe menage, force
    tempfile ent_screen_2018
    save `ent_screen_2018'
restore

merge m:1 grappe menage using `ent_screen_2018', nogen keep(master match)

* Fill enterprise type dummies for HHs with no enterprise
foreach v in ent_food_2018 ent_confection_2018 ent_construct_2018 ///
    ent_commerce_2018 ent_liberal_2018 ent_services_2018 ///
    ent_restaurant_2018 ent_rental_2018 ent_other_2018 {
    replace `v' = 0 if missing(`v')
    label variable `v' "HH has enterprise: `: variable label `v''"
}

tempfile data_2018
save `data_2018'

di as result "2018 data prepared: `=_N' observations"

********************************************************************************
* PART 2: PREPARE 2021 DATA - Rename all variables with _2021 suffix
********************************************************************************

di as text _n "=============================================="
di as text "STEP 2: Preparing 2021 data"
di as text "=============================================="

use "${intermediate}/BEN_2021_cleaned.dta", clear

* ----- Create hhid consistently -----
capture drop hhid
capture drop hhid1
gen long hhid = grappe * 1000 + menage
label variable hhid "Household ID (grappe*1000 + menage)"

* ----- Variables already suffixed with _2021 in cleaning do-file -----
* sexe_2021, age_2021, educ_hi_2021, alfab_2021, educ_scol_2021
* activ7j_2021, hcsp_2021, hhweight_2021, ethnie_2021

* ----- Rename non-suffixed variables to add _2021 -----

* Enterprise indicators
capture rename ent_2021 ent_2021  // already named

* Individual characteristics
rename zae zae_2021
rename milieu milieu_2021
capture rename lien lien_2021

* Enterprise variables
foreach v in proprietor_id nonag_id is_proprietor {
    capture rename `v' `v'_2021
}

* Enterprise performance
foreach v in revenue expenses profit value_total value_machines ///
    value_vehicles value_furniture value_other owns_assets ///
    val_hired_labor max_rev_by_owner {
    capture rename `v' `v'_2021
}

* Enterprise characteristics
foreach v in num_emp num_emp_tot num_emp_child ent_child_emp ///
    num_hhemp hires_nonhh_workers num_hhemp_cat ///
    no_wages_paid place financing year_est ///
    firm_keeps_accounts firm_has_fisc_id ///
    firm_in_trade_register firm_cnps_registered ///
    legal_form cooperative is_highest_revenue sector ///
    share_revenue_resale share_revenue_processed share_revenue_services ///
    N_enterprises_hh multiple_enterprises ///
    labor_affected_covid {
    capture rename `v' `v'_2021
}

* Problem variables
foreach letter in a b c d e f g h i j k l m n o {
    capture rename s10q45`letter' s10q45`letter'_2021
}

* Employment variables
foreach v in employed unemployed in_labor_force working_age ///
    sector_work emp_type formal public_employer ///
    days_worked_month hours_worked_day hours_worked_month months_worked ///
    salary_month bonus_month benefits_inkind_month food_value_month ///
    total_comp_month has_secondary_job ///
    days_worked_month_sec hours_worked_day_sec hours_worked_month_sec ///
    salary_month_sec bonus_month_sec benefits_inkind_month_sec ///
    food_value_month_sec total_comp_month_sec total_emp_income_month {
    capture rename `v' `v'_2021
}

* Section 4 raw variables
foreach v of varlist s04q* {
    capture rename `v' `v'_2021
}

* Household head variables
foreach v in hgender hage hmstat hreligion hnation ///
    heduc hdiploma hhandig hactiv7j hactiv12m hbranch hsectins hcsp {
    capture rename `v' `v'_2021
}
* 2021 may have additional HH head variable names
capture rename halfa halfa_2021
capture rename halfa2 halfa2_2021
capture rename hethnie hethnie_2021
capture rename halfab halfab_2021

* Location classification
capture rename location location_2021

* Household characteristics
foreach v in hhweight hhsize eqadu1 eqadu2 month ///
    logem mur toit sol ///
    eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
    ordure toilet eva_toi eva_eau ///
    tv fer frigo cuisin ordin decod car superf ///
    grosrum petitrum porc lapin volail ///
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth {
    capture rename `v' `v'_2021
}

* Rename household electricity to has_electricity
capture rename elec_ac_2021 has_electricity_2021

* NOTE: BEN 2021 uses departement (not region) — from welfare file
* Renamed to departement_2021 for clarity
capture rename departement departement_2021

* Welfare variables
foreach v in dali dnal dtot pcexp zzae zref def_spa def_temp ///
    def_temp_prix2021m11 def_temp_cpi def_temp_adj ///
    zali0 dtet monthly_cpi cpi2017 icp2017 dollars {
    capture rename `v' `v'_2021
}

* Credit variables
* NOTE: BEN uses ind_got_credit/hh_got_credit (not ind_has_loan/hh_has_loan as in SEN)
foreach v in ind_got_credit ind_credit_source ind_credit_amount ///
    ind_has_outstanding ind_num_outstanding ///
    hh_got_credit hh_num_with_credit hh_main_credit_source ///
    hh_total_credit_amount hh_has_outstanding hh_total_outstanding ///
    hh_formal_credit hh_informal_credit ///
    hh_credit_bank hh_credit_mfi hh_credit_coop hh_credit_tontine {
    capture rename `v' `v'_2021
}

* Remittance variables
foreach v in hh_remit_total_annual hh_remit_from_abroad hh_received_remittances {
    capture rename `v' `v'_2021
}

* Bank account variable
capture rename has_bank has_bank_2021

* Credit section raw variables
foreach v of varlist s06q* {
    capture rename `v' `v'_2021
}

* Section 10 raw variables
foreach v of varlist s10q* {
    capture rename `v' `v'_2021
}

* Internet access: has_internet_2021 already created from ehcvm_individu in 04_clean_2021_BEN.do
capture rename has_internet has_internet_2021

* Country and year
capture drop year
capture drop vague

drop if missing(grappe) | missing(menage) | missing(numind)

* Keep track of which year
gen byte in_2021 = 1
label variable in_2021 "Individual observed in 2021"

* Household head dummy (based on relationship to head variable, lien == 1)
gen byte is_hh_head_2021 = (lien_2021 == 1)
label variable is_hh_head_2021 "Is household head in 2021"

* Enterprise household dummy
bysort hhid: egen byte hh_has_enterprise_2021 = max(ent_2021)
label variable hh_has_enterprise_2021 "Household has at least one enterprise in 2021"

* ----- Merge enterprise screening data for enterprise-type dummies -----
* Source: s10a_me_ben2021 (HH-level screening: s10q02-s10q10)
preserve
    use "${data_2021}/s10a_me_ben2021.dta", clear
    foreach v in s10q02 s10q03 s10q04 s10q05 s10q06 s10q07 s10q08 s10q09 s10q10 {
        replace `v' = 0 if `v' != 1
    }
    rename s10q02 ent_food_2021
    rename s10q03 ent_confection_2021
    rename s10q04 ent_construct_2021
    rename s10q05 ent_commerce_2021
    rename s10q06 ent_liberal_2021
    rename s10q07 ent_services_2021
    rename s10q08 ent_restaurant_2021
    rename s10q09 ent_rental_2021
    rename s10q10 ent_other_2021
    keep grappe menage ent_food_2021 ent_confection_2021 ent_construct_2021 ///
        ent_commerce_2021 ent_liberal_2021 ent_services_2021 ///
        ent_restaurant_2021 ent_rental_2021 ent_other_2021
    duplicates drop grappe menage, force
    tempfile ent_screen_2021
    save `ent_screen_2021'
restore

merge m:1 grappe menage using `ent_screen_2021', nogen keep(master match)

foreach v in ent_food_2021 ent_confection_2021 ent_construct_2021 ///
    ent_commerce_2021 ent_liberal_2021 ent_services_2021 ///
    ent_restaurant_2021 ent_rental_2021 ent_other_2021 {
    replace `v' = 0 if missing(`v')
    label variable `v' "HH has enterprise: `: variable label `v''"
}

tempfile data_2021
save `data_2021'

di as result "2021 data prepared: `=_N' observations"

********************************************************************************
* PART 3: MERGE 2018 AND 2021 INTO PANEL
********************************************************************************

di as text _n "=============================================="
di as text "STEP 3: Merging into panel"
di as text "=============================================="

* Merge on grappe + menage + numind (individual-level panel)
use `data_2018', clear
merge 1:1 grappe menage numind using `data_2021'

* Document merge results
tab _merge

* ----- Create match indicators -----

* Household-level match: HH appears in both waves
gen byte hh_matched = 0
label variable hh_matched "Household matched across 2018 and 2021"

* An HH is matched if at least one individual from that HH appears in both waves
bysort hhid: egen has_2018 = max(in_2018)
bysort hhid: egen has_2021 = max(in_2021)
replace hh_matched = 1 if has_2018 == 1 & has_2021 == 1
drop has_2018 has_2021

label define hh_matched 0 "Not matched" 1 "Matched across waves"
label values hh_matched hh_matched

* Individual-level match: same person in both waves
gen byte ind_matched = (_merge == 3)
label variable ind_matched "Individual matched across 2018 and 2021"
label define ind_matched 0 "Not matched" 1 "Matched across waves"
label values ind_matched ind_matched

* ----- Validate individual match with gender and age checks -----

* Gender consistency check (same person should have same gender)
gen byte gender_consistent = .
replace gender_consistent = 1 if ind_matched == 1 & sexe_2018 == sexe_2021
replace gender_consistent = 0 if ind_matched == 1 & sexe_2018 != sexe_2021
label variable gender_consistent "Gender matches across waves (quality check)"

* Age consistency check: age in 2021 should be ~3 years more than 2018
gen age_diff = age_2021 - age_2018 if ind_matched == 1
gen byte age_consistent = .
replace age_consistent = 1 if ind_matched == 1 & inrange(age_diff, 1, 5)
replace age_consistent = 0 if ind_matched == 1 & !inrange(age_diff, 1, 5)
label variable age_consistent "Age difference 1-5 years across waves (quality check)"
label variable age_diff "Age difference (2021 - 2018)"

* Validated individual match: matched AND passes gender + age checks
gen byte ind_validated = 0
replace ind_validated = 1 if ind_matched == 1 & gender_consistent == 1 & age_consistent == 1
label variable ind_validated "Individual validated match (ID + gender + age consistent)"
label define ind_validated 0 "Not validated" 1 "Validated match"
label values ind_validated ind_validated

* Fill in missing year indicators
replace in_2018 = 0 if missing(in_2018)
replace in_2021 = 0 if missing(in_2021)

* Clean up merge variable
drop _merge

di as result "Panel merge complete"
tab hh_matched
tab ind_matched
tab ind_validated

********************************************************************************
* PART 4: CREATE ANALYSIS VARIABLES - DEMOGRAPHICS
********************************************************************************

di as text _n "=============================================="
di as text "STEP 4: Creating analysis variables"
di as text "=============================================="

*------------------------------------------------------------------------------
* 4.1: Age categories (for each year)
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    recode age_`yr' ///
        (15/29 = 1 "15-29") ///
        (30/44 = 2 "30-44") ///
        (45/64 = 3 "45-64") ///
        (65/max = 4 "65+") ///
        (min/14 = .), ///
        gen(age_cat_`yr')
    label variable age_cat_`yr' "Age category (`yr')"
}

*------------------------------------------------------------------------------
* 4.2: Urban/rural dummy (rural=1)
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen byte rural_`yr' = .
    * milieu: 1=Urban, 2=Rural (standard EHCVM coding)
    replace rural_`yr' = 0 if milieu_`yr' == 1
    replace rural_`yr' = 1 if milieu_`yr' == 2
    label variable rural_`yr' "Rural area (`yr')"
    label define rural_`yr' 0 "Urban" 1 "Rural"
    label values rural_`yr' rural_`yr'
}

*------------------------------------------------------------------------------
* 4.3: Education categories
*------------------------------------------------------------------------------

* educ_hi codes: 1=Aucun 2=Maternelle 3=Primaire
* 4=Second.gl1 5=Second.tech1 6=Second.gl2 7=Second.tech2
* 8=Postsecondaire 9=Superieur

foreach yr in 2018 2021 {
    gen educ_cat_`yr' = .
    replace educ_cat_`yr' = 1 if educ_hi_`yr' == 1              // No education
    replace educ_cat_`yr' = 2 if educ_hi_`yr' == 2              // Less than primary
    replace educ_cat_`yr' = 3 if educ_hi_`yr' == 3              // Less than secondary
    replace educ_cat_`yr' = 4 if inrange(educ_hi_`yr', 4, 9)   // Secondary and higher

    label variable educ_cat_`yr' "Education category (`yr')"
    label define educ_cat_`yr' 1 "No education" 2 "Less than primary" 3 "Less than secondary" 4 "Secondary and higher"
    label values educ_cat_`yr' educ_cat_`yr'
}

*------------------------------------------------------------------------------
* 4.4: Type of activity
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen activity_type_`yr' = .
    * emp_type codes: 1=Paid work, 2=Unpaid work, 3=Unpaid family worker,
    *                 4=Own account worker, 5=Employer
    replace activity_type_`yr' = 1 if ent_`yr' == 1 & in_`yr' == 1
    replace activity_type_`yr' = 2 if employed_`yr' == 1 & ent_`yr' != 1 & ///
        inlist(emp_type_`yr', 1, 5) & in_`yr' == 1  // paid workers and employers
    replace activity_type_`yr' = 3 if employed_`yr' == 1 & ent_`yr' != 1 & ///
        inlist(emp_type_`yr', 2, 3) & in_`yr' == 1  // unpaid work and unpaid family workers
    replace activity_type_`yr' = 4 if employed_`yr' != 1 & ent_`yr' != 1 & in_`yr' == 1

    label variable activity_type_`yr' "Type of activity (`yr')"
    label define activity_type_`yr' ///
        1 "Entrepreneur" ///
        2 "Wage job" ///
        3 "Non-wage job" ///
        4 "Not working"
    label values activity_type_`yr' activity_type_`yr'
}

*------------------------------------------------------------------------------
* 4.5: Wage job sub-categories
*------------------------------------------------------------------------------

* formal_YYYY: from s04q38 (contributes to FNRB/CNSS in Benin)
* public_employer_YYYY: from s04q31 (principal employer)
* These are renamed with year suffixes in Parts 1 and 2 above.

********************************************************************************
* PART 5: CREATE ANALYSIS VARIABLES - LEVEL OF ANALYSIS INDICATORS
********************************************************************************

*------------------------------------------------------------------------------
* 5.1: Individual-level entrepreneur dummy
*------------------------------------------------------------------------------

gen byte is_entrepreneur = (ent_2018 == 1 | ent_2021 == 1)
label variable is_entrepreneur "Is entrepreneur in at least one wave"
label define is_entrepreneur 0 "Not an entrepreneur" 1 "Entrepreneur"
label values is_entrepreneur is_entrepreneur

tab is_entrepreneur, mi

*------------------------------------------------------------------------------
* 5.2: Entrepreneur status across waves (4 categories)
*------------------------------------------------------------------------------

gen byte ent_status = 1
replace ent_status = 2 if ent_2018 == 1 & ent_2021 != 1
replace ent_status = 3 if ent_2018 != 1 & ent_2021 == 1
replace ent_status = 4 if ent_2018 == 1 & ent_2021 == 1

label variable ent_status "Entrepreneur status across waves"
label define ent_status ///
    1 "Not entrepreneur in either wave" ///
    2 "Entrepreneur in 2018 only" ///
    3 "Entrepreneur in 2021 only" ///
    4 "Entrepreneur in both waves"
label values ent_status ent_status

tab ent_status, mi

*------------------------------------------------------------------------------
* 5.3: Household has enterprise dummy
*------------------------------------------------------------------------------

bysort hhid: egen byte hh_has_enterprise = max(is_entrepreneur)
label variable hh_has_enterprise "Household has an entrepreneur in at least one wave"
label define hh_has_enterprise 0 "No enterprise in HH" 1 "HH has enterprise"
label values hh_has_enterprise hh_has_enterprise

tab hh_has_enterprise, mi

********************************************************************************
* PART 5b: TRANSITION INDICATORS
********************************************************************************

*------------------------------------------------------------------------------
* 5b.1: Entrepreneurship transition (4 categories, panel individuals only)
*------------------------------------------------------------------------------

gen ent_transition = . if ind_matched == 1
replace ent_transition = 1 if ent_2018 == 0 & ent_2021 == 0 & ind_matched == 1
replace ent_transition = 2 if ent_2018 == 0 & ent_2021 == 1 & ind_matched == 1
replace ent_transition = 3 if ent_2018 == 1 & ent_2021 == 0 & ind_matched == 1
replace ent_transition = 4 if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1

label variable ent_transition "Entrepreneurship transition 2018-2021"
label define ent_transition ///
    1 "Not entrepreneur in either year" ///
    2 "Entered entrepreneurship in 2021" ///
    3 "Exited entrepreneurship in 2021" ///
    4 "Remained entrepreneur"
label values ent_transition ent_transition

*------------------------------------------------------------------------------
* 5b.2: Entry source for 2021 entrepreneurs (4 categories)
*------------------------------------------------------------------------------

gen ent_entry_source = . if ent_2021 == 1 & ind_matched == 1
replace ent_entry_source = 1 if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
replace ent_entry_source = 2 if ent_2018 != 1 & ent_2021 == 1 & ///
    activity_type_2018 == 2 & ind_matched == 1
replace ent_entry_source = 3 if ent_2018 != 1 & ent_2021 == 1 & ///
    activity_type_2018 == 3 & ind_matched == 1
replace ent_entry_source = 4 if ent_2018 != 1 & ent_2021 == 1 & ///
    activity_type_2018 == 4 & ind_matched == 1

label variable ent_entry_source "Source of entry into entrepreneurship in 2021"
label define ent_entry_source ///
    1 "Was entrepreneur in 2018" ///
    2 "Entered from wage job" ///
    3 "Entered from non-wage job" ///
    4 "Entered from non-work"
label values ent_entry_source ent_entry_source

*------------------------------------------------------------------------------
* 5b.3: Exit dummy
*------------------------------------------------------------------------------

gen byte ent_exited = .
replace ent_exited = 1 if ent_2018 == 1 & ent_2021 != 1 & ind_matched == 1
replace ent_exited = 0 if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable ent_exited "Exited entrepreneurship between 2018 and 2021"
label define ent_exited 0 "Remained entrepreneur" 1 "Exited"
label values ent_exited ent_exited

********************************************************************************
* PART 6: CREATE ANALYSIS VARIABLES - HOUSEHOLD HEAD INDICATORS
********************************************************************************

*------------------------------------------------------------------------------
* 6.1: Household head characteristics (from welfare data)
*------------------------------------------------------------------------------

* hgender_YYYY, hage_YYYY, heduc_YYYY already in data from menage merge

foreach yr in 2018 2021 {
    * HH head age categories
    capture drop hage_cat_`yr'
    gen hage_cat_`yr' = .
    replace hage_cat_`yr' = 1 if hage_`yr' >= 15 & hage_`yr' <= 29
    replace hage_cat_`yr' = 2 if hage_`yr' >= 30 & hage_`yr' <= 44
    replace hage_cat_`yr' = 3 if hage_`yr' >= 45 & hage_`yr' <= 64
    replace hage_cat_`yr' = 4 if hage_`yr' >= 65 & hage_`yr' < .
    label variable hage_cat_`yr' "HH head age category (`yr')"
    label define hage_cat_`yr' 1 "15-29" 2 "30-44" 3 "45-64" 4 "65+"
    label values hage_cat_`yr' hage_cat_`yr'

    * HH head education category (same codes as educ_hi)
    gen heduc_cat_`yr' = .
    replace heduc_cat_`yr' = 1 if heduc_`yr' == 1              // No education
    replace heduc_cat_`yr' = 2 if heduc_`yr' == 2              // Less than primary
    replace heduc_cat_`yr' = 3 if heduc_`yr' == 3              // Less than secondary
    replace heduc_cat_`yr' = 4 if inrange(heduc_`yr', 4, 9)   // Secondary and higher

    label variable heduc_cat_`yr' "HH head education category (`yr')"
    label define heduc_cat_`yr' 1 "No education" 2 "Less than primary" 3 "Less than secondary" 4 "Secondary and higher"
    label values heduc_cat_`yr' heduc_cat_`yr'
}

*------------------------------------------------------------------------------
* 6.2: HH head is NOT the entrepreneur
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen byte head_not_ent_`yr' = (is_hh_head_`yr' == 1 & ent_`yr' != 1)
    label variable head_not_ent_`yr' "HH head is not the entrepreneur (`yr')"
}

*------------------------------------------------------------------------------
* 6.3: Share of HH members in wage jobs
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen byte has_wage_job_`yr' = (activity_type_`yr' == 2)
    bysort hhid: egen n_wage_`yr' = total(has_wage_job_`yr')
    bysort hhid: egen n_employed_`yr' = total(employed_`yr' == 1)
    gen share_wage_hh_`yr' = n_wage_`yr' / n_employed_`yr' if n_employed_`yr' > 0
    label variable share_wage_hh_`yr' "Share of employed HH members with wage job (`yr')"
    drop has_wage_job_`yr' n_wage_`yr' n_employed_`yr'
}

********************************************************************************
* PART 7: CREATE ANALYSIS VARIABLES - ENTERPRISE PERFORMANCE
********************************************************************************

*------------------------------------------------------------------------------
* 7.1: GDP deflator-adjusted profits and capital (real 2018 prices)
*------------------------------------------------------------------------------

* Benin GDP deflators: 101 (2018), 105.2 (2021) — set in Part 0

foreach yr in 2018 2021 {
    gen profit_real_`yr' = profit_`yr' * (${gdpdef_2018} / ${gdpdef_`yr'}) if ent_`yr' == 1
    label variable profit_real_`yr' "Monthly profit in real 2018 prices (`yr')"

    gen value_total_real_`yr' = value_total_`yr' * (${gdpdef_2018} / ${gdpdef_`yr'}) if ent_`yr' == 1
    label variable value_total_real_`yr' "Capital value in real 2018 prices (`yr')"
}

*------------------------------------------------------------------------------
* 7.2: Log transformations
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen log_profit_`yr' = ln(profit_`yr') if profit_`yr' > 0 & ent_`yr' == 1
    label variable log_profit_`yr' "Log of monthly profit (`yr')"

    gen log_capital_`yr' = ln(value_total_`yr') if value_total_`yr' > 0 & ent_`yr' == 1
    label variable log_capital_`yr' "Log of capital value (`yr')"
}

*------------------------------------------------------------------------------
* 7.3: Changes between years (panel enterprises only)
*------------------------------------------------------------------------------

gen change_profit_real = profit_real_2021 - profit_real_2018 ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable change_profit_real "Change in real profit (2021 - 2018)"

gen change_capital_real = value_total_real_2021 - value_total_real_2018 ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable change_capital_real "Change in real capital value (2021 - 2018)"

gen change_num_emp = num_emp_2021 - num_emp_2018 ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable change_num_emp "Change in non-family employees (2021 - 2018)"

gen change_num_hhemp = num_hhemp_2021 - num_hhemp_2018 ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable change_num_hhemp "Change in family employees (2021 - 2018)"

gen growth_profit = .
replace growth_profit = ((profit_real_2021 / profit_real_2018) - 1) ///
    if profit_real_2018 > 0 & profit_real_2021 > 0 & ///
    ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1
label variable growth_profit "Annual growth rate of real profits"

gen byte profit_increased = (change_profit_real > 0) ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1 & !missing(change_profit_real)
label variable profit_increased "Enterprise increased real profits 2018-2021"

gen byte capital_increased = (change_capital_real > 0) ///
    if ent_2018 == 1 & ent_2021 == 1 & ind_matched == 1 & !missing(change_capital_real)
label variable capital_increased "Enterprise increased real capital 2018-2021"

*------------------------------------------------------------------------------
* 7.4: Profit categories
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen profit_cat_`yr' = .
    replace profit_cat_`yr' = 1 if profit_`yr' < 0 & ent_`yr' == 1
    replace profit_cat_`yr' = 2 if profit_`yr' == 0 & ent_`yr' == 1
    replace profit_cat_`yr' = 3 if profit_`yr' > 0 & profit_`yr' < . & ent_`yr' == 1
    label variable profit_cat_`yr' "Profit category (`yr')"
    label define profit_cat_`yr' 1 "Negative/loss" 2 "Zero" 3 "Positive"
    label values profit_cat_`yr' profit_cat_`yr'
}

*------------------------------------------------------------------------------
* 7.5: Formality indicators
*------------------------------------------------------------------------------

* firm_keeps_accounts_YYYY, firm_has_fisc_id_YYYY, firm_in_trade_register_YYYY
* already renamed with year suffixes in Parts 1 and 2.
* formal_YYYY (FNRB/CNSS pension contribution) available for wage workers.

*------------------------------------------------------------------------------
* 7.6: Firm age categories
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    local survey_year = `yr'
    gen firm_age_`yr' = `survey_year' - year_est_`yr' if ent_`yr' == 1
    label variable firm_age_`yr' "Firm age in years (`yr')"

    recode year_est_`yr' ///
        (min/1999 = 1 "Before 2000") ///
        (2000/2009 = 2 "2000-2009") ///
        (2010/2014 = 3 "2010-2014") ///
        (2015/2021 = 4 "2015+"), ///
        gen(year_est_cat_`yr')
    label variable year_est_cat_`yr' "Year established category (`yr')"
}

*------------------------------------------------------------------------------
* 7.7: Value added per worker
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    * Total workers = proprietor (1) + family workers + non-family workers
    gen total_workers_`yr' = 1 + num_hhemp_`yr' + num_emp_`yr' if ent_`yr' == 1
    replace total_workers_`yr' = 1 if total_workers_`yr' == 0 & ent_`yr' == 1

    * Value added = revenue - expenses + wages (wages added back since in expenses)
    gen value_added_`yr' = revenue_`yr' - expenses_`yr' + val_hired_labor_`yr' if ent_`yr' == 1
    replace value_added_`yr' = revenue_`yr' - expenses_`yr' if missing(val_hired_labor_`yr') & ent_`yr' == 1
    label variable value_added_`yr' "Value added (`yr')"

    gen va_per_worker_`yr' = value_added_`yr' / total_workers_`yr' if ent_`yr' == 1
    label variable va_per_worker_`yr' "Value added per worker (`yr')"
}

*------------------------------------------------------------------------------
* 7.8: Total employees (family + non-family)
*------------------------------------------------------------------------------

foreach yr in 2018 2021 {
    gen total_emp_`yr' = num_hhemp_`yr' + num_emp_`yr' if ent_`yr' == 1
    replace total_emp_`yr' = num_hhemp_`yr' if missing(num_emp_`yr') & ent_`yr' == 1
    label variable total_emp_`yr' "Total employees, family + non-family (`yr')"
}
