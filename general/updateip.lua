#!/usr/bin/lua

-- For use with openwrt since openwrt supports LUA.
-- Prerequisites:

-- luasec
-- luasocket
-- libubus-lua
-- json4lua

-- I have a PPPoE connection so I just drop this script in /etc/ppp/ip-up.d
-- You can run via crontab or put it in interface hotplug :)

update_records = {"ddns"}
domain_name = "domain.com"

function log(msg)
	os.execute("logger -t updateip '" .. msg .. "'")
end

require ("os")
json = require ("json")
require ("socket")
https = require ("ssl.https")
require ("ltn12")

reqheaders = {
	["X-Auth-Email"] = "EMAIL_ID",
	["X-Auth-Key"] = "API_KEY",
	["Content-Type"] = "application/json",
}

zones = {}

success = https.request({
	url = "https://api.cloudflare.com/client/v4/zones?name=" .. domain_name,
	sink = ltn12.sink.table(zones),
	method = "GET",
	headers = reqheaders,
})

if not success then
	log('Failed to fetch zones')
	os.exit(1)	
end

zones = json.decode(zones[1])

if not zones.success then
	log('Zone fetch failed')
	os.exit(1)
end

zone_id = zones.result[1].id

for i, name in ipairs(update_records) do
	if name ~= domain_name then
		update_records[i] = string.format("%s.%s", name, domain_name)
	end
end

record_filter = "name=" .. table.concat(update_records, ",")

records = {}
success = https.request({
	url = "https://api.cloudflare.com/client/v4/zones/" .. zone_id .. "/dns_records?type=A&" .. record_filter,
	sink = ltn12.sink.table(records),
	method = "GET",
	headers = reqheaders
})

if not success then
	log('Failed to fetch dns records')
	os.exit(1)
end

records = json.decode(records[1])

if not records.success then
	log('Record fetch failed')
	os.exit(1)
end

update_records_1 = {}

require ("ubus")
u = ubus.connect()

if not u then
	log('Ubus connect failed')
	os.exit(1)
end

status = u:call("network.interface.wan", "status", {})
ip = status["ipv4-address"][1]["address"]

for _, record in pairs(records.result) do
	for _, name in pairs(update_records) do
		if name == record.name then
			record.content = ip
			table.insert(update_records_1, record)
		end
	end
end

for _, record in pairs(update_records_1) do
	encoded_update = json.encode(record)	
	response = {}
	reqheaders["content-length"] = string.len(encoded_update)
	success = https.request({
		url = "https://api.cloudflare.com/client/v4/zones/" .. zone_id .. "/dns_records/" .. record.id,
		method = "PUT",
		headers = reqheaders,
		sink = ltn12.sink.table(response),
		source = ltn12.source.string(encoded_update)
	})
	if not success then
		log("Failed to update " .. record.name)
	else
		response = json.decode(response[1])
		if not response.success then
			log("Failed to update " .. record.name)
		else
			log("Updated " .. record.name)
		end
	end
end
