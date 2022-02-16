#!/bin/bash

# slack.sh - Slack module for Toolbox
# Copyright (C) 2022 Matthias Kruk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

__init() {
	if ! include "json"; then
		return 1
	fi

	return 0
}

slack_chat_post_message() {
	local token="$1"
	local recipient="$2"
	local text="$3"

	local json
	local resp

	json=$(json_object "channel" "$recipient" \
	                   "text"    "$text")

	if ! resp=$(curl -X POST --data "$json"                                   \
	                 --header "Content-Type: application/json; charset=UTF-8" \
	                 --header "Authorization: Bearer $token"                  \
	                 "https://slack.com/api/chat.postMessage" 2>&1); then
		return 1
	fi

	return 0
}

slack_markdown_link() {
	local url="$1"
	local title="$2"

	if ! printf '<%s|%s>' "$url" "$title"; then
		return 1
	fi

	return 0
}

slack_markdown_quote() {
	local quote="$1"

	local line

	if (( $# < 1 )); then
		quote=$(< /dev/stdin)
	fi

	while IFS="" read -r line; do
		if ! printf "> %s\n" "$line"; then
			return 1
		fi
	done <<< "$quote"

	return 0
}

slack_markdown_code() {
	local code="$1"

	if (( $# < 1 )); then
		code=$(< /dev/stdin)
	fi

	if ! printf '```\n%s\n```\n' "$code"; then
		return 1
	fi

	return 0
}
