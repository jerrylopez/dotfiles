<h3 align="center">dotfiles</h3>

<p align="center">
My personal system configuration files, managed with <a href="https://github.com/anishathalye/dotbot">Dotbot</a>.<br />
One repo, two machines: a macOS workstation and a headless Ubuntu dev server.
</p>

<hr />

## Install

The repo has to live at `~/.dotfiles` — `$ZSH` and the `config/bin` PATH entry point there.

```sh
git clone --recurse-submodules git@github.com:jerrylopez/dotfiles.git ~/.dotfiles
~/.dotfiles/script/bootstrap
```

`bootstrap` works out which platform it is on, installs Homebrew and that
platform's package list, then links everything into place. It is idempotent —
re-run it whenever.

On Linux it also makes zsh the login shell, which takes effect at the next login.

## Scripts

| Command | What it does |
| --- | --- |
| `script/bootstrap` | Full setup: packages and config, dispatching per platform. |
| `script/install` | Symlinks only. Run this after adding a link to a Dotbot config. |
| `script/update` | Updates Homebrew and Composer, re-bundles. Also aliased to `update`. |
| `script/defaults` | macOS system preferences. Called by bootstrap. |
| `script/lib/platform` | Echoes `macos` or `linux`. Everything else dispatches on this. |

## The platform split

`script/lib/platform` names the machine, and that name is the suffix on every
file that differs:

| | macOS | Linux |
| --- | --- | --- |
| Bootstrap | `script/bootstrap.macos` | `script/bootstrap.linux` |
| Packages | `config/homebrew/Brewfile.macos` | `config/homebrew/Brewfile.linux` |
| Symlinks | `install.macos.conf.yaml` | `install.linux.conf.yaml` |
| Shell | `config/shell/os/macos.zsh` | `config/shell/os/linux.zsh` |

Everything else is shared — `install.conf.yaml` holds the links both machines
want, and `config/shell/*.zsh` the shell config they both load.

**To add something OS-specific**, put it in that platform's file. Both shell
files are kept out of the zshrc glob that loads everything else; only the
matching one is sourced, after the shared files so it can override them, and
before `compinit` so anything it adds to `fpath` is seen.

### What actually differs

**macOS** is the workstation: GUI casks, Aerospace, Ghostty, VS Code settings
under `~/Library`, and system defaults.

**Linux** is a headless Ubuntu/Debian box: no casks, no GUI config, `$EDITOR`
is `nvim` rather than `code`, and Homebrew lives in `/home/linuxbrew`.

`script/defaults` has no Linux counterpart — there is no GUI there to
configure.

## Layout

```
config/
  aerospace/ ghostty/ vscode/   macOS GUI apps
  homebrew/                     Brewfile.macos, Brewfile.linux
  nvim/                         LazyVim; lazy-lock.json is committed
  shell/                        aliases, exports, functions — plus os/
  zsh/                          zshrc and core zsh config
  bin/                          wt, on PATH
  git/ claude/ agents/ composer/ herdr/
script/                         bootstrap, install, update, lib/platform
install.conf.yaml               shared links (+ .macos, .linux)
```

## Local overrides

`~/.localrc` is sourced first, if it exists, and `~/.gitconfig.local` is pulled
in by the git config. Both are for the machine-specific things that should stay
out of a public repo.
