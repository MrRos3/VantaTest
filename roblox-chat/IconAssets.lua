-- Real MrRos3/SaltyIcons white PNG masks, pinned to the inspected source commit.
-- The optional local-image API is the same capability used by the existing GUI.
-- No message content, identity tokens, or chat requests are sent over HTTP here.
local paths={chat="social/messages-square",send="social/send",attach="files/file-plus",
    heart="social/heart",like="social/thumbs-up",reply="navigation/corner-up-left",
    copy="misc/copy",more="misc/ellipsis",remove="misc/trash-2",user="social/user",
    x="status/x",mention="social/at-sign",down="navigation/chevron-down"}
local base="https://raw.githubusercontent.com/MrRos3/SaltyIcons/b7db826820a3456fe953f0097b1924de9e04ff97/icons/png/96/"
local cache={}
local function valid(data)
    return type(data)=="string" and #data>=8 and #data<131072 and data:sub(1,8)=="\137PNG\13\10\26\10"
end
local Assets={Paths=paths}
function Assets.Resolve(key)
    if cache[key] then return cache[key] end
    if not paths[key] then return nil end
    local custom=getcustomasset or getsynasset
    if type(custom)~="function" or type(writefile)~="function" or type(readfile)~="function" or type(makefolder)~="function" then return nil end
    local ok,result=pcall(function()
        pcall(makefolder,"VantaTest")
        pcall(makefolder,"VantaTest/SaltyIcons-b7db826")
        local filename="VantaTest/SaltyIcons-b7db826/"..key..".png"
        local readOK,data=pcall(readfile,filename)
        if not readOK or not valid(data) then
            data=game:HttpGet(base..paths[key]..".png")
            assert(valid(data),"Invalid SaltyIcons PNG")
            writefile(filename,data)
        end
        return custom(filename)
    end)
    if ok and type(result)=="string" and result~="" then cache[key]=result;return result end
    return nil
end
return Assets

