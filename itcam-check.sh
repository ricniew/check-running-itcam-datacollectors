#!/bin/bash
#set -x
###################################################################
# R. Niewolik IBM AVP
###################################################################
# 22.04.2021: R. Niewolik  Initial version V1.0
# Display ITCAM Data Collector version and server status
# Usage:
#        $PROGNAME { -h WAS home } "
# Example:  $PROGNAME -h /usr/WebSphere/Appserver
###################################################################
#
echo " INFO Script Version 2"
#
PROGNAME=$(basename $0)
USRCMD="$0 $*"
#echo " INFO \"${USRCMD}\" used"

#############
# Functions #
#############
#--------
Usage()
{ # usage description
echo ""
echo " Usage:"
echo "  $PROGNAME { -h WAS home } "
exit 99
}

#----------------------
CheckAndDisplayStatus()
{
     echo " -----------------------------"
     echo " INFO Display Server's status "
     echo " INFO for ${WASHOME}:"
     rc=0
     server=`grep "Server:" ${WAS_CONFDATA} | awk '{ print $2, "," $3 }'`
     i=0
     for srv in ${server//,/}
         do
           jvm="${srv%%/*}"
           jvmStatus="${srv#*/}"
           jvmStatus=$(echo $jvmStatus | tr -d ' ')
           if [ "$jvmStatus" == "not-running" ] ; then
               #printf " WARNING  %-30s %-10s Server not running \n" $jvm  $jvmStatus
               printf " WARNING  %-20s %-20s \n" $jvm $jvmStatus  
               SERVERLIST_TMP[$i]="$jvm"
           else
               psout=`ps -ef | grep $WASHOME | grep java | grep "$jvm$" | awk '{ n=split($0,a); for (x = 1; x <=n ; x++) {if ( match(a[x], "(^-Dam.home=)") ) { sub(/-Dam.home=/," ",a[x]); printf "%s %s\t", $2, a[x]}} print ""}'`
               if  [ "${psout}" == "" ] ; then
                   printf " INFO     %-30s %-10s No ITCAM version found in CMD (DC configed but not restarted or CMD too long and cut off) \n" $jvm  $jvmStatus 
               else
                   printf " INFO     %-30s %-10s PID=%s DCHOME=%s\n" $jvm  $jvmStatus $psout
               fi 
               SERVERLIST[$i]="$jvm"
               SERVERLIST_TMP[$i]="$jvm"
           fi
           i=$((i+1))
     done

     #echo " -debug - The running process uses:"
     #ps -ef|grep java|grep wasdc| sed 's/\(.*\).* - .*wasdc\/\(.*\)\/itcam.*/\1 \2/'
     
     return $rc
}


#-----------------------------
CheckRunningServerDcConfig ()
{
     rc=0
     i=0
     array_t=("${SERVERLIST_TMP[@]}")
     echo "--------------------------------------------------"
     echo " INFO \"server.xml\" shows DC Versions configured:"
     #echo "- debug was.appserver.profile.name=${PROFILENAME}"
     #echo "- debug was.appserver.home=${WASHOME}"
     #echo "- debug was.appserver.cell.name=${CELLNAME}"
     #echo "- debug was.appserver.node.name=${NODENAME}"
     for srv in "${SERVERLIST_TMP[@]}"
     do
       name="$srv"
       if [ "${PROFILENAME}" == "wp_profile" ] ; then
          temp=`dirname ${WASHOME}`
          FINDDIR="${temp}/wp_profile/config/cells/${CELLNAME}/nodes/${NODENAME}/servers/${name}"
       else
          FINDDIR="${WASHOME}/profiles/${NODENAME}/config/cells/${CELLNAME}/nodes/${NODENAME}/servers/${name}"
       fi

       #echo "- debug ${FINDDIR}"
       #echo "- debug executing: find  ${FINDDIR} -name server.xml -exec grep -i \"name=\\\"am.home\" {} \; | cut -d'\"' -f6"
       dcconfig=`find  ${FINDDIR} -name server.xml -exec grep -i "name=\"am.home" {} \; | cut -d'"' -f6`
       #echo "$dcconfig"
       if  [ "${dcconfig}" == "" ] ; then
           configuredVersion="notDCconfigured"
       else
           configuredVersion=`echo ${dcconfig} |sed 's/.*\/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.[0-9]\{1,3\}\)\/.*/\1/'`
       fi
       printf " INFO     %-30s %-20s \n" $srv $configuredVersion 
     done

     return 0
}

#--------------------
CreateWsadminScript()
{
     cat <<EOF > ${WSADMIN_SCRIPT}
import re
import os
import socket
import sys
import java
import java.util as util
import java.io as javaio

def GetShorthostname(provided_name):
    match=re.search("^(\w+)(\.\w+)(\.\w+)*$", provided_name)
    if match:
        shortname=match.group(1)
    else:
        shortname=provided_name
    #endif
    return str(shortname)

rc=0
# get DMGR name
dmgrname=AdminControl.queryNames('WebSphere:name=DeploymentManager,*')
#  WebSphere:name=DeploymentManager,process=dmgr,platform=common,node=e200n-z1tl0001,diagnosticProvider=true,version=
match=re.search("node=([^\,]*)",dmgrname)
if match:
     dmgrnode=match.group(1)
     print "DmgrNode: " + dmgrnode
#endif

# get Cell name
cellname=AdminControl.getCell()
print "Cellname: " + cellname

# get Node name, Dmgr hostname and soap connector port
system_name = GetShorthostname(socket.gethostname())
nodes=AdminConfig.list('Node').splitlines()
nodefound = 0
dmgrhostfound = 0
dmgrportfound = 0
for node_id in nodes:
    #node_id=AdminConfig.getid("/Node:"+node_name+"/")
    node_name=AdminConfig.showAttribute(node_id,'name')
    nodehost=AdminConfig.showAttribute(node_id,'hostName')
    dmgrmatch=re.search(dmgrnode, node_name)
    #print "---" + node_name  + "--" + dmgrnode
    if dmgrmatch:
        dmgrhostfound = 1
        print "CellMgrHostname: " + nodehost
        #print "CellMgrNodeId: " + node_id
        NamedEndPoints = AdminConfig.list( "NamedEndPoint" , node_id).split(lineSeparator)
        for namedEndPoint in NamedEndPoints:
            endPointName = AdminConfig.showAttribute(namedEndPoint, "endPointName" )
	    if endPointName == 'SOAP_CONNECTOR_ADDRESS':
                dmgrportfound = 1
                endPoint = AdminConfig.showAttribute(namedEndPoint, "endPoint" )
                host = AdminConfig.showAttribute(endPoint, "host" )
                port = AdminConfig.showAttribute(endPoint, "port" )
                print "DMGRPort" + endPointName + ": " + port
            #endif
        #endfor
    #endif
    dcbindip=nodehost
    nodehost=GetShorthostname(nodehost)
    if nodehost == system_name:
        if not dmgrmatch:
            nodefound = 1
            print "Running on: " + dcbindip
            #print " INFO: Running on host: " + nodehost
            #print " INFO: Nodename is: " + node_name
            break
        #endif
    #endif
#endfor

if dmgrhostfound == 0:
    print "ERROR: Could not identify DMgr hostname (DmgrNode:" + dmgrnode + ")"
    sys.exit(1)
elif nodefound == 0:
    print "ERROR: Could not identify local node" + node_name + " hostname"
    print "ERROR: HostName (returned by wsadmin showattribute): " + nodehost
    print "ERROR: System's hostname(returned by socket.gethostname): " + system_name
    sys.exit(1)
elif dmgrportfound == 0:
    print "DMGRPortSOAP_CONNECTOR_ADDRESS: notfound" 
else:
    pass
#endif
print  "Nodename: " + node_name

# Get Server Names
plist = "[-serverType APPLICATION_SERVER -nodeName " + node_name + "]"
server_list=AdminTask.listServers(plist)
server_list = AdminUtilities.convertToList(server_list)
servernames=""
for server in server_list:
     server_name=AdminConfig.showAttribute(server,'name')
     plist='cell=' + cellname + ',node=' + node_name + ',name=' + server_name + ',type=Server,*'
     server_status=AdminControl.completeObjectName(plist)
     #print  "Server: " + server_name
     #print "---------------------------" + server_status + "-"
     if server_status == '':
         print  "Server: " + server_name + "/not-running"
         #servernames=servernames + "," + server_name + "!!! Not started"
     else:
         #servernames=servernames + "," + server_name
         javahomeserver=server_name
         print  "Server: " + server_name + "/running"
     #endif
     continue
#endfor

#sys.exit(rc)
EOF

     if [ $? -ne 0 ] ; then
         rc=$?
         echo " ERROR During creation of wsadmin python input file (rc=$?)"
         return $rc
     fi

     return 0
}

#-----------------
GetWebSphereData()
{
     CreateWsadminScript
     if [ $? -ne 0 ] ; then
         return 1
     fi

     echo " INFO Collecting required data from WebSphere using wsadmin"
     echo " INFO Executing ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} "
     ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} > ${WAS_CONFDATA}
     if [ $? -ne 0 ] ; then
         echo " ERROR during: ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} (rc=$?)!! "
         return 1
     else
         grep "ERROR" ${WAS_CONFDATA}
         if [ $? -ne 0 ] ; then
             echo " INFO Data successfully collected from WebSphere"
         else
             echo " ERROR during: ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT}!! "
             return 1
         fi
     fi

     # Save collected data in variables
     CELLMGRHOST=`grep "CellMgrHostname" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   CellMgrHostname=${CELLMGRHOST}"

     CELLNAME=`grep "Cellname" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   Cellname=${CELLNAME}"

     NODENAME=`grep "Nodename" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   Nodename=${NODENAME}"

     THISHOST=`grep "Running on" ${WAS_CONFDATA} | awk '{ print $3 }'`
     echo " INFO   Running on host ${THISHOST}"

     DMGRSOAPPORT=`grep "DMGRPortSOAP_CONNECTOR_ADDRESS" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   DMGR SOAP connector address returned by wsadmin is: ${DMGRSOAPPORT}"

     return 0
}

