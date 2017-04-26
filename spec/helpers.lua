local parse_query_string
parse_query_string = require("lapis.util").parse_query_string
local assert_shape
assert_shape = function(obj, shape)
  return assert(shape(obj))
end
local extract_params
extract_params = function(str)
  local params = assert(parse_query_string(str))
  local _tbl_0 = { }
  for k, v in pairs(params) do
    if type(k) == "string" then
      _tbl_0[k] = v
    end
  end
  return _tbl_0
end
local make_http
make_http = function(handle)
  local http_requests = { }
  local fn
  fn = function(self)
    self.http_provider = "test"
    return {
      request = function(req)
        table.insert(http_requests, req)
        if handle then
          handle(req)
        end
        return 1, 200, { }
      end
    }
  end
  return fn, http_requests
end
return {
  extract_params = extract_params,
  make_http = make_http,
  assert_shape = assert_shape
}
