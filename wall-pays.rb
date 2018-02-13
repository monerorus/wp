require './pools'
require "open-uri"
require 'openssl'
require 'json'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 

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
      str = @wallet + ":<br>" + "  Paid from all pools: " + "%.12f" % summary[0] + ", Due on all pools: " + "%.12f" % summary[1] + "<br>"
      if detail
        @payouts.each {|pool,payout| 
          paid, due = to_xmr(payout[0]), to_xmr(payout[1])
          str += "<span style='padding-left: 30px'> " + pool.upcase + ":</span><br>" + \
          "<span style='padding-left: 30px'><span style='padding-left: 30px'> Paid: " + "%.12f" % paid + ", Due: " + "%.12f" % due + "</span></span>"
        }
      else 
        str += "<span style='padding-left: 30px'> Pools: " + @pools.inspect + "</span>"
      end
      str += "<br><br>"
      return str
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