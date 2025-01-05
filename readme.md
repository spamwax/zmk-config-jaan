<!-- <picture>
  <source media="(prefers-color-scheme: dark)" srcset="/docs/images/TOTEM_logo_dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="/docs/images/TOTEM_logo_bright.svg">
  <img alt="TOTEM logo font" src="/docs/images/TOTEM_logo_bright.svg">
</picture> -->

# ZMK CONFIG FOR THE JAAN SPLIT KEYBOARD

[Here](https://github.com/spamwax/jaan) you can find the hardware files and build guide.\

Jaan is a 48 key column-staggered, column-fanned, column-welled(?!) split keyboard running [ZMK](https://zmk.dev/). It's meant to be used with a nice!nano.

<!-- ![TOTEM layout](/docs/images/TOTEM_layout.svg) -->

## HOW TO USE

- fork this repo
- `git clone` your repo, to create a local copy on your PC (you can use the [command line](https://www.atlassian.com/git/tutorials) or [github desktop](https://desktop.github.com/))
- adjust the jaan.keymap file (find all the keycodes on [the zmk docs pages](https://zmk.dev/docs/codes/))
- `git push` your repo to your fork
- on the GitHub page of your fork navigate to "Actions"
- scroll down and unzip the `firmware.zip` archive that contains the latest firmware
- connect the left half of the Jaan to your PC, press reset twice
- the keyboard should now appear as a mass storage device
- drag'n'drop the `jaan_left-nice_nano_v2-zmk.uf2` file from the archive onto the storage device
- repeat this process with the right half and the `jaan_right-nice_nano_v2-zmk.uf2` file.