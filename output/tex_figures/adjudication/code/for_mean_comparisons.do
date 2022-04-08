
	
********************************************Generating Output**************************************
cd "$tbldir\tex_figures\adjudication\tbl"

global var_list age white black hispanic race_other male female diverted dismissal convicted time incarceration probation drug property public_order violent /*assault burglary driving_related drug_trafficking forgery_fraud larceny_theft motor_vehicle_theft murder other_drug other_property other_public_order other_violent rape robbery weapons*/ 

/**** CJARS ****/
clear 
use "top_75_roster_merged.dta", replace

recode race (1 = 1) (2 = 0) (3 = 0) (4 = 0) (5 = 0) (6 = 0) (. = .), gen(white)
recode race (1 = 0) (2 = 1) (3 = 0) (4 = 0) (5 = 0) (6 = 0) (. = .), gen(black)
recode race (1 = 0) (2 = 0) (3 = 0) (4 = 1) (5 = 0) (6 = 0) (. = .), gen(hispanic)
gen race_other = white == 0 & black == 0 & hispanic == 0

recode sex (1 = 1) (2 = 0) (. = .), gen(male)
recode sex (1 = 0) (2 = 1) (. = .), gen(female)

gen convicted = 0
replace convicted = 1 if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI", "GU")
replace convicted = . if adj_disp_cd == "UU" 

gen dismissal = 0
replace dismissal = 1 if inlist(adj_disp_cd, "ND", "NI")
replace dismissal = . if adj_disp_cd == "UU" 

gen acquittal = 0
replace acquittal = 1 if adj_disp_cd == "NA"
replace acquittal = . if adj_disp_cd == "UU" 

gen diverted = 0
replace diverted = 1 if adj_disp_cd == "DU"
replace diverted = . if adj_disp_cd == "UU" 

gen incarceration = adj_sent_inc if adj_sent_inc >= 12
gen probation = adj_sent_pro if adj_sent_pro > 0

gen time = sent_dt - disp_dt
replace time = . if time < 0 | time > 730

egen juris_id = group( adj_st_ori_fips adj_cnty_ori_fips)
gen 	county = adj_st_ori_fips*1000 + adj_cnty_ori_fips 
gen N = 1
collapse (mean) $var_list (sum) N, by(juris_id county event_year)
gen source = "cjars"
tempfile cjars_data
save "`cjars_data'"




/**** SCPS ****/

clear 
use "SCPS_all_years.dta" 

*age 
replace age  = . if age > 90

*race
recode racehisp (1 = 1) (2 = 0) (3 = 0) (4 = 0) (9 = .), gen(white)
recode racehisp (1 = 0) (2 = 1) (3 = 0) (4 = 0) (9 = .), gen(black)
recode racehisp (1 = 0) (2 = 0) (3 = 0) (4 = 1) (9 = .), gen(hispanic)
gen race_other = white == 0 & black == 0 & hispanic == 0

*gender
recode gender (1 = 1) (2 = 0) (9 = .), gen(male)
recode gender (1 = 0) (2 = 1) (9 = .), gen(female)

*disposition
recode adjtype (1 = 0) (2 = 0) (3 = 1) (4 = 0) (5 = 0) (6 = 0) (8 = .) (9 = .), gen(diverted)
recode adjtype (1 = 1) (2 = 0) (3 = 0) (4 = 0) (5 = 0) (6 = 0) (8 = .) (9 = .), gen(dismissal)
recode adjtype (1 = 0) (2 = 0) (3 = 0) (4 = 1) (5 = 1) (6 = 0) (8 = .) (9 = .), gen(convicted)
recode adjtype (1 = 0) (2 = 1) (3 = 0) (4 = 0) (5 = 0) (6 = 0) (8 = .) (9 = .), gen(acquittal)

*time
gen time = adjsent
replace time = . if adjsent == 888 | adjsent == 999

*incarceration
gen incarceration = prismax
replace incarceration = . if prismax > 1440

*probation
gen probation = probmths
replace probation = . if probmths > 688

