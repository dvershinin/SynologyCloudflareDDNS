#!/bin/sh

# DSM Config
__USERNAME__="$(echo ${@} | cut -d' ' -f1)"
__PASSWORD__="$(echo ${@} | cut -d' ' -f2)"
__HOSTNAME__="$(echo ${@} | cut -d' ' -f3)"
__MYIP__="$(echo ${@}  | cut -d' ' -f4)"

# log location
__LOGFILE__="/var/log/cloudflareddns.log"

# CloudFlare Config
__RECTYPE__="A"

# "rev" command is not available in Synology boxes
# __ZONE_DOMAIN__=$(echo "${__HOSTNAME__}" | rev | cut -d '.' -f 1,2 | rev)
# and we want to use something more reliable which will deal with things like .co.uk properly
__ZONE_DOMAIN__=$(echo "${__HOSTNAME__}" | python -c "import sys, tldextract; print tldextract.extract(sys.stdin.readline()).registered_domain")
__ZONE_ID__=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${__ZONE_DOMAIN__}" \
  -H "X-Auth-Email: ${__USERNAME__}" \
  -H "X-Auth-Key: ${__PASSWORD__}" \
  -H "Content-Type: application/json" \
  | python -c "import sys, json; print json.load(sys.stdin)['result'][0]['id']")
__RECID__=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${__ZONE_ID__}/dns_records?name=${__HOSTNAME__}" \
  -H "X-Auth-Email: ${__USERNAME__}" \
  -H "X-Auth-Key: ${__PASSWORD__}" \
  -H "Content-Type: application/json" \
  | python -c "import sys, json; print json.load(sys.stdin)['result'][0]['id']")
__TTL__="1"
__PROXY__="true"

echo $__ZONE_ID__

log() {
    __LOGTIME__=$(date +"%b %e %T")
    if [ "${#}" -lt 1 ]; then
        false
    else
        __LOGMSG__="${1}"
    fi
    if [ "${#}" -lt 2 ]; then
        __LOGPRIO__=7
    else
        __LOGPRIO__=${2}
    fi

    logger -p ${__LOGPRIO__} -t "$(basename ${0})" "${__LOGMSG__}"
    echo "${__LOGTIME__} $(basename ${0}) (${__LOGPRIO__}): ${__LOGMSG__}" >> ${__LOGFILE__}
}

__URL__="https://api.cloudflare.com/client/v4/zones/${__ZONE_ID__}/dns_records/${__RECID__}"

# Update DNS record:
log "Updating with ${__MYIP__}..."
__RESPONSE__=$(curl -s -X PUT "${__URL__}" \
     -H "X-Auth-Email: ${__USERNAME__}" \
     -H "X-Auth-Key: ${__PASSWORD__}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${__RECTYPE__}\",\"name\":\"${__HOSTNAME__}\",\"content\":\"${__MYIP__}\",\"ttl\":${__TTL__},\"proxied\":${__PROXY__}}")

# Strip the result element from response json
__RESULT__=$(echo ${__RESPONSE__} | python -c "import sys, json; print json.load(sys.stdin)['success']")
echo ${__RESPONSE__}
case ${__RESULT__} in
    'true')
        __STATUS__='good'
        true
        ;;
    *)
        __STATUS__="${__RESULT__}"
        log "__RESPONSE__=${__RESPONSE__}"
        false
        ;;
esac
log "Status: ${__STATUS__}"

printf "%s" "${__STATUS__}"
