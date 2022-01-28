
/*
==============================================================================

			SOURCE FOR GLOBALVARS_T C STRUCTURE

==============================================================================
*/

//
// system globals
//
entity		self;
entity		other;
entity		world;
float		time;
float		frametime;

float		force_retouch;		// force all entities to touch triggers
								// next frame.  this is needed because
								// non-moving things don't normally scan
								// for triggers, and when a trigger is
								// created (like a teleport trigger), it
								// needs to catch everything.
								// decremented each frame, so set to 2
								// to guarantee everything is touched
string		mapname;

float		deathmatch;
float		coop;
float		teamplay;

float		serverflags;		// propagated from level to level, used to
								// keep track of completed episodes

float		total_secrets;
float		total_monsters;

float		found_secrets;		// number of secrets found
float		killed_monsters;	// number of monsters killed


// spawnparms are used to encode information about clients across server
// level changes
float		parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;

//
// global variables set by built in functions
//	
vector		v_forward, v_up, v_right;	// set by makevectors()
	
// set by traceline / tracebox
float		trace_allsolid;
float		trace_startsolid;
float		trace_fraction;
vector		trace_endpos;
vector		trace_plane_normal;
float		trace_plane_dist;
entity		trace_ent;
float		trace_inopen;
float		trace_inwater;

entity		msg_entity;				// destination of single entity writes

//
// required prog functions
//
void() 		main;						// only for testing

void()		StartFrame;

void() 		PlayerPreThink;
void() 		PlayerPostThink;

void()		ClientKill;
void()		ClientConnect;
void() 		PutClientInServer;		// call after setting the parm1... parms
void()		ClientDisconnect;

void()		SetNewParms;			// called when a client first connects to
									// a server. sets parms so they can be
									// saved off for restarts

void()		SetChangeParms;			// call to set parms for self so they can
									// be saved for a level transition


//================================================
void		end_sys_globals;		// flag for structure dumping
//================================================

/*
==============================================================================

			SOURCE FOR ENTVARS_T C STRUCTURE

==============================================================================
*/

//
// system fields (*** = do not set in prog code, maintained by C code)
//
.float		modelindex;		// *** model index in the precached list
.vector		absmin, absmax;	// *** origin + mins / maxs

.float		ltime;			// local time for entity
.float		movetype;
.float		solid;

.vector		origin;			// ***
.vector		oldorigin;		// ***
.vector		velocity;
.vector		angles;
.vector		avelocity;

.vector		punchangle;		// temp angle adjust from damage or recoil

.string		classname;		// spawn function
.string		model;
.float		frame;
.float		skin;
.float		effects;

.vector		mins, maxs;		// bounding box extents reletive to origin
.vector		size;			// maxs - mins

.void()		touch;
.void()		use;
.void()		think;
.void()		blocked;		// for doors or plats, called when can't push other

.float		nextthink;
.entity		groundentity;

// stats
.float		health;
.float		frags;
.float		weapon;			// one of the IT_SHOTGUN, etc flags
.string		weaponmodel;
.float		weaponframe;
.float		currentammo;
.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;

.float		items;			// bit flags

.float		takedamage;
.entity		chain;
.float		deadflag;

.vector		view_ofs;			// add to origin to get eye point


.float		button0;		// fire
.float		button1;		// use
.float		button2;		// jump

.float		impulse;		// weapon changes

.float		fixangle;
.vector		v_angle;		// view / targeting angle for players
.float		idealpitch;		// calculated pitch angle for lookup up slopes


.string		netname;

.entity 	enemy;

.float		flags;

.float		colormap;
.float		team;

.float		max_health;		// players maximum health is stored here

.float		teleport_time;	// don't back up

.float		armortype;		// save this fraction of incoming damage
.float		armorvalue;

.float		waterlevel;		// 0 = not in, 1 = feet, 2 = wast, 3 = eyes
.float		watertype;		// a contents value

.float		ideal_yaw;
.float		yaw_speed;

.entity		aiment;

.entity 	goalentity;		// a movetarget or an enemy

.float		spawnflags;

.string		target;
.string		targetname;

// damage is accumulated through a frame. and sent as one single
// message, so the super shotgun doesn't generate huge messages
.float		dmg_take;
.float		dmg_save;
.entity		dmg_inflictor;

.entity		owner;		// who launched a missile
.vector		movedir;	// mostly for doors, but also used for waterjump

.string		message;		// trigger messages

