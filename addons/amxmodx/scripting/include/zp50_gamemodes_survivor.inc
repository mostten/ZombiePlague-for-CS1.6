#if defined _zp50_gamemodes_survivor_included
  #endinput
#endif
#define _zp50_gamemodes_survivor_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_gamemodes_survivor
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_gamemodes_survivor
	#endif
#else
	#pragma library zp50_gamemodes_survivor
#endif


/**
 * Called when a survivor mode starts.
 *
 * @param survivor_index		Internal ID for the survivor.
 */
forward zp_fw_survivor_started(survivor_index);