/*==============================================================================
Generate subset of CJARS adjudication data and aggregrate data that is used for SCPS comparisons
==============================

Output(s)
=========
-subset of individual-level CJARS adjudication data that is used for SCPS data comparison
-aggregate dataset used for SCPS data comparison figure
==============================================================================*/


************************create one appended and deduplicated CJARS roster file*************************

clear
import sas "$datadir\cjars_roster_2021q1.sas7bdat", case(lower)
keep cjars_id dob_mm dob_dd dob_yyyy sex race race_raw
gen dob = mdy(dob_mm, dob_dd, dob_yyyy)
format dob %td
drop dob_dd dob_mm dob_yyyy
keep cjars_id sex race race_raw dob
bys cjars_id: egen sex_mode = mode(sex), minmode //determining modal sex within a cjars_id to use as a person's sex
bys cjars_id: egen race_mode = mode(race), minmode //determining modal race within a cjars_id to use as a person's race
bys cjars_id: egen race_raw_mode = mode(race_raw), minmode //determining modal race within a cjars_id to use as a person's race (using race raw variable)
bys cjars_id: egen dob_mode = mode(dob), minmode //determining modal dob within a cjars_id to use as a person's dob
duplicates drop cjars_id sex_mode race_mode race_raw_mode dob_mode, force
drop sex race dob race_raw
rename (sex_mode race_mode race_raw_mode dob_mode) (sex race race_raw dob)
format dob %td
tempfile pii
save `pii'

	
************************create a tempfile that includes the 75 most populous counties to identify subset of SCPS counties******************************

clear 
import delimited using "$utility\Census\County_population_2000_2010 (Intercensal).csv", varnames(1)
drop if county == 0
keep state county popestimate2009
rename (state county popestimate2009) (adj_st_ori_fips adj_cnty_ori_fips popl)
gsort -popl // sort from largest to smallest
keep in 1/75 // creates list of 75 largest counties
tempfile top75
save `top75'


********************************create a file to determine years/jurisdicitons covered in CJARS data for filtering purposes****************************************

clear
import sas "$datadir\cjars_coverage_2021q1.sas7bdat", case(lower)

// Separate out the dates and format FIPS codes
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

// The population-based coverage table is only for adjudication
drop if !inlist(cjars_table, "ADJ_FE", "ADJ_MI")

// Calculate how many months of the year each county is covered
collapse (sum) coverage, by (st_fips cnty_fips cjars_table cov_yyyy)
order st_fips cnty_fips cjars_table cov_yyyy coverage
compress

drop if coverage < 12
keep if cjars_table == "ADJ_FE"

bysort cnty_fips: egen coverage_start = min(cov_yyyy)
bysort cnty_fips: egen coverage_end = max(cov_yyyy)

keep cnty_fips coverage_start coverage_end

duplicates drop

gen adj_st_ori_fips = substr(cnty_fips, 1, 2)
gen adj_cnty_ori_fips = substr(cnty_fips, 3, 3)
destring adj_st_ori_fips adj_cnty_ori_fips, replace

drop cnty_fips

