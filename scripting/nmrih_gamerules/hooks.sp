#pragma newdecls required
#pragma semicolon 1

enum
{
    HOK_GetPlayerSpawnSpot,

    HOK_Total
}

enum
{
    FWD_GetPlayerSpawnSpot,
    FWD_GetPlayerSpawnSpotPost,

    FWD_Total
}

static DynamicHook hHooks[HOK_Total];
static GlobalForward hGlobalForwards[FWD_Total];


void CreateHooksGlobalForwards()
{
    hGlobalForwards[FWD_GetPlayerSpawnSpot]     = new GlobalForward("OnGameRulesGetPlayerSpawnSpot",        ET_Hook,    Param_CellByRef, Param_CellByRef);
    hGlobalForwards[FWD_GetPlayerSpawnSpotPost] = new GlobalForward("OnGameRulesGetPlayerSpawnSpotPost",    ET_Ignore,  Param_Cell, Param_Cell);
}

void LoadHooks(GameData gamedata)
{
    hHooks[HOK_GetPlayerSpawnSpot] = LoadHook(gamedata, "CGameRules::GetPlayerSpawnSpot");
}

// Map End 会自动移除 Hook
// 需要在 Map Start 再次 Hook
void EnableHooks()
{
    EnableHook(hHooks[HOK_GetPlayerSpawnSpot], GetPlayerSpawnSpot, GetPlayerSpawnSpotPost);
}

static DynamicHook LoadHook(Handle gamedata, const char[] name)
{
    DynamicHook hook = DynamicHook.FromConf(gamedata, name);
    if (hook == null)
        SetFailState("Failed to setup hook for Functions \"%s\"", name);
    return hook;
}

static void EnableHook(DynamicHook hook, DHookCallback PreCB, DHookCallback PostCB)
{
    if (!hook.HookGamerules(Hook_Pre, PreCB))
        log.ThrowError(LogLevel_Fatal, "Failed to hook game rules");

    if (!hook.HookGamerules(Hook_Post, PostCB))
        log.ThrowError(LogLevel_Fatal, "Failed to hook game rules Post");
}


static MRESReturn GetPlayerSpawnSpot(DHookReturn hReturn, DHookParam hParams)
{
    int player = hParams.Get(1);
    int returnValue = hReturn.Value;
    log.TraceEx("GetPlayerSpawnSpot (player %d) (return %d)", player, returnValue);


    Action result;
    Call_StartForward(hGlobalForwards[FWD_GetPlayerSpawnSpot]);
    Call_PushCellRef(player);
    Call_PushCellRef(returnValue);
    Call_Finish(result);

    if (result == Plugin_Continue)
        return MRES_Ignored;

    hParams.Set(1, player);
    hReturn.Value = returnValue;

    log.TraceEx("GetPlayerSpawnSpot Changed %d | player = %d return = %d", result, player, returnValue);

    if (result == Plugin_Changed)
        return MRES_Override;

    return MRES_Supercede;
}

static MRESReturn GetPlayerSpawnSpotPost(DHookReturn hReturn, DHookParam hParams)
{
    int player = hParams.Get(1);
    int returnValue = hReturn.Value;
    log.TraceEx("GetPlayerSpawnSpotPost (player %d) (return %d)", player, returnValue);

    Call_StartForward(hGlobalForwards[FWD_GetPlayerSpawnSpotPost]);
    Call_PushCell(player);
    Call_PushCell(returnValue);
    Call_Finish();

    return MRES_Ignored;
}
