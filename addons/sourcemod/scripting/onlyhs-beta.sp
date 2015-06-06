/*

	Changelog 2.0.0:
		- Removed Updater
		- Removed AutoExecConfig
		- New Syntax/API Support (require Sourcemod 1.7+)
		- Plugin name changed ( Headshot Only -> Only Headshot )

*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

#define ONLYHS_VERSION "2.0.0"

ConVar g_hEnablePlugin = null;
ConVar g_hEnableOneShot = null;
ConVar g_hEnableWeapons = null;
ConVar g_hAllowGrenade = null;
ConVar g_hAllowWorld = null;
ConVar g_hAllowMelee = null;
ConVar g_hAllowedWeapons = null;
ConVar g_hEnableBloodSplatter = null;
ConVar g_hEnableBloodSplash = null;
ConVar g_hEnableNoBlood = null;

char g_sAllowedWeapons[256];
char g_sGrenade[32];
char g_sWeapon[32];


public Plugin myinfo = 
{
	name = "Only Headshot",
	author = "Bara",
	description = "Only Headshot Plugin for CSS and CSGO",
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
	
	g_hEnablePlugin = CreateConVar("onlyhs_enable", "1", "Enable / Disalbe Only HeadShot Plugin", _, true, 0.0, true, 1.0);
	g_hEnableOneShot = CreateConVar("onlyhs_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_hEnableWeapons = CreateConVar("onlyhs_oneweapon", "1", "Enable / Disalbe certain weapons damage ( see: onlyhs_allow_weapon )", _, true, 0.0, true, 1.0);
	g_hAllowGrenade = CreateConVar("onlyhs_allow_grenade", "0", "Enable / Disalbe No Grenade Damage", _, true, 0.0, true, 1.0);
	g_hAllowWorld = CreateConVar("onlyhs_allow_world", "0", "Enable / Disalbe No World Damage", _, true, 0.0, true, 1.0);
	g_hAllowMelee = CreateConVar("onlyhs_allow_knife", "0", "Enable / Disalbe No Knife Damage", _, true, 0.0, true, 1.0);
	g_hAllowedWeapons = CreateConVar("onlyhs_allow_weapon", "deagle,elite", "Which weapon should be permitted ( Without 'weapon_' )?");
	g_hEnableNoBlood = CreateConVar("onlyhs_allow_blood", "0", "Enable / Disable No Blood", _, true, 0.0, true, 1.0);
	g_hEnableBloodSplatter = CreateConVar("onlyhs_allow_blood_splatter", "0", "Enable / Disable No Blood Splatter", _, true, 0.0, true, 1.0);
	g_hEnableBloodSplash = CreateConVar("onlyhs_allow_blood_splash", "0", "Enable / Disable No Blood Splash", _, true, 0.0, true, 1.0);

	AutoExecConfig();

	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
	AddTempEntHook("World Decal", TE_OnWorldDecal);

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
	if(g_hEnablePlugin.BoolValue)
	{
		if(IsClientValid(victim))
		{
			if(damagetype & DMG_FALL || attacker == 0)
			{
				if(g_hAllowWorld.BoolValue)
					return Plugin_Continue;
				else
					return Plugin_Handled;
			}

			if(IsClientValid(attacker))
			{
				GetEdictClassname(inflictor, g_sGrenade, sizeof(g_sGrenade));
				GetClientWeapon(attacker, g_sWeapon, sizeof(g_sWeapon));

				if(damagetype & CS_DMG_HEADSHOT)
				{
					if(g_hEnableWeapons.BoolValue)
					{
						g_sAllowedWeapons[0] = '\0';
						g_hAllowedWeapons.GetString(g_sAllowedWeapons, sizeof(g_sAllowedWeapons));

						if(StrContains(g_sAllowedWeapons, g_sWeapon[7], false) != -1)
							return Plugin_Continue;

						return Plugin_Handled;
					}

					if(g_hEnableOneShot.BoolValue)
					{
						damage = float(GetClientHealth(victim));

						return Plugin_Changed;
					}

					return Plugin_Continue;
				}
				else
				{
					if(g_hAllowMelee.BoolValue)
					{
						if ((StrContains(g_sWeapon, "knife", false) != -1) || (StrContains(g_sWeapon, "bayonet", false) != -1))
							return Plugin_Continue;
					}

					if(g_hAllowGrenade.BoolValue)
					{
						if (StrContains(g_sGrenade, "_projectile", false) != -1)
							return Plugin_Continue;
					}
					return Plugin_Handled;
				}
			}
			else
				return Plugin_Handled;
		}
		else
			return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	int nHitBox = TE_ReadNum("m_nHitBox");
	char sEffectName[64];

	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	
	if(g_hEnableNoBlood.BoolValue)
	{
		if(StrEqual(sEffectName, "csblood"))
		{
			if(g_hEnableBloodSplatter.BoolValue)
				return Plugin_Handled;
		}
		if(StrEqual(sEffectName, "ParticleEffect"))
		{
			if(g_hEnableBloodSplash.BoolValue)
			{
				char sParticleEffectName[64];
				GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
				
				if(StrEqual(sParticleEffectName, "impact_helmet_headshot") || StrEqual(sParticleEffectName, "impact_physics_dust"))
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action TE_OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
	float vecOrigin[3];
	int nIndex = TE_ReadNum("m_nIndex");
	char sDecalName[64];

	TE_ReadVector("m_vecOrigin", vecOrigin);
	GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
	
	if(g_hEnableNoBlood.BoolValue)
	{
		if(StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
			if(g_hEnableBloodSplash.BoolValue)
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

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("decalprecache");
	
	return ReadStringTable(table, index, sDecalName, maxlen);
}