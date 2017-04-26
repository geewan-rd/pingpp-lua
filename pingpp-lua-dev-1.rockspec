package = "pingpp-lua"
version = "dev-1"

source = {
  url = "git://github.com/enginix/pingpp-lua.git",
}

description = {
  summary = "Pingpp support for lua, work with openresty.",
  homepage = "https://github.com/enginix/pingpp-lua",
  license = "None"
}

dependencies = {
  "payments",
  "luacrypto",
  "lapis", -- for encode_query_string
}

build = {
  type = "builtin",
  modules = {
    ["payments.pingpp"] = "payments/pingpp.lua",
  }
}
