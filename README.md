# get

- This script creates a target specific wordlist for pentesting using wayback

## Requirements

- [golang](https://golang.org/)
- [anew](https://github.com/tomnomnom/anew)
- [assetfinder](https://github.com/tomnomnom/assetfinder)
- [httprobe](https://github.com/tomnomnom/httprobe)
- [unfurl](https://github.com/tomnomnom/unfurl)
- [amass](https://github.com/OWASP/Amass)
- [subfinder](https://github.com/projectdiscovery/subfinder)
- [gau](https://github.com/lc/gau)
- [httpx](https://github.com/projectdiscovery/httpx)
- [getJS](https://github.com/003random/getJS)

## Basic Usage

```
user@guest:~/tools/scripts/recon$ ./get.sh tesla.com
```
```
user@guest:~/tools/scripts/recon$ echo tesla.com | ./get.sh
```
```
user@guest:~/tools/scripts/recon$ ./get.sh domains.txt
```
```
user@guest:~/tools/scripts/recon$ cat domains.txt | ./get.sh
```