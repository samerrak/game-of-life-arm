# Game of Life Using ARMv7 Assembly Code 

This repository contains the implementation of the "Game of Life". This project demonstrates the integration of the **VGA driver** and **PS/2 keyboard driver** to create an interactive simulation of Conway's Game of Life on the DE1-SoC FPGA.

## Features

- **Grid Display**: A 16x12 grid representing the Game of Life board is rendered on the VGA screen.
- **Interactive Controls**: Users can use the PS/2 keyboard to interact with the grid:
  - **W, A, S, D keys**: Move a cursor across the grid.
  - **Spacebar**: Toggle the state of a cell (alive or dead).
  - **N key**: Apply the rules of the Game of Life to progress the simulation.
- **Game Logic**: Implements Conway's Game of Life rules to update the board state:
  - Alive cells with fewer than 2 or more than 3 neighbors die.
  - Dead cells with exactly 3 neighbors become alive.

## File Structure

- **vga.s**: Contains the VGA driver implementation for rendering points, characters, and the grid.
- **ps2.s**: Contains the PS/2 keyboard driver implementation for reading and interpreting keyboard inputs.
- **gol.s**: Main application implementing the Game of Life, integrating both the VGA and PS/2 drivers.

## How It Works

1. **Grid Drawing**:
   - A grid is drawn using horizontal and vertical lines to divide the screen into a 16x12 grid.
   - Each cell can be toggled between alive (filled) and dead (empty).

2. **Interactive Cursor**:
   - A cursor, distinct from the grid, moves across the board based on user input from the PS/2 keyboard.

3. **Game Rules**:
   - The state of the board is stored in memory as a 2D array.
   - Upon pressing `N`, the game updates all cells based on the rules of Conway's Game of Life.

4. **Rendering**:
   - The VGA driver updates the grid in real time to reflect the current state of the board.

## Keyboard Controls

- **W, A, S, D**: Move the cursor up, left, down, or right.
- **Spacebar**: Toggle the state of the cell under the cursor (alive or dead).
- **N**: Apply Game of Life rules to progress to the next state.

## Usage Instructions

1. **Compile**:
   - Ensure all files (`vga.s`, `ps2.s`, and `gol.s`) are assembled and linked correctly using the ARM simulator provided in the lab.

2. **Run**:
   - Load the compiled binary onto the DE1-SoC simulator or board.
   - Open the VGA pixel buffer view to see the rendered grid.
   - Use the PS/2 keyboard input to interact with the game.

3. **Testing**:
   - Verify the grid displays correctly.
   - Ensure keyboard inputs (e.g., W, A, S, D, Spacebar, N) modify the grid as expected.

## Deliverables Overview

- **Code**:
  - Implementation of the VGA and PS/2 drivers.
  - Game of Life logic integrating these drivers.
- **Demo**:
  - A demonstration showcasing the interactive Game of Life on the VGA screen.
- **Report**:
  - A detailed report describing the approach, challenges, and testing methodology.

## Credits

This project was developed as part of McGill University's ECSE 324: Computer Organization course under the guidance of Professor Brett H. Meyer.
