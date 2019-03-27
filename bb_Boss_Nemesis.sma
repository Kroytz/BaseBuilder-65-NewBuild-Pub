#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>
#include <basebuilder>
#include <fakemeta>
#include <eG>
#include <hamsandwich>
#include <xs>
#include <dhudmessage>

#define BOSS_ALARM	"basebuilder/FAITH/Boss_Alarm.wav" // Alarm Sound

native zp_override_user_model(id, const newmodel[], modelindex = 0)

#define	TASK_BOSS_SKILL_COUNTDOWN 100
#define TASK_OFF_SKILL 100

new bool:g_bIsBoss[33]
new bool:g_bBossNoDmg = false
new g_iBossPhase
new g_iBossCountdown[33]
new g_msgScreenShake
new g_spriteSmoke, beam, boom

public plugin_init()
{
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public client_connected(id)
{
	g_bIsBoss[id] = false
	g_iBossCountdown[id] = 0
	g_iBossPhase = 0
}

public plugin_precache()
{
	// -- N-1
	precache_model("models/stinger/stinger_rocket_frk14.mdl")
	precache_model("models/player/RE_Nemesis_frk/RE_Nemesis_frk.mdl")
	precache_model("models/player/RE_Nemesis_frk/RE_Nemesis_frkT.mdl")
	precache_model("models/stinger/p_stinger_frk14.mdl")
	precache_model("models/v_bazooka_nem.mdl")
	
	beam = precache_model("sprites/smoke.spr")
	boom = precache_model("sprites/zerogxplode55.spr")
	g_spriteSmoke = precache_model("sprites/wall_puff4.spr")
	precache_sound("basebuilder/FAITH/nemesis/rpg7_shoot.wav")
	
	// -- N-2
	precache_model("models/player/Nemesis_2nd_frk14/Nemesis_2nd_frk14.mdl")
	precache_model("models/player/Nemesis_2nd_frk14/Nemesis_2nd_frk14T.mdl")
	precache_model("models/v_clow_nem.mdl")
	precache_sound("basebuilder/FAITH/nemesis/nemesisgodmode.wav")

	register_plugin("[BB] Boss: Nemesis", "1.2", "EmeraldGhost")
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Spawn, "player", "fwHam_spawn", 1)

	//register_clcmd("eg_testboss", "Become_Boss")
}

public plugin_natives()
{
	register_native("bb_nemesis_me", "Native_Become_Nemesis", 1)
	register_native("bb_nemesis_phase2", "Native_Nemesis_Evolution", 1)
}

public Native_Become_Nemesis(id) Become_Boss(id)
public Native_Nemesis_Evolution(id) Nemesis_Phase2(id)

public Become_Boss(id)
{
	new players_ct[32], ict
	get_players(players_ct,ict,"ae","CT")

	g_bIsBoss[id] = true
	g_iBossPhase = 1
	g_iBossCountdown[id] = 222
	set_task(0.5, "boss_skill_reload", id + TASK_BOSS_SKILL_COUNTDOWN, _, _, "b")
	
	set_pev(id, pev_viewmodel2, "models/v_bazooka_nem.mdl")
	set_pev(id, pev_weaponmodel2, "models/stinger/p_stinger_frk14.mdl")
	zp_override_user_model(id, "RE_Nemesis_frk")
	
	set_user_health(id, ict * 1250 + 500)
	set_user_maxspeed(id, 1.1)
	set_user_gravity(id, 0.8)
	
	new wjsl = get_playersnum(0)
	if(wjsl < 8) client_printc(0, "\y[\g基地建设\y] 由于在线玩家数量小于 8 人, Nemesis 伤害自动削弱 .");
}

public Nemesis_Phase2(id)
{
	if(g_iBossPhase != 1 || !g_bIsBoss[id])
		return PLUGIN_HANDLED

	client_cmd(0, "spk %s", BOSS_ALARM)
	set_dhudmessage(200, 0, 0, -1.0, 0.35, 0, 0.0, 3.0, 2.0, 1.0, false)
	show_dhudmessage(0, "Nemesis 进化至 Phase 2")
		
	new players_ct[32], ict
	get_players(players_ct,ict,"ae","CT")

	g_iBossPhase = 2
	
	set_pev(id, pev_viewmodel2, "models/v_clow_nem.mdl")
	set_pev(id, pev_weaponmodel2, "")
	zp_override_user_model(id, "Nemesis_2nd_frk14")
	
	set_user_health(id, ict * 4790 + 250)
	g_iBossCountdown[id] = 888
	
	g_bBossNoDmg = true

	client_cmd(0, "spk basebuilder/FAITH/nemesis/nemesisgodmode.wav")
	//emit_sound(id, CHAN_STATIC, "basebuilder/FAITH/nemesis/nemesisgodmode.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)

	set_user_godmode(id, 1)
	set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 3)

	set_task(2.0, "Skill_Godmode_Off", id + TASK_OFF_SKILL)
}

