#!/bin/bash
NEW_PASSOWRD=w3USEstrong_P&sswordS
ADD_TO_SUDO=""
PAM_USER_IS_PRESENT=""
PAM_RC_IS_PRESENT=""

PAM_USERNAME="os_pam_user"
PAM_RC_USERNAME="os_pam_rc"

# Root access is needed in order to modify ageing and sshd configuration.
WHOAMI=`whoami`
if [ "$WHOAMI" != "root" ] ; then
  echo -e "\nThis script must be run by the superuser\n" && exit 1
fi

# Exit if distribution is not supported
LINUX_PROC_VERSION="`egrep -i "SuSE|Debian|Ubuntu|Red Hat" /proc/version`"
if [ "${LINUX_PROC_VERSION}" = "" ] ; then
  echo -e "\nOnly support for SuSE SLES, Debian, Ubuntu and Red Hat/CentOS. GOODBYE!\n" && exit 1
fi

## Get Distribtion 
 if !(type lsb_release &>/dev/null); then
    distribution=$(cat /etc/*-release | grep '^NAME' )
    release=$(cat /etc/*-release | grep '^VERSION_ID')
 else
    distribution=$(lsb_release -i | grep 'ID' | grep -v 'n/a')
    release=$(lsb_release -r | grep 'Release' | grep -v 'n/a')
 fi;
 if [ -z "$distribution" ]; then
    distribution=$(cat /etc/*-release)
    release=$(cat /etc/*-release)
 fi;

 OS_RELEASE=${release//[!0-9.]}
 case $distribution in
     *"Debian"*) OS_ID='Debian'; OS_NAME='Debian';;
     *"Ubuntu"*) OS_ID='Debian'; OS_NAME='Ubuntu';;
     *"SUSE"* | *"SLES"*) OS_ID='SLES' ; OS_NAME='SUSE';;
     *"CentOS"*) OS_ID='RHEL'; OS_NAME='CentOS';;
     *"RedHat"* | *"Red Hat"*) OS_ID='RHEL'; OS_NAME='RedHat';;
 esac

echo -e "\nOS Name:        ${OS_NAME}"
echo "OS Release:     ${OS_RELEASE}"
echo -e "---------------------------------------------------------------------------------\n"
REPORT_TEXT="OS Name:        ${OS_NAME}\nOS Release:     ${OS_RELEASE}\nOS Identification:     ${OS_ID}\n---------------------------------------------------------------------------------\n"

if [ `echo $OS_ID$OS_RELEASE | grep "SLES9"` ]; then 
  echo -e "Only support for SuSE SLES11 and newer. GOODBYE!\n" && exit 1
fi

#Get hostname
HOSTNAME=`hostname | sed "s/.cph.dk//"`
# Init of EXIT_STATE varible, assumes OK
EXIT_STATE="OK"

# Report module, purpose is to collect result of the script
report () {
  NAME=`basename $0`
  REPORT_FILE=/tmp/$HOSTNAME\_$NAME\_report_$EXIT_STATE
  REPORT_TEXT="Report Generated on $(date +%Y-%m-%dT%H:%M:%S\ %Z)\n\n$REPORT_TEXT"
  echo -e $REPORT_TEXT > $REPORT_FILE
  chmod 777 $REPORT_FILE
}

finish_script () {
    # Set exit code
    if [ $EXIT_STATE != "OK" ]; then 
        #Run Report 
        report
        exit 1
    else
        echo -e "\nPAM Onbording users - OK"
        exit 0
    fi
}

cleanup_old_config_pam_users () {
    #First version of PAM implementation we used "pam_user" and "pam_rc"
    usermod -m -d /home/$PAM_USERNAME -l $PAM_USERNAME pam_user
    groupmod -n $PAM_USERNAME pam_user

    usermod -m -d /home/$PAM_RC_USERNAME -l $PAM_RC_USERNAME pam_rc 
    groupmod -n $PAM_RC_USERNAME pam_rc

    #Fix Sudoers for old username entries
    sed -i -e "s/pam_user ALL=(ALL) ALL/$PAM_USERNAME ALL=(ALL) ALL/g" /etc/sudoers


    sed -i -e "s/pam_rc ALL= NOPASSWD: \/usr\/bin\/passwd pam_user/$PAM_RC_USERNAME ALL= NOPASSWD: \/usr\/bin\/passwd */g" /etc/sudoers
    sed -i -e "s/$os_pam_rc ALL= NOPASSWD: \/usr\/bin\/passwd os_pam_user/$PAM_RC_USERNAME ALL= NOPASSWD: \/usr\/bin\/passwd */g" /etc/sudoers
    sed -i -e "s/$os_pam_rc ALL= NOPASSWD: \/usr\/bin\/passwd os_pam_user/$PAM_RC_USERNAME ALL= NOPASSWD: \/usr\/bin\/passwd */g" /etc/sudoers
}


