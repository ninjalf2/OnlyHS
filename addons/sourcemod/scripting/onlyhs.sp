#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

#define ONLYHS_VERSION "2.0.2"

ConVar g_cEnablePlugin = null;
ConVar g_cEnableOneShot = null;
ConVar g_cAllowGrenade = null;
ConVar g_cAllowWorld = null;
ConVar g_cAllowKnife = null;

public Plugin myinfo =
{
	name = "Only Headshot [modified]",
	author = "Bara [modified by ninjalf2]",
	description = "[Modified] Only Headshot Plugin for CSS and CSGO",
	version = ONLYHS_VERSION,
	url = "www.bara.in"
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
	}

	CreateConVar("onlyhs_version", ONLYHS_VERSION, "Only Headshot", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LoadTranslations("common.phrases");

	g_cEnablePlugin = CreateConVar("onlyhs_enable", "1", "Enable / Disalbe Only HeadShot Plugin", _, true, 0.0, true, 1.0);
	g_cEnableOneShot = CreateConVar("onlyhs_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_cAllowGrenade = CreateConVar("onlyhs_allow_grenade", "0", "Enable / Disalbe No Grenade Damage", _, true, 0.0, true, 1.0);
	g_cAllowWorld = CreateConVar("onlyhs_allow_world", "0", "Enable / Disalbe No World Damage", _, true, 0.0, true, 1.0);
	g_cAllowKnife = CreateConVar("onlyhs_allow_knife", "0", "Enable / Disalbe No Knife Damage", _, true, 0.0, true, 1.0);

	AutoExecConfig();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(g_cEnablePlugin.BoolValue)
	{
		if(IsClientValid(victim))
		{
			if(
				damagetype == DMG_FALL
				|| damagetype == DMG_GENERIC
				|| damagetype == DMG_CRUSH
				|| damagetype == DMG_SLASH
				|| damagetype == DMG_BURN
				|| damagetype == DMG_VEHICLE
				|| damagetype == DMG_FALL
				|| damagetype == DMG_BLAST
				|| damagetype == DMG_SHOCK
				|| damagetype == DMG_SONIC
				|| damagetype == DMG_ENERGYBEAM
				|| damagetype == DMG_DROWN
				|| damagetype == DMG_PARALYZE
				|| damagetype == DMG_NERVEGAS
				|| damagetype == DMG_POISON
				|| damagetype == DMG_ACID
				|| damagetype == DMG_AIRBOAT
				|| damagetype == DMG_PLASMA
				|| damagetype == DMG_RADIATION
				|| damagetype == DMG_SLOWBURN
				|| attacker == 0
			)
			{
				if(g_cAllowWorld.BoolValue)
					return Plugin_Continue;
				else
					return Plugin_Handled;
			}

			if(IsClientValid(attacker))
			{
				char sGrenade[32];
				char sWeapon[32];

				GetEdictClassname(inflictor, sGrenade, sizeof(sGrenade));
				GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));

				if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
					if(g_cAllowKnife.BoolValue)
						return Plugin_Continue;

				if (StrContains(sGrenade, "_projectile", false) != -1)
					if(g_cAllowGrenade.BoolValue)
						return Plugin_Continue;

				if(damagetype & CS_DMG_HEADSHOT)
				{
					if(g_cEnableOneShot.BoolValue)
					{
						damage = float(GetClientHealth(victim) + GetClientArmor(victim));
						return Plugin_Changed;
					}
					return Plugin_Continue;
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}