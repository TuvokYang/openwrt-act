#! /bin/bash

. /etc/os-release

case "$NAME" in
    Ubuntu*)
        case "$VERSION_ID" in
            24.*)
                apt-get -qq install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget
                ;;
            22.*)
                apt-get -qq build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-distutils python3-setuptools rsync swig unzip zlib1g-dev file wget
                ;;
            *)
                echo "System: \"$NAME-$VERSION_ID\" not supported."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "System: \"$NAME-$VERSION_ID\" not supported."
        exit 1
        ;;
esac

exit 0
