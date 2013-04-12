--[[
Example of a user script
]]--

return function()
  local path = utils.split(ngx.var.request," ")[2]
  ngx.header.content_type = "text/plain"
  ngx.say(path.." rules!")
  ngx.exit(ngx.HTTP_OK)
end