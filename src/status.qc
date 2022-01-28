string(entity who) AA_Get_Status =
{
        local   entity  list;
        local   string  foos;
        local   float   ef, ef2, ef3, ef4, ef5;

//v1.1
// we have to figure out how much damage it will take to kill this person
        if (AA_Atype == 1) {
                ef4 = 0.8;
        } else if (AA_Atype == 2) {
                ef4 = 0.6;
        } else if (AA_Atype == 3) {
                ef4 = 0.3;
        } else {
                ef4 = 0.0;
        }
        if (ef4 == 0.0 || who.armortype == 0.0) {       // no armor modifier
                ef = who.health;        // will take this much damage to kill this person
        } else {
                ef3 = who.health / (1.0 - ef4); // this is how much damage health is good for
                ef2 = who.armorvalue / (ef4);   // this is how much damage armor is good for
                if (ef2 > ef3) {
                        ef = ef3;
                } else {
                        ef = ef2;
                        ef = ef + (who.health - (ef2 * (1.0 - ef4)));
                }
        }
        ef3 = AA_Health / (1.0 - ef4);
        ef2 = AA_Armor / (ef4);
        if (ef2 > ef3) {
                ef5 = ef3;
        } else {
                ef5 = ef2;
                ef5 = ef5 + (AA_Health - (ef2 * (1.0 - ef4)));
        }

        ef2 = ef / ef5;

//        ef3 = AA_Health;
//        ef2 = who.health;
//        ef2 = ef2 / ef3;

        if (ef2 > 0.75) {
                ef = 0;
        } else if (ef2 > 0.50) {
                ef = 1;
        } else if (ef2 > 0.25) {
                ef = 2;
        } else {
                ef = 3;
        }

//        ef3 = 0;
//        list = AA_Players.aiment;
//        while(list) {
//                if(list.speed == who.goalentity.speed) {
//                        ef2 = AA_Count_List(list);
//                } else {
//                        ef4 = AA_Count_List(list);
//                        if (ef4 > ef3) {
//                                ef3 = ef4;
//                        }
//                }
//                list = list.aiment;
//        }

//        if (AA_Game_Mode == AA_GM_COMP) {
//                if (ef2 == 1 && ef3 > ef2) {
//                        ef = ef + 4;
//                }
//        }

//        if (ef == 0)    foos = infokey(world, "status1");
//        if (ef == 1)    foos = infokey(world, "status2");
//        if (ef == 2)    foos = infokey(world, "status3");
//        if (ef == 3)    foos = infokey(world, "status4");
//        if (ef == 4)    foos = infokey(world, "status5");
//        if (ef == 5)    foos = infokey(world, "status6");
//        if (ef == 6)    foos = infokey(world, "status7");
//        if (ef == 7)    foos = infokey(world, "status8");

//        if (foos == string_null) {
                if (ef == 0)    foos = "good";
                if (ef == 1)    foos = "fair";
                if (ef == 2)    foos = "poor";
                if (ef == 3)    foos = "bad";
//                if (ef == 4)    foos = "good";
//                if (ef == 5)    foos = "fair";
//                if (ef == 6)    foos = "poor";
//                if (ef == 7)    foos = "bad";
//        }

        return(foos);
};

void(entity who) AA_Status_Bar =
{
        local   string  foos;
        local   string  foos2;
        local   float   ef3;
        

        if (!who.goalentity.movetarget) return;

//v1.1
        who.items = who.goalentity.movetarget.items;
        who.armorvalue = who.goalentity.movetarget.armorvalue;
        who.health = who.goalentity.movetarget.health;
        who.weapon = who.goalentity.movetarget.weapon;
        who.currentammo = who.goalentity.movetarget.currentammo;

        ef3 = who.goalentity.t_length;
        if (!ef3)       return;
        else if (ef3 == 200)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 786)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 600)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 480)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 400)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 384)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 350)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 300)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else if (ef3 == 240)
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        else 
                 foos2 = "\n\n\n\n\n\n\n\n\n\n\n";

        foos = AA_Get_Status(who.goalentity.movetarget);
        centerprint6(who, foos2, "Name: ",
                         who.goalentity.movetarget.netname,
                         "\nStatus: ", foos, "\n");
};

void() AA_Sbup_Command =
{
        local   string  foos;

        if (self.goalentity.t_length == 0) self.goalentity.t_length = 200;
        else if (self.goalentity.t_length == 200) self.goalentity.t_length = 240;
        else if (self.goalentity.t_length == 240) self.goalentity.t_length = 300;
        else if (self.goalentity.t_length == 300) self.goalentity.t_length = 350;
        else if (self.goalentity.t_length == 350) self.goalentity.t_length = 384;
        else if (self.goalentity.t_length == 384) self.goalentity.t_length = 400;
        else if (self.goalentity.t_length == 400) self.goalentity.t_length = 480;
        else if (self.goalentity.t_length == 480) self.goalentity.t_length = 600;
        else if (self.goalentity.t_length == 600) self.goalentity.t_length = 786;
        else if (self.goalentity.t_length == 786) self.goalentity.t_length = 786;

        if(self.goalentity.t_length) {
                foos = ftos(self.goalentity.t_length);
        } else {
                foos = "OFF";
        }
        sprint(self, "Sbar set to ");
        sprint(self, foos);
        sprint(self, "\n");
};

void() AA_Sbdown_Command =
{
        local   string  foos;

        if (self.goalentity.t_length == 0) self.goalentity.t_length = 0;
        else if (self.goalentity.t_length == 200) self.goalentity.t_length = 0;
        else if (self.goalentity.t_length == 240) self.goalentity.t_length = 200;
        else if (self.goalentity.t_length == 300) self.goalentity.t_length = 240;
        else if (self.goalentity.t_length == 350) self.goalentity.t_length = 300;
        else if (self.goalentity.t_length == 384) self.goalentity.t_length = 350;
        else if (self.goalentity.t_length == 400) self.goalentity.t_length = 384;
        else if (self.goalentity.t_length == 480) self.goalentity.t_length = 400;
        else if (self.goalentity.t_length == 600) self.goalentity.t_length = 480;
        else if (self.goalentity.t_length == 786) self.goalentity.t_length = 600;

        if(self.goalentity.t_length) {
                foos = ftos(self.goalentity.t_length);
        } else {
                foos = "OFF";
        }
        sprint(self, "Sbar set to ");
        sprint(self, foos);
        sprint(self, "\n");
};
