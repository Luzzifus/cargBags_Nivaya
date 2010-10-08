local addon, ns = ...
local cargBags = ns.cargBags

cargBags_Nivaya = CreateFrame('Frame', 'cargBags_Nivaya', UIParent)
cargBags_Nivaya:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
cargBags_Nivaya:RegisterEvent("ADDON_LOADED")

local cbNivaya = cargBags:GetImplementation("Nivaya")
cbNivCatDropDown = CreateFrame("Frame", "cbNivCatDropDown", UIParent, "UIDropDownMenuTemplate")

---------------------------------------------
---------------------------------------------
local L = cBnivL
cB_Bags = {}
cB_BagHidden = {}
cB_CustomBags = {}
cB_ActiveCustomBags = {}

-- Those are default values only, change them ingame via "/cbniv":
local optDefaults = {
                    NewItems = true,
                    TradeGoods = true,
                    Armor = true,
                    CoolStuff = false,
                    Junk = true,
                    AmmoAlwaysHidden = false,
                    BankBlack = false,
                    scale = 0.8,
                    FilterBank = true,
                    CompressEmpty = true,
                    Unlocked = true,
                    SortBags = true,
                    SortBank = true,
                    }

-- Those are internal settings, don't touch them at all:
local defaults =    { 
                    showAmmo = false, 
                    }

local ItemSetCaption = (IsAddOnLoaded('ItemRack') and "ItemRack ") or (IsAddOnLoaded('Outfitter') and "Outfitter ") or "Item "
local bankOpenState = false

function cbNivaya:UpdateBags() for i = -2, 11 do cbNivaya:UpdateBag(i) end end
function cbNivaya:ShowBags(...) for i = 1, select("#", ...) do local bag = select(i, ...); if not cB_BagHidden[bag.name] then bag:Show() end end end
function cbNivaya:HideBags(...) for i = 1, select("#", ...) do select(i, ...):Hide() end end

local LoadDefaults = function()
	cBniv = cBniv or {}
	for k,v in pairs(defaults) do
		if(type(cBniv[k]) == 'nil') then cBniv[k] = v end
	end
    cBnivCfg = cBnivCfg or {}
	for k,v in pairs(optDefaults) do
		if(type(cBnivCfg[k]) == 'nil') then cBnivCfg[k] = v end
	end
end

