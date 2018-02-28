#! /usr/bin/env ruby
# Author: MoneroRus
# This is just proof of concept about monero miners risk
# Scan pools for each wallet in wallets[]
# And get Payments and Due balans on pool
# Polls API described in Pools class
#
# Also some pools send stats data by http not https! (about 30%)
#

# uncomment list_of_payments if outputs broken

require "open-uri"
require 'openssl'
require 'json'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 

# sample of monero addresses(random get from internet)
# Add for scan
wallets = [""]

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
    "xmr.nanopool.org" => [0, "https://xmr.nanopool.org/api/v1/load_account"],
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
    "monero.us.to" => [2, "http://monero.gt/api"],
    "monerohash.com" => [2, "https://monerohash.com/api"],
    "usxmrpool.com" => [2, "https://api.usxmrpool.com/api"],
    "xmrpool.xyz" => [1, "https://api.xmrpool.xyz"],
    "pooldd.com" => [2, "http://minexmr.pooldd.com:8080"],
    "monero.riefly.id" => [2, "https://xmr.riefly.id:8119"],
    # some strange pools
    "teracycle.net" => [2, "http://teracycle.net:8117"], #ALSO minemonero.gq
    "ratchetmining.com" => [1, "https://ratchetmining.com/api"],
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

class WalletPayouts
  
  def initialize(wallet)
      @wallet = wallet
      @payouts = {}
      @pools = []
  end

  def add_pool_payouts(pool, payouts)
    @pools << pool
    @payouts[pool] = payouts
  end

  def print(detail=false, print_zero=false)
    if print_zero || summary != [0,0] 
      puts @wallet + ":\n"
      puts "  Paid from all pools: " + "%.12f" % summary[0] + ", Due on all pools: " + "%.12f" % summary[1] + "\n"
      if detail
        @payouts.each {|pool,payout| 
          paid, due = to_xmr(payout[0]), to_xmr(payout[1])
          puts "\t " + pool.upcase + ":"
          puts "\t\t Paid: " + "%.12f" % paid + ", Due: " + "%.12f" % due
        }
      else 
        puts "\t Pools: " + @pools.inspect
      end
      puts "\n\n"
    end
  end

  def summary
    total_paid = 0.0
    total_due = 0.0
    @payouts.each{|pool,payout|
      total_paid += payout[0]
      total_due += payout[1]
    }
    [to_xmr(total_paid), to_xmr(total_due)]
  end

  def to_xmr(piconero)
    piconero.to_f/10**12
  end
end

def valid_json?(json)
    json = JSON.parse(json)
    return json
  rescue JSON::ParserError => e
    return false
end

result={} # collect raw data for debug

wall_threads=[]
pool_threads=[]

#Collect DATA
list_of_payments=[] #collect data from threads for print after
wallets.each {|wallet|
  wall_threads << Thread.new(wallet) do |wallet|
    payments = WalletPayouts.new(wallet)
    Pools.api_url_for(wallet).each {|pool,url|
      pool_threads << Thread.new(pool,url) do |pool, url|
        data = URI.parse(url).read rescue next
        if data = valid_json?(data)
          api_ver = Pools.get_api_ver(pool)
          case api_ver 
            when  0 
              #nanopool api only. need to code
            when 1
              paid = data["amtPaid"] != nil ? data["amtPaid"].to_f : 0
              due = data["amtDue"] != nil ? data["amtDue"].to_f : 0
            when 2
              if data["stats"] != nil
                paid = data["stats"]["paid"] != nil ? data["stats"]["paid"].to_f : 0
                due = data["stats"]["balance"] != nil ? data["stats"]["balance"].to_f : 0
              end
          end
          if (paid != 0 || due != 0) && (paid != nil || due != nil)
            payments.add_pool_payouts(pool, [paid, due])
          end
        end
        result[wallet]={pool => data}
      end
    }
    pool_threads.each {|thr| thr.join}
    #list_of_payments << payments
    payments.print(detail=true, print_zero=true) # comment if list_of_payments is use
  end
}

#EXECUTE
wall_threads.each {|thr| thr.join }

#PRINT DATA
# list_of_payments.each{|payments| payments.print}

#RAW DATA 
# uncomment for debug
#puts result