# Description:
#   hubot eat saba
#
# Commands:
#   hubot mackerel hosts - show all hosts and graph urls
#   hubot mackerel hosts [service <service>] [role <role>] [name <name>] [status <status>] - show hosts and graph urls filterd by specified service, role, name or status
#   hubot mackerel host <hostId> - show detail information about the host
#   hubot mackerel status <hostId> <standby|working|maintenance|poweroff> - update status of the host
#   hubot mackerel retire <hostId> - retuire the host
#
# Author:
#   mdoi

checkToken = (msg) ->
  unless process.env.HUBOT_MACKEREL_API_KEY?
    msg.send 'You need to set HUBOT_MACKEREL_API_KEY to a valid Mackerel API key'
    return false
  else
    return true

checkEndpoint = (msg) ->
  unless process.env.HUBOT_MACKEREL_API_ENDPOINT?
    msg.send 'You need to set HUBOT_MACKEREL_API_ENDPOINT'
    return false
  else
    return true

checkUrlBase = (msg) ->
  unless process.env.HUBOT_MACKEREL_URL_BASE?
    msg.send 'You need to set HUBOT_MACKEREL_URL_BASE'
    return false
  else
    return true

handleResponse = (msg, handler) ->
  (err, res, body) ->
    if err?
      msg.send "Failed to get mackerel api response: #{err}"

    switch res.statusCode
      when 404
        response = JSON.parse(body)
        msg.send "Failed to get mackerel api response: Not Found"
      when 401
        msg.send 'Failed to get mackerel api response: Not authorized'
      when 500
        msg.send 'Failed to get mackerel api response: Internal server error'
      when 200
        response = JSON.parse(body)
        handler response
      else
        msg.send "Failed to get mackerel api response: #{res.statusCode}", body

module.exports = (robot) ->
  robot.respond /mackerel hosts(.*)/i, (msg) ->
    unless checkToken(msg)
      return
    unless checkEndpoint(msg)
      return
    unless checkUrlBase(msg)
      return
    queryString = ""
    if msg.match[1].length > 0
      queryStringArray = []
      addQueryString = false
      options = msg.match[1].trim()
      optionMatch = /service\s+(\S+)/.exec(options)
      if optionMatch?
        addQueryString = true
        queryStringArray.push('service=' + optionMatch[1])
      optionMatch = /role\s+(\S+)/.exec(options)
      if optionMatch?
        addQueryString = true
        queryStringArray.push('role=' + optionMatch[1])
      optionMatch = /name\s+(\S+)/.exec(options)
      if optionMatch?
        addQueryString = true
        queryStringArray.push('name=' + optionMatch[1])
      optionMatch = /status\s+(\S+)/.exec(options)
      if optionMatch?
        addQueryString = true
        queryStringArray.push('status=' + optionMatch[1])
      if addQueryString
        queryString = '?' + queryStringArray.join('&')
    msg.http(process.env.HUBOT_MACKEREL_API_ENDPOINT + "hosts.json" + queryString)
      .headers("X-Api-Key": process.env.HUBOT_MACKEREL_API_KEY)
      .get() handleResponse  msg, (response) ->
          if response.length == 0
            msg.send "Failed to get mackerel api response: resnponse is empty"
          else
            hosts_text = ""
            for k,v of response['hosts']
              hosts_text += "#{v['name']} - #{v['id']}" + "\n" + process.env.HUBOT_MACKEREL_URL_BASE + v['id'] + "\n\n"
            msg.send hosts_text

  robot.respond /mackerel status (\w+) (standby|working|maintenance|poweroff)/i, (msg) ->
    unless checkToken(msg)
      return
    unless checkEndpoint(msg)
      return
    unless checkUrlBase(msg)
      return

    host_id = msg.match[1]
    status = msg.match[2]

    if !host_id
      msg.send "No host_id specified"

    post_content = JSON.stringify({status: status})
    headers =
      "X-Api-Key": process.env.HUBOT_MACKEREL_API_KEY
      "Content-Type": "application/json"

    msg.http(process.env.HUBOT_MACKEREL_API_ENDPOINT + "hosts/#{host_id}/status")
      .headers(headers)
      .post(post_content) handleResponse  msg, (response) ->
        if !response.success
          msg.send "Failed to update status: #{host_id} to #{status}"
        msg.send "Status of #{host_id} is updated to #{status}"

  robot.respond /mackerel retire (\w+)/i, (msg) ->
    unless checkToken(msg)
      return
    unless checkEndpoint(msg)
      return
    unless checkUrlBase(msg)
      return

    host_id = msg.match[1]

    if !host_id
      msg.send "No host_id specified"

    post_content = JSON.stringify({})
    headers =
      "X-Api-Key": process.env.HUBOT_MACKEREL_API_KEY
      "Content-Type": "application/json"

    msg.http(process.env.HUBOT_MACKEREL_API_ENDPOINT + "hosts/#{host_id}/retire")
      .headers(headers)
      .post(post_content) handleResponse  msg, (response) ->
        if !response.success
          msg.send "Failed to retire host: #{host_id}"
        msg.send "host #{host_id} retired"

  robot.respond /mackerel host (\w+)/i, (msg) ->
    unless checkToken(msg)
      return
    unless checkEndpoint(msg)
      return
    unless checkUrlBase(msg)
      return

    host_id = msg.match[1]

    if !host_id
      msg.send "No host_id specified"

    headers =
      "X-Api-Key": process.env.HUBOT_MACKEREL_API_KEY

    msg.http(process.env.HUBOT_MACKEREL_API_ENDPOINT + "hosts/#{host_id}")
      .headers(headers)
      .get() handleResponse  msg, (response) ->
        if !response.host
          msg.send "Failed to get host information: #{host_id}"
        msg.send JSON.stringify response.host, null, 2
