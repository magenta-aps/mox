#!/bin/bash

echo "Compiling auth module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")
for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

pushd
mvn package

ln -sf "auth.sh" "../../auth.sh"

popd