function cargBags_Nivaya:ADDON_LOADED(event, addon)

	if (addon ~= 'cargBags_Nivaya') then return end
	self:UnregisterEvent(event)
    
    LoadDefaults()
    if cBnivCfg.optAmmoAlwaysHidden then cBniv.showAmmo = false end
    UIDropDownMenu_Initialize(cbNivCatDropDown, cbNivaya.CatDropDownInit, "MENU")
    
    cB_filterEnabled["Armor"] = cBnivCfg.Armor
    cB_filterEnabled["TradeGoods"] = cBnivCfg.TradeGoods
    cB_filterEnabled["Junk"] = cBnivCfg.Junk
    
    for _,v in pairs(cB_CustomBags) do
        table.insert(cB_ActiveCustomBags, v)
    end
    
    -----------------
    -- Frame Spawns
    -----------------

    local C = cbNivaya:GetContainerClass()

    -- bank bags
    cB_Bags.bankSets        = C:New("cBniv_BankSets")
    cB_Bags.bankArmor       = C:New("cBniv_BankArmor")
    cB_Bags.bankConsumables = C:New("cBniv_BankCons")
    cB_Bags.bankQuest       = C:New("cBniv_BankQuest")
    cB_Bags.bankTrade       = C:New("cBniv_BankTrade")
    cB_Bags.bank            = C:New("cBniv_Bank")

    cB_Bags.bankSets        :SetMultipleFilters(true, cB_Filters.fBank, cB_Filters.fBankFilter, cB_Filters.fItemSets)
    cB_Bags.bankArmor       :SetExtendedFilter(cB_Filters.fItemClass, "BankArmor")
    cB_Bags.bankConsumables :SetExtendedFilter(cB_Filters.fItemClass, "BankConsumables")
    cB_Bags.bankQuest       :SetExtendedFilter(cB_Filters.fItemClass, "BankQuest")
    cB_Bags.bankTrade       :SetExtendedFilter(cB_Filters.fItemClass, "BankTradeGoods")
    cB_Bags.bank            :SetMultipleFilters(true, cB_Filters.fBank, cB_Filters.fHideEmpty)

    -- inventory bags
    cB_Bags.key         = C:New("cBniv_Keyring")
    cB_Bags.bagSoul     = C:New("cBniv_Soulshards")
    cB_Bags.bagAmmo     = C:New("cBniv_Ammo")
    cB_Bags.bagItemSets = C:New("cBniv_ItemSets")
    cB_Bags.bagStuff    = C:New("cBniv_Stuff")
    for _,v in pairs(cB_ActiveCustomBags) do cB_Bags[v] = C:New(v); cB_filterEnabled[v] = true end
    cB_Bags.bagJunk     = C:New("cBniv_Junk")
    cB_Bags.bagNew      = C:New("cBniv_NewItems")
    cB_Bags.armor       = C:New("cBniv_Armor")
    cB_Bags.quest       = C:New("cBniv_Quest")
    cB_Bags.consumables = C:New("cBniv_Consumables")
    cB_Bags.tradegoods  = C:New("cBniv_TradeGoods")
    cB_Bags.main        = C:New("cBniv_Bag")

    cB_Bags.key         :SetExtendedFilter(cB_Filters.fItemClass, "Keyring")
    cB_Bags.bagSoul     :SetExtendedFilter(cB_Filters.fItemClass, "Soulshards")
    cB_Bags.bagAmmo     :SetExtendedFilter(cB_Filters.fItemClass, "Ammo")
    cB_Bags.bagItemSets :SetFilter(cB_Filters.fItemSets, true)
    cB_Bags.bagStuff    :SetExtendedFilter(cB_Filters.fItemClass, "Stuff")
    cB_Bags.bagJunk     :SetExtendedFilter(cB_Filters.fItemClass, "Junk")
    cB_Bags.bagNew      :SetFilter(cB_Filters.fNewItems, true)
    cB_Bags.armor       :SetExtendedFilter(cB_Filters.fItemClass, "Armor")
    cB_Bags.quest       :SetExtendedFilter(cB_Filters.fItemClass, "Quest")
    cB_Bags.consumables :SetExtendedFilter(cB_Filters.fItemClass, "Consumables")
    cB_Bags.tradegoods  :SetExtendedFilter(cB_Filters.fItemClass, "TradeGoods")
    cB_Bags.main        :SetMultipleFilters(true, cB_Filters.fBags, cB_Filters.fHideEmpty)
    for _,v in pairs(cB_ActiveCustomBags) do cB_Bags[v]:SetExtendedFilter(cB_Filters.fItemClass, v) end

    -----------------------------------------------
    -- Store the anchoring order:
    -- read: "tar" is anchored to "src" in the direction denoted by "dir".
    -----------------------------------------------
    local function CreateAnchorInfo(src, tar, dir)
        tar.AnchorTo = src
        tar.AnchorDir = dir
        if src then
            if not src.AnchorTargets then src.AnchorTargets = {} end
            src.AnchorTargets[tar] = true
        end
    end

    -- Main Anchors:
    CreateAnchorInfo(nil, cB_Bags.main, "Bottom")
    CreateAnchorInfo(nil, cB_Bags.bank, "Bottom")

    cB_Bags.main:SetPoint("BOTTOMRIGHT", -20, 150)
    cB_Bags.bank:SetPoint("LEFT", 15, 0)    
    
    -- Bank Anchors:
    CreateAnchorInfo(cB_Bags.bank, cB_Bags.bankArmor, "Right")
    CreateAnchorInfo(cB_Bags.bankArmor, cB_Bags.bankSets, "Bottom")
    CreateAnchorInfo(cB_Bags.bankSets, cB_Bags.bankTrade, "Bottom")
    
    CreateAnchorInfo(cB_Bags.bank, cB_Bags.bankConsumables, "Bottom")
    CreateAnchorInfo(cB_Bags.bankConsumables, cB_Bags.bankQuest, "Bottom")
    
    -- Bag Anchors:
    CreateAnchorInfo(cB_Bags.main, cB_Bags.key, "Bottom")

    CreateAnchorInfo(cB_Bags.main, cB_Bags.bagItemSets, "Left")
    CreateAnchorInfo(cB_Bags.bagItemSets, cB_Bags.armor, "Top")
    CreateAnchorInfo(cB_Bags.armor, cB_Bags.bagJunk, "Top")
    CreateAnchorInfo(cB_Bags.bagJunk, cB_Bags.bagNew, "Top")
    CreateAnchorInfo(cB_Bags.bagNew, cB_Bags.bagSoul, "Top")
    CreateAnchorInfo(cB_Bags.bagSoul, cB_Bags.bagAmmo, "Top")

    CreateAnchorInfo(cB_Bags.main, cB_Bags.tradegoods, "Top")
    CreateAnchorInfo(cB_Bags.tradegoods, cB_Bags.consumables, "Top")
    CreateAnchorInfo(cB_Bags.consumables, cB_Bags.quest, "Top")
    CreateAnchorInfo(cB_Bags.quest, cB_Bags.bagStuff, "Top")
    
    local ref = 0
    for _,v in pairs(cB_ActiveCustomBags) do
        if ref == 0 then ref = cB_Bags.bagStuff end
        CreateAnchorInfo(ref, cB_Bags[v], "Top")
        ref = cB_Bags[v]
    end
    
    cbNivaya:UpdateAnchors(self)
    cbNivaya:Init()