.float		sounds;		// either a cd track number or sound number

.string		noise, noise1, noise2, noise3;	// contains names of wavs to play

//================================================
void		end_sys_fields;			// flag for structure dumping
//================================================

/*
==============================================================================

				VARS NOT REFERENCED BY C CODE

==============================================================================
*/


//
// constants
//

float	FALSE					= 0;
float 	TRUE					= 1;

// edict.flags
float	FL_FLY					= 1;
float	FL_SWIM					= 2;
float	FL_CLIENT				= 8;	// set for all client edicts
float	FL_INWATER				= 16;	// for enter / leave water splash
float	FL_MONSTER				= 32;
float	FL_GODMODE				= 64;	// player cheat
float	FL_NOTARGET				= 128;	// player cheat
float	FL_ITEM					= 256;	// extra wide size for bonus items
float	FL_ONGROUND				= 512;	// standing on something
float	FL_PARTIALGROUND		= 1024;	// not all corners are valid
float	FL_WATERJUMP			= 2048;	// player jumping out of water
float	FL_JUMPRELEASED			= 4096;	// for jump debouncing

// edict.movetype values
float	MOVETYPE_NONE			= 0;	// never moves
//float	MOVETYPE_ANGLENOCLIP	= 1;
//float	MOVETYPE_ANGLECLIP		= 2;
float	MOVETYPE_WALK			= 3;	// players only
float	MOVETYPE_STEP			= 4;	// discrete, not real time unless fall
float	MOVETYPE_FLY			= 5;
float	MOVETYPE_TOSS			= 6;	// gravity
float	MOVETYPE_PUSH			= 7;	// no clip to world, push and crush
float	MOVETYPE_NOCLIP			= 8;
float	MOVETYPE_FLYMISSILE		= 9;	// fly with extra size against monsters
float	MOVETYPE_BOUNCE			= 10;
float	MOVETYPE_BOUNCEMISSILE	= 11;	// bounce with extra size

// edict.solid values
float	SOLID_NOT				= 0;	// no interaction with other objects
float	SOLID_TRIGGER			= 1;	// touch on edge, but not blocking
float	SOLID_BBOX				= 2;	// touch on edge, block
float	SOLID_SLIDEBOX			= 3;	// touch on edge, but not an onground
float	SOLID_BSP				= 4;	// bsp clip, touch on edge, block

// range values
float	RANGE_MELEE				= 0;
float	RANGE_NEAR				= 1;
float	RANGE_MID				= 2;
float	RANGE_FAR				= 3;

// deadflag values

float	DEAD_NO					= 0;
float	DEAD_DYING				= 1;
float	DEAD_DEAD				= 2;
float	DEAD_RESPAWNABLE		= 3;

// takedamage values

float	DAMAGE_NO				= 0;
float	DAMAGE_YES				= 1;
float	DAMAGE_AIM				= 2;

// items
float	IT_AXE					= 4096;
float	IT_SHOTGUN				= 1;
float	IT_SUPER_SHOTGUN		= 2;
float	IT_NAILGUN				= 4;
float	IT_SUPER_NAILGUN		= 8;
float	IT_GRENADE_LAUNCHER		= 16;
float	IT_ROCKET_LAUNCHER		= 32;
float	IT_LIGHTNING			= 64;
float	IT_EXTRA_WEAPON			= 128;

float	IT_SHELLS				= 256;
float	IT_NAILS				= 512;
float	IT_ROCKETS				= 1024;
float	IT_CELLS				= 2048;

float	IT_ARMOR1				= 8192;
float	IT_ARMOR2				= 16384;
float	IT_ARMOR3				= 32768;
float	IT_SUPERHEALTH			= 65536;

float	IT_KEY1					= 131072;
float	IT_KEY2					= 262144;

float	IT_INVISIBILITY			= 524288;
float	IT_INVULNERABILITY		= 1048576;
float	IT_SUIT					= 2097152;
float	IT_QUAD					= 4194304;

// point content values

float	CONTENT_EMPTY			= -1;
float	CONTENT_SOLID			= -2;
float	CONTENT_WATER			= -3;
float	CONTENT_SLIME			= -4;
float	CONTENT_LAVA			= -5;
float	CONTENT_SKY				= -6;

float	STATE_TOP		= 0;
float	STATE_BOTTOM	= 1;
float	STATE_UP		= 2;
float	STATE_DOWN		= 3;

