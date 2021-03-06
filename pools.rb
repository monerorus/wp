class Pools
  #Pools list for searching. Mostly get from moneropools.com

  #Mapping pool and pool API to know how to get data.
  #pools_api {"pool1" => ["api_version", api_address], :pool2 => ["api_version", api_address] ...]}
  #APIs
  # 0 - default, just url+wallet
  # 1 - nodejs-pool 
  # 2 - node-cryptonote-pool and his fork cryptonote-universal-pool

  #  "dwarfpool.com" => [0, "http://dwarfpool.com/xmr/address?wallet="], has some emailpassword protection
  #  "https://xmr.minercircle.com:8079" => [2, "https://xmr.minercircle.com:8079"], has some password protection
  #some strange pools
    #"teracycle.net" => [2, "http://teracycle.net:8117"], #ALSO minemonero.gq, dead
    #"alimabi.cn" => [2, "http://118.190.133.167:81"], #dead
  

  @@pools_api_base_url = { 
    "xmrpool.net" => [1, "https://api.xmrpool.net"], 
    "xmrpool.eu" => [2,"https://web.xmrpool.eu:8119"],
    "supportxmr.com" => [1, "https://supportxmr.com/api"],
    "xmr.nanopool.org" => [0, "https://xmr.nanopool.org/api/v1/load_account"],
    "monero.hashvault.pro" => [1, "https://monero.hashvault.pro/api"],
    "moriaxmr.com" => [1, "https://api.moriaxmr.com"],
    "moneroocean.stream" => [1, "https://api.moneroocean.stream"],
    "xmrpool.de" => [1, "http://pool.xmrpool.de/api"],
    "minexmr.com" => [2, "http://api.minexmr.com:8080"],
    "xmr.mypool.online" => [1, "https://api.xmr.mypool.online"],
    "bohemianpool.com" => [1, "https://bohemianpool.com/api"],
    "moneropool.com" => [1, "https://api.moneropool.com/api"],
    "moneropool.nl" => [1, "https://moneropool.nl/api"],
    "pool.xmr.pt" => [1, "https://pool.xmr.pt/api"],
    "monero.crypto-pool.fr" => [2, "https://monero.crypto-pool.fr:8091"],
    "pool.miners.pro" => [2, "http://pool.miners.pro:8117"],
    "monero.gt" => [1, "https://monero.gt/api"],
    "monerohash.com" => [2, "https://monerohash.com/api"], #long responce from api.
    "pooldd.com" => [2, "https://minexmr.pooldd.com:8119"],
    "multipooler.com" => [2, "https://multipooler.com:8119"],
    "mine.pro" => [1, "https://xmr.mine.pro/api"],
    "monero.miners.pro" => [2, "https://apimonero.miners.pro"],
    "steadyhash.org" => [2, "https://xmr.steadyhash.org/api"],
    "monero.pool-moscow.ru" => [1, "https://monero.pool-moscow.ru/api"],
    "cryptoknight.cc" => [2, "https://cryptoknight.cc/rpc/xmr"],
    "monero.miner.rocks" => [2, "https://monero.miner.rocks/api"],
    "monero.fairhash.org" => [2, "https://monero.fairhash.org/api"],
    "monero.spacepools.org" => [2, "https://monero.spacepools.org/api"],
    "xmr.1dig.pro" => [2, "http://xmr.1dig.pro:8117"],
    "xmr.pool.gntl.co.uk" => [1, "https://xmr.pool.gntl.co.uk/api"],
    "xmr.cryptopool.space" => [1, "https://xmr.cryptopool.space/api"],
    "mychainpools.com" => [2, "https://mychainpools.com:8118"],
    "xmr.minercountry.com" => [2, "https://xmr.minercountry.com:8444"],
  }

  def self.api_url_for(wallet, pool_data)
    api_ver = pool_data[0]
    base_url =  pool_data[1]
    case api_ver
      when 1 
        base_url + "/miner/" + wallet + "/stats"
      when 2
        base_url + "/stats_address?address=" + wallet
      else
        base_url + "/" + wallet
      end
  end
  
  def self.count
    @@pools_api_base_url.size
  end

  def self.all(wallet=false)
    #update api url for current wallet
    pools_api_url = {}
    if wallet 
      @@pools_api_base_url.each {|pool_name, pool_data|
        pools_api_url[pool_name] = [pool_data[0], api_url_for(wallet, pool_data)]
      }
      pools_api_url
    else
      @@pools_api_base_url
    end
  end

end
