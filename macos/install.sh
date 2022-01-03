# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. There's a nifty
# command line interface to it that we can use to just install everything, so
# yeah, let's do that.

if [[ $OSTYPE =~ ^darwin ]] && [[ `uname -m` == 'arm64' ]]; then
 sudo softwareupdate --install-rosetta --agree-to-license
fi

echo "› sudo softwareupdate -i -a"
sudo softwareupdate -i -a