vector	VEC_ORIGIN = '0 0 0';
vector	VEC_HULL_MIN = '-16 -16 -24';
vector	VEC_HULL_MAX = '16 16 32';

vector	VEC_HULL2_MIN = '-32 -32 -24';
vector	VEC_HULL2_MAX = '32 32 64';

// protocol bytes
float	SVC_TEMPENTITY		= 23;
float	SVC_KILLEDMONSTER	= 27;
float	SVC_FOUNDSECRET		= 28;
float	SVC_INTERMISSION	= 30;
float	SVC_FINALE			= 31;
float	SVC_CDTRACK			= 32;
float	SVC_SELLSCREEN		= 33;


float	TE_SPIKE		= 0;
float	TE_SUPERSPIKE	= 1;
float	TE_GUNSHOT		= 2;
float	TE_EXPLOSION	= 3;
float	TE_TAREXPLOSION	= 4;
float	TE_LIGHTNING1	= 5;
float	TE_LIGHTNING2	= 6;
float	TE_WIZSPIKE		= 7;
float	TE_KNIGHTSPIKE	= 8;
float	TE_LIGHTNING3	= 9;
float	TE_LAVASPLASH	= 10;
float	TE_TELEPORT		= 11;

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) allways override a playing sound on that channel
float	CHAN_AUTO		= 0;
float	CHAN_WEAPON		= 1;
float	CHAN_VOICE		= 2;
float	CHAN_ITEM		= 3;
float	CHAN_BODY		= 4;

float	ATTN_NONE		= 0;
float	ATTN_NORM		= 1;
float	ATTN_IDLE		= 2;
float	ATTN_STATIC		= 3;

// update types

float	UPDATE_GENERAL	= 0;
float	UPDATE_STATIC	= 1;
float	UPDATE_BINARY	= 2;
float	UPDATE_TEMP		= 3;

// entity effects

float	EF_BRIGHTFIELD	= 1;
float	EF_MUZZLEFLASH 	= 2;
float	EF_BRIGHTLIGHT 	= 4;
float	EF_DIMLIGHT 	= 8;


// messages
float	MSG_BROADCAST	= 0;		// unreliable to all
float	MSG_ONE			= 1;		// reliable to one (msg_entity)
float	MSG_ALL			= 2;		// reliable to all
float	MSG_INIT		= 3;		// write to the init string

//================================================

//
// globals
//
float	movedist;
float	gameover;		// set when a rule exits

string	string_null;	// null string, nothing should be held here
float	empty_float;

entity	newmis;			// launch_spike sets this after spawning it

entity	activator;		// the entity that activated a trigger or brush

entity	damage_attacker;	// set by T_Damage
float	framecount;

float		skill;

//================================================

//
// world fields (FIXME: make globals)
//
.string		wad;
.string 	map;
.float		worldtype;	// 0=medieval 1=metal 2=base

//================================================

.string		killtarget;

//
// quakeed fields
//
.float		light_lev;		// not used by game, but parsed by light util
.float		style;


//
// monster ai
//
.void()		th_stand;
.void()		th_walk;
.void()		th_run;
.void()		th_missile;
.void()		th_melee;
.void(entity attacker, float damage)		th_pain;
.void()		th_die;

.entity		oldenemy;		// mad at this player before taking damage

.float		speed;

.float	lefty;

.float	search_time;
.float	attack_state;

float	AS_STRAIGHT		= 1;
float	AS_SLIDING		= 2;
float	AS_MELEE		= 3;
float	AS_MISSILE		= 4;

//
// player only fields
//
.float		walkframe;

.float 		attack_finished;
.float		pain_finished;

.float		invincible_finished;
.float		invisible_finished;
.float		super_damage_finished;
.float		radsuit_finished;

.float		invincible_time, invincible_sound;
.float		invisible_time, invisible_sound;
.float		super_time, super_sound;
.float		rad_time;
.float		fly_sound;

.float		axhitme;

.float		show_hostile;	// set to time+0.2 whenever a client fires a
							// weapon or takes damage.  Used to alert
							// monsters that otherwise would let the player go
.float		jump_flag;		// player jump flag
.float		swim_flag;		// player swimming sound flag
.float		air_finished;	// when time > air_finished, start drowning
.float		bubble_count;	// keeps track of the number of bubbles
.string		deathtype;		// keeps track of how the player died

//
// object stuff
//
.string		mdl;
.vector		mangle;			// angle at start