tempfile coverage
save `coverage'



*******************************preparing CJARS adjudication file to create subsets of data*******************************

clear
import sas "$datadir\cjars_adjudication_2021q1.sas7bdat", case(lower)
keep if adj_grd_cd == "FE" // need to have only felony cases
gen file_dt = mdy(adj_file_dt_mm, adj_file_dt_dd, adj_file_dt_yyyy) //starting to generate event date based on the combination of date variables in thed data
gen disp_dt = mdy(adj_disp_dt_mm, adj_disp_dt_dd, adj_disp_dt_yyyy)
gen sent_dt = mdy(adj_sent_dt_mm, adj_sent_dt_dd, adj_sent_dt_yyyy)
gen off_dt = mdy(adj_off_dt_mm, adj_off_dt_dd, adj_off_dt_yyyy)
gen event_dt = off_dt
replace event_dt = file_dt if event_dt == .
replace event_dt = disp_dt if event_dt == .
replace event_dt = sent_dt if event_dt == .
format event_dt %td
gen event_year = year(event_dt)
gen event_month = month(event_dt)
gen event_day = day(event_dt)
keep if event_month == 5 // need to keep only cases from the month of May
gen off_cd = adj_chrg_off_cd //creating a combined offense code variable where charge code takes precenden... doing this because skips uses "arresting offense
replace off_cd = adj_disp_off_cd if off_cd == "9999" //creating a combined offense code variable where charge code takes precenden... doing this because skips uses "arresting offense
destring adj_st_ori_fips adj_cnty_ori_fips, replace
merge m:1 adj_st_ori_fips adj_cnty_ori_fips using `top75', keep(matched) nogen // keeps observations only in the most populous counties
merge m:1 cjars_id using `pii', keep(match) nogen 
gen age = (event_dt - dob)/365.25
gen count = 1
*generating SCPS child offense category
gen off_cd_child = "murder" if off_cd == "1010" | off_cd == "1030"
replace off_cd_child = "rape" if off_cd == "1070"
replace off_cd_child = "robbery" if off_cd == "1180" | off_cd == "1190"
replace off_cd_child = "assault" if off_cd == "1200" | off_cd == "1011" | off_cd == "1210" | off_cd == "1230"
replace off_cd_child = "other violent" if off_cd == "1040" | off_cd == "1050" | off_cd == "1100" | off_cd == "1060" | off_cd == "1220" | off_cd == "1240" | off_cd == "1250"
replace off_cd_child = "burglary" if off_cd == "2010"
replace off_cd_child = "larceny/theft" if off_cd == "2050" | off_cd == "2060" | off_cd == "2070"
replace off_cd_child = "motor vehicle theft" if off_cd == "2030"
replace off_cd_child = "forgery/fraud" if off_cd == "2040"
replace off_cd_child = "other property" if off_cd == "2090" | off_cd == "2100" | off_cd == "2020" | off_cd == "2110" | off_cd == "2140" | off_cd == "2150"
replace off_cd_child = "drug trafficking" if off_cd == "3010" | off_cd == "3020" | off_cd == "3030" | off_cd == "3040" | off_cd == "3050" | off_cd == "3060" | off_cd == "3070" | off_cd == "3080"
replace off_cd_child = "other drug" if off_cd == "3090" | off_cd == "3100" | off_cd == "3110" | off_cd == "3120" | off_cd == "3130" | off_cd == "3140" | off_cd == "3150" | off_cd == "3160" | off_cd == "3250"
replace off_cd_child = "weapons" if off_cd == "5040"
replace off_cd_child = "driving related" if off_cd == "4010" | off_cd == "4020" | off_cd == "4030" | off_cd == "6010"
replace off_cd_child = "other public order" if off_cd == "5020" | off_cd == "5030" | off_cd == "5050" | off_cd == "5060" | off_cd == "5070" | off_cd == "5010" | off_cd == "5130" | off_cd == "5190" | off_cd == "5200"
*generating SCPS parent offense category
gen off_cd_parent = "violent" if off_cd_child == "murder" | off_cd_child == "rape" | off_cd_child == "robbery" | off_cd_child == "assault" | off_cd_child == "other violent"
replace off_cd_parent = "property" if off_cd_child == "burglary" | off_cd_child == "larceny/theft" | off_cd_child == "motor vehicle theft" | off_cd_child == "forgery/fraud" | off_cd_child == "other property"
replace off_cd_parent = "drug" if off_cd_child == "drug trafficking" | off_cd_child == "other drug"
replace off_cd_parent = "public order" if off_cd_child == "weapons" | off_cd_child == "driving related" | off_cd_child == "other public order"
	
keep if event_year > 1989

*******************************generating dataset for individual-level CJARS-SCPS comparisons*******************************

preserve
	keep if inlist(event_year, 1990, 1992, 1994, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
	
	*drug
	gen drug = 0
	replace drug = 1 if off_cd_parent == "drug"
	replace drug = . if off_cd_parent == ""
	*property
	gen property = 0
	replace property = 1 if off_cd_parent == "property"
	replace property = . if off_cd_parent == ""
	*public_order
	gen public_order = 0
	replace public_order = 1 if off_cd_parent == "public order"
	replace public_order = . if off_cd_parent == ""
	*violent
	gen violent = 0
	replace violent = 1 if off_cd_parent == "violent"
	replace violent = . if off_cd_parent == ""
	*assault
	gen assault = 0
	replace assault = 1 if off_cd_child == "assault"
	replace assault = . if off_cd_child == ""
	*burglary 
	gen burglary = 0
	replace burglary = 1 if off_cd_child == "burglary"
	replace burglary = . if off_cd_child == ""
	*driving related
	gen driving_related = 0
	replace driving_related = 1 if off_cd_child == "driving related"
	replace driving_related = . if off_cd_child == ""
	*drug trafficking
	gen drug_trafficking = 0
	replace drug_trafficking = 1 if off_cd_child == "drug trafficking"
	replace drug_trafficking = . if off_cd_child == ""
	*forgery/fraud
	gen forgery_fraud = 0
	replace forgery_fraud = 1 if off_cd_child == "forgery/fraud"
	replace forgery_fraud = . if off_cd_child == ""
	*larceny/theft
	gen larceny_theft = 0
	replace larceny_theft = 1 if off_cd_child == "larceny/theft"
	replace larceny_theft = . if off_cd_child == ""
	*motor vehicle theft
	gen motor_vehicle_theft = 0
	replace motor_vehicle_theft = 1 if off_cd_child == "motor vehicle theft"
	replace motor_vehicle_theft = . if off_cd_child == ""
	*murder
	gen murder = 0
	replace murder = 1 if off_cd_child == "murder"
	replace murder = . if off_cd_child == ""
	*other drug
	gen other_drug = 0
	replace other_drug = 1 if off_cd_child == "other drug"
	replace other_drug = . if off_cd_child == ""
	*other property
	gen other_property = 0
	replace other_property = 1 if off_cd_child == "other property"
	replace other_property = . if off_cd_child == ""
	*other public order
	gen other_public_order = 0
	replace other_public_order = 1 if off_cd_child == "other public order"
	replace other_public_order = . if off_cd_child == ""
	*other violent
	gen other_violent = 0
	replace other_violent = 1 if off_cd_child == "other violent"
	replace other_violent = . if off_cd_child == ""
	*rape
	gen rape = 0
	replace rape = 1 if off_cd_child == "rape"
	replace rape = . if off_cd_child == ""
	*robbery
	gen robbery = 0
	replace robbery = 1 if off_cd_child == "robbery"
	replace robbery = . if off_cd_child == ""
	*weapons
	gen weapons = 0
	replace weapons = 1 if off_cd_child == "weapons"
	replace weapons = . if off_cd_child == ""
	
	merge m:1 adj_st_ori_fips adj_cnty_ori_fips using `coverage' 
	keep if _merge == 3
	drop if event_year < coverage_start
	drop if event_year > coverage_end
	
	save "$tbldir\tex_figures\adjudication\tbl\top_75_roster_merged.dta", replace 

