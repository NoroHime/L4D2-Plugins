#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma semicolon 1
#pragma newdecls required
#define DEBUG 0

#define GETVERSION "3.5"
#define ARRAY_SIZE 5000
#define MAX_PATHS 20

#define DESIRED_ADM_FLAGS ADMFLAG_UNBAN //Edit here the flags to fit your needs!

#define RouteType_Easy		0
#define	RouteType_Medium	1
#define RouteType_Hard		2

char FolderNames[][] = {
	"addons/stripper",
	"addons/stripper/maps",
	"addons/stripper/routing",
	"addons/stripper/plugin_cache"
};

TopMenu g_TopMenuHandle;

int g_iCategory[MAXPLAYERS+1]				= {0};
int g_iSubCategory[MAXPLAYERS+1]			= {0};
int g_iFileCategory[MAXPLAYERS+1]			= {0};
int g_iMoveCategory[MAXPLAYERS+1]			= {0};
int g_iLastObject[MAXPLAYERS+1]			= {-1};
int g_iLastGrabbedObject[MAXPLAYERS+1]	= {-1};

bool g_bSpawned[ARRAY_SIZE]				= {false};
bool g_bGrabbed[ARRAY_SIZE]				= {false};
bool g_bGrab[MAXPLAYERS+1]				= {false};
bool g_bUnsolid[ARRAY_SIZE]				= {false};
bool g_bLoaded							= false;

float g_vecEntityAngles[ARRAY_SIZE][3];
float g_vecLastEntityAngles[MAXPLAYERS+1][3];

char g_sPath[128];

// Global variables to hold menu position
int g_iRotateMenuPosition[MAXPLAYERS+1]			= {0};
int g_iMoveMenuPosition[MAXPLAYERS+1]			= {0};
int g_iVehiclesMenuPosition[MAXPLAYERS+1]		= {0};
int g_iFoliageMenuPosition[MAXPLAYERS+1]		= {0};
int g_iInteriorMenuPosition[MAXPLAYERS+1]		= {0};
int g_iExteriorMenuPosition[MAXPLAYERS+1]		= {0};
int g_iDecorMenuPosition[MAXPLAYERS+1]			= {0};
int g_iMiscMenuPosition[MAXPLAYERS+1]			= {0};

ConVar g_cvarPhysics;
ConVar g_cvarDynamic;
ConVar g_cvarStatic;
ConVar g_cvarVehicles;
ConVar g_cvarFoliage;
ConVar g_cvarInterior;
ConVar g_cvarExterior;
ConVar g_cvarDecorative;
ConVar g_cvarMisc;
ConVar g_cvarLog;
ConVar g_cvarAutoload;
ConVar g_cvarAutoloadType;

public Plugin myinfo = 
{
	name = "[L4D1/2] Objects Spawner",
	author = "honorcode23 & $atanic $pirit & HarryPotter",
	description = "Let admins spawn any kind of objects",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1186503"
}

bool L4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		L4D2Version = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		L4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{	
	LoadTranslations("l4d2_spawn_props.phrases");
	
	CreateConVar("l4d2_spawn_props_version", GETVERSION, "Version of the Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); //Version
	g_cvarPhysics 		= CreateConVar("l4d2_spawn_props_physics", 				"1", "Enable the Physics Objects in the menu");
	g_cvarDynamic 		= CreateConVar("l4d2_spawn_props_dynamic",				"1", "Enable the Dynamic (Non-solid) Objects in the menu");
	g_cvarStatic 		= CreateConVar("l4d2_spawn_props_static",				"1", "Enable the Static (Solid) Objects in the menu");
	g_cvarVehicles 		= CreateConVar("l4d2_spawn_props_category_vehicles",		"1", "Enable the Vehicles category");
	g_cvarFoliage 		= CreateConVar("l4d2_spawn_props_category_foliage",		"1", "Enable the Foliage category");
	g_cvarInterior 		= CreateConVar("l4d2_spawn_props_category_interior",		"1", "Enable the Interior category");
	g_cvarExterior 		= CreateConVar("l4d2_spawn_props_category_exterior",		"1", "Enable the Exterior category");
	g_cvarDecorative 	= CreateConVar("l4d2_spawn_props_category_decorative",	"1", "Enable the Decorative category");
	g_cvarMisc 			= CreateConVar("l4d2_spawn_props_category_misc", 		"1", "Enable the Misc category");
	g_cvarLog 			= CreateConVar("l4d2_spawn_props_log_actions", 			"0", "Log if an admin spawns an object?");
	g_cvarAutoload 		= CreateConVar("l4d2_spawn_props_autoload", 			"0", "Enable the plugin to auto load the cache?");
	g_cvarAutoloadType 	= CreateConVar("l4d2_spawn_props_autoload_different", 	"1", "Should the paths be different for the teams or not?");
	
	RegAdminCmd("sm_spawnprop", CmdSpawnProp, DESIRED_ADM_FLAGS, "Spawns an object with the given information");
	RegAdminCmd("sm_savemap", CmdSaveMap, DESIRED_ADM_FLAGS, "Save all the spawned object in a stripper file");

	RegAdminCmd("sm_prop_rotate", CmdRotate, DESIRED_ADM_FLAGS, "Rotates the last spawned object with the desired angles");
	RegAdminCmd("sm_prop_removelast", CmdRemoveLast, DESIRED_ADM_FLAGS, "Remove last spawned object");
	RegAdminCmd("sm_prop_removelook", CmdRemoveLook, DESIRED_ADM_FLAGS, "Remove the looking object");
	RegAdminCmd("sm_prop_removeall", CmdRemoveAll, DESIRED_ADM_FLAGS, "Remove all objects");
	RegAdminCmd("sm_prop_move", CmdMove, DESIRED_ADM_FLAGS, "Move an object with the desired movement type");
	RegAdminCmd("sm_prop_setang", CmdSetAngles, DESIRED_ADM_FLAGS, "Forces an object angles");
	RegAdminCmd("sm_prop_setpos", CmdSetPosition, DESIRED_ADM_FLAGS, "Sets the last object position");
	
	RegAdminCmd("sm_debugprop", CmdDebugProp, ADMFLAG_ROOT, "DEBUG");
	
	
	AutoExecConfig(true, "l4d2_spawn_props");
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//DEV
	RegAdminCmd("sm_spload", CmdLoad, DESIRED_ADM_FLAGS, "Load map");
	
	//Events
	if(L4D2Version)
	{
		HookEvent("survival_round_start", Event_SurvivalRoundStart);
		HookEvent("scavenge_round_start", Event_ScavengeRoundStart);
	}
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	//Create required folders
	BuildFileDirectories();
}

public Action CmdDebugProp(int client, int args)
{
	char name[256];
	int Object = g_iLastObject[client];
	if(Object > MaxClients && IsValidEntity(Object))
	{
		GetEntPropString(Object, Prop_Data, "m_iName", name, sizeof(name));
		PrintToChat(client, "prop: %s", name);
	}
	return Plugin_Handled;
}

public void Event_SurvivalRoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(g_cvarAutoload.BoolValue && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}

public void Event_ScavengeRoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	LogSpawn("Scavenge Round Has Started");
	if(g_cvarAutoload.BoolValue && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}
public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(g_cvarAutoload.BoolValue && g_cvarAutoloadType.BoolValue)
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}
	LogSpawn("Normal Round Has Started");
	if(g_cvarAutoload.BoolValue && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}

public void Event_RoundEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bLoaded = false;
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void OnMapStart()
{
	for(int i=MaxClients; i < ARRAY_SIZE; i++)
	{
		g_bSpawned[i] = false;
		g_bUnsolid[i] = false;
		g_vecEntityAngles[i][0] = 0.0;
		g_vecEntityAngles[i][1] = 0.0;
		g_vecEntityAngles[i][2] = 0.0;
	}
	if(g_cvarAutoload.BoolValue && !g_cvarAutoloadType.BoolValue)
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}
}

