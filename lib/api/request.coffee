# Node modules
QueryS = require 'querystring'
Path   = require 'path'
FS     = require 'fs'

# NPM modules
Request = require 'request'

# generate a secure call to own API
module.exports = (method, url, options, callback)->

	caller = (context, error, data)->
		opts = method:'debug', caller:'API:' + method
		ﬁ.log.custom opts, JSON.stringify(if error then error else data)
		opts = undefined
		callback.call context, error, data

	args = Array::slice.call arguments
	# if no options are being sent, the user can ommit them and send the CB instead
	if args.length is 3 and ﬁ.util.isFunction options
		callback = options
		options  = {}
	options = {} if not ﬁ.util.isDictionary options

	throw new ﬁ.error 'Invalid callback.' if not ﬁ.util.isFunction callback

	return caller(null, 'Invalid method name.') if not ﬁ.util.isString method
	return caller(null, 'Invalid url.')         if not ﬁ.util.isString url
	return caller(null, 'Invalid options.')     if not ﬁ.util.isDictionary options
	
	# convert options to query string in order to send data, following HTTPS specs.
	if not ﬁ.util.isEmptyDictionary(options) and (method is 'get' or method is 'delete')
		url += if url.indexOf('?') is -1 then '?' else '&'
		url += QueryS.stringify options	
		options = {}

	url     = url.substring(1) if url[0] is '/'
	method  = method.toUpperCase()
	url     = [ﬁ.conf.url, ﬁ.conf.api.substring(1), url].join('/')
		
	onResponse = (error, response, body)->
		return caller(response, error) if error
		if not ﬁ.util.isString(body) and not ﬁ.util.isArray(body)
			return caller response, 'Invalid response body'
		if ﬁ.util.isString(body)
			try
				body = JSON.parse body
			catch e
				ﬁ.log.warn "Response body was not parsed."
		if response.statusCode isnt 200
			body = [body] if not ﬁ.util.isArray(body)
			caller(response, body)
		else
			caller(response, null, body.response)

	if method is 'GET' or method is 'DELETE'
		challenge = [method, url].join(';')
		API       = ﬁ.util.hmac(challenge,'hex')
		url += (if url.indexOf('?') is -1 then '?' else '&') + "API=#{API}"
		Request (method: method, uri: url), onResponse 
	else
		challenge = [method, url, QueryS.stringify options].join(';')
		options.API = ﬁ.util.hmac challenge, 'hex'
		Request (method:method, uri:url, form:options), onResponse 	