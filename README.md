<h1 align="center">🛡️ VPS Alapbeállítások</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Debian-✓-red?style=for-the-badge&logo=debian" />
  <img src="https://img.shields.io/badge/Ubuntu-✓-orange?style=for-the-badge&logo=ubuntu" />
  <img src="https://img.shields.io/badge/Bash-Script-black?style=for-the-badge&logo=gnubash" />
  <img src="https://img.shields.io/badge/Author-Doky-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Licenc-MIT-yellow?style=for-the-badge" />
</p>

<p align="center"><strong>Interaktív bash szkript friss Debian/Ubuntu VPS-ek alapvető biztonsági beállításaihoz.</strong></p>

<p align="center">Végigvezet a szükséges lépéseken: hosztnév, SSH port, időzóna, sudo felhasználó létrehozása, root SSH tiltása, rendszerfrissítés — mindezt biztonsági mentésekkel és részletes összegzéssel.</p>

---

## 📌 Funkciók

- **Root ellenőrzés** — csak root jogosultsággal futtatható
- **OS ellenőrzés** — kizárólag Debian és Ubuntu rendszereken fut
- **Rendszerinformációk** — OS, kernel, architektúra, hosztnév, időzóna megjelenítése
- **Hosztnév beállítása** — új hosztnév megadása vagy kihagyás
- **SSH port módosítása** — egyedi port megadása (1024–65535, alapértelmezett: 22)
- **Időzóna beállítása** — pl. `Europe/Budapest`
- **Sudo felhasználó létrehozása** — új felhasználó, 22 karakteres véletlenszerű jelszóval
- **NOPASSWD sudo** — jelszó nélküli sudo jog az új felhasználónak
- **Rendszerfrissítés** — `apt update` és `apt upgrade` futtatása
- **Root SSH tiltása** — közvetlen root bejelentkezés letiltása (`PermitRootLogin no`)
- **SSH konfiguráció ellenőrzése** — `sshd -t` validálás, majd szolgáltatás újraindítás
- **Belépési adatok mentése** — `/root/<felhasználó>_credentials.txt` fájlba, `chmod 600` joggal
- **Részletes összegzés** — minden elvégzett módosítás áttekintése a futás végén
- **Biztonsági mentések** — fájlok módosítása előtt időbélyegzős backup készül

---

## 📦 Rendszerkövetelmények

- Debian 12/13 vagy Ubuntu 22.04/24.04
- Root jogosultság (`sudo`)
- Internetkapcsolat (apt frissítéshez)

---

## 📥 Használat

### Letöltés és futtatás

```bash
wget https://raw.githubusercontent.com/Doky1988/vps-alapbeallitasok/main/vps-alapbeallitasok.sh
chmod +x vps-alapbeallitasok.sh
sudo bash vps-alapbeallitasok.sh
```

### Egy paranccsal

```bash
bash <(wget -qO- https://raw.githubusercontent.com/Doky1988/vps-alapbeallitasok/main/vps-alapbeallitasok.sh)
```

---

## ⚙️ A script működése

A szkript végigvezet a beállításokon — minden lépésnél megadhatod a kívánt értéket, vagy Enter-rel kihagyhatod:

1. **Root és OS ellenőrzés** — automatikus, nem kihagyható
2. **Rendszerinformációk** — automatikusan megjelennek
3. **Hosztnév** — add meg az új hosztnevet, vagy Enter a kihagyáshoz
4. **SSH port** — add meg az új portot, vagy Enter a 22-höz
5. **Időzóna** — add meg az időzónát (pl. `Europe/Budapest`), vagy Enter a jelenlegihez
6. **Sudo felhasználó** — add meg a felhasználónevet, vagy Enter a kihagyáshoz
7. **Rendszerfrissítés** — automatikusan lefut
8. **SSH konfiguráció** — root tiltás, port csere, validálás, újraindítás
9. **Belépési adatok mentése** — fájlba mentés (ha volt felhasználó létrehozás)
10. **Összegzés és figyelmeztetések**

---

## 🖥️ Példa kimenet

```
==============================================
    Linux Szerver – Biztonsági Beállítások
                Készítette: Doky
==============================================

Rendszerinformációk:
  Operációs rendszer:   Debian GNU/Linux 13 (trixie)
  Kernel verzió:        6.12.86+deb13-amd64
  Architektúra:         x86_64
  Jelenlegi hosztnév:   vps12345
  Jelenlegi idő:        Sat Aug  8 15:30:00 UTC 2026
  Időzóna:              Europe/Budapest

═══ Hosztnév beállítása ═══
  Jelenlegi: vps12345
Új hosztnév (Enter = kihagy): szervered.host.hu
[✓] Hosztnév beállítva: szervered.host.hu

═══ SSH port beállítása ═══
  Jelenlegi port (sshd_config-ból): 22
Új SSH port [22]: 2222
[*] SSH port: 2222

═══ Új sudo felhasználó létrehozása ═══
Új felhasználónév (Enter = kihagy): felhasznalo
[✓] Felhasználó létrehozva: felhasznalo
[✓] Jelszó beállítva.
[✓] NOPASSWD sudo beállítva: /etc/sudoers.d/10-felhasznalo-nopasswd

═══ Rendszer frissítése ═══
[✓] Rendszer frissítve (apt update + apt upgrade).

═══ SSH konfiguráció ═══
[✓] Biztonsági mentés: /etc/ssh/sshd_config.backup.20260808_153000
[✓] Root SSH bejelentkezés: tiltva (PermitRootLogin no)
[✓] SSH port beállítva: 2222
[*] SSH konfiguráció ellenőrzése (sshd -t)...
[✓] SSH konfiguráció szintaktikailag rendben.
[✓] SSH szolgáltatás újraindítva.

═══ Belépési adatok mentése ═══
[✓] Belépési adatok mentve: /root/felhasznalo_credentials.txt

========================================
          RÉSZLETES ÖSSZEGZÉS
========================================

  Rendszer információ:
    OS:                  Debian GNU/Linux 13 (trixie)
    Kernel:              6.12.86+deb13-amd64
    Hosztnév:            szervered.host.hu
    Időzóna:             Europe/Budapest

  Rendszer állapot:
    [✓] Rendszer frissítve (apt update + upgrade)

  Felhasználó:
    [✓] Felhasználónév:     felhasznalo
    [✓] Sudo:               NOPASSWD (jelszó nélküli)
    [✓] Credentials fájl:   /root/felhasznalo_credentials.txt

  SSH:
    [✓] Root SSH bejelentkezés: tiltva
    [✓] SSH port:              2222

========================================
               FIGYELEM!
========================================
  ► Az SSH port megváltozott: 2222
  ► Kapcsolódáshoz használd: ssh -p 2222 admin@szerver
  ► Nyiss egy ÚJ SSH MUNKAMENETET mielőtt kilépsz!
  ► Teszteld, hogy tudsz-e csatlakozni az új beállításokkal!

Kész – a szerver alapvető biztonsági beállításai elvégezve.
```

---

## ⚠️ Fontos

- **SSH portcsere után** nyiss egy új SSH munkamenetet, mielőtt kilépsz a jelenlegiből — ellenkező esetben kizárhatod magad a szerverről!
- A generált belépési adatokat a `/root/<felhasználó>_credentials.txt` fájl tartalmazza — **őrizd meg biztonságosan!**
- Az első bejelentkezés után **változtass jelszót** a `passwd` paranccsal
- A script **nem zavar be** meglévő vezérlőpanelekbe (KeyHelp, cPanel, Plesk, ISPConfig stb.)

---

## ❤️ Készítette: Doky  
📅 2026.08.08
