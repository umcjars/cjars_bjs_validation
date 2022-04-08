/*==============================================================================
Build aggregate caseload information for adjudication, incarceration, probation, and parole records in CJARS
to compare against BJS statistical series.
==============================
==============================================================================*/

clear

global datadir 			"cjars\2021q1"
global utility 			"utility"
global tbldir 			"output"

global scpsdir 			"validation_data\SCPS" /* BJS State Court Processing Statistics program */
global npsdir 			"validation_data\NPS" /* BJS National Prisoner Statistics program */
global ncrpdir 			"validation_data\NCRP" /* BJS National Corrections Reporting Program */
global aprosdir 		"validation_data\APS\Annual_Probation_Survey" /* BJS Annual Probation Survey */
global aparsdir 		"validation_data\APS\Annual_Parole_Survey" /* BJS Annual Parole Survey */


local today c(current_date)
display `today'

foreach event_type in adjudication probation incarceration parole{
	do processing_files\\`event_type'_event_counts.do
}

/* End of file*/
