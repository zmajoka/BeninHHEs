********************************************************************************
* EHCVM BENIN - EXTRACT VARIABLE CODEBOOK TO EXCEL
********************************************************************************
* Purpose: Extract variable metadata (names, types, labels, value labels)
*          from all raw datasets for Benin 2018 and 2021 and export to Excel.
*          Each dataset gets its own tab in the output Excel file.
*
* Date:    April 2026
*
* OUTPUT:  ${output}/BEN_codebook_2018.xlsx
*          ${output}/BEN_codebook_2021.xlsx
*
* INSTRUCTIONS:
*   1. Set your project path in PART 0 below
*   2. Run this entire do-file in Stata
*   3. Each output Excel file will have one tab per dataset,
*      named after the dataset (e.g. "s01_me_ben2018")
*
* NOTE: This do-file only READS data — it does not modify any files.
********************************************************************************

clear all
set more off

********************************************************************************
* PART 0: SET PATHS
********************************************************************************

* Main project directory — UPDATE THIS TO MATCH YOUR SETUP
global project "C:\Users\WB461621\OneDrive - WBG\SPJ\West Africa\Regional HH Enterprise Work"

* Data directories
global data_2018     "${project}/Data/BEN/2018"
global data_2021     "${project}/Data/BEN/2021"
global output        "${project}/Output/BEN"

* Create output directory if needed
capture mkdir "${output}"

********************************************************************************
* PROGRAM: EXTRACT CODEBOOK FROM A SINGLE DATASET
********************************************************************************
* Loads a dataset, extracts all variable metadata, and writes it to its own
* sheet in the output Excel file (one sheet per dataset).
*
* Arguments:
*   1 = full file path to dataset (without .dta)
*   2 = dataset short name — also used as the Excel sheet name
*   3 = questionnaire section label
*   4 = full path to output Excel file

capture program drop extract_codebook
program define extract_codebook
    args filepath dataname section excelfile

    di as text _n "=============================================="
    di as text "Processing: `dataname'"
    di as text "=============================================="

    * Load the dataset
    capture use "`filepath'", clear
    if _rc != 0 {
        di as error "WARNING: Could not load `filepath' — skipping."
        exit
    }

    * Get number of variables
    qui describe, short
    local nvars = r(k)
    local nobs  = r(N)

    di as text "  Variables: `nvars'  |  Observations: `nobs'"

    *--------------------------------------------------------------------------
    * STEP 1: Extract variable-level metadata
    *--------------------------------------------------------------------------

    * Use numeric keys to avoid invalid macro names (e.g. vars with __ or .)
    local vnum = 0
    foreach v of varlist * {
        local ++vnum
        local vkey = "v`vnum'"
        local varkey_`vnum'  "`v'"
        local type_`vkey'   : type `v'
        local label_`vkey'  : variable label `v'
        local vallbl_`vkey' : value label `v'
    }
    local nvars_total = `vnum'

    *--------------------------------------------------------------------------
    * STEP 2: Build codebook dataset for this file and export to its own sheet
    *--------------------------------------------------------------------------

    clear
    qui set obs `nvars_total'

    gen str80  variable_name   = ""
    gen str40  section_name    = ""
    gen str20  type            = ""
    gen str244 label           = ""
    gen str244 value_labels    = ""
    gen str40  valid_range     = ""
    gen str80  skip_logic      = ""
    gen str80  missing_codes   = ""
    gen str244 notes           = ""

    forvalues i = 1/`nvars_total' {
        local v    "`varkey_`i''"
        local vkey "v`i'"

        qui replace variable_name = "`v'" in `i'
        qui replace section_name  = "`section'" in `i'
        qui replace type          = "`type_`vkey''" in `i'

        local clean_label = subinstr(`"`label_`vkey''"', char(34), "", .)
        qui replace label = `"`clean_label'"' in `i'

        if `"`vallbl_`vkey''"' != "" {
            qui replace value_labels = "`vallbl_`vkey''" in `i'
        }

        if inlist("`v'", "grappe", "menage", "hhid", "numind", "membres__id", "vague") {
            qui replace notes = "Identifier variable" in `i'
        }
    }

    * Excel sheet name: use dataname, truncated to 31 chars (Excel limit)
    local sheetname = substr("`dataname'", 1, 31)

    export excel using "`excelfile'", ///
        sheet("`sheetname'") sheetreplace firstrow(variables)

    di as text "  Sheet '`sheetname'' written to `excelfile'"
    di as text "  Variables exported: `nvars_total'"

