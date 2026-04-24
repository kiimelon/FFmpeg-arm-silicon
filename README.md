## What this project does

This repository provides prebuilt `ffmpeg`, `ffprobe`, and `ffplay` binaries for Apple Silicon macOS.

It is useful when you need to bundle these tools inside a macOS app.

Most users can download [FFmpeg-arm-silicon-Tools-20260424.zip](https://github.com/kiimelon/FFmpeg-arm-silicon/releases/tag/0.5.0) from Releases.

If you want to rebuild the tools from source, follow the steps in the `Quick start` section below.

## Quick start 
1. Open Terminal.

2. Install required build tools:

```bash
brew install cmake meson ninja autoconf automake libtool pkg-config
```

3. Clone the repository: 

```bash 
git clone https://github.com/kiimelon/FFmpeg-arm-silicon.git  
```

4. Enter the project directory: 

```bash 
cd FFmpeg-arm-silicon
```

5. Run the full build pipeline:  

```bash 
bash scripts/build-all-static.sh 
```
This command runs:
- Stage 1: Fetching dependency sources
- Stage 2: Building static dependencies
- Stage 3: Building FFmpeg suite
- Stage 4: Verifying static suite
- Stage 5: Exporting FFmpeg tools
- When the build finishes, the exported tools will be available at: `Tools`

## Using the binaries in a macOS app

After building, copy or drag the `Tools` folder into your Xcode project.

In Swift, you can locate a tool like this:

```swift
guard let ffmpegPath = Bundle.main.path(
    forResource: "ffmpeg",
    ofType: nil,
    inDirectory: "Tools"
) else {
    fatalError("ffmpeg not found in Tools")
}
```


## Dependency Groups (currently)

| Group | Libraries * |
|---|---|
| Support libs | `zlib`, `bzip2`, `brotli`, `snappy` |
| Audio chain | `libogg`, `opus`, `libvorbis`, `lame`, `twolame`, `libsoxr` |
| Video chain | `dav1d`, `x264`, `x265`, `libvpx`, `libtheora` |
| Subtitle chain | `freetype`, `fribidi`, `harfbuzz`, `libass` |
| Image / video processing chain | `libwebp`, `openjpeg`, `zimg` |
| Utility / integration libs | `libxml2`, `libzmq` |
| Player / UI | `sdl2` |

\* Third-party libraries fetched by the build scripts keep their own licenses.

## Planned Dependency Expansion

| Library | Purpose |
|---|---|
| `aom` | AV1 encoding support |
| `vmaf` | Video quality analysis |
| `xvid` | MPEG-4 Part 2 encoding support |
| `speex` | Speech codec support |
| `gsm` | GSM audio codec support |
| `opencore-amr` | AMR-NB / AMR-WB support |
| `vo-amrwbenc` | AMR-WB encoder support |
| `shine` | Lightweight MP3 encoder |
| `rubberband` | Time-stretching and pitch-shifting |
| `mysofa` | HRTF / spatial audio filter support |
| `modplug` | Tracker module format support |
| `bluray` | Blu-ray structure reading support |
| `zvbi` | Teletext / VBI support |
| `fontconfig` | Font discovery for subtitle rendering |
| `vidstab` | Video stabilization filters |
| `openh264` | H.264 codec support |
| `xavs` | AVS video codec support |
| `avisynth` | Avisynth input support |