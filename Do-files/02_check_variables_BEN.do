********************************************************************************
* EHCVM BENIN — VARIABLE INSPECTION DO-FILE
********************************************************************************
* Purpose: Open each dataset listed in "Variable List.xlsx" one by one,
*          run codebook on the relevant variables, and browse the data
*          so you can check how each variable is coded.
*          Fill in the "Coding Notes" column in the Excel file as you go.
*
* Date:    April 2026
*
* DATASETS (in Variable List order):
*   2018: s10_2, s10_1, ehcvm_individu, s01, s04, ehcvm_menage,
*         ehcvm_welfare, s06, s13a_2
*   2021: s10b, s10a, ehcvm_individu, s04a, s04b, s04c, ehcvm_menage,
*         ehcvm_welfare, s06, s13_2
*
* USAGE:
*   - Set your project path in PART 0
*   - Run section by section (Ctrl+D on selected block in Stata)
*     OR set pause on to step through automatically
*   - Each section: (1) loads dataset, (2) describes key vars,
*     (3) runs codebook on them, (4) opens browser
*
* NOTE: This do-file only READS data — it does not modify any files.
********************************************************************************

clear all
set more off

* Uncomment the line below to pause at each dataset (press any key to continue)
* pause on

********************************************************************************
* PART 0: SET PATHS  —  UPDATE THIS TO MATCH YOUR SETUP
********************************************************************************

global project   "C:\Users\WB461621\OneDrive - WBG\SPJ\West Africa\Regional HH Enterprise Work"
global data_2018 "${project}/Data/BEN/2018"
global data_2021 "${project}/Data/BEN/2021"

********************************************************************************
*                                                                              *
*                          ===  2018 DATASETS  ===                            *
*                                                                              *
********************************************************************************

********************************************************************************
* 2018 — 1/9  |  s10_2_me_ben2018  (Section 10B: Enterprise Details)
********************************************************************************

use "${data_2018}/s10_2_me_ben2018", clear

codebook ///
    s10q58      ///  Enterprise still active (filter)
    s10q15__0   ///  Code ID of owner/proprietor 1
    s10q62a_1 s10q62a_2 s10q62a_3 s10q62a_4  ///  # hired employees by sex/age
    s10q61a_*   ///  Code ID of HH members working in enterprise (up to 11)
    s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4  ///  Salary paid to hired workers
    s10q35 s10q36 s10q37 s10q38 s10q39 s10q40 s10q41 s10q42  ///  Assets
    s10q46 s10q48 s10q50  ///  Monthly revenues
    s10q47 s10q49 s10q51 s10q52 s10q53 s10q54  ///  Operating costs
    s10q55 s10q56 s10q57  ///  Taxes & fees
    s10q23 s10q34 s10q20 s10q26 s10q29 s10q30 s10q31 s10q32 s10q33  ///  Characteristics
    s10q17a  ///  Branch of activity
    s10q45a s10q45b s10q45c s10q45d s10q45e s10q45f s10q45g ///
    s10q45h s10q45i s10q45j s10q45k s10q45l s10q45m s10q45n s10q45o  // Problems

browse s10q58 s10q15__0 s10q62a_1-s10q62a_4 s10q61a_* ///
    s10q35 s10q36 s10q37 s10q38 s10q39 s10q40 s10q41 s10q42 ///
    s10q46 s10q47 s10q48 s10q49 s10q50 s10q51-s10q57 ///
    s10q23 s10q34 s10q20 s10q26 s10q29-s10q33 s10q17a s10q45a-s10q45o

pause  // Press any key to continue to next dataset

********************************************************************************
* 2018 — 2/9  |  s10_1_me_ben2018  (Section 10A: Enterprise Screening)
********************************************************************************

use "${data_2018}/s10_1_me_ben2018", clear

codebook ///
    s10q02 s10q03 s10q04 s10q05 s10q06 s10q07 s10q08 s10q09 s10q10

browse s10q02-s10q10

pause

********************************************************************************
* 2018 — 3/9  |  ehcvm_individu_ben2018  (Individual Characteristics)
********************************************************************************

use "${data_2018}/ehcvm_individu_ben2018", clear

codebook ///
    grappe menage numind hhid hhweight ///
    lien sexe age zae milieu ///
    csp activ7j educ_hi alfab educ_scol ///
    bank internet

browse grappe menage numind hhid hhweight ///
    lien sexe age zae milieu ///
    csp activ7j educ_hi alfab educ_scol bank internet

pause

********************************************************************************
* 2018 — 4/9  |  s01_me_ben2018  (Section 1: Household Roster — ethnie/ID)
********************************************************************************

use "${data_2018}/s01_me_ben2018", clear

codebook s01q00a s01q16

browse s01q00a s01q16

pause

