#pragma semicolon 1
#pragma tabsize 4

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

#define FIXFLAG_INVULNERABILITY (1<<0)
#define FIXFLAG_TELEPORT (1<<1)

public Plugin:myinfo = 
{
    name = "[L4D & L4D2] Tank Rock Fix",
    author = "xiaolinRM",
    description = "Fixes two Tank rock bugs: the rock cannot be destroyed for 0.5s after being thrown, and it may teleport to Survivors near the Tank.",
    version = PLUGIN_VERSION,
    url = "https://github.com/xiaolinRM/L4D2Plugins/tree/main/l4d_tankrock_fix"
};

new g_iFixFlags;

new m_vecPrevOrigin;
new m_invulnerableTime;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    new EngineVersion:engine = GetEngineVersion();
    if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2) return APLRes_Success;
    strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
    return APLRes_SilentFailure;
}

public OnPluginStart()
{
    m_vecPrevOrigin = FindSendPropInfo("CBaseCSGrenadeProjectile", "m_vInitialVelocity") + 24;
    m_invulnerableTime = m_vecPrevOrigin + 16;

    SetConVarString(CreateConVar("l4d_tankrock_fix_version", PLUGIN_VERSION, "Tank Rock Fix Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD), PLUGIN_VERSION);

    new Handle:convar = CreateConVar("l4d_tankrock_fix_flags", "3", "Fix Flags\n0 = Disable Plugin\n1 = Fix Rock Invulnerability\n2 = Fix Rock Teleport\n3 = Fix Rock Invulnerability & Teleport", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    AutoExecConfig(true, "l4d_tankrock_fix");
    HookConVarChange(convar, OnConVarChanged);
    g_iFixFlags = GetConVarInt(convar);

    if (g_iFixFlags == 0) return;

    new entity = -1;
    while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
    {
        if (g_iFixFlags & FIXFLAG_INVULNERABILITY) SDKHook(entity, SDKHook_Think, CTankRock_ProximityThink);
        if (g_iFixFlags & FIXFLAG_TELEPORT) SDKHook(entity, SDKHook_ThinkPost, CTankRock_ProximityThink_Post);
    }
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    new oldFlags = g_iFixFlags;
    g_iFixFlags = GetConVarInt(convar);
    if (oldFlags == g_iFixFlags) return;

    new entity = -1;
    while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
    {
        if (!(oldFlags & FIXFLAG_INVULNERABILITY) && (g_iFixFlags & FIXFLAG_INVULNERABILITY)) SDKHook(entity, SDKHook_Think, CTankRock_ProximityThink);
        else if ((oldFlags & FIXFLAG_INVULNERABILITY) && !(g_iFixFlags & FIXFLAG_INVULNERABILITY)) SDKUnhook(entity, SDKHook_Think, CTankRock_ProximityThink);
        if (!(oldFlags & FIXFLAG_TELEPORT) && (g_iFixFlags & FIXFLAG_TELEPORT)) SDKHook(entity, SDKHook_ThinkPost, CTankRock_ProximityThink_Post);
        else if ((oldFlags & FIXFLAG_TELEPORT) && !(g_iFixFlags & FIXFLAG_TELEPORT)) SDKUnhook(entity, SDKHook_ThinkPost, CTankRock_ProximityThink_Post);
    }
}

public OnEntityCreated(entity, const String:classname[])
{
    if (g_iFixFlags == 0) return;

    if (strcmp(classname, "tank_rock") == 0)
    {
        if (g_iFixFlags & FIXFLAG_INVULNERABILITY) SDKHook(entity, SDKHook_Think, CTankRock_ProximityThink);
        if (g_iFixFlags & FIXFLAG_TELEPORT) SDKHook(entity, SDKHook_ThinkPost, CTankRock_ProximityThink_Post);
    }
}

public CTankRock_ProximityThink(entity)
{
    if (GetEntDataFloat(entity, m_invulnerableTime) > 0.0001)
        SetEntDataFloat(entity, m_invulnerableTime, 0.0001);
}

public CTankRock_ProximityThink_Post(entity)
{
    new Float:origin[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
    SetEntDataVector(entity, m_vecPrevOrigin, origin);
}
