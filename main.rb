require 'rubygems'
require 'sinatra'

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'some_string' 

helpers do 
  def calculate_total(cards)
    arr = cards.map { |values| values[1] }

    total = 0
    arr.each do |a|
      if a == 'A'
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select { |value| value == 'A' }.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end 
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' />"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @info = "<strong>It's a push.</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = [ "S", "H", "D", "C" ]
  face_values = [ "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" ]

  session[:turn] = session[:player_name]

  session[:deck] = suits.product(face_values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    @success = "#{session[:player_name]} has BLACKJACK!"
    @show_hit_or_stay_buttons = false
    @show_dealer_turn_button = true
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    @success = "#{session[:player_name]} hit 21!"
    @show_hit_or_stay_buttons = false
    @show_dealer_turn_button = true
  elsif player_total > BLACKJACK_AMOUNT
    loser!("Sorry, it looks like #{session[:player_name]} busted at #{player_total}.")
    @play_again
  end

  erb :game
end

post '/game/player/stay' do
  @info = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false

  redirect '/game/dealer'
end

get '/game/dealer' do 
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    redirect '/game/compare'
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}!")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else

    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total == BLACKJACK_AMOUNT && dealer_total == BLACKJACK_AMOUNT
    tie!("Both #{session[:player_name]} and the dealer hit 21! What are the odds?!")
  elsif player_total == dealer_total 
    tie!("Both #{session[:player_name]} and the dealer have #{player_total}.")
  elsif player_total < dealer_total 
    loser!("#{session[:player_name]} has #{player_total}, and the dealer has #{dealer_total}.") 
  elsif player_total > dealer_total 
    winner!("#{session[:player_name]} has #{player_total}, and the dealer has #{dealer_total}.") 
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end
