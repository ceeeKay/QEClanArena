void() AA_Arena_Init =
{
        local   entity  e;
        local   float   ef;

        AA_Precache();

// debug
        AD_Curbot = 0;
        AD_Thebot = world;

        // CK: Initialize this before we grab temp1
        AA_Got_Change_Parms = 0;

        // CK: Get this before we set up map parameters
        ef = cvar("temp1");

        AA_Custom_Map = 0;
        AA_Idmap = 0;
        AA_Check_Map();
        if (ef & 64) {
                // dprint("Treating map as ID style due to temp1 settings\n");
                AA_Idmap = 1;
        }
        if (AA_Idmap) {
                AA_Fook = 1;
        } else {
                AA_Fook = 0;
        }

        // CK: Must be done before AA_Set_Defaults() or else
        // it defaults to 0 (invalid mode) and sets teamplay to 4
        AA_Game_Mode = AA_GM_NORMAL;

        AA_Set_Defaults();
        AA_Num_Players = 2;
        AA_Min_Players = 2;
        AA_Num_Teams = 2;
        AA_Num_Rounds = 9;
        AA_Force = 0;
        AA_Locked = 0;

        AA_List_Num = 1;
        AA_Init_Lists();

        AA_Game_State = AA_GAME_WAIT;
        AA_Grace = 0;
        AA_Comp_State = AA_COMP_WAIT;

        AA_Idle_Val = 15;
        AA_Idle_Time = -1;

        AA_Last_Player = world;

        AA_Setup_Hack = 0;
        AA_Report_Flag = 0;
        AA_Fullteams = 0;

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.think = AA_Arena_Think;
        e.nextthink = time + 1.0;

//v1.1
        if (ef & 4)
                AA_Pickup = 1;
        else
                AA_Pickup = 0;

        if (AA_Pickup) {
                AA_Idle_Val = 15;
                AA_Idle_Time = -1;
                AA_Game_Mode = AA_GM_COMP;
                AA_Num_Players = AA_V_Players;
                AA_Num_Rounds = AA_V_Rounds;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
                AA_Unready_All();
                AA_Respawn_All();
                AA_Show_Commands();
                // Crashes QE with illegible svc_print error
                // bprint("Mode is now Competition\n");
        }
        if (ef & 8) {
                AA_Menus = 1;
        }
        if (ef & 16) {
                AA_Fullteams = 1;
        }
//arena 3/6
        // Not a command in QE
        // localcmd("sv_aim 1\n");
};

void() AA_Arena_Think =
{
        local   float   timelimit;
        local   float   ef;
        local   entity  e;
        local   string  foos;

//        self.nextthink = time + 0.5;
        self.nextthink = time + 1;

        if (AA_Fook > 0 && AA_Fook < 5) {
                // dprint("Removing stuff\n");
                AA_Remove_Stuff();
                AA_Fook = AA_Fook + 1;
        }

        AA_Check_Empty();
        if (AA_Locked && AA_Game_Mode == AA_GM_NORMAL)
                AA_Unlock_Server();

// server timeout stuff
        if (AA_Game_Mode != AA_GM_NORMAL &&
            AA_Comp_State == AA_COMP_WAIT) {
//v1.1
               if (!AA_Pickup) {        // no timelimit on pickup server
                if (AA_Idle_Time == -1) {       // need to set the timeout
                        if (AA_Idle_Val == 0) {
                                AA_Idle_Time = -1;
                                AA_Idle_Val = 15;
                                AA_Reset_Server();
                                return;
                        } else if (AA_Idle_Val == 1) {
                                AA_Idle_Time = time + 1 * 60;
                        } else if (AA_Idle_Val == 5) {
                                AA_Idle_Time = time + 4 * 60;
                        } else {
                                AA_Idle_Time = time + 5 * 60;
                        }

                        foos = ftos(AA_Idle_Val);
                        bprint("Server will reset in ");
                        bprint(foos);
                        bprint(" minutes\n");
                } else if (time > AA_Idle_Time) {
                        AA_Idle_Time = -1;      // need to set the timeout again
                        if (AA_Idle_Val == 1) {
                                AA_Idle_Val = 0;
                        } else if (AA_Idle_Val == 5) {
                                AA_Idle_Val = 1;
                        } else {
                                AA_Idle_Val = AA_Idle_Val - 5;
                        }
                }
               }
        }

        if (AA_Game_Mode == AA_GM_ROUND) {
                AA_Competition2();
                return;
        }

        if (AA_Game_Mode == AA_GM_COMP) {
                AA_Competition();
                return;
        }

//        bprint(".\n");
	timelimit = cvar("timelimit") * 60;
        if (timelimit && time >= timelimit)
                NextLevel ();

        e = AA_Get_New(world);
        while (e) {
                AA_Add_To_List(AA_Spec1, e);
                e = AA_Get_New(e);
        }

        AA_Game_Loop();
        if (AA_Game_State == AA_GAME_WAIT) {
                AA_Set_Vars();
        }
};

entity(entity foo) AA_Get_New =
{
        local   entity  e;

        e = find(foo, classname, "p_status");
        while(e) {
//                bprint(e.owner.netname);
//                bprint("\n");
                if (e.flags == AA_NEW) {
                        return(e);
                }
                e = find(e, classname, "p_status");
        }
        return(world);
};

entity(string name, float which) AA_Make_List =
{
        local   entity  e;

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.classname = "list";
        e.netname = name;
        e.enemy = world;
        e.aiment = world;
        e.oldenemy = world;
        e.flags = which;
        e.health = -1;
        e.speed = AA_List_Num;          // list id
        AA_List_Num = AA_List_Num + 1;

        return(e);
};

void(entity list, entity foo) AA_Add_To_List =
{
        local   entity  org;

        org = list;
        while(list.enemy) {
                list = list.enemy;
        }
        list.enemy = foo;
        foo.enemy = world;
        foo.health = list.health + 1;
        foo.trigger_field = org;
        foo.target = org.target;
        foo.netname = org.netname;
        foo.flags = org.flags;
//        if (foo.owner) {
// debug
//                bprint("Adding ");
//                bprint(foo.owner.netname);
//                bprint(" to ");
//                bprint(foo.netname);
//                bprint("\n");
//        }
};

void(entity list, entity foo) AA_Remove_From_List =
{
        local   entity  e;

        e = list;
        while(e.enemy) {
                if(e.enemy == foo) {
                        e.enemy = foo.enemy;
//                        if(foo.owner) {
// debug
//                                bprint("Removing ");
//                                bprint(foo.owner.netname);
//                                bprint(" from ");
//                                bprint(list.netname);
//                                bprint("\n");
//                        }
                        AA_Count_List(list);
                        return;
                }
                e = e.enemy;
        }
};



entity(entity list) AA_Shift_List =
{
        local   entity  e;

        if (list.enemy) {
                e = list.enemy;
                AA_Remove_From_List(list, e);
                return(e);
        } else {
                return(world);
        }
};

entity(entity list, float who) AA_Get_Pos =
{
        list = list.enemy;
        while(list) {
                if (list.health == who) {
                        return(list);
                }
                list = list.enemy;
        }
        return(world);
};

void(entity foo) AA_Set_Ammo =
{
        local   entity  e;
        local   string  foos;

        foo.goalentity.style = 1;          // So far perfect

        foo.items = foo.items - (foo.items & (IT_SHOTGUN | IT_SUPER_SHOTGUN | IT_NAILGUN |
                                              IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER |
                                              IT_ROCKET_LAUNCHER | IT_LIGHTNING |
                                              IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
        if (AA_Atype == 1) {
                foo.items = foo.items | IT_ARMOR3;
                foo.armortype = 0.8;
        } else if (AA_Atype == 2) {
                foo.items = foo.items | IT_ARMOR2;
                foo.armortype = 0.6;
        } else if (AA_Atype == 3) {
                foo.items = foo.items | IT_ARMOR1;
                foo.armortype = 0.3;
        } else {
                foo.armortype = 0.0;
                foo.armorvalue = 0;
        }

        if (AA_Weapons &  1) { foo.items = foo.items | IT_LIGHTNING; }
        if (AA_Weapons &  2) { foo.items = foo.items | IT_ROCKET_LAUNCHER; }
        if (AA_Weapons &  4) { foo.items = foo.items | IT_GRENADE_LAUNCHER; }
        if (AA_Weapons &  8) { foo.items = foo.items | IT_SUPER_NAILGUN; }
        if (AA_Weapons & 16) { foo.items = foo.items | IT_NAILGUN; }
        if (AA_Weapons & 32) { foo.items = foo.items | IT_SUPER_SHOTGUN; }
        if (AA_Weapons & 64) { foo.items = foo.items | IT_SHOTGUN; }

        foo.ammo_shells = AA_Shells;
        foo.ammo_nails = AA_Nails;
        foo.ammo_rockets = AA_Rockets;
        foo.ammo_cells = AA_Cells;
        foo.health = AA_Health;
        if (foo.armortype > 0.0) {
                foo.armorvalue = AA_Armor;
        }

        e = self;
        self = foo;
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo();
        self = e;
};

void(entity foo) AA_Place_Player =
{
        local   entity  e, oldself;
        local   entity  t;
        local   vector  org, v1;

        e = foo.owner;

//v1.1
        if(!e)
                return;

        centerprint(e, "\n");

        AA_Track_Off(e);

        spawn_tfog (e.origin);

        if (AA_Idmap) {
                oldself = self;
                self = e;
                self.solid = SOLID_SLIDEBOX;
                self.movetype = MOVETYPE_WALK;
                setmodel(self, "progs/player.mdl");
                self.modelindex = modelindex_player;
                setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
                player_stand1();
                self = oldself;
                t = AA_SelectSpawnPoint("info_player_deathmatch");
                v1 = t.angles;
        } else {
                t = AA_SelectSpawnPoint("info_teleport_destination");
                v1 = t.mangle;
        }
	if (!t)
		objerror ("couldn't find target");
		
// spawn a tfog flash in front of the destination
        makevectors (v1);
	org = t.origin + 32 * v_forward;

	spawn_tfog (org);
        spawn_tdeath(t.origin, e);

// move the player and lock him down for a little while
        setorigin (e, t.origin);
        e.angles = v1;
        e.fixangle = 1;             // turn this way immediately
        e.teleport_time = time + 0.7;
        if (e.flags & FL_ONGROUND) {
                e.flags = e.flags - FL_ONGROUND;
                e.velocity = v_forward * 300;
	}
        e.flags = e.flags - e.flags & FL_ONGROUND;
        e.takedamage = DAMAGE_AIM;
        e.air_finished = time + 12;
        e.dmg = 2;

        e.goalentity.rad_time = 1;      // flag that says they're in arena
// small hack
        if (AA_Game_State == AA_GAME_ON) {
                AA_Set_Ammo(e);
        }
};

void() AA_Init_New_Player =
{
        local   string  foos;
        local   entity  e;

//        bprint("foo1\n");
        if (parm10 != 1) {
//                bprint("foo2\n");
                e = spawn();
                e.movetype = MOVETYPE_NONE;
                e.solid = SOLID_NOT;
                setmodel(e, "");
                setsize(e, '0 0 0', '0 0 0');
                setorigin(e, '0 0 -5000');
                e.classname = "p_status";
                e.flags = AA_NEW;
                e.fly_sound = 0;        // hasnt readied
                if (parm11 & 2) {
                        e.lefty = 2;            // autopl off
                } else {
                        e.lefty = 0;            // autopl on
                }
// no pl in NQ
//                if (parm11 & 32) {              // pl is messed up
////v1.1
//                        if (stof(infokey(self, "pl")) > 0) {
//                                foos = infokey(self, "pl");
//                        } else {
//                                foos = "500";
//                        }
//                        stuffcmd(self, "pushlatency -");
//                        stuffcmd(self, foos);
//                        stuffcmd(self, "\n");
//                }
                if (parm11 & 32) {
                        e.lefty = e.lefty - (e.lefty & 64);
                        e.lefty = e.lefty + 64;
                } else {
                        e.lefty = e.lefty - (e.lefty & 64);
                }
                e.movetarget = world;   // not currently tracking
                e.light_lev = 0;        // so we can track 10 times a second
                e.owner = self;
                if (parm11 & 4) {
                        e.search_time = AA_ADMIN;
                } else {
                        e.search_time = AA_NORMAL;
                }
                e.think = AA_Status_Think;
                e.nextthink = time + 1.0;
                e.trigger_field = world;
                e.speed = 0;    // not in a team
                self.goalentity = e;

// total stats for player
                e.invincible_finished = 0;
                e.invisible_finished = 0;
                e.super_damage_finished = 0;
                e.radsuit_finished = 0;

//v1.1
                e.t_length = 200;       // sbar set to 200

                if (AA_Game_Mode != AA_GM_NORMAL)
                        AA_Print_Commands(self);
                sprint(self, "Welcome to Clan Arena v1.3 by ");
                sprint(self, "Mungo");
                sprint(self, " (bml@netwiz.net)\n");

// debug
                if (self.sounds != AD_FAKE)
                if (parm10 == 0) {
                        AA_Start_Stuffs(self);
                }
                AA_Get_Change_Parms();
        } else {
                if (self.goalentity.flags != AA_NOT_READY) {
                        self.goalentity.flags = AA_NEW;
                }
                AA_Track_Off(self);             // disable tracking
        }

        self.goalentity.rad_time = 0;   // isnt in arena
        self.goalentity.style = time;    // respawn delay var
        self.takedamage = DAMAGE_NO;

        if (AA_Game_Mode != AA_GM_NORMAL &&
            AA_Comp_State != AA_COMP_WAIT &&
            AA_Comp_State != AA_COMP_OFF3) {
                AA_Clear_Team(self);    // arrived in the middle of a game
        }

        W_SetCurrentAmmo();     // get rid of weapon model
};

void(entity foo) AA_Delete_Player =
{
        local   entity  e;
        local   float   ef;

        if (foo.trigger_field) {
                AA_Remove_From_List(foo.trigger_field, foo);
//                foo.trigger_field = world;
        }
        foo.flags = AA_NULL;
};

float() AA_Count_Projectiles =
{
        local   float   ef;

        ef = 0;
        ef = ef + AA_Check_Projectile("rocket");
        ef = ef + AA_Check_Projectile("grenade");
        ef = ef + AA_Check_Projectile("spike");
        return(ef);
};

float(string foos) AA_Check_Projectile =
{
        local   entity  e;

        e = find(world, classname, foos);
        if (e) { return(1); }
        return(0);
};

void() AA_Impulses =
{
        local   entity  t;
        local   float   ef, col, col2;
        local   string  foos;
/*
// debug
        if (self.impulse == 30) {
                AD_Spawn_Fake();
        }
        else
        if (self.impulse == 31) {
                AD_Respawn();
        }
        else
        if (self.impulse == 32) {
                AA_Make_Admin(self, 1);
        }
        else
        if (self.impulse == 35) {
                AD_Select_Bot();
        }
        else
        if (self.impulse == 36) {
                AD_Ready_Bot();
        }
        else
        if (self.impulse == 38) {
                AD_Set_Team();
        }
        else
        if (self.impulse == 39) {
                AD_Killbot();
        }
        else
        if (self.impulse == 22) {
                AD_Check_Col();
        }
        else
        if (self.impulse == 23) {
                AD_Break = 1;
        }
        else
        if (self.impulse == 24) {
                self.view_ofs = '0 0 1';
                self.angles = '0 0 0';
                self.fixangle = TRUE;          // turn this way immediately
                self.takedamage = DAMAGE_NO;
                self.solid = SOLID_NOT;
                self.movetype = MOVETYPE_NONE;
                self.modelindex = 0;
                t = SelectSpawnPoint();
                setorigin (self, t.origin);
//                sprint(self, "going to spawnpoint\n");
        }
        else
// body chute
        if (self.impulse == 37) {
                AA_Shoot_Body(self);
        }
        else
*/
// normal commands
        if (self.impulse == 67) {
                AA_Sbup_Command();
        }
        else
        if (self.impulse == 72) {
                AA_Sbdown_Command();
        }
        else
        if (self.impulse == 69) {
                AA_Scores_Command(AA_Specs);
        }
        else
        if (self.impulse == 70) {
                if (!AA_Menus) {
                        AA_Ready_Command();
                } else {
                        sprint(self, "Please use the menus\n");
                }
        }
        else
        if (self.impulse == 80) {
                if (self.goalentity.search_time == AA_ADMIN) {
//v1.1
                        if (AA_Pickup) {
                                sprint(self, "Modeset disabled on a pickup server\n");
                        } else
                        AA_Change_Mode();
                }
        }
        else
        if (self.impulse == 82) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Reset_Command();
                }
        }
        else
        if (self.impulse >= 83 && self.impulse <= 89) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Toggle_Weapon(self.impulse - 83);
                }
        }
        else
        if (self.impulse == 90) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        if (AA_Game_Mode != AA_GM_NORMAL &&
                            AA_Comp_State == AA_COMP_WAIT) {
                                bprint("Forcing series to start...\n");
                                AA_Force = 1;
                        }
                }
        }
        else
        if (self.impulse == 92) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        if (AA_Game_Mode != AA_GM_NORMAL) {
//v1.1
                               if (AA_Pickup) {
                               sprint(self, "Locking disabled on a pickup server\n");
                               } else {
                                if (AA_Locked) {
                                        AA_Unlock_Server();
                                } else {
                                        AA_Lock_Server();
                                }
                               }
                        }
                }
        }
