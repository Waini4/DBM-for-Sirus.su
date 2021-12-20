local mod	= DBM:NewMod("VoidReaver", "DBM-TheEye", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210130153000")

mod:SetCreatureID(19516)
mod:RegisterCombat("combat")
mod:SetUsedIcons(3, 4, 5, 6, 7, 8)
mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_REMOVED",
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_START"
)

-----обычка-----
local timerNextPounding         = mod:NewCDTimer(14, 34162, nil, nil, nil, 1)
local timerNextKnockback        = mod:NewCDTimer(30, 25778, nil, "Healer", nil, 5, DBM_CORE_HEALER_ICON)
------героик------

local warnPhase1				= mod:NewAnnounce("Phase1", 2) -- Фаза пониженного урона
local warnPhase2				= mod:NewAnnounce("Phase2", 2) -- Фаза повышенного урона
--local warnKnockback				= mod:NewSoonAnnounce(308470, 2, nil, "Tank|Healer|RemoveEnrage")  -- тяжкий удар
local warnMagnet                = mod:NewTargetAnnounce(308467, 4) -- Сфера магнетизм
local warnSign                  = mod:NewTargetAnnounce(308471, 4) -- Знак

--local warnSpawnOrbs				= mod:NewAnnounce("SpawnOrbs", 2)
--local warnScope					= mod:NewSoonAnnounce(308984, 2, nil, "Tank|Healer|RemoveEnrage")  -- Сферы
--local warnBah					= mod:NewAnnounce("Bah", 2)  -- Сферы

local specWarnSign       = mod:NewSpecialWarningRun(308471, nil, nil, nil, 3, 4) -- Знак
local specWarnMagnet       = mod:NewSpecialWarningRun(308467, nil, nil, nil, 1, 4) -- Магнетизм
local yellSign			= mod:NewYell(308471, nil, nil, nil, "YELL")
local yellSignFades		= mod:NewShortFadesYell(308471, nil, nil, nil, "YELL")


local timerOrbCD				= mod:NewCDTimer(30, 308466, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON) -- Таймер чародейской сферы
local timerLoadCD				= mod:NewCDTimer(60, 308465, nil, nil, nil, 1, nil, DBM_CORE_ENRAGE_ICON) -- Таймер 1 фазы
local timerReloadCD				= mod:NewCDTimer(60, 308474, nil, nil, nil, 2, nil, DBM_CORE_DAMAGE_ICON) -- Таймер 2 фазы
local timerSignCD		       = mod:NewCDTimer(16, 308471, nil, nil, nil, 7) -- Знак


local berserkTimer				= mod:NewBerserkTimer(600)

mod:AddSetIconOption("SetIconOnSignTargets", 308471, true, true, {3, 4, 5, 6, 7, 8})
mod:AddBoolOption("AnnounceSign", false)
mod:AddBoolOption("RangeFrame", true)

local beaconIconTargets	= {}
local MagnetTargets = {}
local SignTargets = {}
local SignIcons = 8

mod.vb.phase = 0

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetSignIcons()
		table.sort(SignTargets, sort_by_group)
		if #SignTargets <= 6 then
			for i, v in ipairs(SignTargets) do
				if mod.Options.AnnounceSign then
					if DBM:GetRaidRank() > 0 then
						SendChatMessage(L.SignIcon:format(SignIcons, UnitName(v)), "RAID_WARNING")
					else
						SendChatMessage(L.SignIcon:format(SignIcons, UnitName(v)), "RAID")
					end
				end
				if self.Options.SetIconOnSignTargets then
					self:SetIcon(UnitName(v), SignIcons, 8)
				end
				SignIcons = SignIcons - 1
			end
		end
		warnSign:Show(table.concat(SignTargets, "<, >"))
		table.wipe(SignTargets)
		SignIcons = 8
	end
end

function mod:OnCombatStart(delay)
	table.wipe(beaconIconTargets)
	DBM:FireCustomEvent("DBM_EncounterStart", 19516, "Void Reaver")
	if mod:IsDifficulty("heroic25") then
	    timerLoadCD:Start()
	    timerOrbCD:Start()
		--timerKnockbackCD:Start()
		if self.Options.RangeFrame then
		DBM.RangeCheck:Show(15)
		end
	else
		berserkTimer:Start()
		timerNextPounding:Start()
		timerNextKnockback:Start()
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 19516, "Void Reaver", wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

----------------------об--------------------------------------

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 25778 then
		timerNextKnockback:Start()
	elseif spellId == 34162 then
		timerNextPounding:Start()
	end
end

-------------------------хм------------------------------------

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 308465 then --- 1 фаза
		timerLoadCD:Start()
		timerOrbCD:Start()
		warnPhase1:Schedule(0)
		timerOrbCD:Start(60)
	elseif args:IsSpellID(308473) then  --- 2 фаза
		timerReloadCD:Start()
		warnPhase2:Schedule(0)
	elseif spellId == 308471 then
		if args:IsPlayer() then
			specWarnSign:Show()
			yellSign:Yell()
			yellSignFades:Countdown(spellId)
		end
		SignTargets[#SignTargets + 1] = args.destName
		self:UnscheduleMethod("SetSignIcons")
		self:ScheduleMethod(0.1, "SetSignIcons")
		timerSignCD:Start()
	elseif spellId == 308467 then
		MagnetTargets[#MagnetTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnMagnet:Show()
		end
		timerOrbCD:Start()
		self:UnscheduleMethod("Magnet")
		self:ScheduleMethod(0.1, "Magnet")

	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 308471 then
		if self.Options.SetIconOnSignTargets then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:Magnet()
	warnMagnet:Show(table.concat(MagnetTargets, "<, >"))
	table.wipe(MagnetTargets)
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED