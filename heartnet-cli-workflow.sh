#! /usr/bin/env bash
# heartnet-docker-workflow.sh
# This script requires a running witness network and it sets it up and tears it down at the end of the script.

source print-colors.sh

# clear out any existing KERI keystores -- WARNING: this will delete all existing KERI keystores
print_red "Clearing out existing KERI keystores, press Enter to continue"
read -r
rm -rfv ${HOME}/.keri && rm -rfv /usr/local/var/keri

# Function to wait for a port to be accepting connections
wait_for() {
  local host=$1
  local port=$2
  local timeout=${3:-30}

  for ((i=0; i<timeout; i++)); do
    if nc -z "$host" "$port"; then
      return 0
    fi
    sleep 1
  done

  return 1
}

#
# Start witness network
#
PID_LIST=""
kli witness demo &
pid=$!
PID_LIST+="${pid}"
print_green "Witness network started with PID: ${pid}"
print_lcyan "Waiting 5 seconds for witness network to accept connections"
sleep 5
# Wait for the HTTP port 5642 or TCP port 5632 to be accepting connections
if wait_for 127.0.0.1 5642 || wait_for 127.0.0.1 5632; then
  print_green "Witness network is accepting connections"
else
  print_red "Timeout waiting for witness network to accept connections"
  exit 1
fi

export WAN_WITNESS_AID="BBilc4-L3tFUnfM_wJr4S4OJanAv_VmF_dJNN6vkf2Ha"
export WIL_WITNESS_AID="BLskRTInXnMxWaGqcpSyMgo0nYbalW99cGZESrz3zapM"
export WES_WITNESS_AID="BIKKuvBwpmDVA4Ds-EpL5bt9OqPzWPja2LigFYZN2YfX"
export WIT_WITNESS_AID="BM35JN8XeJSEfpxopjn5jr7tAHCE5749f0OobhMLCorE"
export WUB_WITNESS_AID="BIj15u5V11bkbtAxMA7gcNJZcax-7TgaBMLsQnMHpYHP"
export WYZ_WITNESS_AID="BF2rZTW79z4IXocYRQnjjsOuvFUQv-ptCf8Yltd7PfsM"
#
# Create keystore configuration files for Allie and Brett
#
print_lcyan "Creating keystore configuration files for Allie and Brett"
echo

# read in keystore configuration JSON from heredoc
read -r -d '' ALLIE_KEYSTORE_CONFIG_JSON <<EOM
{
  "dt": "2022-01-20T12:57:59.823350+00:00",
  "iurls": [
    "http://127.0.0.1:5642/oobi/${WAN_WITNESS_AID}/controller",
    "http://127.0.0.1:5643/oobi/${WIL_WITNESS_AID}/controller",
    "http://127.0.0.1:5644/oobi/${WES_WITNESS_AID}/controller"
  ]
}
EOM

# Create temporary file to store the JSON config
temp_allie_keystore_config=$(mktemp)
# write the JSON config to the temporary file
echo "${ALLIE_KEYSTORE_CONFIG_JSON}" >${temp_allie_keystore_config}
# add .json extension to the temporary file so it is usable by the KERI CLI
cp -v ${temp_allie_keystore_config} ${temp_allie_keystore_config}.json
print_lcyan "Allie's keystore configuration file created"
cat ${temp_allie_keystore_config}.json
echo

read -r -d '' BRETT_KEYSTORE_CONFIG_JSON <<EOM
{
  "dt": "2022-01-20T12:57:59.823350+00:00",
  "iurls": [
    "http://127.0.0.1:5645/oobi/${WIT_WITNESS_AID}/controller",
    "http://127.0.0.1:5646/oobi/${WUB_WITNESS_AID}/controller",
    "http://127.0.0.1:5647/oobi/${WYZ_WITNESS_AID}/controller"
  ]
}
EOM

temp_brett_keystore_config=$(mktemp)
echo "${BRETT_KEYSTORE_CONFIG_JSON}" >${temp_brett_keystore_config}
cp -v ${temp_brett_keystore_config} ${temp_brett_keystore_config}.json
print_lcyan "Brett's keystore configuration file created"
cat ${temp_brett_keystore_config}.json
echo

#
# Create keystores for Allie and Brett
#
export ALLIE_SALT=0AAiU3Ih3WYmTuWWymZTYFbP # Use hardcoded salt for tutorial purposes
print_yellow "using hardcoded salt for Allie: ${ALLIE_SALT}"
# use export ALLIE_SALT="$(kli salt)" to get your own unique salt value if you want
kli init \
    --name allie_ks \
    --nopasscode \
    --salt ${ALLIE_SALT} \
    --config-file ${temp_allie_keystore_config}.json
