/* Progression requires only the core, not condition, dialogue or reporting modules. */
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
study: Room 'Study';
student: RpgProfile actor = player;
chapter: RpgMilestone id = 'chapter' points = 10;
chapterReceipt: RpgAward profile = student milestone = chapter;
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
modify gameMain initialRoom = study;