end


********************************************************************************
* PART 1: EXTRACT CODEBOOK FOR 2018 DATASETS
********************************************************************************

di as text _n "***********************************************************"
di as text "EXTRACTING 2018 CODEBOOK"
di as text "***********************************************************"

local excel2018 "${output}/BEN_codebook_2018.xlsx"

* --- EHCVM Core datasets ---
extract_codebook "${data_2018}/ehcvm_conso_ben2018" ///
    "ehcvm_conso_ben2018" "EHCVM - Consumption" "`excel2018'"

extract_codebook "${data_2018}/ehcvm_individu_ben2018" ///
    "ehcvm_individu_ben2018" "EHCVM - Individual characteristics" "`excel2018'"

extract_codebook "${data_2018}/ehcvm_menage_ben2018" ///
    "ehcvm_menage_ben2018" "EHCVM - Household characteristics" "`excel2018'"

extract_codebook "${data_2018}/ehcvm_ponderations_ben2018" ///
    "ehcvm_ponderations_ben2018" "EHCVM - Weights" "`excel2018'"

extract_codebook "${data_2018}/ehcvm_welfare_ben2018" ///
    "ehcvm_welfare_ben2018" "EHCVM - Welfare/poverty" "`excel2018'"

extract_codebook "${data_2018}/grappe_gps_ben2018" ///
    "grappe_gps_ben2018" "GPS coordinates" "`excel2018'"

* --- Section 0: Cover page ---
extract_codebook "${data_2018}/s00_me_ben2018" ///
    "s00_me_ben2018" "Section 0 - Cover page (ME)" "`excel2018'"

extract_codebook "${data_2018}/s00a_co_ben2018" ///
    "s00a_co_ben2018" "Section 0a - Cover page (CO)" "`excel2018'"

extract_codebook "${data_2018}/s00b_co_ben2018" ///
    "s00b_co_ben2018" "Section 0b - Cover page (CO)" "`excel2018'"

* --- Section 1: Household roster ---
extract_codebook "${data_2018}/s01_co_ben2018" ///
    "s01_co_ben2018" "Section 1 - Household roster (CO)" "`excel2018'"

extract_codebook "${data_2018}/s01_me_ben2018" ///
    "s01_me_ben2018" "Section 1 - Household roster (ME)" "`excel2018'"

* --- Section 2 ---
extract_codebook "${data_2018}/s02_co_ben2018" ///
    "s02_co_ben2018" "Section 2 (CO)" "`excel2018'"

extract_codebook "${data_2018}/s02_me_ben2018" ///
    "s02_me_ben2018" "Section 2 (ME)" "`excel2018'"

* --- Section 3 ---
extract_codebook "${data_2018}/s03_co_ben2018" ///
    "s03_co_ben2018" "Section 3 (CO)" "`excel2018'"

extract_codebook "${data_2018}/s03_me_ben2018" ///
    "s03_me_ben2018" "Section 3 (ME)" "`excel2018'"

* --- Section 4: Employment ---
extract_codebook "${data_2018}/s04_co_ben2018" ///
    "s04_co_ben2018" "Section 4 - Employment (CO)" "`excel2018'"

extract_codebook "${data_2018}/s04_me_ben2018" ///
    "s04_me_ben2018" "Section 4 - Employment (ME)" "`excel2018'"

* --- Section 5 ---
extract_codebook "${data_2018}/s05_co_ben2018" ///
    "s05_co_ben2018" "Section 5 (CO)" "`excel2018'"

extract_codebook "${data_2018}/s05_me_ben2018" ///
    "s05_me_ben2018" "Section 5 (ME)" "`excel2018'"

