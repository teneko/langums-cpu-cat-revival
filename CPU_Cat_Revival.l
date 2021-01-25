global current_wave = 0;
global wave_time = 10;
global zero = 0;
global player_flags[7];
global flags = 0;

fn main() {
  show_leaderboard("Cats Killed", Kills, Men);
  leaderboard_show_cpu(Disable);

  run_ai_script(Force1, TurnOnSharedVisionOfPlayer8WithCurrentPlayer);

  if (current_wave == 0) {
    // Activate once. The next countdown 
    // starts when wave units are spawned.
    set_countdown(wave_time);
    clear_buffered_events();
  }

  while(true) {
    poll_events();
  }
}

// Check defeat condition
deaths(Force1, AtLeast, 1, ProtossProbe),
commands(Force1, Exactly, 0, ProtossProbe),
commands(Force1, Exactly, 0, ProtossShieldBattery) => {
  print("DEFEAT");
  // end(Force1, Defeat);
}

// Prints "mice died"
fn print_mice_died() {
  print("Mice died! Rescue them fast by catching their flags.");
}

// Display "mice died" to increase teamplay
commands(Force1, AtLeast, 1, PowerupFlag),
countdown(Exactly, 1) => {
  for <PlayerId> in (Player1,Player2,Player3,Player4,Player5,Player6,Player7) {
    if (player_flags[PlayerId] == 1) {
      print_mice_died();
      return;
    }
  }
}

unit ProbeTheBoss {
  Energy = 100,
  Invincible = true
}

// Determines wave location
fn determine_wave_location(locationIndex) {
  for <LocationIndex, LocationName> in (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63), ("Location 1", "Location 2", "Location 3", "Location 4", "Location 5", "Location 6", "Location 7", "Location 8", "Location 9", "Location 10", "Location 11", "Location 12", "Location 13", "Location 14", "Location 15", "Location 16", "Location 17", "Location 18", "Location 19", "Location 20", "Location 21", "Location 22", "Location 23", "Location 24", "Location 25", "Location 26", "Location 27", "Location 28", "Location 29", "Location 30", "Location 31", "Location 32", "Location 33", "Location 34", "Location 35", "Location 36", "Location 37", "Location 38", "Location 39", "Location 40", "Location 41", "Location 42", "Location 43", "Location 44", "Location 45", "Location 46", "Location 47", "Location 48", "Location 49", "Location 50", "Location 51", "Location 52", "Location 53", "Location 54", "Location 55", "Location 56", "Location 57", "Location 58", "Location 59", "Location 60", "Location 61", "Location 62", "Location 63", "Location 66") {
    if (LocationIndex == locationIndex) {
      print(LocationName);
      spawn(ZergUltralisk, Player8, 1, LocationName);
      run_ai_script(Player8, SendAllUnitsOnRandomSuicideMissions);
      set_countdown(wave_time);
      return;
    }
  }
}

countdown(Exactly, 1) => {
  current_wave++;

  var randomLocation = random();

  while (randomLocation > 63) {
    randomLocation = randomLocation - 64;
  }

  determine_wave_location(randomLocation);
}

fn spawn_probe<PlayerId, LocationName>(PlayerId, LocationName) {
  spawn(ProtossProbe, PlayerId, 1, LocationName);
  center_view(PlayerId, LocationName);
}

for <PlayerId> in (Player1,Player2,Player3,Player4,Player5,Player6,Player7) {
  commands(PlayerId, AtLeast, 1, ProtossPylon) => {
    modify(ProtossPylon, PlayerId, 999, Health, 100, AnyLocation);
    modify(ProtossPylon, PlayerId, 999, Shields, 100, AnyLocation);
    // Function set_invincibility need a force as player type.
    set_invincibility(AllPlayers, ProtossPylon, Enable, AnyLocation);
  }

  commands(PlayerId, AtLeast, 1, ZergQueen) => {
    modify(ZergQueen, PlayerId, 0, Energy, 0, AnyLocation);
    set_invincibility(PlayerId, ZergQueen, Enable, AnyLocation );
  }

  // First Protoss Probe
  deaths(PlayerId, Exactly, 0, ProtossProbe),
  commands(PlayerId, Exactly, 0, ProtossProbe),
  commands(PlayerId, Exactly, 0, PowerupFlag) => {
    sleep(200);
    spawn(ProtossProbe, PlayerId, 1, MapCentral);
  }

  // Rescue Protoss Probe by ally men
  bring(Force1, AtLeast, 1, Men, MapCentral),
  commands(PlayerId, Exactly, 1, PowerupFlag) => {
    kill(PowerupFlag, PlayerId, 1, AnyLocation);

    if (!is_present(PlayerId)) {
      return;
    }

    spawn_probe(PlayerId, MapCentral);
  }

  // Protoss Probe death
  deaths(PlayerId, AtLeast, 1, ProtossProbe),
  commands(PlayerId, Exactly, 0, ProtossProbe),
  commands(PlayerId, Exactly, 0, ProtossShieldBattery),
  commands(PlayerId, Exactly, 0, PowerupFlag) => {
      // remove(AllUnits, PlayerId, 999);
      remove(TerranSCV, PlayerId, 999);
      spawn(PowerupFlag, PlayerId, 1, MapCentral);
      print_mice_died();
  }

  // Set flag = true
  commands(PlayerId, Exactly, 1, PowerupFlag) => {
    player_flags[PlayerId] = 1;
  }

  // Set flag = false
  commands(PlayerId, Exactly, 0, PowerupFlag) => {
    player_flags[PlayerId] = 0;
  }
}

for <PlayerId, NexusLocation> in (Player1,Player2,Player3,Player4,Player5,Player6,Player7), (Nexus1, Nexus2, Nexus3, Nexus4, Nexus5, Nexus6, Nexus7) {
  // Rescue Probe by Protoss Shield Battery
  commands(PlayerId, Exactly, 0, ProtossProbe),
  commands(PlayerId, AtLeast, 1, ProtossShieldBattery) => {
    move_loc(ProtossShieldBattery, PlayerId, AnyLocation, NexusLocation);
    kill(ProtossShieldBattery, PlayerId, 1, AnyLocation);
    spawn_probe(PlayerId, NexusLocation);
  }

  // Spawn Terran SCV
  commands(PlayerId, AtLeast, 1, ProtossZealot) => {
    kill(ProtossZealot, PlayerId, 1, AnyLocation);
    spawn(TerranSCV, PlayerId, 1, NexusLocation);
  }

  // Spawn SCV Dropper
  commands(PlayerId, Exactly, 0, ZergQueen),
  commands(PlayerId, AtLeast, 1, ProtossProbe),
  commands(PlayerId, AtLeast, 1, ProtossNexus) => {    
    move_loc(ProtossNexus, PlayerId, AnyLocation , NexusLocation);
    spawn(ZergQueen, PlayerId, 1, NexusLocation);
  }

  // Set Terran SCV spawn location
  commands(PlayerId, AtLeast, 1, ZergQueen) => {
    move_loc(ZergQueen, PlayerId, AnyLocation , NexusLocation);
  }
}