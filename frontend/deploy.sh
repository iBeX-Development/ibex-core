#!/bin/bash
set -euo pipefail
export DEPLOY_TOKEN_USERNAME=$1
export DEPLOY_TOKEN_PASSWORD=$2
cd /opt/sites/cmms-front || exit

stash_created=false
if [[ -n $(git status --porcelain) ]]; then
	git stash push --include-untracked -m "pre-deploy-local-changes-$(date +%Y%m%d%H%M%S)"
	stash_created=true
fi

git config --global http.extraheader "Authorization: Basic $(echo -n $DEPLOY_TOKEN_USERNAME:$DEPLOY_TOKEN_PASSWORD | base64)" || exit
git pull --ff-only https://gitlab.com/amaraad/cmms-front.git || exit

if [[ $stash_created == true ]]; then
	git stash pop
fi

pnpm install || exit
pnpm run build || exit
pm2 restart limble-front || exit
pm2 restart smartgps-app || exit
