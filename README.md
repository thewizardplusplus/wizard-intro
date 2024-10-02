# Wizard Intro

[![lint](https://github.com/thewizardplusplus/wizard-intro/actions/workflows/lint.yaml/badge.svg)](https://github.com/thewizardplusplus/wizard-intro/actions/workflows/lint.yaml)

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
- drawing of the logo (optionally):
  - automatic horizontal and vertical centering;
  - fade in and out:
    - support for a start delay for fading in;
    - quit at the finish of the fading out;
    - play the sounds during the animation (optionally):
      - play the foreground sound during the fading in;
      - play the background sound during the fading in and out;
- drawing of the text rectangles (optionally):
  - automatic horizontal and vertical centering;
  - align text in the rectangles to the center;
  - automatic text splitting into lines:
    - each line contains as many words as possible;
    - select the largest possible font size to fit the text on the screen;
  - animations:
    - animation of appearing from behind the edge of the screen;
    - animation of letter-by-letter typing;
    - common features:
      - all animations run sequentially one after the other;
      - support for a start delay for animation;
      - quit at the finish of the animation;
      - play the separate sound during each animation (optionally);
- automatic screencast:
  - use the [ffmpeg](https://www.ffmpeg.org/) tool;
  - support for Linux only;
  - capture video:
    - with the [X.Org](https://www.x.org/);
  - capture audio (optionally):
    - with the [ALSA](https://www.alsa-project.org/);
    - with the [PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio/);
  - postprocessing:
    - automatic waiting for the finish of the [ffmpeg](https://www.ffmpeg.org/) tool;
    - automatic trimming screencast allowances (optionally);
- menu and settings:
  - main menu allows to choose between the general drawing modes (see above);
  - background settings allow to choose between the background drawing modes (see above);
  - text rectangle settings allow to set the text to be displayed;
  - misc. settings allow to choose:
    - between the silent and full-sounding modes;
    - whether or not to trim videos automatically.

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
