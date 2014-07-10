# Description:
#   saba
#
# Commands:
#   hubot mackerel hosts - show all hosts and graph urls
#   hubot mackerel hosts service <service> - show hosts and graph urls filterd by specified service
#   hubot mackerel hosts service <service> role <role> - show hosts and graph urls filterd by specified service and role
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
      if addQueryString
        queryString = '?' + queryStringArray.join('&')
    unless checkToken(msg)
      return
    unless checkEndpoint(msg)
      return
    unless checkUrlBase(msg)
      return
    msg.http(process.env.HUBOT_MACKEREL_API_ENDPOINT + "hosts.json" + queryString)
      .headers("X-Api-Key": process.env.HUBOT_MACKEREL_API_KEY)
      .get() handleResponse  msg, (response) ->
          if response.length == 0
            msg.send "Failed to get mackerel api response: resnponse is empty"
          else
            hosts_text = ""
            for k,v of response['hosts']
              hosts_text += v['name'] + "\n" + process.env.HUBOT_MACKEREL_URL_BASE + v['id'] + "\n\n"
            msg.send hosts_text
