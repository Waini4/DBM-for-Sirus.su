local mod	= DBM:NewMod("Gorelac", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20201208235000")

mod:SetCreatureID(121217)
mod:RegisterCombat("combat", 121217)
mod:SetUsedIcons(8, 7)


mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"UNIT_DIED",
	"UNIT_TARGET",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_LOOT",
	"SWING_DAMAGE"
)


local warnStrongBeat			= mod:NewStackAnnounce(310548, 1, nil, "Tank")
local warnPoisonous				= mod:NewSpellAnnounce(310549, 4)
local warnParalysis				= mod:NewSpellAnnounce(310555, 4)
local warnMassiveShell			= mod:NewTargetAnnounce(310560, 2)
local warnPowerfulShot			= mod:NewTargetAnnounce(310564, 4)
local warnShrillScreech			= mod:NewSpellAnnounce(310566, 4)
local warnCallGuardians			= mod:NewSpellAnnounce(310557, 4)

local specWarnRippingThorn		= mod:NewSpecialWarningStack(310546, "Melee", 7)
local specWarnPoisonousBlood	= mod:NewSpecialWarningStack(310547, "SpellCaster", 7)
local specWarnStrongBeat		= mod:NewSpecialWarningYou(310548, nil, nil, nil, 2, 2)
local specWarnPoisonous			= mod:NewSpecialWarningYou(310549, nil, nil, nil, 2, 2)
local specwarnCallGuardians		= mod:NewSpecialWarningSwitch(310557, "Ranged|Tank", nil, nil, 1, 2)
local specWarnShrillScreech		= mod:NewSpecialWarningYou(310566, nil, nil, nil, 2, 2)

local timerStrongBeat			= mod:NewBuffFadesTimer(30, 310548, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerPoisonous			= mod:NewBuffFadesTimer(30, 310549, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerShrillScreech		= mod:NewBuffFadesTimer(6, 310566, nil, nil, nil, 5, nil, DBM_CORE_INTERRUPT_ICON)
local timerPoisonousCD			= mod:NewCDTimer(25, 310549, nil, nil, nil, 3, nil, DBM_CORE_TANK_ICON)
local timerStrongBeatCD			= mod:NewCDTimer(25, 310548, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerCallGuardiansCD		= mod:NewNextTimer(45, 310557, nil, nil, nil, 1, nil, DBM_CORE_DAMAGE_ICON)

local enrageTimer				= mod:NewBerserkTimer(750)


function mod:OnCombatStart(delay)
    DBM:FireCustomEvent("DBM_EncounterStart", 121217, "Gorelac")
    enrageTimer:Start()
    timerCallGuardiansCD:Start(45-delay)
	DBM.RangeCheck:Show(6)
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 121217, "Gorelac", wipe)
    DBM.RangeCheck:Hide()
end


function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
    if spellId == 310566 then
		warnShrillScreech:Show()
    elseif spellId == 310549 then
        warnPoisonous:Show()
        timerPoisonousCD:Start()
    elseif spellId == 310564 or spellId == 310565 then
		warnPowerfulShot:Show(args.destName)
    elseif spellId == 310557 then
        warnCallGuardians:Show()
		specwarnCallGuardians:Show()
        timerCallGuardiansCD:Start()
    end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
    if spellId == 310546 then
		local amount = args.amount or 1
		if amount >= 10 then
            if args:IsPlayer() then
				specWarnRippingThorn:Show(args.amount)
				specWarnRippingThorn:Play("stackhigh")
			end
        end
    elseif spellId == 310547 then
		local amount = args.amount or 1
		if amount >= 10 then
            if args:IsPlayer() then
				specWarnPoisonousBlood:Show(args.amount)
				specWarnPoisonousBlood:Play("stackhigh")
			end
        end
    elseif spellId == 310548 then
        warnStrongBeat:Show(args.destName, args.amount or 1)
        if args:IsPlayer() then
            specWarnStrongBeat:Show()
            timerStrongBeat:Start(args.destName)
        end
    elseif spellId == 310549 then
        timerPoisonous:Start(args.destName)
		if args:IsPlayer() then
			specWarnPoisonous:Show()
		end
	elseif spellId == 310566 then
		timerShrillScreech:Start()
		if args:IsPlayer() then
			specWarnShrillScreech:Show()
		end
    end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
    if spellId == 310548 then
        timerStrongBeatCD:Start()
	elseif spellId == 310560 or spellId == 310561 or spellId == 310562 or spellId == 310563 then
		warnMassiveShell:Show()
    end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
    if spellId == 310549 then
        if args:IsPlayer() then
		timerPoisonous:Cancel()
		end
    elseif spellId == 310548 then
        if args:IsPlayer() then
		timerStrongBeat:Cancel()
		end
	end
end