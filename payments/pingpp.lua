local ltn12 = require("ltn12")
local json = require("cjson")
local crypto = require("crypto")
local encode_query_string, parse_query_string
do
  local _obj_0 = require("lapis.util")
  encode_query_string, parse_query_string = _obj_0.encode_query_string, _obj_0.parse_query_string
end
local encode_base64, decode_base64
do
  local _obj_0 = require("lapis.util.encoding")
  encode_base64, decode_base64 = _obj_0.encode_base64, _obj_0.decode_base64
end
local _decode_base64
_decode_base64 = function(data)
  if not (data) then
    return 
  end
  local pad = {
    "=",
    "==",
    "==="
  }
  data = data:gsub('[\n\r]', '')
  local remainder = #data % 4
  if remainder > 0 then
    data = data .. pad[remainder]
  end
  return decode_base64(data)
end
local PingppSign
do
  local _class_0
  local _base_0 = {
    verify = function(self, data, sig)
      local signs = _decode_base64(sig)
      return crypto.verify(self.alg, data, signs, self.pubkey)
    end,
    sign = function(self, data)
      local sig = crypto.sign(self.alg, data, self.prikey)
      return encode_base64(sig)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, pubkeystr, privkeystr, alg)
      if alg == nil then
        alg = 'SHA256'
      end
      self.alg = alg
      if pubkeystr then
        self.pubkey = crypto.pkey.from_pem(pubkeystr)
      end
      if privkeystr then
        self.prikey = crypto.pkey.from_pem(privkeystr, true)
      end
    end,
    __base = _base_0,
    __name = "PingppSign"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  PingppSign = _class_0
end
local Pingpp
do
  local _class_0
  local resource
  local _parent_0 = require("payments.base_client")
  local _base_0 = {
    api_url = "https://api.pingxx.com/v1/",
    _request = function(self, method, path, params, access_token)
      if access_token == nil then
        access_token = self.api_key
      end
      local out = { }
      if params then
        for k, v in pairs(params) do
          params[k] = tostring(v)
        end
      end
      local body
      if method ~= "GET" then
        body = params and encode_query_string(params)
      end
      local parse_url = require("socket.url").parse
      local headers = {
        ["Host"] = assert(parse_url(self.api_url).host, "failed to get host"),
        ["Authorization"] = "Basic " .. encode_base64(access_token .. ":"),
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-length"] = body and tostring(#body) or nil
      }
      local url = self.api_url .. path
      if method == "GET" and params then
        url = url .. "?" .. tostring(encode_query_string(params))
      end
      local _, status = self:http().request({
        url = url,
        method = method,
        headers = headers,
        sink = ltn12.sink.table(out),
        source = body and ltn12.source.string(body) or nil,
        protocol = self.http_provider == "ssl.https" and "sslv23" or nil
      })
      local res = pcall(json.decode, table.concat(out))
      return self:_format_response(res, status)
    end,
    _format_response = function(self, res, status)
      if not status or status > 299 then
        return nil, res and res.message, res, status
      else
        return res, status
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, opts)
      self.app_id = assert(opts.app_id, "missing app id")
      self.api_key = assert(opts.api_key, "missing api key")
      return _class_0.__parent.__init(self, opts)
    end,
    __base = _base_0,
    __name = "Pingpp",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  resource = function(name, resource_opts)
    if resource_opts == nil then
      resource_opts = { }
    end
    local singular = resource_opts.singular or name:gsub("s$", "")
    local api_path = resource_opts.path or name
    local list_method = "list_" .. tostring(name)
    if not (resource_opts.get == false) then
      self.__base[list_method] = self.__base[list_method] or function(self, opts)
        return self:_request("GET", api_path, opts)
      end
      self.__base["get_" .. tostring(singular)] = self.__base["get_"] or function(self, id, opts)
        return self:_request("GET", tostring(api_path) .. "/" .. tostring(id), opts)
      end
    end
    if not (resource_opts.edit == false) then
      self.__base["update_" .. tostring(singular)] = self.__base["update_"] or function(self, id, opts)
        if resource_opts.update then
          opts = resource_opts.update(self, opts)
        end
        return self:_request("POST", tostring(api_path) .. "/" .. tostring(id), opts)
      end
      self.__base["delete_" .. tostring(singular)] = self.__base["delete_"] or function(self, id)
        return self:_request("DELETE", tostring(api_path) .. "/" .. tostring(id))
      end
    end
    if not (resource_opts.create == false) then
      self.__base["create_" .. tostring(singular)] = self.__base["create_"] or function(self, opts)
        if resource_opts.create then
          opts = resource_opts.create(self, opts)
        end
        return self:_request("POST", api_path, opts)
      end
    end
  end
  resource("charges", {
    edit = false,
    create = function(self, opts)
      assert(tonumber(opts.amount), "missing amount")
      assert(opts.subject, "missing subject")
      assert(opts.body, "missing body")
      assert(opts.order_no, "missing body")
      assert(opts.channel, "missing channel")
      assert(opts.client_ip, "missing client ip")
      opts.currency = 'cny'
      opts['app[id]'] = self.app_id
      return opts
    end
  })
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Pingpp = _class_0
end
return {
  Pingpp = Pingpp,
  PingppSign = PingppSign
}
