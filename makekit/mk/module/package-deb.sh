#
# Copyright (c) Brian Koropoff
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the MakeKit project nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
#

##
#
# package-deb.sh -- build Debian packages
#
##

### section configure

DEPENDS="core program package"

option()
{
    mk_option \
        OPTION="package-deb" \
        VAR="MK_PACKAGE_DEB" \
        PARAM="yes|no" \
        DEFAULT="yes" \
        HELP="Enable building deb packages"

    mk_option \
        OPTION="deb-dir" \
        VAR="MK_PACKAGE_DEB_DIR" \
        PARAM="path" \
        DEFAULT="$MK_PACKAGE_DIR/deb" \
        HELP="Subdirectory for built deb packages"

    default_gpg_key_sign_deb="no"
    mk_option \
        OPTION=gpg-key-sign-deb \
        PARAM="yes|no" \
        VAR="MK_GPG_KEY_SIGN_DEB" \
        DEFAULT="$default_gpg_key_sign_deb" \
        HELP="Sign Debian packages"

}

configure()
{
    mk_declare -e MK_PACKAGE_DEB_DIR
    mk_declare -e MK_GPG_KEY_SIGN_DEB

    if mk_check_program PROGRAM=dpkg-buildpackage &&
       [ "$MK_PACKAGE_DEB" = "yes" ]
    then
        mk_msg "debian package building: enabled"
        MK_PACKAGE_DEB_ENABLED=yes
    else
        mk_msg "debian package building: disabled"
        MK_PACKAGE_DEB_ENABLED=no
    fi
}

mk_deb_enabled()
{
    [ "$MK_PACKAGE_DEB_ENABLED" = "yes" ]
}

#<
# @brief Begin Debian package definition
# @usage PACKAGE=name VERSION=version DEBIANFILES=debfiles
# @option PACKAGE=name Sets the name of the package.
# @option VERSION=ver Sets the version of the package.
# @option DEBIANFILES=debfiles Specifies a list of Debian
# build files (those usually appearing in the <lit>debian</lit>
# subdirectory).  The files will be processed as if by
# <funcref>mk_output_file</funcref>, and any <lit>.in</lit>
# file suffixes will be stripped.  You must provide
# <lit>control</lit>, <lit>rules</lit>, and <lit>changelog</lit>
# at a minimum.  Do not provide any <lit>.install</lit> or
# <lit>.dirs</lit> files, as these will generated automatically.
#
# Begins the definition of an Debian package.
#
# After invoking this function, you can use functions
# such as <funcref>mk_package_targets</funcref> or
# <funcref>mk_package_patterns</funcref> to add files
# to the package, or <funcref>mk_deb_sub_do</funcref>
# to define subpackages.  End the definition of the
# package with <funcref>mk_deb_done</funcref>.
#>
mk_deb_do()
{
    mk_push_vars PACKAGE DEBIANFILES VERSION
    mk_parse_params
    
    DEB_PKGDIR=".deb-${PACKAGE}/build"
    DEB_PACKAGE="$PACKAGE"
    DEB_VERSION="$VERSION"
    DEB_SUBPACKAGES=""
    DEB_SUBPACKAGE=""
    DEB_DEPS=""

    mk_resolve_file "$DEB_PKGDIR"
    mk_safe_rm "$result"
    
    for _i in ${DEBIANFILES}
    do
        _basename="${_i##*/}"
        mk_output_file INPUT="$_i" OUTPUT="${DEB_PKGDIR}/debian/${_basename%.in}"
        mk_quote "$result"
        DEB_DEPS="$DEB_DEPS $result"
    done
    
    mk_resolve_file "${DEB_PKGDIR}/debian/${DEB_PACKAGE}.install"
    DEB_INSTALLFILE="$result"
    #echo "# Generated by MakeKit" > "$DEB_INSTALLFILE" || mk_fail "could not write $DEB_INSTALLFILE"
    touch "$DEB_INSTALLFILE" || mk_fail "could not write $DEB_INSTALLFILE"
    mk_add_configure_output "$DEB_INSTALLFILE"
    mk_quote "@$DEB_INSTALLFILE"
    DEB_DEPS="$DEB_DEPS $result"

    mk_resolve_file "${DEB_PKGDIR}/debian/${DEB_PACKAGE}.dirs"
    DEB_DIRFILE="$result"
    #echo "# Generated by MakeKit" > "$DEB_DIRFILE" || mk_fail "could not write $DEB_DIRFILE"
    touch "$DEB_DIRFILE" || mk_fail "could not write $DEB_DIRFILE"
    mk_add_configure_output "$DEB_DIRFILE"
    mk_quote "@$DEB_DIRFILE"
    DEB_DEPS="$DEB_DEPS $result"
    
    mk_package_targets()
    {
        if [ -n "$DEB_SUBPACKAGE" ]
        then
            installfile="$DEB_SUBINSTALLFILE"
        else
            installfile="$DEB_INSTALLFILE"
        fi

        mk_quote_list "$@"
        DEB_DEPS="$DEB_DEPS $result"

        for _i
        do
            echo "${_i#@$MK_STAGE_DIR/}"
        done >> "$installfile"
    }
    
    mk_package_dirs()
    {
        if [ -n "$DEB_SUBPACKAGE" ]
        then
            dirfile="$DEB_SUBDIRFILE"
        else
            dirfile="$DEB_DIRFILE"
        fi

        for _i in "$@"
        do
            echo "$_i"
        done >> "$dirfile"
    }

    mk_pop_vars
}