.vector		oldorigin;		// only used by secret door

.float		t_length, t_width;


//
// doors, etc
//
.vector		dest, dest1, dest2;
.float		wait;			// time from firing to restarting
.float		delay;			// time from activation to firing
.entity		trigger_field;	// door's trigger entity
.string		noise4;

//
// monsters
//
.float 		pausetime;
.entity 	movetarget;


//
// doors
//
.float		aflag;
.float		dmg;			// damage done by door when hit
	
//
// misc
//
.float		cnt; 			// misc flag
	
//
// subs
//
.void()		think1;
.vector		finaldest, finalangle;

//
// triggers
//
.float		count;			// for counting triggers


//
// plats / doors / buttons
//
.float		lip;
.float		state;
.vector		pos1, pos2;		// top and bottom positions
.float		height;

//
// sounds
//
.float		waitmin, waitmax;
.float		distance;
.float		volume;




//===========================================================================
	

//
// builtin functions
//

void(vector ang)	makevectors		= #1;		// sets v_forward, etc globals
void(entity e, vector o) setorigin	= #2;
void(entity e, string m) setmodel	= #3;		// set movetype and solid first
void(entity e, vector min, vector max) setsize = #4;
// #5 was removed
void() break						= #6;
float() random						= #7;		// returns 0 - 1
void(entity e, float chan, string samp, float vol, float atten) sound = #8;
vector(vector v) normalize			= #9;
void(string e) error				= #10;
void(string e) objerror				= #11;
float(vector v) vlen				= #12;
float(vector v) vectoyaw			= #13;
entity() spawn						= #14;
void(entity e) remove				= #15;

// sets trace_* globals
// nomonsters can be:
// An entity will also be ignored for testing if forent == test,
// forent->owner == test, or test->owner == forent
// a forent of world is ignored
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;	

entity() checkclient				= #17;	// returns a client to look for
entity(entity start, .string fld, string match) find = #18;
string(string s) precache_sound		= #19;
string(string s) precache_model		= #20;
void(entity client, string s)stuffcmd = #21;
entity(vector org, float rad) findradius = #22;
void(string s) bprint				= #23;
void(entity client, string s) sprint = #24;
void(string s) dprint				= #25;
string(float f) ftos				= #26;
string(vector v) vtos				= #27;
void() coredump						= #28;		// prints all edicts
void() traceon						= #29;		// turns statment trace on
void() traceoff						= #30;
void(entity e) eprint				= #31;		// prints an entire edict
float(float yaw, float dist) walkmove	= #32;	// returns TRUE or FALSE
// #33 was removed
float(float yaw, float dist) droptofloor= #34;	// TRUE if landed on floor
void(float style, string value) lightstyle = #35;
float(float v) rint					= #36;		// round to nearest int
float(float v) floor				= #37;		// largest integer <= v
float(float v) ceil					= #38;		// smallest integer >= v
// #39 was removed
float(entity e) checkbottom			= #40;		// true if self is on ground
float(vector v) pointcontents		= #41;		// returns a CONTENT_*
// #42 was removed
float(float f) fabs = #43;
vector(entity e, float speed) aim = #44;		// returns the shooting vector
float(string s) cvar = #45;						// return cvar.value
void(string s) localcmd = #46;					// put string into local que
entity(entity e) nextent = #47;					// for looping through all ents
void(vector o, vector d, float color, float count) particle = #48;// start a particle effect
void() ChangeYaw = #49;						// turn towards self.ideal_yaw
											// at self.yaw_speed
// #50 was removed
vector(vector v) vectoangles			= #51;

//
// direct client message generation
//
void(float to, float f) WriteByte		= #52;
void(float to, float f) WriteChar		= #53;
void(float to, float f) WriteShort		= #54;
void(float to, float f) WriteLong		= #55;
void(float to, float f) WriteCoord		= #56;
void(float to, float f) WriteAngle		= #57;
void(float to, string s) WriteString	= #58;
void(float to, entity s) WriteEntity	= #59;

//
// broadcast client message generation
//

// void(float f) bWriteByte		= #59;
// void(float f) bWriteChar		= #60;
// void(float f) bWriteShort		= #61;
// void(float f) bWriteLong		= #62;
// void(float f) bWriteCoord		= #63;
// void(float f) bWriteAngle		= #64;
// void(string s) bWriteString	= #65;
// void(entity e) bWriteEntity = #66;

void(float step) movetogoal				= #67;

