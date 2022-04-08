# CJARS BJS Validation

This repository contains the validation infrastructure to benchmark the Criminal Justice Administrative Records System (CJARS) against published statistical information on criminal justice caseloads from the Bureau of Justice Statistics (BJS).

The execution of the scripts in this repository process CJARS data and produce tables and figures that depict the comparison of aggregate statistics generated using CJARS data and other BJS benchmarking data resources.

The benchmarking pipeline consists of two major processes: (1) processing scripts to produce aggregate statistics and (2) generation of output (tables and figures) to convey comparisons between CJARS and other BJS benchmarking data resources.

Primary scripts in each of these major processes are described below.

## Processing Files

Producing aggregate estimates on caseload composition and counts of events occurring in the justice system serve as the main effort to benchmark the CJARS data infrastructure.

A set of scripts are used to produce aggregate statistics for the CJARS relational tables (i.e., adjudication, incarceration, probation, and parole). The purpose of each script is described below. 

1. `/processing_files/adjudication_event_counts.do`
	- Creates a subset of the CJARS adjudication relational table that is comparable to samples from the State Court Processing Statistics (SCPS) data series
	- Recodes data from the CJARS adjudication relational table to create comparable information (e.g., type of offense) to SCPS data
	- Produces aggregate caseload composition statistics and event counts using CJARS data
	- Processes aggregate caseload composition statistics and event counts using SCPS data
	- Merges aggregate statistics produced using CJARS and SCPS to create a combined dataset that facilitates comparison across the two data sources

2. `/processing_files/incarceation_event_counts.do`
	- Processes and analyzes the CJARS incarceration relational table to create an aggregated set of jurisdiction-by-year incarceration entry counts
	- Processes and analyzes data from the National Prisoner Statistics (NPS) program and National Corrections Reporting Program (NCRP) to create an aggregated set of jurisdiction-by-year counts of incarceration entries
	- Merges aggregate jurisdiction-by-year incarceration entry count statistics produced using CJARS, NPS, and NCRP to create a combined dataset that facilitates comparison across the three data sources

3. `/processing_files/probation_event_counts.do`
	- Processes and analyzes the CJARS probation relational table to create an aggregated set of jurisdiction-by-year probation entry counts
	- Processes and analyzes data from the Annual Probation Survey to create an aggregated set of jurisdiction-by-year probation entry counts
	- Merges aggregate jurisdiction-by-year probation entry count statistics produced using CJARS and the Annual Probation Survey to create a combined dataset that facilitates comparison across the two data sources

4. `/processing_files/parole_event_counts.do`
	- Processes and analyzes the CJARS parole relational table to create an aggregated set of jurisdiction-by-year parole entry counts
	- Processes and analyzes data from the Annual Parole Survey to create an aggregated set of jurisdiction-by-year parole entry counts
	- Merges aggregate jurisdiction-by-year parole entry count statistics produced using CJARS and the Annual Parole Survey to create a combined dataset that facilitates comparison across the two data sources
	
All of these processing files are executed through a single script - `build_aggregate_counts.do`. This script sets a series of globals and then executes each of the aformentioned processing files.
	
The processing files listed above call on a number of files contained in folders in this repository. These are described below:

1. `cjars`
	- This folder is empty in this repository, but would include the CJARS databases that are available through the U.S. Census Bureau's Federal Statistical Data Center (FSRDC) network. To execute the processing files, you would need to copy the CJARS databases available through the FSRDC network. These files include:
		+ `cjars_roster_2021q1.sas7bdat`
		+ `cjars_coverage_2021q1.sas7bdat`
		+ `cjars_adjudication_2021q1.sas7bdat`
		+ `cjars_incarceration_2021q1.sas7bdat`
		+ `cjars_probation_2021q1.sas7bdat`
		+ `cjars_parole_2021q1.sas7bdat`

2. `utility`
	- This folder contains a number of utility files called on by the processing files. A short description of each file is included below:
		+ `fips_to_name.do` - converts state fips codes to the name of each state to facilitate readibility
		+ `offense_recode.do` - recodes offense codes in the CJARS offense schema (Unified Crime Classification Standard) to match the offense coding schema used in BJS validation data
		+ `/Census/County_population_2000_2010 (Intercensal).csv` - publicly available county-level population estimates
		
