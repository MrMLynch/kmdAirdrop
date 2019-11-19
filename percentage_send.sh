#!/bin/bash
# (c) Decker, 2018
# (c) mrlynch, 2019
#
# Don't edit unless you know what you're doing
# Only thing you need to worry about is percentage_config.json; edit that - see percentage_config.json.example

cd "${BASH_SOURCE%/*}" || exit

RESET="\033[0m"
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

if [ ! -f $HOME/.komodo/komodo.conf ]; then
  echo -e "${RED}Error: komodo.conf not found in $HOME/.komodo/${RESET}"
  exit 0
fi

source ~/.komodo/komodo.conf

if [ ! -f percentage_config.json ]; then
  echo -e "${RED}Error: percentage_config.json not found in $(pwd)${RESET}"
  exit 0
fi

beneficiaries=$(cat percentage_config.json | jq -r '.beneficiaries')
changeAddress=$(cat percentage_config.json | jq -r '.change')
donees=($(echo ${beneficiaries} | jq -r 'keys_unsorted | .[]'))
curlport=$(cat percentage_config.json | jq -r '.curlport')

echo -e 'KMD Percentage SendMany Script v0.1alpha (c) '${MAGENTA}mrlynch${RESET}, 2019
echo    '=========================================================='

curl -s --user $rpcuser:$rpcpassword --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "listunspent", "params": [0, 9999999]}' -H 'content-type: text/plain;' http://127.0.0.1:$curlport/ | jq .result > createrawtx.txt

# all spendable txids over 1 KMD will be used to calculate total balance
transactions=$(cat createrawtx.txt | jq '.[] | select (.spendable == true and .amount > 1) | del (.generated, .address, .segid, .account, .amount, .interest, .scriptPubKey, .rawconfirmations, .confirmations, .spendable)' | jq -r -s '. | tostring')
balance=$(cat createrawtx.txt | jq '.[] | select (.spendable == true and .amount > 1) | .amount' | jq -s add)
balance=$(echo "scale=8; $balance/1*1" | bc -l | sed 's/^\./0./')

addresses='{'
# this is used to calculate change if any
totalsend=0

echo -e 'Balance: '${GREEN}$balance${RESET}

for don in "${donees[@]}"; do
  address=$(echo ${beneficiaries} | jq -r .\"${don}\".address)
  pct=$(echo ${beneficiaries} | jq -r .\"${don}\".percentage)
  amount=$(echo "scale=8; $pct/100*$balance" | bc -l | sed 's/^\./0./')
  echo -e ${BLUE}${don}${RESET}" address: $address\t\tpercentage: "${GREEN}$pct${RESET}'\t\tamount: '${GREEN}$amount${RESET}
  totalsend=$(echo "scale=8; ($totalsend+$amount)" | bc -l | sed 's/^\./0./')
  if [ "${don}" == "${donees[-1]}" ]; then
    addresses=$(echo ${addresses}'"'${address}'"': $amount)
  else
    addresses=$(echo ${addresses}'"'${address}'"': $amount', ')
  fi
done

change=$(echo "scale=8; ($balance-$totalsend)/1*1" | bc -l | sed 's/^\./0./')

# check for change bigger than 0.1 - if you have 0.00000003 you won't be able to send
if (( $(echo "$change > 0.001" | bc -l) )); then
  addresses=$(echo ${addresses}', "'${changeAddress}'"': $change'}')
  echo -e "Change: ${GREEN}$change${RESET}"
else
  addresses=$(echo ${addresses}'}')
  echo -e "Change: ${GREEN}$change${RESET}"
fi


### create raw tx
echo "{\"jsonrpc\": \"1.0\", \"id\":\"curltest\", \"method\": \"createrawtransaction\", \"params\": [$transactions,$addresses] }" > createrawtx.curl

hex=$(curl -s --user $rpcuser:$rpcpassword --data-binary "@createrawtx.curl" -H 'content-type: text/plain;' http://127.0.0.1:$curlport/ | jq -r .result)

# setting of nLockTime
nlocktime=$(printf "%08x" $(date +%s) | dd conv=swab 2> /dev/null | rev)

txtail=000000000000000000000000000000
hex=${hex::-38}${nlocktime}${txtail}

### sign raw tx
signed=$(curl -s --user $rpcuser:$rpcpassword --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "signrawtransaction", "params": ["'$hex'"]}' -H 'content-type: text/plain;' http://127.0.0.1:$curlport/  | jq -r .result.hex)

echo -e '\n'
echo -e ${YELLOW}'Unsigned TX: '${RESET}$hex
echo -e '\n'
echo -e ${YELLOW}'Signed TX: '${RESET}$signed
echo -e '\n'
echo -e 'Now you are able to broadcast your signed tx via "sendrawtransaction" or in any Insight Explorer. '${GREEN}'Verify it before broadcast!'${RESET}


### Uncomment these if you want to auto-send although it is best to manually broadcast in explorer.

#echo "{\"jsonrpc\": \"1.0\", \"id\":\"curltest\", \"method\": \"sendrawtransaction\", \"params\": [\"$signed\"] }" > sendrawtx.curl
#curl -s --user $rpcuser:$rpcpassword --data-binary "@sendrawtx.curl" -H 'content-type: text/plain;' http://127.0.0.1:$curlport/
