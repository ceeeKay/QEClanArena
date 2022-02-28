// Change this and recompile to change admin code
float AA_D_Admin_Code = 9194;
float AA_D_Vote_Pct = 50;
float AA_D_Vote_Time = 60;
float AA_D_Cells = 100;
float AA_D_Rockets = 100;
float AA_D_Nails = 100;
float AA_D_Shells = 100;
float AA_D_Atype = 1;
float AA_D_Armor = 200;
float AA_D_Health = 100;
float AA_D_Weapons = 127;
float AA_D_Players = 1;
float AA_D_Players2 = 4;
float AA_D_Teams = 2;
float AA_D_Rounds = 9;

// Change these and recompile to change default maps/order
string(float num) AA_Get_Map_For_Num =
{
// normal maps
        if (num == 0) return "dm1";
        if (num == 1) return "dm2";
        if (num == 2) return "dm6";
        if (num == 3) return "dm3";
        if (num == 4) return "end";
        if (num == 5) return "horde1";
        if (num == 6) return "horde2";
        if (num == 7) return "horde3";
        if (num == 8) return "horde4";
// custom maps
        if (num == 9) return "test/mals_combatbox";
        if (num == 10) return "test/test_characters";
        if (num == 11) return "test/test_invis";
        if (num == 12) return "test/test_aiming";
        if (num == 13) return "test/test_shadow";
        if (num == 14) return "test/test_rockets";
        if (num == 15) return "test/test_door";
        return(string_null);
};

