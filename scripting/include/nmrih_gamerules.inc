/** Double-include prevention */
#if defined _nmrih_game_rules_utils_included_
  #endinput
#endif
#define _nmrih_game_rules_utils_included_

#pragma newdecls required
#pragma semicolon 1

/**
 * See: https://github.com/dysphie/nmrih-guaranteedspawn/blob/2b06ceb48fb0146f72c947600b4661e802b07031/scripting/nmrih-guaranteedspawn.sp#L242
 *
 * @param client        client index.
 * @param returnValue   The real function return value.
 * @return              Return Plugin_Continue continue with the original action;
 *                      Return Plugin_Changed call real function, but use my return value;
 *                      Return Plugin_Handled or Plugin_Stop skip real function, and use my return value;
 */
forward Action OnGameRulesGetPlayerSpawnSpot(int &client, int &returnValue);
forward  void  OnGameRulesGetPlayerSpawnSpotPost(int client, int returnValue);


enum NMR_GameType
{
    NMR_GameType_Objective = 0,
    NMR_GameType_Wave,

    NMR_GameType_Total
}
