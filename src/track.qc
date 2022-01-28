void(entity who) AA_Track =
{
        local   vector  v1, v2, v3;

        if (!who.goalentity.movetarget)    return;              // not tracking

        if (AA_Comp_State == AA_COMP_OFF) {
                AA_Track_Off(who);
                return;
        }
        else
        if (who.goalentity.movetarget.goalentity.flags != AA_PLAYER) { // cant track this one
                AA_Track_On(who);
                return;
        }

        if (who.velocity == '0 0 0' || (who.goalentity.lefty & 1)) {
                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 1);
                setorigin(who, who.goalentity.movedir);
        }
        v1 = who.goalentity.movetarget.origin;
        v2 = who.v_angle;
        makevectors(v2);
        v2 = v_forward * 160;
        traceline(v1, v1 - v2, TRUE, who.goalentity.movetarget);
        v2 = v2 * trace_fraction;
        v3 = v1 - (v2 * 0.6);
        v2 = v1 - v2;

        traceline(who.origin, v2, TRUE, who.goalentity.movetarget);
        if (trace_fraction == 1.0) {
                v1 = v3 - who.origin;
                v1 = v1 * 10;
                who.velocity = v1;
        } else {
                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 1);
                who.goalentity.lefty = who.goalentity.lefty + 1;
                who.velocity = '0 0 0';
        }
        who.goalentity.movedir = v3;
};

void(entity who) AA_Track_On =
{
        local   float   ef;
        local   entity  e;

        if (AA_Count_Lists(AA_Players) < 1) {
                AA_Track_Off(who);
                return;         // no one to follow
        }

        e = find(who.goalentity.movetarget, classname, "player");
        ef = 32;
        while(e.goalentity.flags != AA_PLAYER && ef > 0) {
                e = find(e, classname, "player");
                ef = ef - 1;
        }
        if (!ef) {
                AA_Track_Off(who);
                return;
        }
//        AA_Last_Player = e;

//        e = find(AA_Last_Player, classname, "player");
//        ef = 32;
//        while(e.goalentity.flags != AA_PLAYER && ef > 0) {
//                e = find(e, classname, "player");
//                ef = ef - 1;
//        }
//        if (!ef) {
//                AA_Track_Off(who);
//                return;
//        }
//        AA_Last_Player = e;
        sprint(who, "Tracking ");
        sprint(who, e.netname);
        sprint(who, " ... Press jump for next\n");
        who.v_angle = '0 0 0';
        who.goalentity.movetarget = e;
        who.movetype = MOVETYPE_FLY;
//        who.touch = AA_Track_Hit_Wall;
//        who.gravity = 0.0;
        who.velocity = '0 0 0';
        who.goalentity.movedir = who.origin;
        if (!(who.goalentity.lefty & 2)) {
//                stuffcmd(who, "pushlatency 0\n");
                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 32);
                who.goalentity.lefty = who.goalentity.lefty + 32;
        }
};

void(entity who) AA_Toggle_Pl =
{
        if (who.goalentity.lefty & 2) {         // turn off autopl
                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 2);
                sprint(who, "Auto-pushlatency enabled\n");
        } else {
                who.goalentity.lefty = who.goalentity.lefty + 2;
                sprint(who, "Auto-pushlatency disabled\n");
        }
};

void(entity who) AA_Track_Off =
{
        local   string  foos;
        local   entity  t;

        if (!who.goalentity.movetarget) return; // not tracking

//        if ((who.goalentity.lefty & 32)) {
//v1.1
//                if (stof(infokey(who, "pl")) > 0) {
//                        foos = infokey(who, "pl");
//                } else {
//                        foos = "500";
//                }
//                stuffcmd(who, "pushlatency -");
//                stuffcmd(who, foos);
//                stuffcmd(who, "\n");
//                who.goalentity.lefty = who.goalentity.lefty - (who.goalentity.lefty & 32);
//        }
        centerprint(who, "\n");
//v1.1
        who.items = IT_SHOTGUN | IT_AXE;
        who.armorvalue = 0;
        who.health = 100;
        who.weapon = IT_SHOTGUN;
        who.currentammo = who.ammo_shells;

//        who.touch = SUB_Null;
//        who.gravity = 1.0;
        setsize(who, VEC_HULL_MIN, VEC_HULL_MAX);
        who.movetype = MOVETYPE_WALK;
        who.velocity = '0 0 0';
        who.goalentity.movedir = who.origin;
        who.goalentity.movetarget = world;
        t = AA_SelectSpawnPoint("info_player_deathmatch");
        if (t) {
                setorigin(who, t.origin);
                who.angles = t.angles;
                who.fixangle = 1;
                who.flags = who.flags - (who.flags & FL_ONGROUND);
        }
};

void() AA_Track_Hit_Wall =
{
//        sprint(self, PRINT_LOW, ".\n");
        self.goalentity.lefty = self.goalentity.lefty - (self.goalentity.lefty & 4);
        self.goalentity.lefty = self.goalentity.lefty + 4;
};

