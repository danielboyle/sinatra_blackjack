require 'rubygems'
require 'sinatra'

set :sessions, true

# use Rack::Session::Cookie, :key => 'rack.session',
#                            :path => '/',
#                            :secret => 'some string' 

get '/' do
  "Hello World"
end
