********************************************************************************
* EHCVM BENIN - 2018 DATA CLEANING
********************************************************************************
* Purpose: Clean and prepare 2018 wave data for analysis
* Author: Zaineb Majoka (mzaineb@worldbank.org). Based on Do-Files shared by David & Joseph
* Date: April 2026
*
* INPUT:  Raw 2018 data files
* OUTPUT: Cleaned 2018 dataset
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
global intermediate  "${project}/Data/BEN/Intermediate"
global output        "${project}/Output/BEN"
global final         "${project}/Data/BEN/Final"

* Create directories if needed
capture mkdir "${intermediate}"
capture mkdir "${output}"

********************************************************************************
* PART 1: CLEAN ENTERPRISE DATA (SECTION 10)
********************************************************************************

use "${data_2018}/s10_2_me_ben2018", clear

*------------------------------------------------------------------------------
* 1.1: Drop inactive enterprises and invalid owners
*------------------------------------------------------------------------------

drop if s10q58==2
drop if s10q15__0<0 | s10q15__0==.


*------------------------------------------------------------------------------
* 1.2: Create enterprise/individual identifier
*------------------------------------------------------------------------------

* Proprietor ID - who owns/runs this enterprise

gen proprietor_id = s10q15__0
label variable proprietor_id "Proprietor/owner ID (from Section 10)"

* Enterprise ID: cluster_household_proprietor
* This uses the proprietor ID, not individual ID
gen nonag_id = strofreal(grappe,"%3.0f") + "_" + ///
               strofreal(menage,"%02.0f") + "_" + ///
               strofreal(proprietor_id,"%02.0f")

label variable nonag_id "Enterprise ID (cluster_household_proprietor)"

sort nonag_id

*Create a numind to be used when merging datasets

gen numind = s10q15__0

*------------------------------------------------------------------------------
* 1.3: Calculate number of employees
*------------------------------------------------------------------------------

* Hired employees (non-household workers)
* David did not include boys/girls working in the enterprise. We are only including
* adults when counting number of employees

* Adult employees

gen num_emp = max(s10q62a_1, 0) + max(s10q62a_2, 0)
label variable num_emp "Number of hired employees"

* Total employees
gen num_emp_tot = max(s10q62a_1,0) + max(s10q62a_2,0) + ///
              max(s10q62a_3,0) + max(s10q62a_4,0)

* Children only (if we want it for child labor analysis)
gen num_emp_child = max(s10q62a_3,0) + max(s10q62a_4,0)

* enterprises with children employees
gen ent_child_emp = 1 if num_emp_child>=1 & num_emp_child!=.
replace ent_child_emp = 0 if num_emp_child==0

* Household employees (family workers) - up to 11 in 2018
* each variable refers to individual id within the household

gen num_hhemp = 0
label variable num_hhemp "Number of household employees"

forvalues person = 1/11 {
    capture confirm variable s10q61a_`person'
    if !_rc {
        replace num_hhemp = num_hhemp + 1 if s10q61a_`person' < .
    }
}

*dummy for enterprises that hire non-household employees

gen hires_nonhh_workers = (num_emp_tot > 0) if !missing(num_emp_tot)
label variable hires_nonhh_workers "Enterprise hires non-household workers"
label define hires_nonhh_workers 0 "No hired workers" 1 "Hires non-HH workers"
label values hires_nonhh_workers hires_nonhh_workers

*categorical variable for number of household member employees

recode num_hhemp (0=0 "0") (1=1 "1") (2/max=2 "2+"), gen(num_hhemp_cat)
label variable num_hhemp_cat "Number of household employees (categorical)"

*------------------------------------------------------------------------------
* 1.4: Calculate wages paid to hired workers
*------------------------------------------------------------------------------

* Rename wage variables
rename s10q62d_1 out_hh_worker_men_salary
rename s10q62d_2 out_hh_worker_women_salary
rename s10q62d_3 out_hh_worker_boys_salary
rename s10q62d_4 out_hh_worker_girls_salary