//v1.1
        else
        if (self.impulse == 66) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Tmset_Command();
                }
        }
        else
        if (self.impulse == 65) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Plup_Command();
                }
        }
        else
        if (self.impulse == 64) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Pldown_Command();
                }
        }
        else
        if (self.impulse == 63) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Tmup_Command();
                }
        }
        else
        if (self.impulse == 62) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Tmdown_Command();
                }
        }
        else
        if (self.impulse == 61) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Rdup_Command();
                }
        }
        else
        if (self.impulse == 60) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Rddown_Command();
                }
        }
        else
        if (self.impulse == 59) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Cells_Command();
                }
        }
        else
        if (self.impulse == 58) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Rockets_Command();
                }
        }
        else
        if (self.impulse == 57) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Nails_Command();
                }
        }
        else
        if (self.impulse == 56) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Shells_Command();
                }
        }
        else
        if (self.impulse == 55) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Atset_Command();
                }
        }
        else
        if (self.impulse == 54) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Amup_Command();
                }
        }
        else
        if (self.impulse == 53) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Amdown_Command();
                }
        }
        else
        if (self.impulse == 52) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Hup_Command();
                }
        }
        else
        if (self.impulse == 51) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Hdown_Command();
                }
        }
        else
        if (self.impulse == 93) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Pickup_Command();
                }
        }
        else
        if (self.impulse == 94) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Fullteams_Command();
                }
        }
        else
        if(self.impulse == 71) {
                if (self.goalentity.search_time != AA_ADMIN) {
                        self.goalentity.search_time = 1;
                        self.goalentity.attack_state = 0;
                        sprint(self, "Enter first digit of admin code:\n");
                }
        }
        else
        if(self.impulse == 99) {
                AA_Print_Commands(self);
        }
        else
        if(self.impulse == 98) {
                AA_Cprint_Command(self);
        }
        else
        if(self.impulse == 73) {
                AA_Not_Ready_Command();
        }
        else
        if(self.impulse == 74) {
                AA_List_Maps(self);
        }
        else
        if(self.impulse == 75) {
                if (self.goalentity.search_time != AA_ADMIN) {
                        AA_Elect_Command(self);
                }
        }
        else
        if(self.impulse == 50) {
                AA_Setup_Command(self);
        }
        else
        if(self.impulse == 76) {
                AA_Vote_Command(self, 1);
        }
        else
        if(self.impulse == 77) {
                AA_Vote_Command(self, 0);
        }
        else
        if(self.impulse == 78) {
                AA_Show_Settings(self);
        }
        else
        if(self.impulse == 79) {
                AA_List_Players_Command(self);
        }
        else
        if(self.impulse == 81) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_List_Maps(self);
                        self.goalentity.ideal_yaw = 5;
                        self.goalentity.attack_state = 0;
                        sprint(self, "Enter first digit of map number:\n");
                }
        }
        else
        if(self.impulse == 91) {
                if (self.goalentity.search_time == AA_ADMIN) {
                        AA_Kick_List(self);
                        self.goalentity.ideal_yaw = 7;
                        self.goalentity.attack_state = 0;
                        sprint(self, "Enter first digit of player number:\n");
                }
        }
        else
        if (self.impulse >= 40 && self.impulse <= 49) {
                if (self.goalentity.search_time == 1) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.search_time = 2;
                        sprint(self, "Enter second digit of admin code:\n");
                } else if (self.goalentity.search_time == 2) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.search_time = 3;
                        sprint(self, "Enter third digit of admin code:\n");
                } else if (self.goalentity.search_time == 3) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.search_time = 4;
                        sprint(self, "Enter fourth digit of admin code:\n");
                } else if (self.goalentity.search_time == 4) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.search_time = 0;
                        if (self.goalentity.attack_state == AA_Admin_Code) {
                                AA_Make_Admin(self, 1);
                        } else {
                                sprint(self, "Incorrect\n");
                        }
                        self.goalentity.attack_state = 0;
                } else if (self.goalentity.ideal_yaw == 5) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.ideal_yaw = 6;
                        sprint(self, "Enter second digit of map number:\n");
                } else if (self.goalentity.ideal_yaw == 6) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.ideal_yaw = 0;
                        AA_Warp_Command(self.goalentity.attack_state);
                } else if (self.goalentity.ideal_yaw == 7) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.ideal_yaw = 8;
                        sprint(self, "Enter second digit of player number:\n");
                } else if (self.goalentity.ideal_yaw == 8) {
                        self.goalentity.attack_state = self.goalentity.attack_state * 10 + self.impulse - 40;
                        self.goalentity.ideal_yaw = 0;
                        AA_Kick_Command(self, self.goalentity.attack_state);
                }
        }
        if ((self.impulse > 0 && self.impulse < 9) ||
            (self.impulse > 40 && self.impulse < 49)) {
               if (self.goalentity.ideal_yaw > 30) {
                ef = self.impulse; if (ef > 40) ef = ef - 40;
                if (self.goalentity.ideal_yaw == 31 && ef < 5) {
                        if (ef == 1) { self.goalentity.ideal_yaw = 0;
                        } else {
                        foos = ftos(ef);
                        AA_V_Teams = ef;
                        self.goalentity.ideal_yaw = 32;
                        }
                } else if (self.goalentity.ideal_yaw == 32) {
                        if (ef == 1) { self.goalentity.ideal_yaw = 0;
                        } else {
                        foos = ftos(ef);
                        AA_V_Players2 = ef;
                        self.goalentity.ideal_yaw = 33;
                        }
                } else if (self.goalentity.ideal_yaw == 33) {
                        col = 0;
                        if (ef == 1) col = 3;
                        else if (ef == 2) col = 5;
                        else if (ef == 3) col = 7;
                        else if (ef == 4) col = 9;
                        else if (ef == 5) col = 11;
                        else if (ef == 6) col = 13;
                        else if (ef == 7) col = 15;
                        else if (ef == 8) self.goalentity.ideal_yaw = 0;
                        if(col) {
                        AA_V_Rounds = col;
                        self.goalentity.ideal_yaw = 35;
                        }
                } else if (self.goalentity.ideal_yaw == 34 && ef < 6) {
                        if (ef == 5) { self.goalentity.ideal_yaw = 0;
                        } else {
                        AA_Setup_Hack = 1;
                        if (ef == 1) changelevel("dm6");
                        else if (ef == 2) changelevel("dm3");
                        else if (ef == 3) changelevel("dm2");
                        else if (ef == 4) changelevel("dm1");
                        else AA_Setup_Hack = 0;
                        }
                } else if (self.goalentity.ideal_yaw == 35 && (ef == 1 || ef == 2 || ef == 36 || ef == 37 || ef == 3)) {
                        if (ef == 3) { self.goalentity.ideal_yaw = 0;
                        } else {
                        if(ef == 1 || ef == 36) {
                                AA_Fullteams = 1;
                                bprint("Fullteams enabled\n");
                        } else {
                                AA_Fullteams = 0;
                                bprint("Fullteams disabled\n");
                        }
                        self.goalentity.ideal_yaw = 34;
                        }
                }
               } else
               if (AA_Menus &&
                   AA_Game_Mode != AA_GM_NORMAL &&
                   AA_Comp_State == AA_COMP_WAIT) {
                ef = self.impulse;
                if(ef >= 40) ef = ef - 40;
                // Map 1, 2, 4, 6 on controller D-pad to 1, 2, 3, 4
                if (ef == 4) // D-pad right (quickswitch_right)
                        ef = 3;
                if (ef == 6) // D-pad down (quickswitch_down)
                        ef = 4;
                if (!(self.goalentity.fly_sound)) { // joining a team
                        if (ef <= AA_Num_Teams) {
                                AA_Set_Team_Menus(self, ef);
                        }
                } else { // set shirt color, etc.
                        // Change 5->4 to make equivalent to 1-4 options for team choice
                        if (ef == 4) {
                                AA_Not_Ready_Command();
                                return;
                        }
                        col2 = self.goalentity.team - 1;
                        col = 0;
                        if (col2 == 13) {
                                if (ef == 1) {
                                        col = 13; // blue
                                } else if (ef == 2) {
                                        col = 2;  // light blue
                                } else if (ef == 3) {
                                        col = 11; // green blue
                                }
                        }
                        if (col2 == 4) {
                                if (ef == 1) {
                                        col = 4; // red
                                } else if (ef == 2) {
                                        col = 6;  // peach
                                } else if (ef == 3) {
                                        col = 7;  // pink
                                }
                        }
                        if (col2 == 12) {
                                if (ef == 1) {
                                        col = 12; // yellow
                                } else if (ef == 2) {
                                        col = 5;  // dark yellow
                                } else if (ef == 3) {
                                        col = 10; // tan
                                }
                        }
                        if (col2 == 3) {
                                if (ef == 1) {
                                        col = 3; // green
                                } else if (ef == 2) {
                                        col = 8;  // purple
                                } else if (ef == 3) {
                                        col = 9;  // magenta
                                }
                        }
                        if (col) {
//                                bprint(PRINT_HIGH, "fook!\n");
                                self.goalentity.colormap = col;
                                AA_Set_Color2(self, col, col2);
                        }
                }
               }
        }
};

void() AA_Precache =
{
        local   float   ef;

        ef = cvar("temp1");
//        if (stof(infokey(world, "sounds")) > 0) {
        if(!(ef & 1)) {
        precache_sound("ra/1.wav");
        precache_sound("ra/2.wav");
        precache_sound("ra/3.wav");
        precache_sound("ra/excelent.wav");
        precache_sound("ra/fight.wav");
        precache_sound("ra/flawless.wav");
        AA_MK_Sounds = 1;
        } else {
        precache_sound("sf1.wav");
        precache_sound("sf2.wav");
        precache_sound("sf3.wav");
        precache_sound("sf4.wav");
        precache_sound("sf5.wav");
        precache_sound("sf6.wav");
        precache_sound("sf7.wav");
        precache_sound("sf8.wav");
        precache_sound("sf9.wav");
        precache_sound("sffight.wav");
        precache_sound("sffinal.wav");
        precache_sound("sfround.wav");
        precache_sound("sfdraw.wav");
        precache_sound("sfko.wav");
        precache_sound("sfperf.wav");
        AA_MK_Sounds = 0;
        }
};

void(float which, float num) AA_Play_MK_Sound =
{
        local   string  wav;

        wav = string_null;
        if (which == AA_SD_COUNT) {
                if (num == 1) {
                        wav = "ra/1.wav";
                } else if (num == 2) {
                        wav = "ra/2.wav";
                } else if (num == 3) {
                        wav = "ra/3.wav";
                }
        }
//        else if (which == AA_SD_KO) {
//                wav = "sfko.wav";
//        }
        else if (which == AA_SD_FIGHT) {
                wav = "ra/fight.wav";
        }
//        else if (which == AA_SD_DRAW) {
//                wav = "sfdraw.wav";
//        }
//        else if (which == AA_SD_ROUND) {
//                wav = "sfround.wav";
//        }
        else if (which == AA_SD_PERFECT) {
                wav = "ra/flawless.wav";
        }

        if (wav == string_null) return;
        sound(world, CHAN_AUTO, wav, 1, ATTN_NONE);
};

void(float which, float num) AA_Play_Sound =
{
        local   string  wav;

        if (AA_MK_Sounds > 0) {
                AA_Play_MK_Sound(which, num);
                return;
        }

        wav = string_null;
        if (which == AA_SD_COUNT) {
                if (num == 1) {
                        wav = "sf1.wav";
                } else if (num == 2) {
                        wav = "sf2.wav";
                } else if (num == 3) {
                        wav = "sf3.wav";
                } else if (num == 4) {
                        wav = "sf4.wav";
                } else if (num == 5) {
                        wav = "sf5.wav";
                } else if (num == 6) {
                        wav = "sf6.wav";
                } else if (num == 7) {
                        wav = "sf7.wav";
                } else if (num == 8) {
                        wav = "sf8.wav";
                } else if (num == 9) {
                        wav = "sf9.wav";
                }
        }
        else if (which == AA_SD_KO) {
                wav = "sfko.wav";
        }
        else if (which == AA_SD_FIGHT) {
                wav = "sffight.wav";
        }
        else if (which == AA_SD_DRAW) {
                wav = "sfdraw.wav";
        }
        else if (which == AA_SD_ROUND) {
                wav = "sfround.wav";
        }
        else if (which == AA_SD_PERFECT) {
                wav = "sfperf.wav";
        }

        if (wav == string_null) return;
        sound(world, CHAN_AUTO, wav, 1, ATTN_NONE);
};

/*
void() AA_Set_Draw =
{
//        if (AA_First_Player == world || AA_Second_Player == world ||
//            AA_First_Player == AA_Second_Player) {
//                bprint("Error: first and second player not defined\n");
//                return;
//        }
        AA_Force_Respawn(AA_First_Player);
        AA_Force_Respawn(AA_Second_Player);
        AA_Add_To_List(AA_List1, AA_First_Player.goalentity);
        AA_Add_To_List(AA_List1, AA_Second_Player.goalentity);
        AA_Place_Player(AA_First_Player.goalentity);
        AA_Place_Player(AA_Second_Player.goalentity);
};
*/

void(entity foo) AA_Force_Respawn =
{
        local   entity  e;

        e = self;
        self = foo;
        if (!self.deadflag) {
                set_suicide_frame();
        }
        respawn();
// debug
        if(self.sounds == AD_FAKE) {
                self.movetype = MOVETYPE_NONE;
        }
        self = e;
};

void(entity list, entity foo) AA_Link_Lists =
{
        while(list.aiment) {
                list = list.aiment;
        }
        list.aiment = foo;
        foo.aiment = world;
};

float(entity list) AA_Count_Lists =
{
        local   float   ef;

        list = list.aiment;
        ef = 0;
        while(list) {
                ef = ef + AA_Count_List(list);
                list = list.aiment;
        }
        return(ef);
};

float(entity list) AA_Count_List =
{
        local   float   ef;
        local   entity  e;

        ef = 0;
        list = list.enemy;
        while (list) {
// small hack
                AA_Winner = list.owner;
                list.health = ef;
                ef = ef + 1;
                list = list.enemy;
        }
        return(ef);
};

void(entity list) AA_Set_Ammo_Lists =
{
        list = list.aiment;
        while(list) {
                AA_Set_Ammo_List(list);
                list = list.aiment;
        }
};

void(entity list) AA_Set_Ammo_List =
{
        local   entity  e;

        e = list.enemy;
        while(e) {
                AA_Set_Ammo(e.owner);
                AA_Clear_Stats(e);
                e = e.enemy;
        }
};

float(entity list) AA_Get_Players_Lists =
{
        local   entity  org;

        org = list;
        list = list.aiment;
        while(list) {
                AA_Get_Players_List(list, list.oldenemy);
                list = list.aiment;
        }
        return(AA_Count_Lists(org));
};

void(entity tolist, entity fromlist) AA_Get_Players_List =
{
        local   float   ef, ef2;
        local   entity  e;

        ef = AA_Count_List(tolist);
        ef2 = 1;
        while (ef < AA_Num_Players && ef2 == 1) {
                e = AA_Shift_List(fromlist);
                if (e) {
                        AA_Add_To_List(tolist, e);
                        AA_Place_Player(e);
                        ef = AA_Count_List(tolist);
                } else {
                        ef2 = 0;
                }
        }
};

void() AA_Init_Lists =
{
        AA_List1 = AA_Make_List("players1", AA_PLAYER);
        AA_List2 = AA_Make_List("players2", AA_PLAYER);
        AA_List3 = AA_Make_List("players3", AA_PLAYER);
        AA_List4 = AA_Make_List("players4", AA_PLAYER);
        AA_Players = AA_Make_List("players", AA_PLAYER);
        AA_Link_Lists(AA_Players, AA_List1);
        AA_Link_Lists(AA_Players, AA_List2);
        AA_Link_Lists(AA_Players, AA_List3);
        AA_Link_Lists(AA_Players, AA_List4);
        AA_Spec1 = AA_Make_List("specs1", AA_SPEC);
        AA_Spec2 = AA_Make_List("specs2", AA_SPEC);
        AA_Spec3 = AA_Make_List("specs3", AA_SPEC);
        AA_Spec4 = AA_Make_List("specs4", AA_SPEC);
        AA_Specs = AA_Make_List("specs", AA_SPEC);
        AA_List1.oldenemy = AA_Spec1;
        AA_List2.oldenemy = AA_Spec2;
        AA_List3.oldenemy = AA_Spec3;
        AA_List4.oldenemy = AA_Spec4;
        AA_Spec1.team = 13 + 1;  // team 1 is blue
        AA_Spec2.team = 4 + 1;   // team 2 is red
        AA_Spec3.team = 12 + 1;  // team 3 is yellow
        AA_Spec4.team = 3 + 1;   // team 4 is green
        AA_List1.team = 13 + 1;  // team 1 is blue
        AA_List2.team = 4 + 1;   // team 2 is red
        AA_List3.team = 12 + 1;  // team 3 is yellow
        AA_List4.team = 3 + 1;   // team 4 is green
        AA_Specs.armortype = 0;
        AA_Link_Teams();
};

