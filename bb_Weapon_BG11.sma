/* 本插件由 AMXX-Studio 中文版自动生成*/
/* UTF-8 func by www.DT-Club.net */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN_NAME	"Balrog XI"
#define PLUGIN_VERSION	"1.0 for Online"
#define PLUGIN_AUTHOR	"xhsu"

#define VMDL 		"models/FAITH/v_balrog11.mdl"
#define WMDL 		"models/FAITH/w_balrog11.mdl"
#define OLD_WMDL	"models/w_xm1014.mdl"
#define PMDL 		"models/FAITH/p_balrog11.mdl"

#define WEAPON_CSW	CSW_XM1014
#define WEAPON_ENT	"weapon_xm1014"
#define WEAPON_HUD	"weapon_balrog11"

#define FIRE_NAME	"balrog11_fire"
#define FIRE_MODEL	"sprites/flame_puff01.spr"
#define FIRE_SOUND	"weapons/balrog11-2.wav"
#define FIRE_HOLD	2.0
#define FIRE_DAMAGE	random_float(100.0, 200.0)
#define ATTACK_RATE	0.4
#define UPDATE_SOUND	"weapons/balrog11_charge.wav"
#define GUNSHOOT_SOUND	"weapons/balrog11-1.wav"
#define MAX_FIRE	7

#define SPECIAL_CODE	235377687

#define g_CvarFriendlyFire	get_cvar_num("mp_friendlyfire")

enum {
	idle = 0,
	shoot1,
	shoot2,
	insert,
	after_reload,
	start_reload,
	draw
}

new g_szNumIcon[33][24], g_fwBotForwardRegister

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_clcmd("Get_Balrog-11RsGame", "GiveBalrog")
	register_clcmd(WEAPON_HUD, "HUD_Handler")
	
	register_event("CurWeapon","EventCurrentWeapon","be","1=1")
	register_message(get_user_msgid("DeathMsg"), "MSG_DeathMSG")
	
	register_forward(FM_SetModel, "fwSetModel")
	register_forward(FM_Touch, "fwTouchPost", 1)
	
	RegisterHam(Ham_Think, "env_sprite", "HamFireThink")
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_ENT, "HamItemAddToPlayer")
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_ENT, "HamWeaponPriAttack")
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_ENT, "HamWeaponIdle")
	
	RegisterHam(Ham_CS_RoundRespawn, "player", "HamPlayerRoundSpawnPost", 1)
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)
}

public plugin_precache()
{
	precache_model(VMDL)
	precache_model(WMDL)
	precache_model(PMDL)
	
	precache_model(FIRE_MODEL)
	precache_sound(FIRE_SOUND)
	precache_sound(UPDATE_SOUND)
	precache_sound(GUNSHOOT_SOUND)
}

public fw_BotForwardRegister_Post(iPlayer)
{
	if(!is_user_bot(iPlayer))
	return

	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
	RegisterHamFromEntity(Ham_CS_RoundRespawn, iPlayer, "HamPlayerRoundSpawnPost", 1)
}

public HamPlayerRoundSpawnPost(id)
{
	if(!is_user_bot(id)) return
	new iNum = random_num(1, 10)
	if(iNum == 1) GiveBalrog(id)
}

public GiveBalrog(id)
{
	fm_drop_weapons(id, 1)
	new iEntity = fm_give_weapon(id, WEAPON_ENT)
	xhsu_ChangeWeaponList(id, WEAPON_CSW, WEAPON_HUD)
	set_pev(iEntity, pev_weapons, SPECIAL_CODE)
	set_pev(iEntity, pev_iuser1, 0)
	set_pev(iEntity, pev_iuser2, 0)
	set_pev(iEntity, pev_fuser1, get_gametime())
}

public HamItemAddToPlayer(iEntity, id)
{
	if(pev(iEntity, pev_weapons) != SPECIAL_CODE) return
	
	xhsu_ChangeWeaponList(id, WEAPON_CSW, WEAPON_HUD)
	set_pev(iEntity, pev_iuser2, 0)
}

public HUD_Handler(id)
{
	client_cmd(id, WEAPON_ENT)
	return PLUGIN_HANDLED
}

public EventCurrentWeapon(id)
{
	if(!is_user_alive(id)) return
	
	new iEntity = get_pdata_cbase(id, 373)
	if(pev(iEntity, pev_weapons) != SPECIAL_CODE)
	{
		ShowNum(id, -1)
		return
	}
	
	set_pev(id, pev_viewmodel2, VMDL)
	set_pev(id, pev_weaponmodel2, PMDL)
	ShowNum(id, pev(iEntity, pev_iuser1))
}

