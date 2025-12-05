# Installing Firefox for testing

- On Ubuntu 22.04 and above, Firefox is a Snap package. After installing, run `sudo ln -s /snap/bin/firefox.geckodriver /usr/local/bin` to link to the snap geckodriver
- On Flatpak installed Firefox, see: <https://firefox-source-docs.mozilla.org/testing/geckodriver/Usage.html#Running-Firefox-in-an-container-based-package>
- On locally installed Firefox, install geckodriver from the standard releases: <https://github.com/mozilla/geckodriver/releases> - then run the script below

**Firefox 135-137 do not appear to work correctly. `esr/stable` currently provides version 128, which is a working fallback.**

**For Snap:**

```bash
snap info firefox
# shows esr/stable as 128.x
snap refresh firefox --channel=esr/stable
```

**For locally installed Firefox, install geckodriver using the script below**

```bash
### Only run this if not using Snap or Flatpak
GVER=0.36.0
GECKODRIVER="https://github.com/mozilla/geckodriver/releases/download/v${GVER}/geckodriver-v${GVER}-linux64.tar.gz"
wget -O geckodriver.tar.gz ${GECKODRIVER}
tar -xvf geckodriver.tar.gz
sudo mv -f geckodriver /usr/local/bin/
sudo chmod 777 /usr/local/bin/geckodriver
```
