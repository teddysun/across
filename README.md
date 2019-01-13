# Some useful scripts

l2tp.sh
=======

- Description: Auto install L2TP VPN for CentOS6+/Debian7+/Ubuntu12+
- Intro: https://teddysun.com/448.html
```bash
Usage: l2tp [-l,--list|-a,--add|-d,--del|-m,--mod|-h,--help]

| Bash Command     | Description                  |
|------------------|------------------------------|
| l2tp -l,--list   | List all users               |
| l2tp -a,--add    | Add a user                   |
| l2tp -d,--del    | Delete a user                |
| l2tp -m,--mod    | Modify a user password       |
| l2tp -h,--help   | Print this help information  |
```

bbr.sh
======

- Description: Auto install latest kernel for TCP BBR
- Intro: https://teddysun.com/489.html

kms.sh
======

- Description: Auto install KMS Server
- Intro: https://teddysun.com/530.html

bench.sh
========

- Description: Auto test download & I/O speed script
- Intro: https://teddysun.com/444.html
```bash
Usage:

| No.      | Bash Command                    |
|----------|---------------------------------|
| 1        | wget -qO- bench.sh | bash       |
| 2        | curl -Lso- bench.sh | bash      |
| 3        | wget -qO- 86.re/bench.sh | bash |
| 4        | curl -so- 86.re/bench.sh | bash |
```

backup.sh
=========

- You must modify the config before run it
- Backup MySQL/MariaDB/Percona datebases, files and directories
- Backup file is encrypted with AES256-cbc with SHA1 message-digest (option)
- Auto transfer backup file to Google Drive (need install `gdrive` command) (option)
- Auto transfer backup file to FTP server (option)
- Auto delete Google Drive's or FTP server's remote file (option)
- Intro: https://teddysun.com/469.html

```bash
Install gdrive command step:

For x86_64: 
wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-x64
chmod +x /usr/bin/gdrive

For i386: 
wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-386
chmod +x /usr/bin/gdrive
```

ftp_upload.sh
=============

- You must modify the config before run it
- Upload file(s) to FTP server
- Intro: https://teddysun.com/484.html

unixbench.sh
============

- Description: Auto install unixbench and test script
- Intro: https://teddysun.com/245.html

pptp.sh(Deprecated, DO NOT USE)
===================

- Description: Auto Install PPTP for CentOS 6
- Intro: https://teddysun.com/134.html

Copyright (C) 2013-2019 Teddysun <i@teddysun.com>