public HamWeaponPriAttack(iEntity)
{
	if(pev(iEntity, pev_weapons) != SPECIAL_CODE) return
	
	static iFireAmmo, id
	iFireAmmo = pev(iEntity, pev_iuser1)
	id = get_pdata_cbase(iEntity, 41, 4)
	set_pev(iEntity, pev_iuser2, pev(iEntity, pev_iuser2)+1)
	
	if(pev(iEntity, pev_iuser2) >= 4 && get_pdata_int(iEntity, 51, 4) > 0 && iFireAmmo < MAX_FIRE)
	{
		set_pev(iEntity, pev_iuser1, min(MAX_FIRE, iFireAmmo+1))
		set_pev(iEntity, pev_iuser2, 0)
		ShowNum(id, iFireAmmo)
		
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, UPDATE_SOUND, 1.0, 0.4, 0, PITCH_NORM)
	}
	
	remove_task(iEntity+SPECIAL_CODE)
	set_task(0.3, "ClearShoot", iEntity+SPECIAL_CODE)
	
	if(is_user_bot(id)) Func_BotThink(id, iEntity)
}

public ClearShoot(iEntity) set_pev(iEntity-SPECIAL_CODE, pev_iuser2, 0)

public HamWeaponIdle(iEntity)
{
	if(pev(iEntity, pev_weapons) != SPECIAL_CODE) return
	else if(pev(iEntity, pev_iuser1) <= 0) return
	
	static id; id = get_pdata_cbase(iEntity, 41, 4)
	static iButton; iButton = pev(id, pev_button)
	if(!fm_is_weapon_ready(id, iEntity)) return
	
	static Float:fNextAttack
	pev(iEntity, pev_fuser1, fNextAttack)
	if(get_gametime() < fNextAttack) return
	
	if(iButton & IN_ATTACK2)
	{
		fm_make_weapon_idle(id, iEntity, ATTACK_RATE)
		native_playanim(id, shoot2)
		engfunc(EngFunc_EmitSound, iEntity, CHAN_WEAPON, FIRE_SOUND, 1.0, 0.4, 0, PITCH_NORM)
		
		set_pev(iEntity, pev_iuser1, max(pev(iEntity, pev_iuser1)-1, 0))
		ShowNum(id, pev(iEntity, pev_iuser1))
		
		new Float:fSpeed[3] = {750.0, 500.0, 250.0}
		for(new i = 0; i < 3; i++) make_fire_effect(id, fSpeed[i])
		
		set_pev(iEntity, pev_fuser1, get_gametime()+ATTACK_RATE)
	}
}

public fwSetModel(iEntity, szModel[])
{
	if(strcmp(szModel, OLD_WMDL)) return FMRES_IGNORED
	
	static szClassName[32]
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName))
	
	if(strcmp(szClassName, "weaponbox")) return FMRES_IGNORED
	
	new iEntity2 = get_pdata_cbase(iEntity, 35, 4)
	
	if(!pev_valid(iEntity2)) return FMRES_IGNORED
	
	if(pev(iEntity2, pev_weapons) != SPECIAL_CODE) return FMRES_IGNORED
	
	engfunc(EngFunc_SetModel, iEntity, WMDL)
	
	new id  = pev(iEntity, pev_owner)
	xhsu_ChangeWeaponList(id, WEAPON_CSW, WEAPON_ENT)
	
	return FMRES_SUPERCEDE
}

public HamFireThink(iEntity)
{
	if(!pev_valid(iEntity)) return
	
	static szClassName[32]
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName))
	if(strcmp(szClassName, FIRE_NAME)) return
	
	static Float:fScale
	pev(iEntity, pev_scale, fScale)
	fScale += 0.02
	
	set_pev(iEntity, pev_scale, fScale)
	set_pev(iEntity, pev_nextthink, get_gametime()+0.05)
	
	static Float:fTimeRemove
	pev(iEntity, pev_fuser1, fTimeRemove)
	if(get_gametime() >= fTimeRemove) engfunc(EngFunc_RemoveEntity, iEntity)
}