* --- Section 6: Credit ---
extract_codebook "${data_2018}/s06_me_ben2018" ///
    "s06_me_ben2018" "Section 6 - Credit" "`excel2018'"

* --- Section 7 ---
extract_codebook "${data_2018}/s07a1_me_ben2018" ///
    "s07a1_me_ben2018" "Section 7a1" "`excel2018'"

extract_codebook "${data_2018}/s07a2_me_ben2018" ///
    "s07a2_me_ben2018" "Section 7a2" "`excel2018'"

extract_codebook "${data_2018}/s07b_me_ben2018" ///
    "s07b_me_ben2018" "Section 7b" "`excel2018'"

* --- Section 8 ---
extract_codebook "${data_2018}/s08a_me_ben2018" ///
    "s08a_me_ben2018" "Section 8a" "`excel2018'"

extract_codebook "${data_2018}/s08b1_me_ben2018" ///
    "s08b1_me_ben2018" "Section 8b1" "`excel2018'"

extract_codebook "${data_2018}/s08b2_me_ben2018" ///
    "s08b2_me_ben2018" "Section 8b2" "`excel2018'"

* --- Section 9 ---
extract_codebook "${data_2018}/s09a_me_ben2018" ///
    "s09a_me_ben2018" "Section 9a" "`excel2018'"

extract_codebook "${data_2018}/s09b_me_ben2018" ///
    "s09b_me_ben2018" "Section 9b" "`excel2018'"

extract_codebook "${data_2018}/s09c_me_ben2018" ///
    "s09c_me_ben2018" "Section 9c" "`excel2018'"

extract_codebook "${data_2018}/s09d_me_ben2018" ///
    "s09d_me_ben2018" "Section 9d" "`excel2018'"

extract_codebook "${data_2018}/s09e_me_ben2018" ///
    "s09e_me_ben2018" "Section 9e" "`excel2018'"

extract_codebook "${data_2018}/s09f_me_ben2018" ///
    "s09f_me_ben2018" "Section 9f" "`excel2018'"

* --- Section 10: Enterprise ---
extract_codebook "${data_2018}/s10_1_me_ben2018" ///
    "s10_1_me_ben2018" "Section 10 - Enterprise (part 1)" "`excel2018'"

extract_codebook "${data_2018}/s10_2_me_ben2018" ///
    "s10_2_me_ben2018" "Section 10 - Enterprise (part 2)" "`excel2018'"

* --- Section 11 ---
extract_codebook "${data_2018}/s11_me_ben2018" ///
    "s11_me_ben2018" "Section 11" "`excel2018'"

* --- Section 12 ---
extract_codebook "${data_2018}/s12_me_ben2018" ///
    "s12_me_ben2018" "Section 12" "`excel2018'"

* --- Section 13: Remittances ---
extract_codebook "${data_2018}/s13a_1_me_ben2018" ///
    "s13a_1_me_ben2018" "Section 13a - Remittances (part 1)" "`excel2018'"

extract_codebook "${data_2018}/s13a_2_me_ben2018" ///
    "s13a_2_me_ben2018" "Section 13a - Remittances (part 2)" "`excel2018'"

extract_codebook "${data_2018}/s13b_1_me_ben2018" ///
    "s13b_1_me_ben2018" "Section 13b (part 1)" "`excel2018'"

extract_codebook "${data_2018}/s13b_2_me_ben2018" ///
    "s13b_2_me_ben2018" "Section 13b (part 2)" "`excel2018'"

* --- Section 14 ---
extract_codebook "${data_2018}/s14_me_ben2018" ///
    "s14_me_ben2018" "Section 14" "`excel2018'"

* --- Section 15 ---
extract_codebook "${data_2018}/s15_me_ben2018" ///
    "s15_me_ben2018" "Section 15" "`excel2018'"

* --- Section 16 ---
extract_codebook "${data_2018}/s16a_me_ben2018" ///
    "s16a_me_ben2018" "Section 16a" "`excel2018'"

