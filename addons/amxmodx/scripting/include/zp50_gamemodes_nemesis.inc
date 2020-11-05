#if defined _zp50_gamemodes_nemesis_included
  #endinput
#endif
#define _zp50_gamemodes_nemesis_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_gamemodes_nemesis
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_gamemodes_nemesis
	#endif
#else
	#pragma library zp50_gamemodes_nemesis
#endif


/**
 * Called when a nemesis mode starts.
 *
 * @param nemesis_index		Internal ID for the nemesis.
 */
forward zp_fw_nemesis_started(nemesis_index);