#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <eg_boss>

#define PLUGIN "CSO Shooting Star"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define DAMAGE 350
#define RADIUS 150
#define AMMO 10

#define V_MODEL "models/FAITH/v_firecracker.mdl"
#define P_MODEL "models/FAITH/p_firecracker.mdl"
#define W_MODEL "models/FAITH/w_firecracker.mdl"
#define S_MODEL "models/FAITH/shell_firecracker.mdl"

new const WeaponSounds[8][] =
{
	"weapons/firecracker-1.wav",
	"weapons/firecracker-2.wav",
	"weapons/firecracker_draw.wav",
	"weapons/firecracker_bounce1.wav",
	"weapons/firecracker_bounce2.wav",
	"weapons/firecracker_bounce3.wav",
	"weapons/firecracker-wick.wav",
	"weapons/firecracker_explode.wav"
}

new const WeaponResources[][] =
{
	"sprites/spark1.spr",
	"sprites/mooncake.spr",
	"sprites/muzzleflash18.spr",
	"sprites/scope_vip_grenade.spr",
	"sprites/weapon_firecracker.txt",
	"sprites/FAITH/640hud7.spr",
	"sprites/FAITH/640hud72.spr"
}

enum
{
	FC_ANIM_IDLE = 0,
	FC_ANIM_SHOOT1,
	FC_ANIM_SHOOT2,
	FC_ANIM_DRAW
}

#define CSW_FIRECRACKER CSW_DEAGLE
#define weapon_firecracker "weapon_deagle"

#define OLD_W_MODEL "models/w_deagle.mdl"
#define WEAPON_EVENT "events/deagle.sc"
#define WEAPON_SECRETCODE 213168

new g_Had_Firecracker[33], g_SpecialShoot[33], g_Old_Weapon[33], Float:g_LastShoot[33]
new g_firecracker_event, g_ham_bot, g_Exp_SprId, g_Exp2_SprId, g_MF_SprId, g_Trail_SprId

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "Event_DeathMsg", "a")
	
	register_think("grenade2", "fw_Grenade_Think")
	register_touch("grenade2", "*", "fw_Grenade_Touch")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_firecracker, "fw_Item_PrimaryAttack")
	RegisterHam(Ham_Weapon_Reload, weapon_firecracker, "fw_Weapon_Reload")
	RegisterHam(Ham_Item_AddToPlayer, weapon_firecracker, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	register_clcmd(DEF_FIRECRACKER_CODE, "Get_Firecracker")
	register_clcmd("weapon_firecracker", "Hook_Weapon")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)
	
	new i
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i = 0; i < sizeof(WeaponResources); i++)
	{
		if(i == 0) g_Exp_SprId = engfunc(EngFunc_PrecacheModel, WeaponResources[i])
		else if(i == 1) g_Exp2_SprId = engfunc(EngFunc_PrecacheModel, WeaponResources[i])
		else if(i == 2) g_MF_SprId = engfunc(EngFunc_PrecacheModel, WeaponResources[i])
		else if(i == 4) engfunc(EngFunc_PrecacheGeneric, WeaponResources[i])
		else engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	}
	
	g_Trail_SprId = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_firecracker_event = get_orig_retval()		
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_firecracker)
	return PLUGIN_HANDLED
}

public Get_Firecracker(id)
{
	if(!is_user_alive(id))
		return
		
	drop_weapons(id, 2)
	g_Had_Firecracker[id] = 1
	g_SpecialShoot[id] = 0
	
	fm_give_item(id, weapon_firecracker)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_FIRECRACKER)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 0)
	
	// Update Ammo
	cs_set_user_bpammo(id, CSW_FIRECRACKER, AMMO)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(AMMO)
	message_end()
}

public Remove_Firecracker(id)
{
	if(!is_user_connected(id))
		return
		
	g_Had_Firecracker[id] = 0
	g_SpecialShoot[id] = 0
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	static CSWID; CSWID = read_data(2)	
	
	if((CSWID == CSW_FIRECRACKER) && g_Had_Firecracker[id])
	{
		if(g_Old_Weapon[id] != CSW_FIRECRACKER) // DRAW
		{
			set_pev(id, pev_viewmodel2, V_MODEL)
			set_pev(id, pev_weaponmodel2, P_MODEL)
			
			set_weapon_anim(id, FC_ANIM_DRAW)
		}
		
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
		write_byte(1)
		write_byte(CSW_FIRECRACKER)
		write_byte(-1)
		message_end()
		
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_FIRECRACKER)
		if(pev_valid(Ent) && !cs_get_weapon_ammo(Ent)) cs_set_weapon_ammo(Ent, 0)
	}
	
	g_Old_Weapon[id] = CSWID
}

