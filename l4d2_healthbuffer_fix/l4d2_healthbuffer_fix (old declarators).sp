#pragma semicolon 1
#pragma tabsize 4

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] Health Buffer Fix",
	author = "xiaolinRM",
	description = "Fix the issue where health buffer display cannot exceed 200",
	version = PLUGIN_VERSION,
	url = "https://github.com/xiaolinRM/L4D2Plugins/tree/main/l4d2_healthbuffer_fix"
};

new Float:pain_pills_decay_rate;

public OnPluginStart()
{
	CreateConVar("l4d2_healthbuffer_fix_version", PLUGIN_VERSION, "Health Buffer Fix Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
    new Handle:convar = FindConVar("pain_pills_decay_rate");
    HookConVarChange(convar, OnConVarChanged);
    pain_pills_decay_rate = GetConVarFloat(convar);
    if (!pain_pills_decay_rate)
    {
        PrintToServer("The value of pain_pills_decay_rate is 0, Health buffer display fix is now disabled.");
        return;
    }

    HookEvent("pills_used", Event_CheckEvent);
    HookEvent("adrenaline_used", Event_CheckEvent);
    HookEvent("player_hurt", Event_CheckEvent);
    for (new client = 1; client <= MaxClients; client++)
        if (IsClientInGame(client))
            SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnPluginEnd()
{
    UpdateHealthBuffer();
}

public OnClientPutInServer(client)
{
    if (pain_pills_decay_rate)
        SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnPostThinkPost(client)
{
    CheckPlayerHealthBuffer(client);
}

public Event_CheckEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client) CheckPlayerHealthBuffer(client);
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    new Float:value = GetConVarFloat(convar);
    if (value == pain_pills_decay_rate) return;
    UpdateHealthBuffer();
    new Float:old = pain_pills_decay_rate;
    pain_pills_decay_rate = value;
    if (!old && pain_pills_decay_rate)
    {
        HookEvent("pills_used", Event_CheckEvent);
        HookEvent("adrenaline_used", Event_CheckEvent);
        HookEvent("player_hurt", Event_CheckEvent);
        for (new client = 1; client <= MaxClients; client++)
            if (IsClientInGame(client))
                SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
        PrintToServer("Health buffer display fix is now enabled.");
    }
    else if (old && !pain_pills_decay_rate)
    {
        UnhookEvent("pills_used", Event_CheckEvent);
        UnhookEvent("adrenaline_used", Event_CheckEvent);
        UnhookEvent("player_hurt", Event_CheckEvent);
        for (new client = 1; client <= MaxClients; client++)
            if (IsClientInGame(client))
                SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
        PrintToServer("The value of pain_pills_decay_rate is 0, Health buffer display fix is now disabled.");
    }
}

CheckPlayerHealthBuffer(client)
{
    if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return;
    new Float:health = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - 200.0;
    if (health <= 0.0) return;
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 200.0);
    new Float:time = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    time += health / pain_pills_decay_rate;
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", time);
}

UpdateHealthBuffer()
{
    new Float:gameTime = GetGameTime();
    for (new client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
        new Float:health = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (gameTime - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * pain_pills_decay_rate;
        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
        SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", gameTime);
    }
}