public fwHam_spawn(id)
{
	remove_task(id + TASK_BOSS_SKILL_COUNTDOWN)
	g_iBossCountdown[id] = 0
	
	if(g_bIsBoss[id])
	{
		g_bBossNoDmg = false
		g_bIsBoss[id] = false
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
		set_pev(id, pev_weaponmodel2, "")
	}
}

public boss_skill_reload(taskid)
{
	new id = taskid - TASK_BOSS_SKILL_COUNTDOWN
	if(is_user_alive(id) && is_user_connected(id))
	{
		if(g_iBossCountdown[id] >= 888)
        {
			g_iBossCountdown[id] = 888
			
			if(g_iBossPhase == 1)
				client_print(id, print_center, "【 Reload 完成丨按 'R' 发射火箭】");
			else if(g_iBossPhase == 2)
				client_print(id, print_center, "【 Reload 完成丨按 'R' 使用无敌】");
        }
		else
		{		
			if(g_iBossPhase == 1)
				g_iBossCountdown[id] += 16;
			else if(g_iBossPhase == 2)
				g_iBossCountdown[id] += 23;
				
			client_print(id, print_center, "【 Reload: %d / 888 】", g_iBossCountdown[id])
		}
	}
}

public Skill_Godmode(id)
{
	g_bBossNoDmg = true
	event_hud(0, 0, 255, 255, "Nemesis 发动技能【无敌】^n所有伤害免疫 4 秒")

	client_cmd(0, "spk basebuilder/FAITH/nemesis/nemesisgodmode.wav")
	//emit_sound(id, CHAN_STATIC, "basebuilder/FAITH/nemesis/nemesisgodmode.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)

	set_user_godmode(id, 1)
	set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 3)

	set_task(4.0, "Skill_Godmode_Off", id + TASK_OFF_SKILL)
}

public Skill_Godmode_Off(taskid)
{
	new id = taskid - TASK_OFF_SKILL
	
	if(is_user_alive(id) && is_user_connected(id))
	{
		g_bBossNoDmg = false
		set_user_godmode(id)
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
	}
}

public fw_CmdStart(id, uc_handle, seed) 
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	if ((button & IN_RELOAD) && !(oldbutton & IN_RELOAD))
	{
		if(zp_get_user_zombie(id) && is_user_alive(id) && g_bIsBoss[id] && g_iBossCountdown[id] == 888)
		{
			if(g_iBossPhase == 1)
			{
				Create_Rocket(id)
				g_iBossCountdown[id] = 0
			}
			else if(g_iBossPhase == 2)
			{
				if(!g_bBossNoDmg)
				{
				Skill_Godmode(id)
				g_iBossCountdown[id] = 0
				}
				else client_print(id, print_center, "正在无敌状态, 无法使用无敌!")
			}
		}
	}
	return PLUGIN_HANDLED 
}

