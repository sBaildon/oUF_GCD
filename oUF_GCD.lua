local _, ns = ...
local cfg = ns.cfg
local oUF = ns.oUF or oUF

--[[
oUF_GCD - Global Cooldown timer for oUF
by Exactly of Turalyon (us)


Example

	self.GCD = CreateFrame('Frame', nil, self)
	self.GCD:SetPoint('BOTTOMLEFT', self.Title, 'BOTTOMLEFT')
	self.GCD:SetPoint('BOTTOMRIGHT', self.Title, 'BOTTOMRIGHT')
	self.GCD:SetHeight(2)

	self.GCD.Spark = self.GCD:CreateTexture(nil, "OVERLAY")
	self.GCD.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.GCD.Spark:SetBlendMode("ADD")
	self.GCD.Spark:SetHeight(10)
	self.GCD.Spark:SetWidth(10)
	self.GCD.Spark:SetPoint('BOTTOMLEFT', self.Title, 'BOTTOMLEFT', -5, -5)

	self.GCD.ReferenceSpellName = '***SEE BELOW***'

You have to set a reference spell. You should choose one that has no cooldown
except the global cooldown, and that cant be interrupted or silenced -- and
it has to be one that's in your spellbook.

Alternatively, you can add spells to the "referenceSpells" block at the top of
this file and the addon will automatically choose the first one that you know. I'll add
more spells to the list as I figure out what they are. For now, you can just add more
spells to the list -- it doesnt matter where.

Enjoy!
--]]

local referenceSpells = {
	45462,			-- Death Knight
	1978,			-- Hunter
	589,			-- Priest
	85256,			-- Paladin
	686,			-- Warlock
	30449,			-- Mage
	140817,			-- Warrior
	403,			-- Shaman
	1752,			-- Rogue
	5176,			-- Druid
	100780,         	-- Monk
	162243,			-- Demon Hunter
}
local spellid
local GetTime = GetTime
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local GetSpellCooldown = GetSpellCooldown

local Init = function()
	local FindInSpellbook = function(spell)
		for tab = 1, 4 do
			local _, _, offset, numSpells = GetSpellTabInfo(tab)
			for i = (1+offset), (offset + numSpells) do
				local bspell = GetSpellInfo(i, BOOKTYPE_SPELL)
				if (bspell == spell) then
					return i
				end
			end
		end
		return nil
	end

	for _, lspell in pairs(referenceSpells) do
		local na = GetSpellInfo (lspell)
		local x = FindInSpellbook(na)
		if x ~= nil then
			spellid = lspell
			break
		end
	end

	if spellid == nil then
		-- XXX: print some error ..
		print ("Cant find spellid, oUF_GCD")
	end

	return spellid
end


local OnUpdateGCD
do
	OnUpdateGCD = function(self)
		self.Spark:ClearAllPoints()
		local perc = (GetTime() - self.starttime) / self.duration
		if perc > 1 then
			self:Hide()
			return
		else
			self.Spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * perc, 0)
		end
	end
end

local OnHideGCD = function(self)
	self:SetScript('OnUpdate', nil)
	self.drawing = false
end

local OnShowGCD = function(self)
	self:SetScript('OnUpdate', OnUpdateGCD)
end

local Update = function(self, event, unit)
	if self.GCD then
		if spellid == nil then
			if Init() == nil then
				return
			end
		end

		local start, dur = GetSpellCooldown(spellid)

		if (not start) then return end
		if (not dur) then dur = 0 end

		if (dur == 0) then
			self.GCD:Hide()
		else
			self.GCD.starttime = start
			self.GCD.duration = dur
			self.GCD:Show()
		end
	end
end

local Enable = function(self)
	if (self.GCD) then
		self.GCD:Hide()
		self.GCD.drawing = false
		self.GCD.starttime = 0
		self.GCD.duration = 0

		self:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN', Update)
		self.GCD:SetScript('OnHide', OnHideGCD)
		self.GCD:SetScript('OnShow', OnShowGCD)
	end
end

local Disable = function(self)
	if (self.GCD) then
		self:UnregisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
		self.GCD:Hide()
	end
end

oUF:AddElement('GCD', Update, Enable, Disable)
