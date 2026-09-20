#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Creates a git worktree for the current project and gives it a Warden
## environment of its own, so several branches of one project can run at the
## same time without colliding on env name, domain or container names.
##
## Everything that distinguishes the worktree lives in .env.local, which Warden
## loads after .env and lets override WARDEN_, TRAEFIK_ and PHP_ values. The
## parent's .env is copied in first because it is gitignored, so a fresh
## worktree has none, and Warden cannot see an environment without one.
##
## The path is printed on stdout and nothing else is, so the caller can capture
## it: herdr worktree open --path "$(warden worktree feature-a)"

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

## Progress goes to stderr to keep stdout clean for the path.
function note { >&2 echo -e "\033[0;36m==>\033[0m $*"; }

if [[ -z "${WORKTREES:-}" ]]; then
  fatal "WORKTREES is not set. It is exported from config/shell/os/<platform>.zsh."
fi

BRANCH=
BASE=
while (( ${#WARDEN_PARAMS[@]} )); do
  case "${WARDEN_PARAMS[0]}" in
    --base)
      BASE="${WARDEN_PARAMS[1]:-}"
      [[ ${BASE} ]] || fatal "--base needs a ref"
      WARDEN_PARAMS=("${WARDEN_PARAMS[@]:2}")
      ;;
    -*)
      fatal "unknown option ${WARDEN_PARAMS[0]}"
      ;;
    *)
      [[ ${BRANCH} ]] && fatal "only one branch may be named"
      BRANCH="${WARDEN_PARAMS[0]}"
      WARDEN_PARAMS=("${WARDEN_PARAMS[@]:1}")
      ;;
  esac
done

[[ ${BRANCH} ]] || fatal "usage: warden worktree <branch> [--base <ref>]"

## A branch may contain characters a directory name and a hostname label cannot,
## so the slug is what names the directory, the environment and the subdomain.
SLUG="$(printf '%s' "${BRANCH}" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
[[ ${SLUG} ]] || fatal "branch '${BRANCH}' has no usable characters for a directory or hostname"

PROJECT="${WARDEN_ENV_NAME}"

## The base domain is everything after the first label of the parent's domain,
## so kmstools-checkout-lunar.stowbox.dev yields stowbox.dev. Set
## WARDEN_WORKTREE_DOMAIN in .env to override; it is WARDEN_ prefixed, so the
## machinery that loads .env and .env.local already carries it here.
BASE_DOMAIN="${WARDEN_WORKTREE_DOMAIN:-${TRAEFIK_DOMAIN#*.}}"
[[ ${BASE_DOMAIN} && ${BASE_DOMAIN} != "${TRAEFIK_DOMAIN}" ]] \
  || fatal "cannot derive a base domain from TRAEFIK_DOMAIN='${TRAEFIK_DOMAIN}'; set WARDEN_WORKTREE_DOMAIN"

ENV_NAME="${PROJECT}-${SLUG}"
DOMAIN="${ENV_NAME}.${BASE_DOMAIN}"
DEST="${WORKTREES}/${PROJECT}/${SLUG}"

[[ -e "${DEST}" ]] && fatal "${DEST} already exists"

cd "${WARDEN_ENV_PATH}" || fatal "cannot enter ${WARDEN_ENV_PATH}"

## An existing branch is checked out as-is; a remote-only one starts tracking;
## anything else is created, from --base when given.
note "creating worktree at ${DEST}"
mkdir -p "$(dirname "${DEST}")"

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git worktree add "${DEST}" "${BRANCH}" >&2 || fatal "git worktree add failed"
elif git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  git worktree add "${DEST}" -b "${BRANCH}" --track "origin/${BRANCH}" >&2 || fatal "git worktree add failed"
else
  git worktree add "${DEST}" -b "${BRANCH}" ${BASE:+"${BASE}"} >&2 || fatal "git worktree add failed"
fi

## Warden needs a .env to see an environment at all, and it is gitignored, so
## the parent's is the only copy available to seed from.
if [[ -f "${WARDEN_ENV_PATH}/.env" ]]; then
  cp "${WARDEN_ENV_PATH}/.env" "${DEST}/.env"
  note "copied .env from the parent checkout"
else
  warning "no .env in ${WARDEN_ENV_PATH}; the worktree has none either"
fi

note "writing .env.local — env ${ENV_NAME}, domain ${DOMAIN}"
cat > "${DEST}/.env.local" <<LOCAL
## Written by 'warden worktree'. Loaded after .env and overrides it.
WARDEN_ENV_NAME=${ENV_NAME}
TRAEFIK_DOMAIN=${DOMAIN}
LOCAL

>&2 echo
>&2 echo -e "    env     \033[0;32m${ENV_NAME}\033[0m"
>&2 echo -e "    domain  \033[0;32mhttps://${DOMAIN}\033[0m"
>&2 echo
>&2 echo -e "    next    cd into it, then 'warden env up'. Application-level values"
>&2 echo -e "            such as APP_URL live in .env and are not overridden here."
>&2 echo

printf '%s\n' "${DEST}"