void() AA_Game_Loop =
{
        local   entity  e;
        local   string  foos;
        local   float   ef;

        if (AA_Game_State == AA_GAME_WAIT) {
                ef = AA_Get_Players_Lists(AA_Players);
                if (ef >= AA_Min_Players) {
                        AA_Game_State = AA_GAME_READY;
                }
        }
        else if (AA_Game_State == AA_GAME_READY) {
//                AA_First_Player = world;
//                AA_Second_Player = world;
                AA_Draw_Hack1();
                AA_Set_Ammo_Lists(AA_Players);
                AA_Show_Players_Lists(AA_Players);
                AA_Count_Time = 6;
//                AA_Second_Toggle = 1;
                AA_Game_Time = 0;
                AA_Game_State = AA_GAME_COUNT;
                bprint("Match begins in 5 seconds\n");
        }
        else if (AA_Game_State == AA_GAME_COUNT) {
//                if (AA_Second_Toggle) {
//                        AA_Second_Toggle = 0;
//                } else {
//                        AA_Second_Toggle = 1;
                        AA_Count_Time = AA_Count_Time - 1;
                        if (AA_Count_Time > 0) {
                                foos = ftos(AA_Count_Time);
                                AA_Cprint(foos);
                                AA_Play_Sound(AA_SD_COUNT, AA_Count_Time);
                        } else {
                                AA_Play_Sound(AA_SD_FIGHT, 0);
                                AA_Cprint("FIGHT!");
                                if (AA_MK_Sounds) {
                                        e = spawn();
                                        e.think = AA_MK_Hack;
                                        e.nextthink = time + 0.2;
                                } else {
                                        bprint("The match has begun!\n");
                                        AA_Game_State = AA_GAME_ON;
                                }
                        }
//                }
        }
        else if (AA_Game_State == AA_GAME_ON) {
                ef = AA_Count_Lists(AA_Players);
                if (ef < AA_Min_Players) {
                        AA_Game_State = AA_GAME_PAUSE;
// debug 
//                        bprint("paused\n");
                }
                AA_Game_Time = AA_Game_Time + 1;
        }
        else if (AA_Game_State == AA_GAME_PAUSE) {
                ef = AA_Count_Lists(AA_Players);
                if (!ef) {      // Last person died, so it's a draw
                        bprint("Draw!\n");
                        AA_Play_Sound(AA_SD_DRAW, 0);
                        AA_Game_State = AA_GAME_DRAW;
                } else {
                        ef = AA_Count_Projectiles();
                        if (!ef) {
                                AA_Play_Sound(AA_SD_KO, 0);
                                AA_Game_State = AA_GAME_OFF;
// debug
//                                bprint("stopped\n");
                        }
                }
        }
        else if (AA_Game_State == AA_GAME_DRAW) {
//                if (AA_First_Player != world &&
//                    AA_Second_Player != world &&
//                    AA_Second_Player.classname == "player") {
                        if(AA_Is_Dead) {
//                        if (AA_First_Player.deadflag >= DEAD_DEAD &&
//                            AA_Second_Player.deadflag >= DEAD_DEAD) {
//                                AA_Clear_Lists(AA_Players);
//                                AA_Set_Draw();
                                AA_Draw_Hack2();
                        }
//                } else {
//                        dprint("Error on draw\n");
//                        AA_Clear_Arena();
//                        AA_Clear_Lists(AA_Players);
//                        AA_Game_State = AA_GAME_WAIT;
//                }
        }
        else if (AA_Game_State == AA_GAME_OFF) {
                bprint(AA_Winner.netname);
                bprint(" has won after ");
                AA_Print_Num(AA_Game_Time);
                bprint(" seconds\n");
                AA_Report_Stats(AA_Winner.goalentity, 1);
                if (AA_Game_Mode == AA_GM_NORMAL &&
                    AA_Winner != world) {
                        AA_Place_Player(AA_Winner.goalentity);
                }
                AA_Game_State = AA_GAME_WAIT;
// debug
//                bprint("restarted\n");
        }
};

void(entity list) AA_Show_Players_Lists =
{
        local   float   isfirst;

        isfirst = 1;
        list = list.aiment;
        while(list) {
                AA_Show_Players_List(list, isfirst);
                isfirst = 0;
                list = list.aiment;
        }
        bprint("\n");
};

void(entity list, float isfirst) AA_Show_Players_List =
{
        local   float   pos;
        local   entity  e;

        pos = 0;
        e = AA_Get_Pos(list, pos);
        if (!e) {
                return;
        }
        if (!isfirst) {
                bprint(" vs. ");
        }
        bprint(e.owner.netname);
        pos = pos + 1;
        e = AA_Get_Pos(list, pos);
        while(e) {
                if (AA_Game_Mode == AA_GM_NORMAL) {
                        bprint(" vs. ");
                } else {
                        bprint(" , ");
                }
                bprint(e.owner.netname);
                pos = pos + 1;
                e = AA_Get_Pos(list, pos);
        }
};

void(entity list) AA_Clear_Lists =
{
        local   entity  e;

        list = list.aiment;
        while(list) {
                list.enemy = world;
                list.armorvalue = 0;    // hasnt been "created"
// debug
//                bprint("Clearing ");
//                bprint(list.netname);
//                bprint("\n");
                list = list.aiment;
        }
};

entity(entity list, entity who, float which) AA_Get_Team =
{
        local   string  foos;
        local   string  foos2;

        AA_Clear_Empty_Teams(AA_Specs);

        list = list.aiment;
        while(list) {
// debug
                if (who.sounds == AD_FAKE)
                        foos = AD_Team_Name;
                else {
//
                foos = AA_Get_Name_For_Team(who.team - 1);
// debug
                }
                foos2 = AA_Get_Name_For_Team(list.team - 1);
                if (foos2 == foos) {
                        return(list);
                }
                list = list.aiment;
        }
        return(world);
};

void(entity list, entity who, string foos2) AA_Set_Team =
{
        local   string  foos;
        local   float   col;

// debug
        if (who.sounds == AD_FAKE)
                foos = AD_Team_Name;
        else {
//
        if (foos2 == string_null) {
                foos = AA_Get_Name_For_Team(who.team - 1);
        } else {
                foos = foos2;
        }

//        stuffcmd(who, "setinfo skin base\n");
// debug
        }
        
        if (!list.armorvalue) {      // need to create this team
                AA_Add_To_List(list, who.goalentity);
                bprint(who.netname);
                bprint(" has created team ");
                bprint(foos);
                bprint("\n");
                list.armorvalue = 1;
// debug
//                if(who.sounds != AD_FAKE) {
//                stuffcmd(who, "setinfo oldteam ");
//                stuffcmd(who, foos);
//                stuffcmd(who, "\n");
// debug
//                }
//                localcmd("localinfo ");
//                localcmd(list.target);
//                localcmd(" ");
//                localcmd(foos);
//                localcmd("\n");
//                col = AA_Get_Color(who);
                list.team = who.team;
                who.goalentity.team = list.team;
                who.goalentity.colormap = list.team - 1;
                AA_Set_Color(who, list.team - 1);
                who.goalentity.fly_sound = 1;   // has been committed
                return;
        }
        AA_Add_To_List(list, who.goalentity);
        bprint(who.netname);
        bprint(" has been added to team ");
        bprint(foos);
        bprint("\n");
// debug
//        if(who.sounds != AD_FAKE) {
//        stuffcmd(who, "setinfo oldteam ");
//        stuffcmd(who, foos);
//        stuffcmd(who, "\n");
// debug
//        }
        who.goalentity.team = list.team;
        who.goalentity.colormap = list.team - 1;
        AA_Set_Color(who, list.team - 1);
        who.goalentity.fly_sound = 1;   // has been committed
};

void(entity list, entity who) AA_Add_To_Smallest_Team =
{
        local   float   ef, ef2;
        local   entity  e;
        local   string  foos;

        list = list.aiment;
        e = world;
        while(list) {
                ef2 = AA_Count_List(list);
                if (e == world || ef2 < ef) {
                        e = list;
                        ef = ef2;
                }
                list = list.aiment;
        }

        if (!e) {
                bprint("error finding smallest team\n");
                return;
        }

        foos = AA_Get_Name_For_Team(e.team - 1);
//        stuffcmd(who, "setinfo team ");
//        stuffcmd(who, foos);
//        stuffcmd(who, "\n");
        who.team = e.team;
        who.goalentity.team = e.team;
        who.goalentity.colormap = e.team - 1;
        AA_Set_Color(who, e.team - 1);
        AA_Set_Team(e, who, foos);
};


void() AA_Ready_Command =
{
        local   string  foos;
        local   float   ef;
        local   entity  e;

        if (AA_Game_Mode == AA_GM_NORMAL) {
                if (self.goalentity.flags == AA_NOT_READY) {
                        self.goalentity.flags = AA_NEW;
                        sprint(self, "You have committed\n");
                }
                return;
        }

        if (AA_Comp_State != AA_COMP_WAIT)
                return;

        if (self.goalentity.fly_sound)  // already committed
                return;

// debug
//        bprint(self.netname);
//        bprint("\n");
        if(self.sounds == AD_FAKE)
                foos = AD_Team_Name;
        else
        foos = AA_Get_Name_For_Team(self.team - 1);

        if (foos == string_null ||
            foos == "White") {      // Hasnt got a team, so add to smallest one
                AA_Add_To_Smallest_Team(AA_Specs, self);
        }
        else
        {
                ef = 0;
                // try and add to a list that has the same teamname
                e = AA_Get_Team(AA_Specs, self, 0);
                if (e) {
// debug
//                        bprint("found a team\n");
                        AA_Set_Team(e, self, "");
                        ef = 1;
                }

                // see if we can create a team
                if (!ef) {
                        e = AA_Find_Empty_Team(AA_Specs);
                        if (e) {
                                AA_Set_Team(e, self, "");
                                ef = 1;
                        }
                }

                if(!ef) {       //otherwise, just toss to smallest team
// debug
//                        bprint("not any\n");
                        AA_Add_To_Smallest_Team(AA_Specs, self);
                }
        }
};

void() AA_Competition =
{
        local   float   ef, ef1, ef2;
        local   entity  e;
        local   string  foos, foos2;

        if (AA_Comp_State == AA_COMP_WAIT) {
                AA_Set_Vars();
                AA_Link_Teams();
                AA_Clear_Empty_Teams(AA_Specs);
              if (AA_Grace || AA_Force) {
                AA_Grace = AA_Grace - 1;
                if (AA_Grace <= 0 || AA_Force == 1) {
                        AA_Force = 0;
                        AA_Clear_Arena();
                        AA_Clear_Frags();
                        AA_Print_Teams(AA_Specs);
                        AA_Clear_Stats_Lists(AA_Specs);
                        AA_Highest_Num = 0;
                        AA_Set_Order_Lists(AA_Specs);
                        AA_Cur_Round = 1;
                        AA_Link_Teams2();
                        AA_Comp_State = AA_COMP_READY;
                }
              } else {
                ef = 0;
                e = find(world, classname, "player");
                while (e != world && ef == 0) {
                        if (!(e.goalentity.fly_sound)) {
                                ef = 1;
                        }
                        e = find(e, classname, "player");
                }
                ef2 = AA_Count_Lists(AA_Specs);
                if ((!ef && ef2 >= 2)) {        //everyone's committed, check fullteams
                       if ((AA_Fullteams && AA_Check_Fullteams()) ||
                           !AA_Fullteams) {
                        AA_Auto_Lock();
                        AA_Grace = 10;
                        bprint("Series begins in 10 seconds...\n");
                       }
                }
              }
        }
        else if (AA_Comp_State == AA_COMP_READY) {
                AA_Report_Round();
                AA_Get_Players_Lists(AA_Players);
                AA_Comp_State = AA_COMP_ON;
                AA_Game_State = AA_GAME_READY;
        }
        else if (AA_Comp_State == AA_COMP_ON) {
                ef = AA_Get_Players_Lists2(AA_Players);
                if (ef < AA_Min_Players) {
                        AA_Comp_State = AA_COMP_OFF;
                } else {
                        AA_Game_Loop();
                }
        }
        else if (AA_Comp_State == AA_COMP_OFF) {
                ef = AA_Count_Projectiles();
                if (!ef) {
                        AA_Winner = AA_Get_First_Player(AA_Players);
                        if (AA_Winner) {
                                AA_Report_Stats_Team(AA_Specs, AA_Winner.speed);
                                AA_Give_Win(AA_Specs, AA_Winner.speed);
                                bprint("Team ");
                                foos = AA_Get_Name_For_Team(AA_Winner.team - 1);
                                bprint(foos);
                                bprint(" has won the round\n");
                                AA_Cur_Round = AA_Cur_Round + 1;
                        } else {
                                bprint("Round is a draw!\n");
                        }
                        AA_Accumulate_Stats_Lists(AA_Specs);
                        AA_Clear_Lists(AA_Players);
                        AA_Clear_Lists(AA_Specs);
                        AA_Game_State = AA_GAME_OFF;
                        e = AA_Find_Winner_Team(AA_Specs, 0);
                        if (e != world ||
                            AA_Cur_Round > AA_Num_Rounds) {
                                e = AA_Find_Winner_Team(AA_Specs, 1);
                                AA_Report_Stats2(e);
                                AA_Unready_All();
                                AA_Reset_Teams(AA_Specs);
                                AA_Grace = 0;
                                AA_Comp_State = AA_COMP_WAIT;
                                AA_Auto_Unlock();
                                AA_Idle_Val = 15;
                                AA_Idle_Time = -1;
                        } else {
                                AA_Report_Stats3();     // show which team currently leads the series
                                AA_Comp_State = AA_COMP_OFF2;   // wait for players to die
                        }
                }
        }
        else if (AA_Comp_State == AA_COMP_OFF2) {
                if (AA_Is_Dead) {
                        AA_Respawn_All();
                        AA_Reset_Teams(AA_Specs);
                        AA_Comp_State = AA_COMP_OFF3;           // allow a grace period
                        AA_Idle_Time = time + 3;
//                        AA_Comp_State = AA_COMP_READY;
                }
        } else if (AA_Comp_State == AA_COMP_OFF3) {
                AA_Set_Vars2();
                AA_Get_Missing_Players();
                if (time > AA_Idle_Time) {
                        AA_Remake_Lists(AA_Specs);
                        AA_Comp_State = AA_COMP_READY;
                }
        }
};

void(entity list) AA_Set_Order_Lists =
{
        list = list.aiment;
        while(list) {
                AA_Set_Order_List(list);
                list = list.aiment;
        }
};

void(entity list) AA_Set_Order_List =
{
        local   entity  org;

        org = list;
        list = list.enemy;
        while(list) {
                if (list.fly_sound) {
                        list.lip = list.health;         // copy order into a var that wont get munged
                        if (list.health > AA_Highest_Num) {
                                AA_Highest_Num = list.health;
                        }
                        list.speed = org.speed;         // Save which team we came from
                } else {
                        list.lip = -1;
                }
                list = list.enemy;
        }
};

void() AA_Report_Round =
{
        local   string  foos;
        local   entity  e;

        foos = ftos(AA_Cur_Round);
        bprint("Round ");
        bprint(foos);
        bprint("\n");
        if (AA_MK_Sounds)       return;

        AA_Play_Sound(AA_SD_ROUND, 0);

        e = spawn();
        e.solid = SOLID_NOT;
        e.movetype = MOVETYPE_NONE;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.count = AA_Cur_Round;
        e.think = AA_Round_Think;
        e.nextthink = time + 0.8;
};

void() AA_Round_Think =
{
        AA_Play_Sound(AA_SD_COUNT, self.count);
        remove(self);
};

void(entity list) AA_Remake_Lists =
{
        list = list.aiment;
        while(list) {
                AA_Remake_List(list);
                list = list.aiment;
        }
};

void(entity list) AA_Remake_List =
{
        local   entity  e;
        local   float   ef;
        local   float   ef2;

        ef = 0;
        ef2 = AA_Cur_Round - 1;         // Shift list
        while(ef <= AA_Highest_Num) {
                while(ef2 > AA_Highest_Num) {
                        ef2 = ef2 - AA_Highest_Num - 1;
                }
                e = AA_Find_Pos(ef2, list.speed);
                if (e) {
                        AA_Add_To_List(list, e);
                }
                ef = ef + 1;
                ef2 = ef2 + 1;
        }
};

entity(float which, float id) AA_Find_Pos =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if(e.goalentity.speed == id &&
                   e.goalentity.lip == which) {
                        return(e.goalentity);
                }
                e = find(e, classname, "player");
        }
        return(world);
};

void() AA_Respawn_All =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if (e.deadflag || e.goalentity.rad_time) {
                        AA_Force_Respawn(e);
                }

                AA_Track_Off(e);

                e.goalentity.flags = AA_NEW;
                e = find(e, classname, "player");
        }
};

void() AA_Check_Map =
{
        local   string  foos;

        if (mapname == "dm1") {
                AA_Idmap = 1;
        } else if (mapname == "dm2") {
                AA_Idmap = 1;
        } else if (mapname == "dm3") {
                AA_Idmap = 1;
        } else if (mapname == "dm4") {
                AA_Idmap = 1;
        } else if (mapname == "dm5") {
                AA_Idmap = 1;
        } else if (mapname == "dm6") {
                AA_Idmap = 1;
        } else if (mapname == "dm7") {
                AA_Idmap = 1;
        } else if (mapname == "dm8") {
                AA_Idmap = 1;
        } else if (mapname == "e1m1") {
                AA_Idmap = 1;
        } else if (mapname == "e1m2") {
                AA_Idmap = 1;
        } else if (mapname == "e1m3") {
                AA_Idmap = 1;
        } else if (mapname == "e1m4") {
                AA_Idmap = 1;
        } else if (mapname == "e1m5") {
                AA_Idmap = 1;
        } else if (mapname == "e1m6") {
                AA_Idmap = 1;
        } else if (mapname == "e1m7") {
                AA_Idmap = 1;
        } else if (mapname == "e1m8") {
                AA_Idmap = 1;
        } else if (mapname == "e2m1") {
                AA_Idmap = 1;
        } else if (mapname == "e2m2") {
                AA_Idmap = 1;
        } else if (mapname == "e2m3") {
                AA_Idmap = 1;
        } else if (mapname == "e2m4") {
                AA_Idmap = 1;
        } else if (mapname == "e2m5") {
                AA_Idmap = 1;
        } else if (mapname == "e2m6") {
                AA_Idmap = 1;
        } else if (mapname == "e2m7") {
                AA_Idmap = 1;
        } else if (mapname == "e3m1") {
                AA_Idmap = 1;
        } else if (mapname == "e3m2") {
                AA_Idmap = 1;
        } else if (mapname == "e3m3") {
                AA_Idmap = 1;
        } else if (mapname == "e3m4") {
                AA_Idmap = 1;
        } else if (mapname == "e3m5") {
                AA_Idmap = 1;
        } else if (mapname == "e3m6") {
                AA_Idmap = 1;
        } else if (mapname == "e3m7") {
                AA_Idmap = 1;
        } else if (mapname == "e4m1") {
                AA_Idmap = 1;
        } else if (mapname == "e4m2") {
                AA_Idmap = 1;
        } else if (mapname == "e4m3") {
                AA_Idmap = 1;
        } else if (mapname == "e4m4") {
                AA_Idmap = 1;
        } else if (mapname == "e4m5") {
                AA_Idmap = 1;
        } else if (mapname == "e4m6") {
                AA_Idmap = 1;
        } else if (mapname == "e4m7") {
                AA_Idmap = 1;
        } else if (mapname == "e4m8") {
                AA_Idmap = 1;
        } else if (mapname == "start") {
                AA_Idmap = 1;
        } else if (mapname == "end") {
                AA_Idmap = 1;
        } else if (mapname == "test/mals_combatbox") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_aiming") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_barrierjump") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_button") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_characters") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_door") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_invis") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_laser") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_nodes") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_obstacles") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_powerup") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_rockets") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_shadow") {
                AA_Idmap = 1;
        } else if (mapname == "test/test_walkoffledge") {
                AA_Idmap = 1;
        } else if (mapname == "horde1") {
                AA_Idmap = 1;
        } else if (mapname == "horde2") {
                AA_Idmap = 1;
        } else if (mapname == "horde3") {
                AA_Idmap = 1;
        } else if (mapname == "horde4") {
                AA_Idmap = 1;
        } else if (mapname == "mgdm1") {
                AA_Idmap = 1;
        } else if (mapname == "mgdm2") {
                AA_Idmap = 1;
        } else if (mapname == "mgdm3") {
                AA_Idmap = 1;
        } else if (mapname == "mdgm4") {
                AA_Idmap = 1;
        }