*assault
gen assault = 0
replace assault = 1 if offense1 == 4
replace assault = . if inlist(offense1, ., 99)
*burglary
gen burglary = 0
replace burglary = 1 if offense1 == 6
replace burglary = . if inlist(offense1, ., 99)
*driving
gen driving_related = 0
replace driving_related = 1 if offense1 == 15
replace driving_related = . if inlist(offense1, ., 99)
*drug
gen drug = 0
replace drug = 1 if offtype1 == 3
replace drug = . if inlist(offtype1, ., 9)
*drug_trafficking
gen drug_trafficking = 0
replace drug_trafficking = 1 if offense1 == 12
replace drug_trafficking = . if inlist(offense1, ., 99)
*forgery
gen forgery_fraud = 0
replace forgery_fraud = 1 if offense1 == 9
replace forgery_fraud = . if inlist(offense1, ., 99)
*larceny
gen larceny_theft = 0
replace larceny_theft = 1 if offense1 == 7
replace larceny_theft = . if inlist(offense1, ., 99)
*motor_vehicle_theft
gen motor_vehicle_theft = 0
replace motor_vehicle_theft = 1 if offense1 == 8
replace motor_vehicle_theft = . if inlist(offense1, ., 99)
*murder
gen murder = 0
replace murder = 1 if offense1 == 1
replace murder = . if inlist(offense1, ., 99)
*other_drug
gen other_drug = 0
replace other_drug = 1 if offense1 == 13
replace other_drug = . if inlist(offense1, ., 99)
*other_property
gen other_property = 0
replace other_property = 1 if offense1 == 11
replace other_property = . if inlist(offense1, ., 99)
*other_public_order
gen other_public_order = 0
replace other_public_order = 1 if offense1 == 16
replace other_public_order = . if inlist(offense1, ., 99)
*other_violent
gen other_violent = 0
replace other_violent = 1 if offense1 == 5
replace other_violent = . if inlist(offense1, ., 99)
*property
gen property = 0
replace property = 1 if offtype1 == 2
replace property = . if inlist(offtype1, ., 9)
*public_order
gen public_order = 0
replace public_order = 1 if offtype1 == 4
replace public_order = . if inlist(offtype1, ., 9)
*rape
gen rape = 0
replace rape = 1 if offense1 == 2
replace rape = . if inlist(offense1, ., 99)
*robbery
gen robbery = 0
replace robbery = 1 if offense1 == 3
replace robbery = . if inlist(offense1, ., 99)
*violent
gen violent = 0
replace violent = 1 if offtype1 == 1
replace violent = . if inlist(offtype1, ., 9)
*weapons
gen weapons = 0
replace weapons = 1 if offense1 == 14
replace weapons = . if inlist(offense1, ., 99)

rename year event_year
egen juris_id = group(state county)
gen N = 1
collapse (mean) $var_list (sum) N [pw=totalwt], by(juris_id event_year county)
gen source = "scps"
tempfile scps_data
save "`scps_data'"


clear
use "`cjars_data'"
append using "`scps_data'"

egen group = group(county)
gen scps = source == "scps"

eststo clear
foreach measure in $var_list {
	reg `measure' scps i.event_year##i.county [pw=N]   , cluster(group)
	eststo
}
esttab using "means_comparison_pval.csv", replace nostar noobs p  noparentheses nogaps keep(scps)
esttab using "means_comparison_se.csv", replace nostar noobs se  noparentheses nogaps n keep(scps)
breaaak



tsset juris_id event_year 
foreach measure in $var_list {
	display "`measure'"
	eststo clear
	reg `measure'  , vce(bootstrap)
	eststo 
	reg `measure' if event_year > 1994  , vce(bootstrap)
	eststo 
	foreach year in 1990 1992 1994 1996 1998 2000 2002 2004 2006 2009{
		reg `measure' if event_year == `year'  , vce(bootstrap)
		eststo
	}
	esttab using "means_`measure'.csv", replace nostar noobs se plain
}