3. `validation_data`
	- This folder contains publicly available benchmarking data resources. The files in this directory were either directly downloaded from a publicly available source or are a compiled/processed version of publicly available data or published statistics. Each file in this directory is described below and links are provided to the sources of relevant information.
		+ `SCPS/1996_2009_scps (collapsed forgery fraud).xlsx` - This file contains a compiled set of published caseload composition statistics from BJS's *Felony Defendants in Large Urban Counties* publication series. This file was hand coded based on the statistics in available published reports. Reports from this publication series are available from: https://bjs.ojp.gov/library/publications/list?series_filter=Felony%20Defendants%20in%20Large%20Urban%20Counties.
		+ `NPS/37639-0001-Data.dta` - This file includes a comprehensive database of *National Prisoner Statistics* program data covering 1978-2018. Available from: https://www.icpsr.umich.edu/web/NACJD/studies/37639.
		+ `NPS/37639-0001-Supplemental_syntax.dta` - This file includes syntax provided by ICPSR to process `NPS/37639-0001-Data.dta`. Available from: https://www.icpsr.umich.edu/web/NACJD/studies/37639.
		+ `NCRP/37021-0002-Data.dta` - This file includes a comprehensive database of *National Corrections Reporting Program* data covering 1991-2016. It is not included in this respository because it is large. But it is available from: https://www.icpsr.umich.edu/web/NACJD/studies/37021.
		+ `NCRP/37021-0002-Supplemental_syntax.dta` - This file includes syntax provided by ICPSR to process `NCRP/37021-0002-Data.dta`. Available from: https://www.icpsr.umich.edu/web/NACJD/studies/37021.
		+ `APS/Annual_Probation_Survey/probation_totals.dta` - This file includes a comprehensive database of *Annual Probation Survey* data covering 1994-2016. This file was generated by appending all available waves of *Annual Probation Survey* data available from: https://www.icpsr.umich.edu/web/NACJD/series/327.
		+ `APS/Annual_Parole_Survey/parole_totals.dta` - This file includes a comprehensive database of *Annual Parole Survey* data covering 1994-2016. This file was generated by appending all available waves of *Annual Parole Survey* data available from: https://www.icpsr.umich.edu/web/NACJD/series/328.

## Benchmarking Output

The aggregated statistics produced using CJARS and all relevant benchmarking data sources are used to create a set of tables and figures to assist with the interpretation of the output.

The scripts used to produce these tables and figures are outlined below.

1. `/output/tex_figures/adjudication/`
	- `code/adjudication.tex`
		+ Generates figure comparing aggregate statistics produced using CJARS and SCPS
	- `code/for_mean_comparisons.do`
		+ Compares statistical equivalence of aggregate statistics produced using CJARS and SCPS through a series of regression models. Notably, output files produced using this script are not included in this repository because of data use agreement restrictions.
		+ It is important to note that there are two files called on in this script that cannot be shared in this public repository: `top_75_roster_merged.dta` and `SCPS_all_years.dta`. The file `top_75_roster_merged.dta` can be produced by executing `/processing_files/adjudication_event_counts.do`, however, it cannot be shared publicly because it includes micro-level CJARS data. The file `SCPS_all_years.dta` cannot be shared publicly because it is restricted-access and must be requested through ICPSR. Requests can be made through: https://www.icpsr.umich.edu/web/NACJD/studies/2038.
	- `tbl/adjudication_output_combined.csv`
		+ Aggregate data used to produce figure comparing CJARS and SCPS

2. `/output/tex_figures/incarceration/`
	- `code/incarceration.tex`
		+ Generates figures comparing aggregate statistics produced using CJARS, NPS, and NCRP
	- `tbl/incarceration_event_counts_entries_all.csv`
		+ Aggregate data used to produce figures comparing CJARS, NPS, and NCRP

3. `/output/tex_figures/probation/`
	- `code/probation.tex`
		+ Generates figures comparing aggregate statistics produced using CJARS and the Annual Probation Survey
	- `tbl/probation_event_counts_entries_all.csv`
		+ Aggregate data used to produce figures comparing CJARS and the Annual Probation Survey

4. `/output/tex_figures/parole/`
	- `code/parole.tex`
		+ Generates figures comparing aggregate statistics produced using CJARS and the Annual Parole Survey
	- `tbl/parole_event_counts_entries_all.csv`
		+ Aggregate data used to produce figures comparing CJARS and the Annual Parole Survey

























