#!/bin/sh

# verbose and exit on error
set -xe

# import GPG keys
gpg --import /gpg/nextcloud-bot.public.asc
gpg --allow-secret-key-import --import /gpg/nextcloud-bot.asc
gpg --list-keys

# fetch git repo
git clone git@github.com:nextcloud/$1 /app

# mail specific code
php build/translation-extractor.php

# build PO file
cd l10n
wget https://raw.githubusercontent.com/owncloud/administration/master/jenkins/translation_sync/l10n.pl
perl ./l10n.pl $1 read

# push sources
tx push -s

# pull translations - force pull because a fresh clone has newer time stamps
tx pull -f -a --minimum-perc=75

# build JS/JSON based on translations
perl ./l10n.pl $1 write

rm l10n.pl
cd ..

if [ -d tests ]; then
  # remove tests/
  rm -rf tests
  git checkout -- tests/
fi

# create git commit and push it
git add l10n/*.js l10n/*.json
git commit -am "[tx-robot] updated from transifex" || true
git push origin master
echo "done"
