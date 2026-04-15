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
