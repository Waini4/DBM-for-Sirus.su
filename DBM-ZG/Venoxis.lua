local mod	= DBM:NewMod("Venoxis", "DBM-ZG", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))
mod:SetCreatureID(14507)
mod:RegisterCombat("combat", 14507)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_SUCCESS",
	"SPELL_CAST_START",
	"UNIT_HEALTH"
)

local warnSerpent	= mod:NewTargetAnnounce(23865)
local warnCloud		= mod:NewSpellAnnounce(23861)
local warnRenew		= mod:NewTargetAnnounce(23895)
local warnFire		= mod:NewSpecialWarningCount(23860, nil, nil, nil, 1, 2)--mod:NewTargetAnnounce(23860)
local prewarnPhase2	= mod:NewAnnounce("warnPhase2Soon")
local yellogoni		= mod:NewPosYell(23860)
local yellogonifade	= mod:NewIconFadesYell(23860)

--local warnPlasmaBlast			= mod:NewSpecialWarningDefensive(23860, "Tank", nil, nil, 1, 2)

local timerCloud	= mod:NewBuffActiveTimer(10, 23861)
local timerRenew	= mod:NewTargetTimer(15, 23895)
local timerFireNext	= mod:NewCDTimer(30, 23860, nil, nil, nil, 2, nil, DBM_CORE_DAMAGE_ICON, nil, 1)
local timerFire		= mod:NewTargetTimer(8, 23860, nil, "Melee", 2, 5)

--mod.vb.arrowIcon = 1
mod:AddBoolOption("RangeFrame", true)
mod:AddSetIconOption("SetIconOnWailingArrow", 23860, true, false, {1, 2, 3})--Applies to both reg and mythic version
mod:AddInfoFrameOption(23860, true)
mod:AddBoolOption("Taimeri", true)
local prewarn_Phase2
mod.vb.Fire = 0
local essence = DBM:GetSpellInfo(23860)
mod:AddBoolOption("BossHealthFrame", true, "misc")



function mod:OnCombatStart(delay)
	--self.vb.arrowIcon = 1
	self.vb.Fire = 0
	self:SetStage(1)
	timerFireNext:Start(10)
	prewarn_Phase2 = false
    if self.Options.BossHealthFrame then
		DBM.BossHealth:AddBoss(50608, L.name)
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10)
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM_CORE_INFOFRAME_POWER)
		DBM.InfoFrame:Show(3, "enemypower", 2)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 23860 then
		local remaining = timerFireNext:GetRemaining()
		--timerFireNext:Start(40)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args:IsSpellID(23895) then
		warnRenew:Show(args.destName)
		timerRenew:Stop(args.destName)
	elseif spellId == 23860 and self.vb.phase == 1 then
		self.vb.Fire = self.vb.Fire + 1
		--local icon = self.vb.arrowIcon
		if self.Options.SetIconOnWailingArrow then
			self:SetIcon(args.destName, 1, 10)
		end
		if args:IsPlayer() then
			yellogoni:Yell(1, 1)
			yellogonifade:Countdown(spellId)
		end
		--[[if self.Options.InfoFrame then
			DBM.InfoFrame:SetHeader(essence)
			DBM.InfoFrame:Show(16, "playerdebuffremaining", essence, 3)
		end]]
		warnFire:Show(self.vb.Fire)
		timerFire:Start(args.destName)
		--timerFireNext:Stop()
		--local remaining = timerFireNext:GetRemaining()
		timerFireNext:Start()
		--self.vb.arrowIcon = self.vb.arrowIcon + 1
	elseif args:IsSpellID(23865) then
		warnSerpent:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if args:IsSpellID(23895) then
		timerRenew:Stop()
		elseif args:IsSpellID(23860) then
			--timerFireNext:AddTime(30 + remaining)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(23861) then
		warnCloud:Show()
		timerCloud:Start()
		if self.Options.Taimeri then
			SendChatMessage(L.Rezonans, "SAY")
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not prewarn_Phase2 and self:GetUnitCreatureId(uId) == 14507 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.53 then
		prewarn_Phase2 = true
		prewarnPhase2:Show()
	end
end