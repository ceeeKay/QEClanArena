void() AD_Spawn_Fake =
{
        local   entity  e;

        e = self;
        self = spawn();
        SetNewParms();
        if (AD_Curbot == 0) {
                self.netname = "Dummy0";
        } else if (AD_Curbot == 1) {
                self.netname = "Dummy1";
        } else if (AD_Curbot == 2) {
                self.netname = "Dummy2";
        } else if (AD_Curbot == 3) {
                self.netname = "Dummy3";
        } else if (AD_Curbot == 4) {
                self.netname = "Dummy4";
        } else if (AD_Curbot == 5) {
                self.netname = "Dummy5";
        } else if (AD_Curbot == 6) {
                self.netname = "Dummy6";
        } else if (AD_Curbot == 7) {
                self.netname = "Dummy7";
        }
        self.sounds = AD_FAKE;
        PutClientInServer();
        self.movetype = MOVETYPE_NONE;
        self.owner = e;
        self.sounds = AD_FAKE;
        self.count = AD_Curbot;
        AD_Curbot = AD_Curbot + 1;

        bprint(self.netname);
        bprint(" created\n");

        self = e;
};

void() AD_Respawn =
{
        local   entity  e, e2;

        e = find(world, classname, "player");
        while(e) {
                if (e.deadflag && e.sounds == AD_FAKE) {
                        e2 = self;
                        self = e;
                        respawn();
                        self.movetype = MOVETYPE_NONE;
                        self.sounds = AD_FAKE;
                        self = e2;
                }
                e = find(e, classname, "player");
        }
};

void() AD_Select_Bot =
{
        local   entity  e;
        local   string  foos;
        local   float   ef;

        e = find(AD_Thebot, classname, "player");
        ef = 0;
        while(!ef) {
                if (e.sounds == AD_FAKE) {
                        ef = 1;
                } else {
                        e = find(e, classname, "player");
                }
        }
        AD_Thebot = e;
        bprint("Working with bot ");
        bprint(e.netname);
        bprint("\n");
};

void() AD_Ready_Bot =
{
        local   entity  e;

        e = self;
        self = AD_Thebot;
        AA_Ready_Command();
        self = e;
};

void() AD_Set_Team =
{
        AD_Team = AD_Team + 1;
        if (AD_Team > 2) {
                AD_Team = 0;
        }

        if (AD_Team == 0) {
                AD_Team_Name = "foo";
        } else if (AD_Team == 1) {
                AD_Team_Name = "dumb";
        } else {
                AD_Team_Name = "two";
        }

        bprint("AD_Team_Name is now ");
        bprint(AD_Team_Name);
        bprint("\n");
};

void() AD_Killbot =
{
        T_Damage(AD_Thebot, self, self, 5000);
};

void() AD_Check_Col =
{
        local   string  foos;

        foos = ftos(self.goalentity.trigger_field.team);
        bprint("team color is ");
        bprint(foos);
        bprint("\n");
};