end

function cbNivaya:UpdateAnchors(self)
    if not self.AnchorTargets then return end
    for v,_ in pairs(self.AnchorTargets) do
        local t, u = v.AnchorTo, v.AnchorDir
        if t then
            local h = cB_BagHidden[t.name]
            v:ClearAllPoints()
            if      not h   and u == "Top"      then v:SetPoint("BOTTOM", t, "TOP", 0, 15)
            elseif  h       and u == "Top"      then v:SetPoint("BOTTOM", t, "BOTTOM")
            elseif  not h   and u == "Bottom"   then v:SetPoint("TOP", t, "BOTTOM", 0, -15)
            elseif  h       and u == "Bottom"   then v:SetPoint("TOP", t, "TOP")
            elseif u == "Left" then v:SetPoint("BOTTOMRIGHT", t, "BOTTOMLEFT", -15, 0)
            elseif u == "Right" then v:SetPoint("TOPLEFT", t, "TOPRIGHT", 15, 0) end
        end
    end
end

function cbNivaya:OnOpen()
    cB_Bags.main:Show()
    cbNivaya:ShowBags(cB_Bags.armor, cB_Bags.bagNew, cB_Bags.bagItemSets, cB_Bags.quest, cB_Bags.consumables, 
                      cB_Bags.tradegoods, cB_Bags.bagStuff, cB_Bags.bagJunk)
    if cBniv.showAmmo and not cBnivCfg.AmmoAlwaysHidden then cbNivaya:ShowBags(cB_Bags.bagSoul, cB_Bags.bagAmmo) end
    for _,v in pairs(cB_ActiveCustomBags) do cbNivaya:ShowBags(cB_Bags[v]) end
end

function cbNivaya:OnClose()
    cbNivaya:HideBags(cB_Bags.main, cB_Bags.armor, cB_Bags.bagNew, cB_Bags.bagItemSets, cB_Bags.quest, cB_Bags.consumables, 
                      cB_Bags.tradegoods, cB_Bags.bagStuff, cB_Bags.bagJunk, cB_Bags.key, cB_Bags.bagSoul, cB_Bags.bagAmmo)
    if cBnivCfg.AmmoAlwaysHidden then cBniv.showAmmo = false end
    for _,v in pairs(cB_ActiveCustomBags) do cbNivaya:HideBags(cB_Bags[v]) end
end

function cbNivaya:OnBankOpened() cB_Bags.bank:Show(); cbNivaya:ShowBags(cB_Bags.bankSets, cB_Bags.bankArmor, cB_Bags.bankQuest, cB_Bags.bankTrade, cB_Bags.bankConsumables) end
function cbNivaya:OnBankClosed() cbNivaya:HideBags(cB_Bags.bank, cB_Bags.bankSets, cB_Bags.bankArmor, cB_Bags.bankQuest, cB_Bags.bankTrade, cB_Bags.bankConsumables) end

local SetFrameMovable = function(f, v)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:RegisterForClicks("LeftButton", "RightButton")
    if v then 
        f:SetScript("OnMouseDown", function() 
            f:ClearAllPoints() 
            f:StartMoving() 
        end)
        f:SetScript("OnMouseUp",  f.StopMovingOrSizing)
    else
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
    end
end

function cbNivaya:CatDropDownInit()
    level = 1
    local info = UIDropDownMenu_CreateInfo()
  
    local function AddInfoItem(type)
        local caption = "cBniv_"..type
        local t = L.bagCaptions[caption]
        info.text = t and t or type
        info.value = type
        info.func = function(self) cbNivaya:CatDropDownOnClick(self) end
        info.owner = self:GetParent()
        UIDropDownMenu_AddButton(info, level)
    end

    AddInfoItem("Armor")
    AddInfoItem("Consumables")
    AddInfoItem("Quest")
    AddInfoItem("TradeGoods")
    AddInfoItem("Stuff")
    AddInfoItem("ItemSets")
    AddInfoItem("Ammo")
    AddInfoItem("Junk")
    AddInfoItem("Bag")
    for _,v in pairs(cB_ActiveCustomBags) do AddInfoItem(v) end
