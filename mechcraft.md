<style>
  /* just some css injection
  */
  .span {
    margin:auto;
  }
  p {
    white-space: pre-line;
  }
</style>


This is a doc of technical stuff

**Overall game design is here**:
https://docs.google.com/document/d/1_mchctExyfANMstbnlfEHbj8GiNQbtsnMjGoqCRgeic/edit?usp=sharing

## General stuff about making the game not crash

The game will process every tile in the world every tick. There will probably like 5 ticks every second or something.
It doesn't need to be very fast (because the items would go flying otherwise).

🌎world update order:
- for each storage tile
  - process conveyor lines ending at it
    - process lines connecting to those
- process remaining lines and tiles
- miner storage replenishes

🌟**singular item storage** (for every tile unless specified)
- simplifies code and rules
- speed upgrades not viable
- alternate objective like organization

🌟output items to empty tiles and storage overflow items are deleted

merger, splitter, intersection have been combined into conveyor balancer


## Rocket

End game goal.
Can't be destroyed.

## Noise score

Every tile has a noise score. If the noise score of a tile is too high, a sandworm or something eats the surrounding tiles, destroying tiles and collapsing the ground.
- Collapsed tiles cannot be built on and slowly regenerate into normal tiles.
- There is only 1 sandworm in the game, attacks can't happen simultaneously
- Attacks have a minimum grace period (so the worm isn't eating your entire factory)

## Conveyor

The one and only.

- Has exactly one input and one output across it.
- If output isn't pointing at an input, items are deleted instead of moved
- Splitting and merging will be handled by other tiles.

## Conveyor Balancer

Makes stuff work out depending on the number of inputs and outputs connected.
It's basically a **splitter and merger and intersection** combined into one.

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

## Conveyor Line

Not an actual tile.

- A list of tiles used for calculations
- One path of conveyors defined by a start tile (miner) and an end tile (merger, splitter, storage, basically everything that isn't a conveyor)
- No weird loops cause that would make the code way more complicated.
- Processes from end tile to first conveyor

## Miner

Pulls resources from the ground every [insert random number].

- No extra internal storage (just the regular single item one)
- Adds resources to internal storage every tick

## Storage

- Literally just storage

## Constructor

Makes new things out of things.

- Has 2 inputs opposite of each other and 1 output
- Takes two input items to make one output item

## Launcher?

probably not going to be added

- Launches item 3 or 4 tiles without collision
- Larger delay
- More "noise"


