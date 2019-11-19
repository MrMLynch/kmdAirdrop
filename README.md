# KMD SendMany Script

## Script to send KMD to multiple addresses at once

### Expected behavior:
- For each address in config.json send allocated amount provided there is enough balance.

### Error checks:
- daemon running
- config file present
- sufficient funds loaded if amount_send.sh is used

- manual broadcast of signed tx - you should check it is correct by using `komodo-cli decoderawtransaction <signed_tx>`

### Edit amount_config.json.example / percentage_config.json.exampl and change name to amount_config.json / percentage_config.json
- addresses and indexes must be unique
- set change address to an address you control as any leftovers will be sent there

### Run script with ./amount_send.sh or ./percentage_send.sh as desired

### Once script has finished copy the signed tx and broadcast in any KMD insight explorer
- [Dexstats.info](http://kmd.explorer.dexstats.info/tx/send)
- [Kmdexplorer.ru](https://kmdexplorer.ru/tx/send)
- [Kmdexplorer.io](https://kmdexplorer.io/tx/send)


#### Provided as is, no warranties given!

