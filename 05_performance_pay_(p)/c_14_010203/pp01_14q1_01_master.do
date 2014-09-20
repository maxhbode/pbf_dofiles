/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PROJECT:      SEWA Bank
PURPOSE:      Do-file Directory
PROGRAMMER:   Max Bode (EPoD, CID, HU)
DATE:         18 Jun 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

set more off
set linesize 225

*************************************************************************
* Command Bridge
*************************************************************************

* Truecrypt mounting on/off
*------------------------------------------------------

loc dir "/03_performance_pay(p)/03_performancepay_calc(pp)/2014q1"

local TRUECRYPT 0
* Truecrypt volumes get mounted trough running the "01 intro.do" file.
* IF TRUECRYPT==0 then volumes are not mounted in "01 intro.do".
if "/03_performance_pay(p)/03_performancepay_calc(pp)/2014q1" != "" local TRUECRYPT "/03_performance_pay(p)/03_performancepay_calc(pp)/2014q1"
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
runcopy, file("pp01_14q1_01_master") loc("$DO/`dir'") back("$DO_B/`dir'") `onlycopy'

* pp03a_pay_calculate_14q1_m
loc ++i
runcopy, file("pp03a_pay_calculate_14q1_m") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp03a_pay_calculate_14q1_m
/*
* pp03b_pay_analyze_14q1_m
loc ++i
runcopy, file("pp03b_pay_analyze_14q1_m") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp03b_pay_analyze_14q1_m
*/
* pp04a_bonus_calculate_q_14q1
loc ++i
runcopy, file("pp04a_bonus_calculate_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp04a_bonus_calculate_q_14q1
/*
* pp04b_bonus_analyze_q_14q1
loc ++i
runcopy, file("pp04b_bonus_analyze_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp04b_bonus_analyze_q_14q1
*/
* pp04c_bonus_outsheet_q_14q1
loc ++i
runcopy, file("pp04c_bonus_outsheet_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp04c_bonus_outsheet_q_14q1

* pp05a_phcu_calculate_q_14q1
loc ++i
runcopy, file("pp05a_phcu_calculate_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp05a_phcu_calculate_q_14q1
/*
* pp05b_phcu_analyze_q_14q1
loc ++i
runcopy, file("pp05b_phcu_analyze_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp05b_phcu_analyze_q_14q1
*/
* pp05c_phcu_outsheet_q_14q1
loc ++i
runcopy, file("pp05c_phcu_outsheet_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp05c_phcu_outsheet_q_14q1

* pp06_all_outsheet_q_14q1
loc ++i
runcopy, file("pp06_all_outsheet_q_14q1") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp06_all_outsheet_q_14q1

* pp06a_all_analyze
loc ++i
runcopy, file("pp06a_all_analyze") loc("$DO/`dir'") back("$DO_B/`dir'") `runcopy'
master_describe_tool `i' pp06a_all_analyze

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

