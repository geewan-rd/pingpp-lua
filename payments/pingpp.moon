-- vim: et ts=2 sw=2:
ltn12 = require "ltn12"
json = require "cjson"
crypto = require "crypto"

import encode_query_string, parse_query_string from require "lapis.util"
import encode_base64, decode_base64 from require "lapis.util.encoding"

_decode_base64 = (data) ->
  return unless data
  pad = {"=", "==", "==="}
  data = data\gsub '[\n\r]', ''
  remainder = #data % 4
  if remainder > 0
    data ..= pad[remainder]
  decode_base64 data

class PingppSign
  new: (pubkeystr, privkeystr, @alg = 'SHA256') =>
    if pubkeystr
      @pubkey = crypto.pkey.from_pem pubkeystr
    if privkeystr
      @prikey = crypto.pkey.from_pem privkeystr, true

  verify: (data, sig) =>
    signs = _decode_base64 sig
    crypto.verify @alg, data, signs, @pubkey

  sign: (data) =>
    sig = crypto.sign @alg, data, @prikey
    encode_base64 sig

class Pingpp extends require "payments.base_client"
  api_url: "https://api.pingxx.com/v1/"

  new: (opts) =>
    @api_key = assert opts.api_key, "missing api key"
    @app_id = opts.app_id
    super opts

  resource = (name, resource_opts={}) ->
    singular = resource_opts.singular or name\gsub "s$", ""
    api_path = resource_opts.path or name

    list_method = "list_#{name}"

    unless resource_opts.get == false
      @__base[list_method] or= (opts) =>
        @_request "GET", api_path, opts

      @__base["get_#{singular}"] or= (id, opts) =>
        @_request "GET", "#{api_path}/#{id}", opts

    unless resource_opts.edit == false
      @__base["update_#{singular}"] or= (id, opts) =>
        if resource_opts.update
          opts = resource_opts.update @, opts

        @_request "POST", "#{api_path}/#{id}", opts

      @__base["delete_#{singular}"] or= (id) =>
        @_request "DELETE", "#{api_path}/#{id}"

    unless resource_opts.create == false
      @__base["create_#{singular}"] or= (opts) =>
        if resource_opts.create
          opts = resource_opts.create @, opts

        @_request "POST", api_path, opts

  _request: (method, path, params, access_token=@api_key) =>
    out = {}

    if params
      for k,v in pairs params
        params[k] = tostring v

    body = if method != "GET"
      params and encode_query_string params

    parse_url = require("socket.url").parse

    headers = {
      "Host": assert parse_url(@api_url).host, "failed to get host"
      "Authorization": "Basic " .. encode_base64 access_token .. ":"
      "Content-Type": "application/x-www-form-urlencoded"
      "Content-length": body and tostring(#body) or nil
    }

    url = @api_url .. path
    if method == "GET" and params
      url ..= "?#{encode_query_string params}"

    _, status = @http!.request {
      :url
      :method
      :headers
      sink: ltn12.sink.table out
      source: body and ltn12.source.string(body) or nil

      protocol: @http_provider == "ssl.https" and "sslv23" or nil
    }
    body = table.concat out
    if not status or status != 200 then
      ngx.log ngx.ERR, "url: ", url
      if params
        ngx.log ngx.ERR, "params: ", tostring(encode_query_string(params))
      if status
        ngx.log ngx.ERR, "status: ", status
      ngx.log ngx.ERR, "response: ", body
    ok, res = pcall json.decode, body
    res = {message: "bad response: #{tostring(body)\sub(1, 20)}"} unless ok
    @_format_response res, status

  _format_response: (res, status) =>
    if not status or status > 299
      nil, res.message, res, status
    else
      res, status

  resource "charges", {
    edit: false
    create: (opts) =>
      assert tonumber(opts.amount), "missing amount"
      assert opts.subject, "missing subject"
      assert opts.body, "missing body"
      assert opts.order_no, "missing body"
      assert opts.channel, "missing channel"
      assert opts.client_ip, "missing client ip"
      assert @app_id, "missing app ip"

      opts.currency = 'cny'
      opts['app[id]'] = @app_id

      opts
  }

{ :Pingpp, :PingppSign }
