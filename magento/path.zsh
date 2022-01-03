export CLOUDCLIPATH=$HOME/.magento-cloud/bin
export PATH="$CLOUDCLIPATH/bin:$PATH"

if [ -f "$HOME/"'.magento-cloud/shell-config.rc' ]; then . "$HOME/"'.magento-cloud/shell-config.rc'; fi
