# VLC Folder Playlist Loader & Navigation

A VLC extension that automatically loads all media files from the current folder into the playlist while maintaining playback of the initially opened file. Provides seamless navigation through folder contents.



## Features

- **Automatic Playlist Population**: Loads all supported media files from the current folder
- **Smart Initialization**: Keeps focus on the initially opened file
- **Navigation Controls**:
  - Play next/previous file in folder
  - Wrap-around at beginning/end of playlist
  - Media key support (for keyboards with dedicated media keys)
- **Wide Format Support**: Works with video and audio files (MP4, MKV, AVI, MP3, FLAC, etc.)
- **Cross-Platform**: Works on Windows, Linux, and macOS

## Installation

1. **Download** the latest `.lua` file from the [Releases](https://github.com/asdman011/vlc-folder-playlist/releases) section
2. **Place** the file in VLC's extensions folder:
   - **Windows**: `%APPDATA%\vlc\lua\extensions\`
   - **Linux**: `~/.local/share/vlc/lua/extensions/`
   - **macOS**: `/Users/yourusername/Library/Application Support/org.videolan.vlc/lua/extensions/`
3. **Restart** VLC

## Usage

1. Open any media file in VLC
2. Activate the extension:
   - Go to `View` > `Folder Playlist Loader`
   - Alternatively, use the extension manager in VLC's preferences

**Navigation Commands**:
- `View` > `Folder Playlist Loader` > `Play Next in Folder`
- `View` > `Folder Playlist Loader` > `Play Previous in Folder`
- **Keyboard Shortcuts**: You can set custom shortcuts in VLC's Hotkeys preferences

## Supported File Formats

All common media formats are supported, including:

**Video Formats**:
- MP4, MKV, AVI, MOV, WMV, MPEG, MPG, FLV, WebM, 3GP

**Audio Formats**:
- MP3, WAV, FLAC, AAC, OGG, WMA, ALAC, APE, OPUS

*(Full list in the source code)*

## Troubleshooting

**Extension not appearing in VLC?**
- Verify the file is in the correct extensions folder
- Check VLC's version (works with VLC 3.0 and newer)
- Look for error messages in VLC's Messages window (set verbosity to 2)

**Playlist not loading?**
- Ensure you have read permissions for the folder
- Check that files have standard extensions

## Building/Modifying

To modify the extension:
1. Edit the `.lua` file with any text editor
2. Test changes by placing in your extensions folder
3. Reload extensions in VLC with `View` > `Reload extensions` or restart VLC

## License

[GNU General Public License v3.0](LICENSE)

## Contributing

Contributions are welcome! Please open an issue or pull request for any:
- Bug fixes
- New features
- Documentation improvements

---

**Enjoy seamless folder playback in VLC!** 🎥🔊
