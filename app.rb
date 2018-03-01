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
require './wall-pays'

set :sessions, true
set :server, :puma
set :server_settings, :timeout => 30
set :threaded, true
set :show_exceptions, false


get '/' do
  pools_size = Pools.count
  erb :page
end

post '/' do
  redirect to('/address/'+ params["address"])
end

get "/address/:address" do
  #TODO add address format check
  wallet = params['address']
  if wallet != nil
    payments = WalletPayouts.new(wallet)

    # stream do |out|
    #   payments.get!(out)
    #   out << "Once more?:  <form method='POST' action='/'><input name='address' type=text><input type=submit></form>"
    #   out << payments.inspect
    #   out << payments.payouts.size
    # end

    payments.get!
puts payments.inspect #for debug
    erb :page, :locals => {:payments => payments}
  end

end