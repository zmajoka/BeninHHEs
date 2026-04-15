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