public Action CmdSpawnProp(int client, int args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnprop <model> [static | dynamic | physics] [cursor | origin]");
		return Plugin_Handled;
	}
	char arg1[256];
	char arg2[256];
	char arg3[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	char model[256];
	strcopy(model, sizeof(model), arg1);
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}
	if(StrContains(arg2, "static") >= 0)
	{
		float  VecOrigin[3];
		float VecAngles[3];
		int prop = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
		if(strcmp(arg3, "cursor") == 0)
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(null))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(strcmp(arg3, "origin") == 0)
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		char name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a static object with model <%s>", name, model);
	}
	else if(StrContains(arg2, "dynamic") >= 0)
	{
		float  VecOrigin[3];
		float VecAngles[3];
		int prop = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		if(strcmp(arg3, "cursor") == 0 )
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(null))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(strcmp(arg3, "origin")== 0)
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		g_bUnsolid[prop] = true;
		char name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
	}
	else if(StrContains(arg2, "physics") >= 0)
	{
		float  VecOrigin[3];
		float VecAngles[3];
		int prop = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		if(strcmp(arg3, "cursor")== 0)
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(null))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(strcmp(arg3, "origin")== 0)
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		char name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a physics object with model <%s>", name, model);
	}
	else
	{
		PrintToChat(client, "[SM] Invalid render mode. Use: [static | dynamic | physics]");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Admin Menu ready
public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == g_TopMenuHandle)
	{
		return;
	}
	g_TopMenuHandle = view_as<TopMenu>(topmenu);
	TopMenuObject menu_category_prop = g_TopMenuHandle.AddCategory("Object Spawner", Category_Handler);
	
	if (menu_category_prop != INVALID_TOPMENUOBJECT)
    {
		g_TopMenuHandle.AddItem("sm_spdelete", AdminMenu_Delete, menu_category_prop, "sm_spdelete", DESIRED_ADM_FLAGS); //Delete
		g_TopMenuHandle.AddItem("sm_spedit", AdminMenu_Edit, menu_category_prop, "sm_spedit", DESIRED_ADM_FLAGS); //Edit
		g_TopMenuHandle.AddItem("sm_spspawn", AdminMenu_Spawn, menu_category_prop, "sm_spspawn", DESIRED_ADM_FLAGS); //Spawn
		g_TopMenuHandle.AddItem("sm_spsave", AdminMenu_Save, menu_category_prop, "sm_spsave", DESIRED_ADM_FLAGS); //Save
		g_TopMenuHandle.AddItem("sm_spload", AdminMenu_Load, menu_category_prop, "sm_spload", DESIRED_ADM_FLAGS); //Load
	}
}

