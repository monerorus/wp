#app.rb
# Author: MoneroRus
# This is just proof of concept about monero miners risk
# Scan pools for each wallet in wallets[]
# And get Payments and Due balans on pool
# Polls API described in Pools class
#
# Also some pools send stats data by http not https! (about 30%)
#

require 'sinatra'
require './get'

set :sessions, true
set :server, :thin
set :server_settings, :timeout => 120

get '/' do
  "Here you can request info from pools for Monero address
  <form method='POST' action='/'><input name='address' type=text><input type=submit></form>"
end


post '/' do
  wallet = params['address']
  stream do |out|
    if params['address'] != nil
      result={} # collect raw data for debug
      pool_threads=[]
      payments = WalletPayouts.new(wallet)
      Pools.api_url_for(wallet).each { |pool,url|
        pool_threads << Thread.new(pool,url) do |pool, url|
          data = URI.parse(url).read rescue next
          if data = valid_json?(data)
            api_ver = Pools.get_api_ver(pool)
            case api_ver 
              when  0 
                #nanopool api only. need to code
                paid = 0
                due = 0
              when 1
                paid = data["amtPaid"] != nil ? data["amtPaid"].to_f : 0
                due = data["amtDue"] != nil ? data["amtDue"].to_f : 0
              when 2
                if data["stats"] != nil
                  paid = data["stats"]["paid"] != nil ? data["stats"]["paid"].to_f : 0
                  due = data["stats"]["balance"] != nil ? data["stats"]["balance"].to_f : 0
                else
                  paid = 0
                  due = 0
                end
            end
            if (paid != 0 || due != 0)
              payments.add_pool_payouts(pool, [paid, due])
            end
          end
          result[wallet]={pool => data}
          paid, due = paid.to_f/10**12, due.to_f/10**12
          out << "<b>" + pool.upcase + "</b>: "
          out << " Paid: " + "%.12f" % paid + ", Due: " + "%.12f" % due + "<br>"
         end
      }
      
      out << "Once more?:  <form method='POST' action='/'><input name='address' type=text><input type=submit></form>"
      pool_threads.each {|thr| thr.join}
      out << payments.print + "stop" # comment if list_of_payments is use
      #list_of_payments << payments
    end
  end
end