-- Real MrRos3/SaltyIcons white PNG masks, pinned to the inspected source commit.
-- The optional local-image API is the same capability used by the existing GUI.
-- No message content, identity tokens, or chat requests are sent over HTTP here.
local paths={chat="social/messages-square",send="social/send",attach="files/file-plus",
    heart="social/heart",like="social/thumbs-up",reply="navigation/corner-up-left",
    copy="misc/copy",more="misc/ellipsis",remove="misc/trash-2",user="social/user",
    x="status/x",mention="social/at-sign",down="navigation/chevron-down"}
local base="https://raw.githubusercontent.com/MrRos3/SaltyIcons/b7db826820a3456fe953f0097b1924de9e04ff97/icons/png/96/"
local cache={}
local configured={}
local errors={}
local function valid(data)
    return type(data)=="string" and #data>=8 and #data<131072 and data:sub(1,8)=="\137PNG\13\10\26\10"
end
local Assets={Paths=paths,Errors=errors}
function Assets.Configure(options) configured=options or {} end
function Assets.Resolve(key)
    if cache[key] then return cache[key] end
    if not paths[key] then return nil end
    local url=base..paths[key]..".png"
    -- Prefer the library's proven wallpaper/brand image pipeline.
    if type(configured.LoadRemoteImage)=="function" then
        local ok,result=pcall(configured.LoadRemoteImage,url,"VantaTestChat")
        if ok and type(result)=="string" and result~="" then cache[key]=result;errors[key]=nil;return result end
        errors[key]=tostring(result)
    end
    local custom=getcustomasset or getsynasset
    if type(custom)~="function" or type(writefile)~="function" then
        errors[key]=errors[key] or "Local image loading is unavailable in this environment."
        return nil,errors[key]
    end
    local ok,result=pcall(function()
        local filename="VantaTest-SaltyIcons-b7db826-"..key..".png"
        if type(makefolder)=="function" then
            pcall(makefolder,"VantaTest")
            pcall(makefolder,"VantaTest/SaltyIcons-b7db826")
            filename="VantaTest/SaltyIcons-b7db826/"..key..".png"
        end
        local readOK,data=false,nil
        if type(readfile)=="function" then readOK,data=pcall(readfile,filename) end
        if not readOK or not valid(data) then
            local downloaded,body=pcall(function()return game:HttpGet(url)end)
            if downloaded and valid(body) then data=body else data=nil end
            if not data then
                local requestImage=configured.Request or http_request or request or (syn and syn.request)
                if type(requestImage)=="function" then
                    local requested,response=pcall(requestImage,{Url=url,Method="GET"})
                    local candidate=requested and type(response)=="table" and (response.Body or response.body) or response
                    if valid(candidate) then data=candidate end
                end
            end
            assert(valid(data),"Original SaltyIcons PNG download failed.")
            writefile(filename,data)
        end
        return custom(filename)
    end)
    if ok and type(result)=="string" and result~="" then cache[key]=result;errors[key]=nil;return result end
    errors[key]=tostring(result)
    return nil,errors[key]
end
return Assets