set_sudo_access () {


    # Is there a sudo group to add to $PAM_USERNAME?
    [ -n "`cat /etc/sudoers | grep ^%sudo`" ] && ADD_TO_SUDO="-G sudo"
    [ -n "`cat /etc/sudoers | grep ^%wheel`" ] && ADD_TO_SUDO="-G wheel"

    echo -e "\nFixing sudo access if necessary"
    [ -z "`cat /etc/sudoers | grep '^$PAM_RC_USERNAME ALL= NOPASSWD: /usr/bin/passwd'`" ] && echo "$PAM_RC_USERNAME ALL= NOPASSWD: /usr/bin/passwd *" >> /etc/sudoers
    [ -z "$ADD_TO_SUDO" ] && [ -z "`cat /etc/sudoers | grep '^$PAM_USERNAME ALL=(ALL) ALL'`" ] && echo "$PAM_USERNAME ALL=(ALL) ALL" >> /etc/sudoers
}

add_pam_users () {
    echo "Adding users if missing - $PAM_USERNAME and $PAM_RC_USERNAME"
    if [ -z "$PAM_USER_IS_PRESENT" ]; then
        RESULT=`useradd -m -s /bin/bash -c "Cyberark session user" $ADD_TO_SUDO $PAM_USERNAME 2>&1`
        if [ "$?" != "0" ]; then 
            echo "Errors adding $PAM_USERNAME, aborting script"
            REPORT_TEXT="$REPORT_TEXT\nErrors adding $PAM_USERNAME, aborting script\nError msg: $RESULT"
            EXIT_STATE="ERROR" && finish_script
        fi
    fi

    if [ -z "$PAM_RC_IS_PRESENT" ]; then
        RESULT=`useradd -m -s /bin/bash -c "Cyberark reconcile user" $PAM_RC_USERNAME 2>&1`
        if [ "$?" != "0" ]; then 
            echo "Errors adding pam_rc, aborting script" 
            REPORT_TEXT="$REPORT_TEXT\nErrors adding pam_rc, aborting script\nError msg: $RESULT" 
            EXIT_STATE="ERROR" && finish_script
        fi
    fi
}

adjust_password_policy_to_pam () {
    echo -e "\nReversing minimum password lenght to 16 chars"
    RESULT=`sed -i -e "s/,32,32,32/,16,16,16/g" /etc/pam.d/common-password 2>&1`
    [ "$?" != "0" ] && echo "Error setting password length policy" && REPORT_TEXT="$REPORT_TEXT\nError setting password length policy\nError msg: $RESULT" && EXIT_STATE="ERROR"
    RESULT=`sed -i -e "s/minlen=32/minlen=16/g" /etc/pam.d/common-password  2>&1`
    [ "$?" != "0" ] && echo "Error setting password length policy" && REPORT_TEXT="$REPORT_TEXT\nError setting password length policy\nError msg: $RESULT" && EXIT_STATE="ERROR"
}

set_specific_pam_password_policy () {
    echo -e "\nUnsetting min and max days between password changes"
    chage -M 90 -m 0 $PAM_USERNAME
    chage -M 90 -m 0 $PAM_RC_USERNAME
}


set_default_password_for_pam_users () {
    # set default password if users where created
    if [ -z "$PAM_USER_IS_PRESENT" ]; then
        echo -e "\nSetting password for "$PAM_USERNAME""
        RESULT=`echo -e "${NEW_PASSOWRD}\n${NEW_PASSOWRD}" | passwd $PAM_USERNAME 2>&1`
        [ "$?" != "0" ] && echo "Error setting password for $PAM_USERNAME" && REPORT_TEXT="$REPORT_TEXT\nError setting password for $PAM_USERNAME\nError msg: $RESULT" && EXIT_STATE="ERROR"
        echo "$PAM_USERNAME password is configured, must be changes ASAP by PAM!"
    fi

    if [ -z "$PAM_RC_IS_PRESENT" ]; then
        echo -e "\nSetting password for "$PAM_RC_IS_PRESENT"" 
        RESULT=`echo -e "${NEW_PASSOWRD}\n${NEW_PASSOWRD}" | passwd $PAM_RC_IS_PRESENT  2>&1`
        [ "$?" != "0" ] && echo "Error setting password for $PAM_RC_IS_PRESENT" && REPORT_TEXT="$REPORT_TEXT\nError setting password for $PAM_RC_IS_PRESENT\nError msg: $RESULT" && EXIT_STATE="ERROR"
        echo "$PAM_RC_IS_PRESENT password is configured, must be changes ASAP by PAM!"
    fi
}


#### MAIN ####
cleanup_old_config_pam_users

# check is users already is created 
[ -n "`cat /etc/passwd | grep $PAM_USERNAME`" ] && echo "$PAM_USERNAME is already present, checking settings and policy" && PAM_USER_IS_PRESENT="1"
[ -n "`cat /etc/passwd | grep $PAM_RC_USERNAME`" ] && echo -e "$PAM_RC_USERNAME is already present, checking settings and policy\n"  && PAM_RC_IS_PRESENT="1"

add_pam_users
set_sudo_access
adjust_password_policy_to_pam
set_specific_pam_password_policy
set_default_password_for_pam_users

echo -e "\nCleanup"
rm $0

finish_script