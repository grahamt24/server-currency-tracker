-- including and setting up necessary external libraries
SCT = LibStub("AceAddon-3.0"):NewAddon("SCT", "AceConsole-3.0", "AceEvent-3.0")
local icon = LibStub("LibDBIcon-1.0")
local LibQTip = LibStub("LibQTip-1.0")
local sctLDB = LibStub("LibDataBroker-1.1"):NewDataObject("SCT", {
    type = "data source",
    label = "ServerCurrecyTracker",
    tocname = "ServerCurrecyTracker",
    icon = "Interface\\Icons\\INV_Misc_Coin_02",
})
local defaults = {
    profile = {
        minimap = {
            hide = false,
        },
    },
}

-- get constant globals
local realmName = GetRealmName()
local characterName = UnitName("player")
local localizedClass, characterClass, classIndex = UnitClass("player")
local tooltip, frame
local nameAndClass = characterName .. " - " .. characterClass
local classColors = {
    ["WARRIOR"] = {["r"] = .78, ["g"] = .61, ["b"] = .43},
    ["PALADIN"] = {["r"] = .96, ["g"] = .55, ["b"] = .73},
    ["HUNTER"] = {["r"] = .67, ["g"] = .83, ["b"] = .45},
    ["ROGUE"] = {["r"] = 1, ["g"] = .96, ["b"] = .41},
    ["PRIEST"] = {["r"] = 1, ["g"] = 1, ["b"] = 1},
    ["DEATHKNIGHT"] = {["r"] = .77, ["g"] = .12, ["b"] = .23},
    ["SHAMAN"] = {["r"] = 0, ["g"] = 0.44, ["b"] = 0.87},
    ["MAGE"] = {["r"] = .41, ["g"] = .8, ["b"] = .94},
    ["WARLOCK"] = {["r"] = .58, ["g"] = .51, ["b"] = .79},
    ["MONK"] = {["r"] = 0, ["g"] = 1, ["b"] = .59},
    ["DRUID"] = {["r"] = 1, ["g"] = .49, ["b"] = .04},
    ["DEMONHUNTER"] = {["r"] = .64, ["g"] = .19, ["b"] = .79},
}

-- On Enable function for Ace3.0
function SCT:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterEvent("PLAYER_TRADE_MONEY")
    self:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
end

-- set up everything needed to work
function SCT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SCTDB", defaults)
    self.db:RegisterDefaults(defaults)
    icon:Register("ServerCurrencyTracker", sctLDB, self.db.profile.minimap)
    SCT:Initialize()
    SCT:RegisterChatCommand("sct", "SlashProcessing")
end

-- process the slash command. Only supports 1 command but once additional currencies are supported it will support more
function SCT:SlashProcessing(input)
    SCT:DisplayGold()
    --[[if input == "" then
        SCT:Print("Server Currency Tracker commands include: " .. 
        "\n/sct gold - Show spent, earned, loss or gain (if applicable), and total gold for the server." ..
        "\nMore commands to be implemented soon!")
    elseif input == "gold" then
        SCT:DisplayGold()
    end]]--
end

-- handle PLAYER_ENTERING_WORLD event
function SCT:PLAYER_ENTERING_WORLD()
    SCT:GetInfo()
end

-- handle PLAYER_MONEY event
function SCT:PLAYER_MONEY()
    SCT:UpdateGold()
end

-- handle PLAYER_TRADE_MONEY event
function SCT:PLAYER_TRADE_MONEY()
    SCT:UpdateGold()
end

-- handle SEND_MAIL_MONEY_CHANGED event
function SCT:SEND_MAIL_MONEY_CHANGED()
    SCT:UpdateGold()
end

-- handle PLAYER_LOGOUT event
function SCT:PLAYER_LOGOUT()
    -- store and update necessary values
    self.db.realm[nameAndClass] = currentGold
    self.db.realm.gold = self.db.realm.gold + totalSpentGold
    self.db.realm.gold = self.db.realm.gold + totalEarnedGold
end

-- initialize the realm gold to be 0 if it's nil
function SCT:Initialize()
    if self.db.realm.gold == nil then
        self.db.realm.gold = 0
    end
end

-- get the current gold count for the player and store it in the saved variable
function SCT:GetInfo()
    currentGold = GetMoney()
    if self.db.realm[nameAndClass] == nil then
        self.db.realm[nameAndClass] = currentGold
        self.db.realm.gold = self.db.realm.gold + currentGold
    end
    totalSpentGold = 0
    totalEarnedGold = 0
end

-- Update the gold for the character
function SCT:UpdateGold()
    local transactionGold = GetMoney()
    local spentGold = 0
    local earnedGold = 0
    goldDiff = transactionGold - currentGold
    if goldDiff < 0 then
        spentGold = goldDiff
        totalSpentGold = totalSpentGold + goldDiff
    else
        earnedGold = goldDiff
        totalEarnedGold = totalEarnedGold + goldDiff
    end
    currentGold = transactionGold
    self.db.realm[nameAndClass] = currentGold
    self.db.realm.gold = self.db.realm.gold + spentGold
    self.db.realm.gold = self.db.realm.gold + earnedGold
