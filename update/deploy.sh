#!/bin/bash

function list_tags() {
  image="$1"
  tags=`wget -q https://registry.hub.docker.com/v1/repositories/${image}/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'`

  if [ -n "$2" ]
  then
      tags=` echo "${tags}" | grep "$2" `
  fi
  echo $tags
}

tags=$(list_tags "homeassistant/home-assistant" "^[0-9]*\.[0-9]*\.[0-9]*$") # include only STABLE versions
ha_tags=($tags)
fn='helm.yaml'
ha_latest=${ha_tags[-1]}
tag=$(egrep 'tag:\s*([0-9\.]+)' helm.yaml)
ha_current=$(echo $tag | sed 's|tag:||' | sed 's| ||g')
upgrade="n"

if [[ "$ha_latest" == "$ha_current" ]]; then
  read -p "Already on version ${ha_latest}. Re-deploy? [Y/n] " restart
  if [[ "$restart" != "Y" ]]; then exit 0; fi
else
  read -p "Upgrade from ${ha_current} to ${ha_latest} [Y/n] " upgrade
  if [[ "$upgrade" != "Y" ]]; then exit 0; fi
fi

if [[ "$upgrade" == "Y" ]]; then
  echo "Upgrading to ${ha_latest}..."
  sed -i "s|$ha_current|$ha_latest|" $fn
fi

helm upgrade --install -f $fn house ~/charts/stable/home-assistant
