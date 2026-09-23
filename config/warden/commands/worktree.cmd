#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Gives an existing git worktree a Warden environment of its own, so several
## branches of one project can run at the same time without colliding on
## environment name, domain or container names.
##
## Creating the worktree is herdr's job; this only configures one. That split is
## why the command cannot start from locateEnvPath the way other Warden commands
## do: a fresh worktree may have no config yet, so there is no environment to
## locate. The parent checkout is found through git instead, and its config read
## directly.
##
## The path is the only thing on stdout, so the caller can capture it.

function note { >&2 echo -e "\033[0;36m==>\033[0m $*"; }

## Warden now reads .warden.env, keeping .env as a deprecated fallback; older
## installs know only .env. Defer to Warden's own resolver where it exists so
## both eras behave identically, and which name a project uses stays its
## business rather than something this command hardcodes.
if declare -F findEnvFile >/dev/null; then
  function locateConfig { findEnvFile "$@"; }
else
  function locateConfig {
    local configFile="${1}/.env"
    [[ -f "${configFile}" ]] || return 1

    if [[ "${2:-}" = "markers" ]]; then
      grep -q "^WARDEN_ENV_NAME" "${configFile}" || return 1
      grep -q "^WARDEN_ENV_TYPE" "${configFile}" || return 1
    fi

    echo "${configFile}"
  }
fi

TARGET="${WARDEN_PARAMS[0]:-$PWD}"
[[ -d "${TARGET}" ]] || fatal "no such directory: ${TARGET}"
TARGET="$(cd "${TARGET}" && pwd)"

git -C "${TARGET}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || fatal "${TARGET} is not inside a git repository"

## --git-common-dir points at the main checkout's .git from anywhere in a linked
## worktree, which is how the parent is found without being told where it is.
COMMON_DIR="$(cd "${TARGET}" && cd "$(git rev-parse --git-common-dir)" && pwd)"
PARENT="$(dirname "${COMMON_DIR}")"

[[ "${PARENT}" == "${TARGET}" ]] && fatal "${TARGET} is the main checkout, not a worktree"

## Warden identifies a project by these two keys in its config; without them the
## parent is simply not a Warden project, which is not an error worth failing
## on — herdr runs this against every worktree it creates.
if ! PARENT_ENV_FILE="$(locateConfig "${PARENT}" markers)"; then
  note "${PARENT} is not a Warden project — nothing to configure"
  printf '%s\n' "${TARGET}"
  exit 0
fi

## Read config values without sourcing the file, which would run anything a
## project happened to put in it.
function env_value {
  [[ -f "${1}" ]] || return 0
  sed 's/\r$//' "${1}" | grep "^${2}=" | tail -1 | cut -d= -f2- | sed 's/^"//; s/"$//'
}

function parent_env { env_value "${PARENT_ENV_FILE}" "${1}"; }

PROJECT="$(parent_env WARDEN_ENV_NAME)"
PARENT_DOMAIN="$(parent_env TRAEFIK_DOMAIN)"

## A base domain set in the parent's config is about that one project, so it
## wins over the machine-wide default in Warden's own ~/.warden/.env.
CONFIGURED_BASE="$(parent_env WARDEN_WORKTREE_DOMAIN)"
CONFIGURED_BASE="${CONFIGURED_BASE:-$(env_value "${WARDEN_HOME_DIR}/.env" WARDEN_WORKTREE_DOMAIN)}"

[[ ${PROJECT} ]] || fatal "WARDEN_ENV_NAME is empty in ${PARENT_ENV_FILE}"

## The directory name is the slug: herdr has already reduced the branch to
## something a path can hold, and matching it keeps the environment name and the
## directory in step.
SLUG="$(basename "${TARGET}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
[[ ${SLUG} ]] || fatal "'$(basename "${TARGET}")' leaves nothing usable as a hostname label"

## With WARDEN_WORKTREE_DOMAIN set nowhere, fall back to everything after the
## first label of the parent's domain, so kmstools-checkout-lunar.stowbox.dev
## yields stowbox.dev.
BASE_DOMAIN="${CONFIGURED_BASE:-${PARENT_DOMAIN#*.}}"
[[ ${BASE_DOMAIN} && ${BASE_DOMAIN} != "${PARENT_DOMAIN}" ]] \
  || fatal "cannot derive a base domain from TRAEFIK_DOMAIN='${PARENT_DOMAIN}'; set WARDEN_WORKTREE_DOMAIN in ${PARENT_ENV_FILE} or ${WARDEN_HOME_DIR}/.env"

ENV_NAME="${PROJECT}-${SLUG}"
DOMAIN="${ENV_NAME}.${BASE_DOMAIN}"

## A project that commits .warden.env brings it along with the checkout, so
## there is usually nothing to copy. One still configured through the deprecated
## .env has it gitignored, and the worktree needs a copy before Warden can see
## an environment there at all. Either way the worktree keeps whichever filename
## the parent uses, so the .local written below is the one Warden pairs with it.
if TARGET_ENV_FILE="$(locateConfig "${TARGET}")"; then
  note "$(basename "${TARGET_ENV_FILE}") is already present — leaving it alone"
else
  TARGET_ENV_FILE="${TARGET}/$(basename "${PARENT_ENV_FILE}")"
  cp "${PARENT_ENV_FILE}" "${TARGET_ENV_FILE}"
  note "copied $(basename "${PARENT_ENV_FILE}") from ${PARENT}"
fi

TARGET_LOCAL_FILE="${TARGET_ENV_FILE}.local"

note "writing $(basename "${TARGET_LOCAL_FILE}") — env ${ENV_NAME}, domain ${DOMAIN}"
cat > "${TARGET_LOCAL_FILE}" <<LOCAL
## Written by 'warden worktree'. Warden loads this after
## $(basename "${TARGET_ENV_FILE}") and lets it override WARDEN_, TRAEFIK_ and
## PHP_ values.
WARDEN_ENV_NAME=${ENV_NAME}
TRAEFIK_DOMAIN=${DOMAIN}
LOCAL

>&2 echo
>&2 echo -e "    env     \033[0;32m${ENV_NAME}\033[0m"
>&2 echo -e "    domain  \033[0;32mhttps://${DOMAIN}\033[0m"
>&2 echo -e "    next    'warden env up' from within the worktree. Application-level"
>&2 echo -e "            values such as APP_URL are not overridden."
>&2 echo

printf '%s\n' "${TARGET}"
