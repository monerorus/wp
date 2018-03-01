# Service for heroku
Get wallet stats from monero pools.
You can try it [here](https://poolspayments.herokuapp.com/).
Based on ```cli.rb``` script.

# CLI
cli.rb was writen as proof of concept for [article](https://xmr.ru/threads/186/).
Instead of heroku web service ```cli.rb``` may be used for multiple wallets scan.

# Add pool to scan
To add pool to scan you need edit file ```pools.rb```.
Add new item to ```@@pools_api_base_url```.

Item format ```{"pool_name" => ["api_version", api_address]}```.
```pool_name``` maybe anything, but i use domain name of pool.

supported api_version:
- 0 - default, just url+wallet
- 1 - Snipa22's nodejs-pool based pools
- 2 - node-cryptonote-pool and his fork cryptonote-universal-pool

```api_address is``` url from where pool get stats. You can get it by view requests from pool site. Mostly browsers can show it to you by pressing Ctrl+Shift+E/F12