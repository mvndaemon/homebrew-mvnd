#!/usr/bin/env bash
#
# Copyright 2019 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


set -e
#set -x

latestReleaseInfo="$(curl --silent "https://api.github.com/repos/mvndaemon/mvnd/releases/latest")"
version="$(echo "${latestReleaseInfo}" | grep tag_name | perl -lpe 's/.*"tag_name": "(.*)".*/$1/g')"
darwinZipUrl="https://github.com/mvndaemon/mvnd/releases/download/${version}/mvnd-${version}-darwin-amd64.zip"
darwinSha256="$(curl -L --silent "${darwinZipUrl}.sha256")"
linuxZipUrl="https://github.com/mvndaemon/mvnd/releases/download/${version}/mvnd-${version}-linux-amd64.zip"
linuxSha256="$(curl -L --silent "${linuxZipUrl}.sha256")"

echo "Updating Formula/mvnd.rb with"
echo "version: ${version}"
echo "darwin-url: ${darwinZipUrl}"
echo "darwin-sha256: ${darwinSha256}"
echo "linux-url: ${linuxZipUrl}"
echo "linux-sha256: ${linuxSha256}"

perl -i -0pe 's|(on_macos do\n\s+url )\"([^\"]+)\"(\n\s+sha256 )\"([^\"]+)\"|$1\"'${darwinZipUrl}'\"$3\"'${darwinSha256}'\"|g' Formula/mvnd.rb
perl -i -0pe 's|(on_linux do\n\s+url )\"([^\"]+)\"(\n\s+sha256 )\"([^\"]+)\"|$1\"'${linuxZipUrl}'\"$3\"'${linuxSha256}'\"|g' Formula/mvnd.rb

if [ -n "$(git status --porcelain)" ]; then
    echo "Committing release ${version}"
    git config --global user.email "ppalaga@redhat.com"
    git config --global user.name "Peter Palaga"
    git add -A
    git commit -m "Release ${version}"
    git push upstream master
else
    echo "Nothing to commit"
fi