#<
# @brief Begin Debian subpackage definition
# @usage SUBPACKAGE=name
# @option SUBPACKAGE=name Sets the name of the subpackage
# by itself, e.g. <lit>dev</lit>, <lit>dbg</lit>.
#
# Begins the definition of an Debian subpackage.  The build
# files provided to <funcref>mk_deb_do</funcref> must
# provide appropriate metadata for the subpackage, but
# the file list and directly lists will be created automatically.
#
# After invoking this function, you can use functions
# such as <funcref>mk_package_targets</funcref> or
# <funcref>mk_package_patterns</funcref> to add files
# to the subpackage.  End the definition of the subpackage
# with <funcref>mk_deb_sub_done</funcref>.
#>
mk_deb_sub_do()
{
    mk_push_vars SUBPACKAGE
    mk_parse_params
    
    [ -z "$SUBPACKAGE" ] && SUBPACKAGE="$1"
    DEB_SUBPACKAGE="$SUBPACKAGE"
    DEB_SUBPACKAGES="$DEB_SUBPACKAGES $SUBPACKAGE"
    
    mk_resolve_file "${DEB_PKGDIR}/debian/${DEB_PACKAGE}-${DEB_SUBPACKAGE}.install"
    DEB_SUBINSTALLFILE="$result"
    echo "# Generated by MakeKit" > "$DEB_SUBINSTALLFILE" || mk_fail "could not write $DEB_SUBINSTALLFILE"
    mk_add_configure_output "$DEB_SUBINSTALLFILE"
    mk_quote "@$DEB_SUBINSTALLFILE"
    DEB_DEPS="$DEB_DEPS $result"
    
    mk_resolve_file "${DEB_PKGDIR}/debian/${DEB_PACKAGE}-${DEB_SUBPACKAGE}.dirs"
    DEB_SUBDIRFILE="$result"
    echo "# Generated by MakeKit" > "$DEB_SUBDIRFILE" || mk_fail "could not write $DEB_SUBDIRFILE"
    mk_add_configure_output "$DEB_SUBDIRFILE"
    mk_quote "@$DEB_SUBDIRFILE"
    DEB_DEPS="$DEB_DEPS $result"
    
    mk_pop_vars
}

#<
# @brief End Debian subpackage definition
# @usage
#
# Ends the Debian subpackage definition started with
# <funcref>mk_deb_sub_do</funcref>.
#>
mk_deb_sub_done()
{
    unset DEB_SUBPACKAGE DEB_SUBINSTALLFILE DEB_SUBDIRFILE
}

#<
# @brief End Debian package definition
# @usage
#
# Ends the Debian package definition started with
# <funcref>mk_deb_do</funcref>.
#>
mk_deb_done()
{
    mk_target \
        TARGET="@${MK_PACKAGE_DEB_DIR}/${DEB_PACKAGE}" \
        DEPS="$DEB_DEPS" \
        _mk_build_deb "${DEB_PACKAGE}" "&${DEB_PKGDIR}"
    master="$result"

    unset DEB_PACKAGE DEB_SUBPACKAGE DEB_INSTALLFILE DEB_SUBINSTALLFILE DEB_PKGDIR
    unset DEB_SUBPACKAGES
    unset -f mk_package_files mk_package_dirs

    mk_add_package_target "$master"

    result="$master"
}

### section build

_mk_build_deb()
{
    MK_MSG_DOMAIN="deb"

    mk_msg "begin $1"
    cd "$2" || mk_fail "could not cd to $2"
    mk_run_quiet_or_fail dpkg-buildpackage -rfakeroot -uc -b
    mk_mkdir "${MK_ROOT_DIR}/${MK_PACKAGE_DEB_DIR}/${1}"
    for i in ../*.deb
    do
        if [ "${MK_GPG_KEY_SIGN_DEB}" = "yes" ] 
        then
           mk_run_or_fail dpkg-sig -s builder -k 7237D0AC --passphrase-file /home/builder/.gnupg/passphrase-file "$i" 
        fi
        mk_run_or_fail mv -f "$i" "${MK_ROOT_DIR}/${MK_PACKAGE_DEB_DIR}/${1}"
        mk_msg "built ${i##*/}"
    done
    mk_msg "end $1"
}
