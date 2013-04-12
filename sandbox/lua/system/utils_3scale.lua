--[[
Auxiliary functions
]]--

local M = {} -- public interface

function M.split(self, delimiter)
  local result = { }
  local from = 1
  local delim_from, delim_to = string.find( self, delimiter, from )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from )
  end
  table.insert( result, string.sub( self, from ) )
  return result
end

function M.escape(self)
  local nstr = string.gsub(self, "([&=+%c])", function (c) return string.format("%%%02X", string.byte(c)) end)
  return string.gsub(nstr, " ", "+")
end

function M.unescape(self)
  local nstr = string.gsub(self, "+", " ")
  return string.gsub(nstr, "%%(%x%x)", function (h) return string.char(tonumber(h, 16)) end)
end

function M.get_query_args_extended(self)
  local args = self
  for k, v in pairs(args) do
    t = {}
    for k2 in string.gmatch(k, "%b[]") do
      table.insert(t,string.sub(k2,2,string.len(k2)-1))
    end
    if #t > 0 then
      -- it has nested params, needs to be transformed
      first = string.sub(k,1,string.find(k,"%[")-1)
      if args[first]==nil or type(args[first])~="table" then
        args[first] = {}
      end
      args[first][t[1]] = v
    end
  end
  return args
end

return M
