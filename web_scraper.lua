-- ========================================================
-- WEB SCRAPER MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")
local Web = {}

-- Added broader executor support (e.g., fluxus) to match the new AI module
local requestFunc = (request or http_request or (syn and syn.request) or (fluxus and fluxus.request))

function Web.Search(query)
    if not requestFunc then
        return "Web search blocked: Executor lacks HTTP request capability."
    end
    
    -- Smarter query cleaning to improve API hit rates
    local lowerQuery = string.lower(query)
    local cleanQuery = lowerQuery:gsub("search the web for", "")
                                 :gsub("search web for", "")
                                 :gsub("search for", "")
                                 :gsub("search", "")
                                 :gsub("lookup", "")
                                 :gsub("who is", "")
                                 :gsub("what is", "")
    
    -- Trim leading and trailing whitespace
    cleanQuery = string.match(cleanQuery, "^%s*(.-)%s*$")
    
    -- Fallback if the entire prompt was just trigger words
    if not cleanQuery or cleanQuery == "" then
        cleanQuery = query
    end
    
    local safeQuery = HttpService:UrlEncode(cleanQuery)
    local url = "https://api.duckduckgo.com/?q=" .. safeQuery .. "&format=json"
    
    local success, response = pcall(function()
        return requestFunc({Url = url, Method = "GET"})
    end)
    
    if success and response and (response.StatusCode == 200 or response.Success) then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if decodeSuccess and data then
            if data.AbstractText and data.AbstractText ~= "" then
                return data.AbstractText
            elseif data.RelatedTopics and #data.RelatedTopics > 0 and data.RelatedTopics[1].Text then
                return data.RelatedTopics[1].Text
            else
                return "No direct web summary found for: '" .. cleanQuery .. "'. Try using more specific keywords."
            end
        end
    end

    return "Failed to establish a secure web connection or the API is currently unavailable."
end

return Web
