# Change Log

## [v1.4.0](https://github.com/thewizardplusplus/wizard-intro/tree/v1.4.0) (2024-08-19)

Add menu and settings and fix the bugs with drawing of the text rectangles.

- drawing of the text rectangles:
  - fix the bug with infinite animation and sound if there is only one text rectangle;
  - fix the bug with a doubled gap after the last text rectangle;
- menu and settings:
  - main menu allows to choose between the general drawing modes (see above);
  - background settings allow to choose between the background drawing modes (see above);
  - text rectangle settings allow to set the text to be displayed.

## [v1.3.0](https://github.com/thewizardplusplus/wizard-intro/tree/v1.3.0) (2024-08-11)

Add the sounds to the animations.

- drawing of the logo:
  - fade in and out:
    - play the sounds during the animation:
      - play the foreground sound during the fading in;
      - play the background sound during the fading in and out;
- drawing of the text rectangles:
  - animations:
    - common features:
      - play the separate sound during each animation.

## [v1.2.1](https://github.com/thewizardplusplus/wizard-intro/tree/v1.2.1) (2024-07-24)

Improve drawing of the background and the text rectangles.

- drawing of the background:
  - quit at a finish of the animation:
    - for the duration of the animation is taken the minimum duration of the end YouTube screen;
  - support for the several drawing modes:
    - pale mode;
    - transparent mode;
    - blur mode:
      - box blur;
      - fast Gaussian blur;
      - Gaussian blur;
      - glow;
  - tune up the random generator;
- drawing of the text rectangles:
  - automatic horizontal and vertical centering:
    - improve vertical distribution of the rectangles;
    - restrict the maximal rectangle margin;
  - align text in the rectangles to the center;
  - fix the bugs:
    - remove a trailing space from text lines;
    - fix the bug with a missing side padding.

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