********************************************************************************
* 2018 — 5/9  |  s04_me_ben2018  (Section 4: Employment)
********************************************************************************

use "${data_2018}/s04_me_ben2018", clear

codebook ///
    s01q00a  ///  Individual ID (to be renamed numind)
    s04q06 s04q07 s04q08 s04q09  ///  Worked in past 7 days (activity types)
    s04q13 s04q14  ///  Unpaid work for other HH member
    s04q15 s04q17 s04q19  ///  Job search / availability
    s04q28a s04q28b  ///  Type of employment in last 12 months
    s04q29b s04q30b  ///  Occupation / branch of activity (primary job)
    s04q32 s04q36 s04q37 s04q39  ///  Months/days/hours/CSP (primary)
    s04q43 s04q43_unite  ///  Salary (primary)
    s04q44 s04q45 s04q45_unite  ///  Bonuses (primary)
    s04q46 s04q47 s04q47_unite  ///  In-kind benefits (primary)
    s04q48 s04q49 s04q49_unite  ///  Food benefits (primary)
    s04q50  ///  Has secondary job?
    s04q55 s04q56  ///  Months/days (secondary job)
    s04q58 s04q58_unite  ///  Salary (secondary)
    s04q59 s04q60 s04q60_unite  ///  Bonuses (secondary)
    s04q61 s04q62 s04q62_unite  ///  In-kind benefits (secondary)
    s04q63 s04q64 s04q64_unite  // Food benefits (secondary)

browse s01q00a s04q06-s04q09 s04q13-s04q15 s04q17 s04q19 ///
    s04q28a s04q28b s04q29b s04q30b s04q32 s04q36 s04q37 s04q39 ///
    s04q43 s04q43_unite s04q44 s04q45 s04q45_unite ///
    s04q46 s04q47 s04q47_unite s04q48 s04q49 s04q49_unite s04q50 ///
    s04q55 s04q56 s04q58 s04q58_unite s04q59 s04q60 s04q60_unite ///
    s04q61 s04q62 s04q62_unite s04q63 s04q64 s04q64_unite

pause

********************************************************************************
* 2018 — 6/9  |  ehcvm_menage_ben2018  (Household Characteristics + Shocks)
********************************************************************************

use "${data_2018}/ehcvm_menage_ben2018", clear

codebook ///
    logem mur toit sol  ///  Housing
    eauboi_ss eauboi_sp  ///  Water source
    elec_ac elec_ur elec_ua  ///  Electricity
    ordure toilet eva_toi eva_eau  ///  Sanitation
    tv fer frigo cuisin ordin decod car  ///  Assets
    superf grosrum petitrum porc lapin volail  ///  Land & livestock
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio  // Shocks

browse logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
    ordure toilet eva_toi eva_eau ///
    tv fer frigo cuisin ordin decod car ///
    superf grosrum petitrum porc lapin volail ///
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio

pause

********************************************************************************
* 2018 — 7/9  |  ehcvm_welfare_ben2018  (Welfare Aggregates + Geography)
********************************************************************************

use "${data_2018}/ehcvm_welfare_ben2018", clear

codebook ///
    hhsize eqadu1 eqadu2  ///  HH size & equivalence scales
    dali dnal dtot pcexp  ///  Consumption aggregates
    zae region milieu  ///  Geography (note: uses zae not zzae in 2018)
    zref def_spa def_temp  ///  Poverty lines & deflators
    hgender hage hmstat hreligion hnation  ///  HH head demographics
    halfab heduc hdiploma hhandig  ///  HH head education & disability
    hactiv7j hactiv12m hbranch hsectins hcsp  // HH head activity

browse hhsize eqadu1 eqadu2 dali dnal dtot pcexp ///
    zae region milieu zref def_spa def_temp ///
    hgender hage hmstat hreligion hnation halfab heduc hdiploma hhandig ///
    hactiv7j hactiv12m hbranch hsectins hcsp

pause

********************************************************************************
* 2018 — 8/9  |  s06_me_ben2018  (Section 6: Credit)
********************************************************************************

use "${data_2018}/s06_me_ben2018", clear

codebook ///
    s01q00a  ///  Individual ID (renamed to numind in cleaning)
    s06q05   ///  Obtained credit in last 12 months?
    s06q12   ///  Source of credit
    s06q12_autre  ///  Source of credit (other, specify)
    s06q14   ///  Amount of last credit
    s06q09   ///  Has outstanding loans?
    s06q10   //   Number of outstanding loans

browse s01q00a s06q05 s06q12 s06q12_autre s06q14 s06q09 s06q10

pause

********************************************************************************
* 2018 — 9/9  |  s13a_2_me_ben2018  (Section 13A Part 2: Remittances)
********************************************************************************

use "${data_2018}/s13a_2_me_ben2018", clear

