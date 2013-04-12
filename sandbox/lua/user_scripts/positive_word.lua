
--[[
User script that returns the word with highest positive emotional value.
It runs against the SentimentAPI REST AP. See blog entry for the full details.
]]--

return function()

  local max_sentiment = 5
  local params = ngx.req.get_query_args()
  local path = utils.split(ngx.var.request," ")[2]

  -- Get the sentence to be analyzed from the URL path
  local sentence = ngx.re.match(path,[=[^/aggr/positive_word/(.+).json]=])[1]
  sentence = utils.unescape(sentence)

  -- Do the REST API request to get the sentiment value of the sentence
  local res_sentence = ngx.location.capture("/v1/sentence/".. utils.escape(sentence) .. ".json" )
  local result = cjson.decode(res_sentence.body)

  -- If positive
  if (result["sentiment"]>0) then

    sentence = utils.unescape(sentence)

    local max = nil
    local words = utils.split(sentence," ")

    -- for each word in the sentence, do the REST API request to get the sentiment value of the 
    -- word
    for i,w in pairs(words) do
      local res_word = ngx.location.capture("/v1/word/".. utils.escape(w) .. ".json" )
      local word = cjson.decode(res_word.body)
      if max == nil or max < word.sentiment then
        max = word.sentiment
        result.highest_positive_sentiment_word = word
        if word.sentiment == max_sentiment then
          break
        end
      end
    end
  end

  ngx.header.content_type = "application/json"
  ngx.say(cjson.encode(result))
  ngx.exit(ngx.HTTP_OK)

end
