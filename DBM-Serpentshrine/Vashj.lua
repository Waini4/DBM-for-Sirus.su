﻿local mod	= DBM:NewMod("Vashj", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20201229013800")

mod:SetCreatureID(21212)
mod:RegisterCombat("combat", 21212)
mod:SetUsedIcons(7, 8)

mod:RegisterEventsInCombat(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"UNIT_DIED",
	"UNIT_TARGET",
	"UNIT_HEALTH",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_LOOT",
	"SWING_DAMAGE",
	"SPELL_SUMMON"
)

local warnCore           = mod:NewAnnounce("WarnCore", 3, 38132)
local warnCharge         = mod:NewTargetAnnounce(38280, 4)
local warnPhase          = mod:NewAnnounce("WarnPhase", 1)
local warnElemental      = mod:NewAnnounce("WarnElemental", 4)

local specWarnCore       = mod:NewSpecialWarningYou(38132)
local specWarnCharge     = mod:NewSpecialWarningRun(38280)

local timerStrider       = mod:NewTimer(66, "Strider", "Interface\\Icons\\INV_Misc_Fish_13", nil, nil, 1)
local timerElemental     = mod:NewTimer(53, "TaintedElemental", "Interface\\Icons\\Spell_Nature_ElementalShields", nil, nil, 1)
local timerNaga          = mod:NewTimer(47.5, "Naga", "Interface\\Icons\\INV_Misc_MonsterHead_02", nil, nil, 1)
local timerCharge        = mod:NewTargetTimer(20, 38280, nil, nil, nil, 4)

--------------------------------Героик--------------------------------


local warnStaticAnger       	 = mod:NewTargetAnnounce(310636, 3) -- Статический заряд
local warnElemAnonce       		 = mod:NewSoonAnnounce(310635, 1) -- Скоро призыв элементалей хм
local warnStartElem     		 = mod:NewSpellAnnounce(310635, 1) -- Призыв элемов хм
local warnScat      		     = mod:NewSpellAnnounce(310657, 1) -- Призыв скатов хм
local warnPhase2Soon			 = mod:NewPrePhaseAnnounce(2)
local warnPhase3Soon		     = mod:NewPrePhaseAnnounce(3)
local warnPhase2     		 	 = mod:NewPhaseAnnounce(2)
local warnPhase3     	 		 = mod:NewPhaseAnnounce(3)

local specWarnStaticAnger  	 	 = mod:NewSpecialWarningMove(310636, nil, nil, nil, 4, 5) -- Статический заряд на игроке
local specWarnStaticAngerNear	 = mod:NewSpecialWarning("SpecWarnStaticAngerNear", 310636, nil, nil, 1, 2) -- Статический заряд около игрока
local yellStaticAnger			= mod:NewYell(310636)
local yellStaticAngerFade		= mod:NewShortFadesYell(310636)
local yellStaticAngerPhase2		= mod:NewYell(310659, nil, nil, nil, "YELL")
local yellStaticAngerPhase2Fade	= mod:NewShortFadesYell(310659, nil, nil, nil, "YELL")
local timerStaticAngerCD 	     = mod:NewCDTimer(15, 310636, nil, nil, nil, 3) -- Статический заряд
local timerStaticAnger     		 = mod:NewTargetTimer(8, 310636, nil, nil, nil,3) -- Статический заряд на игроке
local timerElemCD     			 = mod:NewCDTimer(60, 310635, nil, nil, nil, 1) -- Элементали


mod:AddBoolOption("Elem")
mod:AddSetIconOption("SetIconOnStaticTargets", 310636, true, true, {7, 8})
mod:AddBoolOption("AnnounceStatic", false)

local ti = true
local warned_elem = false
local warned_preP1 = false
local warned_preP2 = false
local warned_preP3 = false
local warned_preP4 = false
local StaticTargets = {}
local StaticIcons = 8

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:StaticAngerIcons() -- метки и анонс целей статического заряда
		if DBM:GetRaidRank() >= 0 then
			table.sort(StaticTargets, sort_by_group)
			for i, v in ipairs(StaticTargets) do
				if mod.Options.AnnounceStatic then
					if DBM:GetRaidRank() > 0 then
						SendChatMessage(L.StaticIcon:format(StaticIcons, UnitName(v)), "RAID_WARNING")
					else
						SendChatMessage(L.StaticIcon:format(StaticIcons, UnitName(v)), "RAID")
					end
				end
				if self.Options.SetIconOnStaticTargets then
					self:SetIcon(UnitName(v), StaticIcons, 8)
				end
				StaticIcons = StaticIcons - 1
			end
			warnStaticAnger:Show(table.concat(StaticTargets, "<, >"))
			if self.vb.phase == 3 then
				timerStaticAngerCD:Start(30)
			else
				timerStaticAngerCD:Start()
			end
			table.wipe(StaticTargets)
			StaticIcons = 8
		end
	end
end

function mod:NextStrider()
	timerStrider:Start()
	self:UnscheduleMethod("NextStrider")
	self:ScheduleMethod(66, "NextStrider")
end

function mod:NextNaga()
	timerNaga:Start()
	self:UnscheduleMethod("NextNaga")
	self:ScheduleMethod(47.5, "NextNaga")
end

function mod:NextElem()
	timerElemCD:Start()
	self:ScheduleMethod(50, "NextElemAnonce")
end

function mod:NextElemAnonce()
	warnElemAnonce:Show()
	warned_elem = false
end

function mod:ElementalSoon()
	ti = true
	warnElemental:Show()
end

function mod:SWING_DAMAGE(args)
	if args:GetDestCreatureID() == 22009  and args:IsSrcTypePlayer() then
		if args.sourceName ~= UnitName("player") then
			if self.Options.Elem then
				DBM.Arrow:ShowRunTo(args.sourceName, 0, 0)
			end
		end
	end
end

function mod:TaintedIcon()
	if DBM:GetRaidRank() >= 1 then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid"..i.."target") == L.TaintedElemental then
				ti = false
				SetRaidTarget("raid"..i.."target", 8)
				break
			end
		end
	end
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 21212, "Lady Vashj")
	ti = true
	self:SetStage(1)
	if mod:IsDifficulty("heroic25") then
		DBM.RangeCheck:Show(20)
		timerElemCD:Start(10)
		timerStaticAngerCD:Start()
	else -- Обычка
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 21212, "Lady Vashj", wipe)
	warned_elem = false
	warned_preP1 = false
	warned_preP2 = false
	warned_preP3 = false
	warned_preP4 = false
	DBM.RangeCheck:Hide()
