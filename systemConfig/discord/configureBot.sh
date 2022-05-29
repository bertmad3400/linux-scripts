#!/bin/bash

echo -n "Enter project name: "
read projectName

while [ "$(expr "$projectName" : ^[a-z][-a-z0-9]*\$)" = 0 ]
do
	echo -n 'Please enter a project name which matches this regex "^[a-z][-a-z0-9]*\$)": '
	read projectName
done

echo -n "Enter git URL: "
read gitURL

echo -n "Enter discord bot token: "
read botToken

projectPath="/srv/discordBots/$projectName"

serviceFile="[Unit]
Description=Discord bot for $projectName
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
Environment='PYTHONUNBUFFERED=1 PYTHONPATH=${projectPath}'
User=$projectName
WorkingDirectory=$projectPath
ExecStart=${projectPath}/VEnv/bin/python3 -m app

[Install]
WantedBy=multi-user.target"


mkdir -p "/srv/discordBots" || { echo "Could not create folder for discord bots"; exit 1; }
git clone $gitURL "$projectPath" || { echo "Could not clone the needed source files from github to $projectPath"; exit 1; }

echo "$botToken" > "${projectPath}/token.secret" || { echo "Could not write bot token to file"; exit 1; }

chmod 400 "${projectPath}/token.secret"

useradd -U -d "$projectPath" -M -s "/bin/false" "$projectName" || { echo "Could not create the $projectName user, used for running the bot"; exit 1; }

chown -R ${projectName}:${projectName} "$projectPath" || { echo "Could not transfer ownership of the $projectPath directory to the $projectName user"; exit 1; }

sudo -u "$projectName" python -m venv "${projectPath}/VEnv" || { echo "Could not create virtual enviroment at ${projectPath}/VEnv"; exit 1; }

sudo -u "$projectName" "${projectPath}/VEnv/bin/pip" install -r "${projectPath}/requirements.txt" || { echo "Could not install requirements found at ${projectPath}/requirements.txt"; exit 1; }


echo "$serviceFile" > "/etc/systemd/system/${projectName}.service" || { echo "Could not install service file for discord bot"; exit 1; }

systemctl enable --now "$projectName"
