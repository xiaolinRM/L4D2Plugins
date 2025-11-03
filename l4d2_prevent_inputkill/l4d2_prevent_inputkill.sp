#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 4

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "[L4D & L4D2] Prevent Input Kill",
    author = "xiaolinRM",
    description = "Prevent players from being removed (Kicked by Console : CBaseEntity::InputKill()).",
    version = PLUGIN_VERSION,
    url = "https://https://github.com/xiaolinRM/L4D2Plugins/tree/main/l4d2_prevent_inputkill"
};

ConVar g_hMode;
ConVar g_hTeam;
ConVar g_hType;

bool g_bMode;
int g_iTeam;
int g_iType;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2) return APLRes_Success;
    strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
    return APLRes_SilentFailure;
}

public void OnPluginStart()
{
    g_hMode = CreateConVar("l4d2_prevent_inputkill_mode", "0", "Conditions for Preventing Client Deletion.\n0 = Either team condition OR type condition is met\n1 = Both team condition AND type condition must be met", _, true, 0.0, true, 1.0);
    g_hTeam = CreateConVar("l4d2_prevent_inputkill_team", "2", "Teams to Protect from Deletion.\n(Add the values of the teams you wish to protect)\n1 = Spectator (Team 1)\n2 = Survivor (Team 2)\n4 = Infected (Team 3)\n8 = Passing L4D1 Survivor (Team 4)", _, true, 0.0, true, 15.0);
    g_hType = CreateConVar("l4d2_prevent_inputkill_type", "1", "Client Types to Protect from Deletion.\n(Add the values of the client types you wish to protect)\n1 = Human Player\n2 = Bot", _, true, 0.0, true, 3.0);
    AutoExecConfig(true, "l4d2_prevent_inputkill");
    g_hMode.AddChangeHook(OnConVarChanged);
    g_hTeam.AddChangeHook(OnConVarChanged);
    g_hType.AddChangeHook(OnConVarChanged);
    UpdateConVarValue();

    CreateConVar("l4d2_prevent_inputkill_version", PLUGIN_VERSION, "Prevent Input Kill Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

    AddCommandListener(CommandListener_KickID, "kickid");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateConVarValue();
}

public Action CommandListener_KickID(int client, const char[] command, int argc)
{
    if (client || !argc) return Plugin_Continue;
    char args[64];
    GetCmdArgString(args, sizeof args);
    if (StrContains(args, "CBaseEntity::InputKill()") == -1) return Plugin_Continue;
    int target = GetClientOfUserId(StringToInt(args));
    if (!target || !IsClientConnected(target)) return Plugin_Continue;
    bool bTeam = IsClientInGame(target) && (g_iTeam & (1 << (GetClientTeam(target) - 1)));
    bool bType = (g_iType & (IsFakeClient(target) ? 2 : 1)) != 0;
    return (g_bMode ? (bTeam && bType) : (bTeam || bType)) ? Plugin_Stop : Plugin_Continue;
}

void UpdateConVarValue()
{
    g_bMode = g_hMode.BoolValue;
    g_iTeam = g_hTeam.IntValue;
    g_iType = g_hType.IntValue;
}
