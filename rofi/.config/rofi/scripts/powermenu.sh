#!/bin/bash

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"

# Options
shutdown='  Shutdown'
reboot='  Reboot'
lock='  Lock'
# suspend=''
logout='  Logout'
yes='  Yes'
no='  No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $uptime"
}

# Confirmation CMD
confirm_cmd() {
	rofi -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' 
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			sudo poweroff
		elif [[ $1 == '--reboot' ]]; then
			sudo reboot
		# elif [[ $1 == '--suspend' ]]; then
		# 	mpc -q pause
		# 	amixer set Master mute
		# 	systemctl suspend
		elif [[ $1 == '--lock' ]]; then
			dm-tool lock
		elif [[ $1 == '--logout' ]]; then
			if [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
				openbox --exit
			elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
				bspc quit
			elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
				i3-msg exit
			elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
				qdbus org.kde.ksmserver /KSMServer logout 0 0 0
			fi
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
"$shutdown")
	run_cmd --shutdown
	;;
"$reboot")
	run_cmd --reboot
	;;
"$lock")
	run_cmd --lock
	;;
# "$suspend")
# 	run_cmd --suspend
# dm-tool lock
"$logout")
	run_cmd --logout
	;;
esac
