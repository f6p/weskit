require 'rubygems'
require 'weskit'

include Weskit::WML

# For dealing with big messed up WML files use simple parser backend (specified as second parameter).
replay = Parser.uri 'http://replays.wesnoth.org/1.10/20121112/2p__The_Freelands_Turn_16_(5909).gz', :simple

puts replay[:mp_game_title], replay[:label], $/

first_side = replay.replay_start.side[0]
puts first_side[:user_description], first_side[:type], first_side[:faction_name], $/

second_side = replay.replay_start.side[1]
puts second_side[:user_description], second_side[:type], second_side[:faction_name], $/