string(string s) precache_file		= #68;	// no effect except for -copy
void(entity e) makestatic		= #69;
void(string s) changelevel = #70;

//#71 was removed

void(string var, string val) cvar_set = #72;	// sets cvar.value

void(entity client, string s) centerprint = #73;	// sprint, but in middle
//arena
void(entity client, string s, string s2, string s3, string s4) centerprint4 = #73;        // sprint, but in middle
void(entity client, string s, string s2, string s3, string s4, string s5) centerprint5 = #73;        // sprint, but in middle
void(entity client, string s, string s2, string s3, string s4, string s5, string s6) centerprint6 = #73;        // sprint, but in middle
//arena

void(vector pos, string samp, float vol, float atten) ambientsound = #74;

string(string s) precache_model2	= #75;		// registered version only
string(string s) precache_sound2	= #76;		// registered version only
string(string s) precache_file2		= #77;		// registered version only

void(entity e) setspawnparms		= #78;		// set parm1... to the
												// values at level start
												// for coop respawn

//============================================================================

//
// subs.qc
//
void(vector tdest, float tspeed, void() func) SUB_CalcMove;
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt;
void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove;
void()  SUB_CalcMoveDone;
void() SUB_CalcAngleMoveDone;
void() SUB_Null;
void() SUB_UseTargets;
void() SUB_Remove;

//
//	combat.qc
//
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;


float (entity e, float healamount, float ignore) T_Heal; // health function

float(entity targ, entity inflictor) CanDamage;


// arena
// globals
float   AA_Pickup;
float   AA_Custom_Map;
float   AA_Got_Change_Parms;
float   AA_Min_Players;
entity  AA_List1;
entity  AA_List2;
entity  AA_List3;
entity  AA_List4;
entity  AA_Spec1;
entity  AA_Spec2;
entity  AA_Spec3;
entity  AA_Spec4;
float   AA_Game_State;
float   AA_Comp_State;
float   AA_Game_Mode;
float   AA_Count_Time;
//float   AA_Second_Toggle;
//entity  AA_First_Player;
//entity  AA_Second_Player;
entity  AA_Winner;
entity  AA_Players;
entity  AA_Specs;
float   AA_Cur_Round;
float   AA_Highest_Num;
float   AA_List_Num;
float   AA_Is_Dead;
float   AA_Idmap;
float   AA_Fook;
float   AA_Game_Time;
float   AA_Num_Rounds2;
float   AA_Set_Num;
float   AA_Cur_Set;
float   AA_Counted_Teams;
float   AA_Admin_Code;
entity  AA_Last_Player;
float   AA_MK_Sounds;
float   AA_Runnerup;
float   AA_Force;
float   AA_Locked;
float   AA_Menus;
float   AA_Grace;
float   AA_Setup_Hack;
float   AA_Report_Flag;
float   AA_Fullteams;
// server reset timeouts
float   AA_Idle_Time;
float   AA_Idle_Val;
// temp holding vars
float   AA_V_Armor;
float   AA_V_Weapons;
float   AA_V_Armor;
float   AA_V_Weapons;
float   AA_V_Atype;
float   AA_V_Health;
float   AA_V_Shells;
float   AA_V_Nails;
float   AA_V_Rockets;
float   AA_V_Cells;
float   AA_V_Rounds;
float   AA_V_Teams;
float   AA_V_Players;
float   AA_V_Players2;
float   AA_V_Mode;
float   AA_V_Teamplay;
// game vars
float   AA_Armor;
float   AA_Weapons;
float   AA_Armor;
float   AA_Weapons;
float   AA_Atype;
float   AA_Health;
float   AA_Shells;
float   AA_Nails;
float   AA_Rockets;
float   AA_Cells;
float   AA_Num_Rounds;
float   AA_Num_Teams;
float   AA_Num_Players;
// voting
entity  AA_Vote_Ent;
float   AA_Vote_Pct;
float   AA_Vote_Time;