extract_codebook "${data_2018}/s16b_me_ben2018" ///
    "s16b_me_ben2018" "Section 16b" "`excel2018'"

extract_codebook "${data_2018}/s16c_me_ben2018" ///
    "s16c_me_ben2018" "Section 16c" "`excel2018'"

* --- Section 17 ---
extract_codebook "${data_2018}/s17_me_ben2018" ///
    "s17_me_ben2018" "Section 17" "`excel2018'"

* --- Section 18 ---
extract_codebook "${data_2018}/s18_1_me_ben2018" ///
    "s18_1_me_ben2018" "Section 18 (part 1)" "`excel2018'"

extract_codebook "${data_2018}/s18_2_me_ben2018" ///
    "s18_2_me_ben2018" "Section 18 (part 2)" "`excel2018'"

extract_codebook "${data_2018}/s18_3_me_ben2018" ///
    "s18_3_me_ben2018" "Section 18 (part 3)" "`excel2018'"

extract_codebook "${data_2018}/s18_4_me_ben2018" ///
    "s18_4_me_ben2018" "Section 18 (part 4)" "`excel2018'"

* --- Section 19 ---
extract_codebook "${data_2018}/s19_me_ben2018" ///
    "s19_me_ben2018" "Section 19" "`excel2018'"

* --- Section 20 ---
extract_codebook "${data_2018}/s20_me_ben2018" ///
    "s20_me_ben2018" "Section 20" "`excel2018'"

di as result _n "2018 codebook saved to: ${output}/BEN_codebook_2018.xlsx"


********************************************************************************
* PART 2: EXTRACT CODEBOOK FOR 2021 DATASETS
********************************************************************************

di as text _n "***********************************************************"
di as text "EXTRACTING 2021 CODEBOOK"
di as text "***********************************************************"

local excel2021 "${output}/BEN_codebook_2021.xlsx"

* --- EHCVM Core datasets ---
extract_codebook "${data_2021}/calorie_conversion_wa_2021" ///
    "calorie_conversion_wa_2021" "EHCVM - Calorie conversion" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_conso_ben2021" ///
    "ehcvm_conso_ben2021" "EHCVM - Consumption" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_ihpc_ben2021" ///
    "ehcvm_ihpc_ben2021" "EHCVM - IHPC price index" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_individu_ben2021" ///
    "ehcvm_individu_ben2021" "EHCVM - Individual characteristics" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_menage_ben2021" ///
    "ehcvm_menage_ben2021" "EHCVM - Household characteristics" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_nsu_ben2021" ///
    "ehcvm_nsu_ben2021" "EHCVM - NSU" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_nsu_com_ben2021" ///
    "ehcvm_nsu_com_ben2021" "EHCVM - NSU commune" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_nsu_dep_ben2021" ///
    "ehcvm_nsu_dep_ben2021" "EHCVM - NSU department" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_nsu_nat_ben2021" ///
    "ehcvm_nsu_nat_ben2021" "EHCVM - NSU national" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_panier2018_code2021" ///
    "ehcvm_panier2018_code2021" "EHCVM - Basket 2018 codes (2021)" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_ponderations_ben2021" ///
    "ehcvm_ponderations_ben2021" "EHCVM - Weights" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_prix_ben2021" ///
    "ehcvm_prix_ben2021" "EHCVM - Prices" "`excel2021'"

extract_codebook "${data_2021}/ehcvm_welfare_ben2021" ///
    "ehcvm_welfare_ben2021" "EHCVM - Welfare/poverty" "`excel2021'"

* --- Section 0: Cover page ---
extract_codebook "${data_2021}/s00_co_ben2021" ///
    "s00_co_ben2021" "Section 0 - Cover page (CO)" "`excel2021'"

extract_codebook "${data_2021}/s00_me_ben2021" ///
    "s00_me_ben2021" "Section 0 - Cover page (ME)" "`excel2021'"

* --- Section 1: Household roster ---
extract_codebook "${data_2021}/s01_co_ben2021" ///
    "s01_co_ben2021" "Section 1 - Household roster (CO)" "`excel2021'"

