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
    g_hLogger.Trace("LoadHooks called.");
    hHooks[HOK_GetPlayerSpawnSpot] = LoadHook(gamedata, "CGameRules::GetPlayerSpawnSpot");
}

// Map End 会自动移除 Hook
// 需要在 Map Start 再次 Hook
void EnableHooks()
{
    g_hLogger.Trace("EnableHooks called.");

    EnableHook(HOK_GetPlayerSpawnSpot, GetPlayerSpawnSpot, GetPlayerSpawnSpotPost);
}

static DynamicHook LoadHook(Handle gamedata, const char[] name)
{
    DynamicHook hook = DynamicHook.FromConf(gamedata, name);
    if (hook == null)
        g_hLogger.FatalF("Failed to setup hook for Functions \"%s\".", name);
    else
        g_hLogger.DebugF("Setup hook for Functions \"%s\".", name);
    return hook;
}

static void EnableHook(int index, DHookCallback PreCB, DHookCallback PostCB)
{
    if (index < 0 || index >= sizeof(hHooks))
        g_hLogger.FatalF("Invalid hHooks index %d.", index);

    DynamicHook hook = hHooks[index];
    {
        int id = hook.HookGamerules(Hook_Pre, PreCB, OnDHookRemoval);
        if (id == INVALID_HOOK_ID)
            g_hLogger.FatalF("Failed to enable hook (index %d).", index);
        else
            g_hLogger.DebugF("Enable hook %d (index %d).", id, index);
    }

    {
        int id = hook.HookGamerules(Hook_Post, PostCB, OnDHookRemoval);
        if (id == INVALID_HOOK_ID)
            g_hLogger.FatalF("Failed to enable hook post (index %d).", index);
        else
            g_hLogger.DebugF("Enable hook post %d (index %d).", id, index);
    }
}


static MRESReturn GetPlayerSpawnSpot(DHookReturn hReturn, DHookParam hParams)
{
    g_hLogger.TraceF("GetPlayerSpawnSpot (hReturn %d) (hParams %d).", hReturn, hParams);

    int player = hParams.Get(1);
    int returnValue = hReturn.Value;
    g_hLogger.DebugF("GetPlayerSpawnSpot (player %d) (return %d).", player, returnValue);

    Action result;
    Call_StartForward(hGlobalForwards[FWD_GetPlayerSpawnSpot]);
    Call_PushCellRef(player);
    Call_PushCellRef(returnValue);
    Call_Finish(result);

    if (result == Plugin_Continue)
        return MRES_Ignored;

    hParams.Set(1, player);
    hReturn.Value = returnValue;

    g_hLogger.DebugF("GetPlayerSpawnSpot Changed! (result %d) (player %d) (return %d).", result, player, returnValue);

    if (result == Plugin_Changed)
        return MRES_Override;

    return MRES_Supercede;
}

static MRESReturn GetPlayerSpawnSpotPost(DHookReturn hReturn, DHookParam hParams)
{
    g_hLogger.TraceF("GetPlayerSpawnSpotPost (hReturn %d) (hParams %d).", hReturn, hParams);

    int player = hParams.Get(1);
    int returnValue = hReturn.Value;
    g_hLogger.DebugF("GetPlayerSpawnSpotPost (player %d) (return %d).", player, returnValue);

    Call_StartForward(hGlobalForwards[FWD_GetPlayerSpawnSpotPost]);
    Call_PushCell(player);
    Call_PushCell(returnValue);
    Call_Finish();

    return MRES_Ignored;
}

static void OnDHookRemoval(int hookid)
{
    g_hLogger.DebugF("Hook %d removed.", hookid);
}
