# Wizard Intro

The demo to generate intros for my YouTube channel.

I came up with an intro for my videos, but my video editing experience wasn't enough to realize what I had in mind. So I decided to write a demo to render this intro and then use screen capture.

_**Disclaimer:** this demo was written directly on an Android smartphone with the [QLua](https://play.google.com/store/apps/details?id=com.quseit.qlua5pro2) IDE and the [LÖVE for Android](https://play.google.com/store/apps/details?id=org.love2d.android) app._

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
