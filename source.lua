local robloxNames = {
    "RobloxPlayerBeta",
    "Windows10Universal"
}

print("Loading...\10")

--

local print = function(...)
    local args = table.pack(...)
    args[#args] = (tostring(args[#args])).."\10"
    print(table.unpack(args))
    return true
end

local err = error
local function error(...)
    print(...,"\10")
    err()
end


local function failedInject(reason)
    error("\10\10Failed to Inject.\10Most likely, the game is not supported.\10"..(reason and "Reason: "..reason.."\10" or ""))
end

function checkFailed(obj,reason)
    if not obj then failedInject(reason) end
end

util = {}
util.allocateMemory = allocateMemory;
util.startThread = executeCode;
util.freeMemory = deAlloc;

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

util.stringToBytes = function(str)
    local result = {}
	for i = 1, #str do
		table.insert(result, string.byte(str, i))
	end
	return result
end

local strexecg = ''

loader = {}
loader.start = function(strexec, pid)
    local results = util.aobScan("62616E616E6173706C697473????????0C")
    for rn = 1,#results do
        local result = results[rn];

        local str = strexec
        local b = {}
        for i = 1, #str + 4 do
            if i <= string.len(str) then
                table.insert(b, str:byte(i,i))
            else
                table.insert(b, 0)
            end
        end

        table.insert(b, string.len(str))
        writeBytes(result, b)

        closeRemoteHandle(pid)
        strexegc = ""
    end

    return nil
end

function onOpenProcess(pid)
    if #strexecg == 0 then
        return
    end
    loader.start(strexecg, pid)
end

function beginInject()
    print("-----\10\10Injecting...\10Please, go away from your keyboard and wait until injected.\10\10-----")
    print("Selecting process...")
    for i,v in pairs(robloxNames) do
        OpenProcess(v)
    end
    print("To speed up the injection process, make graphics lower and disable the antiviruses (if you have them).")
end

function inject()
    beginInject()
    print("Please, wait...")
    local players, nameOffset, valid;
    local results = util.aobScan("506C6179657273??????????????????07000000000000000F")
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

    if not players then
        return print("Roblox not opened!")
    end

    print("Scanning (takes some time, please wait)...")

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
    rapi.toInstance = function(address)
        return setmetatable({},{
            __index = function(self, name)
                if (name == "self" or name == "Adress" or name == "adress") then
                    return address
                elseif (name == "Name" or name == "name") then
                    local ptr = readQword(self.self + nameOffset);
                    if ptr then
                        local fl = readQword(ptr + 0x18);
                        if fl == 0x1F then
                            ptr = readQword(ptr);
                        end
                        return readString(ptr);
                    else
                        return "???";
                    end
                elseif (name == "className" or name == "ClassName") then
                    local ptr = readQword(self.self + 0x18);
                    ptr = readQword(ptr + 0x8);
                    if ptr then
                        local fl = readQword(ptr + 0x18);
                        if fl == 0x1F then
                            ptr = readQword(ptr);
                        end
                        return readString(ptr);
                    else
                        return "???";
                    end
                elseif (name == "Parent" or name == "parent") then
                    return rapi.toInstance(readQword(self.self + parentOffset))
                elseif (name == "getChildren" or name == "GetChildren") then
                    return function(self)
                        local instances = {}
                        local ptr = readQword(self.self + childrenOffset)
                        if ptr then
                            local childrenStart = readQword(ptr + 0)
                            local childrenEnd = readQword(ptr + 8)
                            local at = childrenStart
                            if not at and not childrenEnd then return {} end
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
                elseif (name == "findFirstChild" or name == "FindFirstChild") then
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
                elseif (name == "findFirstClass" or name == "FindFirstClass") then
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
                elseif (name == "setParent" or name == "SetParent") then
                    return function(self, other)
                        writeQword(self.self + parentOffset, other.self)

                         local newChildren = util.allocateMemory(0x400)
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
                         local e = newChildren + 0x40 + (childrenEnd - childrenStart);
                         writeQword(e, self.self)
                         writeQword(e + 8, readQword(self.self + 0x10))
                         e = e + 0x10

                         writeQword(newChildren + 0x8, e)
                         writeQword(newChildren + 0x10, e)
                    end
                elseif (name == "isA" or name == "IsA") then
                    return function(self, class)
                        return self.ClassName == class
                    end
                else
                    return self:findFirstChild(name)
                end
            end,
            __metatable = "The metatable is locked"
        })
    end

    players = rapi.toInstance(players)
    game = rapi.toInstance(dataModel)

    checkFailed(game,"Failed to get datamodel");checkFailed(players,"Failed to get game.Players")

    print("Calculating offsets...")

    local localPlayerOffset = 0
    for i = 0x10,0x600,4 do
        local ptr = readQword(players.self + i)
        if readQword(ptr + parentOffset) == players.self then
            localPlayerOffset = i
            break
        end
    end

    injectScript = nil
    print("Getting inject script...")
    local results = util.aobScan("496E6A656374????????????????????06")
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

    checkFailed(injectScript,"Failed to get inject script.\10Did you join the game through vulkan teleporter?")
    injectScript = rapi.toInstance(injectScript)
    checkFailed(injectScript,"Failed to get inject script.\10Did you join the game through vulkan teleporter?")

    print("Got inject script!")
    print("Almost there, doing the final steps...")

    local localPlayer = rapi.toInstance(readQword(players.self + localPlayerOffset));
    local targetScript
    checkFailed(localPlayer,"Failed to get local player")
    local function doNormalInject()
        local tool,equippedTool
        local character = game.Workspace:FindFirstChild(localPlayer.Name,math.huge)
        local TOOL = function(a)
            if not a or not a:IsA("Tool") then return false end
            print("Checking tool "..a.Name.."...")
            local success = false
            if not tool and not targetScript and a and a:IsA("Tool") then
                local ts = a:FindFirstClass("LocalScript",math.huge)
                if ts then
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
            
            if not tool and not targetScript then
                print("Failed to get player tools.\10Trying to get global tools...")

                local blocked, fail = {}, false
                if not tool and not targetScript and localBackpack or character then
                    repeat
                        local tOOl = game:FindFirstClass("Tool",math.huge,blocked)
                        if not tOOl then fail = true break end
                        TOOL(tOOl)
                        if not tool and not targetScript then
                            table.insert(blocked,tOOl)
                        end
                    until fail or tool and targetScript
                end

                if not fail and tool and targetScript then
                    print("Found global tool!\10Reparenting to "..(localBackpack and "backpack" or character and "character").."...")
                    tool:SetParent(localBackpack or character)
                    equippedTool = localBackpack == nil 
                elseif fail then
                    checkFailed(nil,"Failed to get global tools.")
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
    end
    local inBladeBall = game.Workspace.Dead ~= nil and game.Workspace.Alive ~= nil
    if inBladeBall then
        local character = game.Workspace.Dead:FindFirstChild(localPlayer.Name) or game.Workspace.Alive:FindFirstChild(localPlayer.Name) or game.Workspace:FindFirstChild(localPlayer.Name)
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
        injectedOutput = "Injected!\10Equip/Re-equip ability "..targetScript.Name.." to show vulkan's UI.\10If you don't have any other abilities, then go to the game and it will show."
    else
        doNormalInject()
    end
    
    print("Injecting...")
    local b = readBytes(injectScript.self + 0x100, 0x150, true)
    writeBytes(targetScript.self + 0x100, b)
    print(injectedOutput or "Injected!")
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
fTitle.Font.Size = 11
fTitle.Font.Name = 'Verdana'
fTitle.Caption = 'Vulkan UWP'
fTitle.Anchors = '[akTop,akLeft]'

img_BtnMax = createButton(f)
img_BtnMax.Caption = "Inject"
img_BtnMax.setSize(125,20)
img_BtnMax.setPosition(470-125-10,5)
img_BtnMax.onClick = inject

img_BtnClose = createButton(f)
img_BtnClose.setSize(20,20)
img_BtnClose.setPosition(470,5)
img_BtnClose.Stretch = true
img_BtnClose.Caption = "X"
img_BtnClose.Cursor = -21
img_BtnClose.Anchors = '[akTop,akRight]'
img_BtnClose.onClick = function()
    f.Close()
end

print("Loaded!\10Don't select a process. Vulkan will do it for you!")