public fwTouchPost(iEntity, id)
{
	if(!pev_valid(iEntity)) return
	
	static szClassName[32]
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName))
	if(strcmp(szClassName, FIRE_NAME)) return
	
	if(!pev_valid(id))
	{
		engfunc(EngFunc_RemoveEntity, iEntity)
		return
	}
	
	if(is_user_alive(id) && fm_is_user_same_team(id, pev(iEntity, pev_owner)) && !g_CvarFriendlyFire) return
	else if(id == pev(iEntity, pev_owner) && !g_CvarFriendlyFire) return
	
	ExecuteHamB(Ham_TakeDamage, id, iEntity, pev(iEntity, pev_owner), FIRE_DAMAGE, DMG_BURN|DMG_SLOWBURN)
	if(!is_user_alive(id)) engfunc(EngFunc_RemoveEntity, iEntity)
}

public MSG_DeathMSG(msg_id, msg_dest, msg_ent)
{
	new szTruncatedWeapon[24]
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	if(!strcmp(szTruncatedWeapon, FIRE_NAME)) set_msg_arg_string(4, "xm1014")
	
	new iVictim = get_msg_arg_int(2)
	ShowNum(iVictim, -1)
}

public make_fire_effect(id, Float:fSpeed) //制造火焰
{
	static Float:StartOrigin[3], Float:TargetOrigin[5][3]

	// Left
	get_position(id, 512.0, -140.0, 0.0, TargetOrigin[0])
	get_position(id, 512.0, -70.0, 0.0, TargetOrigin[1])
	
	// Center
	get_position(id, 512.0, 0.0, 0.0, TargetOrigin[2])
	
	// Right
	get_position(id, 512.0, 70.0, 0.0, TargetOrigin[3])
	get_position(id, 512.0, 140.0, 0.0, TargetOrigin[4])

	for(new i = 0; i < 5; i++)
	{
		get_position(id, random_float(30.0, 40.0), 0.0, -5.0, StartOrigin)
		create_fire(id, StartOrigin, TargetOrigin[i], fSpeed)
	}
}

public create_fire(id, Float:Origin[3], Float:TargetOrigin[3], Float:Speed)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	static Float:vfAngle[3], Float:MyOrigin[3], Float:Velocity[3]
	
	pev(id, pev_angles, vfAngle)
	pev(id, pev_origin, MyOrigin)
	
	vfAngle[2] = float(random(18) * 20)

	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 250.0)
	set_pev(iEnt, pev_fuser1, get_gametime() + FIRE_HOLD)	// time remove
	set_pev(iEnt, pev_scale, 1.0)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	
	set_pev(iEnt, pev_classname, FIRE_NAME)
	engfunc(EngFunc_SetModel, iEnt, FIRE_MODEL)
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_owner, id)	
	set_pev(iEnt, pev_frame, 0.0)
	
	get_speed_vector(Origin, TargetOrigin, Speed, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)
}

public ShowNum(id, iNum)
{
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0, 0, 0}, id);
	write_byte(0);
	write_string(g_szNumIcon[id]);
	message_end();
	
	switch(iNum)
	{
		case 0: g_szNumIcon[id] = "number_0"
		case 1: g_szNumIcon[id] = "number_1"
		case 2: g_szNumIcon[id] = "number_2"
		case 3: g_szNumIcon[id] = "number_3"
		case 4: g_szNumIcon[id] = "number_4"
		case 5: g_szNumIcon[id] = "number_5"
		case 6: g_szNumIcon[id] = "number_6"
		case 7: g_szNumIcon[id] = "number_7"
		case 8: g_szNumIcon[id] = "number_8"
		case 9: g_szNumIcon[id] = "number_9"
		default: return
	}
	
	new iColor[3]
	CheckNumColor(iNum, iColor)
	
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0, 0, 0}, id);
	write_byte(1);			// status (0=hide, 1=show, 2=flash)
	write_string(g_szNumIcon[id]);	// sprite name			
	write_byte(iColor[0]);		// red
	write_byte(iColor[1]);		// green
	write_byte(iColor[2]);		// blue
	message_end();
}

public CheckNumColor(iNum, iColor[3])
{
	switch(iNum)
	{
		case 0..2: iColor = {255, 0, 0}
		case 3..5: iColor = {248, 244, 0}
		default: iColor = {0, 200, 0}
	}
}

public Func_BotThink(id, iEntity)
{
	if(!is_user_alive(id) || pev(iEntity, pev_weapons) != SPECIAL_CODE) return
	
	new iTargets, Float:fOrigin[3], Float:fOrigin2[3]
	pev(id, pev_origin, fOrigin)
	for(new i = 0; i < 33; i++)
	{
		if(!is_user_alive(i))
		continue
		
		if(fm_is_user_same_team(id, i))
		continue
		
		pev(i, pev_origin, fOrigin2)
		if(get_distance_f(fOrigin, fOrigin2) > 350.0)
		continue
		
		if(is_wall_between_points(fOrigin, fOrigin2, _, id))
		continue
		
		iTargets++
	}
	if(iTargets < 4) return
	
	new Float:fSpeed[3] = {750.0, 500.0, 250.0}
	for(new i = 0; i < 3; i++) make_fire_effect(id, fSpeed[i])
}

