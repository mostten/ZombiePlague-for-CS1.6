#if defined _zp50_class_npc_included
  #endinput
#endif
#define _zp50_class_npc_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_npc
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_npc
	#endif
#else
	#pragma library zp50_class_npc
#endif

/**
 * Returns a npc's current class ID.
 *
 * @param npc		Npc entity index.
 * @return			Internal npc class ID, or -1 if not yet chosen.
 */
native zp_class_npc_get_classid(const npc);

/**
 * Returns whether a entity is a npc.
 *
 * @param entity	Entity index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_class_npc_get(const entity);

/**
 * Returns number of alive npcs.
 *
 * @param classid	Npc classid.
 * @return			Npc count.
 */
native zp_class_npc_get_count(const classid = -1);

/**
 * Spawn a npc.
 *
 * @param classid		Nternal npc class ID.
 *
 * @return				Npc index.
 */
native zp_class_npc_spawn(const classid);

/**
 * Registers a custom class which will be added to the npc classes menu of ZP.
 *
 * Note: The returned npc class ID can be later used to identify
 *
 * @param name					Caption to display on the menu.
 * @param classname				Class name.
 * @param model					Class model.
 * @param mins					Model mins.
 * @param maxs					Model maxs.
 * @param speed					Class maxspeed.
 * @param health				Class health.
 * @param damage				Attack damage.
 * @param gravity				Class gravity multiplier.
 * @param jump_height			Class jump height.
 *
 * @return						An internal npc class ID, or -1 on failure.
 */
native zp_class_npc_register(const name[], const classname[], const model[], const Float:mins[3], const Float:maxs[3], const Float:speed, const Float:health, const Float:damage, const Float:gravity, const Float:jump_height);

/**
 * Registers a custom anim for npc's AI.
 *
 * @param classid				Npc classid.
 * @param sound_hurt			Npc's hurt sound.
 * @param sound_attack			Npc's attack sound.
 * @param sound_die				Npc's dead sound.
 *
 * @no return.
 */
native zp_class_npc_sound_register(const classid, const sound_hurt[] = "", const sound_attack[] = "", const sound_die[] = "");

/**
 * Registers a custom anim for npc's AI.
 *
 * @param classid				Npc classid.
 * @param anim_idle				AI's idle anim.
 * @param anim_run				AI's run anim.
 * @param anim_attack			AI's attack anim.
 * @param anim_die				AI's dead anim.
 * @param anim_jump				AI's jump anim.
 * @param anim_fall				AI's fall anim.
 *
 * @no return.
 */
native zp_class_npc_anim_register(const classid, const anim_idle[] = "", const anim_run[] = "", const anim_attack[] = "", const anim_die[] = "", const anim_jump[] = "", const anim_fall[] = "");

/**
 * Returns a npc class' name.
 *
 * @param classid	A valid npc class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native bool:zp_class_npc_get_name(const classid, name[], len);

/**
 * Shows menu with available npc classes to a player.
 *
 * @param id		Player index.
 */
native zp_class_npc_show_menu(id);

/**
 * Returns a random of spawn points.
 *
 * @return		whether point is hull vacant.
 */
native bool:zp_class_npc_random_point(Float:origin[3], &bool:jump);

/**
 * Called when a npc was spawned.
 *
 * @param npc		Npc index.
 * @param classid	Npc classid.
 *
 */
forward zp_fw_npc_spawn_post(npc, classid);

/**
 * Called when a npc was dead.
 *
 * @param npc		Npc index.
 * @param attacker	Attacker index.
 *
 */
forward zp_fw_npc_dead_post(npc, attacker);

/**
 * Called right when npc attack.
 *
 * Possible return values are:
 *	- PLUGIN_HANDLED to block
 *
 * @param npc			Npc index.
 * @param target		Target index.
 */
forward zp_fw_npc_attack_pre(npc, target);

/**
 * Called right when npc attack.
 *
 * @param npc			Npc index.
 * @param target		Target index.
 */
forward zp_fw_npc_attack_post(npc, target);