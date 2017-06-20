# pingpp-lua
`pingpp-lua` is a [lua-payments](https://github.com/leafo/lua-payments) extension that lets you pay with [ping++](https://www.pingxx.com).

The following APIs are supported:
- [Charges](#charges)
- [Signature](#signature)
# Examples
Create the API client:
```lua
local pingpp = require("payments.pingpp")

local client = pingpp.Pingpp({
    app_id = "your-app-id",
    app_key = "sk_xxxxxxxx"
})
```

### Charges
Create a new charge:
```lua
local pingxx_charge = assert(client:create_charge({
    order_no = "123456789",
    amount = 100,
    subject = "Some thing",
    body = "Buy sth.",
    channel = "wx",
    client_ip = "127.0.0.1"

}))
-- send pingxx_charge to client.
```
Query charge:
```lua
local pingxx_charge = assert(client:get_charge({
    id = "ch_xxxxxxxx",
}))
-- check charge state etc.
```

### Signature
Verify signature of [webhooks](https://www.pingxx.com/api?language=cURL#events-事件) request:
```lua
local pingpp = require("payments.pingpp")
local verifier = pingpp.PingppSign('Your-pingpp-public-key')
-- parse request to table, get signature from http header['x-pingplusplus-signature']
assert(verifier(request, signature))
```
# License
MIT, Copyright (C) 2017 by enginix.
