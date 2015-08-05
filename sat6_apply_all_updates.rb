#!/usr/local/rvm/rubies/ruby-2.2.1/bin/ruby
#
# This script will apply all erratas for a given content host
# This script requires Satellite 6.1 and V2 APIs
# You need to update URL, KATELLO_URL, username, password and host
#
require 'rest-client'
require 'json'

url = 'https://sat6.host.com/api/v2/'
katello_url = 'https://sat6.host.com/katello/api/v2/'
$username = 'xxxxx'
$password = 'xxxxx'
host = "sat6.content.host.com"

def get_json(location)
	response = RestClient::Request.new(
		:method => :get,
		:url => location,
		:verify_ssl => false,
		:user => $username,
		:password => $password,
		:headers => { :accept => :json,
		:content_type => :json }
	).execute

	results = JSON.parse(response.to_str)
end

def put_json(location, json_data)
	response = RestClient::Request.new(
		:method => :put,
		:url => location,
		:verify_ssl => false,
		:user => $username,
		:password => $password,
		:headers => { :accept => :json,
		:content_type => :json},
		:payload => json_data
	).execute
	results = JSON.parse(response.to_str)
end

systems = get_json(katello_url+"systems")
uuid = {}
hostExists = false
systems['results'].each do |system|
	if system['name'].include? host
		puts "Host ID " + system['id']
		puts "Host UUID " + system['uuid']
		uuid = system['uuid'].to_s
		hostExists = true
	end
end

if !hostExists
	puts "Host " + host + " not found"
	exit()
end

erratas = get_json(katello_url+"systems/"+uuid+"/errata")
errata_list = Array.new
erratas['results'].each do |errata|
	errata_id = errata['errata_id']
	puts "Errata id[" + errata['errata_id'] + "] title[" + errata['title'] + "] severity[" + errata['severity'] + "] found"
	errata_list.push errata_id
end

if erratas['results'].nil? || erratas['results'].empty?
	puts "No erratas found for host " + host
end

errata_result = put_json(katello_url+"systems/"+uuid+"/errata/apply", JSON.generate({"errata_ids"=>errata_list}))
puts "Errata Updates are being applied pending[" + errata_result['pending'].to_s + "] state[" + errata_result['state'] + "]"

exit()
