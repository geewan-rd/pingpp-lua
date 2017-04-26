-- vim: et ts=2 sw=2:
import types from require "tableshape"
import extract_params, make_http, assert_shape from require "spec.helpers"

import parse_query_string from require "lapis.util"

assert_shape = (obj, shape) ->
  assert shape obj

describe "pingpp", ->
  it "creates a pingpp object", ->
    import Pingpp from require "payments.pingpp"
    pingpp = assert Pingpp {
      app_id: "app_your_app_id"
      api_key: "sk_test_your_api_key"
    }

  describe "with client", ->
    local pingpp, http_requests, http_fn
    local api_response

    api_request = (opts={}, fn) ->
      method = opts.method or "GET"
      spec_name = opts.name or "#{method} #{opts.path}"

      it spec_name, ->
        response = { fn! }

        assert.same {
          opts.response_object or {hello: "world"}
          200
        }, response

        req = assert http_requests[#http_requests], "expected http request"

        assert_shape req, types.shape {
          :method
          url: "https://api.pingxx.com/v1#{assert opts.path, "missing path"}"

          sink: types.function
          source: opts.body and types.function

          headers: types.shape {
            "Host": "api.pingxx.com"
            "Content-Type": "application/x-www-form-urlencoded"
            "Content-length": opts.body and types.pattern "%d+"
            "Authorization": "Basic Y2xpZW50X3NlY3JldDo="
          }
        }

        if opts.body
          source = req.source!
          source_data = parse_query_string source
          expected = {k,v for k,v in pairs source_data when type(k) == "string"}
          assert.same opts.body, expected

    before_each ->
      api_response = nil -- reset to default
      import Pingpp from require "payments.pingpp"
      http_fn, http_requests = make_http (req) ->
        req.sink api_response or '{"hello": "world"}'

      pingpp = assert Pingpp {
        app_id: "app_id"
        api_key: "client_secret"
      }
      pingpp.http = http_fn

    describe "charges", ->
      api_request {
        method: 'POST'
        path: "/charges"
        body: {
          order_no: '123456789'
          amount: '100'
          subject: 'donate'
          body: 'support us'
          channel: 'wx'
          client_ip: '127.0.0.1'
          ['app[id]']: "app_id"
          currency: 'cny'
        }
      }, ->
        pingpp\create_charge {
          order_no: 123456789
          amount: 100
          subject: 'donate'
          body: 'support us'
          channel: 'wx'
          client_ip: '127.0.0.1'
        }

