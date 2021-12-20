local mod	= DBM:NewMod("BPCouncil", "DBM-Icecrown", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20200405141240")
mod:SetCreatureID(37970, 37972, 37973)
mod:SetUsedIcons(7, 8)

mod:SetBossHealthInfo(
	37972, L.Keleseth,
	37970, L.Valanar,
	37973, L.Taldaram
)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_SUMMON",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_TARGET",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnTargetSwitch			= mod:NewAnnounce("WarnTargetSwitch", 3, 70952)
local warnTargetSwitchSoon		= mod:NewAnnounce("WarnTargetSwitchSoon", 2, 70952)
local warnConjureFlames			= mod:NewCastAnnounce(71718, 2)
local warnEmpoweredFlamesCast	= mod:NewCastAnnounce(72040, 3)
local warnEmpoweredFlames		= mod:NewTargetAnnounce(72040, 4)
local warnGliteringSparks		= mod:NewTargetAnnounce(72798, 2)
local warnShockVortex			= mod:NewTargetAnnounce(72037, 3)				-- 1,5sec cast
local warnEmpoweredShockVortex	= mod:NewCastAnnounce(72039, 4)					-- 4,5sec cast
local warnKineticBomb			= mod:NewSpellAnnounce(72053, 3, nil, "Ranged")
local warnDarkNucleus			= mod:NewSpellAnnounce(71943, 1, nil, false)	-- instant cast

local specWarnVortex			= mod:NewSpecialWarningYou(72037, nil, nil, nil, 1, 2)
local yellVortex				= mod:NewYell(72037)
local specWarnVortexNear		= mod:NewSpecialWarningClose(72037, nil, nil, nil, 1, 2)
local specWarnEmpoweredShockV	= mod:NewSpecialWarningMoveAway(72039, nil, nil, nil, 1, 2)
local specWarnEmpoweredFlames	= mod:NewSpecialWarningRun(72040, nil, nil, nil, 4, 2)
local specWarnShadowPrison		= mod:NewSpecialWarningStack(72999, nil, 6, nil, nil, 1, 6)

local timerTargetSwitch			= mod:NewTimer(47, "TimerTargetSwitch", 70952)	-- every 46-47seconds
local timerDarkNucleusCD		= mod:NewCDTimer(10, 71943, nil, false, nil, 5)	-- usually every 10 seconds but sometimes more
local timerConjureFlamesCD		= mod:NewCDTimer(20, 71718, nil, nil, nil, 3) -- every 20-30 seconds but never more often than every 20sec
local timerGlitteringSparksCD	= mod:NewCDTimer(20, 72798, nil, nil, nil, 2) -- This is pretty nasty on heroic
local timerShockVortex			= mod:NewCDTimer(16.5, 72037, nil, nil, nil, 3) -- Seen a range from 16,8 - 21,6
local timerKineticBombCD		= mod:NewCDTimer(18, 72053, nil, "Ranged", nil, 1) -- Might need tweaking
local timerShadowPrison			= mod:NewBuffFadesTimer(10, 72999, nil, nil, nil, 5) -- Hard mode debuff

local berserkTimer				= mod:NewBerserkTimer(600)

mod:AddSetIconOption("EmpoweredFlameIcon", 72040, true, true, {7})
mod:AddSetIconOption("ActivePrinceIcon", "ActivePrinceIcon", true, true, {8})
mod:AddBoolOption("RangeFrame", true)
mod:AddBoolOption("VortexArrow")
mod:AddBoolOption("BypassLatencyCheck", false)--Use old scan method without syncing or latency check (less reliable but not dependant on other DBM users in raid)

local activePrince
local glitteringSparksTargets	= {}

local function warnGlitteringSparksTargets()
	warnGliteringSparks:Show(table.concat(glitteringSparksTargets, "<, >"))
	table.wipe(glitteringSparksTargets)
	timerGlitteringSparksCD:Start()
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 37970, "Blood Prince Council")
	berserkTimer:Start(-delay)
	warnTargetSwitchSoon:Schedule(42-delay)
	timerTargetSwitch:Start(-delay)
	activePrince = nil
	table.wipe(glitteringSparksTargets)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(12)
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 37970, "Blood Prince Council", wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:ShockVortexTarget()
	local targetname = self:GetBossTarget(37970)
	if not targetname then return end
	if mod:LatencyCheck() then--Only send sync Shock Vortex target if you have low latency.
		self:SendSync("ShockVortex", targetname)
	end
end

function mod:OldShockVortexTarget()
	local targetname = self:GetBossTarget(37970)
	if not targetname then return end
	warnShockVortex:Show(targetname)
	if targetname == UnitName("player") then
		specWarnVortex:Show()
		specWarnVortex:Play("watchstep")
		yellVortex:Yell()
	elseif targetname then
		local uId = DBM:GetRaidUnitId(targetname)
		if uId then
			local inRange = CheckInteractDistance(uId, 2)
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			if inRange then
				specWarnVortexNear:Show(targetname)
				specWarnVortexNear:Play("watchstep")
				if self.Options.VortexArrow then
					DBM.Arrow:ShowRunAway(x, y, 10, 5)
				end
			end
		end
	end
