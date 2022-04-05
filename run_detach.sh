#!/usr/bin/env bash

SSID=${1:-$SSID}
SSID_PASS=${2:-$SSID_PASS}
WIFI_ADAPTER=${3:-}
PROFILE=${4:-}

source common.sh
source common_run.sh

# Cutting device from cloud, allowing local-tuya access still
echo "Cutting device off from cloud.."
echo "==> Wait for 20-30 seconds for the device to connect to 'cloudcutter-flash'. This script will then show the activation requests sent by the device, and tell you whether local activation was successful."
nmcli device set ${WIFI_ADAPTER} managed no
trap "nmcli device set ${WIFI_ADAPTER} managed yes" EXIT  # Set WiFi adapter back to managed when the script exits
INNER_SCRIPT=$(xargs -0 <<- EOF
	# This janky looking string substitution is because of double evaluation.
	# Once in the parent shell script, and once in this heredoc used as a shell script.
	# First evaluate the value from the parent shell script while escaping ' chars
	# with this janky substitutions so that it doesn't break this heredoc script.
	SSID='${SSID/\'/\'\"\'\"\'}'
	SSID_PASS='${SSID_PASS/\'/\'\"\'\"\'}'
	bash /src/setup_apmode.sh ${WIFI_ADAPTER}
	pipenv run python3 -m cloudcutter configure_local_device --ssid "\${SSID}" --password "\${SSID_PASS}" "/work/device-profiles/${PROFILE}" "${CONFIG_DIR}"
EOF
)
run_in_docker bash -c "$INNER_SCRIPT"
if [ ! $? -eq 0 ]; then
    echo "Oh no, something went wrong with detaching from the cloud! Try again I guess.."
    exit 1
fi