public Event_DeathMsg()
{
	static Victim; Victim = read_data(2)
	Remove_Firecracker(Victim)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_FIRECRACKER && g_Had_Firecracker[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_FIRECRACKER || !g_Had_Firecracker[invoker])
		return FMRES_IGNORED
	if(eventid != g_firecracker_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	Handle_Shoot(invoker)
		
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_firecracker, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_Had_Firecracker[iOwner])
		{
			Remove_Firecracker(iOwner)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_FIRECRACKER || !g_Had_Firecracker[id])
		return
	
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	if((CurButton & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		if(get_pdata_float(id, 83, 5) > 0.0)
			return
		if(cs_get_user_bpammo(id, CSW_FIRECRACKER) <= 0)
			return	
			
		g_SpecialShoot[id] = 0
		Handle_Shoot(id)
	}
	if((CurButton & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		if(get_pdata_float(id, 83, 5) > 0.0)
			return
		if(cs_get_user_bpammo(id, CSW_FIRECRACKER) <= 0)
			return
			
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_FIRECRACKER)
		if(pev_valid(Ent)) 
		{
			g_SpecialShoot[id] = 1
			Handle_Shoot(id)
			g_SpecialShoot[id] = 0
		}
	}
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
	}
}

public fw_TakeDamage(victim, inflictor, attacker) 
{
	if (get_user_team(attacker) == 1 && get_user_team(victim) == 1)
	{
		if(get_user_weapon(attacker) == CSW_FIRECRACKER)
		{
			if(g_Had_Firecracker[attacker])
				SetHamParamFloat(4, 0)
		}
	}
	if (get_user_team(attacker) == 2 && get_user_team(victim) == 2)
	{
		if(get_user_weapon(attacker) == CSW_FIRECRACKER)
		{
			if(g_Had_Firecracker[attacker])
				SetHamParamFloat(4, 0)
		}
	}
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_FIRECRACKER || !g_Had_Firecracker[Attacker])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

public fw_Item_PrimaryAttack(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id) || !g_Had_Firecracker[id])
		return HAM_IGNORED

	static Float:PunchAngles[3]
	
	PunchAngles[0] = PunchAngles[1] = PunchAngles[2] = 0.0
	set_pev(id, pev_punchangle, PunchAngles)
		
	return HAM_HANDLED
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && g_Had_Firecracker[id])
		return HAM_SUPERCEDE

	return HAM_IGNORED;
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_Had_Firecracker[id] = 1
		set_pev(ent, pev_impulse, 0)
	}		
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), .player = id)
	write_string(g_Had_Firecracker[id] == 1 ? "weapon_firecracker" : "weapon_deagle")
	write_byte(8) // PrimaryAmmoID
	write_byte(35) // PrimaryAmmoMaxAmount
	write_byte(-1) // SecondaryAmmoID
	write_byte(-1) // SecondaryAmmoMaxAmount
	write_byte(1) // SlotID (0...N)
	write_byte(1) // NumberInSlot (1...N)
	write_byte(g_Had_Firecracker[id] == 1 ? CSW_FIRECRACKER : CSW_DEAGLE) // WeaponID
	write_byte(0) // Flags
	message_end()

	return HAM_HANDLED	
}

