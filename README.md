# Purrfect Parkour

A colorful little 2D rooftop platform adventure made with **Godot 4.7.2**. Help a brave orange cat leap between buildings, climb leafy trees, and scoop up shiny fish medals!

## Play

Open this folder in Godot 4.7.2 and press **F6** (or run the project). On the title screen, click **LET'S PLAY!** or press Enter.

- **Move:** A / D or Left / Right
- **Jump:** Space or Up
- **Climb:** Hold Up or Down while beside a tree
- **Pause / resume:** Escape

Race through two districts—the sunny Rooftop Run and the starry Moonlight Market—to reach the garden rooftop at the far end. Find all 18 fish medals, use your extra mid-air air-pounce and rooftop spring pads to rescue tricky jumps, and look for two checkpoints along the way. Falling just sends you back to your last safe rooftop.

## Testing

The GitHub Actions workflow runs the project on Godot 4.7.2 headless: first editor import/script validation, then a short runtime smoke test. Locally, the same checks are:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 5
```

All art is drawn in GDScript, so there are no external asset downloads or import steps required for play.
