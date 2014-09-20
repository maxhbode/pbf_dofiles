/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT:      SEWA Bank
PURPOSE:      Do-file Directory
PROGRAMMER:   Max Bode (EPoD, CID, HU)
DATE:         23 Jun 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set more off
set linesize 225
set graphics off

*************************************************************************
* Command Bridge
*************************************************************************

* Truecrypt mounting on/off
*------------------------------------------------------

loc dir "06_comparison(c)"

local TRUECRYPT 0
* Truecrypt volumes get mounted trough running the "01 intro.do" file.
* IF TRUECRYPT==0 then volumes are not mounted in "01 intro.do".
if "06_comparison(c)" != "" local TRUECRYPT "06_comparison(c)"
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
runcopy, file("c01_master") loc("$DO/`dir'") back("$DO_B/`dir'") `onlycopy'

* c02_prepare
loc ++i
runcopy, file("c02_prepare") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' c02_prepare

* c03a_randomization
loc ++i
runcopy, file("c03a_randomization") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' c03a_randomization

* c03b_psm
loc ++i
runcopy, file("c03b_psm") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' c03b_psm

* c04_balance
loc ++i
runcopy, file("c04_balance") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' c04_balance

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

