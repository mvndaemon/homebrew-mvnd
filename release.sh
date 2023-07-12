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

function extract_platform_url
{
    latest_version_json="$1"
    platform_search="$2"
    download_urls=$(echo "$latest_version_json" | jq --arg search "$platform_search" -r '.assets[] | select(.browser_download_url | contains($search)) | .browser_download_url')

    # download_urls can hold many versions, for instance a search on 'darwin-amd64.zip' returns:
    # https://github.com/apache/maven-mvnd/releases/download/1.0-m6/maven-mvnd-1.0-m6-m39-darwin-amd64.zip
    # https://github.com/apache/maven-mvnd/releases/download/1.0-m6/maven-mvnd-1.0-m6-m40-darwin-amd64.zip
    # The first result in descending order is assumed to be the latest build of the latest version.
    echo "$download_urls" | sort --reverse | head -n 1
}

# jq returns the following error when encountering escaped characters: "parse error: Invalid string: control characters from U+0000 through U+001F must be escaped"
# As a workaround, we pipe GitHub's JSON to sed in order to remove backslashes.
latestReleaseInfo="$(curl --location --silent "https://api.github.com/repos/mvndaemon/mvnd/releases/latest" | sed 's.\\..g')"
version="$(echo "${latestReleaseInfo}" | grep tag_name | perl -lpe 's/.*"tag_name": "(.*)".*/$1/g')"
darwinZipUrl=$(extract_platform_url "$latestReleaseInfo" "darwin-amd64.zip")
darwinSha256="$(curl -L --silent "${darwinZipUrl}.sha256")"
linuxZipUrl=$(extract_platform_url "$latestReleaseInfo" "linux-amd64.zip")
linuxSha256="$(curl -L --silent "${linuxZipUrl}.sha256")"

echo "Updating Formula/mvnd.rb with"
echo "version: ${version}"
echo "darwin-url: ${darwinZipUrl}"
echo "darwin-sha256: ${darwinSha256}"
echo "linux-url: ${linuxZipUrl}"
echo "linux-sha256: ${linuxSha256}"

perl -i -0pe 's|(on_macos do\n\s+url )\"([^\"]+)\"(\n\s+sha256 )\"([^\"]+)\"|$1\"'${darwinZipUrl}'\"$3\"'${darwinSha256}'\"|g' Formula/mvnd.rb
perl -i -0pe 's|(on_linux do\n\s+url )\"([^\"]+)\"(\n\s+sha256 )\"([^\"]+)\"|$1\"'${linuxZipUrl}'\"$3\"'${linuxSha256}'\"|g' Formula/mvnd.rb
perl -i -0pe 's|(version )"([^\"]+)"|$1\"'${version}'\"|g' Formula/mvnd.rb

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
