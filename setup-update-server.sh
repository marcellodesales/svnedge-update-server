#!/bin/bash
#
# Sets up an Update Server and repository
# 
# This script assumes a Red Hat system
############################################################

INSTALL_DIR=/opt/update-server
REPOS_DIR=$INSTALL_DIR/repos
STAGE_REPOS_DIR=$REPOS_DIR/stage
RELEASE_REPOS_DIR=$REPOS_DIR/release
UPDATE_USER=updator
PKG_TOOLKIT_DIR=$INSTALL_DIR/pkg-toolkit-linux-i386
PKG_TOOLKIT_FILE=pkg-toolkit-linux-i386.tar.bz
CONFIG=/etc/sysconfig/update-server
HTTPD_CONFD_DIR=/etc/httpd/conf.d
STARTER_REPO_DIR=$REPOS_DIR/starters
STARTER_REPO_LINUX=repo-2.3.1-linux-i386.zip
STARTER_REPO_WINDOWS=repo-2.3.1-windows-i386.zip
STARTER_REPO_MAC=repo-2.3.1-darwin-universal.zip
STARTER_REPO_SOLARIS_X86=repo-2.3.1-sunos-i386.zip
STARTER_REPO_SOLARIS_SPARC=repo-2.3.1-sunos-sparc.zip

############################################################

adduser=/usr/sbin/adduser
chkconfig=/sbin/chkconfig
service=/sbin/service
chown=/bin/chown
cp=/bin/cp
install=/usr/bin/install
mkdir=/bin/mkdir
su=/bin/su
tar=/bin/tar
unzip=/usr/bin/unzip

user=`whoami`


if [ "root" != "$USER" ]; then
    echo "Must be run as root user.  sudo is your friend."
    exit
fi

$mkdir -p $RELEASE_REPOS_DIR
$mkdir -p $STAGE_REPOS_DIR
if [ ! -d "$RELEASE_REPOS_DIR" ] ; then
    echo "Unable to create to $RELEASE_REPOS_DIR.  Sorry, I'm outta here."
    exit
fi

# Create the platform repo dirs
for destdir in {linux,linux-64,windows,windows-64,mac,solaris-x86,solaris-sparc}
do
    if [ ! -d $RELEASE_REPOS_DIR/$destdir ]; then
        $mkdir $RELEASE_REPOS_DIR/$destdir
    fi
    if [ ! -d $STAGE_REPOS_DIR/$destdir ]; then
        $mkdir $STAGE_REPOS_DIR/$destdir
    fi
done

if [ ! -d $PKG_TOOLKIT_DIR ]; then
    echo
    echo "Extracting the update server software into place..."
    echo
    currdir=`pwd`
    cd $INSTALL_DIR
    $tar xjvf $currdir/$PKG_TOOLKIT_FILE
    cd -
fi

# Extract starter repos
echo
echo "Extracting the starter repositories..."
echo

for destdir in {linux,linux-64,windows,windows-64,mac,solaris-x86,solaris-sparc}
do
    mkdir -p $STARTER_REPO_DIR/$destdir
done
$unzip $STARTER_REPO_LINUX -d $STARTER_REPO_DIR/linux
# For now, no 64-bit pkg versions for Linux/Windows, so using 32-bit versions
$unzip $STARTER_REPO_LINUX -d $STARTER_REPO_DIR/linux-64
$unzip $STARTER_REPO_WINDOWS -d $STARTER_REPO_DIR/windows
$unzip $STARTER_REPO_WINDOWS -d $STARTER_REPO_DIR/windows-64
$unzip $STARTER_REPO_MAC -d $STARTER_REPO_DIR/mac
$unzip $STARTER_REPO_SOLARIS_X86 -d $STARTER_REPO_DIR/solaris-x86
$unzip $STARTER_REPO_SOLARIS_SPARC -d $STARTER_REPO_DIR/solaris-sparc


# Now copy a subset of the starter packages to each repo
echo
echo "Copying starter packages into the new repos...."
echo
for platfrm in {linux,linux-64,windows,windows-64,mac,solaris-x86,solaris-sparc}
do
    # to release dir
    $PKG_TOOLKIT_DIR/pkg/bin/copypkgs -s $STARTER_REPO_DIR/$platfrm \
      -d $RELEASE_REPOS_DIR/$platfrm pkg python2.4-minimal

    # to stage dir
    $PKG_TOOLKIT_DIR/pkg/bin/copypkgs -s $STARTER_REPO_DIR/$platfrm \
      -d $STAGE_REPOS_DIR/$platfrm pkg python2.4-minimal
done


# Setup the user who will run the update server
$adduser -M $UPDATE_USER -d $INSTALL_DIR
$chown -R $UPDATE_USER:$UPDATE_USER  $INSTALL_DIR

# Setup as service
$install update-server /etc/init.d
$chkconfig --add update-server
# Copy config vals into config file used by service
echo "REPOS_DIR=$REPOS_DIR" > $CONFIG

# Now copy httpd config into place
if [ -d $HTTPD_CONFD_DIR ]; then
    $install updatesrv.conf $HTTPD_CONFD_DIR
else
    echo
    echo "Unable to install the apache conf file updatesrv.conf to"
    echo "$HTTPD_CONFD_DIR.  Make sure Apache is installed and uses this"
    echo "directory for add-on configuration files."
    echo
    exit
fi


$service update-server start
$service httpd start

echo
echo "Done!"
echo
