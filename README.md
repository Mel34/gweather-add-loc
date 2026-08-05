# 🌤️ gweather-add-loc

A simple, standalone Bash script to add custom locations with arbitrary coordinates to **GNOME Weather** (`org.gnome.Weather`) via `gsettings`.

Works with **GNOME 40+ / libgweather-4**.

## 📌 Prerequisites

The script requires `bc` for floating-point calculations:

* **Fedora:** `sudo dnf install bc`
* **Debian/Ubuntu:** `sudo apt install bc`
* **Arch Linux:** `sudo pacman -S bc`

## 🚀 Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/crian/gweather-add-loc.git
cd gweather-add-loc
chmod +x gweather-add-loc.sh
```

## ⚙️ Usage

```bash
./gweather-add-loc.sh "Location Name" LATITUDE LONGITUDE
```

### 💡 Examples

Add Berlin:
```bash
./gweather-add-loc.sh "Berlin" 52.5200 13.4050
```

The script automatically converts the coordinates to radians, formats the `libgweather-4` GVariant string, updates `gsettings`, and restarts `gnome-weather` to apply the changes.

## 📄 License

[MIT](LICENSE)
