local util = {
    Patterns = {
        Players = "506C6179657273??????????????????07000000000000000F";
        Inject = "496E6A656374????????????????????06";
    },

    RobloxNames = {
        "RobloxPlayerBeta",
        "Windows10Universal"
    },

    InjectMethod = "Reset",
    InjectMethods = {
        "Tool",
        "Reset"
    },

    Patched = false,
    Discontinued = false
}

if util.Discontinued then return print("We're sorry, but Vulkan is discontinued now :(\10") end
if util.Patched then return print("\10Vulkan is patched!\10Please be patient while we fixing it.\10It can take 1-2 days or less.\10") end

local function wait(t)
    if not tonumber(t) then return end
    return sleep(math.max(0, tonumber(t)) * 1000)
end
local error = function(str)
    if not str then error() end
    error(tostring(str).."\10\10\10\10")
end
local function httpGet(url)
    local internet = getInternet('CEVersionCheck')
    local res = internet.getURL(url)
    internet = nil
    return res
end
local typeof = type
local table = {
    insert = function(t, e)
        if typeof(t) ~= "table" then return nil end
        local emptyIdx = 0
        local idxExist = function(i)
            local e = false
            for I,v in pairs(t) do 
               if I == i then
                e = true
               end
            end
            return e
        end
        repeat
            emptyIdx = emptyIdx + 1
        until idxExist(emptyIdx) == false
        t[emptyIdx] = e
    end,
    find = function(t, e)
        if typeof(t) ~= "table" then return nil end
        for i,v in pairs(t) do
            if v == e then
                return i
            end
        end
    end
}

util.aobScan = function(aob, code)
    local new_results = {}
    local results = AOBScan(aob, "*X*C*W")
    if not results then
        return new_results
    end
    for i = 1,results.Count do
        local x = getAddress(results[i - 1])
        table.insert(new_results, x)
    end
    return new_results
end

util.intToBytes = function(val)
    if val == nil then
        error('Cannot convert nil value to byte table')
    end
    local t = { val % 256 }
    for i = 1, 7 do
        val = math.floor(val / 256)
        table.insert(t, val % 256)
    end
    return t
end

function onOpenProcess()
    
end