restore	


	
	
********************************************Generating CJARS Aggregate Statistics**************************************

*offense type - parent category
preserve
	drop if off_cd_parent == ""
	collapse (count) count, by(event_year off_cd_parent)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	tempfile adjudication_ouput_offenses_parent
	save `adjudication_ouput_offenses_parent'
restore

*offense type - child category
preserve
	drop if off_cd_child == ""
	collapse (count) count, by(event_year off_cd_child)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	tempfile adjudication_ouput_offenses_child
	save `adjudication_ouput_offenses_child'
restore

*age
preserve
	drop if off_cd_child == ""
	collapse (mean) age, by(event_year)
	temfile adjudication_ouput_age_any
	save `adjudication_ouput_age_any'
restore

*sex
preserve
	drop if off_cd_parent == ""
	drop if sex == .
	collapse (count) count, by(event_year sex)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	gen sex_str = "male" if sex == 1
	replace sex_str = "female" if sex == 2
	drop sex
	foreach x of var *{
		rename `x' `x'_
	}
	reshape wide freq total percentage, i(event_year) j(sex_str) string
	tempfile adjudication_ouput_sex_any
	save `adjudication_ouput_sex_any'
restore

*race
preserve
	drop if off_cd_parent == ""
	drop if race == . | race == 3 | race == 5 | race == 6
	collapse (count) count, by(event_year race)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	gen race_str = "white" if race == 1
	replace race_str = "black" if race == 2
	replace race_str = "hispanic" if race == 4
	replace race_str = "other" if inlist(race, 3, 5, 6)
	drop race
	foreach x of var *{
		rename `x' `x'_
	}
	reshape wide freq total percentage, i(event_year) j(race_str) string
	tempfile adjudication_ouput_race_any
	save `adjudication_ouput_race_any'
restore

*disposition
preserve
	drop if off_cd_child == ""
	gen dispo_cat = "convicted" if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI", "GU")
	replace dispo_cat = "dismiss" if inlist(adj_disp_cd, "ND", "NI")
	replace dispo_cat = "acquitted" if adj_disp_cd == "NA"
	replace dispo_cat = "diverted" if adj_disp_cd == "DU"
	drop if dispo_cat == ""
	collapse (count) count, by(event_year dispo_cat)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	foreach x of var *{
		rename `x' `x'_
	}
	reshape wide freq total percentage, i(event_year) j(dispo_cat) string
	tempfile adjudication_ouput_disposition_any
	save `adjudication_ouput_disposition_any'
restore

*time
preserve
	drop if off_cd_parent == ""
	gen dispo_cat = "convicted" if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI", "GU")
	keep if dispo_cat == "convicted"
	gen diff = sent_dt - disp_dt
	recode diff (0/1.999999999 = 1) (2/30.99999999 = 2) (31/60.9999999999 = 3) (61/999999999999 = 4), gen(diff_temp)
	gen diff_cat = "0to1_days" if diff_temp == 1
	replace diff_cat = "2to30_days" if diff_temp == 2
	replace diff_cat = "31to60_days" if diff_temp == 3
	replace diff_cat = "61_plus_days" if diff_temp == 4
	drop if diff_cat == ""
	collapse (count) count, by(event_year diff_cat)
	bysort event_year: gen yearly_running_total = sum(count)
	bysort event_year: egen total = max(yearly_running_total)
	drop yearly_running_total
	gen percentage = (count/total)*100
	rename count freq
	foreach x of var *{
		rename `x' `x'_
	}
	reshape wide freq total percentage, i(event_year) j(diff_cat) string
	tempfile adjudication_ouput_time_any
	save `adjudication_ouput_time_any'
restore

*incarceration
preserve
	drop if off_cd_parent == ""
	gen dispo_cat = "convicted" if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI", "GU")
	keep if dispo_cat == "convicted"
	drop if adj_sent_inc < 12 // need to get rid of life and death sentences and sentences that might be jail
	gen inc_length_mean = adj_sent_inc
	gen inc_length_median = adj_sent_inc
	collapse (mean) inc_length_mean (median) inc_length_median, by(event_year)
	tempfile adjudication_ouput_incarceration_any
	save `adjudication_ouput_incarceration_any'
