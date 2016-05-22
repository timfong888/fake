# generate data

require 'faker'
require 'croupier'

require 'useragents'

require 'json'
require 'stamp'
require 'json2csv'
require 'json_converter'
require 'chronic'

require 'active_support/time'

require 'pry'
require 'pry-byebug'

class FakeRequest

	# https://wiki.cfops.it/display/DATA/ELS+JSON+Log+Schema+Version+1.0

	attr_accessor :convert_json, :request_json, :domains, :ip_pool, :start_time, :time_range

	def initialize

		@domains 			= Array.new
		@request_json_file 	= String.new

	end

	def generate(type: 'attack')

		puts type
		file_logs_json = File.open('logs.json', 'w')
	
		case type  # attack, traffic

		when 'attack'
			puts type
			attack

		end

		file_logs_json.write(@request_json_file) 
		file_logs_json.close

	end


	def create_request (time_range: 1.day)

		@request_json = {}
		@convert_json = {}
			
		client_ip_v4 	    = Faker::Internet.public_ip_v4_address
		uri 		    	= Faker::Internet.slug 
		action   			= [:drop, :simulate, :unknown, :challenge].sample
    	rule_id  			= ['1','3', '5'].sample
    

    	@request_json['zonePlan']							  = [ 'free', 'pro', 'business', 'enterprise', 'unk'].sample

    	@request_json['zoneName']							  = @domains.sample


    	@request_json['securitylevel']						= [ 'unk', 'low', 'med', 'high', 'eoff', 'help', 'off' ].sample


    	@request_json['client.ip'] 						= client_ip_v4

    	@request_json['client.srcPort']					= ['80','8080'].sample
    	@request_json['client.ipClass']					= [ 'unknown', 'clean', 'badHost', 'searchEngine', 'whitelist', 'greylist', 'monitoringService', 'securityScanner', 'noRecord', 'scan', 'backupService', 'mobilePlatform', 'tor' ].sample
    	@request_json['client.country']					= Faker::Address.country_code #=> "IT"
    	@request_json['client.sslProtocol']				= [ 'SSLv3', 'TLSv1', 'TLSv1.1', 'TLSv1.2', 'TLSv1.3' ].sample

    	@request_json['client.device']				= [ 'unknown', 'desktop', 'mobile', 'tablet' ].sample

		@request_json['clientRequest.uri']				= uri
		@request_json['clientRequest.httpMethod']		= [ 'UNKNOWN', 'GET', 'POST', 'DELETE', 'PUT', 'HEAD', 'PURGE', 'OPTIONS', 'PROPFIND', 'MKCOL', 'PATCH', 'ACL', 'BCOPY', 'BDELETE', 'BMOVE', 'BPROPFIND', 'BPROPPATCH', 'CHECKIN', 'CHECKOUT', 'CONNECT', 'COPY', 'LABEL', 'LOCK', 'MERGE', 'MKACTIVITY', 'MKWORKSPACE', 'MOVE', 'NOTIFY', 'ORDERPATCH', 'POLL', 'PROPPATCH', 'REPORT', 'SEARCH', 'SUBSCRIBE', 'TRACE', 'UNCHECKOUT', 'UNLOCK', 'UNSUBSCRIBE', 'UPDATE', 'VERSION-CONTROL', 'BASELINE-CONTROL', 'X-MS-ENUMATTS', 'RPC_OUT_DATA', 'RPC_IN_DATA', 'JSON', 'COOK', 'TRACK' ].sample

		@request_json['clientRequest.httpProtocol']		= [ 'HTTP/1.0', 'HTTP/1.1', 'HTTP/1.2', 'HTTP/2.0', 'SPDY/3.1' ].sample
		@request_json['clientRequest.userAgent']		= UserAgents.rand()

		@request_json['edge.ratelimit.rule_id'] 		 = rule_id
		@request_json['edge.ratelimit.action'] 			= action

		timestamp 								= Faker::Time.between(@start_time, @start_time + time_range).strftime('%FT%TZ') #=> "2014-09-18 12:30:59 -0700"
		
		@request_json['timestamp']				= timestamp		  			  
		@convert_json[timestamp] 				= @request_json


	end

	def create_ip_pool(ip_range)

		# create ip_pool

		ip_range.times do | ip |

			ip_address = []
			ip_address << Faker::Internet.public_ip_v4_address
			ip_address << Faker::Internet.ip_v6_address

			@ip_pool << ip_address.sample

		end

	end


	def attack(chronic_time: 'beginning of today', duration_in_minutes: 20, function: 't * 100', 
			   ip_range: 10, rule_id: 1, rule_action: :block, domain_range: 1 )

		@ip_pool = []

		# create set of domains

    	domain_range.times do | x |

    		@domains << Faker::Internet.domain_name
    	
    	end


		puts "** configs **"
		puts "chronic time: #{chronic_time}"
		@start_time = Chronic.parse(chronic_time)

		puts "start time: #{start_time}"

		puts "duration in minutes: #{duration_in_minutes}"
		puts "function: #{function}"
		puts "ip_range: #{ip_range}"
		puts "rule_id: #{rule_id}"
		puts "rule_action: #{rule_action}"

		create_ip_pool(ip_range)
		puts "ip_pool: #{ip_pool}"

		puts "  ****** "

		duration_in_minutes.times do |t|

			count = eval (function)
			puts "t = #{t}"
			puts "count = #{count}"

			count.times do | i |

				time_bucket_start = start_time + t.minutes
				timestamp 		  = Faker::Time.between(time_bucket_start, time_bucket_start + 1.minute).strftime('%FT%TZ')

				create_request

				@request_json['timestamp']				= timestamp
				@request_json['client.ip']				= @ip_pool.sample
				@request_json['edge.ratelimit.rule_id'] = rule_id
				@request_json['edge.ratelimit.action']  = rule_action

				@request_json_file = @request_json_file + @request_json.to_json + "\n"
			end

		end 

	end

end




