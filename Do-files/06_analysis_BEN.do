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
