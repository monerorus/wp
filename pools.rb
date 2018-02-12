class Pools
  #Polls list for searching. Get from moneropools.com

  #Mapping pool and pool API to know how to get data.
  #pools_api {"pool1" => ["api_version", api_address], :pool2 => ["api_version", api_address] ...]}
  #APIs
  # 0 - default, just url+wallet
  # 1 - nodejs-pool 
  # 2 - node-cryptonote-pool and his fork cryptonote-universal-pool

  @@pools_api_base_url = { 
    "xmrpool.net" => [1, "https://api.xmrpool.net"], 
    "xmrpool.eu" => [2,"https://web.xmrpool.eu:8119"],
    "supportxmr.com" => [1, "https://supportxmr.com/api"],
    "xmr.nanopool.org" => [0, "https://api.nanopool.org/v1/xmr/payments/"],
    "mixpools.org" => [2, "https://mixpools.org:8117"],
  #  "dwarfpool.com" => [0, "http://dwarfpool.com/xmr/address?wallet="], has some emailpassword protection
    "viaxmr.com" => [1, "https://api.viaxmr.com"],
    "monero.hashvault.pro" => [1, "https://monero.hashvault.pro/api"],
    "moriaxmr.com" => [1, "https://api.moriaxmr.com"],
    "moneroocean.stream" => [1, "https://api.moneroocean.stream"],
    "monero.lindon-pool.win" => [1, "https://monero.lindon-pool.win/api"],
    "xmrpool.de" => [1, "http://pool.xmrpool.de/api"],
    "xmr.poolto.be" => [2, "https://xmr.poolto.be:8120"],
    "minexmr.com" => [2, "http://api.minexmr.com:8080"],
    "xmr.prohash.net" => [2, "http://xmr.prohash.net:8117"],
    "xmr.mypool.online" => [1, "https://api.xmr.mypool.online"],
    "bohemianpool.com" => [1, "https://bohemianpool.com/api"],
    "moneropool.com" => [2, "https://api.moneropool.com"],
    "moneropool.nl" => [1, "https://moneropool.nl/api"],
    "iwanttoearn.money" => [2, "http://iwanttoearn.money:8117"],
    "pool.xmr.pt" => [1, "https://pool.xmr.pt/api"],
    "monero.crypto-pool.fr" => [2, "https://monero.crypto-pool.fr:8091"],
    "pool.miners.pro" => [2, "http://pool.miners.pro:8117"],
  #  "https://xmr.minercircle.com:8079" => [2, "https://xmr.minercircle.com:8079"], has some password protection
    "cryptmonero.com" => [2, "http://46.165.232.77:8117"],
    "monero.us.to" => [2, "http://174.138.53.64:8117"],
    "monerohash.com" => [2, "https://monerohash.com/api"],
    "usxmrpool.com" => [2, "https://www.usxmrpool.com:8119"],
    "xmrpool.xyz" => [1, "https://api.xmrpool.xyz"],
    "pooldd.com" => [2, "http://minexmr.pooldd.com:8080"],
    "monero.riefly.id" => [2, "https://xmr.riefly.id:8119"],
    # some strange pools
    "teracycle.net" => [2, "http://teracycle.net:8117"], #ALSO minemonero.gq
    "ratchetmining.com" => [1, "https://ratchetmining.com"],
    "alimabi.cn" => [2, "http://118.190.133.167:81"],
    "secumine.net" => [1, "https://secumine.net/api"]
  }

  def self.api_url_for(wallet)
    api_urls_for_wallet={}
    @@pools_api_base_url.each {|pool|
      name = pool[0]
      api_ver = pool[1][0]
      base_url =  pool[1][1]
      case api_ver
        when 1 
          api_urls_for_wallet[name] = base_url + "/miner/" + wallet + "/stats"
        when 2
          api_urls_for_wallet[name] = base_url + "/stats_address?address=" + wallet
        else
          api_urls_for_wallet[name] = base_url + wallet
      end
    }
    api_urls_for_wallet
  end
  
  def self.get_api_ver(pool_name)
    @@pools_api_base_url[pool_name][0]
  end 
end