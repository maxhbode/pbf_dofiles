/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT:      SEWA Bank
PURPOSE:      Do-file Directory
PROGRAMMER:   Max Bode (EPoD, CID, HU)
DATE:         04 Jun 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set more off
set linesize 225

*************************************************************************
* Command Bridge
*************************************************************************

* Truecrypt mounting on/off
*------------------------------------------------------

loc dir "02_treatment(t)/03_cleaning(tc)"

local TRUECRYPT 0
* Truecrypt volumes get mounted trough running the "01 intro.do" file.
* IF TRUECRYPT==0 then volumes are not mounted in "01 intro.do".
if "02_treatment(t)/03_cleaning(tc)" != "" local TRUECRYPT "02_treatment(t)/03_cleaning(tc)"
      * this argument is being passed on from the master files if they are run.

* runcopy option controls
*------------------------------------------------------
local RUN             1
local COPY            0
local OUTSHEET        0
local RUNSTATS        0

if `RUN' == 0 local norun norun
else if `RUN' == 1 local norun

if `COPY' == 0 local nocopy nocopy
else if `COPY' == 1 local nocopy

* Select options for runcopy
*------------------------------------------------------
* The argument master_skiptruecryptmount sets the local 
* TRUECRYPT in the respective .do file to 0.
local runcopy "timestamp `norun' `nocopy' replace arg("master_skiptruecryptmount")"
local onlycopy "timestamp norun `nocopy' replace arg("master_skiptruecryptmount")"

*************************************************************************
* Do-Files
*************************************************************************

*Setting counter for -master_describe-
loc i = 0

* 01. intro
runcopy, file("01 intro") loc("$DO/") back("$DO_B/") `onlycopy' 

* 02. master
runcopy, file("tc_01_master") loc("$DO/`dir'") back("$DO_B/`dir'") `onlycopy'

* tc_02_merge
loc ++i
runcopy, file("tc_02_merge") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' tc_02_merge

* tc_03_clean
loc ++i
runcopy, file("tc_03_clean") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' tc_03_clean

* tc_04_manipulate
loc ++i
runcopy, file("tc_04_manipulate") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' tc_04_manipulate

* tc_05_label
loc ++i
runcopy, file("tc_05_label") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' tc_05_label

* tc_06_outsheet
loc ++i
runcopy, file("tc_06_outsheet") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' tc_06_outsheet

* Number of observations and variables after execution of dofile
if `RUN'==1 {
      foreach X in N k doname {
              loc `X'
              forval ii = 1/`i' {
                      loc `X' ``X'' ``X'`ii'' 
              }
      }

      master_describe, obs(`N') var(`k')  rown(`doname')
}

* NOTE THAT THIS DOFILE WAS CREATED BY THE PROGRAM -master-.

