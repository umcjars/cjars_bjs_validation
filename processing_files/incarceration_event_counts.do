/*==============================================================================
Generate incarceration aggregate data
==============================


Output(s)
=========
-yearly incarceration entry counts for CJARS, NPS, and NCRP
==============================================================================*/

	
********************************create a file to determine years/jurisdicitons covered in CJARS data for filtering purposes****************************************

clear
import sas "$datadir\cjars_coverage_2021q1.sas7bdat", case(lower)

g cov_yyyy = substr(month, 1, 4)
g cov_mm = substr(month, 6, .)
destring cov_yyyy cov_mm, replace

g st_fips_real = string(st_fips, "%02.0f")
g cnty_fips_real = string(cnty_fips,"%03.0f")
tostring cnty_fips, replace
tostring st_fips, replace
replace cnty_fips = st_fips_real + cnty_fips_real
replace st_fips = st_fips_real

replace coverage = "1" if coverage == "primary"
replace coverage = "0" if coverage == "secondary"
destring coverage, replace

drop st_fips_real cnty_fips_real month

frame copy default adj_collapse
frame change adj_collapse

	// Applying a STRONG test: only where BOTH FE and MI are full coverage
	drop if !inlist(cjars_table, "ADJ_FE", "ADJ_MI")
	collapse (sum) coverage, by (st_fips cnty_fips cov_yyyy cov_mm)
	g cjars_table = "ADJ"
	replace coverage = 0 if coverage < 2
	replace coverage = 1 if coverage == 2

	tempfile adj_file
	save `adj_file'
	
frame change default
frame drop adj_collapse
append using `adj_file'
drop if inlist(cjars_table, "ADJ_FE", "ADJ_MI")

// leave this line out if you want monthly coverage, and add cov_mm to order
collapse (sum) coverage, by (st_fips cnty_fips cjars_table cov_yyyy)
order st_fips cnty_fips cjars_table cov_yyyy coverage
compress

//SAVE here as coverage_cnty.dta

// drop cnty fips to produce the statewide table
drop cnty_fips

// Drop arrests since they are always at the county level
// Drop adj since it varies between state and county level
keep if cjars_table == "INC"
duplicates drop

keep if coverage == 12

bysort st_fips: egen start = min(cov_yyyy)
bysort st_fips: egen end = max(cov_yyyy)
keep st_fips start end
destring st_fips, replace
rename st_fips inc_st_juris_fips
duplicates drop

tempfile coverage
save `coverage'

rename inc_st_juris_fips fips
drop start end

tempfile keep_states
save `keep_states'



************************generating CJARS aggregate incarceration entry counts*********************

clear
import sas "$datadir\cjars_incarceration_2021q1.sas7bdat", case(lower)
destring inc_st_juris_fips, replace
*drop if inlist(inc_st_juris_fips, 5, 9, 17, 28, 34, 39) // getting rid of non-historical states
gen entry_dt = mdy(inc_entry_dt_mm, inc_entry_dt_dd, inc_entry_dt_yyyy)
format entry_dt %td 
gen exit_dt = mdy(inc_exit_dt_mm, inc_exit_dt_dd, inc_exit_dt_yyyy)
format exit_dt %td 
order entry_dt exit_dt, after(cjars_id)
gen count = 1
merge m:1 inc_st_juris_fips using `coverage' 

*all entries
preserve
	keep if inc_entry_dt_yyyy != . // drop cases with a missing date because I need this anchor date for collapsing
	drop if inc_entry_dt_yyyy < start
	drop if inc_entry_dt_yyyy > end
	collapse (sum) count, by(inc_st_juris_fips inc_entry_dt_yyyy)
	rename count cjars_entries
	rename inc_entry_dt_yyyy year
	rename inc_st_juris_fips fips
	tempfile cjars_entries_all
	save `cjars_entries_all'
restore

	

**********************Generating NPS aggregate incarceration entry counts***************************

clear
use "$npsdir\37639-0001-Data.dta"
run "$npsdir\37639-0001-Supplemental_syntax.do"
gen nps_entries = ADTOTM + ADTOTF

rename STATEID fips
rename YEAR year

*entries
preserve
	keep year fips nps_entries
	tempfile nps_entries_all
	save `nps_entries_all'
restore




**********************Generating NCRP aggregate incarceration entry counts***************************

clear 
use "$ncrpdir\37021-0002-Data.dta"
run "$ncrpdir\37021-0002-Supplemental_syntax.do"

*all entries
preserve
	drop if ADMITYR == .
	gen ncrp_entries = 1
	collapse (count) ncrp_entries, by(STATE ADMITYR)
	rename STATE fips
	rename ADMITYR year
	tempfile ncrp_entries_all
	save `ncrp_entries_all'
restore

*not enough information in the NCRP to figure out stocks or rates






*******************Merging CJARS, NPS, and NCRP aggregate incarceration entry counts together*******************

*entries
clear
use `cjars_entries_all'
merge 1:1 year fips using `nps_entries_all', nogen 
merge 1:1 year fips using `ncrp_entries_all', nogen 
merge m:1 fips using `keep_states', nogen keep(match)
sort fips year
keep if year >= 1980
gen cjars_nps_ratio = cjars_entries/nps_entries
gen cjars_ncrp_ratio = cjars_entries/ncrp_entries
run "$utility\fips_to_name.do"
replace state = subinstr(state, " ", "_", .)
foreach x of varlist _all {
	rename `x' `x'_
}
drop fips
reshape wide cjars_entries nps_entries ncrp_entries cjars_nps_ratio cjars_ncrp_ratio, i(year) j(state) string
export delimited using "$tbldir\tex_figures\incarceration\tbl\incarceration_event_counts_entries_all.csv", replace