extract_codebook "${data_2021}/s01_me_ben2021" ///
    "s01_me_ben2021" "Section 1 - Household roster (ME)" "`excel2021'"

* --- Section 2 ---
extract_codebook "${data_2021}/s02_co_ben2021" ///
    "s02_co_ben2021" "Section 2 (CO)" "`excel2021'"

extract_codebook "${data_2021}/s02_me_ben2021" ///
    "s02_me_ben2021" "Section 2 (ME)" "`excel2021'"

* --- Section 3 ---
extract_codebook "${data_2021}/s03_co_ben2021" ///
    "s03_co_ben2021" "Section 3 (CO)" "`excel2021'"

extract_codebook "${data_2021}/s03_me_ben2021" ///
    "s03_me_ben2021" "Section 3 (ME)" "`excel2021'"

* --- Section 4: Employment ---
extract_codebook "${data_2021}/s04_co_ben2021" ///
    "s04_co_ben2021" "Section 4 - Employment (CO)" "`excel2021'"

extract_codebook "${data_2021}/s04a_me_ben2021" ///
    "s04a_me_ben2021" "Section 4a - Employment status" "`excel2021'"

extract_codebook "${data_2021}/s04b_me_ben2021" ///
    "s04b_me_ben2021" "Section 4b - Primary job" "`excel2021'"

extract_codebook "${data_2021}/s04c_me_ben2021" ///
    "s04c_me_ben2021" "Section 4c - Secondary job" "`excel2021'"

* --- Section 5 ---
extract_codebook "${data_2021}/s05_me_ben2021" ///
    "s05_me_ben2021" "Section 5" "`excel2021'"

* --- Section 6: Credit ---
extract_codebook "${data_2021}/s06_me_ben2021" ///
    "s06_me_ben2021" "Section 6 - Credit" "`excel2021'"

* --- Section 7 ---
extract_codebook "${data_2021}/s07a_1_me_ben2021" ///
    "s07a_1_me_ben2021" "Section 7a (part 1)" "`excel2021'"

extract_codebook "${data_2021}/s07a_2_me_ben2021" ///
    "s07a_2_me_ben2021" "Section 7a (part 2)" "`excel2021'"

extract_codebook "${data_2021}/s07b_me_ben2021" ///
    "s07b_me_ben2021" "Section 7b" "`excel2021'"

* --- Section 8 ---
extract_codebook "${data_2021}/s08a_me_ben2021" ///
    "s08a_me_ben2021" "Section 8a" "`excel2021'"

* --- Section 9 ---
extract_codebook "${data_2021}/s09a_me_ben2021" ///
    "s09a_me_ben2021" "Section 9a" "`excel2021'"

extract_codebook "${data_2021}/s09b_me_ben2021" ///
    "s09b_me_ben2021" "Section 9b" "`excel2021'"

extract_codebook "${data_2021}/s09c_me_ben2021" ///
    "s09c_me_ben2021" "Section 9c" "`excel2021'"

extract_codebook "${data_2021}/s09d_me_ben2021" ///
    "s09d_me_ben2021" "Section 9d" "`excel2021'"

extract_codebook "${data_2021}/s09e_me_ben2021" ///
    "s09e_me_ben2021" "Section 9e" "`excel2021'"

extract_codebook "${data_2021}/s09f_me_ben2021" ///
    "s09f_me_ben2021" "Section 9f" "`excel2021'"

* --- Section 10: Enterprise ---
extract_codebook "${data_2021}/s10a_me_ben2021" ///
    "s10a_me_ben2021" "Section 10a - Enterprise" "`excel2021'"

extract_codebook "${data_2021}/s10b_me_ben2021" ///
    "s10b_me_ben2021" "Section 10b - Enterprise" "`excel2021'"

* --- Section 11 ---
extract_codebook "${data_2021}/s11_me_ben2021" ///
    "s11_me_ben2021" "Section 11" "`excel2021'"

* --- Section 12 ---
extract_codebook "${data_2021}/s12_me_ben2021" ///
    "s12_me_ben2021" "Section 12" "`excel2021'"

