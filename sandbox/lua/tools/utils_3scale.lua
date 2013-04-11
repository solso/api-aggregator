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

return M