public Create_Rocket(id)
{
    new args[16]
    new Float:Ori[3], Float:Vel[3], Float:vAngles[3]
    new notFloat_vOrigin[3]
    entity_get_vector(id, EV_VEC_origin, Ori)
    entity_get_vector(id, EV_VEC_v_angle, vAngles)

    notFloat_vOrigin[0] = floatround(Ori[0])
    notFloat_vOrigin[1] = floatround(Ori[1])
    notFloat_vOrigin[2] = floatround(Ori[2])

    new NewEnt = create_entity("info_target")
    entity_set_model(NewEnt, "models/stinger/stinger_rocket_frk14.mdl")
    entity_set_string(NewEnt, EV_SZ_classname, "zm_rocket")
    new Float:fl_vecminsx[3] = {-1.0, -1.0, -1.0}
    new Float:fl_vecmaxsx[3] = {1.0, 1.0, 1.0}
    entity_set_vector(NewEnt, EV_VEC_mins, fl_vecminsx)
    entity_set_vector(NewEnt, EV_VEC_maxs, fl_vecmaxsx)
    entity_set_edict(NewEnt, EV_ENT_owner, id)
    entity_set_float(NewEnt, EV_FL_health, 10000.0)
    entity_set_float(NewEnt, EV_FL_takedamage, 100.0)
    entity_set_float(NewEnt, EV_FL_dmg_take, 100.0)
    entity_set_origin(NewEnt, Ori)
    entity_set_vector(NewEnt, EV_VEC_angles, vAngles)
    entity_set_int(NewEnt, EV_INT_solid, SOLID_BBOX)
    entity_set_int(NewEnt, EV_INT_movetype, MOVETYPE_FLY)
    entity_set_size(NewEnt, Float:{-1.0,-1.0,-1.0}, Float:{1.0,1.0,1.0})
    VelocityByAim(id, 800, Vel)
    entity_set_vector(NewEnt, EV_VEC_velocity, Vel)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
    write_byte(22) 
    write_short(NewEnt) 
    write_short(beam) 
    write_byte(60) 
    write_byte(12) 
    write_byte(220) 
    write_byte(20) // 0
    write_byte(60) // 255
    write_byte(255) // 255
    message_end();

    args[0] = id
    args[1] = NewEnt
    args[2] = 1000
    args[8] = notFloat_vOrigin[0]
    args[9] = notFloat_vOrigin[1]
    args[10] = notFloat_vOrigin[2]

    emit_sound(id, CHAN_STATIC, "basebuilder/FAITH/nemesis/rpg7_shoot.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
	
    set_task(0.1, "qigong", 2004+NewEnt, args, 16)
    return PLUGIN_HANDLED_MAIN
}

public vexd_pfntouch(pToucher, pTouched)
{
    if( !is_valid_ent(pToucher) ) return

    new sz[33]
    entity_get_string(pToucher, EV_SZ_classname, sz, 32)
   
    if( equal(sz, "zm_rocket") )
    {
	remove_task(2004+pToucher)
    	new id
    	id = entity_get_edict(pToucher, EV_ENT_owner)
        new Float:Ori[3], Iori[3]
        entity_get_vector(pToucher, EV_VEC_origin, Ori)
        FVecIVec(Ori, Iori)

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(3)
        write_coord(Iori[0])
        write_coord(Iori[1])
        write_coord(Iori[2])
        write_short(boom)
        write_byte(20)
        write_byte(10)
        write_byte(0)
        message_end();

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(3)
        write_coord(Iori[0])
        write_coord(Iori[1])
        write_coord(Iori[2])
        write_short(g_spriteSmoke)	
        write_byte(90)	
        write_byte(20)			
        write_byte(10)
        message_end();
     
		new wjsl = get_playersnum(0)
		if(wjsl > 8) Missile_damage(pToucher, 52.0, 400.0)
		else Missile_damage(pToucher, 40.0, 400.0)
        remove_entity(pToucher)
    }
}

public qigong(args[]) 
{
	new aimvec[3], avgFactor
	new Float:fl_origin[3]
	new id = args[0]
	new ent = args[1]
	new speed = args[2]

	get_user_origin(id, aimvec, 3)
	entity_get_vector(ent, EV_VEC_origin, fl_origin)
	new origin[3]
	origin[0] = floatround(fl_origin[0])
	origin[1] = floatround(fl_origin[1])
	origin[2] = floatround(fl_origin[2])

	if(speed < 320)
		avgFactor = 10
	else if(speed < 680)
		avgFactor = 4
	else
		avgFactor = 2

	new velocityvec[3], length

	velocityvec[0]=aimvec[0]-origin[0]
	velocityvec[1]=aimvec[1]-origin[1]
	velocityvec[2]=aimvec[2]-origin[2]

	length = sqroot(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])

	velocityvec[0]=velocityvec[0]*speed/length
	velocityvec[1]=velocityvec[1]*speed/length
	velocityvec[2]=velocityvec[2]*speed/length

	args[8] = origin[0]
	args[9] = origin[1]
	args[10] = origin[2]

	set_task(0.1, "qigong", 2004+ent, args, 16)

	new Float:missile_health
	missile_health = Float:entity_get_float(ent, EV_FL_health)
	if(missile_health < 10000.0)
		vexd_pfntouch(ent,0)
	return PLUGIN_CONTINUE
}

