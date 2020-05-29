#if defined _zp50_effects_lighting_included
  #endinput
#endif
#define _zp50_effects_lighting_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_effects_lighting
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_effects_lighting
	#endif
#else
	#pragma library zp50_effects_lighting
#endif

/**
 * Called on set a player light style. You can block it by
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param id			Player.
 * @param light_style	Light style.
 */
forward zp_fw_set_user_lightstyle_pre(id, const light_style[2]);

/**
 * Called on set a player light style.
 *
 * @param id			Player index.
 * @param light_style	Light style.
 */
forward zp_fw_set_user_lightstyle_post(id, const light_style[2]);

/**
 * Set a player light style.
 *
 * @param id			Player index.
 * @param light_style	Light style.
 * @param call_forward	Active forward?
 */
native zp_set_user_lightstyle(id, const light_style[2], bool:call_forward = true);