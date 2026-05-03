# Mastering TOTP

## Synopsis
Vous les utilisez tous les jours, ou presque, mais savez vous comment fonctionnent les codes TOTP ? Ces codes à 6 chiffres qui changent toutes les 30 secondes. Cette présentation sera l’occasion de vous expliquer son fonctionnement, son implémentation, les bonnes, et mauvaises, pratiques sur sa sécurité et nous terminerons sur les vulnérabilités connues.

## De la théorie
blablabla

## A la pratique
blablabla

## Et le reste

## Annexes
### Sources
- Dcode : https://www.dcode.fr/code-base-32
- GeekForGeek : https://www.geeksforgeeks.org/dsa/bit-manipulation-swap-endianness-of-a-number
- Korben : https://korben.info/gpu-zip-pixnapping-android-2fa-faille-non-patchee.html
- IT-Connect : https://www.it-connect.fr/authquake-une-faille-critique-decouverte-dans-le-mfa-de-microsoft
- IProov : https://www.iproov.com/fr/blog/one-time-passcode-otp-authentication-risks
- Linkedin : https://www.linkedin.com/feed/update/urn:li:activity:7411305792072597504
- CLUSIF : https://www.globalsecuritymag.fr/CLUSIF-panorama-de-la,20150119,50072.html

### RFC
- 2104 : HMAC: Keyed-Hashing for Message Authentication
- 4226 : HOTP: An HMAC-Based One-Time Password Algorithm
- 4648 : The Base16, Base32, and Base64 Data Encodings
- 6238 : TOTP: Time-Based One-Time Password Algorithm
- 6030 : Portable Symmetric Key Container (PSKC)
- 8332 : Use of RSA Keys with SHA-256 and SHA-512 in the Secure Shell (SSH) Protocol

### Vulnérabilités
- CVE-2017-18948 : SS7 (Telefonica, Allemagne)
- CVE-2024-43491 : AuthQuake (Microsoft)
- CVE-2025-48561 : Pixnapping (Google/Android)