codebook ///
    s13aq14   ///  Location of sender
    s13aq17a  ///  Amount sent each time
    s13aq17b  //   Frequency of transfers

browse s13aq14 s13aq17a s13aq17b

di as result _n "========================================"
di as result "2018 VARIABLE INSPECTION COMPLETE"
di as result "========================================"

pause

********************************************************************************
*                                                                              *
*                          ===  2021 DATASETS  ===                            *
*                                                                              *
********************************************************************************

********************************************************************************
* 2021 — 1/10  |  s10b_me_ben2021  (Section 10B: Enterprise Details)
********************************************************************************

use "${data_2021}/s10b_me_ben2021", clear

codebook ///
    s10q58      ///  Enterprise still active (filter)
    s10q15__0   ///  Code ID of owner/proprietor 1
    s10q62a_1 s10q62a_2 s10q62a_3 s10q62a_4  ///  # hired employees by sex/age
    s10q61a_*   ///  Code ID of HH members working in enterprise (up to 9)
    s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4  ///  Salary paid to hired workers
    s10q35 s10q36 s10q37 s10q38 s10q39 s10q40 s10q41 s10q42  ///  Assets
    s10q46 s10q48 s10q50  ///  Monthly revenues
    s10q47 s10q49 s10q51 s10q52 s10q53 s10q54  ///  Operating costs
    s10q55 s10q56 s10q57  ///  Taxes & fees
    s10q23 s10q34 s10q20 s10q26 s10q29 s10q30 s10q31 s10q32 s10q33  ///  Characteristics
    s10q17a     ///  Branch of activity
    s10q62_a    ///  Labor management affected by COVID-19 (NEW in 2021)
    s10q45a s10q45b s10q45c s10q45d s10q45e s10q45f s10q45g ///
    s10q45h s10q45i s10q45j s10q45k s10q45l s10q45m s10q45n s10q45o  // Problems

browse s10q58 s10q15__0 s10q62a_1-s10q62a_4 s10q61a_* ///
    s10q35-s10q42 s10q46-s10q57 ///
    s10q23 s10q34 s10q20 s10q26 s10q29-s10q33 s10q17a s10q62_a ///
    s10q45a-s10q45o

pause

********************************************************************************
* 2021 — 2/10  |  s10a_me_ben2021  (Section 10A: Enterprise Screening)
********************************************************************************

use "${data_2021}/s10a_me_ben2021", clear

codebook s10q02 s10q03 s10q04 s10q05 s10q06 s10q07 s10q08 s10q09 s10q10

browse s10q02-s10q10

pause

********************************************************************************
* 2021 — 3/10  |  ehcvm_individu_ben2021  (Individual Characteristics)
********************************************************************************

use "${data_2021}/ehcvm_individu_ben2021", clear

codebook ///
    grappe menage numind hhid hhweight ///
    lien sexe age zae milieu ///
    csp activ7j educ_hi alfa educ_scol ///
    ethnie bank internet

browse grappe menage numind hhid hhweight ///
    lien sexe age zae milieu ///
    csp activ7j educ_hi alfa educ_scol ethnie bank internet

pause

********************************************************************************
* 2021 — 4/10  |  s04a_me_ben2021  (Section 4A: Employment Status)
********************************************************************************

use "${data_2021}/s04a_me_ben2021", clear

codebook ///
    membres__id  ///  Individual ID (renamed to numind)
    s04q06 s04q07 s04q08 s04q09  ///  Worked in past 7 days (activity types)
    s04q13 s04q14  ///  Unpaid work for other HH member
    s04q15 s04q17 s04q19  ///  Job search / availability
    s04q28a s04q28b  // Type of employment in last 12 months

browse membres__id s04q06-s04q09 s04q13 s04q14 s04q15 s04q17 s04q19 ///
    s04q28a s04q28b

pause

********************************************************************************
* 2021 — 5/10  |  s04b_me_ben2021  (Section 4B: Primary Job Details)
********************************************************************************

use "${data_2021}/s04b_me_ben2021", clear

codebook ///
    membres__id  ///  Individual ID (renamed to numind)
    s04q29b s04q30b  ///  Occupation / branch of activity
    s04q32 s04q36 s04q37  ///  Months/days/hours (primary job)
    s04q38  ///  Contributes to FNRB/CNSS (formality indicator)
    s04q39  ///  Socio-professional category
    s04q31  ///  Principal employer (public/private)
    s04q43 s04q43_unite  ///  Salary (primary)
    s04q44 s04q45 s04q45_unite  ///  Bonuses (primary)
    s04q46 s04q47 s04q47_unite  ///  In-kind benefits (primary)
    s04q48 s04q49 s04q49_unite  ///  Food benefits (primary)
    s04q50  // Has secondary job?