//        if (!AA_Idmap) {
//                if (infokey(world, "idmap1") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap2") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap3") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap4") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap5") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap6") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap7") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap8") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap9") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap10") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap11") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap12") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap13") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap14") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap15") == mapname)  AA_Idmap = 1;
//                if (infokey(world, "idmap16") == mapname)  AA_Idmap = 1;
//        }

        dprint(mapname);
        dprint("\n");
        if(AA_Idmap) {
                dprint("Using id map rules\n");
        }
};

void() AA_Remove_Stuff =
{
        AA_Remove_Thing("item_artifact_super_damage");
        AA_Remove_Thing("item_artifact_invulnerability");
        AA_Remove_Thing("item_artifact_invisibility");
        AA_Remove_Thing("item_artifact_envirosuit");
        AA_Remove_Thing("item_shells");
        AA_Remove_Thing("item_spikes");
        AA_Remove_Thing("item_rockets");
        AA_Remove_Thing("item_cells");
        AA_Remove_Thing("item_weapon");
        AA_Remove_Thing("item_armor1");
        AA_Remove_Thing("item_armor2");
        AA_Remove_Thing("item_armorInv");
        AA_Remove_Thing("weapon_supershotgun");
        AA_Remove_Thing("weapon_supernailgun");
        AA_Remove_Thing("weapon_nailgun");
        AA_Remove_Thing("weapon_rocketlauncher");
        AA_Remove_Thing("weapon_grenadelauncher");
        AA_Remove_Thing("weapon_lightning");
        AA_Remove_Thing("item_health");
        AA_Remove_Thing("monster_ogre");
        AA_Remove_Thing("monster_demon1");
        AA_Remove_Thing("monster_shambler");
        AA_Remove_Thing("monster_knight");
        AA_Remove_Thing("monster_army");
        AA_Remove_Thing("monster_wizard");
        AA_Remove_Thing("monster_dog");
        AA_Remove_Thing("monster_zombie");
        AA_Remove_Thing("monster_boss");
        AA_Remove_Thing("monster_tarbaby");
        AA_Remove_Thing("monster_hell_knight");
        AA_Remove_Thing("monster_fish");
        AA_Remove_Thing("monster_shalrath");
        AA_Remove_Thing("monster_enforcer");
        AA_Remove_Thing("monster_oldone");
};

void(string foos) AA_Remove_Thing =
{
        local   entity  e;

        e = find(world, classname, foos);
        while(e) {
                e.solid = SOLID_NOT;
                e.modelindex = 0;
                e = find(e, classname, foos);
        }
};

void(entity foo) AA_Clear_Stats =
{
// before clearing stats, accumulate on total stats
        foo.invincible_finished = foo.invincible_finished + foo.ammo_shells;
        foo.invisible_finished = foo.invisible_finished + foo.ammo_nails;
        foo.super_damage_finished = foo.super_damage_finished + foo.ammo_rockets;
        foo.radsuit_finished = foo.radsuit_finished + foo.ammo_cells;

        foo.ammo_shells = 0;
        foo.ammo_nails = 0;
        foo.ammo_rockets = 0;
        foo.ammo_cells = 0;
};

void(entity foo, float which) AA_Report_Stats =
{
        local   string  foos;

        bprint("Self: ");
        AA_Print_Num(foo.ammo_cells);
        bprint("   Direct: ");
        AA_Print_Num(foo.ammo_nails);
        bprint("\nFired: ");
        AA_Print_Num(foo.ammo_shells);
        bprint("   Hit: ");
        AA_Print_Num(foo.ammo_rockets);
        if (which) {
                bprint("\nArmor: ");
                AA_Print_Num(foo.owner.armorvalue);
                bprint(" Health: ");
                AA_Print_Num(foo.owner.health);
                if (foo.style) {        // won with perfect
                        bprint("\nPerfect!");
                        AA_Play_Perfect();
                }
        }
        bprint("\n");
};

void(entity list) AA_Print_List =
{
        local   string  foos;

        foos = list.netname;
        list = list.enemy;
        while(list) {
                bprint(foos);
                bprint(": ");
                bprint(list.owner.netname);
                bprint("\n");
                list = list.enemy;
        }
};

void(entity foo, float id) AA_Report_Stats_Team =
{
        local   entity  list, e;
        local   float   ef;

        list = AA_Find_List(foo, id);
        if (!list) {
                bprint("Couldnt print stats for team\n");
                return;
        }

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.ammo_shells = 0;
        e.ammo_nails = 0;
        e.ammo_rockets = 0;
        e.ammo_cells = 0;
        list = e;

        ef = 0;
        while(ef <= AA_Highest_Num) {
                e = AA_Find_Pos(ef, id);
                if (e) {
                        list.ammo_shells = list.ammo_shells + e.ammo_shells;
                        list.ammo_nails = list.ammo_nails + e.ammo_nails;
                        list.ammo_rockets = list.ammo_rockets + e.ammo_rockets;
                        list.ammo_cells = list.ammo_cells + e.ammo_cells;
                }
                ef = ef + 1;
        }

        AA_Report_Stats(list, 0);
        remove(list);

//        return;
        
//        if (AA_Count_Lists(AA_Players) == 1) {
                ef = 0;
                while(ef <= AA_Highest_Num) {
                        e = AA_Find_Pos(ef, id);
                        if (e != world && e.flags == AA_PLAYER) {
                                bprint(e.owner.netname);
                                bprint(" had ");
                                AA_Print_Num(e.owner.armorvalue);
                                bprint(" armor and ");
                                AA_Print_Num(e.owner.health);
                                bprint(" health\n");
//                                ef = AA_Highest_Num + 1;
                        }
                        ef = ef + 1;
                }
//        }
};

void() AA_Competition2 =
{
        local   float   ef, ef1, ef2;
        local   entity  e;
        local   string  foos, foos2;

        if (AA_Comp_State == AA_COMP_WAIT) {
                AA_Set_Vars();
                AA_Link_Teams();
                AA_Clear_Empty_Teams(AA_Specs);
              if (AA_Grace || AA_Force) {
                AA_Grace = AA_Grace - 1;
                if (AA_Grace <= 0 || AA_Force == 1) {
                        AA_Force = 0;
                        AA_Clear_Frags();
                        AA_Print_Teams(AA_Specs);
                        AA_Clear_Stats_Lists(AA_Specs);
                        AA_Highest_Num = 0;
                        AA_Set_Order_Lists(AA_Specs);
                        AA_Cur_Round = 1;
                        AA_Num_Rounds2 = AA_Power(AA_Highest_Num + 1, AA_Counted_Teams);
                        AA_Link_Teams2();
                        AA_Comp_State = AA_COMP_READY;
                        AA_Set_Num = 1;
                        AA_Cur_Set = 0;
                }
              } else {
                ef = 0;
                e = find(world, classname, "player");
                while (e != world && ef == 0) {
                        if (!(e.goalentity.fly_sound)) {
                                ef = 1;
                        }
                        e = find(e, classname, "player");
                }
                AA_Counted_Teams = AA_Count_Teams(AA_Specs);
                ef2 = AA_Count_Lists(AA_Specs);
                if ((!ef && ef2 >= 2) &&
                    AA_Counted_Teams >= 2) {       //everyone's committed, check fullteams
                       if ((AA_Fullteams && AA_Check_Fullteams()) ||
                           !AA_Fullteams) {
                        AA_Auto_Lock();
                        AA_Grace = 10;
                        bprint("Series begins in 10 seconds...\n");
                       }
                }
              }
        }
        else if (AA_Comp_State == AA_COMP_READY) {
                AA_Report_Round();
                if (AA_Check_Forfeit(AA_Specs, AA_Cur_Set)) {   // Skip this round
                        AA_Comp_State = AA_COMP_OFF;
                        AA_Is_Dead = 1;
                } else {
                        if (AA_Cur_Set == 0) {  // First round of the set, so we need to make the lists
                                AA_Clear_Lists(AA_Specs);
                                AA_Make_Sets(AA_Specs);
                        }
                        AA_Get_Players_Lists(AA_Players);
                        AA_Comp_State = AA_COMP_ON;
                        AA_Game_State = AA_GAME_READY;
                }
        }
        else if (AA_Comp_State == AA_COMP_ON) {
                AA_Game_Loop();
                if (AA_Game_State == AA_GAME_WAIT) {
                        AA_Give_Win(AA_Specs, AA_Winner.goalentity.speed);
                        AA_Accumulate_Stats_Lists(AA_Specs);
                        AA_Comp_State = AA_COMP_OFF;
                }
        }
        else if (AA_Comp_State == AA_COMP_OFF) {
                AA_Clear_Lists(AA_Players);
                AA_Cur_Round = AA_Cur_Round + 1;
                if (AA_Cur_Round > AA_Num_Rounds2) {
                        e = AA_Find_Winner_Team(AA_Specs, 1);
                        AA_Report_Stats2(e);
                        AA_Unready_All();
                        AA_Reset_Teams(AA_Specs);
                        AA_Grace = 0;
                        AA_Comp_State = AA_COMP_WAIT;
                        AA_Idle_Val = 15;
                        AA_Idle_Time = -1;
                        AA_Clear_Lists(AA_Specs);
                        AA_Auto_Unlock();
                } else {
                        AA_Report_Stats3();     // show which team currently leads the series
                        AA_Comp_State = AA_COMP_OFF2;   // wait for players to die
                }
        }
        else if (AA_Comp_State == AA_COMP_OFF2) {
                if (AA_Is_Dead) {
                        AA_Respawn_All();
                        AA_Reset_Teams(AA_Specs);
                        AA_Comp_State = AA_COMP_OFF3;           // allow a grace period
                        AA_Idle_Time = time + 3;
                }
        }
        else if (AA_Comp_State == AA_COMP_OFF3) {
                AA_Set_Vars2();
                AA_Get_Missing_Players();
                if (time > AA_Idle_Time) {
                        AA_Cur_Set = AA_Cur_Set + 1;
                        if (AA_Cur_Set > AA_Highest_Num) {
                                AA_Cur_Set = 0;
                                AA_Set_Num = AA_Set_Num + 1;
                        }
                        AA_Comp_State = AA_COMP_READY;
                }
        }
};

float(float num, float pwr) AA_Power =
{
        local   float   ef;

        ef = 1;
        while(pwr) {
                ef = ef * num;
                pwr = pwr - 1;
        }
        return(ef);
};

float(float num, float mod, float lev) AA_Modulo =
{
        local   float   ef;
        local   float   ef2, x, y;

        ef = AA_Power(mod, lev);
        ef2 = ef * mod;

        x = floor(num / ef2);
        y = num - (x * ef2);
        x = floor(y / ef);

        return(x);
};

float(entity list) AA_Make_Sets =
{
        local   float   ef;

        ef = 0;
        list = list.aiment;
        while(list) {
                AA_Make_Set(list, ef);
                ef = ef + 1;
                list = list.aiment;
        }
};

float(entity list, float num) AA_Make_Set =
{
        local   float   ef, ef2;
        local   entity  e;

        ef2 = AA_Highest_Num + 1;
        ef = AA_Modulo(AA_Cur_Round - 1, AA_Highest_Num + 1, num);
        while(ef2) {
                e = AA_Find_Pos(ef, list.speed);
                if (e) {
                        AA_Add_To_List(list, e);
                }
                ef = ef + 1;
                if (ef > AA_Highest_Num) {
                        ef = ef - AA_Highest_Num - 1;
                }
                ef2 = ef2 - 1;
        }
};

float(entity list) AA_Count_Teams =
{
        local   float   ef;

        ef = 0;
        list = list.aiment;
        while(list) {
                ef = ef + 1;
                list = list.aiment;
        }
        return(ef);
};

void() AA_Play_Perfect =
{
        local   entity  e;

        e = spawn();
        e.solid = SOLID_NOT;
        e.movetype = MOVETYPE_NONE;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.think = AA_Perfect_Think;
        if (!AA_MK_Sounds)
                e.nextthink = time + 0.8;
        else
                e.nextthink = time + 0.1;
};

void() AA_Perfect_Think =
{
        AA_Play_Sound(AA_SD_PERFECT, 0);
        remove(self);
};

void() AA_Status_Think =
{
        local   string  foos;
        local   string  foos2, foos3, foos4, foos5;
        local   float   col, col2;
        local   entity  e, e2;

        if(self.owner.goalentity != self) {
                remove(self); return;
        }

        if (self.movetarget) {
                self.nextthink = time + 0.1;
                AA_Track(self.owner);
                if (self.light_lev) {
                        self.light_lev = self.light_lev - 1;
                        return;
                }
                self.light_lev = 4;
        } else {
                self.nextthink = time + 0.5;
        }

// debug
        if(self.owner.sounds == AD_FAKE)        return;

        if (self.ideal_yaw == 31) {     // setup menu
                centerprint(self.owner, "Type the number of teams that\nwill be playing\n\n2 thru 4\n\n1 cancels");
        } else if (self.ideal_yaw == 32) {
                centerprint(self.owner, "Type the number of players that\nwill be on each team\n\n2 thru 8\n\n1 cancels");
        } else if (self.ideal_yaw == 33) {
                centerprint(self.owner, "Choose the number of rounds:\n\n1. 3 rounds\n2. 5 rounds\n3. 7 rounds\n4. 9 rounds\n5. 11 rounds\n6. 13 rounds\n7. 15 rounds\n\n8 cancels\nDefault is 9 rounds\n");
        } else if (self.ideal_yaw == 34) {
                centerprint(self.owner, "Choose the map from the list\nOR\nUse the warp command\n\n1. dm6\n2. dm3\n3. dm2\n4. dm1\n\nOnce the map has changed\nsetup will be complete\n\n5 cancels\n");
        } else if (self.ideal_yaw == 35) {
                centerprint(self.owner, "Should the mod wait until\nall teams are full\nbefore starting the match?\n\n1. YES\n2. NO\n\n3 cancels");
        } else if (self.ideal_yaw == 39) {
                centerprint(self.owner, "----------------\nWelcome to QE Clan Arena v1.3\nwritten by Mungo\nupdated for QE by CK\n\nhttps://github.com/ceeeKay/QEClanArena\n\nHave you joined the Discord yet?\nquakeqe.com?\n----------------\n");
        }

        AA_Status_Bar(self.owner);

//        if(self.search_time == AA_ADMIN) {
//                AA_Admin_Vars(self.owner);
//        }
        if(AA_Game_Mode == AA_GM_NORMAL) {
                if(self.flags == AA_SPEC &&
                   AA_Game_State != AA_GAME_ON &&
                   AA_Game_State != AA_GAME_PAUSE) {
                        AA_Show_Rank();
                   }
        } else if (AA_Comp_State != AA_COMP_WAIT &&
                   AA_Comp_State != AA_COMP_OFF3) {
                if(self.flags == AA_SPEC &&
                   AA_Game_State == AA_GAME_ON) {
//                   AA_Game_State != AA_GAME_ON &&
//                   AA_Game_State != AA_GAME_PAUSE) {
                        AA_Show_Rank();
                }
        }
        if (AA_Menus &&
            AA_Game_Mode != AA_GM_NORMAL &&
            AA_Comp_State == AA_COMP_WAIT &&
            self.ideal_yaw < 30) {
                if (!self.fly_sound) {  // hasnt committed yet
                        foos3 = "\n";
                        foos4 = "\n";
                        if (AA_Num_Teams >= 3) {
                                foos3 = "4 or D-pad right: Yellow\n";
                        }
                        if (AA_Num_Teams >= 4) {
                                foos4 = "6 or D-pad down: Green\n";
                        }
                        col = 100;
                        e = AA_Specs.aiment;
                        while(e) {
                                col2 = AA_Count_List(e);
                                if (col2 < col) {
                                        col = col2;
                                        foos5 = AA_Get_Name_For_Team(e.team - 1);
//                                        foos5 = infokey(world, e.target);
                                }
                                e = e.aiment;
                        }
                        centerprint6(self.owner, "Please choose a team\n\n1 or D-pad left: Blue\n2 or D-pad up: Red\n", foos3, foos4, "\n\nTeam ", foos5, " needs more people\n");
                } else {
                        e = find(world, classname, "player");
                        col = 0;
                        col2 = 0;
                        while(e) {
                                col2 = col2 + 1;
                                if (!(e.goalentity.fly_sound)) {
                                        col = col + 1;
                                        e2 = e;
                                }
                                e = find(e, classname, "player");
                        }
                        foos3 = " "; foos4 = "\n";
                        if (col == 1 && col2 > 1) {
                                foos3 = e2.netname;
                                foos4 = " is holding things up!\n";
                        }

                        col = self.team - 1;
                        col = col & 15;
                        if (col == 13) {
                                foos5 = "1 or D-pad left: Blue\n2 or D-pad up: Light Blue\n4 or D-pad right: Green Blue\n";
                        } else if (col == 4) {
                                foos5 = "1 or D-pad left: Red\n2 or D-pad up: Peach\n4 or D-pad right: Tan\n";
                        } else if (col == 12) {
                                foos5 = "1 or D-pad left: Yellow\n2 or D-pad up:Dark Yellow\n4 or D-pad right: Tan\n";
                        } else if (col == 3) {
                                foos5 = "1 or D-pad left: Green\n2 or D-pad up: Purple\n4 or D-pad right: Magenta\n";
                        } else {
                                foos5 = "\n\nNONE\n\n";
                        }

                        centerprint5(self.owner, "Waiting for other players to be ready...\n\nChoose your shirt color while you wait:\n\n", foos5, "\n\nPress 6 or D-pad down to uncommit\n\n", foos3, foos4);
                }
        }

// try and reduce lag?
        if (self.lefty & 16) {
                self.lefty = self.lefty - 16;
                return;
        }
        self.lefty = self.lefty + 16;
        if(AA_Game_Mode != AA_GM_NORMAL) {
                if ((AA_Comp_State == AA_COMP_WAIT && self.fly_sound) ||
                    (AA_Comp_State == AA_COMP_ON && self.flags == AA_PLAYER)) {
//                        if (self.team != self.owner.team) {
//                                stuffcmd(self.owner, "setinfo team ");
//                                stuffcmd(self.owner, foos);
//                                stuffcmd(self.owner, "\n");
//                        }
//                        col = AA_Get_Color(self.owner);
//                        if (self.flags == AA_PLAYER) {
//                                col2 = self.trigger_field.oldenemy.team;
//                        } else {
//                                col2 = self.trigger_field.team;
//                        }
//                        if (col != col2) {
//                                AA_Set_Color(self.owner, col2 - 1);
//                        }
                        AA_Set_Color2(self.owner, self.colormap, self.team - 1);
                } else if (AA_Comp_State == AA_COMP_ON &&
                           (!self.fly_sound ||
                            (self.fly_sound && self.flags != AA_PLAYER))) {
//                        if (self.owner.team != 0) {
//                                stuffcmd(self.owner, "setinfo team \"\"\n");
//                        }
//                        col = AA_Get_Color(self.owner);
//                        if (col != 0) {
                                AA_Set_Color(self.owner, 0);
//                        }
                }
        }
};