end

-- Display the gold upon /sct
function SCT:DisplayGold()
    SCT:Print("You have earned " .. SCT:FormatGold(totalEarnedGold))
    SCT:Print("You have spent " .. SCT:FormatGold(totalSpentGold))
    local change = totalSpentGold + totalEarnedGold
    if change < 0 then
        SCT:Print("Session Loss: " .. SCT:FormatGold(change))
    elseif change > 0 then
        SCT:Print("Session Gain: " .. SCT:FormatGold(change))
    end
    SCT:Print("Total Gold on " .. realmName .. ": " .. SCT:FormatGold(self.db.realm.gold))
    for k,v in pairs(self.db.realm) do
        if k ~= "gold" then
            local name, dash, class = strsplit(" ", k)
            SCT:Print(name .. ": " .. SCT:FormatGold(v))
        end
    end
end

-- format gold to show amount for each type (gold, silver, copper) and their respective icon
function SCT:FormatGold(money)
    if money < 0 then
        money = abs(money)
    end
    local gold = floor(money / 100 / 100)
    local silver = floor(money / 100 % 100)
    local copper = floor(money % 100 % 100)
    local moneyString = format(GOLD_AMOUNT_TEXTURE .. " " .. SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
    return moneyString
end

local showingTT = false

-- Shows the tooltip for the minimap icon
function SCT:ShowTooltip()
    if showingTT == true then return end
    showingTT = true

    if LibQTip:IsAcquired("SCTTooltip") and tooltip then
        if tooltip:IsVisible() then
            showingTT = false
            return
        end
        tooltip:Clear()
    else
        tooltip = LibQTip:Acquire("SCTTracker", 9, "LEFT","CENTER","CENTER","CENTER","CENTER","CENTER","RIGHT","CENTER")
    end
    
    local line = tooltip:AddLine()
    tooltip:SetCell(line,1,"Shift Left Click the icon to reset data then ReloadUI to update.")
    tooltip:SetCellTextColor(line,1,.75,.75,.75)
    
    local newHeaderFont = CreateFont("NewFont")
    newHeaderFont:CopyFontObject("GameFontNormalLarge")
    newHeaderFont:SetFont("Fonts\\Default.TTF", 16)
    newHeaderFont:SetTextColor(1,.84,0)
    
    tooltip:SetHeaderFont(newHeaderFont)
    tooltip:AddHeader("Session")
    
    line = tooltip:AddLine()
    tooltip:SetCell(line,1,"Earned:")
    tooltip:SetCell(line,7,SCT:FormatGold(totalEarnedGold),nil, "RIGHT")
    
    line = tooltip:AddLine()
    tooltip:SetCell(line,1,"Spent:",nil)
    tooltip:SetCell(line,7,SCT:FormatGold(totalSpentGold),nil, "RIGHT")
    
    line = tooltip:AddLine()
    local change = totalSpentGold + totalEarnedGold
    if change < 0 then
        tooltip:SetCell(line,1,"Session Loss:")
        tooltip:SetCell(line,7,SCT:FormatGold(change))
    elseif change > 0 then
        tooltip:SetCell(line,1,"Session Gain:")
        tooltip:SetCell(line,7,SCT:FormatGold(change))
    end

    for i=0,5 do
        tooltip:AddLine()
    end

    tooltip:AddHeader("Character",nil,nil,nil,nil,nil,"Gold")

    for k,v in pairs(self.db.realm) do
        if k ~= "gold" then
            local name, dash, class = strsplit(" ", k)
            local r,g,b
            line = tooltip:AddLine()
            tooltip:SetCell(line,1,name,nil,"LEFT")
            for k,v in pairs(classColors) do
                for k2,v2 in pairs(v) do
                    if k2 == "r" and k == class then
                        r = v2
                    elseif k2 == "g" and k == class then
                        g = v2
                    elseif k2 == "b" and k == class then
                        b = v2
                    end
                end
            end
            tooltip:SetCellTextColor(line,1,r,g,b)
            tooltip:SetCell(line,7,SCT:FormatGold(v),"RIGHT")
        end
    end

    for i=0,5 do
        tooltip:AddLine()
    end

    tooltip:AddHeader(realmName)
    line = tooltip:AddLine()
    tooltip:SetCell(line,1,"Total gold:")
    tooltip:SetCell(line,7,SCT:FormatGold(self.db.realm.gold))

    for i=0,5 do
        tooltip:AddLine()
    end

    tooltip:SmartAnchorTo(frame)

    tooltip:Show()

    showingTT = false
end

-- for displaying the tooltip
function sctLDB.OnEnter(self)
    frame = self
    SCT:ShowTooltip()
end

-- for hiding the tooltip
function sctLDB.OnLeave(self)
    -- Release the tooltip
    LibQTip:Release(tooltip)
    tooltip = nil
end

-- for clicking on the minimap icon
function sctLDB.OnClick(self)
    if IsShiftKeyDown() then
        SCTDB = {}
    end
end