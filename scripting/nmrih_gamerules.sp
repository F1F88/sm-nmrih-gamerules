#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

#include <log4sp>
#undef  REQUIRE_PLUGIN
#include <log4sp/registry>
#define REQUIRE_PLUGIN

#include <nmrih_gamerules>

#define PLUGIN_NAME        "Library NMRiH GameRules"
#define PLUGIN_DESCRIPTION "Library NMRiH GameRules"
#define PLUGIN_VERSION     "1.1.1"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = "F1F88",
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = "https://github.com/F1F88/"
};


#define LIB_GAMERULES_LOGGER_NAME           "lib-gamerules"
#define LIB_GAMERULES_LOGGER_FILE           "logs/lib/gamerules.log"
#define LIB_GAMERULES_LOGGER_MAX_FILE_SIZE  1024 * 1024 * 4         // MB
#define LIB_GAMERULES_LOGGER_MAX_FILES      2


// int OS;
Logger  g_hLogger;

#include "nmrih_gamerules/hooks.sp"


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    /* ------- Load Hooks ------- */
    CreateHooksGlobalForwards();

    return APLRes_Success;
}

public void OnPluginStart()
{
    /* ------- Load GameData ------- */
    GameData gamedata = new GameData("nmrih_gamerules.games");
    if (!gamedata)
        SetFailState("Couldn't find nmrih_gamerules.games gamedata");

    // if ((OS = gamedata.GetOffset("OS")) == -1)
    //     SetFailState("Failed to read gamedata offset of \"OS\"");

    LoadHooks(gamedata);
    delete gamedata;

    /* ------- Load ConVar ------- */
    CreateConVar("sm_lib_nmrih_gamerules_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY | FCVAR_DONTRECORD);

    /* ------- Register Libray ------- */
    RegPluginLibrary("nmrih_gamerules");

    /* ------- Log Debug ------- */
    g_hLogger = CreateLogger();
    g_hLogger.Info("[SM] " ... PLUGIN_NAME ... " (" ... PLUGIN_VERSION ... ") initialize complete!");
}

public void OnAllPluginsLoaded()
{
    if (!LibraryExists("nmrih_gamerules"))
    {
        g_hLogger.Warn("The library \"nmrih_gamerules\" does not exist, NMR_Player.ForceSpawn is unavailable.");
    }

    if (!LoggerRegistry.IsAvailable())
    {
        g_hLogger.Warn("The plugin log4sp_manager is unavailable.");
    }
    else
    {
        LoggerRegistry.Instance().RegisterOrReplaceLogger(g_hLogger);
    }
}

public void OnMapStart()
{
    EnableHooks();
}

public void OnPluginEnd()
{
    if (LoggerRegistry.IsAvailable())
        LoggerRegistry.Instance().Drop(LIB_GAMERULES_LOGGER_NAME);

    delete g_hLogger;
}


static Logger CreateLogger()
{
    char name[] = LIB_GAMERULES_LOGGER_NAME;
    char file[] = LIB_GAMERULES_LOGGER_FILE;
    const int maxFileSize = LIB_GAMERULES_LOGGER_MAX_FILE_SIZE;
    const int maxFiles    = LIB_GAMERULES_LOGGER_MAX_FILES;

    char filename[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filename, sizeof(filename), file);
    RotatingFileSink rotatingFileSink = new RotatingFileSink(filename, maxFileSize, maxFiles);
    ServerConsoleSink serverConsoleSink = new ServerConsoleSink();

    Logger logger = new Logger(name);

#if defined DEBUG || defined _DEBUG
    // 调试模式不考虑性能
    // 记录所有日志，并立即刷写
    logger.SetLevel(LogLevel_Trace);
    logger.SetFlushLevel(LogLevel_Trace);
#else
    // 非调试模式需要保证性能，同时避免日志刷屏控制台
    // 记录 Info 级别以上日志，并按需刷写
    // 控制台仅输出 Warn 级别以上的日志
    serverConsoleSink.SetLevel(LogLevel_Warn);
#endif

    logger.AddSinkAndClose(rotatingFileSink);
    logger.AddSinkAndClose(serverConsoleSink);

    // OnPluginStart 阶段, Error/Fatal 日志可以让插件加载失败
    // 后续 Native、Detour 阶段, Error/Fatal 日志可以在参数校验失败时结束回调
    // 注意: nmrih_player.inc 里纯 sp 实现（不走 native）的 api 需要 log4sp_manager
    //      才能用 logger.Fatal 否则直接使用 ThrowError
    logger.SetThrowLevel(LogLevel_Error);
    return logger;
}