void() AA_Show_Rank =
{
        local   string  foos, foos2;
        local   float   ef, ef2;

        if (!self.health) {
                foos2 = string_null;
                foos = "NEXT";
        } else {
                ef = self.health + 1;
                foos = ftos(ef);
                if (ef >= 11 && ef <= 13) {
                        foos2 = "th";
                } else {
                        ef2 = floor(ef / 10);
                        ef2 = ef - (ef2 * 10);
                        if (ef2 == 1) {
                                foos2 = "st";
                        } else if (ef2 == 2) {
                                foos2 = "nd";
                        } else if (ef2 == 3) {
                                foos2 = "rd";
                        } else {
                                foos2 = "th";
                        }
                }
        }
        centerprint4(self.owner, "You are\n\n", foos, foos2, "\n\nin line\n");
};

float(entity list, float pos) AA_Check_Forfeit =
{
        local   float   ef;
        local   entity  e, e2;
        local   string  foos;

        ef = 0;
        list = list.aiment;
        while(list) {
                e = AA_Find_Pos(pos, list.speed);
                if(!e) {
                        ef = ef + 1;
                        AA_Report_Forfeit(list);
                        list.style = 1;         // signals that this was forfeit
                } else {
                        e2 = list;
                        list.style = 0;         // signals they havent forfeited
                }
                list = list.aiment;
        }

        if (ef == AA_Counted_Teams - 1) {   // Remaining team wins
                foos = AA_Get_Name_For_Team(e2.team - 1);
                bprint("Team ");
                bprint(foos);
                bprint(" wins by default\n");
                e2.invincible_time = e2.invincible_time + 1;    // credit remaining team with win
        }

        if (ef >= AA_Counted_Teams - 1)
                return(TRUE);
        else
                return(FALSE);
};

void(entity list) AA_Report_Forfeit =
{
        local   string  foos;

        foos = AA_Get_Name_For_Team(list.team - 1);
        bprint("Team ");
        bprint(foos);
        bprint(" forfeits this round\n");
        list.rad_time = list.rad_time + 1;              // add a forfeit
};

void(entity list) AA_Clear_Stats_Lists =
{
        list = list.aiment;
        while(list) {
                list.invincible_time = 0;
                list.invisible_time = 0;
                list.rad_time = 0;
                AA_Clear_Stats(list);
                AA_Clear_Stats_List2(list);
                list = list.aiment;
        }
};

entity(entity list) AA_Find_Empty_Team =
{
        list = list.aiment;
        while(list) {
                if (!list.armorvalue) {
                        return(list);
                }
                list = list.aiment;
        }
        return(world);
};

entity(entity list, float id) AA_Find_List =
{
        list = list.aiment;
        while(list) {
                if (list.speed == id) {
                        return(list);
                }
                list = list.aiment;
        }
        return(world);
};

void(entity list, float id) AA_Give_Win =
{
        local   entity  e;

        list = list.aiment;
        while(list) {
                if (list.speed == id) {
                        list.invincible_time = list.invincible_time + 1;
                } else if (!list.style || AA_Game_Mode == AA_GM_COMP) {       // didnt forfeit, so lost
                        list.invisible_time = list.invisible_time + 1;
                }
                list = list.aiment;
        }
};

entity(entity list, float which) AA_Find_Winner_Team =
{
        local   float   ef2, draw;
        local   float   ef;
        local   entity  e;

        ef2 = ceil(AA_Num_Rounds / 2);
        e = world;
        ef = 0;
        draw = 0;
        list = list.aiment;
        AA_Runnerup = 0;
        while(list) {
                if (list.invincible_time > ef) {
                        AA_Runnerup = ef;
                        ef = list.invincible_time;
                        e = list;
                        draw = 0;
                } else if (list.invincible_time == ef) {
                        draw = 1;
                } else {
                        if (list.invincible_time > AA_Runnerup) {
                                AA_Runnerup = list.invincible_time;
                        }
                }
                list = list.aiment;
        }
        if (which && draw)
                return(world);
        if (e.invincible_time >= ef2 || which)
                return(e);
        return(world);
};

void(entity list) AA_Report_Stats2 =
{        
        local   entity  list, e;
        local   float   ef;
        local   string  foos;

        if (!list) {
                bprint("The series is a draw!\n");
                return;
        }

        bprint("Total stats:\n");

        AA_Report_Stats(list, 0);

        bprint("Wins: ");
        AA_Print_Num(list.invincible_time);

        bprint("  Losses: ");
        AA_Print_Num(list.invisible_time);

        if (AA_Game_Mode == AA_GM_ROUND) {
                bprint("  Forfeits: ");
                AA_Print_Num(list.rad_time);
        }
        bprint("\n");
        bprint("Team ");
        foos = AA_Get_Name_For_Team(list.team - 1);
        bprint(foos);
        bprint(" has won the series\n");
};

void(entity list) AA_Accumulate_Stats_Lists =
{
        list = list.aiment;
        while(list) {
                AA_Accumulate_Stats_List(list);
                list = list.aiment;
        }
};

void(entity list) AA_Accumulate_Stats_List =
{
        local   entity  e;
        local   float   ef;

        ef = 0;
        while (ef <= AA_Highest_Num) {
                e = AA_Find_Pos(ef, list.speed);
                if (e) {
                        list.ammo_shells = list.ammo_shells + e.ammo_shells;
                        list.ammo_nails = list.ammo_nails + e.ammo_nails;
                        list.ammo_rockets = list.ammo_rockets + e.ammo_rockets;
                        list.ammo_cells = list.ammo_cells + e.ammo_cells;
                }
                ef = ef + 1;
        }
};

void() AA_Change_Mode =
{
        if (AA_Game_Mode == AA_GM_NORMAL) {     // switch to comp mode from normal
                AA_Idle_Val = 15;
                AA_Idle_Time = -1;
                AA_Game_Mode = AA_GM_COMP;
                AA_Num_Players = AA_V_Players;
                AA_Num_Rounds = AA_V_Rounds;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
//v1.1
//                bprint("Mode is now Competition\n");
                AA_Unready_All();
                AA_Respawn_All();
                AA_Show_Commands();
//v1.1
                bprint("Mode is now Competition\n");
        } else if (AA_Game_Mode == AA_GM_COMP) {        // switch to round-robin from comp
                AA_Idle_Val = 15;
                AA_Idle_Time = -1;
                AA_Game_Mode = AA_GM_ROUND;
                AA_Num_Players = 1;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
//v1.1
//                bprint("Mode is now Round-Robin\n");
                AA_Unready_All();
                AA_Respawn_All();
                AA_Show_Commands();
//v1.1
                bprint("Mode is now Round-Robin\n");
        } else if (AA_Game_Mode == AA_GM_ROUND) {       // switch to normal from round-robin
                AA_Game_Mode = AA_GM_NORMAL;
                AA_Num_Players = AA_V_Players;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
                bprint("Mode is now Normal\n");
                AA_Unready_All();
                AA_Respawn_All();
        }
};

void(entity foo) AA_Start_Stuffs =
{
        local   entity  e;

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.owner = foo;
        e.count = 0;
        e.think = AA_Stuffs_Think;
        e.nextthink = time + 0.5;
        if(foo.goalentity)
                foo.goalentity.ideal_yaw = 39;
};

void() AA_Stuffs_Think =
{
        if (!self.owner) {
                remove(self);
                return;
        }

        self.nextthink = time + 0.2;

        if (self.count == 0) {
                stuffcmd(self.owner, "alias ready impulse 70\n");
                stuffcmd(self.owner, "alias admin impulse 71\n");
                stuffcmd(self.owner, "alias commands impulse 99\n");
                stuffcmd(self.owner, "alias notready impulse 73\n");
                stuffcmd(self.owner, "alias listmaps impulse 74\n");
                stuffcmd(self.owner, "alias scores impulse 69\n");
                self.count = 4;
        } else if (self.count == 4) {
                stuffcmd(self.owner, "alias elect impulse 75\n");
                stuffcmd(self.owner, "alias yes impulse 76\n");
                stuffcmd(self.owner, "alias no impulse 77\n");
                stuffcmd(self.owner, "alias settings impulse 78\n");
                stuffcmd(self.owner, "alias playerlist impulse 79\n");
                stuffcmd(self.owner, "alias cprint impulse 98\n");
                stuffcmd(self.owner, "alias setup impulse 50\n");
                self.count = 1;
        } else if (self.count == 1) {
                stuffcmd(self.owner, "alias 0 impulse 40\n");
                stuffcmd(self.owner, "alias 1 impulse 41\n");
                stuffcmd(self.owner, "alias 2 impulse 42\n");
                stuffcmd(self.owner, "alias 3 impulse 43\n");
                stuffcmd(self.owner, "alias 4 impulse 44\n");
                stuffcmd(self.owner, "alias sbup impulse 67\n");
                stuffcmd(self.owner, "alias sbdown impulse 72\n");
                self.count = 2;
        } else if (self.count == 2) {
                stuffcmd(self.owner, "alias 5 impulse 45\n");
                stuffcmd(self.owner, "alias 6 impulse 46\n");
                stuffcmd(self.owner, "alias 7 impulse 47\n");
                stuffcmd(self.owner, "alias 8 impulse 48\n");
                stuffcmd(self.owner, "alias 9 impulse 49\n");
                self.count = 15;
                self.nextthink = time + 3;
//                remove(self);
        } else if (self.count == 10) {
                stuffcmd(self.owner, "alias modeset impulse 80\n");
                stuffcmd(self.owner, "alias kick impulse 91\n");
                stuffcmd(self.owner, "alias force impulse 90\n");
                stuffcmd(self.owner, "alias warp impulse 81\n");
                stuffcmd(self.owner, "alias reset impulse 82\n");
                stuffcmd(self.owner, "alias lock impulse 92\n");
                stuffcmd(self.owner, "alias pickup impulse 93\n");
                self.count = 11;
        } else if (self.count == 11) {
                stuffcmd(self.owner, "alias lg impulse 83\n");
                stuffcmd(self.owner, "alias rl impulse 84\n");
                stuffcmd(self.owner, "alias gl impulse 85\n");
                stuffcmd(self.owner, "alias sng impulse 86\n");
                stuffcmd(self.owner, "alias ng impulse 87\n");
                stuffcmd(self.owner, "alias ssg impulse 88\n");
                stuffcmd(self.owner, "alias sg impulse 89\n");
                self.count = 12;
        } else if (self.count == 12) {
                stuffcmd(self.owner, "alias tmset impulse 66\n");
                stuffcmd(self.owner, "alias plup impulse 65\n");
                stuffcmd(self.owner, "alias pldown impulse 64\n");
                stuffcmd(self.owner, "alias tmup impulse 63\n");
                stuffcmd(self.owner, "alias tmdown impulse 62\n");
                stuffcmd(self.owner, "alias rdup impulse 61\n");
                stuffcmd(self.owner, "alias rddown impulse 60\n");
                stuffcmd(self.owner, "alias fullteams impulse 94\n");
                self.count = 13;
        } else if (self.count == 13) {
                stuffcmd(self.owner, "alias cells impulse 59\n");
                stuffcmd(self.owner, "alias rockets impulse 58\n");
                stuffcmd(self.owner, "alias nails impulse 57\n");
                stuffcmd(self.owner, "alias shells impulse 56\n");
                stuffcmd(self.owner, "alias atset impulse 55\n");
                stuffcmd(self.owner, "alias amup impulse 54\n");
                stuffcmd(self.owner, "alias amdown impulse 53\n");
                stuffcmd(self.owner, "alias hup impulse 52\n");
                stuffcmd(self.owner, "alias hdown impulse 51\n");
                remove(self);
        } else if (self.count == 15) {
                if(self.owner.goalentity)
                        self.owner.goalentity.ideal_yaw = 0;
                remove(self);
        }
};

void(entity foo, float which) AA_Make_Admin =
{
        local   entity  e;

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        e.owner = foo;
        e.count = 10;
        e.think = AA_Stuffs_Think;
        e.nextthink = time + 0.1;

        foo.goalentity.search_time = AA_ADMIN;
        if (which) {
                bprint(foo.netname);
                bprint(" is now an admin\n");
                AA_Print_Commands(foo);
        }
        if(foo.goalentity.ideal_yaw == 30) foo.goalentity.ideal_yaw = 31; // continue w/ setup
};

void(entity foo) AA_Print_Commands =
{
        sprint(foo, "Normal commands:\n");
        sprint(foo, "cprint.....98\n");
        sprint(foo, "sbdown.....72  notready...73\n");
        sprint(foo, "scores.....69  sbup.......67\n");
        sprint(foo, "settings...78  playerlist.79\n");
        sprint(foo, "yes........76  no.........77\n");
        sprint(foo, "listmaps...74  elect......75\n");
        sprint(foo, "ready......70  admin......71\n");
        sprint(foo, "commands...99  setup......50\n");
        if (foo.goalentity.search_time == AA_ADMIN) {
                sprint(foo, "Admin commands:\n");
                sprint(foo, "lg.........83  rl.........84\n");
                sprint(foo, "gl.........85  sng........86\n");
                sprint(foo, "ng.........87  ssg........88\n");
                sprint(foo, "sg.........89  reset......82\n");
                sprint(foo, "modeset....80  warp.......81\n");
                sprint(foo, "force......90  kick.......91\n");
                sprint(foo, "lock.......92  pickup.....93\n");
                sprint(foo, "tmset......66  plup.......65\n");
                sprint(foo, "pldown.....64  tmup.......63\n");
                sprint(foo, "tmdown.....62  rdup.......61\n");
                sprint(foo, "rddown.....60  cells......59\n");
                sprint(foo, "nails......58  rockets....57\n");
                sprint(foo, "shells.....56  atset......55\n");
                sprint(foo, "amup.......54  amdown.....53\n");
                sprint(foo, "hup........52  hdown......51\n");
                sprint(foo, "fullteams..94\n");
        }
};

void() AA_Show_Commands =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                AA_Print_Commands(e);
                e = find(e, classname, "player");
        }
};

/*
void(entity foo) AA_Admin_Vars =
{
        AA_V_Armor = AA_Check_Var(foo, "armor", AA_V_Armor);
        AA_V_Weapons = AA_Check_Var(foo, "weapons", AA_V_Weapons);
        AA_V_Atype = AA_Check_Var(foo, "atype", AA_V_Atype);
        AA_V_Health = AA_Check_Var(foo, "health", AA_V_Health);
        AA_V_Shells = AA_Check_Var(foo, "shells", AA_V_Shells);
        AA_V_Nails = AA_Check_Var(foo, "nails", AA_V_Nails);
        AA_V_Rockets = AA_Check_Var(foo, "rockets", AA_V_Rockets);
        AA_V_Cells = AA_Check_Var(foo, "cells", AA_V_Cells);
        AA_V_Teams = AA_Check_Var(foo, "teams", AA_V_Teams);
        if (AA_Game_Mode == AA_GM_COMP) {
                AA_V_Players2 = AA_Check_Var(foo, "players", AA_V_Players2);
                AA_V_Rounds = AA_Check_Var(foo, "rounds", AA_V_Rounds);
        } else if (AA_Game_Mode == AA_GM_NORMAL) {
                AA_V_Players = AA_Check_Var(foo, "players", AA_V_Players);
                AA_V_Rounds = AA_Check_Var(foo, "rounds", AA_V_Rounds);
        }
        AA_V_Teamplay = AA_Check_Var(foo, "teamplay", AA_V_Teamplay);
};

float(entity foo, string foos, float num) AA_Check_Var =
{
        local   string  foos2;
        local   float   ef;

        foos2 = infokey(foo, foos);
        if (foos2 != string_null) {
                ef = stof(foos2);
                if (ef >= 0 && ef != num) {
                        if (foo != world) {
                                bprint(foo.netname);
                                bprint(" has set ");
                                bprint(foos);
                                bprint(" to ");
                                bprint(foos2);
                                bprint("\n");
                        }
//                } else if (ef == num) {
//v1.1
//                        if (foo != world) {
//                                sprint(foo, foos);
//                                sprint(foo, " is already ");
//                                sprint(foo, foos2);
//                                sprint(foo, "\n");
//                        }
//                        ef = -1;
                } else {
                        ef = -1;
                }
//                if (foo != world) {
//                        stuffcmd(foo, "setinfo ");
//                        stuffcmd(foo, foos);
//                        stuffcmd(foo, " \"\"\n");
//                }
        } else {
                ef = -1;
        }

        if (ef == -1) {
                return(num);
        } else {
                return(ef);
        }
};
*/

