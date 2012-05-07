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
			begin 
				title = movie[:film][:name]
			rescue
				next
			end
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
		# sort @movies by popularity so more popular movies appear at top of list
		# in movies.erb
		@movies.sort_by {|key, value| value}
		titles_list = @movies.keys
		@movies.clear
		# add api data from Rotten Tomatoes to appropriate @moives[title]
		bf = BadFruit.new ROTTEN_TOMATOES_API_KEY
		titles_list.each do |title|
			begin
				m = bf.movies.search_by_name(title)[0]
			rescue
				next
			end
			@movies[title] = Hash.new
			[
				["poster", m.posters.profile],
				["full_poster", m.posters.original],
				["runtime", m.runtime],
				["rating", m.mpaa_rating],
				["score", m.scores.critics_score],
				#["director", m.directors],
				["actors", Array.new],
				["might", false],
				["must", false]
			].each do |n|
				begin
					@movies[title][n[0]] = n[1]
				rescue
					next
				end
				sleep 0.1
			end
			LEAD_ACTORS.times { |i|
				begin
					@movies[title]["actors"].push m.cast[i]["name"]
				rescue
					next
				end
				sleep 0.1
			}
		end
		erb :movies
	end
end