public Missile_damage(inf, Float:dmg, Float:rad)
{
    new players[32], pnum, Float:rng, Float:cd, Float:ori[3], owner, cdi, killdmg, hurtdmg, health, vec[3]
    new sz[33]
	new owname[33]
    entity_get_string(inf, EV_SZ_classname, sz, 32)
    new team2, team1, ff = get_cvar_num("mp_friendlyfire")
    entity_get_vector(inf, EV_VEC_origin, ori)
    FVecIVec(ori, vec)
    owner = entity_get_edict(inf, EV_ENT_owner)
    team1 = !zp_get_user_zombie(owner)
	get_user_name(owner,owname,32)

    get_players(players, pnum, "a")
    for (new i=0; i < pnum; i++)
    {
        team2 = !zp_get_user_zombie(players[i])
        // if( team2 == team1 && !ff ) continue
        rng = Float:entity_range(inf, players[i])
        if( rng > rad ) continue
        rng = rad - rng
        cd = dmg / ( rad * rad ) * ( rng * rng )
        cdi = floatround(cd)
        Create_ScreenShake(players[i], (1<<14), (1<<13), (1<<14))

        health = get_user_health(players[i])
        health -= cdi
        if(!zp_get_user_zombie(players[i]))
        {
            if( health <= 0)
            {
                killdmg += get_user_health(players[i])
                set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
                set_msg_block(get_user_msgid("ScoreInfo"), BLOCK_ONCE)
                user_kill(players[i], 1)
                entity_set_int(players[i], EV_INT_iuser3, owner)

                message_begin(MSG_ALL, get_user_msgid("DeathMsg"))
                write_byte(owner)
                write_byte(players[i])
                write_byte(0)
                write_string(sz)
                message_end();

                message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
                write_byte(players[i])
                write_short(get_user_frags(players[i]))
                write_short(get_user_deaths(players[i]))
                write_short(0)
                write_short(get_user_team(players[i]))
                message_end();

                message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
                write_byte(owner)
                write_short((team1 != team2)?(get_user_frags(owner)+1):(get_user_frags(owner)-1))
                write_short(get_user_deaths(owner))
                write_short(0)
                write_short(get_user_team(owner))
                message_end();

                set_user_frags(owner, (team1 != team2)?(get_user_frags(owner)+1):(get_user_frags(owner)-1))
            } 
            else 
            {
                hurtdmg += cdi 
                set_user_health(players[i], health)

                message_begin(MSG_ONE, get_user_msgid("Damage"), {0,0,0}, players[i])
                write_byte(0)
                write_byte(cdi)
                write_long(DMG_BLAST)
                write_coord(vec[0])
                write_coord(vec[1])
                write_coord(vec[2])
                message_end();
				
				new Float:velocity[3]
				get_speed_vector_to_entity(inf, players[i], 300.0, velocity) //向量计算推力
				velocity[2] += 30.0 // 基础高度
				set_pev(players[i], pev_velocity, velocity)
            }
			
			//client_printc(players[i], "\g【FAITH】\y你受到来自 \t%s\y 的火箭攻击, 造成伤害 \t%d\y 点!", owname, cdi)
        }
    }
}

stock get_speed_vector_to_entity(ent1, ent2, Float:speed, Float:new_velocity[3])
{
	if (!pev_valid(ent1) || !pev_valid(ent2))
		return 0;
	
	static Float:origin1[3]
	pev(ent1,pev_origin,origin1)
	static Float:origin2[3]
	pev(ent2,pev_origin,origin2)
	
	new_velocity[0] = origin2[0] - origin1[0];
	new_velocity[1] = origin2[1] - origin1[1];
	new_velocity[2] = origin2[2] - origin1[2];
	
	static Float:num
	num = speed / vector_length(new_velocity);
				
	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;
	
	return 1;
}

stock Create_ScreenShake(id, amount, duration, frequency)
{
    message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, {0,0,0}, id) 
    write_short(amount)			        // ammount 
    write_short(duration)			// lasts this long 
    write_short(frequency)			// frequency
    message_end();
}

stock event_hud(index, red, green, blue, msg[])
{
	set_dhudmessage(red, green, blue, -1.0, 0.2, 0, 0.0, 2.0, 0.1, 0.1)
	show_dhudmessage(index, msg)
}
