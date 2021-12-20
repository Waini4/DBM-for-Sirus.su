﻿local mod	= DBM:NewMod("TrashMobs", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20201025140000")

mod:SetCreatureID(21251)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"UNIT_DIED",
	"UNIT_TARGET",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_LOOT"
)

local specWarnRange		= mod:NewSpecialWarningMoveAway(39042)


function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(39042) then
		DBM.RangeCheck:Show(8)
		if args:IsPlayer() and self:AntiSpam(4) then
		specWarnRange:Show()
		end
	end
end

function mod:OnCombatEnd(wipe)
	DBM.RangeCheck:Hide()
end