end

function cbNivaya:CatDropDownOnClick(self)
    local value = self.value
    local itemName = cbNivCatDropDown.itemName
    local itemID = cbNivCatDropDown.itemID
    
    cBniv_CatInfo[itemName] = value
    if (itemID ~= nil) then cB_ItemClass[itemID] = nil end
    cbNivaya:UpdateBags()
end

local function StatusMsg(str1, str2, data, name, short)
    local R,G,t = '|cFFFF0000', '|cFF00FF00', ''
    if (data ~= nil) then t = data and G..(short and 'on|r' or 'enabled|r') or R..(short and 'off|r' or 'disabled|r') end
    t = (name and '|cFFFFFF00cargBags_Nivaya:|r ' or '')..str1..t..str2
    ChatFrame1:AddMessage(t)
end

local function StatusMsgVal(str1, str2, data, name)
    local G,t = '|cFF00FF00', ''
    if (data ~= nil) then t = G..data..'|r' end
    t = (name and '|cFFFFFF00cargBags_Nivaya:|r ' or '')..str1..t..str2
    ChatFrame1:AddMessage(t)
end

local function HandleSlash(str)
    local str, str2 = strsplit(" ", str, 2)
    if str == 'new' then
        cBnivCfg.NewItems = not cBnivCfg.NewItems
        StatusMsg('The "New Items" filter is now ', '.', cBnivCfg.NewItems, true, false)
    elseif str == 'trade' then
        cBnivCfg.TradeGoods = not cBnivCfg.TradeGoods
        cB_filterEnabled["TradeGoods"] = cBnivCfg.TradeGoods
        StatusMsg('The "Trade Goods" filter is now ', '.', cBnivCfg.TradeGoods, true, false)
    elseif str == 'armor' then
        cBnivCfg.Armor = not cBnivCfg.Armor
        cB_filterEnabled["Armor"] = cBnivCfg.Armor
        StatusMsg('The "Armor and Weapons" filter is now ', '.', cBnivCfg.Armor, true, false)
    elseif str == 'junk' then
        cBnivCfg.Junk = not cBnivCfg.Junk
        cB_filterEnabled["Junk"] = cBnivCfg.Junk
        StatusMsg('The "Junk" filter is now ', '.', cBnivCfg.Junk, true, false)
    elseif str == 'ammo' then
        cBnivCfg.AmmoAlwaysHidden = not cBnivCfg.AmmoAlwaysHidden
        StatusMsg('Hiding Ammo/Shard bags by default is now ', '.', cBnivCfg.AmmoAlwaysHidden, true, false)
    elseif str == 'bankbg' then
        cBnivCfg.BankBlack = not cBnivCfg.BankBlack
        StatusMsg('Black background color for the bank is now ', '. Reload your UI for this change to take effect!', cBnivCfg.BankBlack, true, false)
    elseif str == 'bankfilter' then
        cBnivCfg.FilterBank = not cBnivCfg.FilterBank
        StatusMsg('Bank filtering is now ', '. Reload your UI for this change to take effect!', cBnivCfg.FilterBank, true, false)
    elseif str == 'empty' then
        cBnivCfg.CompressEmpty = not cBnivCfg.CompressEmpty
        if cBnivCfg.CompressEmpty then 
            cB_Bags.bank.DropTarget:Show()
            cB_Bags.main.DropTarget:Show()
            cB_Bags.main.EmptySlotCounter:Show()
            cB_Bags.bank.EmptySlotCounter:Show()
        else
            cB_Bags.bank.DropTarget:Hide()
            cB_Bags.main.DropTarget:Hide()
            cB_Bags.main.EmptySlotCounter:Hide()
            cB_Bags.bank.EmptySlotCounter:Hide()
        end
        StatusMsg('Empty bagspace compression is now ', '.', cBnivCfg.CompressEmpty, true, false)
    elseif str == 'unlock' then
        cBnivCfg.Unlocked = not cBnivCfg.Unlocked
        SetFrameMovable(cB_Bags.main, cBnivCfg.Unlocked)
        SetFrameMovable(cB_Bags.bank, cBnivCfg.Unlocked)
        StatusMsg('Movable bags are now ', '.', cBnivCfg.Unlocked, true, false)
    elseif str == 'sortbags' then
        cBnivCfg.SortBags = not cBnivCfg.SortBags
        StatusMsg('Auto sorting bags is now ', '. Reload your UI for this change to take effect!', cBnivCfg.SortBags, true, false)
    elseif str == 'sortbank' then
        cBnivCfg.SortBank = not cBnivCfg.SortBank
        StatusMsg('Auto sorting bank is now ', '. Reload your UI for this change to take effect!', cBnivCfg.SortBank, true, false)
    elseif str == 'scale' then
        local t = tonumber(str2)
        if t then
            cBnivCfg.scale = t
            for _,v in pairs(cB_Bags) do v:SetScale(cBnivCfg.scale) end
            StatusMsgVal('Overall scale has been set to ', '.', cBnivCfg.scale, true)
        else
            StatusMsg('You have to specify a value, e.g. /cbniv scale 0.8.', '', nil, true, false)
        end
    elseif str == 'addbag' then
        local t = str2
        if t then
            local bagNum = -1
            for i,v in ipairs(cB_CustomBags) do if v == t then bagNum = i end end
            
            if bagNum == -1 then
                table.insert(cB_CustomBags, t)
                StatusMsg('The new custom bag has been created. Reload your UI for this change to take effect!', '', nil, true, false)
            else
                StatusMsg('A bag with this name already exists.', '', nil, true, false)
            end
        else
            StatusMsg('You have to specify a name, e.g. /cbniv addbag TestBag.', '', nil, true, false)
        end
    elseif str == 'delbag' then
        local t = str2
        if t then
            local bagNum = -1
            for i,v in ipairs(cB_CustomBags) do if v == t then bagNum = i end end
            
            if bagNum > -1 then
                table.remove(cB_CustomBags, bagNum)
                StatusMsg('The specified custom bag has been removed. Reload your UI for this change to take effect!', '', nil, true, false)
            else
                StatusMsg('There is no bag with this name.', '', nil, true, false)
            end
        else
            StatusMsg('You have to specify a name, e.g. /cbniv delbag TestBag.', '', nil, true, false)
        end
    elseif str == 'listbags' then
        local bagNum = -1
        for i,v in ipairs(cB_CustomBags) do bagNum = i end
        
        if bagNum == -1 then
            StatusMsgVal('There are ', ' custom containers.', 0, true, false)
        else
            StatusMsgVal('There are ', ' custom containers:', bagNum, true, false)
            for i,v in ipairs(cB_CustomBags) do StatusMsg(i..'. '..v, '', nil, true, false) end
        end
    else
        ChatFrame1:AddMessage('|cFFFFFF00cargBags_Nivaya:|r')
        StatusMsg('(', ') unlock - Toggle unlocked status.', cBnivCfg.Unlocked, false, true)
        StatusMsg('(', ') new - Toggle the "New Items" filter.', cBnivCfg.NewItems, false, true)
        StatusMsg('(', ') trade - Toggle the "Trade Goods" filter .', cBnivCfg.TradeGoods, false, true)
        StatusMsg('(', ') armor - Toggle the "Armor and Weapons" filter .', cBnivCfg.Armor, false, true)
        StatusMsg('(', ') junk - Toggle the "Junk" filter.', cBnivCfg.Junk, false, true)        
        StatusMsg('(', ') ammo - Toggle Hiding Ammo/Shard bags by default.', cBnivCfg.AmmoAlwaysHidden, false, true)
        StatusMsg('(', ') bankbg - Toggle black bank background color.', cBnivCfg.BankBlack, false, true)
        StatusMsg('(', ') bankfilter - Toggle bank filtering.', cBnivCfg.FilterBank, false, true)
        StatusMsg('(', ') empty - Toggle empty bagspace compression.', cBnivCfg.CompressEmpty, false, true)
        StatusMsg('(', ') sortbags - Toggle auto sorting the bags.', cBnivCfg.SortBags, false, true)
        StatusMsg('(', ') sortbank - Toggle auto sorting the bank.', cBnivCfg.SortBank, false, true)
        StatusMsgVal('(', ') scale [number] - Set the overall scale.', cBnivCfg.scale, false)
        StatusMsg('', ' addbag [name] - Add a custom container.')
        StatusMsg('', ' delbag [name] - Remove a custom container.')
        StatusMsg('', ' listbags - List all custom containers.')
    end
    cbNivaya:UpdateBags()
end

SLASH_CBNIV1 = '/cbniv'
SlashCmdList.CBNIV = HandleSlash