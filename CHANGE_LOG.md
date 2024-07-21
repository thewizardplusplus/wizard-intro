# Change Log

## [v1.2.0](https://github.com/thewizardplusplus/wizard-intro/tree/v1.2.0) (2024-07-22)

Implement the drawing of the text rectangles.

- drawing of the text rectangles (optionally):
  - automatic horizontal and vertical centering;
  - automatic text splitting into lines:
    - each line contains as many words as possible;
    - select the largest possible font size to fit the text on the screen;
  - animations:
    - animation of appearing from behind the edge of the screen;
    - animation of letter-by-letter typing;
    - common features:
      - all animations run sequentially one after the other;
      - support for a start delay for animation;
      - quit at the finish of the animation.

## [v1.1.0](https://github.com/thewizardplusplus/wizard-intro/tree/v1.1.0) (2024-07-19)

Implement the drawing of the logo.

- drawing of the background:
  - automatic horizontal and vertical centering;
  - perform refactoring:
    - add the field wrapper;
    - partially reimplement the field updating;
- drawing of the logo (optionally):
  - automatic horizontal and vertical centering;
  - fade in and out:
    - support for a start delay for fading in;
    - quit at the finish of the fading out.

## [v1.0.0](https://github.com/thewizardplusplus/wizard-intro/tree/v1.0.0) (2024-07-17)

Major version. Implement the drawing of the background (use [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway's_Game_of_Life) as a background).