// constatns
// game states
float   AA_GAME_WAIT    = 1;
float   AA_GAME_READY   = 2;
float   AA_GAME_ON      = 3;
float   AA_GAME_OFF     = 4;
float   AA_GAME_PAUSE   = 5;
float   AA_GAME_COUNT   = 6;
float   AA_GAME_DRAW    = 7;
// competition states
float   AA_COMP_WAIT    = 1;
float   AA_COMP_READY   = 2;
float   AA_COMP_ON      = 3;
float   AA_COMP_OFF     = 4;
float   AA_COMP_OFF2    = 5;
float   AA_COMP_COUNT   = 6;
float   AA_COMP_OFF3    = 7;
// player states
float   AA_NEW          = 1;
float   AA_NOT_READY    = 2;
float   AA_PLAYER       = 3;
float   AA_SPEC         = 4;
float   AA_NULL         = 5;
float   AA_NORMAL       = 20;
float   AA_ADMIN        = 21;
// game modes
float   AA_GM_NORMAL    = 1;
float   AA_GM_COMP      = 2;
float   AA_GM_ROUND     = 3;
// sound
float   AA_SD_COUNT     = 1;
float   AA_SD_KO        = 2;
float   AA_SD_FIGHT     = 3;
float   AA_SD_DRAW      = 4;
float   AA_SD_ROUND     = 5;
float   AA_SD_PERFECT   = 6;

