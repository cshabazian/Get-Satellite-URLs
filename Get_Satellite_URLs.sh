#!/bin/sh

# This script will gather the URL's necessary from a server registered to a Red Hat Satellite Server
# In order to allow integration with third party products that need to pull data from the Lifecycle Content URL

# Variables:
TEMP_PATH="/tmp"
SAT_REPO="/etc/yum.repos.d/redhat.repo"
RHSM_CONF="/etc/rhsm/rhsm.conf"
RELEASE_FILE="/etc/redhat-release"

# I like to define my binaries where I can, just in case they ever change:
UNAME=/usr/bin/uname
LS=/usr/bin/ls
AWK=/usr/bin/awk
SED=/usr/bin/sed
DATE=/usr/bin/date
MKDIR=/usr/bin/mkdir
RM=/usr/bin/rm
ECHO=/usr/bin/echo
CAT=/usr/bin/cat
CLEAR=/usr/bin/clear
CUT=/bin/cut
GREP=/bin/grep
RPM=/bin/rpm

# This creates a temporary directory that should be unique:
EPOCH=`$DATE +"%s"`
TEMP_PREFIX="tempdir"
TEMPDIR="$TEMP_PATH/$TEMP_PREFIX.$EPOCH"
$MKDIR $TEMPDIR

# Gather necessary info:
BASEARCH=`$UNAME -i`
BASEURL=`$GREP baseurl $RHSM_CONF | $CUT -d = -f 2`
RELEASERPM=`$RPM -qf $RELEASE_FILE`
RELEASEVER=`$RPM -q --provides $RELEASERPM | $GREP releasever | $CUT -d " " -f 3`

# Get the product names and URL's that this system is registered to:
$CAT $SAT_REPO | $AWK '/]/,/^$/' > $TEMPDIR/repos

# Replace variables with values
$SED -i "s/\$releasever/$RELEASEVER/g" $TEMPDIR/repos
$SED -i "s/\$basearch/$BASEARCH/g" $TEMPDIR/repos
$SED -i 's/ //g' $TEMPDIR/repos

# Split the combined repos file into individual repo files
cd $TEMPDIR
$AWK -v RS= '{print > ("repo-" NR ".txt")}' $TEMPDIR/repos

# Display the gathered information
$ECHO -e "\n     These are the repos and their associated URL's that this system is registered to:"
for i in `$LS repo-*` ; do
 $ECHO -e "\n"
 $GREP name $i | $CUT -d = -f 2 && $GREP baseurl $i | $CUT -d = -f 2
done
$ECHO -e "\n\n"

# Clean up after ourselves
$RM -rf $TEMPDIR