void() AA_Set_Vars =
{
        local   float   ef;
        local   string  foos;

        if (AA_V_Armor < 0)     AA_V_Armor = 0;
        if (AA_V_Armor > 999)   AA_V_Armor = 999;
        if (AA_V_Weapons < 0)   AA_V_Weapons = 0;
        if (AA_V_Weapons > 127) AA_V_Weapons = 127;
        if (AA_V_Atype < 0)     AA_V_Atype = 0;
        if (AA_V_Atype > 3)     AA_V_Atype = 3;
        if (AA_V_Health <= 0)   AA_V_Health = 100;
        if (AA_V_Health > 999)  AA_V_Health = 999;
        if (AA_V_Shells < 0)    AA_V_Shells = 0;
        if (AA_V_Shells > 700)  AA_V_Shells = 700;
        if (AA_V_Nails < 0)     AA_V_Nails = 0;
        if (AA_V_Nails > 700)   AA_V_Nails = 700;
        if (AA_V_Rockets < 0)   AA_V_Rockets = 0;
        if (AA_V_Rockets > 700) AA_V_Rockets = 700;
        if (AA_V_Cells < 0)     AA_V_Cells = 0;
        if (AA_V_Cells > 700)   AA_V_Cells = 700;
        if (AA_V_Rounds < 1)    AA_V_Rounds = 1;
        if (AA_V_Rounds > 99)   AA_V_Rounds = 99;
        if (AA_V_Teams < 2)     AA_V_Teams = 2;
        if (AA_V_Teams > 4)     AA_V_Teams = 4;
        if (AA_V_Players < 1)   AA_V_Players = 1;
        if (AA_V_Players > 32)  AA_V_Players = 32;
        if (AA_V_Players2 < 1)  AA_V_Players2 = 1;
        if (AA_V_Players2 > 32) AA_V_Players2 = 32;
        if (AA_V_Teamplay < 0)  AA_V_Teamplay = 0;
        if (AA_V_Teamplay > 4)  AA_V_Teamplay = 4;

        if (AA_Game_Mode == AA_GM_NORMAL &&
            AA_V_Players < 2)
                AA_V_Players = 2;

        AA_Armor = AA_V_Armor;
        AA_Weapons = AA_V_Weapons;
        AA_Atype = AA_V_Atype; 
        AA_Health = AA_V_Health; 
        AA_Shells = AA_V_Shells; 
        AA_Nails = AA_V_Nails; 
        AA_Rockets = AA_V_Rockets; 
        AA_Cells = AA_V_Cells;
        if (AA_Game_Mode != AA_GM_ROUND) {
                AA_Num_Rounds = AA_V_Rounds;
        }
        if (AA_Game_Mode == AA_GM_COMP) {
                AA_Num_Players = AA_V_Players2;
        } else if (AA_Game_Mode == AA_GM_NORMAL) {
                AA_Num_Players = AA_V_Players;
        }
        AA_Num_Teams = AA_V_Teams;
        if (AA_Game_Mode != AA_GM_NORMAL) {
                if (AA_V_Teamplay == 0) {
                        AA_V_Teamplay = 4;
                }
        }
        ef = cvar("teamplay");
        if(ef != AA_V_Teamplay) {
                foos = ftos(AA_V_Teamplay);
                cvar_set("teamplay", foos);
        }
};

void() AA_Set_Defaults =
{
        AA_Armor = AA_V_Armor = AA_D_Armor;
        AA_Weapons = AA_V_Weapons = AA_D_Weapons;
        AA_Atype = AA_V_Atype = AA_D_Atype;
        AA_Health = AA_V_Health = AA_D_Health; 
        AA_Shells = AA_V_Shells = AA_D_Shells; 
        AA_Nails = AA_V_Nails = AA_D_Nails; 
        AA_Rockets = AA_V_Rockets = AA_D_Rockets; 
        AA_Cells = AA_V_Cells = AA_D_Cells;
        AA_Num_Rounds = AA_V_Rounds = AA_D_Rounds;
        AA_Num_Teams = AA_V_Teams = AA_D_Teams;
        AA_Num_Players = AA_V_Players = AA_D_Players;
        AA_V_Players2 = AA_D_Players2;
        AA_V_Teamplay = cvar("teamplay");
        AA_Set_Vars();
        AA_Admin_Code = AA_D_Admin_Code;
        AA_Vote_Pct = AA_D_Vote_Pct;
        AA_Vote_Time = AA_D_Vote_Time;
        AA_Vote_Pct = AA_Vote_Pct / 100.0;
};

void(entity list) AA_Print_Teams =
{
        local   float   ef;
        local   string  foos;

        ef = 1;
        list = list.aiment;
        while(list) {
                if (list.armorvalue) {
                        if (ef) {
                                ef = 0;
                        } else {
                                bprint(" vs. ");
                        }
                        foos = AA_Get_Name_For_Team(list.team - 1);
                        bprint(foos);
                }
                list = list.aiment;
        }
        bprint("\n");
};

entity(string foos) AA_SelectSpawnPoint =
{
	local   entity spot, newspot, thing;
	local   float   numspots, totalspots;
	local   float   rnum, pcount;
	local   float   rs;
	local entity spots;

	numspots = 0;
	totalspots = 0;

// choose a info_player_deathmatch point

// ok, find all spots that don't have players nearby

	spots = world;
        spot = find (world, classname, foos);
	while (spot)
	{
		totalspots = totalspots + 1;

		thing=findradius(spot.origin, 84);
		pcount=0;               
		while (thing)
		{
			if (thing.classname == "player")
				pcount=pcount + 1;                      
			thing=thing.chain;      
		}
		if (pcount == 0) {
			spot.goalentity = spots;
			spots = spot;
			numspots = numspots + 1;
		}

		// Get the next spot in the chain
                spot = find (spot, classname, foos);
	}
	totalspots=totalspots - 1;
	if (!numspots) {
		// ack, they are all full, just pick one at random
//              bprint ("Ackk! All spots are full. Selecting random spawn spot\n");
		totalspots = rint((random() * totalspots));
                spot = find (world, classname, foos);
		while (totalspots > 0) {
			totalspots = totalspots - 1;
                        spot = find (spot, classname, foos);
		}
		return spot;
	}
		
// We now have the number of spots available on the map in numspots

	// Generate a random number between 1 and numspots

	numspots = numspots - 1;
	
	numspots = rint((random() * numspots ) );

	spot = spots;
	while (numspots > 0) {
		spot = spot.goalentity;
		numspots = numspots - 1;
	}
	return spot;

};

void() AA_Not_Ready_Command =
{
        local   entity  foo;
        local   string  foos;

        foo = self.goalentity;
        if (foo.trigger_field) {
                sprint(self, "You have uncommitted\n");
                if (AA_Game_Mode != AA_GM_NORMAL) {
                        if (self.goalentity.fly_sound) {
                                bprint(self.netname);
                                bprint(" has been removed from team ");
                                foos = AA_Get_Name_For_Team(self.goalentity.team - 1);
                                bprint(foos);
                                bprint("\n");
                        }
                }
                AA_Remove_From_List(foo.trigger_field, foo);
//                foo.trigger_field = world;
                foo.target = string_null;
                foo.fly_sound = 0;
        }
        foo.flags = AA_NOT_READY;
        if (self.goalentity.rad_time) {
                AA_Force_Respawn(self);
        }
};

void() AA_Link_Teams =
{
        if(AA_Specs.armortype == AA_Num_Teams)
                return;

        AA_Specs.armortype = AA_Num_Teams;
        AA_Specs.aiment = AA_Spec1;
        AA_Spec1.aiment = AA_Spec2;
        AA_Spec2.aiment = world;
        if (AA_Num_Teams >= 3) {
                AA_Spec2.aiment = AA_Spec3;
                AA_Spec3.aiment = world;
        }
        if (AA_Num_Teams >= 4) {
                AA_Spec3.aiment = AA_Spec4;
                AA_Spec4.aiment = world;
        }
};

void(entity list) AA_Clear_Empty_Teams =
{
        local   string  foos;

        list = list.aiment;
        while(list) {
                if (list.armorvalue) {
                        if (AA_Count_List(list) < 1) {
                                list.armorvalue = 0;
                                bprint("Clearing team ");
                                foos = AA_Get_Name_For_Team(list.team - 1);
                                bprint(foos);
                                bprint("\n");
//                                localcmd("localinfo ");
//                                localcmd(list.target);
//                                if (list.target == "a_team1") {
//                                        localcmd(" one\n");
//                                }
//                                else if (list.target == "a_team2") {
//                                        localcmd(" two\n");
//                                }
//                                else if (list.target == "a_team3") {
//                                        localcmd(" three\n");
//                                }
//                                else {
//                                        localcmd(" four\n");
//                                }
                        }
                }
                list = list.aiment;
        }
};

void(entity foo) AA_List_Maps =
{
        local   string  foos, foos2;
        local   float   ef, ef2;

        sprint(foo, "00 ");
        sprint(foo, mapname);
        sprint(foo, "\n");
        ef = 1;
        ef2 = 0;
        while (ef2 < 16) {
                foos = AA_Get_Map_For_Num(ef2);
                if(foos != string_null) {
                        if (ef < 10)
                                sprint(foo, "0");
                        foos2 = ftos(ef);
                        sprint(foo, foos2);
                        sprint(foo, " ");
                        sprint(foo, foos);
                        sprint(foo, "\n");
                        ef = ef + 1;
                }
                ef2 = ef2 + 1;
        }
};

void(float which) AA_Warp_Command =
{
        local   string  foos;
        local   float   ef;

        if (which == 0) {
                changelevel(mapname);
                return;
        }

        if (which > 50) {
                AA_Choose_Idmap(which);
                return;
        }

        ef = 0;
        while(which > 0 && ef < 16) {
                foos = AA_Get_Map_For_Num(ef);
                if (foos != string_null) {
                        which = which - 1;
                }
                ef = ef + 1;
        }
        if (foos == string_null) {
                sprint(self, "No such map\n");
                return;
        }
        // CK: Treat all the warp maps as custom (id style) maps
        // if (ef >= 8) {
                AA_Custom_Map = 1;
        // } else {
        //         AA_Custom_Map = 0;
        // }
        changelevel(foos);
};

void(float num) AA_Choose_Idmap =
{
        local   string  foos;
        local   string  foos2;

        foos = string_null;

        if (num == 51) {
                foos = "dm1";
        } else if (num == 52) {
                foos = "dm2";
        } else if (num == 53) {
                foos = "dm3";
        } else if (num == 54) {
                foos = "dm4";
        } else if (num == 55) {
                foos = "dm5";
        } else if (num == 56) {
                foos = "dm6";
//        } else if (num == 57) {
//                foos = "dm7";
        } else if (num == 58) {
                foos = "start";
        } else if (num == 61) {
                foos = "e1m1";
        } else if (num == 62) {
                foos = "e1m2";
        } else if (num == 63) {
                foos = "e1m3";
        } else if (num == 64) {
                foos = "e1m4";
        } else if (num == 65) {
                foos = "e1m5";
        } else if (num == 66) {
                foos = "e1m6";
        } else if (num == 67) {
                foos = "e1m7";
        } else if (num == 68) {
                foos = "e1m8";
        } else if (num == 71) {
                foos = "e2m1";
        } else if (num == 72) {
                foos = "e2m2";
        } else if (num == 73) {
                foos = "e2m3";
        } else if (num == 74) {
                foos = "e2m4";
        } else if (num == 75) {
                foos = "e2m5";
        } else if (num == 76) {
                foos = "e2m6";
        } else if (num == 77) {
                foos = "e2m7";
        } else if (num == 81) {
                foos = "e3m1";
        } else if (num == 82) {
                foos = "e3m2";
        } else if (num == 83) {
                foos = "e3m3";
        } else if (num == 84) {
                foos = "e3m4";
        } else if (num == 85) {
                foos = "e3m5";
        } else if (num == 86) {
                foos = "e3m6";
        } else if (num == 87) {
                foos = "e3m7";
        } else if (num == 91) {
                foos = "e4m1";
        } else if (num == 92) {
                foos = "e4m2";
        } else if (num == 93) {
                foos = "e4m3";
        } else if (num == 94) {
                foos = "e4m4";
        } else if (num == 95) {
                foos = "e4m5";
        } else if (num == 96) {
                foos = "e4m6";
        } else if (num == 97) {
                foos = "e4m7";
        } else if (num == 98) {
                foos = "e4m8";
        } else if (num == 99) {
                foos = "end";
        }
        if (foos == string_null) {
                sprint(self, "No such map\n");
                return;
        }

//        foos2 = infokey(world, "a_lastmap");
//        if (foos2 == string_null) {
//                localcmd("localinfo a_lastmap ");
//                localcmd(mapname);
//                localcmd("\n");
//        }
        changelevel(foos);
};

void(entity foo) AA_Elect_Command =
{
        local   entity  e;
        local   float   ef;
        local   string  foos;

        if (AA_Vote_Ent) {
                sprint(foo, "Please wait for current voting to end\n");
                return;
        }
        if (AA_Vote_Pct <= 0.0 || AA_Vote_Time <= 0.0)
                return;         // Voting disabled

        e = spawn();
        e.movetype = MOVETYPE_NONE;
        e.solid = SOLID_NOT;
        setmodel(e, "");
        setsize(e, '0 0 0', '0 0 0');
        setorigin(e, '0 0 -5000');
        AA_Vote_Ent = e;

        ef = 0;
        e = find(world, classname, "player");
        while (e) {
                ef = ef + 1;
                e.goalentity.cnt = 1;   // Can vote flag
                e = find(e, classname, "player");
        }

        AA_Vote_Ent.ammo_shells = ef;           // total votes
        AA_Vote_Ent.ammo_nails = 0;             // total cast
        AA_Vote_Ent.ammo_rockets = 0;           // total in favor
        AA_Vote_Ent.ammo_cells = rint(ef * AA_Vote_Pct);        // total yes needed
        if (!AA_Vote_Ent.ammo_cells) {
                AA_Vote_Ent.ammo_cells = 1;
        }
        AA_Vote_Ent.search_time = time + AA_Vote_Time;
        AA_Vote_Ent.owner = foo;

        bprint(foo.netname);
        bprint(" has requested admin rights\n");
        foos = ftos(AA_Vote_Time);
        bprint("Voting ends in ");
        bprint(foos);
        bprint(" seconds\n");

        AA_Vote_Ent.think = AA_Vote_Think;
        AA_Vote_Ent.nextthink = AA_Vote_Ent.search_time;

        AA_Vote_Command(foo, 1);
};

void() AA_Vote_Think =
{
        AA_End_Vote();
};

void(entity foo, float which) AA_Vote_Command =
{
        local   string  foos;

        if (!AA_Vote_Ent) {     // no vote on
                return;
        }

        if (!AA_Vote_Ent.owner) {       // no one to vote for
                remove(AA_Vote_Ent);
                AA_Vote_Ent = world;
                return;
        }

        if (!foo.goalentity.cnt) {
                return;         // has already voted
        }

        foo.goalentity.cnt = 0;

        AA_Vote_Ent.ammo_nails = AA_Vote_Ent.ammo_nails + 1;
        AA_Vote_Ent.ammo_rockets = AA_Vote_Ent.ammo_rockets + which;

        bprint("Total votes cast: ");
        AA_Print_Num(AA_Vote_Ent.ammo_nails);
        bprint("  needed: ");
        AA_Print_Num(AA_Vote_Ent.ammo_cells);
        bprint("  in favor: ");
        AA_Print_Num(AA_Vote_Ent.ammo_rockets);
        bprint("\n");

        if (AA_Vote_Ent.ammo_rockets >= AA_Vote_Ent.ammo_cells ||
            AA_Vote_Ent.ammo_nails >= AA_Vote_Ent.ammo_shells ||
            (AA_Vote_Ent.ammo_cells - AA_Vote_Ent.ammo_rockets) > (AA_Vote_Ent.ammo_shells - AA_Vote_Ent.ammo_nails)) {
                AA_End_Vote();
        }
};

void() AA_End_Vote =
{
        if (AA_Vote_Ent.ammo_rockets >= AA_Vote_Ent.ammo_cells) {
                AA_Make_Admin(AA_Vote_Ent.owner, 1);
        } else {
                bprint(AA_Vote_Ent.owner.netname);
                bprint(" was not admin'd\n");
        }
        remove(AA_Vote_Ent);
        AA_Vote_Ent = world;
};

void() AA_Clear_Arena =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if(e.goalentity.rad_time) {
                        AA_Force_Respawn(e);
                }
                e = find(e, classname, "player");
        }
};

void(entity who) AA_Show_Settings =
{
        local   string  foos;
        local   float   ef;

        sprint(who, "Weapons: ");
        if (AA_Weapons &  1) sprint(who, "lg ");
        if (AA_Weapons &  2) sprint(who, "rl ");
        if (AA_Weapons &  4) sprint(who, "gl ");
        if (AA_Weapons &  8) sprint(who, "sng ");
        if (AA_Weapons & 16) sprint(who, "ng ");
        if (AA_Weapons & 32) sprint(who, "ssg ");
        if (AA_Weapons & 64) sprint(who, "sg ");
        sprint(who, "\nAtype: ");
        AA_Print_Num2(AA_Atype, who);
        sprint(who, "  Armor: ");
        AA_Print_Num2(AA_Armor, who);
        sprint(who, "  Health: ");
        AA_Print_Num2(AA_Health, who);
        sprint(who, "\nShells: ");
        AA_Print_Num2(AA_Shells, who);
        sprint(who, "  Nails: ");
        AA_Print_Num2(AA_Nails, who);
        sprint(who, "\nRockets: ");
        AA_Print_Num2(AA_Rockets, who);
        sprint(who, "  Cells: ");
        AA_Print_Num2(AA_Cells, who);
        sprint(who, "\nTeamplay: ");
        ef = cvar("teamplay");
        AA_Print_Num2(ef, who);

        sprint(who, "  Mode: ");
        if (AA_Game_Mode == AA_GM_NORMAL) {
                sprint(who, "Normal");
        } else if (AA_Game_Mode == AA_GM_COMP) {
                sprint(who, "Competition");
        } else if (AA_Game_Mode == AA_GM_ROUND) {
                sprint(who, "Round");
        }

        sprint(who, "\nPlayers: ");
        foos = ftos(AA_Num_Players);
        sprint(who, foos);

        sprint(who, "  Teams: ");
        foos = ftos(AA_Num_Teams);
        sprint(who, foos);

        if(AA_Game_Mode == AA_GM_COMP) {
                sprint(who, "  Rounds: ");
                foos = ftos(AA_Num_Rounds);
                sprint(who, foos);
        }
        sprint(who, "\nFullteams: ");
        if(AA_Fullteams) {
                sprint(who, "on");
        } else {
                sprint(who, "off");
        }
        sprint(who, "  Centerprint: ");
        if(who.goalentity.lefty & 64) {
                sprint(who, "on\n");
        } else {
                sprint(who, "off\n");
        }
};

