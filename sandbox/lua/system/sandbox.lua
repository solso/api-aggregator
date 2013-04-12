--[[

Run the API aggregation scripts on a sandboxed environment

In the table sandboxed_env you define all the functions that the api aggregation
lua scripts will be able to use. For instance, we can limit the functions available
on the nginx module: { var = ngx.var, re = ngx.re, location = ngx.location, 
header = ngx.header, exit = ngx.exit, say = ngx.say, HTTP_OK = ngx.HTTP_OK}

You can be as restrictive as you want. Note that each request in nginx runs the lua
script in a different lua virtual machine, so it's not possible to cross-contaminate 
requests.

Check http://lua-users.org/wiki/SandBoxes for more pointers

Additionally, you can set up a timeout of the script by setting a value on,

debug.sethook(timeout_response, "", 5000)

The 5000 is the number of operations that the lua script can execute before timing
out. This will kill automatically any long running requests. Tuning this parameters
depends on the complexity of the scripts that you allow to run. 5000 is plenty for 
the sentence_with_highest_word.lua 

]]--

sandboxed_env = {
  ipairs = ipairs,
  next = next,
  pairs = pairs,
  pcall = pcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  unpack = unpack,
  string = { byte = string.byte, char = string.char, find = string.find,
      format = string.format, gmatch = string.gmatch, gsub = string.gsub,
      len = string.len, lower = string.lower, match = string.match,
      rep = string.rep, reverse = string.reverse, sub = string.sub,
      upper = string.upper },
  table = { insert = table.insert, maxn = table.maxn, remove = table.remove,
      sort = table.sort },
  math = { abs = math.abs, acos = math.acos, asin = math.asin,
      atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
      cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
      fmod = math.fmod, frexp = math.frexp, huge = math.huge,
      ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max,
      min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
      rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh,
      sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
  os = { clock = os.clock, difftime = os.difftime, time = os.time },
  print = print,
  utils = require "utils_3scale",
  cjson = require "cjson",
  ngx = ngx
}

--[[
  Needs to file which file to lua based on the URL
]]--

local utils = require "utils_3scale"
local path = utils.split(ngx.var.request," ")[2]
local user_script_file = ngx.re.match(path,[=[^\/aggr\/([a-zA-Z0-9-_]+)]=])[1]
lc = loadfile(ngx.var.lua_user_scripts_path..user_script_file..".lua")

if (lc == nil) then
  ngx.exit(ngx.HTTP_NOT_FOUND)
else
  user_function = lc()
  if (user_function == nil) then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
end

local timeout_response = function()
  debug.sethook()
  error("The lua script " .. ngx.var.function_to_call_file .. " has timed out!!")
end

debug.sethook(timeout_response, "", 5000)

setfenv(user_function, sandboxed_env)
local res_user_function = pcall(user_function)
if not res_user_function then
  error("There was an error running " .. ngx.var.function_to_call_file)
end
debug.sethook()

