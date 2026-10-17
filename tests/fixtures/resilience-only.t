/* Injury and recovery do not require conflict, progression, language or reporting. */
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-resilience.t>
clinic: Room 'Clinic';
patient: RpgProfile actor = player resilience = patientBody;
patientBody: RpgBody profile = patient;
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
modify gameMain initialRoom = clinic;