#---------------
GetWsadminHome()
{
    temp=`echo ${WASHOME}| awk -F"/AppServer" '{print $1}'`
    wsadmin="${temp}/wp_profile/bin/wsadmin.sh"
    if [ -f "${wsadmin}" ]; then
        WSADMIN_HOME="${temp}/wp_profile/bin/"
    else
        wsadmin="${WASHOME}/bin/wsadmin.sh"
        if [ -f "${wsadmin}" ]; then
            WSADMIN_HOME="${WASHOME}/bin"
        else
            echo " ERROR !!! wsadmin.sh cannot be found. Please verify ${WASHOME}/bin and restart the procedure."
            return 1
        fi
    fi

    echo " INFO WSADMIN_HOME=${WSADMIN_HOME}"
    return 0
}

#---------------
GetProfileName()
{
     # Create profile name (Customer specific, normally equal nodename)
     echo " INFO Collecting profile information using manageprofiles.sh"
     #echo " INFO Executing ${WASHOME}/bin/manageprofiles.sh -listProfiles successfully executed"
     profile=`${WASHOME}/bin/manageprofiles.sh -listProfiles| sed s'/\[//' |  sed s'/\]//' `
     if [ $? -ne 0 ] ; then
         echo " ERROR during: ${WASHOME}/bin/manageprofiles.sh -listProfiles"
         return 1
     else
         echo " INFO Existing profiles: $profile."
     fi
     pffound=0
     c=0
     for pf in $(echo $profile | sed "s/,/ /g")
     do
         c=$((c+1))
         if [ "$pf" == "$NODENAME" ] ; then
             PROFILENAME="${NODENAME}"
             pffound=1 # means profilename equal nodename
             break
         fi
         if [ "$pf" == "wp_profile" ] ; then
             PROFILENAME="wp_profile"
             break
         fi
     done
     if  [ $c == 0 ] ; then
         echo " ERROR manageprofiles.sh does not return any data"
         return 1
     fi
     if  [ $pffound == 0 ] ; then
         PROFILENAME=$pf
     fi

     echo " INFO PROFILENAME=${PROFILENAME}"
     return 0
}

