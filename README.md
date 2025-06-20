# EE 110 GOREPCB Wireless Robot Test-Board

Welcome to the project and demo collection for my EE 110c final project **GOREPCB**: a prototype test board that brings together all the electronics needed for a **wirelessly-controlled servo robot**.  Each demo in this repository is a self-contained **Code Composer Studio (CCS) workspace** you can import, build, and flash onto the board through the 10-pin JTAG header. This repository also includes all design files and documentation required to recreate the project.

---

## Board Capabilities at a Glance

* **Multi-source power**: 7 .2 V, 5 V, 3 .3 V rails selectable from **AC** or **Li-ion battery** (with supervisors & backup).
* **TI CC2652R1** microcontroller: 48 MHz + 32 kHz crystals, BLE-5 ready, watchdog-friendly reset network.
* **High-current servo channel** (7 .2 V) with feedback & fuse protection.
* **5 V mixed-signal peripherals**: 2×16 LCD, 4×4 LED keypad, audio codec (speaker + mic).
* **3 .3 V SPI peripherals**: IMU & micro-SD card.
* **RF front-end**: on-board balun, matching network, selectable PCB or external antenna (MF4).
* **Full test-point coverage** & 100 % schematic / PCB sources in `/Hardware`.

> For detailed schematics, PCB layout, and block diagrams see **`docs/GOREPCB_User_Manual.pdf`** or view them directly from the hardware design files.

---

## Repository Layout

```
EE110/
├─ Demos/           # CSS Project Demos
│  ├─ GOREPCB/          # Demos designed for the GOREPCB
│  |  ├─ GOREPCB_Keypad/    # Keypad demo
│  |  ├─ GOREPCB_LCD/       # ⏳ coming soon
│  |  ├─ GOREPCB_Servo/     # ⏳ coming soon
│  |  ├─ GOREPCB_Audio/     # ⏳ coming soon
│  |  ├─ GOREPCB_BLE/       # ⏳ coming soon
│  |  └─ GOREPCB_FullSystem/# ⏳ coming soon
│  └─ WireWrap/         # Demos designed for tbe wire wrapped prototype
├─ Hardware/        # Altium files, Gerber/NC ZIP, BOM, production outputs
│  ├─ Altium/           # Altium Designer schematic + PCB project
│  ├─ Production Files/ # Gerbers, NC drills (ZIP)
│     └─ GOREPCB_Rev3_DFM2.zip
│  └─ BOM/              # BOM CSV with Digi-Key references
│     └─ EE110 GOREPCB BOM.csv
├─ Docs/                # Final documentation report, user manual
│  └─ Final_Report_EE110.pdf
└─ README.md
```

Feel free to clone the repo now as more demos will be added as they are finished.

---

## Getting Started

1. **Prerequisites**

   * *Hardware*: The test board assembled per the hardware files, a 10-pin JTAG probe, and the external peripherals you want to test.
   * *Software*: [Code Composer Studio](https://www.ti.com/tool/CCSTUDIO) 12 or newer (Windows/Linux/macOS).
2. **Clone the repo**

   ```bash
   git clone https://github.com/GeorgeOre/EE110-Demos.git
   cd EE110-Demos
   ```
3. **Import a demo**

   * In CCS choose **File → Import → Existing CCS Project…**  ➜  Browse to the desired `*-demo` folder ➜ Finish.
4. **Build & Flash**

   * Connect the JTAG probe, power the board, click the **Debug** button, then **Run**.

---

## Available Demos

| Demo            | Status         | What it Shows                                                                                             |
| --------------- | -------------- | --------------------------------------------------------------------------------------------------------- |
| **Keypad**      | Ready          | Scans the 4×4 keypad with interrupt-driven GPIO and logs key presses into a circular buffer.              |
| **LCD**         | In progress    | Drives the 2×16 HD44780 module in 8-bit mode; scrolls text and custom characters.                         |
| **Servo**       | In progress    | Generates PWM to sweep the modified servo; reads the feedback pot and echoes the angle on the LCD.        |
| **Audio**       | In progress    | Streams a WAV clip (“Diamonds” by Rihanna) through the on-board amplifier; includes volume pot demo.      |
| **BLE**         | In progress    | Exposes BLE characteristics for remote control & telemetry via smartphone app.                            |
| **Full System** | In progress    | Glues everything together: keypad → command, LCD → status, BLE → remote, servo → actuation, SD → logging. |

A short README in each demo folder explains the build and run procedure plus any jumper settings.

---

## Hardware Files

You’ll find all fabrication and design files under [`Hardware/`](hardware/):

* `Altium/` – Complete Altium Designer project for schematic & PCB layout
* `Production Files/` – `GOREPCB_Rev3_DFM2.zip` with Gerbers and NC drill for fab upload
* `BOM/` – `EE110 GOREPCB BOM.csv` for Digi-Key with reference designators and part numbers

These files are sufficient for fabricating and assembling your own board using vendors like JLCPCB.

---

## Roadmap / Future Enhancements

* Split the board into separate **Servo Power** and **Control** PCBs.
* Add multi-servo arbitration & high-side current sensing.

---

Made with best efforts by **George Ore**