float(entity list) AA_Get_Players_Lists2 =
{
        local   float   ef, ef2;

        ef2 = 0;
        list = list.aiment;
        while(list) {
                AA_Get_Players_List(list, list.oldenemy);
                ef = AA_Count_List(list);
                if (ef > 0) {
                        ef2 = ef2 + 1;
                }
                list = list.aiment;
        }
        return(ef2);
};

void(entity who) AA_List_Players_Command =
{
        local   entity  e;
        local   string  foos;

        if (AA_Game_Mode != AA_GM_NORMAL) {
                sprint(who, "Team  ");
        }
        sprint(who, "Player  F / D / H / S\n");
        e = find(world, classname, "player");
        while(e) {
                if (AA_Game_Mode != AA_GM_NORMAL) {
                        if (e.goalentity.fly_sound) {
                                foos = AA_Get_Name_For_Team(who.goalentity.team - 1);
                                sprint(who, foos);
                                sprint(who, "  ");
                        } else {
                                sprint(who, "      ");
                        }
                }
                sprint(who, e.netname);
                sprint(who, "  ");
                AA_Print_Num2(e.goalentity.invincible_finished +
                              e.goalentity.ammo_shells, who);
                sprint(who, "/");
                AA_Print_Num2(e.goalentity.invisible_finished +
                              e.goalentity.ammo_nails, who);
                sprint(who, "/");
                AA_Print_Num2(e.goalentity.super_damage_finished +
                              e.goalentity.ammo_rockets, who);
                sprint(who, "/");
                AA_Print_Num2(e.goalentity.radsuit_finished +
                              e.goalentity.ammo_cells, who);
                sprint(who, "\n");
                e = find(e, classname, "player");
        } 
};

void() AA_Unready_All =        // Only called by change mode to clear the ready flag
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if (e.goalentity) {
                        e.goalentity.fly_sound = 0;
                }
                e = find(e, classname, "player");
        }
};

entity(entity list) AA_Get_First_Player =
{
        local   entity  e;

        list = list.aiment;
        while(list) {
                e = AA_Get_Pos(list, 0);
                if (e) {
                        return(e);
                }
                list = list.aiment;
        }
};

void() AA_Get_Change_Parms =
{
        if (AA_Got_Change_Parms)
                return;

        if (!parm12) {
                return;         // no change parms set
        }

        AA_Got_Change_Parms = 1;

        AA_V_Players = parm1;
        AA_V_Mode = parm2;
        AA_V_Players2 = parm3;
        AA_V_Armor = parm4;
        AA_V_Health = parm5;
        AA_V_Weapons = parm6;
        AA_V_Atype = parm7;
        AA_V_Rounds = parm8;
        AA_V_Teams = parm9;
        AA_V_Shells = parm13;
        AA_V_Nails = parm14;
        AA_V_Rockets = parm15;
        AA_V_Cells = parm16;
        AA_V_Teamplay = floor(parm12 / 4);
        if (parm11 & 8)
                AA_Fullteams = 1;
        else
                AA_Fullteams = 0;

        if (AA_V_Mode == 1) {
                AA_Game_Mode = AA_GM_COMP;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
//                cvar_set("teamplay", "2");
        } else if (AA_V_Mode == 2) {
                AA_Game_Mode = AA_GM_ROUND;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
//                cvar_set("teamplay", "2");
        } else {
                AA_Game_Mode = AA_GM_NORMAL;
                AA_Game_State = AA_GAME_WAIT;
                AA_Clear_Lists(AA_Players);
//                cvar_set("teamplay", "0");
        }

        if (parm11 & 64) {
                // dprint("param11 has 64\n");
                AA_Idmap = 1;
                AA_Fook = 1;
        }
};

/*
float(float parm, float which, float pow) AA_Read_Parm =
{
        local   float   ef1, ef2;

        if (pow == 1) {
                ef1 = 256;
        } else {
                ef1 = 65536;
        }

        // bleed off the higher part
        if ((pow == 1 && which != 3) ||
            (pow == 2 && which != 1)) {
                ef2 = AA_Power(ef1, which + 1);
                parm = parm - (floor(parm / ef2) * ef2);
        }
        // bleed off the lower part
        ef2 = AA_Power(ef1, which);
        parm = floor(parm / ef2);
        return(parm);
};
*/

void() AA_Set_Change_Parms =
{
        local   float   ef;

        parm1 = AA_V_Players;
        if (AA_Game_Mode == AA_GM_COMP) ef = 1;
        else if (AA_Game_Mode == AA_GM_ROUND) ef = 2;
        else                            ef = 3;
        parm2 = ef;
        parm3 = AA_V_Players2;
        parm4 = AA_Armor;
        parm5 = AA_Health;
        parm6 = AA_Weapons;
        parm7 = AA_Atype;
        parm8 = AA_Num_Rounds;
        parm9 = AA_Num_Teams;
        parm12 = 1;     // change parms set
        parm12 = parm12 + teamplay * 4;
        parm13 = AA_Shells;
        parm14 = AA_Nails;
        parm15 = AA_Rockets;
        parm16 = AA_Cells;
        if (AA_Fullteams)
                parm11 = parm11 + 8;
        else
                parm11 = parm11 - (parm11 & 8);
        if (AA_Custom_Map) {
                parm11 = parm11 - (parm11 & 64);
                parm11 = parm11 + 64;
        }
};

/*
float(float parmval, float val, float which, float pow) AA_Set_Parm =
{
        local   float   ef;

        if (pow == 1) {
                ef = 256;
        } else {
                ef = 65536;
        }
        ef = AA_Power(ef, which);
        ef = val * ef;
        return(parmval + ef);
};
*/

void() AA_Toss_Player =
{
        local   vector  toss;
        local   entity  who;

        who = self.owner;

        who.solid = SOLID_NOT;
        who.goalentity.style = time + 1;
        toss = '0 0 0';
        toss_y = random() * 360;
        makevectors(toss);
        who.velocity = v_forward * 1000;
        who.velocity_z = 200;
        who.flags = who.flags - (who.flags & FL_ONGROUND);
        self.think = AA_Solid_Player;
        self.nextthink = time + 1;
};

void() AA_Solid_Player =
{
        self.owner.solid = SOLID_SLIDEBOX;
        spawn_tdeath(self.owner.origin, self.owner);
        traceline(self.owner.origin - self.mins, self.owner.origin + self.owner.maxs, FALSE, self.owner);
        if(trace_ent.solid == SOLID_BSP) {      // ended up in a platform
                AA_Place_Player(self.owner.goalentity);
//                AA_Toss_Player();
                return;
        }
        remove(self);
};

void() AA_Reset_Server =
{
// put server back into normal mode
        bprint("Setting server back to normal mode...\n");
        AA_Num_Players = AA_V_Players = 2;
        AA_Game_Mode = AA_GM_NORMAL;
        AA_Game_State = AA_GAME_WAIT;
        AA_Clear_Lists(AA_Players);
        AA_Clear_Lists(AA_Specs);
//        cvar_set("teamplay", "0");
        AA_Unready_All();
        AA_Respawn_All();
};

void() AA_Report_Stats3 =
{
        local   entity  e, e2;
        local   string  foos;
        local   float   ef, ef2;

        e = AA_Find_Winner_Team(AA_Specs, 1);
        if (e) {
                bprint("Team ");
                foos = AA_Get_Name_For_Team(e.team - 1);
                bprint(foos);
                ef = e.invincible_time;
                ef = ef - AA_Runnerup;
                bprint(" leads the series by ");
                AA_Print_Num(ef);
                bprint(" wins");
                if (AA_Game_Mode == AA_GM_COMP) {
                        bprint(" and needs ");
                        ef2 = ceil(AA_Num_Rounds / 2);
                        ef = ef2 - e.invincible_time;
                        AA_Print_Num(ef);
                        bprint(" more");
                }
                bprint("\n");
        } else {
                // the series is a tie, find all teams that are tied
                ef = 0;
                e2 = AA_Specs;
                e2 = e2.aiment;
                while(e2) {
                        if (e2.invincible_time > ef) {
                                ef = e2.invincible_time;
                        }
                        e2 = e2.aiment;
                }
                bprint("The series is tied between teams ");
                e2 = AA_Specs;
                e2 = e2.aiment;
                ef2 = 0;
                while(e2) {
                        if (e2.invincible_time == ef) {
                                if (ef2) {
                                        bprint(" and ");
                                }
                                ef2 = 1;
                                foos = AA_Get_Name_For_Team(e2.team - 1);
                                bprint(foos);
                        }
                        e2 = e2.aiment;
                }
                bprint("\n");
        }
};

void(entity list) AA_Reset_Teams =
{
        local   entity  e, list;
        local   string  foos;

        list = list.aiment;
        while(list) {
                AA_Reset_Team_List(list);
                list = list.aiment;
        }
};

void(entity list) AA_Reset_Team_List =
{
        local   float   ef;
        local   entity  e;
        local   string  foos;

        ef = 0;
        while(ef <= AA_Highest_Num) {
                e = AA_Find_Pos(ef, list.speed);
                if (e) {
// debug
                        if(e.owner.sounds != AD_FAKE) {
                        foos = AA_Get_Name_For_Team(list.team - 1);
//                        stuffcmd(e.owner, "setinfo team ");
//                        stuffcmd(e.owner, foos);
//                        stuffcmd(e.owner, "\n");
                        AA_Set_Color(e.owner, list.team - 1);
// debug
                        }
                }
                ef = ef + 1;
        }
};

void(entity who) AA_Clear_Team =
{
        local   string  foos;

//debug
        if (who.sounds != AD_FAKE)
        if (AA_Game_Mode != AA_GM_NORMAL) {
//                foos = infokey(who, "team");
//                stuffcmd(who, "setinfo oldteam ");
//                stuffcmd(who, foos);
//                stuffcmd(who, "\n");
//                stuffcmd(who, "setinfo team \"\"\n");
                AA_Set_Color(who, 0);
        }
};

void() AA_Clear_Frags =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                e.frags = 0;
                e = find(e, classname, "player");
        }
};

void() AA_Reset_Command =
{
        if (AA_Game_Mode == AA_GM_COMP) {
                AA_Idle_Val = 15;
                AA_Idle_Time = -1;
                AA_Num_Players = AA_V_Players;
                AA_Num_Rounds = AA_V_Rounds;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
                AA_Unready_All();
                AA_Respawn_All();
                AA_Show_Commands();
        } else if (AA_Game_Mode == AA_GM_ROUND) {
                AA_Idle_Val = 15;
                AA_Idle_Time = -1;
                AA_Num_Players = 1;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
                AA_Unready_All();
                AA_Respawn_All();
                AA_Show_Commands();
        } else if (AA_Game_Mode == AA_GM_NORMAL) {
                AA_Num_Players = AA_V_Players;
                AA_Min_Players = 2;
                AA_Game_State = AA_GAME_WAIT;
                AA_Grace = 0;
                AA_Comp_State = AA_COMP_WAIT;
                AA_Clear_Lists(AA_Players);
                AA_Clear_Lists(AA_Specs);
                AA_Unready_All();
                AA_Respawn_All();
        }
        bprint("Server reset...\n");
};

void(float which) AA_Toggle_Weapon =
{
        local   float   ef, ef2;
        local   string  foos;

        ef2 = AA_V_Weapons;

        if (which == 0) {
                foos = "Lightning Gun";
        } else if (which == 1) {
                foos = "Rocket Launcher";
        } else if (which == 2) {
                foos = "Grenade Launcher";
        } else if (which == 3) {
                foos = "Super Nailgun";
        } else if (which == 4) {
                foos = "Nailgun";
        } else if (which == 5) {
                foos = "Super Shotgun";
        } else if (which == 6) {
                foos = "Shotgun";
        } else {
                return;
        }

        ef = AA_Power(2, which);
        if (ef2 & ef) {
                bprint(self.netname);
                bprint(" has disabled the ");
                bprint(foos);
                bprint("\n");
                ef2 = ef2 - (ef2 & ef);
        } else {
                bprint(self.netname);
                bprint(" has enabled the ");
                bprint(foos);
                bprint("\n");
                ef2 = ef2 + ef;
        }
        AA_V_Weapons = ef2;
};

void(entity who, float col) AA_Set_Color =
{
        local   string  foos;

// debug
        if (who.sounds == AD_FAKE)
                return;

        if (col) {
                foos = ftos(col);
        } else {
                foos = "0";
        }

        stuffcmd(who, "color ");
        stuffcmd(who, foos);
        stuffcmd(who, " ");
        stuffcmd(who, foos);
        stuffcmd(who, "\n");
};

float(entity who) AA_Get_Color =
{
        local   float   n1, n2;
        local   string  foos;

// debug
        if (who.sounds == AD_FAKE)
                return(2 * 256 + 2);

//        foos = infokey(who, "topcolor");
//        n1 = stof(foos);
//        foos = infokey(who, "bottomcolor");
//        n2 = stof(foos);
        n1 = 0;
        n2 = who.team;
        return(n1 * 256 + n2);
};

void() AA_Get_Missing_Players =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if(!e.goalentity.fly_sound) {   // hasnt been committed
//                        bprint("checking ");
//                        bprint(e.netname);
//                        bprint("\n");
                        AA_Check_Missing_Player(e);
                }
                e = find(e, classname, "player");
        }
};

void(entity who) AA_Check_Missing_Player =
{
        local   entity  e, list;
        local   float   ef;
        local   string  foos;

        list = AA_Get_Team(AA_Specs, who, 1);
//        if(!list)  bprint("oldteam didnt match\n");
        if(!list)  return;
        ef = 0;
        while(ef <= AA_Highest_Num) {
                e = AA_Find_Pos(ef, list.speed);
                if (!e) {       // we can fill this spot
//                        bprint("tying to fill spot in team ");
//                        foos = infokey(world, list.target);
//                        bprint(foos);
//                        bprint("\n");
//                        AA_Set_Team(list, who, foos);
                        who.goalentity.fly_sound = 1;
                        who.goalentity.lip = ef;
                        who.goalentity.speed = list.speed;
//                        stuffcmd(who, "setinfo skin base\n");
                        return;
                }
                ef = ef + 1;
        }
};

void(float num) AA_Print_Num =
{
        local   string  foos;

        if (num > 0) {
                foos = ftos(num);
        } else {
                foos = "0";
        }
        bprint(foos);
};

void(float num, entity who) AA_Print_Num2 =
{
        local   string  foos;

        if (num > 0) {
                foos = ftos(num);
        } else {
                foos = "0";
        }
        sprint(who, foos);
};

void(entity list) AA_Clear_Stats_List2 =
{
        list = list.enemy;
        while(list) {
                list.ammo_shells = 0;
                list.ammo_nails = 0;
                list.ammo_rockets = 0;
                list.ammo_cells = 0;
                list.invincible_finished = 0;
                list.invisible_finished = 0;
                list.super_damage_finished = 0;
                list.radsuit_finished = 0;
                list = list.enemy;
        }
};

void(entity list) AA_Scores_Command =
{
        local   entity  e;
        local   string  foos;

        if (AA_Game_Mode == AA_GM_NORMAL)       return;
        if (AA_Comp_State == AA_COMP_WAIT)      return;

        sprint(self, "Current round is ");
        AA_Print_Num2(AA_Cur_Round, self);
        sprint(self, " series ends at ");
        if (AA_Game_Mode == AA_GM_ROUND) {
                AA_Print_Num2(AA_Num_Rounds2, self);
        } else {
                AA_Print_Num2(AA_Num_Rounds, self);
        }
        sprint(self, "\n");
        list = list.aiment;
        while(list) {
//                if (list.armorvalue) {
                        sprint(self, "Team: ");
                        foos = AA_Get_Name_For_Team(list.team - 1);
                        sprint(self, foos);
                        sprint(self, "  Wins: ");
                        AA_Print_Num2(list.invincible_time, self);
                        sprint(self, "  Losses: ");
                        AA_Print_Num2(list.invisible_time, self);
                        if (AA_Game_Mode == AA_GM_ROUND) {
                                sprint(self, "  Forfeits: ");
                                AA_Print_Num2(list.rad_time, self);
                        }
                        sprint(self, "\n");
//                }
                list = list.aiment;
        }
};

void() AA_Link_Teams2 =
{
        local   float   ef;

        AA_Specs.aiment = AA_Spec1;
        AA_Spec1.aiment = AA_Spec2;
        AA_Spec2.aiment = world;
        ef = 2;

        if (AA_Num_Teams >= 3 && AA_Spec3.armorvalue) {
                AA_Spec2.aiment = AA_Spec3;
                AA_Spec3.aiment = world;
                ef = 3;
        }

        if (AA_Num_Teams >= 4 && AA_Spec4.armorvalue) {
                AA_Spec3.aiment = AA_Spec4;
                AA_Spec4.aiment = world;
                ef = 4;
        }

        AA_Specs.armortype = ef;
};

void(entity who) AA_Kick_List =
{
        local   entity  e;
        local   float   ef;

        ef = 0;
        e = find(world, classname, "player");
        while(e) {
                if (e != who) {
                        if (ef < 10) {
                                sprint(who, "0");
                        }
                        AA_Print_Num2(ef, who);
                        sprint(who, "  ");
                        sprint(who, e.netname);
                        sprint(who, "\n");
                        ef = ef + 1;
                }
                e = find(e, classname, "player");
        }
};