#--------------
CheckOptions ()
{
    echo " INFO Check options"
    if [ ! -d "${WASHOME}" ] ; then
        echo " ERROR \"${WASHOME}\" directory  not existing or not set"
        Usage
    else
        echo " INFO WASHOME=${WASHOME}"
    fi

    return 0
}

###############################################
################### MAIN ######################
###############################################
WAS_CONFDATA="tmp.itcamdc.websphere_data.conf"
WSADMIN_SCRIPT="tmp.itcamdc.wsadminScript.py"
while getopts "xdh:" OPTS
do
  case $OPTS in
     h) WASHOME=${OPTARG} ;;
     *) echo "$OPTARG is not a valid switch"; Usage ;;
  esac
done

# Check argmuments provided
CheckOptions

GetWsadminHome # Get "wsadmin.sh" Home directory
if [ $? -ne 0 ] ; then
    exit 3
fi

# Retrieve data from WebSphere required by the ITCAM procedures.
# Used in the input file for silent execution.
GetWebSphereData
if [ $? -ne 0 ] ; then
    exit 5
fi

# get Websphere profile name
GetProfileName
if [ $? -ne 0 ] ; then
    exit 6
fi

# Display, check server status and create variable SERVERLIST to be used later
CheckAndDisplayStatus
if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
    echo " ERROR during CheckAndDisplaySrvStatus"
    exit 8
fi
if [ "${#SERVERLIST[@]}" == "0" ] ; then
    echo " ERROR Nothing to process. None of the selected server are running, check messages"
    exit 9
fi

# Check running servers. Server deleted from SERVERLIST under certain conditions 
CheckRunningServerDcConfig
if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
    echo " ERROR during CheckRunningServerDcConfig"
    exit 10
fi
if [ "${#SERVERLIST[@]}" == "0" ] ; then
    echo " ERROR Nothing to process. Please check messages"
    exit 11
fi

echo " INFO procedure successfully ended"
exit 0
