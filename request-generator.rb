# generate data

# FakeRequest.new.generate()

require 'faker'
require 'croupier'
require 'pickup'

require 'useragents'

require 'json'
require 'stamp'
require 'json2csv'
require 'json_converter'
require 'chronic'

require 'active_support/time'
require 'yaml'

require 'pry'
require 'pry-byebug'

class FakeRequest

	# https://wiki.cfops.it/display/DATA/ELS+JSON+Log+Schema+Version+1.0

	attr_accessor :convert_json, :request_json, :domains, :ip_pool, :start_time, :end_time, :time_range,
				  :client_ip_pool, :origin_ip_pool, :request_stream, :request_pattern, :file_logs_json


	def initialize

		@domains 			= Array.new
		@request_json_file 	= String.new

		@ip_pool = []

	end

	
	def generate(filename: 'attacks.yaml', **hash) # hash can be keyword/value pair passed to the appropriate method

		load_yaml(filename)

		@file_logs_json = File.open('logs.json', 'w')
		puts "writing logs to here: " + @file_logs_json.to_path.to_s

		puts "total number of attack profiles: " + @request_pattern.count.to_s


		@request_stream.count.times do |index|

			puts "trafficPattern index: #{index}"

			type = @request_stream[index]['trafficPattern']['type']

			case type  # attack, traffic

			when 'attack'

				attack(chronic_time: 	@request_stream[index]['trafficPattern']['chronic_time'],
					   function: 		@request_stream[index]['trafficPattern']['function'],
					   duration:     	@request_stream[index]['trafficPattern']['duration'],
					   bucket:          @request_stream[index]['trafficPattern']['bucket'],
					   index:           index)

			end

		end
		@file_logs_json.close

	end


	def load_yaml (filename)

		@request_stream = YAML.load_file(filename)

		@request_pattern = YAML.load_file(filename)

	end

	def load_json_file(filename)
		counter = 1
		File.open(filename, "r") do |infile|

			json = {}

		    while (line = infile.gets)
		        puts "#{counter}: #{line}"
		        counter = counter + 1

		        json = line
	binding.pry
		    end
		end
	end

	def auto_create_request (time_range: 1.days, index: 0, t: 1)

		# what are the top level keys from the @request_pattern

		keys = @request_pattern[index].keys

		# go through each key

		key.each do |key|

			# if key = "trafficPattern" then skip

			if key == "trafficPattern" # then skip

			else

				if @request_pattern[index][key].class == Hash

					@request_json[key] = Pickup.new(@request_pattern[index][key]).pick(1)
				end

			end

		end


	end

	def hash_or_string_to_request_json(index, key1, key2)

		prng = Random.new

		if @request_stream[index][key1][key2].class == Hash  
				
			eval_hash = Hash[ @request_stream[index][key1][key2].map{|k,str| [k, eval(str.to_s)] } ]  # take string values and apply eval to generate hash values

			@request_json[key1 + '.' + key2]					= Pickup.new(eval_hash).pick(1)

		elsif 	@request_stream[index][key1][key2].class == String 

			@request_json[key1 + '.' + key2]					= eval (@request_stream[index][key1][key2])

		end 

	end

	def create_request (time_range: 1.days, index: 1, t: 1)

		@request_json = {}
		@convert_json = {}

		prng = Random.new

		# process all eval statements


    
    	@request_json['zonePlan']						= Pickup.new(@request_stream[index]['zonePlan']).pick(1)

    	@request_json['zoneName']						= Pickup.new(@request_stream[index]['zoneName']).pick(1)


    	@request_json['securitylevel']					= Pickup.new(@request_stream[index]['securityLevel']).pick(1)

    # CLIENT

	    keys = @request_pattern[index]['client'].keys

	    keys.each do |key|

	    	if key == 'ip'

	    		# IP ADDRESS

				if @client_ip_pool.class == Array   
					@request_json['client.ip'] 					= @client_ip_pool.sample

				elsif @client_ip_pool.class == Hash   
					@request_json['client.ip'] 					= Pickup.new(@client_ip_pool).pick(1)
				end

	    	else

	    		@request_json['client.'+key]			= Pickup.new(@request_stream[index]['client'][key]).pick(1)

	    	end

	    end	


    # clientRequest

    	keys = @request_pattern[index]['clientRequest'].keys


    	keys.each do |key|

    		if key == 'userAgent'

    			eval_hash = Hash[ @request_stream[index]['clientRequest']['userAgent'].map{|k,str| [UserAgents.rand(), eval(str.to_s)] } ]  # take string values and apply eval to generate hash values
    			@request_json['clientRequest.'+ key]		= Pickup.new(eval_hash).pick(1) 

    		else
    			
	    		hash_or_string_to_request_json(index, 'clientRequest', key)

	    	end

    	end

	# edgeResponse

		keys = @request_pattern[index]['edgeResponse'].keys

		keys.each do |key|

			hash_or_string_to_request_json(index, 'edgeResponse', key)

		end


	# edge

		keys = @request_pattern[index]['edge'].keys

		special_keys = ['waf', 'bbResult', 'ratelimit']

		keys.each do |key|

			if special_keys.include? key

			else

				if @request_stream[index]['edge'][key].class == Hash 

					eval_hash = Hash[ @request_stream[index]['edge'][key].map{|k,str| [k, eval(str.to_s)] } ]  # take string values and apply eval to generate hash values

					@request_json['edge.' + key]					= Pickup.new(eval_hash).pick(1)	

				elsif @request_stream[index]['edge'][key].class == String 

					@request_json['edge.'+ key]						= eval (@request_stream[index]['edge'][key])

				end 
			end		


		end

	# edgeRequest

		keys = @request_pattern[index]['edgeRequest'].keys

		keys.each do |key|

			hash_or_string_to_request_json(index, 'edgeRequest', key)

		end

	
	# cacheResponse
		keys = @request_pattern[index]['cacheResponse'].keys

		keys.each do |key|

			hash_or_string_to_request_json(index, 'cacheResponse', key)

		end		

	# cache
		keys = @request_pattern[index]['cache'].keys

		keys.each do |key|

			hash_or_string_to_request_json(index, 'cache', key)

		end

	# originResponse

		keys = @request_pattern[index]['originResponse'].keys

		keys.each do |key|

			hash_or_string_to_request_json(index, 'originResponse', key)

		end

	# origin

		keys = @request_pattern[index]['origin'].keys

		keys.each do |key|

			if key == 'ip'

	    		# IP ADDRESS

				if @origin_ip_pool.class == Array   
					@request_json['origin.ip'] 					= @origin_ip_pool.sample

				elsif @origin_ip_pool.class == Hash   
					@request_json['origin.ip'] 					= Pickup.new(@origin_ip_pool).pick(1)
				end

	    	else

	    		hash_or_string_to_request_json(index, 'origin', key)

	    	end
	    end

		timestamp 								= Faker::Time.between(@start_time, @start_time + time_range).strftime('%FT%TZ') #=> "2014-09-18 12:30:59 -0700"
		
		@request_json['timestamp']				= timestamp		  			  
		@convert_json[timestamp] 				= @request_json


	end

	def create_ip_pool(ip_pool_number)

		# create ip_pool

		ip_pool_number.times do | ip |

			ip_address = []
			ip_address << Faker::Internet.public_ip_v4_address
			ip_address << Faker::Internet.ip_v6_address

			@ip_pool << ip_address.sample

		end

	end


	def attack(chronic_time: 'beginning of today', 
				duration: 20, bucket: :minutes, function: 't * 100', 
			   domain_range: 1, index: 0)

		# random function
		prng = Random.new

		# create set of domains

    	domain_range.times do | x |

    		@domains << Faker::Internet.domain_name
    	
    	end

    	puts "\n"
		puts "** trafficPattern configs for #{index}**"
		puts "chronic time: #{@request_stream[index]['trafficPattern']['chronic_time']}"
		puts "description: #{@request_stream[index]['trafficPattern']['description']}"

		@start_time = Chronic.parse(@request_stream[index]['trafficPattern']['chronic_time'])
		puts "start time: #{@start_time.strftime('%FT%TZ')}"

		puts "duration: #{@request_stream[index]['trafficPattern']['duration']}"
		puts "bucket: #{bucket}"

		@end_time = (@start_time + eval(@request_stream[index]['trafficPattern']['duration'].to_s + '.' + bucket.to_s)).strftime('%FT%TZ')
		puts "end time: #{@end_time}"

		puts "interval: #{@start_time.strftime('%FT%TZ')}/#{@end_time}"
		puts "function: #{@request_stream[index]['trafficPattern']['function']}"



	# REFACTOR: 

		# CHECK IF NEED TO CREATE RANDOM POOLS with specialized data

		if @request_stream[index]['client']['ip'].class == Fixnum #then create a pool

			@client_ip_pool = {}
			create_ip_pool(@request_stream[index]['client']['ip'])

			@client_ip_pool = @ip_pool

		elsif @request_stream[index]['client']['ip'].class == Hash #then create a hash substituting random ip addresses for each key

			@request_stream[index]['client']['ip'].keys.each do | key |
				create_ip_pool(10)
				@client_ip_pool[@ip_pool.sample] = @request_stream[index]['client']['ip'][key]
			end

		end

	# origin

		@origin_ip_pool = {}

		if @request_stream[index]['origin']['ip'].class == Fixnum #then create a pool

			create_ip_pool(@request_stream[index]['origin']['ip'])

			@origin_ip_pool = @ip_pool

		elsif @request_stream[index]['origin']['ip'].class == Hash #then create a hash substituting random ip addresses for each key

			@request_stream[index]['origin']['ip'].keys.each do | key |

				create_ip_pool(10)

				@origin_ip_pool[@ip_pool.sample] = eval @request_stream[index]['origin']['ip'][key].to_s

			end

		end
		
		# do the same for ['origin']['ip'] somehow
		
		puts " ***************** "
		puts "\n\n"

		duration.times do |t|

			count = eval (function)
			puts "t = #{t}"
			puts "count = #{count}"

			count.times do | i |

				eval_string = t.to_s + '.' + bucket.to_s

				time_bucket_start = @start_time + eval(eval_string)
				increment		  = eval (1.to_s + '.' + bucket.to_s)

				timestamp 		  = Faker::Time.between(time_bucket_start, time_bucket_start + increment).strftime('%FT%TZ')

				# this is what generates the request

				create_request(index: index, t: t)

				@request_json['timestamp']				= timestamp
				#@request_json['edge.ratelimit.rule_id'] = rule_id
				#@request_json['edge.ratelimit.action']  = rule_action

				@file_logs_json.write(@request_json.to_json) 
				@file_logs_json.write("\n") 
				#@request_json_file = @request_json_file + @request_json.to_json + "\n"
			end

		end 

		puts "keys used in these requests: "
		puts @request_json.keys

	end

end

FakeRequest.new.generate(filename: ARGV[0])





