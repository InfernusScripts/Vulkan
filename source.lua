local util = {
    Patterns = {
        UWP = {
            Players = "506C6179657273??????????????????07000000000000000F";
            Inject = "496E6A656374????????????????????06";
        },
        WEB = {
            Players = "";
            Inject = "";
        },
    },

    RobloxNames = {
        "RobloxPlayerBeta",
        "Windows10Universal"
    },

    InjectMethod = "Reset",
    InjectMethods = {
        "Tool",
        "Reset"
    }
}

print("Loading...\10")

--

local injecting = false
local print = function(...)
    local args = table.pack(...)
    args[#args] = (tostring(args[#args])).."\10"
    print(table.unpack(args))
    return true
end

local isEmptyString = function(str)
    return str:gsub(" ",""):gsub("\10",""):gsub("\13","") == ""
end

local wait = function(time)
    return sleep(time*1000)
end

local err = error
local function error(...)
    print(...,"\10")
    err()
end


local function failedInject(reason)
    error("\10\10Failed to Inject.\10Most likely, the game is not supported.\10\10"..(reason and "Actual reason: "..reason.."\10" or ""))
end

function checkFailed(obj,reason)
    if not obj then failedInject(reason) end
end

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
    local t = { val & 0xFF }
    for i = 1,7 do
        table.insert(t, (val >> (8 * i)) & 0xFF)
    end
    return t
end

loader = {}

local rapi, typeof = {}, type
local t = table
local table = {}
for i,v in pairs(t) do
    table[i] = v
end
table.find = function(t,v)
    for idx,val in pairs(t) do
        if idx == v then
            return val, idx
        elseif val == v then
            return idx, val
        end
    end
    return nil
end

function beginInject()
    print("-----\10\10Beginning injecting..."--[[\10Please, go away from your keyboard and wait until injected.\10\10-----"]])
    print("Selecting process...")
    for i,v in pairs(util.RobloxNames) do
        OpenProcess(v)
    end
    print("To speed up the injection process, make graphics lower and disable the antiviruses (if you have them).")
end

function inject()
    if injecting then return end
    --injecting = true
    local UWP, WEB = true, true
    beginInject()
    print("Scanning (can take a while, please wait)...")
    print("READ IT PLEASE WHILE IT IS SCANNING!\10Read while injecting so it wont crash!")
    local players, nameOffset, valid;
    local function scan1(roblox)
        local pattern = util.Patterns[roblox].Players
        if not pattern or pattern:gsub("	",""):gsub(" ",""):gsub("\13",""):gsub("\10","") == "" then return end
        local results = util.aobScan(pattern)
        for rn = 1,#results do
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
                    result = res[i]
                    for j = 1,10 do
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
    end

    print("Checking if roblox is WEB\10(If WEB not found, that means that WEB is not supported)...")
    scan1("WEB")
    if not players then
        WEB = false
        
        print("Checking if roblox is UWP\10(If UWP not found, that means that UWP is not supported)...")
        scan1("UWP")
        if not players then
            UWP = false
        end
    end
    print("WEB: "..tostring(WEB).."\10UWP: "..tostring(UWP))

    if not UWP and not WEB then
        error("Roblox is not opened or the cheat is not updated by the developers!\10Please, try to use different type of roblox (if you're on WEB roblox, try to UWP, else try WEB)\10")
    end

    print("Roblox type:\10"..(UWP and "UWP" or "WEB"))

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

    print("Setting up API...")

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

    local localPlayerOffset

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
                    return workspace:FindFirstChild(game.Players.LocalPlayer.Name, math.huge)
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

    for i = 0x10,0x600,4 do
        local ptr = readQword(players.self + i)
        if readQword(ptr + parentOffset) == players.self then
            localPlayerOffset = i
            break
        end
    end

    game = rapi.toInstance(dataModel)
    checkFailed(game,"Failed to get datamodel")
    workspace = game:GetService("Workspace")
    localPlayer = players.LocalPlayer
    char = localPlayer.Character
    character = char

    injectScript = nil
    print("Getting inject script...")
    local results = util.aobScan(UWP and util.Patterns.UWP.Inject or util.Patterns.WEB.Inject)
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

    checkFailed(injectScript,"Failed to get inject script adress.\10Did you join the game through vulkan teleporter?")
    injectScript = rapi.toInstance(injectScript)
    checkFailed(injectScript,"Failed to get inject script instance.\10Did you join the game through vulkan teleporter?")

    print("Got inject script!")
    print("Almost there, doing the final steps...")
    local playerGui = localPlayer:FindFirstClass("PlayerGui") or localPlayer:FindFirstChild("PlayerGui")
    local playerScripts = localPlayer:FindFirstClass("PlayerScripts")
    local targetScript
    local injectedOutput
    local function INJECT(target, inject)
        local b = readBytes(inject.self + 0x100, 0x150, true)
        writeBytes(target.self + 0x100, b)
    end
    local function doNormalInject()
        if util.InjectMethod == "Tool" then
            local tool,equippedTool
            local TOOL = function(a)
                if not a or not a:IsA("Tool") then return false end
                print("Checking tool "..a.Name.."...")
                local success = false
                if not tool and not targetScript and a and a:IsA("Tool") then
                    local ts = a:FindFirstClass("LocalScript",math.huge)
                    if ts and ts.Enabled then
                        print(a.Name.." is valid tool!")
                        success = true
                        tool,targetScript = a,ts
                    end
                end
                return success
            end
            local inject = function()
                print("Doing normal inject.")
                local localBackpack = localPlayer:FindFirstChild("Backpack") or localPlayer:FindFirstClass("Backpack")
                checkFailed(localBackpack,"Failed to get player's backpack")
                for i,v in pairs(localBackpack:GetChildren()) do
                    if not tool and not targetScript then
                        TOOL(v)
                    end
                end
            end
            if character then
                print("Found character.")
                local suc = TOOL(character:FindFirstClass("Tool"))
                if suc then
                    equippedTool = true
                elseif not tool and not targetScript then
                    print("Failed to get character's equipped for direct tool Injecting.")
                    inject()
                end
            else
                print("Character not found.")
                inject()
            end    

            checkFailed(tool,"Failed to get player's tools.")
            checkFailed(targetScript,"Failed to get player's tools.")
            print("Got tool"..(equippedTool and " (in your hands)" or "")..":",tool.Name)
            injectedOutput = "Injected!\10"..(equippedTool and "Unequip" or "Equip").." "..tool.Name.." to show vulkan's UI."
        elseif util.InjectMethod == "Reset" then
            checkFailed(char,"Failed to get player")
            local ignore, fail = {}, false
            repeat
                targetScript = char:FindFirstChildOfClass("LocalScript", 1, ignore)
                if targetScript and targetScript.Enabled then
                    targetScript:SetParent(localPlayer.PlayerScripts)
                    INJECT(targetScript, injectScript)
                    print("Injected!\10Reset your character to show Vulkan's UI!")
                    break
                elseif targetScript and not targetScript.Enabled then
                    table.insert(ignore, targetScript)
                    targetScript = nil
                elseif not targetScript then
                    fail = true
                end
            until fail or targetScript
            if fail then
                error("Failed to get valid script for injecting.")
            end
            return true
        else
            error("Failed to inject:\10Unknown inject method!")
        end
    end
    if workspace.Dead ~= nil and workspace.Alive ~= nil and workspace.Balls ~= nil then
        print("GAME: Blade Ball")
        if not character then
            doNormalInject()
            return
        end
        local abilities = character:FindFirstChild("Abilities") or character:FindFirstChild("Ability")
        if not abilities then
            doNormalInject()
            return
        end
        targetScript = abilities:FindFirstClass("LocalScript")
        if not targetScript then
            doNormalInject()
            return
        end
        injectedOutput = "Injected!\10"..(targetScript.Enabled and "Re-equip" or "Equip").." ability "..targetScript.Name.." to show vulkan's UI.\10If you don't have any other abilities, then go to the game and it will show."
    elseif game:GetService("StarterGui"):FindFirstChild("CBScoreboard") then
        print("GAME: Counter Blox")
		targetScript = playerGui:FindFirstChild("FreeCam2")
        if not targetScript then
            doNormalInject()
            return
        end
        injectedOutput = "Injected!\10Go the the spectator team to show Vulkan's UI!"
    elseif game:GetService("ReplicatedStorage"):FindFirstChild("HiddenObjects") and game:GetService("ReplicatedStorage").HiddenObjects:FindFirstChild("Boundary") then
        print("GAME: Funky Friday (support soon)")
        if true then
            doNormalInject()
            return
        end
    else
        print("GAME: Other\10Inject method: "..util.InjectMethod)
        local success, res = false, nil
        for i=1, #util.InjectMethods do
            if success then break end
            success, res = pcall(doNormalInject)
            if not success then nextInjectMethod() end
        end
        if res then
            return
        end
    end
    
    print("Injecting...")
    INJECT(targetScript, injectScript)
    print(injectedOutput or "Injected!")
end

local i = getInternet('CEVersionCheck')
local ver = i.getURL("https://raw.githubusercontent.com/InfernusScripts/Vulkan/main/Version")
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
f.onMouseDown = DragIt

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
fMode.Caption = "   Inject\10method:"
fMode.setPosition(470-125-10-50-10-55, 2)

img_BtnInject = createButton(f)
img_BtnInject.Caption = "Inject"
img_BtnInject.setSize(125,20)
img_BtnInject.setPosition(470-125-10,5)
img_BtnInject.onClick = inject

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

print("Loaded!\10Don't select a process. Vulkan will do it for you!")
local isWEBEmpty, isUWPEmpty = false, false

isWEBEmpty = isEmptyString(util.Patterns.WEB.Players)
isUWPEmpty = isEmptyString(util.Patterns.UWP.Players)

if isWEBEmpty and isUWPEmpty then
    print("Uh oh!\10Vulkan is down currently!\10Reason: No patterns found!")
    wait(5)
    os.exit()
elseif isWEBEmpty or isUWPEmpty then
    print("Please make sure that you using Vulkan on "..(isWEBEmpty and "UWP" or "WEB").." roblox, or it will not work!")
end
