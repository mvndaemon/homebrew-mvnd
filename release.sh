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
version="$(echo "${latestReleaseInfo}" | grep -Po '"tag_name": "\K.*?(?=")')"
zipUrl="https://github.com/mvndaemon/mvnd/releases/download/${version}/mvnd-${version}-darwin-amd64.zip"
sha256="$(curl -L --silent "${zipUrl}.sha256")"

echo "Updating Formula/mvnd.rb with"
echo "version: ${version}"
echo "url: ${zipUrl}"
echo "sha256: ${sha256}"

sed -i "s|url \"[^\"]*\"|url \"${zipUrl}\"|" Formula/mvnd.rb
sed -i "s|sha256 \"[^\"]*\"|sha256 \"${sha256}\"|" Formula/mvnd.rb
sed -i "s|version \"[^\"]*\"|version \"${version}\"|" Formula/mvnd.rb

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