inject = function()
    hideCe()
    for i,v in pairs(util.RobloxNames) do
        openProcess(v)
    end
    local players, nameOffset, valid;
    local results = util.aobScan(util.Patterns.Players)
    for rn = 1,#results do
        hideCe()

        local result = results[rn];

        if not result then
            return false
        end

        local bres = util.intToBytes(result);
        local aobs = ""
        for i = 1,8 do
            aobs = aobs .. string.format("%02X", bres[i])
        end

        local first = false
        local res = util.aobScan(aobs)
        if res then
            valid = false
            for i = 1,#res do
                hideCe()
                result = res[i]
                for j = 1,10 do
                    hideCe()
                    local ptr = readQword(result - (8 * j))
                    if ptr then
                        ptr = readQword(ptr + 8)
                        if (readString(ptr) == "Players") then
                            players = (result - (8 * j)) - 0x18
                            nameOffset = result - players
                            value = true
                            break
                        end
                    end
                end
                if valid then break end
            end
        end

        if valid then break end
    end

    if not players then error("Open your roblox dude") end
    hideCe()

    local parentOffset = 0;
    for i = 0x10, 0x120, 8 do
        local ptr = readQword(players + i)
        if ptr ~= 0 and ptr % 4 == 0 then
            if (readQword(ptr + 8) == ptr) then
                parentOffset = i
                break
            end
        end
    end


    local dataModel = readQword(players + parentOffset)


    local childrenOffset = 0;
    for i = 0x10, 0x200, 8 do
        local ptr = readQword(dataModel + i)
        if ptr then
            local childrenStart = readQword(ptr)
            local childrenEnd = readQword(ptr + 8)
            if childrenStart and childrenEnd then
                if childrenEnd > childrenStart and childrenEnd - childrenStart > 1 and childrenEnd - childrenStart < 0x1000 then
                    childrenOffset = i
                    break
                end
            end
        end
    end
    hideCe()

    local localPlayerOffset = 0
    for i = 0x10,0x600,4 do
        local ptr = readQword(players + i)
        if readQword(ptr + parentOffset) == players then
            localPlayerOffset = i
            break
        end
    end
    hideCe()

    injectScript = nil
    local results = util.aobScan(util.Patterns.Inject)
    for rn = 1,#results do
        local result = results[rn];
        local bres = util.intToBytes(result);
        local aobs = ""
        for i = 1,8 do
            aobs = aobs .. string.format("%02X", bres[i])
        end

        local first = false
        local res = util.aobScan(aobs)
        if res then
            valid = false
            for i = 1,#res do
                result = res[i]

                if (readQword(result - nameOffset + 8) == result - nameOffset) then
                    injectScript = result - nameOffset
                    valid = true
                    break
                end
            end
        end

        if valid then break end
    end
    hideCe()

    if not injectScript then error("Join thru vulkan tp, yk, right?") end


    local rapi = {}
    rapi.toInstance = function(a, b)
        local address = a == rapi and b or a
        return setmetatable({}, {
            __index = function(self, name)
                if name == "self" or name == "adress" or name == "Adress" then
                    return address
                elseif name == "Name" then
                    local ptr = readQword(self.self + nameOffset)
                    if ptr then
                        local fl = readQword(ptr + 0x18)
                        if fl == 0x1F then
                            ptr = readQword(ptr)
                        end
    
                        if readString(readQword(ptr)) then
                            return readString(readQword(ptr))
                        end
    
                        return readString(ptr)
                    else
                        return "???"
                    end
                elseif name == "JobId" then
                    if self.self == dataModel then
                        return readString(readQword(dataModel + jobIdOffset))
                    end
    
                    return self:findFirstChild(name)
                elseif name == "className" or name == "ClassName" then
                    local ptr = readQword(self.self + 0x18) or 0
                    ptr = readQword(ptr + 0x8)
                    if ptr then
                        local fl = readQword(ptr + 0x18)
                        if fl == 0x1F then
                            ptr = readQword(ptr)
                        end
                        return readString(ptr)
                    else
                        return "???"
                    end
                elseif name == "Parent" then
                    return rapi.toInstance(readQword(self.self + parentOffset))
                elseif name == "getChildren" or name == "GetChildren" then
                    return function(self)
                        local instances = {}
                        local ptr = readQword(self.self + childrenOffset)
                        if ptr then
                            local childrenStart = readQword(ptr + 0)
                            local childrenEnd = readQword(ptr + 8)
                            local at = childrenStart
                            if not at or not childrenEnd then
                                return instances
                            end
                            while at < childrenEnd do
                                local child = readQword(at)
                                table.insert(instances, rapi.toInstance(child))
                                at = at + 16
                            end
                        end
                        return instances
                    end
                elseif (name == "getDescendants" or name == "GetDescendants") then
                    return function(self)
                        local descs = {}
                        local ut
                        function ut(i)
                            descs[#descs+1] = i
                            for _,v in pairs(i:getChildren()) do
                                descs[#descs+1] = v
                            end
                        end
                        for _,v in pairs(self:GetChildren()) do
                            ut(v)
                        end
                        return descs
                    end
                elseif name == "findFirstChild" or name == "FindFirstChild" then
                    return function(self, name, d, b)
                        local d = math.max(tonumber(d) or 1, 1)
                        local b = typeof(b) == "table" and b or {}
                        local de = 0
                        local fo = nil
                        local f
                        function f(i)
                            if de == d or de >= d then return fo end
                            for _,v in pairs(i:getChildren()) do
                                if v.Name == name and not b[v] and not table.find(b,v) then
                                    fo = fo or v
                                else
                                    for _,val in pairs(v:GetChildren()) do
                                        fo = fo or f(val)
                                    end
                                end
                            end
                            return fo
                        end
    
                        f(self)

                        return fo
                    end
                elseif name == "findFirstClass" or name == "FindFirstClass" or name == "FindFirstChildOfClass" or name == "findFirstChildOfClass" or name == "findFirstChildWhichIsA" or name == "FindFirstChildWhichIsA" then
                    return function(self, name, d, b)
                        local d = math.max(tonumber(d) or 1, 1)
                        local b = typeof(b) == "table" and b or {}
                        local de = 0
                        local fo = nil
                        local f
                        function f(i)
                            if de == d or de >= d then return fo end
                            for _,v in pairs(i:getChildren()) do
                                if v:IsA(name) and not b[v] and not table.find(b,v) then
                                    fo = fo or v
                                else
                                    for _,val in pairs(v:GetChildren()) do
                                        fo = fo or f(val)
                                    end
                                end
                            end
                            return fo
                        end
    
                        f(self)
                        
                        return fo
                    end
                elseif name == "waitForChild" or name == "WaitForChild" then
                    return function(self, name, timeout)
                        timeout = tonumber(timeout) or 9e9
                        local times = 0
                        local target = timeout/2
                        while times ~= target and times <= target do
                            if not self or not self.Name or self.Name == "???" then return end
                            local f = self[name]
                            if f then return f end
                            wait(0.5)
                        end
                    end
                elseif name == "setParent" or name == "SetParent" then
                    return function(self, other)
                        writeQword(self.self + parentOffset, other.self)
    
                        local newChildren = allocateMemory(0x400)
                        writeQword(newChildren + 0, newChildren + 0x40)

                        local ptr = readQword(other.self + childrenOffset)
                        local childrenStart = readQword(ptr + 0)
                        local childrenEnd = readQword(ptr + 8)

                        if not childrenEnd then
                            childrenEnd = 0
                        end
                        if not childrenStart then
                            childrenStart = 0
                        end

                        local b = readBytes(childrenStart, childrenEnd - childrenStart, true)
                        writeBytes(newChildren + 0x40, b)

                        local e = newChildren + 0x40 + (childrenEnd - childrenStart)
                        writeQword(e, self.self)
                        writeQword(e + 8, readQword(self.self + 0x10))
                        e = e + 0x10
    
                        writeQword(newChildren + 0x8, e)
                        writeQword(newChildren + 0x10, e)
                    end
                elseif name == "value" or name == "Value" then
                    if self.className == "StringValue" then
                        return readString(self.self + 0xC0)
                    elseif self.className == "BoolValue" then
                        return readByte(self.self + 0xC0) == 1
                    elseif self.className == "IntValue" then
                        return readInteger(self.self + 0xC0)
                    elseif self.className == "NumberValue" then
                        return readDouble(self.self + 0xC0)
                    elseif self.className == "ObjectValue" then
                        return rapi.toInstance(readQword(self.self + 0xC0))
                    elseif self.className == "Vector3Value" then
                        local x = readFloat(self.self + 0xC0)
                        local y = readFloat(self.self + 0xC4)
                        local z = readFloat(self.self + 0xC8)
                        return {
                            X = x,
                            Y = y,
                            Z = z
                        }
                    else
                        return self[name]
                    end
                elseif name == "Disabled" then
                    if self.className == "LocalScript" then
                        return readByte(self.self + 0x1EC) == 1
                    end
        
                    return self:findFirstChild(name)
                elseif name == "Enabled" then
                    if self.className == "LocalScript" then
                        return readByte(self.self + 0x1EC) == 0
                    end
        
                    return self:findFirstChild(name)
                elseif name == "DisplayName" then
                    if self.className == "Humanoid" then
                        return readString(self.self + 728)
                    end
        
                    return self:findFirstChild(name)
                elseif name == "LocalPlayer" or name == "localPlayer" then
                    return rapi.toInstance(readQword(players.self + localPlayerOffset))
                elseif name == "Character" then
                    return char or character
                elseif name == "GetService" or name == "getService" then
                    return function(self, name)
                        for i,v in pairs(self:GetChildren()) do
                            if v and v.ClassName:gsub(" ","") == name then
                                return v
                            end
                        end
                    end
                elseif name == "IsA" or name == "isA" then
                    return function(self, name)
                        return self.ClassName == name
                    end
                elseif name == "Locked" then
                    return readByte(self.self + 0x1BA) == 1
                else
                    return self:findFirstChild(name)
                end
            end,
            __newindex = function(self, name, value)
                hideCe()
                if name == "value" or name == "Value" then
                    if self.className == "StringValue" then
                        writeString(self.self + 0xC0, value)
                    elseif self.className == "BoolValue" then
                        writeByte(self.self + 0xC0, value and 1 or 0)
                    elseif self.className == "IntValue" then
                        writeInteger(self.self + 0xC0, value)
                    elseif self.className == "NumberValue" then
                        writeDouble(self.self + 0xC0, value)
                    elseif self.className == "ObjectValue" then
                        writeQword(self.self + 0xC0, value.self)
                    elseif self.className == "Vector3Value" then
                        writeFloat(self.self + 0xC0, value.X)
                        writeFloat(self.self + 0xC4, value.Y)
                        writeFloat(self.self + 0xC8, value.Z)
                    else
                        self:findFirstChild(name)
                    end
                elseif name == "Disabled" then
                    if self.className == "LocalScript" then
                        writeByte(self.self + 0x1EC, value and 1 or 0)
                    end
    
                    self:findFirstChild(name)
                elseif name == "Enabled" then
                    if self.className == "LocalScript" then
                        writeByte(self.self + 0x1EC, value and 0 or 1)
                    end
                elseif name == "DisplayName" then
                    if self.className == "Humanoid" then
                        writeString(self.self + 728, value)
                    end
                elseif name == "Locked" then
                    writeByte(self.self + 0x1BA, value and 1 or 0)
                elseif name == "Parent" then
                    self:setParent(value)
                elseif name == "Name" then
                    local ptr = readQword(self.self + nameOffset)
                    if ptr then
                        local fl = readQword(ptr + 0x18)
                        if fl == 0x1F then
                            ptr = readQword(ptr)
                        end
    
                        if readString(readQword(ptr)) then
                            writeString(readQword(ptr), value)
                        else
                            writeString(ptr, value)
                        end
                    end
                end
            end,
            __metatable = "The metatable is locked",
            __tostring = function(self)
                return self.Name
            end
        })
    end

    players = rapi.toInstance(players)
    game = rapi.toInstance(dataModel)
    localPlayer = rapi.toInstance(readQword(players.self + localPlayerOffset))
    plr = localPlayer
    workspace = game:GetService("Workspace")
    if not workspace then error("                    Failed to get workspace.") end
    localBackpack = localPlayer.Backpack or localPlayer:FindFirstClass("Backpack")
    hideCe()
    char = workspace:FindFirstChild(plr.Name, math.huge) or game.Workspace:FindFirstChild(plr.Name, math.huge)
    hideCe()
    character = char
    if not char then error("                    Failed to get character.") end

    injectScript = rapi.toInstance(injectScript)

    local iop

    local function INJECT(res)
        if not targetScript then error(res and "Failed to inject: "..res or "Failed to inject.") end

        hideCe()
        print("Yoo...")

        hideCe()
        local b = readBytes(injectScript.self + 0x100, 0x150, true)
        
        hideCe()
        writeBytes(targetScript.self + 0x100, b)

        hideCe()
        targetScript:SetParent(localPlayer.PlayerScripts)

        hideCe()
        print(iop and iop.."\10Before doing that, walk, jump for like that: just play for a bit." or "YOOOO!!!!")
    
        wait(5)
        os.exit()
    end

    hideCe()
    local function try()
        if util.InjectMethod == "Tool" then
            local V = false
            local function isToolValid(t)
                return t:FindFirstClass("LocalScript") and t:FindFirstClass("LocalScript").Enabled
            end
            for i,v in pairs(char:GetChildren()) do
                if v and v:IsA("Tool") and isToolValid(v) and not V then
                    V = true
                    targetScript = v:FindFirstClass("LocalScript")
                end
            end
            if V then
                iop = "Unequip the "..targetScript.Parent.Name.." pls"
            else
                for i,v in pairs(localBackpack:GetChildren()) do
                    if v and v:IsA("Tool") and isToolValid(v) and not V then
                        V = true
                        targetScript = v:FindFirstClass("LocalScript")
                    end
                end
                if V then
                    iop = "Equip the "..targetScript.Parent.Name.." pls"
                end
            end
            INJECT("Failed to get valid tools.")
        elseif util.InjectMethod == "Reset" then
            local f = false
            for i,v in pairs(char:GetChildren()) do
                if v and v:IsA("LocalScript") and v.Enabled and not f then
                    f = true
                    targetScript = v
                    iop = "Reset your character!!!"
                end
            end
            INJECT("Failed to get valid player script.")
        end
    end
    
    hideCe()
    if game:GetService("StarterGui"):FindFirstChild("CBScoreboard") then
		targetScript = localPlayer.PlayerGui:FindFirstChild("FreeCam2")
        iop = "u must be spectator i think to make it work."
        INJECT()
    else
        for i,v in pairs(util.InjectMethods) do
            local suc, e = pcall(try)
            if not suc then
                nextInjectMethod()
            else
                return
            end
        end
	end
    
    wait(2.5)
    os.exit()
end

local ver = httpGet("https://raw.githubusercontent.com/InfernusScripts/Vulkan/main/Version")
if ver then
    ver = ver:gsub("\10",""):gsub(" ",""):gsub("\13","")
elseif not ver or isEmptyString(ver) then
    ver = io.open("Version","r"):read("*a")
end

f = createForm()
f.Width = 500
f.Height = 30
f.Position = 'poScreenCenter'
f.Color = '0x232323'
f.BorderStyle = 'bsNone'
f.onMouseDown = f.dragNow

fTitle = createLabel(f)
fTitle.setPosition(10,5)
fTitle.Font.Color = '0xFFFFFF'
fTitle.Font.Size = 9
fTitle.Font.Name = 'Verdana'
fTitle.Caption = 'Vulkan'
fTitle.setPosition(10, 4)

fVer = createLabel(f)
fVer.Font.Color = '0xFFFFFF'
fVer.Font.Size = 6
fVer.Font.Name = 'Verdana'
fVer.Caption = ver
fVer.setPosition(10, 18)

fMode = createLabel(f)
fMode.Font.Color = '0xFFFFFF'
fMode.Font.Size = 8
fMode.Font.Name = 'Verdana'
fMode.Caption = "      LOL\10method:"
fMode.setPosition(470-125-10-50-10-55, 2)

img_BtnInject = createButton(f)
img_BtnInject.Caption = "LOL"
img_BtnInject.setSize(125,20)
img_BtnInject.setPosition(470-125-10,5)
img_BtnInject.onClick = function()
    local s,e = pcall(inject)
    if not s then
        print("Inject failed with a reason:\10"..e)
        print("Share the whole console with developers to get the help.\10If you encountering that error for the first time, try again 2 more times, because roblox and cheat engine is a dogshit.\10Closing cheat engine in 12.5 seconds!")
        wait(12.5)
        os.exit()
    else
        print("Enjoy!")
    end
end

img_BtnMode = createButton(f)
img_BtnMode.Caption = util.InjectMethod
img_BtnMode.setSize(50,20)
img_BtnMode.setPosition(470-125-10-50-10,5)
function nextInjectMethod()
    local curIdx = table.find(util.InjectMethods, util.InjectMethod)
    util.InjectMethod = util.InjectMethods[curIdx+1] or util.InjectMethods[1]

    img_BtnMode.Caption = util.InjectMethod
end
img_BtnMode.onClick = nextInjectMethod

img_BtnClose = createButton(f)
img_BtnClose.setSize(20,20)
img_BtnClose.setPosition(470,5)
img_BtnClose.Stretch = true
img_BtnClose.Caption = "X"
img_BtnClose.Cursor = -21
img_BtnClose.Anchors = '[akTop,akRight]'
img_BtnClose.onClick = function()
    print("You motherfu...\10EEHHHHH CLOSED MEEEEEEEEE *bug sounds*\10\10\10...")
    wait(0.1)
    os.exit()
end

print("Credits to the STA Team and Discover for helping with the fix :)")

local function randomString(l)
    local g = ""
    for i=1, tonumber(l) or 25 do
        g = g..string.char(math.random(33, 126))
    end
    return g
end

function hideCe()
    MainForm.Visible = false
    if MainForm.FromAddress then
        MainForm.FromAddress.Text = randomString(#MainForm.FromAddress.Text)
    end
    if MainForm.ToAddress then
        MainForm.ToAddress.Text = randomString(#MainForm.ToAddress.Text)
    end
end

hideCe()
