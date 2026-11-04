# Chessmate

A chess coach for your own games: it imports them from Lichess and Chess.com, finds the moments worth reviewing with Stockfish, and walks you through them with questions before showing you the engine's view.

## Installation

Download the zip for your system from the [releases page](https://github.com/guillep/chess-coach/releases): `Chessmate-macOS.zip` or `Chessmate-Windows.zip`.

### macOS

1. Unzip `Chessmate-macOS.zip` and move `Chessmate.app` to `Applications`.
2. Remove the quarantine flag. Chessmate is not notarized by Apple, so macOS marks the downloaded app as quarantined and refuses to open it, saying it is damaged or comes from an unidentified developer. In Terminal:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Chessmate.app
   ```

   `-r` clears the flag on every file inside the app, which matters: the app contains its own Pharo virtual machine and libraries, and each one would be blocked otherwise. If you keep the app somewhere else, use that path instead.
3. Open Chessmate from `Applications`.

If macOS still says the app can't be opened, check that the flag is gone (`xattr -lr /Applications/Chessmate.app` should print no `com.apple.quarantine` line), then open it once with right-click > Open.

### Windows

1. Unzip `Chessmate-Windows.zip` into a folder of your choice (for example `C:\Program Files\Chessmate`).
2. Run Chessmate's executable in that folder. Windows SmartScreen may warn about an unrecognised app: choose **More info**, then **Run anyway**.

### Stockfish (needed to find mistakes)

Chessmate uses [Stockfish](https://stockfishchess.org/download/) to analyse the games you review. Without it, the coach only works with the moves you mark yourself.

- macOS: `brew install stockfish`. Chessmate looks for it in `/opt/homebrew/bin/stockfish` by default.
- Windows: download Stockfish and note where `stockfish.exe` is.

If Stockfish is somewhere else, set its path in **Settings > Analysis** and press **Test**.

### Ollama (optional)

The coach can sort your written answers into mistake types with a local model run by [Ollama](https://ollama.com). It is optional: without it, you choose the tags yourself.

```bash
ollama pull qwen2.5:7b-instruct
```

Then in **Settings > Coach (local LLM)**, press **Load models** and pick the model. Other models work, but this is the one Chessmate is validated with.

## First run

The setup wizard asks for your Lichess and/or Chess.com username: your games are public, so a username is enough to download them. Logging in to Lichess is optional and only adds the opening statistics of its database.

Chessmate keeps its data (games, analyses, reviews, settings and `errors.log`) in `~/.chess-coach`.

## Updates

Chessmate checks for new releases and shows **Update** in its title bar when one exists; updating closes the window and opens it again. On macOS, a new version downloaded by hand needs the quarantine flag removed again (step 2 above).

## Building

`packaging/build-macos.sh` and `packaging/build-windows.sh` build the release zips from a fresh Pharo 13 image (`RUN_TESTS=1` also runs the tests). The macOS build is signed ad hoc, not notarized, which is why the quarantine flag has to be removed.
