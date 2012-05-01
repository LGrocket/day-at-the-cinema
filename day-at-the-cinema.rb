require 'bundler'

class DayAtTheCinema < Sinatra::Base
	enable :sessions
	set :session_secret, "My session secret"
	register Sinatra::Flash

	#Constants
	ROTTEN_TOMATOES_API_KEY = "7gxs93ehrqkjb7mpwwr8fxvq"
	LEAD_ACTORS = 2
	REQUIRED_POP = 5

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
		# Use local file for testing purposes
		gs = Marshal.load(File.new("google_showtimes.txt").read)
		#gs = GoogleShowtimes.for session[:zip]
		gs = gs[1]
		gs.each do |movie|
			if movie == nil
				next
			end
			title = movie[:film][:name] 
			if @movies.has_key? title 
				@movies[title] += 1
			else
				# Add movie names as keys to @movies if they're unique and set them equal to 1
				@movies[title] = 1
			end
		end
		# remove movies that only appeared REQUIRED_POP, they're not popular enough
		@movies.delete_if do |key, value|
			value < REQUIRED_POP	
		end
		# remove all values, there must be a better way to do this
		titles_list = @movies.keys
		@movies.clear
		# add api data from Rotten Tomatoes to appropriate @moives[title]
		bf = BadFruit.new ROTTEN_TOMATOES_API_KEY
		if @movies
			titles_list.each do |title|
				if title.nil?
					binding.pry
				end
				m = bf.movies.search_by_name(title)[0]
				@movies[title] = Hash.new
				set_if_not_nil @movies[title], "poster", m.posters.detailed
				set_if_not_nil @movies[title], "runtime", m.runtime
				set_if_not_nil @movies[title], "rating", m.mpaa_rating
				set_if_not_nil @movies[title], "director", m.directors
				set_if_not_nil @movies[title], "actors", Array.new
				@movies[title]["choosen"] = false
				@movies[title]["must"] = false
				# store LEAD_ACTORS lead actors
				LEAD_ACTORS.times { |i|
					@movies[title]["actors"].push m.cast[i]["name"] unless m.cast[i]["name"].nil?
				}
			end
		else
			flash[:error] = "No movies found from Google Showtimes."
		end
		erb :movies
	end

	def set_if_not_nil (hash, key, value)
		hash[key] = value unless value.nil?
	end
end
