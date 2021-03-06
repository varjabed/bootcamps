#!/bin/bash
#
# Please configure according to your needs
#

MY_PC_UPGRADE_URL='http://10.21.64.50/images/nutanix_installer_package_pc-release-euphrates-5.5.0.6-stable-14bd63735db09b1c9babdaaf48d062723137fc46.tar.gz'
MY_PC_UPGRADE_META_URL='http://10.21.64.50/images/nutanix_installer_package_pc-release-euphrates-5.5.0.6-metadata.json'

# Script file name
MY_SCRIPT_NAME=`basename "$0"`

# Derive HPOC number from IP 3rd byte
#MY_CVM_IP=$(ip addr | grep inet | cut -d ' ' -f 6 | grep ^10.21 | head -n 1)
MY_CVM_IP=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2}')
array=(${MY_CVM_IP//./ })
MY_HPOC_NUMBER=${array[2]}

# Source Nutanix environments (for PATH and other things)
source /etc/profile.d/nutanix_env.sh

# Logging function
function my_log {
    #echo `$MY_LOG_DATE`" $1"
    echo $(date "+%Y-%m-%d %H:%M:%S") $1
}

# Set Prism Central Password to Prism Element Password
my_log "Setting PC password to PE password"
ncli user reset-password user-name="admin" password="${MY_PE_PASSWORD}"

# Add NTP Server\
my_log "Configure NTP on PC"
ncli cluster add-to-ntp-servers servers=0.us.pool.ntp.org,1.us.pool.ntp.org,2.us.pool.ntp.org,3.us.pool.ntp.org

# Accept Prism Central EULA
my_log "Validate EULA on PC"
curl -u admin:${MY_PE_PASSWORD} -k -H 'Content-Type: application/json' -X POST \
  https://10.21.${MY_HPOC_NUMBER}.39:9440/PrismGateway/services/rest/v1/eulas/accept \
  -d '{
    "username": "SE",
    "companyName": "NTNX",
    "jobTitle": "SE"
}'

# Disable Prism Central Pulse
my_log "Disable Pulse on PC"
curl -u admin:${MY_PE_PASSWORD} -k -H 'Content-Type: application/json' -X PUT \
  https://10.21.${MY_HPOC_NUMBER}.39:9440/PrismGateway/services/rest/v1/pulse \
  -d '{
    "emailContactList":null,
    "enable":false,
    "verbosityType":null,
    "enableDefaultNutanixEmail":false,
    "defaultNutanixEmail":null,
    "nosVersion":null,
    "isPulsePromptNeeded":false,
    "remindLater":null
}'

#my_log "Patching Calm binaries"
#remote_exec mv /usr/local/nutanix/epsilon/epsilon.tar /usr/local/nutanix/epsilon/epsilon.old
#remote_exec mv /usr/local/nutanix/epsilon/nucalm.tar /usr/local/nutanix/epsilon/nucalm.old
#remote_exec wget -nv http://10.21.64.50/images/epsilon.tar
#remote_exec wget -nv http://10.21.64.50/images/nucalm.tar
#remote_exec mv -v /home/nutanix/epsilon.tar /usr/local/nutanix/epsilon/
#remote_exec mv -v /home/nutanix/nucalm.tar /usr/local/nutanix/epsilon/

# Prism Central upgrade
my_log "Download PC upgrade image: ${MY_PC_UPGRADE_URL##*/}"
wget -nv ${MY_PC_UPGRADE_URL}

my_log "Prepare PC upgrade image"
tar -xzf ${MY_PC_UPGRADE_URL##*/}
rm ${MY_PC_UPGRADE_URL##*/}

my_log "Upgrade PC"
cd /home/nutanix/install ; ./bin/cluster -i . -p upgrade

#my_log "Opening TCP port 8090 on PC for Karan"
#remote_exec /usr/local/nutanix/cluster/bin/modify_firewall -o open -i eth0 -p 8090 -a -f
