#!/bin/bash
set -e

# Welcome, Trickster...to my Velvet Room.
# My name is Igor.
# I am delighted to make your aquaintance. - Persona

VERSION="2.0.0"

# ======
# CONFIG
# ======
declare -A CONFIG=(
    # repository folder (where the 'Packages' file will be)
    [repo]='.'
    # each folder is your Debian package source
    # (folder name does not matter, as long as there is a 'DEBIAN' folder inside)
    [sources]='sources'
    # where to store built debs, relative to REPO_FOLDER
    [debs]='debians'
    # overrides for dpkg-scanpackages
    [override]=''
    # how many formats to compress the Packages file in
    [formats]='bzip2'
)

# banner
cat << EOF

*=============================*
#        _         _ _    _   #
#  ___ __| |__ _  _(_) |__| | #
# / -_)_ / '_ \ || | | / _' | #
# \___/__|_.__/\_._|_|_\__._| #
*=============================*
           <v$VERSION>

make Debian packages the ez way
(c) ongyx 2020
<https://github.com/ongyx>

(updated for use with repo.me <https://github.com/syns/repo.me>)

EOF


USAGE=$(cat << EOF
usage: $0 [<option>...]

Options:
    -c, --config <path>  specify config file 
    -V, --version        print version
    -h, --help           print this message
EOF
)


println () { echo $1; echo; }


# https://stackoverflow.com/a/25288289
pushd () { command pushd "$@" > /dev/null; }
popd () { command popd "$@" > /dev/null; }


# https://stackoverflow.com/a/17841619
join_by () {
    local d=$1; shift
    local f=$1; shift
    printf %s "$f" "${@/#/$d}"
}


# https://unix.stackexchange.com/a/206216
load_conf () {
    local file=$1
    
    if [[ ! -f $1 ]]; then
        return 1
    fi
    
    local line
    while read line; do
        if echo $line | grep -F = &>/dev/null; then
            local varname=$(echo "$line" | cut -d '=' -f 1)
            CONFIG[$varname]=$(echo "$line" | cut -d '=' -f 2-)
        fi
    done < file
    
    return 0
}


clean_path () {
    cleaned=$(echo $1 | tr -s /)
    echo $cleaned
    return 0
}


this_is_fine () {
    # check commands needed
    for cmd in 'awk dpkg-deb apt-ftparchive tar bzip2'; do
        if ! command -v $cmd; then
            println "error: $cmd not found"
            if [[ $cmd == dpkg-* ]]; then
                println 'install <dpkg> and <dpkg-dev> using your package manager first'
            else
                println "install <$cmd> using your package manager first"
            fi
            return 1
        fi
    done

    # check permissions
    if [[ $(id -u) != 0 ]]; then
        println 'error: does not appear to be root (hint: use fakeroot)'
        return 1
    fi
    
    return 0
}


get_package_field () {
    echo $(awk "/$1:/ {print \$2}" $2)
}


get_package_filename () {
    local control=$1
    declare -a debfields=("Package" "Version" "Architecture")
    declare -a debdata
    
    local field
    for field in "${debfields[@]}"; do
        debdata+=($(get_package_field $field $control))
    done
    
    echo "${CONFIG[repo]}/${CONFIG[debs]}/$(join_by _ ${debdata[@]}).deb"
    
    return 0
}


build_package () {
    local package_path=$1
    
    if [[ ! -d ${package_path}/DEBIAN ]]; then
        echo "ignoring $package_path, not a Debian source package"
        return 2
    fi
    
    # get rid of duplicate slashes (in case)
    control_path=$(clean_path "${package_path}/DEBIAN/control")
    deb_filename=$(get_package_filename $control_path)
    
    if [[ $? -eq 0 ]]; then
    
        # filename parsed sucessfully, build
        if dpkg-deb -b $package_path $deb_filename; then
            return 0
        else
            println "error: failed to archive ${package_path}"
        fi
    
    fi
    
    return 1
}


build_repo () {
    # generate Packages file and zip it
    # (push/pop)d needed so Packages file will be generated properly with relative paths
    pushd ${CONFIG[repo]}
    rm Packages*
    
    println "building Release"
    apt-ftparchive release -c ./assets/repo/repo.conf . > Release
    
    println "building Packages"
    if ! apt-ftparchive packages \
        "./$DEBS_FOLDER" \
        ${CONFIG[override]} > ./Packages \
    ; then
        println "error: failed to scan Debian archives"
        return 1
    fi
    
    println "compressing Packages into format(s): <${CONFIG[formats]}>"
    for format in ${CONFIG[formats]}; do
        local cmd=($format -kf ./Packages)
        # magic hax
        "${cmd[@]}"
        if [[ ! $? -eq 0 ]]; then
            println "error: failed to archive Packages file using $format"
            return 1
        fi
    done
    
    popd
    
    return 0
}


main () {
    # get options
    #while getopts ":hVc:" opt; do
    #    case $opt in
    #        V|version )
    #            println $VERSION
    #            return 0
    #        ;;
    #        c|config )
    #            load_config $OPTARG
    #        ;;&
    #        h|help|* )
    #            echo $USAGE
    #            return 0
    #        ;;
    #    esac
    #done
    #
    #shift $((OPTIND -1))
    
    println 'checking needed commands and permissions...'
    if ! this_is_fine; then
        exit 1
    fi
    println 'ok'
    
    # build packages
    local counter=0
    for package_path in "${CONFIG[sources]}/*/"; do
        echo "building $package_path"
        build_package $package_path
        
        case $? in
            2 )
                echo "skipping $package_path, not a Debian source package"
                continue
            ;;
            0 )
                counter=$((counter+1))
                continue
            ;;
            * )
                return 1
            
        esac
    done
    
    println "built $counter package(s)"
    
    if ! build_repo; then
        println 'ded: failed to build repo'
    fi
    
    println 'GLORIOUS SUCCESS: build finished'
    
    return 0
}


if main; then
    exit 0
else
    exit 1
fi