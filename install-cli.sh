#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

check_platform_arch() {
  local supported="darwin-amd64 darwin-arm64 linux-amd64 linux-386 linux-arm linux-arm64 windows-386 windows-amd64"

  if ! echo "${supported}" | tr ' ' '\n' | grep -q "${PLATFORM}-${ARCH}"; then
    cat <<EOF

The Drycc Workflow CLI (drycc) is not currently supported on ${PLATFORM}-${ARCH}.

See https://github.com/drycc/workflow-cli for more information.

EOF
  fi
}

PLATFORM="$(uname | tr '[:upper:]' '[:lower:]')"
if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    DRYCC_BIN_URL_BASE="https://drycc-mirrors.drycc.cc/drycc/workflow-cli/releases"
else
    DRYCC_BIN_URL_BASE="https://github.com/drycc/workflow-cli/releases"
fi

# initArch discovers the architecture for this system.
init_arch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="arm";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}

init_latest_version() {
  VERSION=$(curl -Ls $DRYCC_BIN_URL_BASE|grep /drycc/workflow-cli/releases/tag/ | sed -E 's/.*\/drycc\/workflow-cli\/releases\/tag\/(v[0-9\.]+)".*/\1/g' | head -1)
}

init_arch
init_latest_version
check_platform_arch

DRYCC_CLI="drycc-${VERSION}-${PLATFORM}-${ARCH}"
DRYCC_CLI_PATH="${DRYCC_CLI}"
if [ "${VERSION}" != 'stable' ]; then
  DRYCC_CLI_PATH="${VERSION}/${DRYCC_CLI_PATH}"
fi

echo "Downloading ${DRYCC_CLI} From Google Cloud Storage..."
echo "Downloading binary from here: ${DRYCC_BIN_URL_BASE}/download/${DRYCC_CLI_PATH}"
curl -fsSL -o drycc "${DRYCC_BIN_URL_BASE}/download/${DRYCC_CLI_PATH}"

chmod +x drycc

cat <<EOF

The Drycc Workflow CLI (drycc) is now available in your current directory.

To learn more about Drycc Workflow, execute:

    $ ./drycc --help

You can also move it to other directories, such as:

   $ mv $PWD/drycc /usr/local/bin

EOF