// prototypes
void() AA_Arena_Init;
void() AA_Arena_Think;
entity(entity foo) AA_Get_New;
entity(string name, float which) AA_Make_List;
void(entity list, entity foo) AA_Add_To_List;
void(entity list, entity foo) AA_Remove_From_List;
float(entity list) AA_Count_List;
entity(entity list) AA_Shift_List;
entity(entity list, float who) AA_Get_Pos;
void(entity foo) AA_Set_Ammo;
void(entity foo) AA_Place_Player;
void() AA_Init_New_Player;
void(entity foo) AA_Delete_Player;
void() AA_Ready_Command;
void() AA_Competition;
float() AA_Count_Projectiles;
float(string foos) AA_Check_Projectile;
void() AA_Impulses;
void() AA_Precache;
void(float which, float num) AA_Play_Sound;
void(float which, float num) AA_Play_MK_Sound;
//void() AA_Set_Draw;
void(entity foo) AA_Force_Respawn;
void() AA_Init_Lists;
void() AA_Game_Loop;
float(entity list) AA_Count_Lists;
void(entity list) AA_Set_Ammo_Lists;
void(entity list) AA_Set_Ammo_List;
float(entity list) AA_Get_Players_Lists;
void(entity fromlist, entity tolist) AA_Get_Players_List;
void(entity list) AA_Show_Players_Lists;
void(entity list, float isfirst) AA_Show_Players_List;
void(entity list) AA_Clear_Lists;
void(entity list, entity who, string foos) AA_Set_Team;
void(entity list, entity who) AA_Add_To_Smallest_Team;
entity(entity list, entity who, float which) AA_Get_Team;
void(entity list) AA_Set_Order_Lists;
void(entity list) AA_Set_Order_List;
void() AA_Report_Round;
void() AA_Round_Think;
void(entity list) AA_Remake_Lists;
void(entity list) AA_Remake_List;
entity(float which, float id) AA_Find_Pos;
void() AA_Respawn_All;
void() AA_Check_Map;
void() AA_Remove_Stuff;
void(string foos) AA_Remove_Thing;
void(entity foo) AA_Clear_Stats;
void(entity foo, float which) AA_Report_Stats;
void(entity list) AA_Print_List;
void(entity list, float id) AA_Report_Stats_Team;
void() AA_Competition2;
float(float num, float pwr) AA_Power;
float(float num, float mod, float lev) AA_Modulo;
float(entity list) AA_Make_Sets;
float(entity list, float num) AA_Make_Set;
float(entity list) AA_Count_Teams;
void() AA_Play_Perfect;
void() AA_Perfect_Think;
void() AA_Status_Think;
void() AA_Show_Rank;
float(entity list, float pos) AA_Check_Forfeit;
void(entity list) AA_Report_Forfeit;
void(entity list) AA_Clear_Stats_Lists;
entity(entity list) AA_Find_Empty_Team;
entity(entity list, float id) AA_Find_List;
void(entity list, float id) AA_Give_Win;
entity(entity list, float which) AA_Find_Winner_Team;
void(entity list) AA_Report_Stats2;
void(entity list) AA_Accumulate_Stats_Lists;
void(entity list) AA_Accumulate_Stats_List;
void() AA_Change_Mode;
void(entity foo) AA_Start_Stuffs;
void() AA_Stuffs_Think;
void(entity foo, float which) AA_Make_Admin;
void(entity foo) AA_Print_Commands;
void() AA_Show_Commands;
//void(entity foo) AA_Admin_Vars;
//float(entity foo, string foos, float num) AA_Check_Var;
void() AA_Set_Vars;
void() AA_Set_Defaults;
void(entity list) AA_Print_Teams;
entity(string foos) AA_SelectSpawnPoint;
void() AA_Not_Ready_Command;
void() AA_Link_Teams;
void(entity list) AA_Clear_Empty_Teams;
void(entity foo) AA_List_Maps;
void(float which) AA_Warp_Command;
void(float num) AA_Choose_Idmap;
void(entity foo) AA_Elect_Command;
void() AA_Vote_Think;
void(entity foo, float which) AA_Vote_Command;
void() AA_End_Vote;
void() AA_Clear_Arena;
void(entity who) AA_Show_Settings;
float(entity list) AA_Get_Players_Lists2;
void(entity who) AA_List_Players_Command;
void() AA_Unready_All;
entity(entity list) AA_Get_First_Player;
void() AA_Get_Change_Parms;
//float(float parm, float which, float size) AA_Read_Parm;
void() AA_Set_Change_Parms;
//float(float parmval, float val, float which, float size) AA_Set_Parm;
void() AA_Toss_Player;
void() AA_Solid_Player;
void() AA_Reset_Server;
void() AA_Report_Stats3;
void(entity list) AA_Reset_Teams;
void(entity list) AA_Reset_Team_List;
void(entity who) AA_Clear_Team;
void() AA_Clear_Frags;
void() AA_Reset_Command;
void(float which) AA_Toggle_Weapon;
void(entity who, float col) AA_Set_Color;
float(entity who) AA_Get_Color;
void() AA_Get_Missing_Players;
void(entity who) AA_Check_Missing_Player;
void(float num) AA_Print_Num;
void(float num, entity who) AA_Print_Num2;
void(entity list) AA_Clear_Stats_List2;
void(entity list) AA_Scores_Command;
void() AA_Link_Teams2;
void(entity who) AA_Kick_List;
void(entity who, float num) AA_Kick_Command;
void(entity who) AA_Kick;
void() AA_Lock_Server;
void() AA_Unlock_Server;
void() AA_Auto_Lock;
void() AA_Auto_Unlock;
void() AA_Check_Empty;
//v1.1
void() AA_Pickup_Command;
string(float num) AA_Get_Name_For_Team;
void() AA_Tmset_Command;
void() AA_Plup_Command;
void() AA_Pldown_Command;
void() AA_Tmup_Command;
void() AA_Tmdown_Command;
void() AA_Rdup_Command;
void() AA_Rddown_Command;
void() AA_Cells_Command;
void() AA_Rockets_Command;
void() AA_Nails_Command;
void() AA_Shells_Command;
float(float num) AA_Ammo_Command;
void(entity who, string foos, float num) AA_Show_Var;
void() AA_Atset_Command;
void() AA_Amup_Command;
void() AA_Amdown_Command;
void() AA_Hup_Command;
void() AA_Hdown_Command;
void() AA_Set_Vars2;
string(float num) AA_Get_Map_For_Num;
void() AA_Draw_Hack1;
void() AA_Draw_Hack2;
void(entity who, float which) AA_Set_Team_Menus;
void(entity foo) AA_Setup_Command;
void(string foos) AA_Cprint;
void() AA_MK_Hack;
float() AA_Check_Fullteams;
void() AA_Fullteams_Command;
void(entity who) AA_Cprint_Command;
void(entity who, float topcol, float bottomcol) AA_Set_Color2;

// disconnect
float   SVC_DISCONNECT  = 2;

// body chute
float   AA_Body_Chute;
void(entity who) AA_Shoot_Body;

// tracking
void(entity who) AA_Track;
void(entity who) AA_Track_On;
void(entity who) AA_Toggle_Pl;
void(entity who) AA_Track_Off;
void() AA_Track_Hit_Wall;

// status bar
string(entity who) AA_Get_Status;
void(entity who) AA_Status_Bar;
void() AA_Sbup_Command;
void() AA_Sbdown_Command;

// debug
float   AD_Curbot;
entity  AD_Thebot;
float   AD_FAKE         = 10;
float   AD_Team;
float   AD_Break;
string  AD_Team_Name;
void() AD_Spawn_Fake;
void() AD_Respawn;
void() AD_Select_Bot;
void() AD_Ready_Bot;
void() AD_Set_Team;
void() AD_Killbot;
void() AD_Check_Col;
// arena
