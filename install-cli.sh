#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

PLATFORM="$(uname | tr '[:upper:]' '[:lower:]')"

if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    DRYCC_BIN_URL_BASE="https://drycc-mirrors.drycc.cc/drycc/workflow-cli/releases"
else
    DRYCC_BIN_URL_BASE="https://github.com/drycc/workflow-cli/releases"
fi

check_platform_arch() {
  local supported="darwin-amd64 darwin-arm64 linux-amd64 linux-386 linux-arm linux-arm64 windows-386 windows-amd64"

  if ! echo "${supported}" | tr ' ' '\n' | grep -q "^${PLATFORM}-${ARCH}$"; then
    cat <<EOF

The Drycc Workflow CLI (drycc) is not currently supported on ${PLATFORM}-${ARCH}.

See https://github.com/drycc/workflow-cli for more information.

EOF
    exit 1
  fi
}

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
  if [ -z "${VERSION}" ]; then
    echo "Error: unable to determine the latest drycc version from GitHub API." >&2
    echo "Please check your network connection or set VERSION manually." >&2
    exit 1
  fi
}

init_arch
check_platform_arch
init_latest_version

DRYCC_CLI="drycc-${VERSION}-${PLATFORM}-${ARCH}"
DRYCC_CLI_PATH="${DRYCC_CLI}"
if [ "${VERSION}" != 'stable' ]; then
  DRYCC_CLI_PATH="${VERSION}/${DRYCC_CLI_PATH}"
fi

# Install to ~/.local/bin (the XDG / systemd-recommended location for user binaries)
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "Downloading ${DRYCC_CLI}..."
echo "Downloading binary from here: ${DRYCC_BIN_URL_BASE}/download/${DRYCC_CLI_PATH}"
curl -fsSL -o "${INSTALL_DIR}/drycc" "${DRYCC_BIN_URL_BASE}/download/${DRYCC_CLI_PATH}" < /dev/null
chmod +x "${INSTALL_DIR}/drycc"

echo ""
echo "The Drycc Workflow CLI (drycc) has been installed to: ${INSTALL_DIR}/drycc"

# Check whether ~/.local/bin is already in the *current* PATH.
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*)
    PATH_OK=1 ;;
  *)
    PATH_OK=0 ;;
esac

if [ "${PATH_OK}" -eq 1 ]; then
  echo ""
  echo "To learn more about Drycc Workflow, execute:"
  echo ""
  echo "    $ drycc --help"
  echo ""
  exit 0
fi

# ~/.local/bin is NOT in the current PATH.
#
# On many modern distros (Debian/Ubuntu via ~/.profile, Fedora/RHEL via ~/.bashrc)
# ~/.local/bin is ALREADY wired into PATH on login. Two common reasons it is
# missing from the *current* shell:
#   1. The directory did not exist at login time (Debian/Ubuntu only add it with
#      `if [ -d "$HOME/.local/bin" ]`), and we just created it -> a re-login fixes it.
#   2. The current shell is a non-login shell that never sourced the login files.
#
# So: first tell the user a re-login may be all that is needed, then give an
# explicit, shell-correct fallback.

# Determine the user's *login* shell (NOT the shell running this script, which is
# almost always bash when installed via `curl ... | bash`).
USER_SHELL="$(basename "${SHELL:-}")"

echo ""
echo "==> Next steps:"
echo ""
echo "'${INSTALL_DIR}' is not in your current PATH."
echo ""
echo "On most modern distributions this directory is added to PATH automatically"
echo "on your next login (it simply did not exist when this session started)."
echo "Try opening a new terminal or logging out and back in first."
echo ""
echo "If 'drycc' is still not found, add it to PATH manually:"
echo ""

case "${USER_SHELL}" in
  fish)
    echo "  # fish shell"
    echo "  fish_add_path ${INSTALL_DIR}"
    echo ""
    echo "  # (persists automatically; or add to ~/.config/fish/config.fish)"
    ;;
  zsh)
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> \"\$HOME/.zshrc\""
    echo "  source \"\$HOME/.zshrc\""
    ;;
  bash)
    # .bashrc covers non-login interactive shells (GUI terminals); .profile
    # covers login shells. Writing to .bashrc is the most reliable for desktop use.
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> \"\$HOME/.bashrc\""
    echo "  source \"\$HOME/.bashrc\""
    ;;
  *)
    echo "  # add to your shell's startup file, e.g. ~/.profile"
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> \"\$HOME/.profile\""
    echo "  source \"\$HOME/.profile\""
    ;;
esac

echo ""
echo "Then verify with:"
echo ""
echo "    $ drycc --help"
echo ""
