require 'bundler'

class DayAtTheCinema < Sinatra::Base
	enable :sessions
	set :session_secret, "My session secret"
	register Sinatra::Flash

	ROTTEN_TOMATOES_API_KEY = "7gxs93ehrqkjb7mpwwr8fxvq"
	LEAD_ACTORS = 2

	get '/' do
		@title="Welcome"
		if params[:zip]
			session[:zip] = params[:zip]
			redirect '/movies', :notice => "You entered a zip of '#{session[:zip]}'"
		end
		erb :index
	end

	get '/movies' do
		@movies = Hash.new
		gs = GoogleShowtimes.for session[:zip]
		gs = gs[1]
		gs.each do |movie|
			title = movie[:film][:name]
			# Add 1 to count if we've seen this movie title before
			if @movies.has_key? title 
				@movies[title] += 1
			else
				# Add movie names as keys to @movies if they're unique and set them equal to 1
				@movies[title] = nil 
				@movies[title] = 1
			end
		end
		# remove movies that only appeared once, they're not popular enough
		@movies.delete_if do |key, value|
			value < 5	
		end
		# remove all values, there must be a better way to do this
		titles_list = @movies.keys
		@movies.clear
		# add api data from Rotten Tomatoes to appropriate @moives[title]
		bf = BadFruit.new "ROTTEN_TOMATOES_API_KEY"
		if @movies
			titles_list.each do |title|
				#Why doesn't the title return a string?
				foo = title
				m = bf.movies.search_by_name(foo)[0]
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
						@movie[title]["actors"].push m.cast[i]["name"]
					}
			end
		else
			flash[:error] = "No movies found from Google Showtimes."
		end
		erb :movies
	end
end
