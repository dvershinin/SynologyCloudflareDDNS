# Synology Cloudflare DDNS Script 📜
The is a script to be used to add [Cloudflare](https://www.cloudflare.com/) as a DDNS to [Synology](https://www.synology.com/) NAS. 
This is a modified version [script](https://gist.github.com/tehmantra/f1d2579f3c922e8bb4a0) from [Michael Wildman](https://gist.github.com/tehmantra). 
The script uses updated API, Cloudflare API v4.

## How to use
### Access Synology via SSH
1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client or commandline to access Synology. If you don't have any, I recommand you can try out [MobaXterm](http://mobaxterm.mobatek.net/) for Windows.
4. Use your Synology admin account to connect.

### Run commands in Synology
1. Download `cloudflareddns.sh` from this repository to `/usr/local/sbin/cloudflareddns.sh`
```
curl https://raw.githubusercontent.com/dvershinin/SynologyCloudflareDDNS/master/cloudflareddns.sh -o /usr/local/sbin/cloudflareddns.sh
```
It is not a must, you can put I whatever you want. If you put the script in other name or path, make sure you use the right path.

2. Give others execute permission
```
chmod 755 /usr/local/sbin/cloudflareddns.sh
```

3. Add `cloudflareddns.sh` to Synology
```bash
cat >> /etc/ddns_provider.conf << 'EOF'
[USER_Cloudflare]
        modulepath=/usr/local/sbin/cloudflareddns.sh
        queryurl=https://www.cloudflare.com/
E*.
```
`queryurl` does not matter because we are going to use our script but it is needed.

4. A safe Python environment setup

Ths module needs some Python modules installable via `pip`, namely `tldextract`. It will help us to automatically fetch parent domain.

Synology is known for wiping custom Python module you install via pip. This is why we're better of creating a virtualenv at /usr/local or other safe location. In the furue we will convert the entire script to Python.

```bash
curl https://bootstrap.pypa.io/get-pip.py | python
pip install virtualenv
# create virtualenv twice to ensure creation of "activate" script
virtualenv /usr/local/SynologyCloudflareDDNS
virtualenv /usr/local/SynologyCloudflareDDNS
# go inside our virtualenv
. /usr/local/SynologyCloudflareDDNS/bin/activate
# install the packages we need there (cloudflare will be used in the future):
pip install tldextract cloudflare
```

### Get Cloudflare parameters

Go to your [account setting page](https://www.cloudflare.com/a/account/my-account) and get **API Key**.

### Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Select Cloudflare as service provider. Enter your domain as hostname, your Cloudflare account as Username/Email, and API key as Password/Key

## Parameters
### \_\_USERNAME\_\_, \_\_PASSWORD\_\_, \_\_HOSTNAME\_\_, \_\_MYIP\_\_
These are the parameters from Synology.

### \_\_RECTYPE\_\_
DNS record type

### \_\_RECID\_\_
Record ID

### \_\_ZONE\_ID\_\_
Zone ID

### \_\_TTL\_\_
Time to live for DNS record. Value of 1 is 'automatic'

### \_\_PROXY\_\_
Whether the record is receiving the performance and security benefits of Cloudflare.

### \_\_LOGFILE\_\_
Log file location

You can read the [Cloudflare API documentation v4](https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record) for more details.
