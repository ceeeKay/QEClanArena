void() func_body_chute =
{
        AA_Body_Chute = 1;
        self.angles = '0 0 0';
};

void(entity who) AA_Shoot_Body =
{
        local   entity  e;

        e = find(world, classname, "func_body_chute");
        if (!e) return;

        spawn_tfog(who.origin);
        setorigin(who, e.origin);
        who.flags = who.flags - (who.flags & FL_ONGROUND);
        makevectors(e.mangle);
        who.velocity = v_forward * e.speed;
};

