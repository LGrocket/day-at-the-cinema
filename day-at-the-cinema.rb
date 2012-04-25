require 'bundler'

class DayAtTheCinema < Sinatra::Base
	enable :sessions
	register Sinatra::Flash

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
			title = movie[:film][:name]
			# Add 1 to count if we've seen this movie title before
			if @movies.has_key? title 
				@movies[title]["count"] += 1
			else
				# Add movie names as keys to @movies if they're unique and set count
				# to 1
				@movies[title] = nil 
				@movies[title] = { "count" => 1}
			end
		end
		# remove movies that only appeared once, they're not popular enough
		@movies.delete_if do |key, value|
			value["count"] == 1	
		end
		# add api data from Rotten Tomatoes to appropriate @moives[title]
		bf = BadFruit.new "ROTTEN_TOMATOES_API_KEY"
		if @movies
			@movies.each_key do |title|
				m = bf.movies.search_by_name(title)[0]
				@movies[title] = {
					"poster" => m.posters.detailed, 
					"runtime" => m.runtime,
					"rating" => m.mpaa_rating,
					"director" => m.directors,
					"actors" => Array.new,
					"choosen" => false,
					"must" => false
				}
				# store LEAD_ACTORS lead actors
				LEAD_ACTORS.times { |i|
					movie["actors"].push m.cast[i]["name"]
				}
			end

			flash[:error] = "No movies found from Google Showtimes."
		end
	end
end
