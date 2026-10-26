# Dead Air: Archive 09

A Godot 4 visual novel investigation prototype. A self-taught hacker in 2026 slips into a 2004 hotel security archive and discovers footage surrounding a cold-case murder.

## Run the game

1. Install Godot 4.3 or newer.
2. In Godot, choose **Import** and select this folder's `project.godot`.
3. Press **F5** to run the project.
4. Choose **Start New Case**. The archive scene loads in the background before the investigation opens.
5. Click the teal choices to compare camera records, gather clues, and decide what to do with the evidence.

Press **Esc** to pause at the menu. Use **Save Case** to write a checkpoint, **Load Saved Case** from the menu to restore it, or **Continue Current Case** to return to the current session. The save file is stored at `user://archive09_save.cfg`.

## Included

- A 1280×720 CRT-inspired terminal with a changing camera feed, scanlines, system status, operator profile, and recovered-clue list.
- Branching dialogue, optional clues, and seven endings, including a solve-the-case route and several deliberately flawed outcomes.
- A camera index comparison in the hallway and a shift report investigation on the stairs replace the former keyboard movement prompt.
- Button choices and evidence events use code-connected signals. The archive scene loads with `ResourceLoader.load_threaded_request()` behind a transition screen.
- Persistent case checkpoints use `ConfigFile` in `user://`. Static project assets and scenes are kept under `res://`.

## Project files

- `project.godot` — project settings and entry point.
- `Main.tscn`, `main.gd` — terminal UI, menu, dialogue, story choices, threaded loading, and save/load behavior.
- `ArchiveRoom.tscn`, `archive_room.gd` — camera-frame visuals and collision-based clue logic retained for future expansion.
