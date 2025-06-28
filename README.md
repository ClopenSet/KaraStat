# KaraStat

**KaraStat: A Pure, Headless, and Precise Keyboard Statistics Logger for macOS.**

KaraStat is a minimalist, background-only utility that meticulously tracks your keyboard activity with a headless **Karabiner-Elements**. It records the press count for every physical key, storing all data locally in a private SQLite database. Designed for developers, data enthusiasts, and anyone curious about their keyboard usage patterns, KaraStat operates silently in the background without any GUI, menu bar icons, or unnecessary distractions. Then, one day, when curiosity strikes, you can look back and see a complete, uninterrupted history of your work, one keystroke at a time. There is no better way to capture the sheer volume of your digital craftsmanship over a long period.

---

## Key Features

- **Precision**: Leveraging the powerful low-level event observation engine from the renowned **Karabiner-Elements**, KaraStat achieves a level of accuracy that surpasses many other tools. It correctly identifies and counts every physical key, including function keys (`F1`-`F12`), the `Fn` key, and accurately handles a complex key `CapsLock`.
- **Truly Headless**: KaraStat runs as a pure background service (`launchd` agent). There is no graphical user interface, no menu bar icon, and no intrusive pop-ups. It is designed to be completely invisible and resource-efficient. It is engineered to run reliably for months or even years, allowing you to almost forget it exists. 

- **Local & Private**: All your keyboard data is stored locally on your machine in a simple SQLite database. KaraStat does not connect to the internet or transmit your data anywhere. Your keystrokes are your own.
- **Extensible Core**: While the current version focuses on simple key press counts, the underlying `libkrbn` engine is incredibly standalone and powerful. The project is easily extensible to track more complex events, such as shortcut combinations (`Cmd+C`, `Cmd+V`), application-specific key usage, and more.

## Architecture & Acknowledgment

KaraStat was born out of a deep respect for the **Karabiner-Elements** project and a desire for a minimalist keylogging tool without the key-remapping features or GUI.

The architecture of KaraStat is straightforward:
1.  A lightweight, self-contained version of Karabiner's core library, `libkrbn`, was extracted. This **Karabiner-Lite** submodule strips away the GUI and modification capabilities, focusing solely on its powerful event-capturing side effect.
2.  A Swift-based command-line application, **KaraStat**, serves as the host for `libkrbn`. It initializes the library, listens for keyboard events via callbacks, and writes the data to a local SQLite database.

**The incredible precision of this tool is not our achievement, but a direct result of the brilliant engineering within Karabiner-Elements.** We have simply repackaged its powerful engine for a different purpose. The potential to extend KaraStat to any level of detail (e.g., tracking specific shortcuts) is entirely thanks to the robust foundation provided by Karabiner.

## Installation & Usage

KaraStat is available via Homebrew.

1.  **Tap the repository:**
    ```bash
    brew tap clopenset/harbour
    ```

2.  **Install KaraStat:**
    ```bash
    brew install karastat
    ```

### Running the Service

To begin using KaraStat, you must start it as a background service:
```bash
brew services start karastat
```

**‼️ IMPORTANT: macOS Permissions ‼️**

The first time you launch the service, macOS will prompt you to grant "Input Monitoring" access. This is a mandatory security step for any application that needs to observe keyboard input.

1.  Please approve this request in **System Settings > Privacy & Security > Input Monitoring**.
2.  After granting the permission, you **must restart the service** for the change to take effect:
    ```bash
    brew services restart karastat
    ```

Once enabled, KaraStat will begin tracking your keypresses silently.

### Accessing Your Data

Your keyboard statistics are stored in a SQLite database file located at:
`~/Library/Application Support/karastat/key_stats.sqlite`

You can query this file with any SQLite client to analyze your data.

## License

The vast majority of the code in this project originates directly from Karabiner-Elements. In honor of their work and their contribution to the open-source community, KaraStat is also released under the **Unlicense**, following their lead. 