* Sum total wages
egen var1 = total(out_hh_worker_men_salary), by(nonag_id)
egen var2 = total(out_hh_worker_women_salary), by(nonag_id)
egen var3 = total(out_hh_worker_boys_salary), by(nonag_id)
egen var4 = total(out_hh_worker_girls_salary), by(nonag_id)

egen val_hired_labor = rowtotal(var1 var2 var3 var4)
label variable val_hired_labor "Total wages paid"

drop var1 var2 var3 var4

*Dummy for enterprises that hire non-hh members but pay no salary
gen no_wages_paid = (val_hired_labor == 0 | missing(val_hired_labor)) if num_emp > 0
label variable no_wages_paid "Enterprise has hired workers but pays no wages"
label define no_wages_paid 0 "Pays wages" 1 "No wages paid"
label values no_wages_paid no_wages_paid

*------------------------------------------------------------------------------
* 1.5: Calculate capital value
*------------------------------------------------------------------------------

gen value_machines = 0
replace value_machines = s10q36 if s10q35==1
label variable value_machines "Value of machines"

gen value_vehicles = 0
replace value_vehicles = s10q38 if s10q37==1
label variable value_vehicles "Value of vehicles"

gen value_furniture = 0
replace value_furniture = s10q40 if s10q39==1
label variable value_furniture "Value of furniture"

gen value_other = 0
replace value_other = s10q42 if s10q41==1
label variable value_other "Value of other equipment"

egen value_total = rowtotal(value_machines value_vehicles value_furniture value_other)
label variable value_total "Total capital value"

gen owns_assets = (value_total>0 & value_total<.)
label variable owns_assets "Owns any assets"

*------------------------------------------------------------------------------
* 1.6: Calculate revenue
*------------------------------------------------------------------------------

egen revenue = rowtotal(s10q46 s10q48 s10q50)
label variable revenue "Total monthly revenue (FCFA)"

*------------------------------------------------------------------------------
* 1.7: Calculate expenses
*------------------------------------------------------------------------------

* Convert annual taxes to monthly
replace s10q55 = s10q55/12  // Business license
replace s10q56 = s10q56/12  // Other taxes
replace s10q57 = s10q57/12  // Admin fees

* Total expenses
egen expenses = rowtotal(s10q47 s10q49 s10q51 s10q52-s10q57 val_hired_labor)
label variable expenses "Total monthly expenses (FCFA)"

*------------------------------------------------------------------------------
* 1.8: Calculate profit
*------------------------------------------------------------------------------

gen profit = revenue - expenses
label variable profit "Monthly profit (FCFA)"

*------------------------------------------------------------------------------
* 1.9: Enterprise characteristics
*------------------------------------------------------------------------------

* Place of business
gen place = s10q23
label variable place "Place of business"

label define place ///
    1 "Office, workshop, store, shop, garage" ///
    2 "Fixed post on public road" ///
    3 "Mobile post on public road" ///
    4 "At home" ///
    5 "Client's home" ///
    6 "Car, motorcycle" ///
    7 "Mobile/itinerant" ///
    8 "Other (specify)"

label values place place

* Financing source
gen financing = s10q34
label variable financing "Source of initial financing"

label define financing ///
    1 "Own funds" ///
    2 "Help from relative in country" ///
    3 "Help from relative abroad" ///
    4 "Loan from another household" ///
    5 "Loan from tontine" ///
    6 "Bank loan or microfinance" ///
    7 "Loan/support from cooperative" ///
    8 "Loan/support from NGO" ///
    9 "Other (specify)"

label values financing financing

* Year established
gen year_est = s10q20
label variable year_est "Year established"

* Electricity
gen has_electricity = (s10q26 == 1)
label variable has_electricity "Has electricity"

* Formality indicators
* option 1 and 2: yes, transmitted to tax authority and Yes, not transmitted to tax authority
gen firm_keeps_accounts = inlist(s10q29, 1, 2)
label variable firm_keeps_accounts "Keeps written accounts"

gen firm_has_fisc_id = (s10q30 == 1)
label variable firm_has_fisc_id "Has fiscal ID (NIF)"

gen firm_in_trade_register = (s10q31 == 1)
label variable firm_in_trade_register "In trade register"

