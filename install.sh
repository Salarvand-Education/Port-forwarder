#!/bin/bash

CONFIG_PATH="/usr/local/etc/xray/config.json"

function install_xray() {
  echo "Installing X-Ray Core..."
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
  if [ -f /usr/local/bin/xray ]; then
    echo "X-Ray installed successfully!"
  else
    echo "X-Ray installation failed!"
  fi
}

function uninstall_xray() {
  echo "Uninstalling X-Ray Core..."
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
  echo "X-Ray uninstalled successfully!"
}

function add_doko() {
  echo "Adding a Dokodemo Door..."
  read -p "Enter a name for the Dokodemo Door: " DOKO_NAME
  read -p "Enter the destination IP address: " DEST_IP
  read -p "Enter the destination port: " DEST_PORT
  read -p "Enter the Dokodemo Door port: " DOKO_PORT
  echo "Select the network type:"
  echo "1) TCP"
  echo "2) UDP"
  echo "3) Both (TCP, UDP)"
  read -p "Enter your choice (1/2/3): " NETWORK_CHOICE

  case $NETWORK_CHOICE in
    1) NETWORK_TYPE="tcp" ;;
    2) NETWORK_TYPE="udp" ;;
    3) NETWORK_TYPE="tcp,udp" ;;
    *) echo "Invalid choice. Defaulting to 'tcp,udp'."; NETWORK_TYPE="tcp,udp" ;;
  esac

  jq ".inbounds += [{
    \"listen\": null,
    \"port\": $DOKO_PORT,
    \"protocol\": \"dokodemo-door\",
    \"settings\": {
      \"address\": \"$DEST_IP\",
      \"followRedirect\": false,
      \"network\": \"$NETWORK_TYPE\",
      \"port\": $DEST_PORT
    },
    \"tag\": \"$DOKO_NAME\"
  }]" $CONFIG_PATH > temp.json && mv temp.json $CONFIG_PATH

  echo "Dokodemo Door '$DOKO_NAME' added successfully!"
  systemctl restart xray
}

function remove_doko() {
  echo "Removing a Dokodemo Door..."
  read -p "Enter the name of the Dokodemo Door to remove: " DOKO_NAME

  jq "del(.inbounds[] | select(.tag == \"$DOKO_NAME\"))" $CONFIG_PATH > temp.json && mv temp.json $CONFIG_PATH

  echo "Dokodemo Door '$DOKO_NAME' removed successfully!"
  systemctl restart xray
}

function list_dokos() {
  echo "Listing all Dokodemo Doors..."
  jq '.inbounds[] | {name: .tag, port: .port, address: .settings.address, network: .settings.network}' $CONFIG_PATH
}

function remove_all_dokos() {
  echo "Removing all Dokodemo Doors..."
  jq 'del(.inbounds)' $CONFIG_PATH > temp.json && mv temp.json $CONFIG_PATH

  echo "All Dokodemo Doors removed successfully!"
  systemctl restart xray
}

function forward_ports() {
  echo "Forwarding ports..."
  read -p "Enter the range of ports to forward (e.g., 1000-2000 or a single port like 8080): " PORTS
  read -p "Enter the destination IP address: " DEST_IP
  read -p "Enter the destination port: " DEST_PORT
  echo "Select the network type:"
  echo "1) TCP"
  echo "2) UDP"
  echo "3) Both (TCP, UDP)"
  read -p "Enter your choice (1/2/3): " NETWORK_CHOICE

  case $NETWORK_CHOICE in
    1) NETWORK_TYPE="tcp" ;;
    2) NETWORK_TYPE="udp" ;;
    3) NETWORK_TYPE="tcp,udp" ;;
    *) echo "Invalid choice. Defaulting to 'tcp,udp'."; NETWORK_TYPE="tcp,udp" ;;
  esac

  if [[ $PORTS == *-* ]]; then
    START_PORT=$(echo $PORTS | cut -d '-' -f 1)
    END_PORT=$(echo $PORTS | cut -d '-' -f 2)
    for PORT in $(seq $START_PORT $END_PORT); do
      jq ".inbounds += [{
        \"listen\": null,
        \"port\": $PORT,
        \"protocol\": \"dokodemo-door\",
        \"settings\": {
          \"address\": \"$DEST_IP\",
          \"followRedirect\": false,
          \"network\": \"$NETWORK_TYPE\",
          \"port\": $DEST_PORT
        },
        \"tag\": \"doko-$PORT\"
      }]" $CONFIG_PATH > temp.json && mv temp.json $CONFIG_PATH
    done
  else
    jq ".inbounds += [{
      \"listen\": null,
      \"port\": $PORTS,
      \"protocol\": \"dokodemo-door\",
      \"settings\": {
        \"address\": \"$DEST_IP\",
        \"followRedirect\": false,
        \"network\": \"$NETWORK_TYPE\",
        \"port\": $DEST_PORT
      },
      \"tag\": \"doko-$PORTS\"
    }]" $CONFIG_PATH > temp.json && mv temp.json $CONFIG_PATH
  fi

  echo "Ports forwarded successfully!"
  systemctl restart xray
}

function show_menu() {
  echo "========================================="
  echo "           X-Ray Management Tool         "
  echo "========================================="
  echo "1) Install X-Ray"
  echo "2) Uninstall X-Ray"
  echo "3) Add a Dokodemo Door"
  echo "4) Remove a Dokodemo Door"
  echo "5) List all Dokodemo Doors"
  echo "6) Remove all Dokodemo Doors"
  echo "7) Forward Ports"
  echo "8) Exit"
  echo "========================================="
}

while true; do
  show_menu
  read -p "Choose an option: " CHOICE
  case $CHOICE in
    1) install_xray ;;
    2) uninstall_xray ;;
    3) add_doko ;;
    4) remove_doko ;;
    5) list_dokos ;;
    6) remove_all_dokos ;;
    7) forward_ports ;;
    8) exit 0 ;;
    *) echo "Invalid choice. Please try again." ;;
  esac
done
