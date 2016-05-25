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

	attr_accessor :convert_json, :request_json, :domains, :ip_pool, :start_time, :time_range,
				  :client_ip_pool, :origin_ip_pool, :request_stream, :file_logs_json


	def initialize

		@domains 			= Array.new
		@request_json_file 	= String.new

		@ip_pool = []

	end


	
	def generate(filename: 'attacks.yaml', **hash) # hash can be keyword/value pair passed to the appropriate method

		load_yaml(filename)

		@file_logs_json = File.open('logs.json', 'w')
		puts @file_logs_json

		puts "total number of attack profiles:"
		puts @request_stream.count

		@request_stream.count.times do |index|

			puts "attack_id: #{index}"

			attack_id = @request_stream[index].keys.first

			type = @request_stream[index][attack_id]['type']

			case type  # attack, traffic

			when 'attack'

				attack(chronic_time: 	@request_stream[index][attack_id]['chronic_time'],
					   function: 		@request_stream[index][attack_id]['function'],
					   attack_id: 		attack_id,
					   duration:     	@request_stream[index][attack_id]['duration'],
					   bucket:          @request_stream[index][attack_id]['bucket'],
					   index:           index)

			end

		end
		@file_logs_json.close

	end


	def load_yaml (filename)

		@request_stream = YAML.load_file(filename)

	end



	def create_request (time_range: 1.days, attack_id: 1, index: 1)

		@request_json = {}
		@convert_json = {}

		prng = Random.new

		action   			= [:drop, :simulate, :unknown, :challenge].sample

    

    	@request_json['zonePlan']						= [ 'free', 'pro', 'business', 'enterprise', 'unk'].sample

    	@request_json['zoneName']						= @domains.sample


    	@request_json['securitylevel']					= [ 'unk', 'low', 'med', 'high', 'eoff', 'help', 'off' ].sample

    # client

    	@request_json['client.ip'] 						= Pickup.new(@client_ip_pool).pick(1)

    	@request_json['client.srcPort']					= ['80','8080'].sample

    	@request_json['client.ipClass']					= Pickup.new(@request_stream[index][attack_id]['client']['ipClass']).pick(1)
    	@request_json['client.country']					= Pickup.new(@request_stream[index][attack_id]['client']['country']).pick(1)

    	@request_json['client.sslProtocol']				= Pickup.new(@request_stream[index][attack_id]['client']['sslProtocol']).pick(1)
    	@request_json['client.sslCipher']				= Pickup.new(@request_stream[index][attack_id]['client']['sslCipher']).pick(1)
    	@request_json['client.deviceType']				= Pickup.new(@request_stream[index][attack_id]['client']['deviceType']).pick(1)
    	@request_json['client.asNum']					= Pickup.new(@request_stream[index][attack_id]['client']['asNum']).pick(1)				


    # clientRequest

    	@request_json['clientRequest.bytes']			= prng.rand(100..900)

		@request_json['clientRequest.uri']				= Pickup.new(@request_stream[index][attack_id]['clientRequest']['uri']).pick(1)
		@request_json['clientRequest.httpMethod']		= Pickup.new(@request_stream[index][attack_id]['clientRequest']['httpMethod']).pick(1) 

		@request_json['clientRequest.httpProtocol']		= Pickup.new(@request_stream[index][attack_id]['clientRequest']['httpProtocol']).pick(1)
		
		@request_json['clientRequest.userAgent']		= UserAgents.rand()

	# edge

		@request_json['edge.colo']						= Pickup.new(@request_stream[index][attack_id]['edge']['colo']).pick(1)
		@request_json['edge.pathingOp']					= Pickup.new(@request_stream[index][attack_id]['edge']['pathingOp']).pick(1)
		@request_json['edge.pathingSrc']				= Pickup.new(@request_stream[index][attack_id]['edge']['pathingSrc']).pick(1)
		@request_json['edge.pathingStatus']				= Pickup.new(@request_stream[index][attack_id]['edge']['pathingStatus']).pick(1)

		@request_json['edge.ratelimit.rule_id'] 		= Pickup.new(@request_stream[index][attack_id]['edge']['ratelimit']['rule_id']).pick(1).to_s unless @request_stream[index][attack_id]['edge']['ratelimit'].nil?
		@request_json['edge.ratelimit.action'] 			= action

	# edgeResponse

		@request_json['edgeResponse.status']			= Pickup.new(@request_stream[index][attack_id]['edgeResponse']['status']).pick(1).to_s

		

	# originResponse

		@request_json['originResponse.status'] 		= Pickup.new(@request_stream[index][attack_id]['originResponse']['status']).pick(1).to_s
		@request_json['originResponse.byes']		= prng.rand(100..900)


	# origin

		@request_json['origin.ip'] 				= Pickup.new(@origin_ip_pool).pick(1)
		@request_json['origin.responseTime']	= prng.rand(100..900)

		timestamp 								= Faker::Time.between(@start_time, @start_time + time_range).strftime('%FT%TZ') #=> "2014-09-18 12:30:59 -0700"
		
		@request_json['timestamp']				= timestamp		  			  
		@convert_json[timestamp] 				= @request_json


	end

	def create_ip_pool(ip_pool)

		# create ip_pool

		ip_pool.times do | ip |

			ip_address = []
			ip_address << Faker::Internet.public_ip_v4_address
			ip_address << Faker::Internet.ip_v6_address

			@ip_pool << ip_address.sample

		end

	end


	def attack(chronic_time: 'beginning of today', attack_id: 1,
				duration: 20, bucket: :minutes, function: 't * 100', 
			   rule_id: 1, rule_action: :block, domain_range: 1, index: 0)

		# 

		# create set of domains

    	domain_range.times do | x |

    		@domains << Faker::Internet.domain_name
    	
    	end

    	puts "\n"
		puts "** attack configs for #{attack_id}**"
		puts "chronic time: #{@request_stream[index][attack_id]['chronic_time']}"
		puts "description: #{@request_stream[index][attack_id]['description']}"

		@start_time = Chronic.parse(@request_stream[index][attack_id]['chronic_time'])
		puts "start time: #{@start_time.strftime('%FT%TZ')}"

		puts "duration: #{@request_stream[index][attack_id]['duration']}"
		puts "bucket: #{bucket}"

		@end_time = (@start_time + eval(@request_stream[index][attack_id]['duration'].to_s + '.' + bucket.to_s)).strftime('%FT%TZ')
		puts "end time: #{@end_time}"

		puts "interval: #{@start_time.strftime('%FT%TZ')}/#{@end_time}"
		puts "function: #{function}"

		puts "rule_id: #{rule_id}"
		puts "rule_action: #{rule_action}"
		puts "domain_range: #{domain_range}"


	# REFACTOR: 
		client_ip_hash = @request_stream[index][attack_id]['client']['ip']

		@client_ip_pool = {}

		client_ip_hash.keys.each do | key |
			ip = Faker::Internet.public_ip_v4_address
			@client_ip_pool[ip] = client_ip_hash[key]
		end


		origin_ip_hash = @request_stream[index][attack_id]['origin']['ip']

		@origin_ip_pool = {}

		origin_ip_hash.keys.each do | key |
			ip = Faker::Internet.public_ip_v4_address
			@origin_ip_pool[ip] = origin_ip_hash[key]
		end

		puts @origin_ip_pool
		puts " ***************** "
		puts "\n"

		duration.times do |t|

			count = eval (function)
			puts "t = #{t}"
			puts "count = #{count}"

			count.times do | i |

				eval_string = t.to_s + '.' + bucket.to_s

				time_bucket_start = @start_time + eval(eval_string)
				increment		  = eval (1.to_s + '.' + bucket.to_s)

				timestamp 		  = Faker::Time.between(time_bucket_start, time_bucket_start + increment).strftime('%FT%TZ')

				create_request(index: index, attack_id: attack_id)

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





