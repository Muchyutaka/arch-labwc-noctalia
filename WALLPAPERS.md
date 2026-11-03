# Wallpapers

This repo ships no image files. `scripts/fetch-wallpapers.sh` downloads five
photos from [Unsplash](https://unsplash.com/) into
`~/Pictures/Wallpapers/free-use/` when you run it.

## Licence

The photos are used under the [Unsplash License](https://unsplash.com/license):
free to download and use for personal or commercial purposes, with no
permission or attribution required. Attribution is appreciated but not
obligatory.

Unsplash is the source; the files are not redistributed by this repository.

## The five photos

| File | Subject | Photo |
|---|---|---|
| `01-milky-way-peaks.jpg` | Snowy peaks under the Milky Way | <https://images.unsplash.com/photo-1519681393784-d120267933ba> |
| `02-valley-mist.jpg` | Cloud spilling over a green escarpment at sunrise | <https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05> |
| `03-forest-sunlight.jpg` | Sunlight filtering through a dense forest | <https://images.unsplash.com/photo-1441974231531-c6227db76b6e> |
| `04-sea-of-clouds.jpg` | Snow-dusted peaks above a sea of cloud at sunset | <https://images.unsplash.com/photo-1506905925346-21bda4d32df4> |
| `05-glacier-valley.jpg` | Glacier valley between snowy mountains | <https://images.unsplash.com/photo-1464822759023-fed622ff2c3b> |

Each is downloaded as a 1920 px JPEG from `images.unsplash.com`.

## Getting them

```bash
./scripts/fetch-wallpapers.sh          # download missing files
./scripts/fetch-wallpapers.sh --force  # re-download all five
./scripts/fetch-wallpapers.sh --dir ~/Pictures/Wallpapers   # custom folder
```

The script also copies this file to `CREDITS.md` in the wallpaper folder. With
the default `free-use/` folder, Noctalia's picker stays on
`~/Pictures/Wallpapers` so your own images remain visible.

## Switching

- `Super+w` opens the wallpaper picker, which browses `~/Pictures/Wallpapers`
- `Super+Shift+w` switches to the next wallpaper, including those in `free-use/`
- `Super+Alt+w` adds your own image through a file picker
- The wallpaper icon in the bar opens the same picker
- `noctalia msg wallpaper-set /path/to/image.jpg` sets an exact file
- `noctalia msg wallpaper-next`, `wallpaper-previous`, or `wallpaper-random`

Drop your own images into `~/Pictures/Wallpapers` and they appear in the
picker alongside the downloaded set.

Noctalia derives the whole palette from the active wallpaper, so the bar and
panels recolour as soon as you switch.
