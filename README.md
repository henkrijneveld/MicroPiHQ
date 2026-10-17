[English](README.md) | [Nederlands](README.nl.md)

# MicroPiHQ

A package for using the Raspberry Pi HQ Camera with a Raspberry Pi, specifically for microscopy or macro photography. This is a new version of Microscope-Picam, now based on libcamera and Picamera2. The goal is to take and save photographs. Video is supported for the preview, but not for recording.

<a href="pictures/scherm-1.jpg">
  <img src="pictures/scherm-1.jpg" width="650" alt="Camera interface">
</a>

*The user interface*

# Technical

The Pi and camera are connected via C-mount to the microscope's reduction lens or an objective. Communication is over Wi-Fi. The Pi only needs a power cable. The software works from the Pi 3B onwards; operation has actually been tested on the Pi 3B+ and Pi 4. A small web server runs on the Pi so that the camera can be controlled through a browser on the network. The software is intended for local use only, so there is no access protection. Anyone who can reach the Pi over the network can use the software.

The easiest way to access the files on the Pi is through an SFTP connection. Of course, it is also possible to enable the Pi's desktop. The terminal can be used as well.

<a href="pictures/verbinding.jpg">
  <img src="pictures/verbinding.jpg" width="650" alt="Camera mount">
</a>

*The C-mount connection to the reduction lens. The standard acrylic plate was used so that the camera and Pi form a single unit.*

# Installation

Installation assumes that the latest version of Trixie has been installed on the SD card. This can be either the Lite version or the desktop version, although the latter quickly becomes rather demanding for a Pi 3B+. The HQ Camera must also be connected and tested with rpicam-still.

Download the ZIP file (MicroPiHQ.zip) from the latest release (in the right-hand column on GitHub), extract it into a directory on the Pi, and run the *install.sh* script. The installation is checked at the end. If you encounter problems, run *check-installation.sh*, which checks that all required components are available.

Photographs are stored in the photos directory inside the installation. I have deliberately not made this configurable, to keep things as straightforward as possible.

*The camera can be accessed at: http://address-of-the-Pi:8000*

The device accessing the camera must be able to reach the Pi on port 8000.

The installation script installs a service so that the web server starts when the Pi boots. If this is not wanted, it can be disabled with *disable-autostart.sh* and enabled again with *enable-autostart.sh*. There are also start and stop scripts for starting and stopping the web server separately.

Before removing the software, first run *uninstall.sh*. The directory can then be deleted. Software packages installed during installation are not removed by *uninstall.sh*.

To upgrade, download the new version, extract it over the existing installation, and run the installation script again.

**Note for older installations:** the ZIP now contains a `MicroPiHQ/` directory. If your current installation has a different directory name, copy the contents of `MicroPiHQ/` into your existing installation directory and run `./install.sh` there. This preserves the existing `photos/` directory and `.env.local` configuration. `install.sh` also replaces the previous systemd service with `micropihq.service` and removes the obsolete shutdown helper.

# Features

Regular photographs

Standard bracketed exposures: either three frames at -1.5 EV, 0 and +1.5 EV, or five frames at -3 EV, -1.5 EV, 0, +1.5 EV and +3 EV. The step size can be changed in .env.local.

Manual focus stacks. Once enabled, the frame number increases automatically after every shot, while the YYMMDD-HHMMSS part of the filename remains the same for all frames.

Manual entry of Field of View

Automatic exposure (with or without compensation) in two modes: either both the analogue gain and shutter speed vary automatically, or only the shutter speed varies while analogue gain stays at its minimum (1×). The latter reduces noise. There is also a manual mode. At 15 fps, the preview cannot use shutter speeds longer than 66 ms. Select 5 fps for longer shutter speeds in the preview. Currently, automatic exposure in the preview is limited to a maximum shutter speed of 120 ms.

Saturation adjustment

Histogram

White balance can be automatic or manual. Experience shows that manual white balance is almost always needed for microscopy. The SetWB button equalises the intensities of green, red and blue. Place a white surface in front of the camera to establish the correct white balance.

Liveview: in addition to the Camera tab, there is a Liveview tab showing the live microscope image.

At the top left there is a Files tab. This is a very basic file browser for downloading image files. The software assumes that the photos directory will normally be accessed through a terminal or SFTP. SFTP requires SSH to be enabled on the Pi.

There is also a Last Photo tab, showing all images / brackets from the most recent shot to give an impression of the result.

Finally, the "Stop Pi" tab sends the Pi a shutdown signal, disconnecting the camera.

At the top right there is a language selector: NL or EN.

<a href="pictures/scherm-3.jpg">
  <img src="pictures/scherm-3.jpg" width="650" alt="Camera tab">
</a>

*The tab showing the most recently taken photographs*

# Filenames

Since many files are generated, the naming scheme is strict.

## Single captures

Filename: YYMMDD-HHMMSS-[entered name].jpg

## Bracket files (HDR)

Filename: YYMMDD-HHMMSS-[entered name]-AEB-[stops].jpg

<a href="pictures/dynosaurus.jpg">
  <img src="pictures/dynosaurus.jpg" width="650" alt="Dinosaur bone">
</a>

*Photograph of a dinosaur bone*

## Stacking frames

