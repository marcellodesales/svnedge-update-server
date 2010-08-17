#!/bin/bash
#
# Cleans up and re-creates repositories.
#
# WARNING:
#   Under normal circumstances, you do *not* want to run this in
#   a production environment!
# 
######################################################################

INSTALL_DIR=/opt/update-server
PKG_TOOLKIT_DIR=$INSTALL_DIR/pkg-toolkit-linux-i386
REPOS_DIR=$INSTALL_DIR/repos
STAGE_REPOS_DIR=$REPOS_DIR/stage
RELEASE_REPOS_DIR=$REPOS_DIR/release
STARTER_REPO_DIR=$REPOS_DIR/starters


if [ "updator" != "$USER" ]; then
    echo "Must be run as 'updator' user.  sudo is your friend."
    exit
fi

echo
echo "Cleaning out repositories..."
echo 
for platfrm in {linux,linux-64,windows,windows-64,mac,solaris-x86,solaris-sparc}
do
    echo "Cleaning out $RELEASE_REPOS_DIR/$platfrm"
    rm -rf $RELEASE_REPOS_DIR/$platfrm/*
    echo "Cleaning out $STAGE_REPOS_DIR/$platfrm"
    rm -rf $STAGE_REPOS_DIR/$platfrm/*
done


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
