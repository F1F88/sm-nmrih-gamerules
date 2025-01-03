#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

// All
#define LOG4SP_NO_EXT
#include <log4sp>
#include <nmrih_gamerules>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME        "Library NMRiH GameRules"
#define PLUGIN_DESCRIPTION "Library NMRiH GameRules"
#define PLUGIN_VERSION     "1.0.0"

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
#define LIB_GAMERULES_LOGGER_LEVEL          LogLevel_Info
#define LIB_GAMERULES_LOGGER_CONSOLE_LEVEL  LogLevel_Info
#define LIB_GAMERULES_LOGGER_FILE_LEVEL     LogLevel_Trace


// int OS;
Logger  log;

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
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), LIB_GAMERULES_LOGGER_FILE);

    Sink sinks[2];
    sinks[0] = new ServerConsoleSink();
    sinks[0].SetLevel(LIB_GAMERULES_LOGGER_CONSOLE_LEVEL);

    sinks[1] = new RotatingFileSink(path, LIB_GAMERULES_LOGGER_MAX_FILE_SIZE, LIB_GAMERULES_LOGGER_MAX_FILES);
    sinks[1].SetLevel(LIB_GAMERULES_LOGGER_FILE_LEVEL);

    log = new Logger(LIB_GAMERULES_LOGGER_NAME, sinks, 2);
    log.SetLevel(LIB_GAMERULES_LOGGER_LEVEL);

    delete sinks[0];
    delete sinks[1];

    log.InfoEx("********** Library plugin \"%s\" initialize complete! **********", PLUGIN_NAME);
}

public void OnMapStart()
{
    EnableHooks();
}
