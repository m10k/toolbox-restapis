#!/bin/bash

# spotify.sh - Spotify module for Toolbox
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
	if ! include "log" "json"; then
		return 1
	fi

	return 0
}

_spotify_make_authstring() {
	local client_id="$1"
	local client_secret="$2"

	local raw
	local encoded

	raw="$client_id:$client_secret"

	if ! encoded=$(echo -n "$client_id:$client_secret" | base64 -w 0); then
		return 1
	fi

	echo "$encoded"
	return 0
}

spotify_token_new() {
	local client_id="$1"
	local client_secret="$2"

	local now
	local url
	local auth
	local response
	local error
	local access_token
	local valid_until
	local expires_in

	url="https://accounts.spotify.com/api/token"

	if ! now=$(date +"%s"); then
		log_error "Could not get a timestamp. OOM?"
		return 1
	fi

	if ! auth=$(_spotify_make_authstring "$client_id" "$client_secret"); then
		return 1
	fi

	if ! response=$(curl --request POST --url "$url" --silent                       \
	                     --header "Authorization: Basic $auth"                      \
	                     --header "Content-Type: application/x-www-form-urlencoded" \
	                     --data   "grant_type=client_credentials"); then
		log_error "Could not reach Spotify API"
		return 1
	fi

	if error=$(json_object_get "$response" "error_description") &&
	   [[ "$error" != "null" ]]; then
		log_error "Could not authorize with Spotify API: $error"
		return 1
	fi

	if ! access_token=$(json_object_get "$response" "access_token"); then
		log_error "No access token in response from Spotify API"
		return 1
	fi

	if ! expires_in=$(json_object_get "$response" "expires_in"); then
		log_error "No expiration in response from Spotify API"
		return 1
	fi

	valid_until=$((now + expires_in))
	echo "$valid_until:$access_token"

	return 0
}

spotify_token_get_expiration() {
	local token="$1"

	echo "${token%%:*}"
	return 0
}

spotify_token_get_data() {
	local token="$1"

	echo "${token#*:}"
	return 0
}

spotify_token_expired() {
	local token="$1"

	local -i expiration
	local now

	if ! now=$(date +"%s"); then
		log_error "Could not get a timestamp. OOM?"
		return 1
	fi

	expiration=$(spotify_token_get_expiration "$token")

	if (( expiration <= now )); then
		return 0
	fi

	return 1
}

spotify_search() {
	local token="$1"
	local query="$2"
	local type="$3"
	local -i limit="$4"
	local -i offset="$5"

	local url
	local response
	local access_token

	if (( $# < 4 )); then
		limit=50
	fi

	if (( $# < 3 )); then
		type="album,artist,track"
	fi

	access_token=$(spotify_token_get_data "$token")
	url="https://api.spotify.com/v1/search?q=$query&type=$type&limit=$limit&offset=$offset"

	if ! response=$(curl --request GET --url "$url"                     \
	                     --header "Authorization: Bearer $access_token" \
	                     --header 'Content-Type: application/json'); then
		log_error "Could not contact Spotify API"
		return 1
	fi

	echo "$response"
	return 0
}

spotify_album_get() {
	local token="$1"
	local album="$2"

	local url
	local result
	local access_token

	url="https://api.spotify.com/v1/albums/$album"
	access_token=$(spotify_token_get_data "$token")

	if ! result=$(curl --request GET --url "$url" --silent            \
	                   --header "Authorization: Bearer $access_token" \
	                   --header "Content-Type: application/json"); then
		return 1
	fi

	echo "$result"
	return 0
}
