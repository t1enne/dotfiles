#!/bin/bash
# shellcheck disable=1090

RT_BEARER_TOKEN=""
RT_USER_ID=""

CACHE="$HOME/.cache/tcontrol.ini"

ACTIVITIES=(work organization notes)
API_BASE="https://controllo-ore.herokuapp.com/api/"

function get_token() {
	local body
	local username
	local password

	read -rp "Input username: " username
	read -rp "Input password: " password
	# create json with username and password from global vars
	body=$(echo -n "{\"username\":\"$username\",\"password\":\"$password\"}")
	response=$(curl -s "${API_BASE}users/login" \
		-H 'Accept: application/json, text/plain, */*' \
		-H 'Content-Type: application/json' \
		--data-raw $"$body" \
		--compressed)

	RT_USER_ID="$(echo "$response" | jq -r '.data | .user | ._id')"
	RT_BEARER_TOKEN="Bearer $(echo "$response" | jq -r '.data | .token')"

	cat <<EOF >"$CACHE"
RT_USER_ID="$RT_USER_ID"
RT_BEARER_TOKEN="$RT_BEARER_TOKEN"
EOF
}

# update hrs on the server
# $1 is the payload to the func
function update_hrs() {
	local url
	local body

	url="${API_BASE}working-hours/$(date +%Y-%m-%d)"
	body=$(echo "$1" | jq -r '. | { orderId, preference, organization, work, bug, newFeatures, commercial, graphics, notes, orderId }')
	response=$(curl -s -o /dev/null -w "%{http_code}\n" "$url" \
		-H 'Accept: application/json, text/plain, */*' \
		-H "Authorization: ${RT_BEARER_TOKEN}" \
		-H 'Content-Type: application/json' \
		--data-raw "$body" \
		--compressed)

	if [ $response != '201' ]; then
		echo "Something went wrong. Response status: $response" 
		exit 1
	else
		echo "Updated hrs successfully"
	fi
}

function main() {
	if [ -f "$CACHE" ]; then
		source "$CACHE"
	fi

	if [ -z "$RT_USER_ID" ]; then
		# auth
		get_token
	fi

	# fetch current projects
	current_projs=$(curl -s "${API_BASE}working-hours/mask-by-day/$(date +%Y-%m-%d)" \
		-H "Authorization: $RT_BEARER_TOKEN" | jq -c '.data[] | select(.isEnded == false)')
	
	# calculate already input hrs
	projs_with_hrs="$(echo "$current_projs" | jq -c '. | select(.work != null or .organization != null)')"
	already_input_hrs="$(echo ${projs_with_hrs} | jq -c '.work + .organization' | awk '{sum+=$0} END{print sum}')"
	echo -e "Current hrs: ${already_input_hrs}\n" 
	echo "$(echo $projs_with_hrs | jq -cr '"\(.order)\nwork: \(.work); org: \(.organization and .organization)\n"')"

	# prompt user to proceed if already input hrs
	if [ -n "$already_input_hrs" ]; then
		echo ""
		read -erp "Are you sure you want to proceed? (y/n) " -i "y" proceed
		if [ "$proceed" != "y" ]; then
			exit 0
		fi
	fi
	
	while true; do # loop prompt user
		picked_proj="$(echo "$current_projs" | jq -c '. | .order' | fzf)"
		if [ -z "$picked_proj" ]; then # exit if nothing chosen
			echo "Nothing picked, exiting"
			exit 0
		fi
		
		picked_order_name="$picked_proj" # assign order name
		picked_order=$(echo "$current_projs" | jq -c ". | select(.order == $picked_order_name)")
		picked_order_id=$(echo "$picked_order" | jq -r '.orderId')

		# echo "Fill in the fields for $picked_order_name"

		for activity in "${ACTIVITIES[@]}"; do
			starting_value=$(echo "$picked_order" | jq -r ". | .$activity | select( . != null )")
			read -erp "Input for field $activity: " -i "${starting_value}" input

			if [ -z "$input" ]; then # if empty => continue;else => update JSON
				continue
			fi
			# shellcheck disable=2001
			if [ "$activity" != "notes" ]; then # if is NOT notes, insert raw val
				picked_order=$(echo "$picked_order" | jq --argjson update "{ \"$activity\": $input }" '. + $update')
			else
				picked_order=$(echo "$picked_order" | jq --argjson update "{\"notes\": \"$input\" }" '. + $update')
			fi
		done

		PREFERENCES="{\"preference\": { \"_id\": null, \"orderId\": \"$picked_order_id\", \"userId\": \"${RT_USER_ID}\"}}"
		picked_order=$(echo "$picked_order" | jq --argjson update "$PREFERENCES" '. + $update')
		update_hrs "$picked_order"
	done
}

# Dependencies: jq, fzf
hash jq 2>/dev/null || {
	echo "Please install jq"
	exit 1
}

hash fzf 2>/dev/null || {
	echo "Please install fzf"
	exit 1
}

# run main
main
echo "All done!"
exit 0