echo

export BRETT_SALT=0ABfYE2dBj96dT9MNMFIT4Fw # Use hardcoded salt for tutorial purposes
print_yellow "using hardcoded salt for Brett: ${BRETT_SALT}"
# use export BRETT_SALT="$(kli salt)" to get your own unique salt value if you want
kli init \
    --name brett_ks \
    --nopasscode \
    --salt ${BRETT_SALT} \
    --config-file ${temp_brett_keystore_config}.json
echo    

#
# Create inception configuration and events
#

# Create inception configuration files for Allie and Brett
read -r -d '' ALLIE_AID_INCEPTION_CONFIG <<EOM
{
  "transferable": true,
  "wits": [
    "${WAN_WITNESS_AID}",
    "${WIL_WITNESS_AID}",
    "${WES_WITNESS_AID}"
  ],
  "toad": 3,
  "icount": 1,
  "ncount": 1,
  "isith": "1",
  "nsith": "1"
}
EOM

temp_allie_aid_inception_config=$(mktemp)
echo "${ALLIE_AID_INCEPTION_CONFIG}" >${temp_allie_aid_inception_config}
cp -v ${temp_allie_aid_inception_config} ${temp_allie_aid_inception_config}.json
print_lcyan "Allie's inception configuration file created"
cat ${temp_allie_aid_inception_config}.json
echo

read -r -d '' BRETT_AID_INCEPTION_CONFIG <<EOM
{
  "transferable": true,
  "wits": [
    "${WIT_WITNESS_AID}",
    "${WUB_WITNESS_AID}",
    "${WYZ_WITNESS_AID}"
  ],
  "toad": 3,
  "icount": 1,
  "ncount": 1,
  "isith": "1",
  "nsith": "1"
}
EOM

temp_brett_aid_inception_config=$(mktemp)
echo "${BRETT_AID_INCEPTION_CONFIG}" >${temp_brett_aid_inception_config}
cp -v ${temp_brett_aid_inception_config} ${temp_brett_aid_inception_config}.json
print_lcyan "Brett's inception configuration file created"
cat ${temp_brett_aid_inception_config}.json
echo

# Create inception events for Allie and Brett
print_green "Creating inception event for Allie"
kli incept \
    --name allie_ks \
    --alias magic-pencil \
    -f ${temp_allie_aid_inception_config}.json
echo

# Allie's prefix will always be EFgDuEHVf7HtqPQ5Ng_rctkXIRqNNIZEUH9svN7AFzjg because of the hardcoded salt
# If you use your own salt you will get a different prefix
export ALLIE_PREFIX=EFgDuEHVf7HtqPQ5Ng_rctkXIRqNNIZEUH9svN7AFzjg
print_lcyan "Allie's identifier prefix (AID) is: ${ALLIE_PREFIX}"

# Create inception event for Brett
print_green "Creating inception event for Brett"
kli incept \
    --name brett_ks \
    --alias secret-speaker \
    -f ${temp_brett_aid_inception_config}.json

# Brett's prefix will always be EMRWalfLnVV2QVGr9Uk7D65smF39W8qZuhwajb4C0w6j because of the hardcoded salt
# If you use your own salt you will get a different prefix
export BRETT_PREFIX=EMRWalfLnVV2QVGr9Uk7D65smF39W8qZuhwajb4C0w6j
print_lcyan "Brett's identifier prefix (AID) is: ${BRETT_PREFIX}"

#
# Generate OOBI URLs and store them in a variable with "head" and command substitution
#
print_green "Generating OOBI URLs for Allie and Brett"

# Allie
export ALLIE_OOBI=$(kli oobi generate \
    --name allie_ks \
    --alias magic-pencil \
    --role witness | head -n 1)
print_lcyan "Allie's OOBI is: ${ALLIE_OOBI}"
echo

# Brett
export BRETT_OOBI=$(kli oobi generate \
    --name brett_ks \
    --alias secret-speaker \
    --role witness | head -n 1)
print_lcyan "Brett's OOBI is: ${BRETT_OOBI}"
echo

#
# Perform introductions with OOBI URLs
#
print_lcyan "Performing introductions with OOBI URLs"

# Brett discovers Allie
kli oobi resolve \
    --name brett_ks \
    --oobi-alias magic-pencil \
    --oobi "${ALLIE_OOBI}"