//Admin Category Name
public void Category_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Select a task:"));
	}
	else if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Spawn Objects"));
	}
}
/*
////////////////////////////////////////////////////////////////////////////|
						D E L E T E        M E N U							|
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void AdminMenu_Delete(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Delete Object"));
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildDeleteMenu(param);
	}
}

void BuildDeleteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Delete);
	menu.SetTitle("%T", "Select the delete task", client);
	menu.AddItem("sm_spdeleteall", Translate(client, "%t", "Delete All Objects"));
	menu.AddItem("sm_spdeletelook", Translate(client, "%t", "Delete Looking Object"));
	menu.AddItem("sm_spdeletelast", Translate(client, "%t", "Delete Last Object"));
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildDeleteAllAskMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DA_Ask);
	menu.SetTitle("%T", "Are you sure(Delete All)?", client);	
	menu.AddItem("sm_spyes", Translate(client, "%t",  "Yes"));
	menu.AddItem("sm_spno", Translate(client, "%t", "No"));
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DA_Ask(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spyes")== 0)
			{
				DeleteAllProps();
				PrintToChat(param1, "[SM] %T", "Successfully deleted all spawned objects", param1);
			}
			else
			{
				PrintToChat(param1, "[SM] %T", "Canceled", param1);
			}
			BuildDeleteMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_Delete(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spdeleteall")== 0)
			{
				BuildDeleteAllAskMenu(param1);
				PrintToChat(param1, "[SM] %T", "delete all the spawned objects?", param1);
			}
			else if(strcmp(menucmd, "sm_spdeletelook")== 0)
			{
				DeleteLookingEntity(param1);
				BuildDeleteMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spdeletelast")== 0)
			{
				DeleteLastProp(param1);
				BuildDeleteMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/*
////////////////////////////////////////////////////////////////////////////|
						E D I T        M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void AdminMenu_Edit(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Edit Object"));
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildEditPropMenu(param);
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						S P A W N        M E N U							|
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void AdminMenu_Spawn(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Spawn Objects"));
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildSpawnMenu(param);
	}
}

void BuildSpawnMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Spawn);
	menu.SetTitle("%T", "Select the spawn method", client);
	
	if(g_cvarPhysics.BoolValue)
	{
		menu.AddItem("sm_spawnpc", Translate(client, "%t", "Spawn Physics On Cursor"));
		menu.AddItem("sm_spawnpo", Translate(client, "%t", "Spawn Physics On Origin"));
	}
	if(g_cvarDynamic.BoolValue)
	{
		menu.AddItem("sm_spawndc", Translate(client, "%t", "Spawn Non-solid On Cursor"));
		menu.AddItem("sm_spawndo", Translate(client, "%t", "Spawn Non-solid On Origin"));
	}
	if(g_cvarStatic.BoolValue)
	{
		menu.AddItem("sm_spawnsc", Translate(client, "%t", "Spawn Solid On Cursor"));
		menu.AddItem("sm_spawnso", Translate(client, "%t", "Spawn Solid On Origin"));
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Spawn(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spawnpc")== 0)
			{
				BuildPhysicsCursorMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spawnpo")== 0)
			{
				BuildPhysicsPositionMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spawndc")== 0)
			{
				BuildDynamicCursorMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spawndo")== 0)
			{
				BuildDynamicPositionMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spawnsc")== 0)
			{
				BuildStaticCursorMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spawnso")== 0)
			{
				BuildStaticPositionMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/*
////////////////////////////////////////////////////////////////////////////|
						S A V E       M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void AdminMenu_Save(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Save Objects"));
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildSaveMenu(param);
	}
}

void BuildSaveMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Save);
	menu.SetTitle("%T", "Select The Save Method", client);
	menu.AddItem("sm_spsavestripper", Translate(client, "%t", "Save Stripper File"));
	menu.AddItem("sm_spsaverouting", Translate(client, "%t", "Save Routing File"));
	menu.AddItem("sm_spsaveplugin", Translate(client, "%t", "Save Spawn Objects File"));
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildRoutingMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PathDiff);
	menu.SetTitle("%T", "Select Path Difficulty", client);
	menu.AddItem("sm_speasy", Translate(client, "%t", "Easy Path"));
	menu.AddItem("sm_spmedium", Translate(client, "%t", "Medium Path"));
	menu.AddItem("sm_sphard", Translate(client, "%t", "Hard Path"));
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PathDiff(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_speasy")== 0)
			{
				SaveRoutingPath(param1, RouteType_Easy);
			}
			else if(strcmp(menucmd, "sm_spmedium")== 0)
			{
				SaveRoutingPath(param1, RouteType_Medium);
			}
			else if(strcmp(menucmd, "sm_sphard")== 0)
			{
				SaveRoutingPath(param1, RouteType_Hard);
			}
			BuildSaveMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_Save(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spsavestripper")== 0)
			{
				SaveMapStripper(param1);
				BuildSaveMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spsaverouting")== 0)
			{
				BuildRoutingMenu(param1);
			}
			else if(strcmp(menucmd, "sm_spsaveplugin")== 0)
			{
				SavePluginProps(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/*
////////////////////////////////////////////////////////////////////////////|
						L O A D       M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void AdminMenu_Load(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, Translate(param, "%t", "Load Objects"));
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildLoadAskMenu(param);
		PrintToChat(param, "[SM] %T", "load the map data cache?", param);
	}
}

void BuildLoadAskMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Load_Ask);
	menu.SetTitle("%T", "Are you sure?", client);
	menu.AddItem("sm_spyes", Translate(client, "%t", "Yes"));
	menu.AddItem("sm_spno", Translate(client, "%t", "No"));
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildLoadPropsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Load_Props);
	menu.SetTitle("%T", "Choose a map number please", client);
	char buffer[16];
	char buffer2[16];
	for(int i=1; i <= MAX_PATHS; i++)
	{
		Format(buffer, sizeof(buffer), "map%i", i);
		Format(buffer2, sizeof(buffer2), "Map %i", i);
		menu.AddItem(buffer, buffer2);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Load_Props(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			ReplaceString(menucmd, sizeof(menucmd), "map", "", false);
			int number = StringToInt(menucmd);
			LoadPluginProps(param1, number);
			g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_Load_Ask(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spyes")== 0)
			{
				BuildLoadPropsMenu(param1);
			}
			else
			{
				PrintToChat(param1, "[SM] %T", "Canceled", param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/*
////////////////////////////////////////////////////////////////////////////|
						Build Secondary Menus							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/
void BuildPhysicsCursorMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PhysicsCursor);
	CheckSecondaryMenuCategories(menu, client);
}

void BuildPhysicsPositionMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PhysicsPosition);
	CheckSecondaryMenuCategories(menu, client);
}

void BuildDynamicCursorMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DynamicCursor);
	CheckSecondaryMenuCategories(menu, client);
}

void BuildDynamicPositionMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DynamicPosition);
	CheckSecondaryMenuCategories(menu, client);
}
void BuildStaticCursorMenu(int client)
{
	Menu menu = new Menu(MenuHandler_StaticCursor);
	CheckSecondaryMenuCategories(menu, client);
}
void BuildStaticPositionMenu(int client)
{
	Menu menu = new Menu(MenuHandler_StaticPosition);
	CheckSecondaryMenuCategories(menu, client);
}

void CheckSecondaryMenuCategories(Menu menu, int client)
{	
	if(g_cvarVehicles.BoolValue)
	{
		menu.AddItem("vehicles", Translate(client, "%t", "Vehicles"));
	}
	if(g_cvarFoliage.BoolValue)
	{
		menu.AddItem("foliage", Translate(client, "%t", "Foliage"));
	}
	if(g_cvarInterior.BoolValue)
	{
		menu.AddItem("interior", Translate(client, "%t", "Interior"));
	}
	if(g_cvarExterior.BoolValue)
	{
		menu.AddItem("exterior", Translate(client, "%t", "Exterior"));
	}
	if(g_cvarDecorative.BoolValue)
	{
		menu.AddItem("decorative", Translate(client, "%t", "Decorative"));
	}
	if(g_cvarMisc.BoolValue)
	{
		menu.AddItem("misc", Translate(client, "%t", "Misc"));
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	
}

void BuildEditPropMenu(int client)
{
	Menu menu = new Menu(MenuHandler_EditProp);
	menu.SetTitle("%T", "Select an action:", client);
	menu.AddItem("rotate", Translate(client, "%t", "Rotate"));
	menu.AddItem("move", Translate(client, "%t", "Move"));
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PhysicsCursor(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 1;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_PhysicsPosition(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 2;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_DynamicCursor(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 3;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_DynamicPosition(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 4;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;

}

public int MenuHandler_StaticCursor(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 5;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;

}

public int MenuHandler_StaticPosition(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 6;
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "vehicles")== 0)
			{
				DisplayVehiclesMenu(param1);
			}
			else if(strcmp(menucmd, "foliage")== 0)
			{
				DisplayFoliageMenu(param1);
			}
			else if(strcmp(menucmd, "interior")== 0)
			{
				DisplayInteriorMenu(param1);
			}
			else if(strcmp(menucmd, "exterior")== 0)
			{
				DisplayExteriorMenu(param1);
			}
			else if(strcmp(menucmd, "decorative")== 0)
			{
				DisplayDecorativeMenu(param1);
			}
			else if(strcmp(menucmd, "misc")== 0)
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;

}

public int MenuHandler_EditProp(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "rotate")== 0)
			{
				DisplayRotateMenu(param1);
			}
			else if(strcmp(menucmd, "move")== 0)
			{
				DisplayMoveMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && g_TopMenuHandle != null)
			{
				g_TopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

void DisplayVehiclesMenu(int client)
{
	g_iSubCategory[client] =  1;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Vehicles", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iVehiclesMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayFoliageMenu(int client)
{
	g_iSubCategory[client] =  2;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Foliage", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iFoliageMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayInteriorMenu(int client)
{
	g_iSubCategory[client] =  3;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Interior", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iInteriorMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayExteriorMenu(int client)
{
	g_iSubCategory[client] =  4;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Exterior", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iExteriorMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayDecorativeMenu(int client)
{
	g_iSubCategory[client] =  5;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Decorative", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iDecorMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayMiscMenu(int client)
{
	g_iSubCategory[client] =  6;
	Menu menu = new Menu(MenuHandler_DoAction);
	SetFileCategory(menu, client);
	menu.SetTitle("%T", "Misc", client);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iMiscMenuPosition[client], MENU_TIME_FOREVER);
}

void SetFileCategory(Menu menu, int client)
{
	File file;
	char FileName[256];
	char ItemModel[256];
	char ItemTag[256];
	char buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	int len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == null)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(file.ReadLine(buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == 'n')
		{
			buffer[--len] = '0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(strcmp(buffer, "")== 0)
		{
			continue;
		}
		if(g_iFileCategory[client] != g_iSubCategory[client])
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		menu.AddItem(ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	CloseHandle(file);
}

void DisplayRotateMenu(int client)
{
	g_iMoveCategory[client] = 1;
	Menu menu = new Menu(MenuHandler_PropPosition);
	menu.SetTitle("%T", "Rotate", client);
	menu.AddItem("rotate1x", Translate(client, "%t", "Rotate 1 degree (X axys)"));
	menu.AddItem("rotate-1x", Translate(client, "%t", "Back 1 degree (X axys)"));
	menu.AddItem("rotate10x", Translate(client, "%t", "Rotate 10 degree (X axys)"));
	menu.AddItem("rotate-10x", Translate(client, "%t", "Back 10 degree (X axys)"));
	menu.AddItem("rotate15x", Translate(client, "%t", "Rotate 15 degree (X axys)"));
	menu.AddItem("rotate-15x", Translate(client, "%t", "Back 15 degree (X axys)"));
	menu.AddItem("rotate45x", Translate(client, "%t", "Rotate 45 degree (X axys)"));
	menu.AddItem("rotate90x", Translate(client, "%t", "Rotate 90 degree (X axys)"));
	menu.AddItem("rotate180x", Translate(client, "%t", "Rotate 180 degree (X axys)"));
	menu.AddItem("rotate1y", Translate(client, "%t", "Rotate 1 degree (Y axys)"));
	menu.AddItem("rotate-1y", Translate(client, "%t", "Back 1 degree (Y axys)"));
	menu.AddItem("rotate10y", Translate(client, "%t", "Rotate 10 degree (Y axys)"));
	menu.AddItem("rotate-10y", Translate(client, "%t", "Back 10 degree (Y axys)"));
	menu.AddItem("rotate15y", Translate(client, "%t", "Rotate 15 degree (Y axys)"));
	menu.AddItem("rotate-15y", Translate(client, "%t", "Back 15 degree (Y axys)"));
	menu.AddItem("rotate45y", Translate(client, "%t", "Rotate 45 degree (Y axys)"));
	menu.AddItem("rotate90y", Translate(client, "%t", "Rotate 90 degree (Y axys)"));
	menu.AddItem("rotate180y", Translate(client, "%t", "Rotate 180 degree (Y axys)"));
	menu.AddItem("rotate1z", Translate(client, "%t", "Rotate 1 degree (Z axys)"));
	menu.AddItem("rotate-1z", Translate(client, "%t", "Back 1 degree (Z axys)"));
	menu.AddItem("rotate10z", Translate(client, "%t", "Rotate 10 degree (Z axys)"));
	menu.AddItem("rotate-10z", Translate(client, "%t", "Back 10 degree (Z axys)"));
	menu.AddItem("rotate15z", Translate(client, "%t", "Rotate 15 degree (Z axys)"));
	menu.AddItem("rotate-15z", Translate(client, "%t", "Back 15 degree (Z axys)"));
	menu.AddItem("rotate45z", Translate(client, "%t", "Rotate 45 degree (Z axys)"));
	menu.AddItem("rotate90z", Translate(client, "%t", "Rotate 90 degree (Z axys)"));
	menu.AddItem("rotate180z", Translate(client, "%t", "Rotate 180 degree (Z axys)"));
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iRotateMenuPosition[client], MENU_TIME_FOREVER);
}

void DisplayMoveMenu(int client)
{
	g_iMoveCategory[client] = 2;
	Menu menu = new Menu(MenuHandler_PropPosition);
	menu.SetTitle("%T", "Move", client);
	menu.AddItem("moveup1", Translate(client, "%t", "Move Up 1 Unit"));
	menu.AddItem("moveup10", Translate(client, "%t", "Move Up 10 Unit"));
	menu.AddItem("moveup30", Translate(client, "%t", "Move Up 30 Unit"));
	menu.AddItem("movedown1", Translate(client, "%t", "Move Down 1 Unit"));
	menu.AddItem("movedown10", Translate(client, "%t", "Move Down 10 Unit"));
	menu.AddItem("movedown30", Translate(client, "%t", "Move Down 30 Unit"));
	menu.AddItem("moveright1", Translate(client, "%t", "Move Right 1 Unit"));
	menu.AddItem("moveright10", Translate(client, "%t", "Move Right 10 Unit"));
	menu.AddItem("moveright30", Translate(client, "%t", "Move Right 30 Unit"));
	menu.AddItem("moveleft1", Translate(client, "%t", "Move Left 1 Unit"));
	menu.AddItem("moveleft10", Translate(client, "%t", "Move Left 10 Unit"));
	menu.AddItem("moveleft30", Translate(client, "%t", "Move Left 30 Unit"));
	menu.AddItem("moveforward1", Translate(client, "%t", "Move Forward 1 Unit"));
	menu.AddItem("moveforward10", Translate(client, "%t", "Move Forward 10 Unit"));
	menu.AddItem("moveforward30", Translate(client, "%t", "Move Forward 30 Unit"));
	menu.AddItem("movebackward1", Translate(client, "%t", "Move Backward 1 Unit"));
	menu.AddItem("movebackward10", Translate(client, "%t", "Move Backward 10 Unit"));
	menu.AddItem("movebackward30", Translate(client, "%t", "Move Backward 30 Unit"));
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.DisplayAt(client, g_iMoveMenuPosition[client], MENU_TIME_FOREVER);
}

public int MenuHandler_DoAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char model[256];
			GetMenuItem(menu, param2, model, sizeof(model));
			if(!IsModelPrecached(model))
			{
				PrecacheModel(model);
			}
			if(g_iCategory[param1] == 1)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(null))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a physics object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 2)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a physics object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 3)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(null))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			
				g_bSpawned[prop] = true;
				g_bUnsolid[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 4)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_bUnsolid[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 5)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(null))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a static object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 6)
			{
				float  VecOrigin[3];
				float VecAngles[3];
				int prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				char name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a static object with model <%s>", name, model);
			}
			switch(g_iSubCategory[param1])
			{
				case 1:
				{
					g_iVehiclesMenuPosition[param1] = menu.Selection;
					DisplayVehiclesMenu(param1);
				}
				case 2:
				{
					g_iFoliageMenuPosition[param1] = menu.Selection;
					DisplayFoliageMenu(param1);
				}
				case 3:
				{
					g_iInteriorMenuPosition[param1] = menu.Selection;
					DisplayInteriorMenu(param1);
				}
				case 4:
				{
					g_iExteriorMenuPosition[param1] = menu.Selection;
					DisplayExteriorMenu(param1);
					
				}
				case 5:
				{
					g_iDecorMenuPosition[param1] = menu.Selection;
					DisplayDecorativeMenu(param1);
					
				}
				case 6:
				{
					g_iMiscMenuPosition[param1] = menu.Selection;
					DisplayMiscMenu(param1);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				switch(g_iCategory[param1])
				{
					case 1:
					{
						BuildPhysicsCursorMenu(param1);
					}
					case 2:
					{
						BuildPhysicsPositionMenu(param1);
					}
					case 3:
					{
						BuildDynamicCursorMenu(param1);
					}
					case 4:
					{
						BuildDynamicPositionMenu(param1);
					}
					case 5:
					{
						BuildStaticCursorMenu(param1);
					}
					case 6:
					{
						BuildStaticPositionMenu(param1);
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public int MenuHandler_PropPosition(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			switch(g_iMoveCategory[param1])
			{
				case 1:
				{
					if(g_iLastObject[param1] <= 0 || !IsValidEntity(g_iLastObject[param1]))
					{
						PrintToChat(param1, "[SM] The last object is not valid anymore or you haven't spawned anything yet");
						DisplayRotateMenu(param1);
						return 0;
					}
					int Object = g_iLastObject[param1];
					
					float  vecAngles[3];
					vecAngles[0] = g_vecLastEntityAngles[param1][0];
					vecAngles[1] = g_vecLastEntityAngles[param1][1];
					vecAngles[2] = g_vecLastEntityAngles[param1][2];
					
					if(strcmp(menucmd, "rotate1x")== 0)
					{
						vecAngles[0] += 1;
					}
					if(strcmp(menucmd, "rotate-1x")== 0)
					{
						vecAngles[0] -= 1;
					}
					else if(strcmp(menucmd, "rotate10x")== 0)
					{
						vecAngles[0] += 10;
					}
					else if(strcmp(menucmd, "rotate-10x")== 0)
					{
						vecAngles[0] -= 10;
					}
					else if(strcmp(menucmd, "rotate15x")== 0)
					{
						vecAngles[0] += 15;
					}
					else if(strcmp(menucmd, "rotate-15x")== 0)
					{
						vecAngles[0] -= 15;
					}
					else if(strcmp(menucmd, "rotate45x")== 0)
					{
						vecAngles[0] += 45;
					}
					else if(strcmp(menucmd, "rotate90x")== 0)
					{
						vecAngles[0] += 90;
					}
					else if(strcmp(menucmd, "rotate180x")== 0)
					{
						vecAngles[0] += 180;
					}
					else if(strcmp(menucmd, "rotate1y")== 0)
					{
						vecAngles[1] += 1;
					}
					else if(strcmp(menucmd, "rotate-1y")== 0)
					{
						vecAngles[1] -= 1;
					}
					else if(strcmp(menucmd, "rotate10y")== 0)
					{
						vecAngles[1] += 10;
					}
					else if(strcmp(menucmd, "rotate-10y")== 0)
					{
						vecAngles[1] -= 10;
					}
					else if(strcmp(menucmd, "rotate15y")== 0)
					{
						vecAngles[1] += 15;
					}
					else if(strcmp(menucmd, "rotate-15y")== 0)
					{
						vecAngles[1] -= 15;
					}
					else if(strcmp(menucmd, "rotate45y")== 0)
					{
						vecAngles[1] += 45;
					}
					else if(strcmp(menucmd, "rotate90y")== 0)
					{
						vecAngles[1] += 90;
					}
					else if(strcmp(menucmd, "rotate180y")== 0)
					{
						vecAngles[1] += 180;
					}
					else if(strcmp(menucmd, "rotate1z")== 0)
					{
						vecAngles[2] += 1;
					}
					else if(strcmp(menucmd, "rotate-1z")== 0)
					{
						vecAngles[2] -= 1;
					}
					else if(strcmp(menucmd, "rotate10z")== 0)
					{
						vecAngles[2] += 10;
					}
					else if(strcmp(menucmd, "rotate-10z")== 0)
					{
						vecAngles[2] -= 10;
					}
					else if(strcmp(menucmd, "rotate15z")== 0)
					{
						vecAngles[2] += 15;
					}
					else if(strcmp(menucmd, "rotate-15z")== 0)
					{
						vecAngles[2] -= 15;
					}
					else if(strcmp(menucmd, "rotate45z")== 0)
					{
						vecAngles[2] += 45;
					}
					else if(strcmp(menucmd, "rotate90z")== 0)
					{
						vecAngles[2] += 90;
					}
					else if(strcmp(menucmd, "rotate180z")== 0)
					{
						vecAngles[2] += 180;
					}
					
					g_vecLastEntityAngles[param1] = vecAngles;
					TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
					g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					
					g_iRotateMenuPosition[param1] = menu.Selection;
					DisplayRotateMenu(param1);
				}
				case 2:
				{
					if(g_iLastObject[param1] <= 0 || !IsValidEntity(g_iLastObject[param1]))
					{
						PrintToChat(param1, "[SM] The last object is not valid anymore or you haven't spawned anything yet");
						DisplayMoveMenu(param1);
						return 0;
					}
					
					int Object = g_iLastObject[param1];
					float  vecOrigin[3];
					GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
					
					if(strcmp(menucmd, "moveup1")== 0)
					{
						vecOrigin[2]+= 1;
					}
					if(strcmp(menucmd, "moveup10")== 0)
					{
						vecOrigin[2]+= 10;
					}
					if(strcmp(menucmd, "moveup30")== 0)
					{
						vecOrigin[2]+= 30;
					}
					else if(strcmp(menucmd, "movedown1")== 0)
					{
						vecOrigin[2]-= 1;
					}
					else if(strcmp(menucmd, "movedown10")== 0)
					{
						vecOrigin[2]-= 10;
					}
					else if(strcmp(menucmd, "movedown30")== 0)
					{
						vecOrigin[2]-= 30;
					}
					else if(strcmp(menucmd, "moveright1")== 0)
					{
						vecOrigin[1]+= 1;
					}
					else if(strcmp(menucmd, "moveright10")== 0)
					{
						vecOrigin[1]+= 10;
					}
					else if(strcmp(menucmd, "moveright30")== 0)
					{
						vecOrigin[1]+= 30;
					}
					else if(strcmp(menucmd, "moveleft1")== 0)
					{
						vecOrigin[1]-= 1;
					}
					else if(strcmp(menucmd, "moveleft10")== 0)
					{
						vecOrigin[1]-= 10;
					}
					else if(strcmp(menucmd, "moveleft30")== 0)
					{
						vecOrigin[1]-= 30;
					}
					else if(strcmp(menucmd, "moveforward1")== 0)
					{
						vecOrigin[0]+= 1;
					}
					else if(strcmp(menucmd, "moveforward10")== 0)
					{
						vecOrigin[0]+= 10;
					}
					else if(strcmp(menucmd, "moveforward30")== 0)
					{
						vecOrigin[0]+= 30;
					}
					else if(strcmp(menucmd, "movebackward1")== 0)
					{
						vecOrigin[0]-= 1;
					}
					else if(strcmp(menucmd, "movebackward10")== 0)
					{
						vecOrigin[0]-= 10;
					}
					else if(strcmp(menucmd, "movebackward30")== 0)
					{
						vecOrigin[0]-= 30;
					}
					TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					
					g_iMoveMenuPosition[param1] = menu.Selection; 
					DisplayMoveMenu(param1);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				BuildEditPropMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}

void DeleteLookingEntity(int client)
{
	float  VecOrigin[3];
	float VecAngles[3];
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(null))
	{
		int Object = TR_GetEntityIndex(null);
		if(Object > MaxClients && IsValidEntity(Object))
		{
			char class[256];
			GetEdictClassname(Object, class, sizeof(class));
			if(strcmp(class, "prop_physics") == 0
			|| strcmp(class, "prop_dynamic") == 0
			|| strcmp(class, "prop_physics_override") == 0
			|| strcmp(class, "prop_dynamic_override") == 0)
			{
				g_bSpawned[Object] = false;
				g_bUnsolid[Object] = false;
				g_vecEntityAngles[Object][0] = 0.0;
				g_vecEntityAngles[Object][1] = 0.0;
				g_vecEntityAngles[Object][2] = 0.0;

				static char m_ModelName[PLATFORM_MAX_PATH];
				GetEntPropString(Object, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
				PrintToChat(client, "[SM] %T", "Object Model", client, Object, m_ModelName);

				static float position[3];
				GetEntPropVector(Object, Prop_Send, "m_vecOrigin", position);
				PrintToChat(client, "[SM] %T", "Object Position", client, Object, position[0], position[1], position[2]);

				static float angle[3];
				GetEntPropVector(Object, Prop_Data, "m_angRotation", angle);
				PrintToChat(client, "[SM] %T", "Object Angle", client, Object, angle[0], angle[1], angle[2]);

				AcceptEntityInput(Object, "KillHierarchy");
				PrintToChat(client, "[SM] %T", "Successfully removed an object", client, Object);
				if(Object == g_iLastObject[client])
				{
					g_iLastObject[client] = -1;
					g_vecLastEntityAngles[client][0] = 0.0;
					g_vecLastEntityAngles[client][1] = 0.0;
					g_vecLastEntityAngles[client][2] = 0.0;
					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
				}
				if(Object == g_iLastGrabbedObject[client])
				{
					g_iLastGrabbedObject[client] = -1;
				}
				return;
			}
		}
	}

	int Object = GetClientAimTarget(client, false);
	if(Object == -2)
	{
		PrintToChat(client, "[SM] %T","This plugin won't work in this game",client);
		SetFailState("Unhandled Behaviour");
	}
	if(Object > MaxClients && IsValidEntity(Object))
	{
		char class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(strcmp(class, "prop_physics") == 0
		|| strcmp(class, "prop_dynamic") == 0
		|| strcmp(class, "prop_physics_override") == 0
		|| strcmp(class, "prop_dynamic_override") == 0)
		{
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;

			static char m_ModelName[PLATFORM_MAX_PATH];
			GetEntPropString(Object, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
			PrintToChat(client, "[SM] %T", "Object Model", client, Object, m_ModelName);

			static float position[3];
			GetEntPropVector(Object, Prop_Send, "m_vecOrigin", position);
			PrintToChat(client, "[SM] %T", "Object Position", client, Object, position[0], position[1], position[2]);

			static float angle[3];
			GetEntPropVector(Object, Prop_Data, "m_angRotation", angle);
			PrintToChat(client, "[SM] %T", "Object Angle", client, Object, angle[0], angle[1], angle[2]);

			AcceptEntityInput(Object, "KillHierarchy");
			PrintToChat(client, "[SM] %T", "Successfully removed an object", client, Object);

			PrintToChat(client, "[SM] %T", "Successfully removed an object", client, Object);
			if(Object == g_iLastObject[client])
			{
				g_iLastObject[client] = -1;
				g_vecLastEntityAngles[client][0] = 0.0;
				g_vecLastEntityAngles[client][1] = 0.0;
				g_vecLastEntityAngles[client][2] = 0.0;
				if(Object == g_iLastGrabbedObject[client])
				{
					g_iLastGrabbedObject[client] = -1;
				}
			}
			return;
		}
	}
	
	PrintToChat(client, "[SM] %T","You are not looking to a valid object",client);
}

void DeleteAllProps()
{
	CheatCommand(_, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	for(int i=1; i<=MaxClients; i++)
	{
		g_iLastObject[i] = -1;
		g_vecLastEntityAngles[i][0] = 0.0;
		g_vecLastEntityAngles[i][1] = 0.0;
		g_vecLastEntityAngles[i][2] = 0.0;
		g_bGrab[i] = false;
		g_iLastGrabbedObject[i] = -1;
	}
	for(int i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i])
		{
			g_bGrabbed[i] = false;
			g_bSpawned[i] = false;
			g_bUnsolid[i] = false;
			g_vecEntityAngles[i][0] = 0.0;
			g_vecEntityAngles[i][1] = 0.0;
			g_vecEntityAngles[i][2] = 0.0;
			if(IsValidEntity(i))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

void CheatCommand(int client = 0, char[] command, char[] arguments="")
{
	if (!client || !IsClientInGame(client))
	{
		for (int target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

//Disabled right now
void DeleteLastProp(int client)
{
	int Object = g_iLastObject[client];
	if(Object > MaxClients && IsValidEntity(Object))
	{
		char class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(strcmp(class, "prop_physics") == 0
		|| strcmp(class, "prop_dynamic") == 0
		|| strcmp(class, "prop_physics_override") == 0
		|| strcmp(class, "prop_dynamic_override") == 0)
		{
			AcceptEntityInput(g_iLastObject[client], "KillHierarchy");
			PrintToChat(client, "[SM] %T","Succesfully deleted the last spawned object",client);
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
			g_bGrabbed[Object] = false;
			if(Object == g_iLastGrabbedObject[client])
			{
				g_iLastGrabbedObject[client] = -1;
			}
			return;
		}
		else
		{
			PrintToChat(client, "[SM] %T", "The last spawned object index is not an object anymore!", client, Object);
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] %T","The last object is not valid anymore",client);
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] %T","You haven't spawned anything yet",client);
	}
}

void LogSpawn(const char[] format, any ...)
{
	if(!g_cvarLog.BoolValue)
	{
		return;
	}
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	File file;
	char FileName[256];
	char sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/objects_%s.log", sTime);
	file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%b %d |%H:%M:%S| %Y");
	file.WriteLine("%s: %s", sTime, buffer);
	FlushFile(file);
	CloseHandle(file);
}

public Action CmdSaveMap(int client, int args)
{
	SaveMapStripper(client);
	return Plugin_Handled;
}

void SaveMapStripper(int client)
{
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> was called by %N", client);
	#endif
	LogSpawn("%N saved the objects for this map on a 'Stripper' file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	char FileName[256];
	char map[256];
	char classname[256];
	File file;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "../stripper/maps/%s.cfg", map);
	
	if(FileExists(FileName))
	{
		PrintHintText(client, "%T", "The file already exists.", client);
	}
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> File stated, proceed");
	#endif
	file = OpenFile(FileName, "a+");
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> File Opened, proceed");
	#endif
	if(file == null)
	{
		#if DEBUG
		LogSpawn("[DEBUG] <SaveMapStripper> File Invalid, proceed");
		#endif
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing addons/stripper folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	
	float  vecOrigin[3];
	float vecAngles[3];
	char sModel[256];
	char sTime[256];
	int iOrigin[3], iAngles[3];
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	file.WriteLine(";----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	file.WriteLine(";----------BY: %N----------------------||", client);
	file.WriteLine("");
	file.WriteLine("add:");
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> Wrote first information line");
	#endif
	for(int i=MaxClients; i < ARRAY_SIZE; i++)
	{
		#if DEBUG
		LogSpawn("[DEBUG] <SaveMapStripper> CHECK: %i", i);
		#endif
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			#if DEBUG
			LogSpawn("[DEBUG] <SaveMapStripper> Possible Entity Found: %i <%s>", i, classname);
			#endif
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				file.WriteLine("{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						file.WriteLine("	\"solid\" \"0\"");
					}
					else
					{
						file.WriteLine("	\"solid\" \"6\"");
					}
				}
				file.WriteLine("	\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				file.WriteLine("	\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				file.WriteLine("	\"model\"	 \"%s\"", sModel);
				file.WriteLine("	\"classname\"	\"%s\"", classname);
				file.WriteLine("}");
				file.WriteLine("");
				#if DEBUG
				LogSpawn("[DEBUG] <SaveMapStripper> END: %i", i);
				#endif
			}
		}
	}
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> Wrote all entities");
	#endif
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] %T (%s)", "Succesfully saved the map data", client, FileName);
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> END");
	#endif
}

void SaveRoutingPath(int client, int type)
{
	#if DEBUG
	LogSpawn("[DEBUG] <SaveRoutingPath> was called by %N", client);
	#endif
	LogSpawn("%N saved the objects for this map on a \"Routing\" file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	char FileName[256];
	char map[256];
	char classname[256];
	char targetname[256];
	File file;
	bool Exists = false;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "../stripper/routing/%s.cfg", map);
	if(FileExists(FileName))
	{
		PrintHintText(client, "%T", "The file already exists.", client);
		Exists = true;
	}
	file = OpenFile(FileName, "a+");
	if(file == null)
	{
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing addons/stripper/maps/routing folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	float  vecOrigin[3];
	float vecAngles[3];
	char sModel[256];
	char sTime[256];
	int iOrigin[3], iAngles[3];
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	file.WriteLine(";----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	file.WriteLine(";----------BY: %N----------------------||", client);
	file.WriteLine("");
	switch(type)
	{
		case RouteType_Easy:
		{
			file.WriteLine(";This part was generated for an \"Easy\" routing path.");
			Format(targetname, sizeof(targetname), "easy_route_blocker");
		}
		case RouteType_Medium:
		{
			file.WriteLine(";This part was generated for a \"Medium\" routing path.");
			Format(targetname, sizeof(targetname), "medium_route_blocker");
		}
		case RouteType_Hard:
		{
			file.WriteLine(";This part was generated for a \"Hard\" routing path.");
			Format(targetname, sizeof(targetname), "hard_route_blocker");
		}
	}
	file.WriteLine("");
	file.WriteLine("add:");
	
	if(!Exists)
	{
		//First, wee add the necessary relays
		
		file.WriteLine("; plugin trigger relay");
		file.WriteLine("; will get fired by Plugin ONLY IN VERSUS, so it doesnt break coop");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"spawnflags\" \"1\"");
		file.WriteLine("	\"targetname\" \"relay_routing_init\"");
		file.WriteLine("	\"classname\" \"logic_relay\"");
		file.WriteLine("	");
		file.WriteLine("	; destroy Valve routing entities so they dont interfere");
		file.WriteLine("	");
		file.WriteLine("	\"OnTrigger\" \"director_queryKill0-1\"");
		file.WriteLine("}");
		file.WriteLine("");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"spawnflags\" \"1\"");
		file.WriteLine("	\"targetname\" \"relay_routing_disabledbydefault\"");
		file.WriteLine("	\"classname\" \"logic_auto\"");
		file.WriteLine("	");
		file.WriteLine("	\"OnMapSpawn\" \"easy_route_blockerDisable0-1\"");
		file.WriteLine("	\"OnMapSpawn\" \"easy_route_blockerDisableCollision0-1\"");
		file.WriteLine("	\"OnMapSpawn\" \"medium_route_blockerDisable0-1\"");
		file.WriteLine("	\"OnMapSpawn\" \"medium_route_blockerDisableCollision0-1\"");
		file.WriteLine("	\"OnMapSpawn\" \"hard_route_blockerDisable0-1\"");
		file.WriteLine("	\"OnMapSpawn\" \"hard_route_blockerDisableCollision0-1\"");
		file.WriteLine("}");
		file.WriteLine("; config existence checking entity");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"targetname\" \"map_has_routing\"");
		file.WriteLine("	\"noise\" \"0\"");
		file.WriteLine("	\"minAngerRange\" \"1\"");
		file.WriteLine("	\"maxAngerRange\" \"10\"");
		file.WriteLine("	\"classname\" \"logic_director_query\"");
		file.WriteLine("	\"OutAnger\" \"DoHeadBangInValue0-1\"");
		file.WriteLine("}");
		file.WriteLine("");
		file.WriteLine("; easy path");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"targetname\" \"relay_easy_route_spawn\"");
		file.WriteLine("	\"spawnflags\" \"0\"");
		file.WriteLine("	\"classname\" \"logic_relay\"");
		file.WriteLine("	\"OnTrigger\" \"easy_route_blockerEnable0-1\"");
		file.WriteLine("	\"OnTrigger\" \"easy_route_blockerEnableCollision0-1\"");
		file.WriteLine("}");
		file.WriteLine("");
		file.WriteLine("; medium path");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"targetname\" \"relay_medium_route_spawn\"");
		file.WriteLine("	\"spawnflags\" \"0\"");
		file.WriteLine("	\"classname\" \"logic_relay\"");
		file.WriteLine("	\"OnTrigger\" \"medium_route_blockerEnable0-1\"");
		file.WriteLine("	\"OnTrigger\" \"medium_route_blockerEnableCollision0-1\"");
		file.WriteLine("}");
		file.WriteLine("");
		file.WriteLine("; hard path");
		file.WriteLine("{");
		file.WriteLine("	\"origin\" \"0 0 0\"");
		file.WriteLine("	\"targetname\" \"relay_hard_route_spawn\"");
		file.WriteLine("	\"spawnflags\" \"0\"");
		file.WriteLine("	\"classname\" \"logic_relay\"");
		file.WriteLine("	\"OnTrigger\" \"hard_route_blockerEnable0-1\"");
		file.WriteLine("	\"OnTrigger\" \"hard_route_blockerEnableCollision0-1\"");
		file.WriteLine("}");
		file.WriteLine("");
	}
	for(int i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				file.WriteLine("{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						file.WriteLine("	\"solid\" \"0\"");
					}
					else
					{
						file.WriteLine("	\"solid\" \"6\"");
					}
				}
				file.WriteLine("	\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				file.WriteLine("	\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				file.WriteLine("	\"model\"	 \"%s\"", sModel);
				file.WriteLine("	\"targetname\" \"%s\"", targetname);
				file.WriteLine("	\"classname\"	\"%s\"", classname);
				file.WriteLine("}");
				file.WriteLine("");
			}
		}
	}
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] %T (%s)", "Succesfully saved the map data", client, FileName);
}

void SavePluginProps(int client)
{
	LogSpawn("%N saved the objects for this map on a \"Plugin Cache\" file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	char FileName[256];
	char map[256];
	char classname[256];
	char FileNameS[256];
	char FileNameT[256];
	File file;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileNameS, sizeof(FileNameS), "../stripper/plugin_cache/%s", map);
	Format(FileName, sizeof(FileName), "%s_1.txt", FileNameS);
	int map_number = 0;
	if(FileExists(FileName))
	{
		map_number = GetNextMapNumber(FileNameS);
		if(map_number <= 0)
		{
			PrintToChat(client, "\x04[SM] Fatal Error: Too Many path files for this map! (Max: %i)", MAX_PATHS);
			return;
		}
		Format(FileNameT, sizeof(FileNameT), "%s_%i.txt", FileNameS, map_number);
	}
	else
	{
		Format(FileNameT, sizeof(FileNameT), "%s_1.txt", FileNameS);
	}
	file = OpenFile(FileNameT, "a+");
	if(file == null)
	{
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing addons/stripper/maps/plugin_cache folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	CreateInitFile();
	float  vecOrigin[3];
	float vecAngles[3];
	char sModel[256];
	char sTime[256];
	int iOrigin[3], iAngles[3];
	int count = 0;
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	file.WriteLine("//----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	file.WriteLine("//----------BY: %N----------------------||", client);
	file.WriteLine("");
	file.WriteLine("\"Objects_Cache\"");
	file.WriteLine("{");
	for(int i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				count++;
				
				file.WriteLine("	\"object_%i\"", count);
				file.WriteLine("	{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						file.WriteLine("		\"solid\" \"0\"");
					}
					else
					{
						file.WriteLine("		\"solid\" \"6\"");
					}
				}
				file.WriteLine("		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				file.WriteLine("		\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				file.WriteLine("		\"model\"	 \"%s\"", sModel);
				file.WriteLine("		\"classname\"	\"%s\"", classname);
				file.WriteLine("	}");
				file.WriteLine("	");
			}
		}
	}
	file.WriteLine("	\"total_cache\"");
	file.WriteLine("	{");
	file.WriteLine("		\"total\" \"%i\"", count);
	file.WriteLine("	}");
	file.WriteLine("}");
	
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] %T (%s)", "Succesfully saved the map data", client, FileNameT);
}

public Action CmdLoad(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Specify a map number");
	}
	char arg[5];
	GetCmdArgString(arg, sizeof(arg));
	int number = StringToInt(arg);
	LoadPluginProps(client, number);
	return Plugin_Handled;
}

void LoadPluginProps(int client, int number)
{
	LogSpawn("%N loaded the objects for this map", client);
	PrintToChat(client, "\x04[SM] Loading content. Please Wait");
	char KvFileName[256];
	char map[256];
	char name[256];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "../stripper/plugin_cache/%s_%i.txt", map, number);
	if(!FileExists(KvFileName))
	{
		PrintToChat(client, "\x04[SM] The file does not exist");
		PrintHintText(client, "\x04[SM] The file does not exist");
		return;
	}
	KeyValues keyvalues = new KeyValues("Objects_Cache");
	keyvalues.ImportFromFile(KvFileName);
	keyvalues.Rewind();
	if(keyvalues.JumpToKey("total_cache"))
	{
		int max = keyvalues.GetNum("total", 0);
		if(max <= 0)
		{
			PrintToChat(client, "\x04[SM] No objects found in the cache");
			return;
		}
		char model[256];
		char class[64];
		float vecOrigin[3];
		float vecAngles[3];
		int solid;
		keyvalues.Rewind();
		for(int count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(keyvalues.JumpToKey(name))
			{
				solid = keyvalues.GetNum("solid");
				keyvalues.GetVector("origin", vecOrigin);
				keyvalues.GetVector("angles", vecAngles);
				keyvalues.GetString("model", model, sizeof(model));
				keyvalues.GetString("classname", class, sizeof(class));
				int prop = -1;
				keyvalues.Rewind();
				if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
				}
				else
				{
					prop = CreateEntityByName("prop_dynamic_override");
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
				}
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				
				g_vecLastEntityAngles[client][0] = vecAngles[0];
				g_vecLastEntityAngles[client][1] = vecAngles[1];
				g_vecLastEntityAngles[client][2] = vecAngles[2];
				DispatchKeyValueVector(prop, "angles", vecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = vecAngles;				
			}
			else
			{
				break;
			}
		}
	}
	CloseHandle(keyvalues);
	PrintToChat(client, "\x03[SM] Succesfully loaded the map data");
	PrintHintText(client, "[SM] If nothing is visible, you probably forgot something during installation");
}

public Action CmdRotate(int client, int args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_rotate <axys> <angles> [EX: !prop_rotate x 30]");
		return Plugin_Handled;
	}
	int Object = g_iLastObject[client];
	char arg1[16];
	char arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	float  vecAngles[3];
	vecAngles[0] = g_vecLastEntityAngles[client][0];
	vecAngles[1] = g_vecLastEntityAngles[client][1];
	vecAngles[2] = g_vecLastEntityAngles[client][2];
	int iAngles = StringToInt(arg2);
	if(strcmp(arg1, "x")== 0)
	{
		vecAngles[0] += iAngles;
	}
	else if(strcmp(arg1, "y")== 0)
	{
		vecAngles[1] += iAngles;
	}
	else if(strcmp(arg1, "z")== 0)
	{
		vecAngles[2] += iAngles;
	}
	else
	{
		PrintToChat(client, "[SM] Invalid Axys (x,y,z are allowed)");
	}
	g_vecLastEntityAngles[client] = vecAngles;
	TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
	g_vecEntityAngles[g_iLastObject[client]] = vecAngles;
	return Plugin_Handled;
}

public Action CmdRemoveLast(int client, int args)
{
	DeleteLastProp(client);
	return Plugin_Handled;
}

public Action CmdRemoveLook(int client, int args)
{
	DeleteLookingEntity(client);
	return Plugin_Handled;
}

public Action CmdRemoveAll(int client, int args)
{
	PrintToChat(client, "\x04[SM] %T","Are you sure(Delete All)?",client);
	BuildDeleteAllCmd(client);
	return Plugin_Handled;
}

void BuildDeleteAllCmd(int client)
{
	Menu menu = new Menu(MenuHandler_cmd_Ask);
	menu.SetTitle("%T", "Are you sure?", client);
	menu.AddItem("sm_spyes", Translate(client, "%t", "Yes"));
	menu.AddItem("sm_spno", Translate(client, "%t", "No"));
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_cmd_Ask(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(strcmp(menucmd, "sm_spyes")== 0)
			{
				DeleteAllProps();
				PrintToChat(param1, "[SM] %T", "Successfully deleted all spawned objects", param1);
			}
			else
			{
				PrintToChat(param1, "[SM] %T", "Canceled", param1);
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

int GetNextMapNumber(char[] FileName)
{
	char FileNameS[256];
	for(int i=1; i <= MAX_PATHS; i++)
	{
		Format(FileNameS, sizeof(FileNameS), "%s_%i.txt", FileName, i);
		if(FileExists(FileNameS))
		{
			continue;
		}
		else
		{
			return i;
		}
	}
	return -1;
}

void SpawnObjects()
{
	//if disabled
	if(!g_cvarAutoload.BoolValue)
	{
		return;
	}
	char KvFileName[256];
	char name[256];
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "../stripper/plugin_cache/%s.txt", g_sPath);
	LogSpawn("Spawning props from file %s", KvFileName);
	if(!FileExists(KvFileName))
	{
		LogError("Attempted to load an object file which does not exist (%s)", KvFileName);
		LogSpawn("[ERROR] Attempted to load an object file which does not exist (%s)", KvFileName);
		return;
	}
	KeyValues keyvalues = new KeyValues("Objects_Cache");
	keyvalues.ImportFromFile(KvFileName);
	keyvalues.Rewind();
	if(keyvalues.JumpToKey("total_cache"))
	{
		int max = keyvalues.GetNum("total", 0);
		if(max <= 0)
		{
			LogError("No Objects found for the map number cache");
			LogSpawn("[ERROR] No Objects found for the map number cache");
			return;
		}
		char model[256];
		char class[64];
		float vecOrigin[3];
		float vecAngles[3];
		int solid;
		keyvalues.Rewind();
		for(int count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(keyvalues.JumpToKey(name))
			{
				solid = keyvalues.GetNum("solid");
				keyvalues.GetVector("origin", vecOrigin);
				keyvalues.GetVector("angles", vecAngles);
				keyvalues.GetString("model", model, sizeof(model));
				keyvalues.GetString("classname", class, sizeof(class));
				int prop = -1;
				keyvalues.Rewind();
				if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
				}
				else
				{
					prop = CreateEntityByName("prop_dynamic_override");
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
				}
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				
				DispatchKeyValueVector(prop, "angles", vecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = vecAngles;				
			}
			else
			{
				break;
			}
		}
	}
	CloseHandle(keyvalues);
}
void CreateInitFile()
{
	char FileName[256];
	char map[256];
	File file;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "../stripper/plugin_cache/%s_init.txt", map);
	
	if(!FileExists(FileName))
	{
		file = OpenFile(FileName, "a+");
		if(file == null)
		{
			return;
		}
		file.WriteLine("//Init file for map %s", map);
		file.WriteLine("//DO NOT FORGET TO REPLACE \" FOR QUOTES!");
		file.WriteLine("//");
		file.WriteLine("//The format of the file is:");
		file.WriteLine("//");
		file.WriteLine("//	\"coop\" --------> This is the gamemode where the following object list will be loaded");
		file.WriteLine("//	{");
		file.WriteLine("//		\"total\"	\"2\" ---------> This is the total object list availables. Randomly, one will be selected");
		file.WriteLine("//		\"path1\"	\"c5m2_park_1\" -------------> If the plugin chooses the option 1, the file c5m2_park_1.txt will be loaded");
		file.WriteLine("//		\"path2\"	\"c5m2_park_3\" -------------> Same if the option is 2");
		file.WriteLine("//	}");
		file.WriteLine("//");
		file.WriteLine("// If you have any doubts, please check the example_init.txt file or ask on the plugin topic.");
		file.WriteLine("//");
		file.WriteLine("");
		file.WriteLine("\"PathInit\"");
		file.WriteLine("{");
		file.WriteLine("	\"coop\"");
		file.WriteLine("	{");
		file.WriteLine("		");
		file.WriteLine("	}");
		file.WriteLine("	");
		file.WriteLine("	\"versus\"");
		file.WriteLine("	{");
		file.WriteLine("		");
		file.WriteLine("	}");
		file.WriteLine("	");
		file.WriteLine("	\"survival\"");
		file.WriteLine("	{");
		file.WriteLine("		");
		file.WriteLine("	}");
		file.WriteLine("	");
		file.WriteLine("	\"scavenge\"");
		file.WriteLine("	{");
		file.WriteLine("		");
		file.WriteLine("	}");
		file.WriteLine("}");
		FlushFile(file);
		CloseHandle(file);
	}
}

void GetRandomMapPath(char[] MapName, int maxlen)
{
	char KvFileName[256];
	char sMap[128];
	char GameMode[128];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "../stripper/plugin_cache/%s_init.txt", sMap);
	if(!FileExists(KvFileName))
	{
		LogError("Unable to find the init file!");
	}
	else
	{
		KeyValues keyvalues = new KeyValues("PathInit");
		keyvalues.ImportFromFile(KvFileName);
		keyvalues.Rewind();
		ConVar cvarGameMode = FindConVar("mp_gamemode");
		cvarGameMode.GetString(GameMode, sizeof(GameMode));
		if(keyvalues.JumpToKey(GameMode))
		{
			char sNumber[11];
			int total_paths = keyvalues.GetNum("total");
			int random = GetRandomInt(1, total_paths);
			Format(sNumber, sizeof(sNumber), "path%i", random);
			keyvalues.GetString(sNumber, MapName, maxlen);
			CloseHandle(keyvalues);
			return;
		}
		else
		{
			LogError("Unable to find the gamemode");
			Format(MapName, maxlen, "invalid");
			CloseHandle(keyvalues);
			return;
		}
		
	}
	Format(MapName, maxlen, "invalid");
	return;
}

public Action CmdMove(int client, int args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_move <axys> <distance> [EX: !prop_move x 30]");
		return Plugin_Handled;
	}
	int Object = g_iLastObject[client];
	char arg1[16];
	char arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	float  vecPosition[3];
	GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecPosition);
	float flPosition = StringToFloat(arg2);
	if(strcmp(arg1, "x")== 0)
	{
		vecPosition[0] += flPosition;
	}
	else if(strcmp(arg1, "y")== 0)
	{
		vecPosition[1] += flPosition;
	}
	else if(strcmp(arg1, "z")== 0)
	{
		vecPosition[2] += flPosition;
	}
	else
	{
		PrintToChat(client, "[SM] Invalid Axys (x,y,z are allowed)");
	}
	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	TeleportEntity(Object, vecPosition, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action CmdSetAngles(int client, int args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_setang <X Y Z> [EX: !prop_setang 30 0 34");
		return Plugin_Handled;
	}
	int Object = g_iLastObject[client];
	char arg1[16];
	char arg2[16];
	char arg3[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	float  vecAngles[3];
	
	vecAngles[0] = StringToFloat(arg1);
	vecAngles[1] = StringToFloat(arg2);
	vecAngles[2] = StringToFloat(arg3);
	g_vecLastEntityAngles[client] = vecAngles;
	g_vecEntityAngles[Object] = vecAngles;
	
	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
	return Plugin_Handled;
}

public Action CmdSetPosition(int client, int args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_setpos <X Y Z> [EX: !prop_setpos 505 -34 17");
		return Plugin_Handled;
	}
	int Object = g_iLastObject[client];
	char arg1[16];
	char arg2[16];
	char arg3[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	float  vecPosition[3];
	
	vecPosition[0] = StringToFloat(arg1);
	vecPosition[1] = StringToFloat(arg2);
	vecPosition[2] = StringToFloat(arg3);
	TeleportEntity(Object, vecPosition, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

/*
////////////////////////////////////////////////////////////////////////////|
						Build File Directories							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public void BuildFileDirectories()
{
	for(int Num; Num < sizeof(FolderNames); Num++)
	{
		if(!DirExists(FolderNames[Num]))
		{
			CreateDirectory(FolderNames[Num], 509);
		}
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}