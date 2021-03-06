#!/bin/bash
#
# Script to set up Travis-CI test VM.
#
# This file is generated by l2tdevtools update-dependencies.py any dependency
# related changes should be made in dependencies.ini.

DPKG_PYTHON3_DEPENDENCIES="";

DPKG_PYTHON3_TEST_DEPENDENCIES="python3-coverage python3-distutils python3-mock python3-pbr python3-setuptools python3-six";

RPM_PYTHON3_DEPENDENCIES="";

RPM_PYTHON3_TEST_DEPENDENCIES="python3-mock python3-pbr python3-setuptools python3-six";

# Exit on error.
set -e;

if test -n "${FEDORA_VERSION}";
then
	CONTAINER_NAME="fedora${FEDORA_VERSION}";

	docker pull registry.fedoraproject.org/fedora:${FEDORA_VERSION};

	docker run --name=${CONTAINER_NAME} --detach -i registry.fedoraproject.org/fedora:${FEDORA_VERSION};

	# Install dnf-plugins-core and langpacks-en.
	docker exec ${CONTAINER_NAME} dnf install -y dnf-plugins-core langpacks-en;

	# Add additional dnf repositories.
	docker exec ${CONTAINER_NAME} dnf copr -y enable @gift/dev;

	if test -n "${TOXENV}";
	then
		RPM_PACKAGES="python3-tox";

	else
		RPM_PACKAGES="python3 ${RPM_PYTHON3_DEPENDENCIES} ${RPM_PYTHON3_TEST_DEPENDENCIES}";
	fi
	docker exec ${CONTAINER_NAME} dnf install -y ${RPM_PACKAGES};

	docker cp ../dfdatetime ${CONTAINER_NAME}:/

elif test -n "${UBUNTU_VERSION}";
then
	CONTAINER_NAME="ubuntu${UBUNTU_VERSION}";

	docker pull ubuntu:${UBUNTU_VERSION};

	docker run --name=${CONTAINER_NAME} --detach -i ubuntu:${UBUNTU_VERSION};

	# Install add-apt-repository and locale-gen.
	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get update -q";
	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get install -y locales software-properties-common";

	# Add additional apt repositories.
	if test -n "${TOXENV}";
	then
		docker exec ${CONTAINER_NAME} add-apt-repository universe;
		docker exec ${CONTAINER_NAME} add-apt-repository ppa:deadsnakes/ppa -y;
	fi
	docker exec ${CONTAINER_NAME} add-apt-repository ppa:gift/dev -y;

	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get update -q";

	# Set locale to US English and UTF-8.
	docker exec ${CONTAINER_NAME} locale-gen en_US.UTF-8;

	# Install packages.
	if test -n "${TOXENV}";
	then
		DPKG_PACKAGES="build-essential curl python${TRAVIS_PYTHON_VERSION} python${TRAVIS_PYTHON_VERSION}-dev tox";

	elif test "${TARGET}" = "jenkins3";
	then
		DPKG_PACKAGES="sudo";
	else
		DPKG_PACKAGES="python3 ${DPKG_PYTHON3_DEPENDENCIES} ${DPKG_PYTHON3_TEST_DEPENDENCIES}";
	fi
	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get install -y ${DPKG_PACKAGES}";

	docker cp ../dfdatetime ${CONTAINER_NAME}:/

elif test ${TRAVIS_OS_NAME} = "osx";
then
	brew update;

	# Brew will exit with 1 and print some diagnostic information
	# to prevent the CI test from failing || true is added.
	brew install tox || true;
fi
