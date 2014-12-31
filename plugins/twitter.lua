local OAuth = require "OAuth"

local consumer_key = ""
local consumer_secret = ""
local access_token = ""
local access_token_secret = ""

local client = OAuth.new(consumer_key, consumer_secret, {
    RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
}, {
    OAuthToken = access_token,
    OAuthTokenSecret = access_token_secret
})

function run(msg, matches)

  local twitter_url = "https://api.twitter.com/1.1/statuses/show/" .. matches[1] .. ".json"

  print(twitter_url)

  local response_code, response_headers, response_status_line, response_body = client:PerformRequest("GET", twitter_url)
  print(response_body)
  local response = json:decode(response_body)

  print("response = ", response)

  local header = "Tweet from " .. response.user.name .. " (@" .. response.user.screen_name .. ")\n"
  local text = response.text
  
  -- replace short URLs
  if response.entities.url then
    for k, v in pairs(response.entities.urls) do 
        local short = v.url
        local long = v.expanded_url
        text = text:gsub(short, long)
    end
  end
  
  -- remove images
  local images = {}
  if response.entities.media then
    for k, v in pairs(response.entities.media) do
        local url = v.url
        local pic = v.media_url
        text = text:gsub(url, "")
        table.insert(images, pic)
    end
  end

  -- send the parts 
  local receiver = get_receiver(msg)
  send_msg(receiver, header .. "\n" .. text, ok_cb, false)
  for k, v in pairs(images) do
    local file = download_to_file(v)
    send_photo(receiver, file, ok_cb, false)
  end
  
  return nil
end

return {
    description = "When user sends twitter URL, send text and images to origin. Requieres OAuth Key.", 
    usage = "",
    patterns = {"https://twitter.com/[^/]+/status/([0-9]+)"}, 
    run = run 
}


