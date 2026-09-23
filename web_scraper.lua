-- ========================================================
-- WEB SCRAPER MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")
local Web = {}
local requestFunc = (request or http_request or (syn and syn.request))

function Web.Search(query)
    if not requestFunc then
        return "Web search blocked: Executor lacks HTTP request capability."
    end
    
    -- Extract the search term from phrases like "search web for X"
    local cleanQuery = string.gsub(query, "search web", "")
    cleanQuery = string.gsub(cleanQuery, "search", "")
    cleanQuery = string.match(cleanQuery, "^%s*(.-)%s*$") -- Trim whitespace
    
    local safeQuery = HttpService:UrlEncode(cleanQuery)
    local url = "https://api.duckduckgo.com/?q=" .. safeQuery .. "&format=json"
    
    local success, response = pcall(function()
        return requestFunc({Url = url, Method = "GET"})
    end)
    
    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data.AbstractText and data.AbstractText ~= "" then
            return data.AbstractText
        elseif data.RelatedTopics and #data.RelatedTopics > 0 and data.RelatedTopics[1].Text then
            return data.RelatedTopics[1].Text
        else
            return "No abstract found for this query."
        end
    else
        return "Failed to establish secure web connection."
    end
end

return Web
