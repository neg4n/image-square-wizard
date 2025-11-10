


https://github.com/user-attachments/assets/c9a5fca3-eff5-4efd-a837-e5e621018e7d


# image-square-wizard

**isw** _(image square wizard)_ pads rectangular or panoramic images to a square canvas using [`libvips`][libvips]. It
measures the dominant colour (or accepts a user-provided colour / transparent
fill) and expands the image evenly on each side.

## Features

- Fast. Built in C.
- JPEG, PNG, WebP, HEIF/HEIC, TIFF, AVIF support out of the box.
- Only one command. Specify input & output along with extensions and thats it.
- Automatic detection of aspect ratio.
- Probing of the dominant color of the image to be used for padding (by default).
- Customization options, e.g. provide your own colors.

### Prerequisites

- [`libvips`][libvips] 8.12 – 8.18 (tested with 8.17.2). Install via your package manager,
  e.g. `brew install vips` on macOS or `apt install libvips-dev` on Debian/Ubuntu.
- Meson (>= 1.1) and Ninja for the build.
- A C11 toolchain (e.g. clang or gcc) with pkg-config.

### Build Steps

1. Clone the repository: `git clone https://github.com/neg4n/image-square-wizard isw && cd isw`
2. Configure the build directory: `meson setup build`
3. Compile: `meson compile -C build`

### Installation

Run `meson install -C build` inside the repository's root in order to install the `isw` binary and man page. Adjust
`DESTDIR` or `--prefix` during `meson setup` if you need a custom location.

### Usage

Run `isw input.jpg output.png` or inspect options with `isw --help` or `man isw`.

## License

MIT

[libvips]: https://github.com/libvips/libvips