restore

*probation
preserve
	drop if off_cd_parent == ""
	gen dispo_cat = "convicted" if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI", "GU")
	keep if dispo_cat == "convicted"
	drop if adj_sent_pro == 0
	gen pro_length_mean = adj_sent_pro
	gen pro_length_median = adj_sent_pro
	collapse (mean) pro_length_mean (median) pro_length_median, by(event_year)
	tempfile adjudication_ouput_probation_any
	save `adjudication_ouput_probation_any'
restore



*************************Further cleaning to produce more streamlined aggregate datasets****************************

*combining offense type
clear
use `adjudication_ouput_offenses_parent'
keep event_year off_cd_parent percentage
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename off_cd_parent offense
tempfile offenses_parent
save `offenses_parent'

clear
use `adjudication_ouput_offenses_child'
keep event_year off_cd_child percentage
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename off_cd_child offense
append using `offenses_parent'
rename event_year year
rename offense offense_type
rename percentage CJARS
tempfile offenses_cjars
save `offenses_cjars'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("offense")
do "$utility\offense_recode.do"
reshape long percent_, i(offense_type) j(year)
rename percent_ SCPS
merge 1:1 offense_type year using `offenses_cjars', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "offense"
tempfile offense
save `offense'


*age
clear
use `adjudication_ouput_age_any'
gen offense_type = "any"
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
rename age CJARS
tempfile age_any
save `age_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("age")
do "$utility\offense_recode.do"
*drop if offense_type == "forgery/fraud"
keep if offense_type == "any"
reshape long average_, i(offense_type) j(year)
rename average_ SCPS
merge 1:1 offense_type year using `age_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "age"
tempfile age
save `age'


*race
clear
use `adjudication_ouput_race_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year percentage_black percentage_hispanic percentage_white
reshape long percentage_, i(year) j(race) string
gen offense_type = "any"
rename percentage_ CJARS
tempfile race_any
save `race_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("race")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud"
reshape long black_ white_ hispanic_, i(offense_type) j(year)
rename (black_ white_ hispanic_) (percentage_black percentage_white percentage_hispanic)
reshape long percentage_, i(offense_type year) j(race) string
rename percentage_ SCPS
merge 1:1 offense_type year race using `race_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "race"
tempfile race
save `race'


