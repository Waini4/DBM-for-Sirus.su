local mod	= DBM:NewMod("Solarian", "DBM-TheEye", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210130153000")

mod:SetCreatureID(18805)
mod:RegisterCombat("yell", L.YellPull)
mod:SetUsedIcons(2, 6, 7, 8)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_TARGET",
	"SPELL_DISPEL",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SWING_DAMAGE"
)

--------------------------нормал--------------------------

local warnWrathN		= mod:NewTargetAnnounce(42783, 4)
local warnAddsSoon		= mod:NewAnnounce("WarnAddsSoon", 3, 55342)

local specWarnWrathN	= mod:NewSpecialWarningRun(42783, nil, nil, nil, 1, 2)

local timerAdds			= mod:NewTimer(60, "TimerAdds", 55342, "RemoveEnrage", nil, 5, nil, DBM_CORE_ENRAGE_ICON)
local timerPriestsN		= mod:NewTimer(14, "TimerPriests", 47788)
local timerWrathN		= mod:NewTargetTimer(6, 42783, nil, "RemoveEnrage", nil, 5, nil, DBM_CORE_ENRAGE_ICON, nil, 1, 5)
local timerNextWrathN	= mod:NewCDTimer(21, 42783, nil, "RemoveEnrage", nil, 5, nil, DBM_CORE_ENRAGE_ICON)

--------------------------героик--------------------------

local warnRing			= mod:NewSoonAnnounce(308563, 3) -- ослепляющее кольцо
local warnPhase2Soon   	= mod:NewPrePhaseAnnounce(2)
local warnPhase2     	= mod:NewPhaseAnnounce(2)
local warnKol    		= mod:NewTargetAnnounce(308563, 2) -- Кольцо
local warnFlashVoid		= mod:NewSoonAnnounce(308585, 3)

local specWarnHelp		= mod:NewSpecialWarningAdds(308559, nil, nil, nil, 1, 2)  -- Послушники
local specWarnDebaf  	= mod:NewSpecialWarningRun(308544, nil, nil, nil, 3, 4) -- Дебаф 1я фаза
local specWarnFlashVoid = mod:NewSpecialWarningLookAway(308585, nil, nil, nil, 2, 2) -- фир 2 фаза
local yellWrathH		= mod:NewYell(308548, nil, nil, nil, "YELL")
local yellWrathHOb		= mod:NewYell(42783, nil, nil, nil, "YELL")
local yellWrathHFades	= mod:NewShortFadesYell(308548, nil, nil, nil, "YELL")
local yellWrathHObFades	= mod:NewShortFadesYell(42783, nil, nil, nil, "YELL")

local timerNextHelp		= mod:NewTimer(40, "TimerNextHelp", 308558, nil, nil, 3, DBM_CORE_TANK_ICON)
local timerWrathH		= mod:NewTargetTimer(6, 308548, nil, "RemoveEnrage", nil, 1, nil, DBM_CORE_ENRAGE_ICON, nil, 1, 5)
local timerNextWrathH	= mod:NewCDTimer(43, 308548, nil, "RemoveEnrage", nil, 1, nil, DBM_CORE_ENRAGE_ICON)
local timerFlashVoid    = mod:NewCDTimer(75, 308585, nil, "RemoveEnrage", nil, 6, nil, DBM_CORE_HEROIC_ICON)

local priestsN = true
local priestsH = true
local provid = true
local KolTargets = {}
local warned_preP1 = false
local warned_preP2 = false

mod:AddBoolOption("Zrec")
mod:AddBoolOption("RangeFrame", true)

mod.vb.Fear = 0

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 18805, "High Astromancer Solarian")
	if mod:IsDifficulty("heroic25") then
		timerNextHelp:Start(-delay)
	    timerNextWrathH:Start(-delay)
		self:SetStage(1)
	else
		self.vb.Fear = 0
	    timerAdds:Start()
		warnAddsSoon:Schedule(52)
	end
end


function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 18805, "High Astromancer Solarian", wipe)
end

--------------------------нормал--------------------------

function mod:PriestNIcon()  --об
	if DBM:GetRaidRank() >= 1 then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid"..i.."target") == L.PriestN then
				priestsN = false
				SetRaidTarget("raid"..i.."target", 6)
				break
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellAdds then
		timerPriestsN:Start()
		timerNextWrathN:Start()
	elseif msg == L.YellPriests  then
		priestsN = true
		timerAdds:Start()
		warnAddsSoon:Schedule(52)
	end
end

function mod:UNIT_TARGET()
	if priestsN then
		self:PriestNIcon()
	end
end

--------------------------героик--------------------------

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 308562 then -- кольцо
		warnRing:Schedule(0)
	elseif spellId == 308558 then -- послушники
		timerNextHelp:Schedule(80)
		specWarnHelp:Show(args.sourceName)
		priestsH = true
		provid	 = true
	elseif spellId == 308585 then -- УЖАС

		specWarnFlashVoid:Show(self.vb.Fear)
		timerFlashVoid:Schedule(5)
	elseif spellId == 308576 then
		self:SetStage(2)
		timerNextHelp:Stop()
		warnFlashVoid:Schedule(70)
		timerFlashVoid:Start()
		warnPhase2:Show()
	end
end


function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 308548 then    -- хм
		timerNextWrathH:Start()
		timerWrathH:Start(args.destName)
		self:SetIcon(args.destName, 8, 6)
		if args:IsPlayer() then
			yellWrathH:Yell()
			yellWrathHFades:Countdown(spellId)
		end
	elseif spellId == 308544 and self.vb.phase == 1 then -- Стаки луча
		if args:IsPlayer() then
			specWarnDebaf:Show()
		end
	elseif spellId == 308563 then -- Ослепление
		KolTargets[#KolTargets + 1] = args.destName
		self:UnscheduleMethod("Kolzo")
		self:ScheduleMethod(0.1, "Kolzo")
	elseif spellId == 42783 then   -- об
		timerNextWrathN:Start()
		warnWrathN:Show(args.destName)
		timerWrathN:Start(args.destName)
		self:SetIcon(args.destName, 8, 6)
		if args:IsPlayer() then
			specWarnWrathN:Show()
			yellWrathHOb:Yell()
			yellWrathHObFades:Countdown(spellId)
		end
	end
end

function mod:Kolzo()
	warnKol:Show(table.concat(KolTargets, "<, >"))
	table.wipe(KolTargets)
end

function mod:PriestHIcon() -- хм
	if DBM:GetRaidRank() >= 1 then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid"..i.."target") == L.PriestH then
				priestsH = false
				SetRaidTarget("raid"..i.."target", 6)
				break
			end
		end
	end
end

function mod:ProvidIcon()
	if DBM:GetRaidRank() >= 1 then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid"..i.."target") == L.Provid then
				provid = false
				SetRaidTarget("raid"..i.."target", 7)
				break
			end
		end
	end
end

function mod:UNIT_TARGET()
	if priestsH then
		self:PriestHIcon()
	elseif provid then
	    self:ProvidIcon()
	end
end

function mod:SWING_DAMAGE(args)
	if args:GetDestCreatureID() == 3410  and args:IsSrcTypePlayer() then
		if args.sourceName ~= UnitName("player") then
			if self.Options.Zrec then
				DBM.Arrow:ShowRunTo(args.sourceName, 0, 0)
			end
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 18805 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.37 then
		warned_preP1 = true
		warnPhase2Soon:Show()
	elseif not warned_preP2 and self:GetUnitCreatureId(uId) == 18805 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.35 then
		warned_preP2 = true
		warnPhase2:Show()
		timerAdds:Stop()
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED