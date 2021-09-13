# check-running-itcam-datacollectors
This scripts displays the status and the installed version of the running ITCAM data collectors. 
Author: Richard Niewolik

Contact: niewolik@de.ibm.com

Revision: 2.2

#

[1 General](#1-general)

[2 Installation](#2-installation)

[3 Usage](#3-usage)

[3.1 Syntax](#syntax)


#

1 General
=========

Often, multiple ITCAM Data Collector for WebSphere are running on one host. Sometimes they are not all configured with the same version. And sometimes the version the data collector is running with is not the configured version. To check this, several steps are required. You can use this script to quickly check the configuration and operational status. This is especially helpful if you want to migrate or update an existing installation.

 
2 Installation
==============

Download the latest release of the script [here](https://github.com/ricniew/check-running-itcam-datacollectors/releases) and unzip to a temporary directory on the host were your ITCAM Agent\+Datacollector and WebSPhere server are running. It contains following files:

-   Shell procedure *check-itcam.sh*\
    This is the procedure to use.

-   This README document

Supported Operating System
--------------------------

Procedure was tested on UNIX AIX and Linux Redhat but should run on all
UNIX and Linux Operating systems. The required shell is *bash*. It is
not running on Windows.

The ITCAM for WebSphere agent and Data Collector (DC) must be installed.
The tested versions have been 7.2 and 7.3.


3 Usage
=======

Syntax
------

> check-itcam.sh { -h WAS home }

    -h    home directory

Example:
> $ check-itcam.sh  -h /opt/IBM/WebSphere/AppServer
          
Sample execution flow
----------------------

    bash-5.0$ /dmz_sw/itm/itmtools/itcam_check.sh -h /usr/WebSphere85/ProcServer/
    INFO Script Version 2
    INFO Check options
    INFO WASHOME=/usr/WebSphere85/ProcServer/
    INFO WSADMIN_HOME=/usr/WebSphere85/ProcServer//bin
    INFO Collecting required data from WebSphere using wsadmin
    INFO Executing /usr/WebSphere85/ProcServer//bin/wsadmin.sh -lang jython -f tmp.itcamdc.wsadminScript.py
    INFO Data successfully collected from WebSphere
    INFO   CellMgrHostname=dmgr.bavaria.com
    INFO   Cellname=ProcStageCell
    INFO   Nodename=ProcStageNode01
    INFO   Running on host stage.munich.com
    INFO   DMGR SOAP connector address returned by wsadmin is: 18880
    INFO Collecting profile information using manageprofiles.sh
    INFO Existing profiles: StageNode01.
    INFO PROFILENAME=StageNode01
    -----------------------------
    INFO Display Server's status
    INFO for /usr/WebSphere85/ProcServer/:
    INFO     StageProcSupport         running    PID=22806952 DCHOME=/opt/IBM/ITM/yn/aix533/yn/wasdc/7.2.0.0.17/itcamdc
    INFO     StageProcMsg             running    PID=15860206 DCHOME=/opt/IBM/ITM/yn/aix533/yn/wasdc/7.2.0.0.17/itcamdc
    INFO     StageProc01              running    PID=19726692 DCHOME=/opt/IBM/ITM/yn/wasdc/7.2.0.0.17/itcamdc
    INFO     StageProc01_2            running    PID=13566282 DCHOME=/opt/IBM/ITM/yn/wasdc/7.2.0.0.17/itcamdc
    --------------------------------------------------
    INFO "server.xml" shows DC Versions configured:
    INFO     StageProcSupport        7.2.0.0.17
    INFO     StageProcMsg            7.2.0.0.17
    INFO     StageProc01             7.2.0.0.17
    INFO     StageProc01_2           7.2.0.0.17
    INFO procedure successfully ended
    bash-5.0$