Filename: YYMMDD-HHMMSS-[frame number]-[entered name]-[AEB-[stops]].jpg

# Processing files

For the best results, photographs will usually need to be post-processed individually. A script called "mertens.sh" is included in the photos directory. It uses default settings to generate an initial processed set of photographs. Usage: ./mertens.sh YYMMDD-HHMMSS. AEB brackets are processed using enfuse and magick. This generates YYMMDD-HHMMSS-[entered name].jpg, as well as a .tif file for possible further processing and a contrast-enhanced file, YYMMDD-HHMMSS-[entered name]-contrast.jpg. The last one can sometimes cause substantial colour shifts, although sometimes it works out perfectly.

For stacking frames, a directory named YYMMDD-HHMMSS-focusstack is created. A .tif file is generated for each frame if brackets were used, or a .jpg file for single photographs. These files can then be processed in focus-stacking software.

To process every set in a directory, use *mertensall.sh*. Run `./mertensall.sh` from the photos directory, or specify a different directory with `./mertensall.sh /path/to/photos`. The script finds every unique YYMMDD-HHMMSS series containing AEB brackets or focus-stack frames and calls *mertens.sh* once per series. Ordinary single photographs are skipped. Running it again regenerates the processed results; the original photographs are preserved.

# Points to note

## Preview resolution

The preview defaults to high resolution (1280 × 960). If the network experiences delays, the preview can be switched to low resolution (640 × 480).

## Exposure

The Pi has two exposure settings: shutter speed in milliseconds and analogue gain as a multiplication factor. The least noise occurs with the lowest possible analogue gain: 1×. Since microscope subjects generally do not move, longer exposures are not a problem. In practice, it is best to start with fully automatic exposure, then switch to Auto 1×. The shutter speed may then reach its maximum limit, leaving the image too dark. If that happens, select 5 frames per second. The shutter speed can then increase to a maximum of 120 ms. Still too dark? Switch to manual exposure and set the shutter speed yourself. Of course, fully automatic exposure can also be used throughout, but noise may increase. be aware of the settling of the camera as explained below.

## Field of view

MicroPiHQ uses this value only to record the field of view as a parameter in the EXIF metadata. The *mertens.sh* script also copies it to the generated images.

## White balance

White balance is best set by placing a white surface in front of the camera, using the same lighting and exposure as for the photographs. Then click SetWB. White balance switches to manual. Usually the image will not be completely white yet. Use the fine adjustment for blue and red to bring all three colour curves together in the histogram.

## Camera settling after changes

After changing exposure, white balance or saturation, the Pi sometimes needs a few seconds to settle into the new settings. Just give it time. This is especially true with the Auto 1x setting or a manual setting with low gain. Just let the Pi do its thing! 

# GitHub pull requests and issues

Issues can be submitted. They are handled on an irregular basis.

I do not accept pull requests. In this age of AI, I resolve issues myself to retain control. After all, this software opens a web server somewhere on a network, which means I would need to review every pull request to make sure it does not contain a backdoor. Usually that will not be the case. So, if there is a problem, please submit an issue.

**License:** [GNU AGPL v3](LICENSE). External code contributions and pull requests are not accepted.

# Background

I am a gemologist and a software developer. Because I have several microscopes, I was looking for a way to equip each of them with a lightweight camera. Support for HDR and focus stacks was also essential. The Pi + HQ hardware is (was?) cheaper, more flexible and lighter than a DSLR. Since I have four Pi/HQ setups, each microscope has its own permanent installation. I could not find a package for the Pi that offered the features I wanted. Five years ago I built something similar, but its drivers are no longer supported by the new OS. In 2021 I programmed everything myself; this 2026 package was vibe-coded in enjoyable collaboration with ChatGPT 5.6 Sol.

## Effect of HDR

<a href="pictures/hanger-tektiet-contrast.jpg">
  <img src="pictures/hanger-tektiet-contrast.jpg" width="650" alt="Tektite pendant">
</a>

*Photograph of tektite based on five bracketed exposures*

<a href="pictures/hanger-tektiet-AEB-0.jpg">
  <img src="pictures/hanger-tektiet-AEB-0.jpg" width="650" alt="Tektite pendant">
</a>

*The same photograph, but as a single exposure. Much less detail is visible in the dark areas.*

## Effect of HDR and stacking

The effect can be subtle, but the stacked HDR version shows more detail and sharpness than the single photograph.
This is particularly noticeable in the front twig, the detail in the hinge, and the soldering. It makes the difference between an OK-ish image and one that shows everything clearly in a single view. The photograph shows a detail of a brooch with four kinds of joints: gold solder, lead-tin solder, glue and a riveted joint.

<a href="pictures/takje-lood-goud.jpg">
  <img src="pictures/takje-lood-goud.jpg" width="650" alt="Brooch detail">
</a>

*The stacked HDR version*

<a href="pictures/takje-lood-goud-geenstack-geenHDR.jpg">
  <img src="pictures/takje-lood-goud-geenstack-geenHDR.jpg" width="650" alt="Brooch detail">
</a>

*A single photograph focused on the middle.*

> [!NOTE]
> This README is automatically translated from the original Dutch version, [README.nl.md](README.nl.md). The Dutch version is the source document.
