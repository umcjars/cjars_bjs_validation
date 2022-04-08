/*==============================================================================
Generate parole aggregate data
==============================


Output(s)
=========
-yearly parole entry counts for CJARS and APS
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
keep if cjars_table == "PAR"
duplicates drop

keep if coverage == 12

bysort st_fips: egen start = min(cov_yyyy)
bysort st_fips: egen end = max(cov_yyyy)
keep st_fips start end
destring st_fips, replace
rename st_fips par_st_juris_fips
duplicates drop

tempfile coverage
save `coverage'

rename par_st_juris_fips fips
drop start end

tempfile keep_states
save `keep_states'



	

************************generating CJARS aggregate parole entry counts*********************

clear
import sas "$datadir\cjars_parole_2021q1.sas7bdat", case(lower)
destring par_st_juris_fips, replace
*drop if inlist(par_st_juris_fips, 17, 39) // getting rid of non-historical states
gen entry_dt =  mdy(par_bgn_dt_mm, par_bgn_dt_dd, par_bgn_dt_yyyy)
format entry_dt %td
gen exit_dt =  mdy(par_end_dt_mm, par_end_dt_dd, par_end_dt_yyyy)	
format exit_dt %td

gen count = 1
merge m:1 par_st_juris_fips using `coverage' 

*all entries
preserve
	keep if par_bgn_dt_yyyy != . // drop cases with a missing date because I need this anchor date for collapsing
	drop if par_bgn_dt_yyyy < start
	drop if par_bgn_dt_yyyy > end
	collapse (sum) count, by(par_st_juris_fips par_bgn_dt_yyyy)
	rename count cjars_entries
	rename par_bgn_dt_yyyy year
	rename par_st_juris_fips fips
	tempfile cjars_entries
	save `cjars_entries'
restore

	
	

**********************Generating APS aggregate parole entry counts***************************

clear
use "$aparsdir\parole_totals.dta"
rename TOTEN aps_entries
sort fips year


*all entries
preserve
	keep year fips aps_entries
	tempfile aps_entries
	save `aps_entries'
restore
	




*******************Merging CJARS and APS aggregate parole entry counts together*******************


clear
use `cjars_entries'
merge 1:1 year fips using `aps_entries', nogen
merge m:1 fips using `keep_states', nogen keep(match)
sort fips year
keep if year >= 1980
gen cjars_aps_ratio = cjars_entries/aps_entries
run "$utility\fips_to_name.do"
replace state = subinstr(state, " ", "_", .)
foreach x of varlist _all {
	rename `x' `x'_
}
drop fips
reshape wide cjars_entries aps_entries cjars_aps_ratio, i(year) j(state) string
export delimited using "$tbldir\tex_figures\parole\tbl\parole_event_counts_entries_all.csv", replace




