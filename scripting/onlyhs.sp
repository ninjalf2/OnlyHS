#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <updater>

#define ONLYHS_VERSION "1.2.0"

#define UPDATE_URL    "http://update.bara.in/onlyhs.txt"

new Handle:g_hEnablePlugin = INVALID_HANDLE;

new Handle:g_hEnableOneShot = INVALID_HANDLE;

new Handle:g_hEnableWeapon = INVALID_HANDLE;

new Handle:g_hAllowGrenade = INVALID_HANDLE;
new Handle:g_hAllowWorld = INVALID_HANDLE;
new Handle:g_hAllowMelee = INVALID_HANDLE;

new Handle:g_hAllowedWeapon = INVALID_HANDLE;
new String:g_sAllowedWeapon[32];

new String:g_sGameType[64];

public Plugin:myinfo = 
{
	name = "Simple Headshot Only",
	author = "Bara",
	description = "Simple Only Headshot Plugin for CSS and CSGO",
	version = ONLYHS_VERSION,
	url = "www.bara.in"
}

public OnPluginStart()
{
	CreateConVar("onlyhs_version", ONLYHS_VERSION, "Simple Only Headshot", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AutoExecConfig_SetFile("plugin.onlyhs", "sourcemod");
	AutoExecConfig_SetCreateFile(true);

	g_hEnablePlugin = AutoExecConfig_CreateConVar("onlyhs_enable", "1", "Enable / Disalbe Simple Only HeadShot Plugin", _, true, 0.0, true, 1.0);
	g_hEnableOneShot = AutoExecConfig_CreateConVar("onlyhs_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_hEnableWeapon = AutoExecConfig_CreateConVar("onlyhs_allow_oneweapon", "1", "Enable / Disalbe Only One Weapon Damage", _, true, 0.0, true, 1.0);
	g_hAllowGrenade = AutoExecConfig_CreateConVar("onlyhs_allow_grenade", "0", "Enable / Disalbe Grenade Damage", _, true, 0.0, true, 1.0);
	g_hAllowWorld = AutoExecConfig_CreateConVar("onlyhs_allow_world", "1", "Enable / Disalbe World Damage", _, true, 0.0, true, 1.0);
	g_hAllowMelee = AutoExecConfig_CreateConVar("onlyhs_allow_knife", "0", "Enable / Disalbe Knife Damage", _, true, 0.0, true, 1.0);

	GetGameFolderName(g_sGameType, sizeof(g_sGameType));
	if(StrEqual(g_sGameType, "cstrike", false) || StrEqual(g_sGameType, "csgo", false))
	{
		g_hAllowedWeapon = AutoExecConfig_CreateConVar("onlyhs_allow_weapon", "deagle", "Which weapon should be permitted ( Without 'weapon_' )?");
	}
	else if(StrEqual(g_sGameType, "tf", false))
	{
		g_hAllowedWeapon = AutoExecConfig_CreateConVar("onlyhs_allow_weapon", "revolver", "Which weapon should be permitted ( Without 'tf_weapon_' )?");
	}
	else if(StrEqual(g_sGameType, "dod", false))
	{
		g_hAllowedWeapon = AutoExecConfig_CreateConVar("onlyhs_allow_weapon", "colt", "Which weapon should be permitted ( Without 'weapon_' )?");
	}

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	for(new i = 1; i <= MaxClients; i++)
	{
		SDKHook(i, SDKHook_TraceAttack, TraceAttack);
	}

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(GetConVarInt(g_hEnablePlugin))
	{
		if(IsClientValid(victim))
		{
			if(GetConVarInt(g_hAllowWorld))
			{
				if(attacker == 0)
				{
					return Plugin_Continue;
				}
			}
			else
			{
				damage = 0.0;
				return Plugin_Changed;
			}

			if(IsClientValid(attacker))
			{
				decl String:grenade[32];
				GetEdictClassname(inflictor, grenade, sizeof(grenade));
				decl String:weapon[32];
				GetClientWeapon(attacker, weapon, sizeof(weapon));

				if(hitgroup != 1)
				{
					if(GetConVarInt(g_hAllowMelee))
					{
						if(StrEqual(g_sGameType, "cstrike", false) || StrEqual(g_sGameType, "csgo", false))
						{
							if(StrEqual(weapon, "weapon_knife"))
							{
								return Plugin_Continue;
							}
						}
						else if(StrEqual(g_sGameType, "tf", false))
						{
							// Not tested - I dont play tf2
							if(StrEqual(weapon, "tf_weapon_bat") || StrEqual(weapon, "tf_weapon_bat_wood") || StrEqual(weapon, "tf_weapon_bat_fish") || StrEqual(weapon, "tf_weapon_bat_fish") || StrEqual(weapon, "tf_weapon_bat_giftwrap") || StrEqual(weapon, "tf_weapon_shovel") || StrEqual(weapon, "tf_weapon_katana") || StrEqual(weapon, "tf_weapon_fireaxe") || StrEqual(weapon, "tf_weapon_bottle") || StrEqual(weapon, "tf_weapon_sword") || StrEqual(weapon, "tf_weapon_stickbomb") || StrEqual(weapon, "tf_weapon_fists") || StrEqual(weapon, "tf_weapon_wrench") || StrEqual(weapon, "tf_weapon_robot_arm") || StrEqual(weapon, "tf_weapon_bonesaw") || StrEqual(weapon, "tf_weapon_club") || StrEqual(weapon, "tf_weapon_knife"))
							{
								return Plugin_Continue;
							}
						}
						else if(StrEqual(g_sGameType, "dod", false))
						{
							// Not tested - I dont play dods
							if(StrEqual(weapon, "weapon_amerknife") || StrEqual(weapon, "weapon_spade"))
							{
								return Plugin_Continue;
							}
						}
					}

					if(GetConVarInt(g_hAllowGrenade))
					{
						if(StrEqual(g_sGameType, "cstrike", false))
						{
							if(StrEqual(grenade, "hegrenade_projectile"))
							{
								return Plugin_Continue;
							}
						}
						else if(StrEqual(g_sGameType, "csgo", false))
						{
							if(StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile"))
							{
								return Plugin_Continue;
							}
						}
						else if(StrEqual(g_sGameType, "tf", false))
						{
							// Not tested - I dont play tf2
							if(StrEqual(weapon, "tf_weapon_grenadelauncher") || StrEqual(weapon, "tf_weapon_cannon") || StrEqual(weapon, "tf_weapon_pipebomblauncher"))
							{
								return Plugin_Continue;
							}
						}
						else if(StrEqual(g_sGameType, "dod", false))
						{
							// Not tested - I dont play dods
							if(StrEqual(weapon, "weapon_frag_us") || StrEqual(weapon, "weapon_frag_ger"))
							{
								return Plugin_Continue;
							}
						}
					}

					damage = 0.0;
					return Plugin_Changed;
				}
				else
				{
					decl String:allowed[32];
					GetConVarString(g_hAllowedWeapon, g_sAllowedWeapon, sizeof(g_sAllowedWeapon));

					if(StrEqual(g_sGameType, "cstrike", false) || StrEqual(g_sGameType, "csgo", false))
					{
						Format(allowed, sizeof(allowed), "weapon_%s", g_sAllowedWeapon);
					}
					else if(StrEqual(g_sGameType, "tf", false))
					{
						Format(allowed, sizeof(allowed), "tf_weapon_%s", g_sAllowedWeapon);
					}
					else if(StrEqual(g_sGameType, "dod", false))
					{
						Format(allowed, sizeof(allowed), "weapon_%s", g_sAllowedWeapon);
					}
					
					if(GetConVarInt(g_hEnableWeapon))
					{
						if(!StrEqual(weapon, allowed))
						{
							return Plugin_Handled;
						}
					}

					if(GetConVarInt(g_hEnableOneShot))
					{
						// Without +1.0 = Warning on compiling ( tag mismatch )
						damage = GetClientHealth(victim)+1.0;
						return Plugin_Changed;
					}
					return Plugin_Continue;
				}
			}
			else
			{
				return Plugin_Handled;
			}
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}

stock bool:IsClientValid(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}