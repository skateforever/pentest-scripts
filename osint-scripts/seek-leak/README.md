## karma
**API: `pwndb2am4tzkvold (dot) onion`**

![version](https://img.shields.io/badge/version-15.03.19-lightgrey.svg?style=flat-square)
[![demo](https://img.shields.io/badge/demo-video-lightgrey.svg?style=flat-square)](https://www.youtube.com/watch?v=tL-kYkmudz4)

Find leaked emails with your passwords.

![screenshot](screenshot.png)

---

### Install
```
sudo apt install tor python3 python3-pip
sudo service tor start

git clone https://github.com/decoxviii/karma.git ; cd karma
sudo -H pip3 install -r requirements.txt
python3 bin/karma.py --help
```

---

### Tests
All the tests were done in `Debian/Ubuntu`.

1. Search emails with the password: `123456789`
```
python3 bin/karma.py search '123456789' --password -o test1
```

2. Search emails with the local-part: `johndoe`
```
python3 bin/karma.py search 'johndoe' --local-part -o test2
```

3. Search emails with the domain: `hotmail.com`
```
python3 bin/karma.py search 'hotmail.com' --domain -o test3
```

4. Search email password: `johndoe@unknown.com`
```
python3 bin/karma.py target 'johndoe@unknown.com' -o test4
```

---

### Thanks
This program is inspired by the projects:

+ [M3l0nPan](https://github.com/M3l0nPan) - [pwndb-api](https://github.com/M3l0nPan/pwndb_api)
+ [davidtavarez](https://github.com/davidtavarez) - [pwndb](https://github.com/davidtavarez/pwndb)

### Disclaimer

Usage this program for attacking targets without prior consent is illegal. It's the end user's responsibility to obey allapplicable local, state and federal laws. Developers assume no liability and are not responsible for any misuse or damage caused by this program.

---

#### decoxviii

**[MIT](https://github.com/decoxviii/karma/blob/master/LICENSE)**
