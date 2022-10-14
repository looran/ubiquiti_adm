## ubiquiti_adm - manage Ubiquiti Unifi access-point via SSH

tested on Ubiquiti Unifi 7.2

2022, Laurent Ghigonis <ooookiwi@gmail.com>

### Usage

```bash
usage: ./ubiquiti_adm [-q] <ubiquiti_host> <action>
action:
   system                : get system informations
   wifi-aps              : list wifi access points ssids
   wifi-clis             : list wifi clients per access point
   wifi-start <num|ssid> : start one ssid
   wifi-start-radio      : start wifi radio, enabling all ssids
   wifi-stop <num|ssid>  : stop one ssid
   wifi-stop-radio       : stop wifi radio, disabling all ssids
   ssh                   : open ssh session
   -v                    : verbose output
SSH_OPTS=-o HostKeyAlgorithms=+ssh-rsa
```

### Example usage

* list SSIDs

```bash
$ ubiquiti_adm 192.168.1.1 wifi-aps
1 ath0 UP   Company wireless
2 ath1 UP   Company wireless 5G
3 ath2 UP   Guest access
```

* list Wifi clients
```bash
$ ubiquiti_adm 192.168.1.1 wifi-clis
  "00:11:22:33:44:55",  "Company wireless",  149,  6779538491,  5423793449,  [
      "00:11:22:33:44:00",      "192.168.2.11",      -76,      2210,      4,      361792,      229603,      "pipounette"
      "00:11:22:33:44:01",      "192.168.2.12",      -64,      26483,      8,      212150812,      74231234,      "PC-392"
  "00:11:22:33:44:56",  "Company wireless 5G",  6,  3434642,  2187203,  []
  "00:11:22:33:44:57",  "Guest access",  6,  3434642,  2187203,  []
      "00:11:22:33:44:02",      "192.168.3.11",      -64,      93438,      8,      194304983,      93434333,      "iphone"
```

* disable one SSID

```bash
$ ubiquiti_adm 192.168.1.1 wifi-stop "Guest access"
```

* disable all radio

```bash
$ ubiquiti_adm 192.168.1.1 wifi-stop-radio
```

### Prerequisites

1. Get SSH access to your Ubiquiti access point, preferably with an ssh key to avoid entering password
2. If you are using active actions such as wifi-start/wifi-stop/wifi-start-radio/wifi-stop-radio, do not connect an management platform such as Unifi Controller / Unifi Console to the network, as they may rollback actions set my ubiquiti_adm

### Installation

```bash
$ sudo make install
```
