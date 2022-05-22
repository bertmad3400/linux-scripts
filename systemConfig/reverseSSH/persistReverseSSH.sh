#!/bin/sh

createTunnel() {
	# Create a reverse ssh tunnel that will automatically background
	/usr/bin/ssh -p 5167 -N -R 0.0.0.0:2222:localhost:22 limited-user@bertmad.dk

	# Give proper output depending on the exit code of the ssh connection
	[ "$?" = 0 ] && echo "[$(date +"%F %T")] Tunnel to hermes created" || echo "[$(date +"%F %T")] An error occurred when trying to create tunnel to Hermes. Exited with code: $?"
}

echo "[$(date +"%F %T")] Creating tunnel to Hermes..."

# Checking if ssh is already connected to hermes using the limited user on port 5167; if not then trying to connect
[ "$(ps aux | grep limited-user@bertmad.dk | grep 5167 | wc -l)" = 0 ] && createTunnel || echo "[$(date +"%F %T")] Tunnel to Hermes is already established"