stock fm_give_weapon(index, const wEntity[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, wEntity))
	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(iEntity, pev_origin, origin)
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, iEntity)
	new save = pev(iEntity, pev_solid)
	dllfunc(DLLFunc_Touch, iEntity, index)
	if(pev(iEntity, pev_solid) != save)
	return iEntity
	engfunc(EngFunc_RemoveEntity, iEntity)
	return -1
}

stock fm_drop_weapons(index, Slot)
{
	new item = get_pdata_cbase(index, 367+Slot, 4)
	while(item > 0)
	{
		static classname[24]
		pev(item, pev_classname, classname, charsmax(classname))
		engclient_cmd(index, "drop", classname)
		item = get_pdata_cbase(item, 42, 5)
	}
	set_pdata_cbase(index, 367, -1, 4)
}

new const g_szGameWeaponAmmoId[31] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }
new const g_szGameWeaponInSlot[31] = { -1, 3, -1, 9, 1, 12, 3, 13, 14, 3, 5, 6, 15, 16, 17, 18, 4, 2, 2, 7, 4, 5, 6, 11, 3, 2, 1, 10, 1, 1, 8 }
new const g_szGameWeaponWhichSlot[31] = { -1, 1, -1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0 }
new const g_szGameWeaponAmmoMaxAmount[31] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1,100 }

stock xhsu_ChangeWeaponList(iPlayer, OriginWeapCSW, const NewWeapHUD[], iAmmo = -1, iSlot = -1, iList = -1)
{
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, iPlayer)
	write_string(NewWeapHUD)
	write_byte(g_szGameWeaponAmmoId[OriginWeapCSW])
	write_byte(iAmmo == -1 ? g_szGameWeaponAmmoMaxAmount[OriginWeapCSW] : iAmmo)
	write_byte(-1)
	write_byte(-1)
	write_byte(iSlot == -1 ? g_szGameWeaponWhichSlot[OriginWeapCSW] : iSlot-1)
	write_byte(iList == -1 ? g_szGameWeaponInSlot[OriginWeapCSW] : iList)
	write_byte(OriginWeapCSW)
	if(OriginWeapCSW == CSW_C4 || OriginWeapCSW == CSW_HEGRENADE || OriginWeapCSW == CSW_FLASHBANG || OriginWeapCSW == CSW_SMOKEGRENADE) write_byte(24)
	else write_byte(0)
	message_end()
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	xs_vec_normalize(new_velocity, new_velocity)
	new Float:num = floatsqroot(speed*speed / xs_vec_dot(new_velocity, new_velocity))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock native_playanim(index,anim)
{
	set_pev(index, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, index)
	write_byte(anim)
	write_byte(pev(index, pev_body))
	message_end()
}

stock bool:fm_is_weapon_ready(index, iEntity)
{
	if(get_pdata_float(iEntity, 46, 4) <= 0.0 && get_pdata_float(index, 83, 5) <= 0.0) return true
	
	return false
}

stock fm_make_weapon_idle(index, iWeap, Float:fTime)
{
	set_pdata_float(index, 83, fTime-0.1, 5) //next attack
	set_pdata_float(iWeap, 46, fTime+0.1, 4) //next idle
	set_pdata_float(iWeap, 47, fTime+0.1, 4) //next idle
	set_pdata_float(iWeap, 48, fTime+1.1, 4) //next idle
}

stock bool:fm_is_user_same_team(index1, index2)
	return (get_pdata_int(index1, 114, 5) == get_pdata_int(index2, 114, 5))

stock bool:is_wall_between_points(Float:fStart[3], Float:fEnd[3], iIgnoreEnt = DONT_IGNORE_MONSTERS, index = 0)
{
	new iPtr = create_tr2()
	engfunc(EngFunc_TraceLine, fStart, fEnd, iIgnoreEnt, index, iPtr)
	new Float:fEnd2[3]
	get_tr2(iPtr, TR_vecEndPos, fEnd2)
	free_tr2(iPtr)
	
	if(xs_vec_equal(fEnd, fEnd2)) return false
	
	return true
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg936\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset134 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2052\\ f0\\ fs16 \n\\ par }
*/