public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	message_end()
	
	if(get_gametime() - 0.75 > pev(Ent, pev_fuser1))
	{
		emit_sound(Ent, CHAN_BODY, WeaponSounds[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_pev(Ent, pev_fuser1, get_gametime())
	}
	
	if(get_gametime() - pev(Ent, pev_fuser2) >= 2.0)
	{
		Grenade_Explosion(Ent)
		return
	}
		
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_Grenade_Touch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
		
	static Bounce; Bounce = pev(Ent, pev_iuser1)
	if(Bounce)
	{
		/*
		static Float:Velocity[3]
		pev(Ent, pev_velocity, Velocity)
		
		xs_vec_mul_scalar(Velocity, 0.9, Velocity)
		set_pev(Ent, pev_velocity, Velocity)*/
		
		emit_sound(Ent, CHAN_BODY, WeaponSounds[random_num(3, 5)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} else {
		Grenade_Explosion(Ent)
	}
}

public Grenade_Explosion(Ent)
{
	static Float:Origin[3], TE_FLAG
	pev(Ent, pev_origin, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 36.0)
	write_short(g_Exp_SprId)
	write_byte(10)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()	
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 36.0)
	write_short(g_Exp2_SprId)
	write_byte(10)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()		
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(random_num(46, 48))
	message_end()		
	
	emit_sound(Ent, CHAN_BODY, WeaponSounds[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	Check_RadiusDamage(Ent, pev(Ent, pev_owner))
	
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Handle_Shoot(id)
{
	if(get_gametime() - 2.5 > g_LastShoot[id])
	{
		g_LastShoot[id] = get_gametime()
		
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_FIRECRACKER)
		if(!pev_valid(Ent)) return
		
		static Ammo; Ammo = cs_get_user_bpammo(id, CSW_FIRECRACKER)
		if(Ammo <= 0) return
		
		Ammo--
		cs_set_user_bpammo(id, CSW_FIRECRACKER, Ammo)
		
		if(Ammo <= 0) 
		{
			set_weapon_anim(id, FC_ANIM_SHOOT2)
			emit_sound(id, CHAN_WEAPON, WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		} else {
			set_weapon_anim(id, FC_ANIM_SHOOT1)
			emit_sound(id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		
		Make_Muzzleflash(id)
		Make_PunchAngles(id)
	
		set_weapons_timeidle(id, 2.5)
		set_player_nextattack(id, 2.5)
		
		Make_Grenade(id, g_SpecialShoot[id])
	}
}

public Make_Muzzleflash(id)
{
	static Float:Origin[3], TE_FLAG
	get_position(id, 80.0, 20.0, -10.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_MF_SprId)
	write_byte(3)
	write_byte(20)
	write_byte(TE_FLAG)
	message_end()
}

public Make_PunchAngles(id)
{
	static Float:PunchAngles[3]
	
	PunchAngles[0] = random_float(-2.0, 0.0)
	PunchAngles[1] = random_float(-1.0, 1.0)
	
	set_pev(id, pev_punchangle, PunchAngles)
}

public Make_Grenade(id, Bounce)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	static Float:Origin[3], Float:Angles[3]
	
	get_position(id, 50.0, 10.0, 0.0, Origin)
	pev(id, pev_angles, Angles)
	
	set_pev(Ent, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	
	set_pev(Ent, pev_classname, "grenade2")
	engfunc(EngFunc_SetModel, Ent, S_MODEL)
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_owner, id)
	
	set_pev(Ent, pev_iuser1, Bounce)
	set_pev(Ent, pev_fuser2, get_gametime())
	
	// Create Velocity
	static Float:Velocity[3], Float:TargetOrigin[3]
	
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, 700.0, Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(g_Trail_SprId) // sprite
	write_byte(10)  // life
	write_byte(3)  // width
	write_byte(255) // r
	write_byte(170)  // g
	write_byte(212)  // b
	write_byte(200) // brightness
	message_end()	
}

public Check_RadiusDamage(Ent, Id)
{
	static Attacker
	if(!is_user_connected(Id)) Attacker = 0
	else Attacker = Id
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(i == Attacker)
			continue
		if(get_user_team(Attacker) == get_user_team(i))
			continue
		if(entity_range(Ent, i) > float(RADIUS))
			continue
		if(pev(i,pev_takedamage) == DAMAGE_NO)
			continue
			
		set_pdata_float(i, 108, 0.9)
		ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, float(DAMAGE), DMG_BULLET)
	}
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_FIRECRACKER)
	if(!pev_valid(Ent)) 
		return
	
	set_pdata_float(Ent, 46, TimeIdle, 4)
	set_pdata_float(Ent, 47, TimeIdle, 4)
	set_pdata_float(Ent, 48, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock drop_weapons(iPlayer, Slot)
{
	new item = get_pdata_cbase(iPlayer, 367+Slot, 4)
	while(item > 0)
	{
		static classname[24]
		pev(item, pev_classname, classname, charsmax(classname))
		engclient_cmd(iPlayer, "drop", classname)
		item = get_pdata_cbase(item, 42, 5)
	}
	set_pdata_cbase(iPlayer, 367, -1, 4)
}