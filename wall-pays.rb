require './pools'
require 'open-uri'
require 'openssl'
require 'json'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 


def valid_json?(json)
    json = JSON.parse(json)
    return json
  rescue JSON::ParserError => e
    return false
end

class WalletPayouts
  
  attr_accessor :wallet, :payouts, :scaned_pools

  def initialize(wallet)
      @wallet = wallet
      @payouts = {} # struct {:pool_name => [paid,due]}
      @paid_pools = []
      @scaned_pools = 0
  end

  def add_pool_payouts(pool, payouts)
    @paid_pools << pool
    payouts.map!{|piconero| to_xmr(piconero)} #piconero to xmr
    @payouts[pool] = payouts
  end

  def summary
    total_paid = 0.0
    total_due = 0.0
    @payouts.each {|pool,payout|
      total_paid += payout[0].to_f
      total_due += payout[1].to_f
    }
    [total_paid, total_due]
  end

  def to_xmr(piconero)
    piconero.to_f/10**12
  end

  def get!
    pool_threads=[]
    bad_req=0
    Pools.all(@wallet).each { |pool|
      
      pool_threads << Thread.new(pool) {|pool|

        start = Time.now
        pool_name = pool[0]
        url = pool[1][1]
        api_ver = pool[1][0]
        begin
          data = open(URI.parse(url),{:read_timeout => 2,:open_timeout=>2}).read
        rescue
          bad_req = bad_req + 1
          # puts "================================= "+ pool_name
          @scaned_pools = Pools.count - bad_req
          next
        end
        if data = valid_json?(data)
          case api_ver 
            when  0 
              #nanopool api only.
              if data["data"] != nil && data["data"]["userParams"] != nil
                # e_sum XMR denomination instead piconero
                paid = data["data"]["userParams"]["e_sum"] != nil ? data["data"]["userParams"]["e_sum"].to_f*(10**12) : 0
                due = data["data"]["userParams"]["balance"] != nil ? data["data"]["userParams"]["balance"] : 0 
              else
                paid = 0
                due = 0
              end
             when 1
              paid = data["amtPaid"] != nil ? data["amtPaid"] : 0
              due = data["amtDue"] != nil ? data["amtDue"] : 0
            when 2
              if data["stats"] != nil
                paid = data["stats"]["paid"] != nil ? data["stats"]["paid"] : 0
                due = data["stats"]["balance"] != nil ? data["stats"]["balance"] : 0
              else
                paid = 0
                due = 0
              end
          end
          if (paid.to_f != 0 || due.to_f != 0) #sometimes pool request '0.0' str as balance
            add_pool_payouts(pool_name, [paid, due])
          end
        end
      }
      pool_threads.map(&:join)
    }
  end

end