end



function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 38132 then
		warnCore:Show(args.destName)
		if args:IsPlayer() then
			specWarnCore:Show()
		end
	elseif spellId == 310636 then -- хм заряд
		if args:IsPlayer() then
			specWarnStaticAnger:Show()
			yellStaticAnger:Yell()
			yellStaticAngerFade:Countdown(spellId)
		else
			local uId = DBM:GetRaidUnitId(args.destName)
			if uId and self.vb.phase == 1 then
				local inRange = CheckInteractDistance(uId, 3)
				local x, y = GetPlayerMapPosition(uId)
				if x == 0 and y == 0 then
					SetMapToCurrentZone()
					x, y = GetPlayerMapPosition(uId)
				end
				if inRange then
					specWarnStaticAngerNear:Show()
				end
			end
		end
		timerStaticAnger:Start(args.destName)
		StaticTargets[#StaticTargets + 1] = args.destName
		self:UnscheduleMethod("StaticAngerIcons")
		self:ScheduleMethod(0.1, "StaticAngerIcons")
	elseif spellId == 310659 then -- хм заряд
		if args:IsPlayer() then
			specWarnStaticAnger:Show()
			yellStaticAngerPhase2:Yell()
			yellStaticAngerPhase2Fade:Countdown(spellId)
		else
			local uId = DBM:GetRaidUnitId(args.destName)
			if uId and self.vb.phase == 1 then
				local inRange = CheckInteractDistance(uId, 3)
				local x, y = GetPlayerMapPosition(uId)
				if x == 0 and y == 0 then
					SetMapToCurrentZone()
					x, y = GetPlayerMapPosition(uId)
				end
				if inRange then
					specWarnStaticAngerNear:Show()
				end
			end
		end
		timerStaticAnger:Start(args.destName)
		StaticTargets[#StaticTargets + 1] = args.destName
		self:UnscheduleMethod("StaticAngerIcons")
		self:ScheduleMethod(0.1, "StaticAngerIcons")
	end
end

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 310635 and warned_elem == false then
		warnStartElem:Show()
		self:ScheduleMethod(0, "NextElem")
		warned_elem = true
	elseif spellId == 310657 then
		warnScat:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 310636 or spellId == 310659 then
		if self.Options.SetIconOnStaticTargets then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 38280 then
		warnCharge:Show(args.destName)
		timerCharge:Start(args.destName)
		if args:IsPlayer() then
			specWarnCharge:Show()
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPhase2 then
		warnPhase:Show(2)
		timerStrider:Start()
		timerElemental:Start()
		timerNaga:Start()
		self:ScheduleMethod(66, "NextStrider")
		self:ScheduleMethod(47.5, "NextNaga")
		self:ScheduleMethod(48, "ElementalSoon")
	elseif msg == L.YellPhase3 then
		warnPhase:Show(3)
		timerStrider:Cancel()
		timerElemental:Cancel()
		timerNaga:Cancel()
		self:UnscheduleMethod("NextStrider")
		self:UnscheduleMethod("NextNaga")
	end
end

function mod:UNIT_DIED(args)
	if args.destName == L.TaintedElemental then
		timerElemental:Start()
		self:ScheduleMethod(48, "ElementalSoon")
	end
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 21212 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.72 then
		warned_preP1 = true
		warnPhase2Soon:Show()
	end
	if self.vb.phase == 1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 21212 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.70 then
		warned_preP2 = true
		self:SetStage(2)
		warnPhase2:Show()
	end
	if mod:IsDifficulty("heroic25") then
		if self.vb.phase == 2 and not warned_preP3 and self:GetUnitCreatureId(uId) == 21212 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.42 then
			warned_preP3 = true
			warnPhase3Soon:Show()
		end
		if self.vb.phase == 2 and not warned_preP4 and self:GetUnitCreatureId(uId) == 21212 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.40 then
			warned_preP4 = true
			self:SetStage(3)
			warnPhase3:Show()
			timerElemCD:Cancel()
		end
	else
		if self.vb.phase == 2 and not warned_preP4 and self:GetUnitCreatureId(uId) == 21212 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.50 then
			warned_preP4 = true
			self:SetStage(3)
			warnPhase3:Show()
		end
	end
end

function mod:UNIT_TARGET()
	if ti then
		self:TaintedIcon()
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 21212, "Lady Vashj", wipe)
	self:UnscheduleMethod("NextStrider")
	self:UnscheduleMethod("NextNaga")
	self:UnscheduleMethod("ElementalSoon")
	DBM.RangeCheck:Hide()
end