echo

# Allie discovers Brett
kli oobi resolve \
    --name allie_ks \
    --oobi-alias secret-speaker \
    --oobi "${BRETT_OOBI}"
echo

#
# Challenge responses
#
print_lcyan "Performing challenge responses"

# Generate Challenge words for each party

# Brett sets up challenge for Allie
export BRETT_WORDS="$(kli challenge generate --out string)"
print_green "Brett's challenge words to Allie are:"
print_green "${BRETT_WORDS}"
# Brett gives these words to Allie out of band in a way he trusts such as on a video call.

print_lcyan "Allie responds to the challenge"
# Allie responds to the challenge
kli challenge respond \
    --name allie_ks \
    --alias magic-pencil \
    --recipient secret-speaker \
    --words "${BRETT_WORDS}"
echo 

# Brett verifies the challenge response by checking that the signed words match what he sent Allie.
print_lcyan "Brett verifies the challenge response"
kli challenge verify \
    --name brett_ks \
    --alias secret-speaker \
    --signer magic-pencil \
    --words "${BRETT_WORDS}"
echo    

# Allie sets up challenge for Brett
export ALLIE_WORDS="$(kli challenge generate --out string)"
print_green "Allie's challenge words to Brett are:"
print_green "${ALLIE_WORDS}"

print_lcyan "Brett responds to the challenge"
kli challenge respond \
    --name brett_ks \
    --alias secret-speaker \
    --recipient magic-pencil \
    --words "${ALLIE_WORDS}"
echo

print_lcyan "Allie verifies the challenge response"
kli challenge verify \
    --name allie_ks \
    --alias magic-pencil \
    --signer secret-speaker \
    --words "${ALLIE_WORDS}"
echo

print_red "##################################################"
print_red "Allie and Brett are sending love letters"
print_red "##################################################"
echo

print_green "Allie writes a love letter."
love_letter=$(mktemp)
cp -v ${love_letter} ${love_letter}.json
echo '{"love_letter": "well, hello there, honey. Happy Valentines :*"}' >${love-letter}.json

# Allie signs the love letter
print_lcyan "Allie signs the love letter"
export ALLIE_SIGNATURE=$(kli sign \
    --name allie_ks \
    --alias magic-pencil \
    --text ${love_letter}.json | sed -E 's/^[0-9]+\. //')

# Brett verifies the love letter
print_red "Brett verifies the love letter"
kli verify \
    --name brett_ks \
    --alias secret-speaker \
    --prefix ${ALLIE_PREFIX} \
    --text ${love_letter}.json \
    --signature $ALLIE_SIGNATURE

# Brett writes and signs the love letter reply
print_green "Brett writes a love letter reply."
love_letter_reply=$(mktemp)
cp -v ${love_letter_reply} ${love_letter_reply}.json
echo '{"love_letter": "Hey sweetie, I got your letter! <3 <3"}' >${love_letter_reply}.json

print_lcyan "Brett signs the love letter reply"
export BRETT_SIGNATURE=$(kli sign \
    --name brett_ks \
    --alias secret-speaker \
    --text ${love_letter_reply}.json | sed -E 's/^[0-9]+\. //')

# Allie verifies the love letter reply
print_red "Allie verifies the love letter reply"
kli verify \
    --name allie_ks \
    --alias magic-pencil \
    --prefix ${BRETT_PREFIX} \
    --text ${love_letter_reply}.json \
    --signature $BRETT_SIGNATURE    

print_green "Success! Allie and Brett have exchanged love letters."

print_red "##################################################"
print_red "Removing temp files and tearing down the witness network"
print_red "##################################################"
# remove temporary files
rm -fv ${temp_allie_keystore_config}
rm -fv ${temp_allie_keystore_config}.json
rm -fv ${temp_brett_keystore_config}
rm -fv ${temp_brett_keystore_config}.json
rm -fv ${temp_allie_aid_inception_config}
rm -fv ${temp_allie_aid_inception_config}.json
rm -fv ${temp_brett_aid_inception_config}
rm -fv ${temp_brett_aid_inception_config}.json
rm -fv ${love_letter}
rm -fv ${love_letter}.json
rm -fv ${love_letter_reply}
rm -fv ${love_letter_reply}.json

print_red "Tearing down the witness network with PID: ${PID_LIST}"
kill -9 ${PID_LIST}
echo

print_lcyan "Heartnet sign and verify workflow complete"

echo
