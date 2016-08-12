# Some useful scripts

l2tp.sh
=======

* Description: Auto install L2TP VPN for CentOS6+/Debian7+/Ubuntu12+
* Intro: https://teddysun.com/448.html
```bash
Usage: l2tp [-l,--list|-a,--add|-d,--del|-h,--help]

| Bash Command     | Description                  |
|------------------|------------------------------|
| l2tp -l,--list   | List all users               |
| l2tp -a,--add    | Add a user                   |
| l2tp -d,--del    | Delete a user                |
| l2tp -h,--help   | Print this help information  |
```

bench.sh
========

* Description: Auto test download & I/O speed script
* Intro: https://teddysun.com/444.html
```bash
Usage:

| Option   | Bash Command                    |
|----------|---------------------------------|
| 1        | wget -qO- bench.sh | bash       |
| 2        | curl -Lso- bench.sh | bash      |
| 3        | wget -qO- 86.re/bench.sh | bash |
| 4        | curl -so- 86.re/bench.sh | bash |
```

backup.sh
=========

* You need to modify the config at first
* Backup MySQL/MariaDB all datebases & files and directories
* Backups are encrypted with AES256-cbc with SHA1 message-digest
* Auto transfer backup file to Google Drive(need install `gdrive`)

```bash
Install gdrive step:

For x86_64: 
wget -O /usr/bin/gdrive http://dl.teddysun.com/files/gdrive-linux-x64
chmod +x /usr/bin/gdrive

For i386: 
wget -O /usr/bin/gdrive http://dl.teddysun.com/files/gdrive-linux-386
chmod +x /usr/bin/gdrive
```

unixbench.sh
============

* Description: Auto install unixbench and test script
* Intro: https://teddysun.com/245.html

pptp.sh(Deprecated)
===================

* Description: Auto Install PPTP for CentOS 6
* Intro: https://teddysun.com/134.html

Copyright (C) 2013-2016 Teddysun <i@teddysun.com>
