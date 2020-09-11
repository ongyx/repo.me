# cidercellar
Open-sourced Debian packages for iPhoneOS
(actual repository is at `ongyx.github.io/repo` [direct link](https://ongyx.github.io/repo))
Based on [repo.me](https://github.com/syns/repo.me) by [@syns](https://github.com/syns).

## Building

### iOS (jailbroken)
Install `Debian Packager (Perl)`, search in Cydia, et al. or run this in a terminal:

```
(sudo) apt install dpkg-perl
```

### Any other Debian-based system
Install dpkg-dev and fakeroot first:

```
(sudo) apt install dpkg-dev fakeroot
```

### Alpine Linux
Alpine Linux (surprisingly) also has dpkg as a package, so you can build there too:
(Shoutout to [iSH](https://ish.app) users out there!)

```
(sudo) apk add dpkg dpkg-dev fakeroot tar
```

The `tar` that comes with BusyBox in Alpine by default does **not** support `dpkg-deb`, so you need to install GNU `tar`.
(found out about this after some weird `dpkg-deb` errors.)

## Usage

Run `ezbuild.sh` with fakeroot.

NOTE: `fakeroot` is broken on iOS (jailbroken), so you have to run with sudo or as root. Sorry :(

```
(sudo/fakeroot) ./ezbuild.sh
```

## License

Everything except for the folders `debs` and `src` is under the MIT license.
(The packages in the `src` folder and therefore their archives in `debs` have different licenses, so check each one first before redistributing.)
