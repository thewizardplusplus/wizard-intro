# Wizard Intro

![](docs/screenshot_1.png)

The demo to generate intros for my YouTube channel.

I came up with an intro for my videos, but my video editing experience wasn't enough to realize what I had in mind. So I decided to write a demo to render this intro and then use screen capture.

_**Disclaimer:** this demo was written directly on an Android smartphone with the [QLua](https://play.google.com/store/apps/details?id=com.quseit.qlua5pro2) IDE and the [LÖVE for Android](https://play.google.com/store/apps/details?id=org.love2d.android) app._

## Features

- common features:
  - draw in the fullscreen mode;
  - quit by Escape key;
- drawing of the background:
  - use [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway's_Game_of_Life) as a background:
    - use the naive algorithm with iterating and copying of a whole field;
    - ignore outside points;
    - support for a start delay for populating;
  - automatic horizontal and vertical centering;
- drawing of the logo (optionally):
  - automatic horizontal and vertical centering;
  - fade in and out:
    - support for a start delay for fading in;
    - quit at the finish of the fading out;
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

## Running

See for details: <https://love2d.org/wiki/Getting_Started#Running_Games>

### On the Android

Clone this repository:

```
$ git clone https://github.com/thewizardplusplus/wizard-intro.git
$ cd wizard-intro
```

Make a ZIP archive containing it:

```
$ git archive --format zip --output wizard_intro.zip HEAD
```

Change its extension from `.zip` to `.love`:

```
$ mv wizard_intro.zip wizard_intro.love
```

Transfer the resulting file to the Android device.

Open it with the [LÖVE for Android](https://play.google.com/store/apps/details?id=org.love2d.android) app.

### On the PC

Clone this repository:

```
$ git clone https://github.com/thewizardplusplus/wizard-intro.git
$ cd wizard-intro
```

Then run the game with the [LÖVE](https://love2d.org/) engine:

```
$ love .
```

## License

GPL-3.0-or-later

Copyright &copy; 2024 thewizardplusplus