* --- Section 13: Remittances ---
extract_codebook "${data_2021}/s13_1_me_ben2021" ///
    "s13_1_me_ben2021" "Section 13 - Remittances (part 1)" "`excel2021'"

extract_codebook "${data_2021}/s13_2_me_ben2021" ///
    "s13_2_me_ben2021" "Section 13 - Remittances (part 2)" "`excel2021'"

* --- Section 14 ---
extract_codebook "${data_2021}/s14a_me_ben2021" ///
    "s14a_me_ben2021" "Section 14a" "`excel2021'"

extract_codebook "${data_2021}/s14b_me_ben2021" ///
    "s14b_me_ben2021" "Section 14b" "`excel2021'"

* --- Section 15 ---
extract_codebook "${data_2021}/s15_me_ben2021" ///
    "s15_me_ben2021" "Section 15" "`excel2021'"

* --- Section 16 ---
extract_codebook "${data_2021}/s16a_me_ben2021" ///
    "s16a_me_ben2021" "Section 16a" "`excel2021'"

extract_codebook "${data_2021}/s16b_me_ben2021" ///
    "s16b_me_ben2021" "Section 16b" "`excel2021'"

extract_codebook "${data_2021}/s16c_me_ben2021" ///
    "s16c_me_ben2021" "Section 16c" "`excel2021'"

extract_codebook "${data_2021}/s16d_me_ben2021" ///
    "s16d_me_ben2021" "Section 16d" "`excel2021'"

* --- Section 17 ---
extract_codebook "${data_2021}/s17_me_ben2021" ///
    "s17_me_ben2021" "Section 17" "`excel2021'"

* --- Section 18 ---
extract_codebook "${data_2021}/s18_1_me_ben2021" ///
    "s18_1_me_ben2021" "Section 18 (part 1)" "`excel2021'"

extract_codebook "${data_2021}/s18_2_me_ben2021" ///
    "s18_2_me_ben2021" "Section 18 (part 2)" "`excel2021'"

extract_codebook "${data_2021}/s18_3_me_ben2021" ///
    "s18_3_me_ben2021" "Section 18 (part 3)" "`excel2021'"

* --- Section 19 ---
extract_codebook "${data_2021}/s19_me_ben2021" ///
    "s19_me_ben2021" "Section 19" "`excel2021'"

* --- Section 20 ---
extract_codebook "${data_2021}/s20a_me_ben2021" ///
    "s20a_me_ben2021" "Section 20a" "`excel2021'"

extract_codebook "${data_2021}/s20b_1_me_ben2021" ///
    "s20b_1_me_ben2021" "Section 20b (part 1)" "`excel2021'"

extract_codebook "${data_2021}/s20b_2_me_ben2021" ///
    "s20b_2_me_ben2021" "Section 20b (part 2)" "`excel2021'"

extract_codebook "${data_2021}/s20b_3_me_ben2021" ///
    "s20b_3_me_ben2021" "Section 20b (part 3)" "`excel2021'"

extract_codebook "${data_2021}/s20c_me_ben2021" ///
    "s20c_me_ben2021" "Section 20c" "`excel2021'"

di as result _n "2021 codebook saved to: ${output}/BEN_codebook_2021.xlsx"


********************************************************************************
* DONE
********************************************************************************

di as text _n "=============================================="
di as result "CODEBOOK EXTRACTION COMPLETE"
di as text "=============================================="
di as text "Output files:"
di as text "  1. ${output}/BEN_codebook_2018.xlsx  (52 tabs — one per dataset)"
di as text "  2. ${output}/BEN_codebook_2021.xlsx  (59 tabs — one per dataset)"
di as text ""
di as text "Each tab contains: variable_name, section_name, type, label,"
di as text "  value_labels, valid_range, skip_logic, missing_codes, notes"
di as text ""
di as text "NEXT STEPS:"
di as text "  - Review the Excel files"
di as text "  - Fill in valid_range, skip_logic, and missing_codes"
di as text "    columns using the questionnaire PDFs"
di as text "=============================================="