end

function mod:HideRange()
	DBM.RangeCheck:Hide()
end

function mod:TrySetTarget()
	if DBM:GetRaidRank() >= 1 and self.Options.ActivePrinceIcon then
		for i = 1, GetNumRaidMembers() do
			if UnitGUID("raid"..i.."target") == activePrince then
				activePrince = nil
				SetRaidTarget("raid"..i.."target", 8)
			end
			if not (activePrince) then
				break
			end
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(72037) then		-- Shock Vortex
		timerShockVortex:Start()
		if self.Options.BypassLatencyCheck then
			self:ScheduleMethod(0.1, "OldShockVortexTarget")
		else
			self:ScheduleMethod(0.1, "ShockVortexTarget")
		end
	elseif args:IsSpellID(72039, 73037, 73038, 73039) then	-- Empowered Shock Vortex(73037, 73038, 73039 drycoded from wowhead)
		warnEmpoweredShockVortex:Show()
		specWarnEmpoweredShockV:Show()
		specWarnEmpoweredShockV:Play("scatter")
		timerShockVortex:Start()
	elseif args:IsSpellID(71718) then	-- Conjure Flames
		warnConjureFlames:Show()
		timerConjureFlamesCD:Start()
	elseif args:IsSpellID(72040) then	-- Conjure Empowered Flames
		warnEmpoweredFlamesCast:Show()
		timerConjureFlamesCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(70952) and self:IsInCombat() then
		warnTargetSwitch:Show(L.Valanar)
		warnTargetSwitchSoon:Schedule(42)
		timerTargetSwitch:Start()
		activePrince = args.destGUID
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(12)
		end
	elseif args:IsSpellID(70981) and self:IsInCombat() then
		warnTargetSwitch:Show(L.Keleseth)
		warnTargetSwitchSoon:Schedule(42)
		timerTargetSwitch:Start()
		activePrince = args.destGUID
		if self.Options.RangeFrame then
			self:ScheduleMethod(4.5, "HideRange")--delay hiding range frame for a few seconds after change incase valanaar got a last second vortex cast off
		end
	elseif args:IsSpellID(70982) and self:IsInCombat() then
		warnTargetSwitch:Show(L.Taldaram)
		warnTargetSwitchSoon:Schedule(42)
		timerTargetSwitch:Start()
		activePrince = args.destGUID
		if self.Options.RangeFrame then
			self:ScheduleMethod(4.5, "HideRange")--delay hiding range frame for a few seconds after change incase valanaar got a last second vortex cast off
		end
	elseif args:IsSpellID(72999) then	--Shadow Prison (hard mode)
		if args:IsPlayer() then
			timerShadowPrison:Start()
			if (args.amount or 1) >= 6 then	--Placeholder right now, might use a different value
				specWarnShadowPrison:Show(args.amount)
				specWarnShadowPrison:Play("stackhigh")
			end
		end
	elseif args:IsSpellID(71807, 72796, 72797, 72798) and args:IsDestTypePlayer() then	-- Glittering Sparks(Dot/slow, dangerous on heroic during valanaar)
		glitteringSparksTargets[#glitteringSparksTargets + 1] = args.destName
		self:Unschedule(warnGlitteringSparksTargets)
		self:Schedule(1, warnGlitteringSparksTargets)
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_SUMMON(args)
	if args:IsSpellID(71943) then
		warnDarkNucleus:Show()
		timerDarkNucleusCD:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg:match(L.EmpoweredFlames) then
		warnEmpoweredFlames:Show(target)
		if target == UnitName("player") then
			specWarnEmpoweredFlames:Show()
			specWarnEmpoweredFlames:Play("justrun")
		end
		if self.Options.EmpoweredFlameIcon then
			self:SetIcon(target, 7, 10)
		end
	end
end

function mod:UNIT_TARGET()
	if activePrince then
		self:TrySetTarget()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, spellName)
	if spellName == GetSpellInfo(72080) and mod:LatencyCheck() then
		self:SendSync("KineticBomb")
	end
end

function mod:OnSync(msg, target)
	if msg == "KineticBomb" then
		warnKineticBomb:Show()
		if mod:IsDifficulty("normal10") or mod:IsDifficulty("heroic10") then
			timerKineticBombCD:Start(27)
		else
			timerKineticBombCD:Start()
		end
	elseif msg == "ShockVortex" then
		if not self.Options.BypassLatencyCheck then
			warnShockVortex:Show(target)
			if target == UnitName("player") then
				specWarnVortex:Show()
			elseif target then
				local uId = DBM:GetRaidUnitId(target)
				if uId then
					local inRange = CheckInteractDistance(uId, 2)
					local x, y = GetPlayerMapPosition(uId)
					if x == 0 and y == 0 then
						SetMapToCurrentZone()
						x, y = GetPlayerMapPosition(uId)
					end
					if inRange then
						specWarnVortexNear:Show(target)
						if self.Options.VortexArrow then
							DBM.Arrow:ShowRunAway(x, y, 10, 5)
						end
					end
				end
			end
		end
	end
end