void(entity who, float num) AA_Kick_Command =
{
        local   entity  e;
        local   float   ef;

        ef = 0;
        e = find(world, classname, "player");
        while(e) {
                if (e != who) {
                        if (!num) {
                                AA_Kick(e);
                                return;
                        }
                        num = num - 1;
                }
                e = find(e, classname, "player");
        }
        sprint(who, "No such player\n");
};

void(entity who) AA_Kick =
{
        msg_entity = who;
        WriteByte(MSG_ONE, SVC_DISCONNECT);
};

void() AA_Lock_Server =
{
        if (AA_Locked)  return;
        AA_Locked = 1;
        bprint("Locking server...\n");
};

void() AA_Unlock_Server =
{
        if (!AA_Locked) return;
        AA_Locked = 0;
        bprint("Unlocking server...\n");
};

void() AA_Auto_Lock =
{
        local   float   ef;
        if (AA_Locked)  return;
        ef = cvar("temp1");
        if (ef & 2) {
//        if (stof(infokey(world, "autolock")) > 0) {
                AA_Locked = 2;
                bprint("Auto-locking server...\n");
        }
};

void() AA_Auto_Unlock =
{
        if (AA_Locked != 2) return;             // not autolocked
        AA_Unlock_Server();
};

void() AA_Check_Empty =
{
        local   entity  e;

        e = find(world, classname, "player");
        if (e)  return;

        // empty server, so unlock it
        AA_Unlock_Server();
        // reset if in the middle of something
        if ((AA_Game_Mode == AA_GM_NORMAL && AA_Game_State != AA_GAME_WAIT) ||
            (AA_Game_Mode != AA_GM_NORMAL && AA_Comp_State != AA_COMP_WAIT)) {
                AA_Reset_Command();
        }
};

//v1.1
void() AA_Pickup_Command =
{
        local   entity  e;

        if (AA_Game_Mode == AA_GM_NORMAL ||
            AA_Comp_State != AA_COMP_WAIT)
                return;

        AA_Clear_Lists(AA_Players);
        AA_Clear_Lists(AA_Specs);
        AA_Unready_All();

        bprint("Clearing teams...\n");

        e = find(world, classname, "player");
        while(e) {
// debug
                if(e.sounds != AD_FAKE) {
//                stuffcmd(e, "setinfo team \"\"\n");
                stuffcmd(e, "color 0 0\n");
// debug
                }
                e = find(e, classname, "player");
        }
};

string(float num) AA_Get_Name_For_Team =
{
        local   float   ef, ef2;

        ef2 = floor(num / 256);
        ef = num - (ef2 * 256);

        if (ef == 0)  return("White");
        else if (ef == 1)  return("Brown1");
        else if (ef == 2)  return("LtBlue");
        else if (ef == 3)  return("Green");
        else if (ef == 4)  return("Red");
        else if (ef == 5)  return("DkYellow5");
        else if (ef == 6)  return("Peach6");
        else if (ef == 7)  return("Beige7");
        else if (ef == 8)  return("Purple8");
        else if (ef == 9)  return("Magenta9");
        else if (ef == 10)  return("Grey10");
        else if (ef == 11)  return("Cyan");
        else if (ef == 12)  return("Yellow");
        else if (ef == 13)  return("Blue");
        else return(string_null);
};

void() AA_Tmset_Command =
{
        if (AA_V_Teamplay == 4) {
                AA_V_Teamplay = 0;
        } else {
                AA_V_Teamplay = AA_V_Teamplay + 1;
        }
        if (AA_Game_Mode != AA_GM_NORMAL &&
            AA_V_Teamplay == 0)
                AA_V_Teamplay = 1;

        AA_Show_Var(self, "teamplay", AA_V_Teamplay);
};

void() AA_Plup_Command =
{
        if (AA_Game_Mode == AA_GM_COMP) {
                if (AA_V_Players2 < 16) {
                        AA_V_Players2 = AA_V_Players2 + 1;
                }
                AA_Show_Var(self, "players", AA_V_Players2);
        } else {
                if (AA_V_Players < 16) {
                        AA_V_Players = AA_V_Players + 1;
                }
                AA_Show_Var(self, "players", AA_V_Players);
        }
};

void() AA_Pldown_Command =
{
        if (AA_Game_Mode == AA_GM_COMP) {
                if (AA_V_Players2 > 1) {
                        AA_V_Players2 = AA_V_Players2 - 1;
                }
                AA_Show_Var(self, "players", AA_V_Players2);
        } else {
                if (AA_V_Players > 1) {
                        AA_V_Players = AA_V_Players - 1;
                }
                AA_Show_Var(self, "players", AA_V_Players);
        }
};

void() AA_Tmup_Command =
{
        if (AA_V_Teams < 4) {
                AA_V_Teams = AA_V_Teams + 1;
                AA_Show_Var(self, "teams", AA_V_Teams);
        }
};

void() AA_Tmdown_Command =
{
        if (AA_V_Teams > 2) {
                AA_V_Teams = AA_V_Teams - 1;
                AA_Show_Var(self, "teams", AA_V_Teams);
        }
};

void() AA_Rdup_Command =
{
        if (AA_Game_Mode == AA_GM_COMP) {
                if (AA_V_Rounds < 33) {
                        AA_V_Rounds = AA_V_Rounds + 2;
                }
                AA_Show_Var(self, "rounds", AA_V_Rounds);
        }
};

void() AA_Rddown_Command =
{
        if (AA_Game_Mode == AA_GM_COMP) {
                if (AA_V_Rounds > 3) {
                        AA_V_Rounds = AA_V_Rounds - 2;
                }
                AA_Show_Var(self, "rounds", AA_V_Rounds);
        }
};

void() AA_Cells_Command =
{
        AA_V_Cells = AA_Ammo_Command(AA_V_Cells);
        AA_Show_Var(self, "cells", AA_V_Cells);
};

void() AA_Rockets_Command =
{
        AA_V_Rockets = AA_Ammo_Command(AA_V_Rockets);
        AA_Show_Var(self, "rockets", AA_V_Rockets);
};

void() AA_Nails_Command =
{
        AA_V_Nails = AA_Ammo_Command(AA_V_Nails);
        AA_Show_Var(self, "nails", AA_V_Nails);
};

void() AA_Shells_Command =
{
        AA_V_Shells = AA_Ammo_Command(AA_V_Shells);
        AA_Show_Var(self, "shells", AA_V_Shells);
};

float(float num) AA_Ammo_Command =
{
        if (num == 0) {
                return(30);
        } else if (num == 30) {
                return(100);
        } else if (num == 100) {
                return(700);
        } else {
                return(0);
        }
};

void(entity who, string foos, float num) AA_Show_Var =
{
        local   string  foos;

        bprint(who.netname);
        bprint(" has set ");
        bprint(foos);
        bprint(" to ");
        if(num) {
                foos = ftos(num);
        } else {
                foos = "0";
        }
        bprint(foos);
        bprint("\n");
//        if (AA_Game_Mode != AA_GM_NORMAL &&
//            AA_Comp_State != AA_COMP_WAIT) {
//                bprint("Settings will take effect next series\n");
//        }
};

void() AA_Atset_Command =
{
        if (AA_V_Atype == 4) {
                AA_V_Atype = 1;
        } else {
                AA_V_Atype = AA_V_Atype + 1;
        }
        AA_Show_Var(self, "atype", AA_V_Atype);
        if (AA_V_Atype == 4)            AA_V_Armor = 0;
        else if (AA_V_Atype == 3)       AA_V_Armor = 100;
        else if (AA_V_Atype == 2)       AA_V_Armor = 150;
        else if (AA_V_Atype == 1)       AA_V_Armor = 200;
};

void() AA_Amup_Command =
{
        if (AA_V_Armor < 950) {
                AA_V_Armor = AA_V_Armor + 50;
                AA_Show_Var(self, "armor", AA_V_Armor);
        }
};

void() AA_Amdown_Command =
{
        if (AA_V_Armor >= 50) {
                AA_V_Armor = AA_V_Armor - 50;
                AA_Show_Var(self, "armor", AA_V_Armor);
        }
};

void() AA_Hup_Command =
{
        if (AA_V_Health < 950) {
                AA_V_Health = AA_V_Health + 50;
                AA_Show_Var(self, "health", AA_V_Health);
        }
};

void() AA_Hdown_Command =
{
        if (AA_V_Health >= 100) {
                AA_V_Health = AA_V_Health - 50;
                AA_Show_Var(self, "health", AA_V_Health);
        }
};

void() AA_Set_Vars2 =
{
        local   float   ef;
        local   string  foos;

        if (AA_V_Armor < 0)     AA_V_Armor = 0;
        if (AA_V_Armor > 999)   AA_V_Armor = 999;
        if (AA_V_Weapons < 0)   AA_V_Weapons = 0;
        if (AA_V_Weapons > 127) AA_V_Weapons = 127;
        if (AA_V_Atype < 0)     AA_V_Atype = 0;
        if (AA_V_Atype > 3)     AA_V_Atype = 3;
        if (AA_V_Health <= 0)   AA_V_Health = 100;
        if (AA_V_Health > 999)  AA_V_Health = 999;
        if (AA_V_Shells < 0)    AA_V_Shells = 0;
        if (AA_V_Shells > 700)  AA_V_Shells = 700;
        if (AA_V_Nails < 0)     AA_V_Nails = 0;
        if (AA_V_Nails > 700)   AA_V_Nails = 700;
        if (AA_V_Rockets < 0)   AA_V_Rockets = 0;
        if (AA_V_Rockets > 700) AA_V_Rockets = 700;
        if (AA_V_Cells < 0)     AA_V_Cells = 0;
        if (AA_V_Cells > 700)   AA_V_Cells = 700;
        if (AA_V_Rounds < 1)    AA_V_Rounds = 1;
        if (AA_V_Rounds > 99)   AA_V_Rounds = 99;
        if (AA_V_Teams < 2)     AA_V_Teams = 2;
        if (AA_V_Teams > 4)     AA_V_Teams = 4;
        if (AA_V_Players < 1)   AA_V_Players = 1;
        if (AA_V_Players > 32)  AA_V_Players = 32;
        if (AA_V_Players2 < 1)  AA_V_Players2 = 1;
        if (AA_V_Players2 > 32) AA_V_Players2 = 32;
        if (AA_V_Teamplay < 0)  AA_V_Teamplay = 0;
        if (AA_V_Teamplay > 4)  AA_V_Teamplay = 4;

        if (AA_Game_Mode == AA_GM_NORMAL &&
            AA_V_Players < 2)
                AA_V_Players = 2;

        AA_Armor = AA_V_Armor;
        AA_Weapons = AA_V_Weapons;
        AA_Atype = AA_V_Atype; 
        AA_Health = AA_V_Health; 
        AA_Shells = AA_V_Shells; 
        AA_Nails = AA_V_Nails; 
        AA_Rockets = AA_V_Rockets; 
        AA_Cells = AA_V_Cells;
        if (AA_Game_Mode == AA_GM_COMP) {
                AA_Num_Players = AA_V_Players2;
        } else if (AA_Game_Mode == AA_GM_NORMAL) {
                AA_Num_Players = AA_V_Players;
        }
        if (AA_Game_Mode != AA_GM_NORMAL) {
                if (AA_V_Teamplay == 0) {
                        AA_V_Teamplay = 4;
                }
        }
        ef = cvar("teamplay");
        if(ef != AA_V_Teamplay) {
                foos = ftos(AA_V_Teamplay);
                cvar_set("teamplay", foos);
        }
};

void() AA_Draw_Hack1 =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if (e.goalentity) {
                        e.goalentity.lefty = e.goalentity.lefty - (e.goalentity.lefty & 8);
                        if (e.goalentity.flags == AA_PLAYER) {
                                e.goalentity.lefty = e.goalentity.lefty + 8;
                        }
                }
                e = find(e, classname, "player");
        }
};

void() AA_Draw_Hack2 =
{
        local   entity  e;
        local   float   ef;

        AA_Clear_Lists(AA_Players);

        e = find(world, classname, "player");
        ef = 0;
        while(e) {
                if (e.goalentity.lefty & 8) {
                        if(e.deadflag)
                                AA_Force_Respawn(e);
                        AA_Place_Player(e.goalentity);
                        AA_Add_To_List(AA_List1, e.goalentity);
                        ef = ef + 1;
                }
                e = find(e, classname, "player");
        }
        if (ef >= AA_Min_Players)
                AA_Game_State = AA_GAME_READY;
        else
                AA_Game_State = AA_GAME_WAIT;
};

void(entity who, float which) AA_Set_Team_Menus =
{
        local   string  foos;
        local   float   col;
        local   entity  list;
        
        if (which == 1) list = AA_Spec1;
        else if (which == 2) list = AA_Spec2;
        else if (which == 3) list = AA_Spec3;
        else if (which == 4) list = AA_Spec4;
        else return;

        foos = AA_Get_Name_For_Team(list.team - 1);
//        foos = infokey(world, list.target);

        if (!list.armorvalue) {      // need to create this team
                AA_Add_To_List(list, who.goalentity);
                bprint(who.netname);
                bprint(" has created team ");
                bprint(foos);
                bprint("\n");
                list.armorvalue = 1;
// debug
//                if(who.sounds != AD_FAKE) {
//                stuffcmd(who, "setinfo oldteam ");
//                stuffcmd(who, foos);
//                stuffcmd(who, "\n");
// debug
//                }
                if (which == 1) {
                        list.team = 14;
                } else if (which == 2) {
                        list.team = 5;
                } else if (which == 3) {
                        list.team = 13;
                } else if (which == 4) {
                        list.team = 4;
                }
                who.goalentity.team = list.team;
                who.goalentity.colormap = list.team - 1;
                AA_Set_Color(who, list.team);
                who.goalentity.fly_sound = 1;   // has been committed
                AA_Report_Flag = 0;
                return;
        }
        AA_Add_To_List(list, who.goalentity);
        bprint(who.netname);
        bprint(" has been added to team ");
        bprint(foos);
        bprint("\n");
// debug
//        if(who.sounds != AD_FAKE) {
//        stuffcmd(who, "setinfo oldteam ");
//        stuffcmd(who, foos);
//        stuffcmd(who, "\n");
// debug
//        }
        who.goalentity.team = list.team;
        who.goalentity.colormap = list.team - 1;
        AA_Set_Color(who, list.team);
        who.goalentity.fly_sound = 1;   // has been committed
        AA_Report_Flag = 0;
};

void(entity foo) AA_Setup_Command =
{
        if (foo.goalentity.search_time == AA_ADMIN) {
                foo.goalentity.ideal_yaw = 31;
                return;
        }
        foo.goalentity.ideal_yaw = 30;

        if (AA_Vote_Ent) {
                sprint(foo, "Please wait for current voting to end\nOr use the admin command\n");
        }
        else
        if (AA_Vote_Pct <= 0.0 || AA_Vote_Time <= 0.0) {
                sprint(foo, "Voting disabled. You must use the admin command\n");
        }
        else
        {
                AA_Elect_Command(foo);
                sprint(foo, "You can use the admin command to skip voting\n");
        }
        sprint(foo, "Once you have become admin, setup will continue\n");
};

void(string foos) AA_Cprint =
{
        local   entity  e;

        e = find(world, classname, "player");
        while(e) {
                if (e.goalentity.ideal_yaw < 30 && (e.goalentity.lefty & 64)) {
                        centerprint(e, foos);
                }
                e = find (e, classname, "player");
        }
};

void() AA_MK_Hack =
{
        bprint("The match has begun!\n");
        AA_Game_State = AA_GAME_ON;
        remove(self);
};

float() AA_Check_Fullteams =
{
        local   entity  e;
        local   float   ef, ef2, ef3;
        local   string  foos, foos2;

        if(!AA_Fullteams)       return(1);

        e = AA_Specs.aiment;
        ef = AA_Num_Players;
        ef3 = 0;
        if (!AA_Spec1.armorvalue) ef3 = 1;
        if (!AA_Spec2.armorvalue) ef3 = 1;
        if (AA_Num_Teams >= 3 &&
            !AA_Spec3.armorvalue) ef3 = 1;
        if (AA_Num_Teams >= 4 &&
            !AA_Spec4.armorvalue) ef3 = 1;
        if (ef3) {
                if(!AA_Report_Flag) {
                        bprint("There arent enough teams\n");
                        AA_Report_Flag = 1;
                }
                return(0);
        }

        ef = 0;
        while(e) {
                ef2 = AA_Count_List(e);
                if (ef2 < AA_Num_Players) {
                        ef = 1;
                        if(!AA_Report_Flag) {
                                ef3 = AA_Num_Players - ef2;
                                foos = ftos(ef3);
                                foos2 = AA_Get_Name_For_Team(e.team - 1);
//                                foos2 = infokey(world, e.target);
                                bprint("Team ");
                                bprint(foos2);
                                bprint(" is missing ");
                                bprint(foos);
                                bprint(" players\n");
                        }
                }
                e = e.aiment;
        }
        if(!ef) return(1);
        AA_Report_Flag = 1;
        return(0);
};

void() AA_Fullteams_Command =
{
        if (AA_Fullteams) {
                AA_Fullteams = 0;
                bprint("Fullteams disabled\n");
        } else {
                AA_Fullteams = 1;
                bprint("Fullteams enabled\n");
        }
};

void(entity who) AA_Cprint_Command =
{
        if (who.goalentity.lefty & 64) {
                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 64);
                sprint(who, "Centerprint counter disabled\n");
        } else {
                who.goalentity.lefty = who.goalentity.lefty + 64;
                sprint(who, "Centerprint counter enabled\n");
        }
};

void(entity who, float topcol, float bottomcol) AA_Set_Color2 =
{
        local   string  foos;

// debug
        if (who.sounds == AD_FAKE)
                return;

        if (topcol) {
                foos = ftos(topcol);
        } else {
                foos = "0";
        }

        stuffcmd(who, "color ");
        stuffcmd(who, foos);
        stuffcmd(who, " ");

        if (bottomcol) {
                foos = ftos(bottomcol);
        } else {
                foos = "0";
        }

        stuffcmd(who, foos);
        stuffcmd(who, "\n");
};