*sex
clear
use `adjudication_ouput_sex_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year percentage_female percentage_male
reshape long percentage_, i(year) j(sex) string
gen offense_type = "any"
rename percentage_ CJARS
tempfile sex_any
save `sex_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("sex")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud"
reshape long male_ female_, i(offense_type) j(year)
rename (male_ female_) (percentage_male percentage_female)
reshape long percentage_, i(offense_type year) j(sex) string
rename percentage_ SCPS
merge 1:1 offense_type year sex using `sex_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "sex"
tempfile sex
save `sex'


*disposition
clear
use `adjudication_ouput_disposition_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year percentage_*
reshape long percentage_, i(year) j(dispo) string
gen offense_type = "any"
rename percentage CJARS
tempfile dispo_any
save `dispo_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("dispo")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud"
reshape long convict_ dismiss_ acquit_ divert_, i(offense_type) j(year)
rename (convict_ dismiss_ acquit_ divert_) (percentage_convicted percentage_dismiss percentage_acquitted percentage_diverted)
reshape long percentage_, i(offense_type year) j(dispo) string
rename percentage_ SCPS
merge 1:1 offense_type year dispo using `dispo_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "disposition"
tempfile dispo
save `dispo'


*time
clear
use `adjudication_ouput_time_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year percentage_*
reshape long percentage_, i(year) j(time) string
gen offense_type = "any"
replace time = subinstr(time, "_days", "", .) 
replace time = "one_day" if time == "0to1"
replace time = "one_month" if time == "2to30"
replace time = "two_months" if time == "31to60"
replace time = "two_plus" if time == "61_plus"
rename percentage_ CJARS
tempfile time_any
save `time_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("time")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud" | offense_type == ""
reshape long one_day_ one_month_ two_months_ two_plus_, i(offense_type) j(year)
rename (one_day_ one_month_ two_months_ two_plus_) (percentage_one_day percentage_one_month percentage_two_months percentage_two_plus)
reshape long percentage_, i(offense_type year) j(time) string
rename percentage_ SCPS
merge 1:1 offense_type year time using `time_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "timing"
tempfile time
save `time'


*incarceration
clear
use `adjudication_ouput_incarceration_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year inc_*
reshape long inc_length_, i(year) j(inc) string
gen offense_type = "any"
rename inc_length_ CJARS
tempfile inc_any
save `inc_any'

clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("inc")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud"
reshape long mean_ median_, i(offense_type) j(year)
rename (mean_ median_) (inc_length_mean inc_length_median)
reshape long inc_length_, i(offense_type year) j(inc) string
rename inc_length_ SCPS
merge 1:1 offense_type year inc using `inc_any', nogen
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "incarceration"
tempfile inc
save `inc'


*probation
clear
use `adjudication_ouput_probation_any'
keep if inlist(event_year, 1996, 1998, 2000, 2002, 2004, 2006, 2009)
rename event_year year
keep year pro_*
reshape long pro_length_, i(year) j(pro) string
gen offense_type = "any"
rename pro_length_ CJARS
tempfile pro_any
save `pro_any'


clear
import excel using "$scpsdir\1996_2009_scps (collapsed forgery fraud).xlsx", firstrow sheet("pro")
do "$utility\offense_recode.do"
drop if offense_type == "forgery/fraud"
reshape long mean_ median_, i(offense_type) j(year)
rename (mean_ median_) (pro_length_mean pro_length_median)
reshape long pro_length_, i(offense_type year) j(pro) string
rename pro_length_ SCPS
merge 1:1 offense_type year pro using `pro_any', nogen
drop if SCPS == .
egen std_CJARS = std(CJARS)
egen std_SCPS = std(SCPS)
gen source = "probation"
tempfile pro
save `pro'


*appending all outcomes of interest into a single combined file
clear
use `age'
append using `race'
append using `sex'
append using `dispo'
append using `time'
append using `inc'
append using `pro'
append using `offense'
drop CJARS SCPS
rename std_CJARS CJARS
rename std_SCPS SCPS
drop if CJARS == . | SCPS == .
export delimited using "$tbldir\tex_figures\adjudication\tbl\adjudication_ouput_combined.csv", replace



