# Third-party notices

The experimental package contains two programs (`persist-bak.jar`, `persist-asm.jar`). Each one bundles the
smali/baksmali libraries and their dependencies, converted to dex. Those libraries are not ours:

| Component | Used for | License | Project |
|---|---|---|---|
| smali, baksmali, dexlib2 (version 2.5.2) | assembling and disassembling the app's dex | BSD 3-Clause | https://github.com/JesusFreke/smali |
| Guava | collections used by smali and dexlib2 | Apache License 2.0 | https://github.com/google/guava |
| ANTLR 3 runtime | the smali parser | BSD 3-Clause | https://www.antlr3.org |
| JCommander | the smali and baksmali command-line parsers (bundled; never run on the head unit) | Apache License 2.0 | https://jcommander.org |

The original license texts are in those projects' repositories. Our own code in this repository is MIT licensed
(see `LICENSE` at the repository root).

This package does not contain any Hyundai or Kia software. It reads the head unit's own copy of the settings app
on the head unit and builds the changed copy there.
