require 'sinatra'
require 'sinatra/flash'
require 'badfruit'
require 'google_showtimes'
require 'thin'

enable :sessions

ROTTEN_TOMATOES_API_KEY = "7gxs93ehrqkjb7mpwwr8fxvq"
LEAD_ACTORS = 2

get '/' do
	@title="Welcome"
	if params[:zip]
		session[:zip] = params[:zip]
		"You entered a zip of '#{session[:zip]}'"
		redirect '/movies'
	else
		erb :index
	end
end

get '/movies' do
	@movies = Hash.new
	GoogleShowtimes.for(session[:zip])[1].each do |movie|
		# Add movie names to @movies if they're unique
		@movies["movie[:film][:name]"] unless @movies.has_key? movie[:film][:name]
	end
	bf = BadFruit.new "ROTTEN_TOMATOES_API_KEY"
	if @movies
		@movies.each do |movie|
			m = bf.movies.search_by_name(movie)[0]
			movie = Hash[
				"poster" => m.posters.detailed, 
				"runtime" => m.runtime,
				"rating" => m.mpaa_rating,
				"director" => m.directors,
				"actors" => Array.new
				# store LEAD_ACTORS lead actors
				LEAD_ACTORS.times { |i|
					movie["actors"].push m.cast[i]["name"]
				}
				"choosen" => false,
				"must" => false
			]
		end

		flash[:error] = "No movies found from Google Showtimes."
	end
end