* CNPS registration
gen firm_cnps_registered = (s10q32 == 1)
label variable firm_cnps_registered "Registered with CNPS"

* Legal form and cooperative
gen legal_form = s10q33
label variable legal_form "Legal form"
label define legal_form 1 "Individual" 2 "Cooperative/GIE" 3 "Other"
label values legal_form legal_form

gen cooperative = (legal_form == 2)
label variable cooperative "Is a cooperative"

*------------------------------------------------------------------------------
* 1.10: Flag highest-revenue enterprise per owner
*------------------------------------------------------------------------------

* Calculate maximum revenue for each owner
egen max_rev_by_owner = max(revenue), by(nonag_id)

* Create dummy for highest-revenue enterprise
gen is_highest_revenue = (revenue == max_rev_by_owner) if !missing(revenue)
label variable is_highest_revenue "Is highest-revenue enterprise for this owner"
label define is_highest_revenue 0 "Not highest revenue" 1 "Highest revenue"
label values is_highest_revenue is_highest_revenue

* Note: If owner has only 1 enterprise, is_highest_revenue = 1
* If owner has multiple enterprises with same revenue, multiple will = 1

*------------------------------------------------------------------------------
* 1.11: Keep highest-revenue enterprise per owner
*------------------------------------------------------------------------------

gsort nonag_id -revenue -value_total
bysort nonag_id: keep if _n==1

*------------------------------------------------------------------------------
* 1.12: Recode sector
*------------------------------------------------------------------------------

recode s10q17a ///
    (1/2   = 1 "Ag and extractives") ///
    (3     = 2 "Manufacturing") ///
    (4/5   = 3 "Utilities and construction") ///
    (6/7   = 5 "Retail") ///
    (8     = 6 "Transport") ///
    (17    = 7 "Personal services") ///
    (9/16 18 = 9 "Other"), ///
    gen(sector)

label variable sector "Sector"

*------------------------------------------------------------------------------
* 1.13: Revenue shares
*------------------------------------------------------------------------------

gen share_revenue_resale = s10q46/revenue
gen share_revenue_processed = s10q48/revenue
gen share_revenue_services = s10q50/revenue

*------------------------------------------------------------------------------
* 1.14: Problem variables (keep for regressions)
*------------------------------------------------------------------------------

* Label problem variables
label variable s10q45a "Problem: Supply of raw materials"
label variable s10q45b "Problem: Lack of customers"
label variable s10q45c "Problem: Too much competition"
label variable s10q45d "Problem: Accessing credit"
label variable s10q45e "Problem: Recruiting personnel"
label variable s10q45f "Problem: Insufficient space"
label variable s10q45g "Problem: Accessing equipment"
label variable s10q45h "Problem: Technical manufacturing"
label variable s10q45i "Problem: Technical management"
label variable s10q45j "Problem: Electricity access"
label variable s10q45k "Problem: Power outages"
label variable s10q45l "Problem: Other infrastructure"
label variable s10q45m "Problem: Internet"
label variable s10q45n "Problem: Insecurity"
label variable s10q45o "Problem: Regulation and taxes"

label define s10q45 1 "Yes" 2 "No" 3 "N/A"
label values s10q45? s10q45

*------------------------------------------------------------------------------
* 1.15: Number of enterprises per household
*------------------------------------------------------------------------------

* Create household ID
gen hhid = grappe * 1000 + menage
label variable hhid "Household ID (numeric, matches individual dataset)"

bysort hhid: egen N_enterprises_hh = count(proprietor_id)
label variable N_enterprises_hh "Number of enterprises in household"

* Dummy for households with multiple enterprises
gen multiple_enterprises = (N_enterprises_hh > 1) if !missing(N_enterprises_hh)
label variable multiple_enterprises "Household operates more than 1 enterprise"
label define multiple_enterprises 0 "Single enterprise" 1 "Multiple enterprises"
label values multiple_enterprises multiple_enterprises

*------------------------------------------------------------------------------
* 1.16: Save enterprise data
*------------------------------------------------------------------------------

tempfile enterprise_2018
save `enterprise_2018', replace
