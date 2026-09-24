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
    
    local lowerQuery = string.lower(query)
    local cleanQuery = string.gsub(lowerQuery, "search web for", "")
    cleanQuery = string.gsub(cleanQuery, "search web", "")
    cleanQuery = string.gsub(cleanQuery, "search", "")
    cleanQuery = string.gsub(cleanQuery, "lookup", "")
    cleanQuery = string.match(cleanQuery, "^%s*(.-)%s*$")
    
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
                return "No abstract found for: " .. cleanQuery
            end
        end
    end

    return "Failed to establish secure web connection."
end

return Web
