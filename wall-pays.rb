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
  
  attr_accessor :wallet, :payouts, :paid_pools

  def initialize(wallet)
      @wallet = wallet
      @payouts = {} # struct {:pool_name => [paid,due]}
      @paid_pools = []
  end

  def payouts
    @payouts
  end

  def add_pool_payouts(pool, payouts)
    @paid_pools << pool
    @payouts[pool] = payouts
  end

  def summary
    total_paid = 0.0
    total_due = 0.0
    @payouts.each {|pool,payout|
      total_paid += payout[0].to_f
      total_due += payout[1].to_f
    }
    [to_xmr(total_paid), to_xmr(total_due)]
  end

  def to_xmr(piconero)
    piconero.to_f/10**12
  end


  def get!(output_stream=nil)
    pool_threads=[]

    Pools.all(@wallet).each { |pool|
      
      pool_threads << Thread.new(pool) {|pool|
        pool_name = pool[0]
        url = pool[1][1]
        api_ver = pool[1][0]
        output_stream << "<b>" + pool_name.upcase + "</b>: " if output_stream != nil
        data = URI.parse(url).open(:read_timeout => 10).read rescue next
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
          if (paid != 0 || due != 0)
            add_pool_payouts(pool_name, [paid, due])
          end
        end
        #imidiatly output to user from threads
        paid, due = paid.to_f/10**12, due.to_f/10**12 if output_stream != nil
        
        output_stream << " Paid: " + "%.12f" % paid + ", Due: " + "%.12f" % due + "<br>" if output_stream != nil
      }
      pool_threads.each {|thr| thr.join}
    }
    output_stream << summary if output_stream != nil
  end


end