browse membres__id s04q29b s04q30b s04q31 s04q32 s04q36 s04q37 s04q38 s04q39 ///
    s04q43 s04q43_unite s04q44 s04q45 s04q45_unite ///
    s04q46 s04q47 s04q47_unite s04q48 s04q49 s04q49_unite s04q50

pause

********************************************************************************
* 2021 — 6/10  |  s04c_me_ben2021  (Section 4C: Secondary Job Details)
********************************************************************************

use "${data_2021}/s04c_me_ben2021", clear

codebook ///
    membres__id  ///  Individual ID (renamed to numind)
    s04q50  ///  Has secondary job? (may duplicate from s04b)
    s04q54 s04q55 s04q56  ///  Months/days/hours (secondary)
    s04q58 s04q58_unite  ///  Salary (secondary)
    s04q59 s04q60 s04q60_unite  ///  Bonuses (secondary)
    s04q61 s04q62 s04q62_unite  ///  In-kind benefits (secondary)
    s04q63 s04q64 s04q64_unite  // Food benefits (secondary)

browse membres__id s04q50 s04q54 s04q55 s04q56 ///
    s04q58 s04q58_unite s04q59 s04q60 s04q60_unite ///
    s04q61 s04q62 s04q62_unite s04q63 s04q64 s04q64_unite

pause

********************************************************************************
* 2021 — 7/10  |  ehcvm_menage_ben2021  (Household Characteristics + Shocks)
********************************************************************************

use "${data_2021}/ehcvm_menage_ben2021", clear

codebook ///
    logem mur toit sol  ///  Housing
    eauboi_ss eauboi_sp  ///  Water source
    elec_ac elec_ur elec_ua  ///  Electricity
    ordure toilet eva_toi eva_eau  ///  Sanitation
    tv fer frigo cuisin ordin decod car  ///  Assets
    superf grosrum petitrum porc lapin volail  ///  Land & livestock
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth  // Shocks

browse logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
    ordure toilet eva_toi eva_eau ///
    tv fer frigo cuisin ordin decod car ///
    superf grosrum petitrum porc lapin volail ///
    sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth

pause

********************************************************************************
* 2021 — 8/10  |  ehcvm_welfare_ben2021  (Welfare Aggregates + Geography)
********************************************************************************

use "${data_2021}/ehcvm_welfare_ben2021", clear

codebook ///
    hhsize eqadu1 eqadu2  ///  HH size & equivalence scales
    dali dnal dtot pcexp  ///  Consumption aggregates
    zzae departement milieu  ///  Geography
    zref def_spa def_temp  ///  Poverty line & core deflators
    def_temp_prix2021m11 def_temp_cpi def_temp_adj  ///  Extra deflators (2021)
    dtet monthly_cpi cpi2017 icp2017 dollars  ///  Additional welfare vars (2021)
    hgender hage hmstat hreligion hnation  ///  HH head demographics
    heduc hdiploma hhandig  ///  HH head education & disability
    hactiv7j hactiv12m hbranch hsectins hcsp  // HH head activity

browse hhsize eqadu1 eqadu2 dali dnal dtot pcexp ///
    zzae departement milieu zref def_spa def_temp ///
    def_temp_prix2021m11 def_temp_cpi def_temp_adj ///
    dtet monthly_cpi cpi2017 icp2017 dollars ///
    hgender hage hmstat hreligion hnation heduc hdiploma hhandig ///
    hactiv7j hactiv12m hbranch hsectins hcsp

pause

********************************************************************************
* 2021 — 9/10  |  s06_me_ben2021  (Section 6: Credit)
********************************************************************************

use "${data_2021}/s06_me_ben2021", clear

codebook ///
    membres__id  ///  Individual ID (renamed to numind)
    s06q05       ///  Obtained credit in last 12 months?
    s06q12       ///  Source of credit
    s06q12_autre ///  Source of credit (other, specify)
    s06q14       ///  Amount of last credit
    s06q09       ///  Has outstanding loans?
    s06q10       //   Number of outstanding loans

browse membres__id s06q05 s06q12 s06q12_autre s06q14 s06q09 s06q10

pause

********************************************************************************
* 2021 — 10/10  |  s13_2_me_ben2021  (Section 13 Part 2: Remittances)
********************************************************************************

use "${data_2021}/s13_2_me_ben2021", clear

codebook ///
    s13q19   ///  Location of sender
    s13q22a  ///  Amount sent each time
    s13q22b  //   Frequency of transfers

browse s13q19 s13q22a s13q22b

di as result _n "========================================"
di as result "2021 VARIABLE INSPECTION COMPLETE"
di as result "========================================"
di as text ""
di as text "All 19 datasets checked (9 for 2018, 10 for 2021)."
di as text "Update the 'Coding Notes' column in Variable List.xlsx."
