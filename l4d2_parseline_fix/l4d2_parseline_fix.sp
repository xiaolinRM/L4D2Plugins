#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 4

#include <sourcemod>
#include <sdktools>

#define REQUIRE_EXTENSIONS
#include <sourcescramble>

#define PLUGIN_VERSION	"1.0"
#define GAMEDATA "l4d2_parseline_fix"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion CurrentEngine = GetEngineVersion();
	if(CurrentEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] Parse Line Fix",
	author = "xiaolinRM",
	description = "Fix non ASCII characters in cfg file that cannot be executed.",
	version = PLUGIN_VERSION,
	url = "https://github.com/xiaolinRM/L4D2Plugins/tree/main/l4d2_parseline_fix"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_parseline_fix", PLUGIN_VERSION, "Parse Line Fix Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData) SetFailState("Failed to load gamedata: \"%s.txt\"", GAMEDATA);
	
	MemoryPatch patcher = MemoryPatch.CreateFromConf(hGameData, "ParseLine_Patch");
	if (!patcher.Validate()) SetFailState("Failed to validate patch \"ParseLine_Patch\"");
	if (!patcher.Enable()) SetFailState("Failed to enable patch \"ParseLine_Patch\"");

	PrintToServer("Enabled \"ParseLine_Patch\" patch");
	delete hGameData;
}
