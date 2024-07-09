PACKER_CACHE_DIR := ./packer_cache
arch = x86_64
BASE_VERSION = 9.2
headless = true
TARGET_VERSION := 9.2
target = alt-server
THIS_FILE := $(lastword $(MAKEFILE_LIST))
# VM_TYPE may be
# - qemu
# - vbox
# - vagrant-qemu
# - vagrant-vbox
# - onebula
# - cloud
# - vsphere
# - openuds-actor
VM_TYPE := qemu

# For vsphere bulder only
VCENTER_SERVER =
VSPHERE_HOST =
VSPHERE_USER =
VSPHERE_PASSWORD =

# For openuds-actor builder only
OPENUDS_ACTOR_SSL_VALIDATION := no
OPENUDS_HOST := udshost
OPENUDS_AUTHENTICATOR := admin
OPENUDS_USERNAME := root
OPENUDS_PASSWORD := udsmam0
OPENUDS_ACTOR_PRE_CONNECT =
OPENUDS_ACTOR_RUN_ONCE =
OPENUDS_ACTOR_POST_CONFIG =
OPENUDS_ACTOR_LOG_LEVEL := error

GIT_HASH := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git tag --points-at HEAD)
BUILD_DATE := $(shell LC_ALL=POSIX date +%Y%m%d)
BUILD_DATE_FULL := $(shell LC_ALL=POSIX date)

# Check git HEAD tag. If it not exists, use HEAD commit short hash
ifdef GIT_TAG
	IMAGE_FILENAME := ${target}-${BASE_VERSION}-${VM_TYPE}-rev${GIT_TAG}-${BUILD_DATE}-${arch}
else
	IMAGE_FILENAME := ${target}-${BASE_VERSION}-${VM_TYPE}-${BUILD_DATE}-${GIT_HASH}-${arch}
endif

# on-error may be:
# - abort - stop and leave everything "as is"
# - cleanup - is the default behavior
# - ask - ask what to do
onerror = cleanup
organization = BaseALT

# Build base VM box using Packer
image:
	PACKER_CACHE_DIR="$(PACKER_CACHE_DIR)" \
	PACKER_TARGET="$(target)" \
	PACKER_BASE_VERSION="$(BASE_VERSION)" \
	PACKER_ARCH="$(arch)" \
	PACKER_HEADLESS="$(headless)" \
	PACKER_LOG=1 \
	PACKER_TARGET_VERSION="$(TARGET_VERSION)" \
	PACKER_VM_TYPE="$(VM_TYPE)" \
	PACKER_IMAGE_FILENAME="$(IMAGE_FILENAME)" \
	PACKER_GIT_HASH="$(GIT_HASH)" \
	PACKER_GIT_TAG="$(GIT_TAG)" \
	PACKER_BUILD_DATE="$(BUILD_DATE)" \
	PACKER_BUILD_DATE_FULL="$(BUILD_DATE_FULL)" \
	PACKER_VCENTER_SERVER="$(VCENTER_SERVER)" \
	PACKER_VSPHERE_HOST="$(VSPHERE_HOST)" \
	PACKER_VSPHERE_USER="$(VSPHERE_USER)" \
	PACKER_VSPHERE_PASSWORD="$(VSPHERE_PASSWORD)" \
	PACKER_OPENUDS_ACTOR_SSL_VALIDATION="$(OPENUDS_ACTOR_SSL_VALIDATION)" \
	PACKER_OPENUDS_HOST="$(OPENUDS_HOST)" \
	PACKER_OPENUDS_AUTHENTICATOR="$(OPENUDS_AUTHENTICATOR)" \
	PACKER_OPENUDS_USERNAME="$(OPENUDS_USERNAME)" \
	PACKER_OPENUDS_PASSWORD="$(OPENUDS_PASSWORD)" \
	PACKER_OPENUDS_ACTOR_PRE_CONNECT="$(OPENUDS_ACTOR_PRE_CONNECT)" \
	PACKER_OPENUDS_ACTOR_RUN_ONCE="$(OPENUDS_ACTOR_RUN_ONCE)" \
	PACKER_OPENUDS_ACTOR_POST_CONFIG="$(OPENUDS_ACTOR_POST_CONFIG)" \
	PACKER_OPENUDS_ACTOR_LOG_LEVEL="$(OPENUDS_ACTOR_LOG_LEVEL)" \
	./build_vm

# Publish previously built VM box using Vagrant. Please note that you'll
# need to provide TOKEN from Vagrant Cloud as environment variable.
publish_vagrant:
	target="$(target)" \
	arch="$(arch)" \
	BASE_VERSION="$(BASE_VERSION)" \
	TARGET_VERSION="$(TARGET_VERSION)" \
	VM_TYPE="$(VM_TYPE)" \
	IMAGE_FILENAME="$(IMAGE_FILENAME)" \
	GIT_TAG="$(GIT_TAG)" \
	./publish_vm

publish_yandex:
	target="$(target)" \
	arch="$(arch)" \
	TARGET_VERSION="$(TARGET_VERSION)" \
	VM_TYPE="$(VM_TYPE)" \
	IMAGE_FILENAME="$(IMAGE_FILENAME)" \
	GIT_TAG="$(GIT_TAG)" \
	./publish_vm_yandex

# Download images specified in JSON configuration files.
sync:
	PACKER_CACHE_DIR="$(PACKER_CACHE_DIR)" \
	./sync_images