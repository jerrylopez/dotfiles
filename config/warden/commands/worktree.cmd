#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Gives an existing git worktree a Warden environment of its own, so several
## branches of one project can run at the same time without colliding on
## environment name, domain or container names.
##
## Creating the worktree is herdr's job; this only configures one. That split is
## why the command cannot start from locateEnvPath the way other Warden commands
## do: a fresh worktree has no .env yet, so there is no environment to locate.
## The parent checkout is found through git instead, and its .env read directly.
##
## The path is the only thing on stdout, so the caller can capture it.

function note { >&2 echo -e "\033[0;36m==>\033[0m $*"; }

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

## Warden identifies a project by these two keys in .env; without them the
## parent is simply not a Warden project, which is not an error worth failing
## on — herdr runs this against every worktree it creates.
if [[ ! -f "${PARENT}/.env" ]] \
  || ! grep -q "^WARDEN_ENV_NAME" "${PARENT}/.env" \
  || ! grep -q "^WARDEN_ENV_TYPE" "${PARENT}/.env"
then
  note "${PARENT} is not a Warden project — nothing to configure"
  printf '%s\n' "${TARGET}"
  exit 0
fi

## Read the parent's values without sourcing the file, which would run anything
## a project happened to put in it.
function parent_env {
  sed 's/\r$//' "${PARENT}/.env" | grep "^${1}=" | tail -1 | cut -d= -f2- | sed 's/^"//; s/"$//'
}

PROJECT="$(parent_env WARDEN_ENV_NAME)"
PARENT_DOMAIN="$(parent_env TRAEFIK_DOMAIN)"
CONFIGURED_BASE="$(parent_env WARDEN_WORKTREE_DOMAIN)"

[[ ${PROJECT} ]] || fatal "WARDEN_ENV_NAME is empty in ${PARENT}/.env"

## The directory name is the slug: herdr has already reduced the branch to
## something a path can hold, and matching it keeps the environment name and the
## directory in step.
SLUG="$(basename "${TARGET}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
[[ ${SLUG} ]] || fatal "'$(basename "${TARGET}")' leaves nothing usable as a hostname label"

## Everything after the first label of the parent's domain, so
## kmstools-checkout-lunar.stowbox.dev yields stowbox.dev. WARDEN_WORKTREE_DOMAIN
## in the parent's .env overrides it.
BASE_DOMAIN="${CONFIGURED_BASE:-${PARENT_DOMAIN#*.}}"
[[ ${BASE_DOMAIN} && ${BASE_DOMAIN} != "${PARENT_DOMAIN}" ]] \
  || fatal "cannot derive a base domain from TRAEFIK_DOMAIN='${PARENT_DOMAIN}'; set WARDEN_WORKTREE_DOMAIN in ${PARENT}/.env"

ENV_NAME="${PROJECT}-${SLUG}"
DOMAIN="${ENV_NAME}.${BASE_DOMAIN}"

## .env is gitignored, so a fresh worktree has none and Warden cannot see an
## environment at all. An existing one is left alone: it is either a rerun or
## something the project put there deliberately.
if [[ -f "${TARGET}/.env" ]]; then
  note "${TARGET}/.env exists — leaving it alone"
else
  cp "${PARENT}/.env" "${TARGET}/.env"
  note "copied .env from ${PARENT}"
fi

note "writing .env.local — env ${ENV_NAME}, domain ${DOMAIN}"
cat > "${TARGET}/.env.local" <<LOCAL
## Written by 'warden worktree'. Warden loads this after .env and lets it
## override WARDEN_, TRAEFIK_ and PHP_ values.
WARDEN_ENV_NAME=${ENV_NAME}
TRAEFIK_DOMAIN=${DOMAIN}
LOCAL

>&2 echo
>&2 echo -e "    env     \033[0;32m${ENV_NAME}\033[0m"
>&2 echo -e "    domain  \033[0;32mhttps://${DOMAIN}\033[0m"
>&2 echo -e "    next    'warden env up' from within the worktree. Application-level"
>&2 echo -e "            values such as APP_URL live in .env and are not overridden."
>&2 echo

printf '%s\n' "${TARGET}"
