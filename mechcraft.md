~~Coding~~ ~~Designing~~ Doing anything that makes progress for this is gonna be ~~really~~ mildly annoying.

## General stuff about making the game not crash

The game will process every tile in the world every tick. There will probably like 5 ticks every second or something.  

🌎 world update order:
- for each storage tile
  - process conveyor lines ending at it (while recursively processing line connecting to those)
- process remaining lines and tiles (the random unconnected ones)
- miner storage replenishes
- whatever else there is (winning objectives)

🌟singular item storage (for conveyors and stuff)
- simplifies code and rules
- speed upgrades not viable
- alternate objective like organization

🌟output items to empty tiles and storage overflow items are deleted

merger, splitter, and launcher have been combined into conveyor balancer

## Item costs?

idk

## Conveyor

- Has exactly one input and one output across it.
- If output isn't pointing at an input, items are deleted instead of moved
- Splitting and merging will be handled by other tiles.

## Conveyor Balancer

Basically it merges or splits two inputs and outputs

- Has 2 adjacent inputs and 2 adjacent outputs
- Has a selected input and output (when needed)
- If 2 inputs and 2 outputs are connected (even if there are no items)
  - Each input goes to the output across from it (like 2 seperate conveyors)
- If 1 input and 2 outputs are connected
  - The output alternates for each item
- If 2 inputs and 1 output are connected
  - The input alternates for each item
- If 1 input and 1 output are connected
  - uhhh, it doesn't do anything?

outputs are `rotation` and `rotation + 1`

## Conveyor Line

A list of tiles used for calculations

- One path of conveyors defined by a start tile (miner) and an end tile (merger, splitter, storage, basically everything that isn't a conveyor)
- No weird loops cause that would make the code way more complicated.
- Processes from end tile to first conveyor

## Miner

Where stuff spawns

- Has a small internal storage
- Adds resources to internal storage every tick
- 

## Storage

- Literally just storage

## Constructor

Makes stuff

- Has 2 adjacent inputs and 1 output (2 layouts ignoring rotation)
- Takes two input items to make one output item

