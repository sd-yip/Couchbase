#!/usr/bin/env sh
set -eu

[ "$1" = couchbase-server ] || exec "$@"
port=20091

case $(head -1 /opt/couchbase/etc/couchbase/static_config) in
  "{rest_port,$port}.") ;;
  *) sed -i 1s/^/"{rest_port,$port}.\n"/ /opt/couchbase/etc/couchbase/static_config ;;
esac
/entrypoint.sh "$@" | sed "s/:8091\>/:$port/" &
pid1=$!

until
  curl -fsw.\\n localhost:"$port"/pools/default \
    -dmemoryQuota="${MEMORY_QUOTA:-300}" -dindexMemoryQuota="${INDEX_MEMORY_QUOTA:-300}"
do
  sleep 1
done

attempt_curl() {
  curl -fsw.\\n "$@" || {
    curl -sw\\n "$@"
    false
  }
}
services=$(
  printf %s kv%2C
  [ "${ENABLE_QUERY-}" = false ] || printf %s n1ql%2C
  [ "${ENABLE_SEARCH-}" != true ] || printf %s fts%2C
  [ "${ENABLE_INDEX-}" = false ] || printf %s index%2C
)
attempt_curl localhost:"$port"/node/controller/setupServices -dservices="$services"

username=${USERNAME:-Administrator}
password=${PASSWORD:-password}
attempt_curl localhost:"$port"/settings/web -dusername="$username" -dpassword="$password" -dport="$port"

index_storage=${INDEX_STORAGE:-$(
  case $(couchbase-server --version 2>&1) in
    *'(CE)'*) echo forestdb ;;
    *) echo memory_optimized ;;
  esac
)}
attempt_curl -u"$username:$password" localhost:"$port"/settings/indexes \
  -dindexerThreads=0 -dlogLevel=info -dmaxRollbackPoints=5 -dstorageMode="$index_storage"

[ -z ${BUCKET+x} ] || {
  couchbase-cli bucket-create -clocalhost:"$port" -u"$username" -p"$password" \
    --bucket "$BUCKET" \
    --bucket-type "${BUCKET_TYPE:-couchbase}" \
    --bucket-ramsize "${BUCKET_QUOTA:-100}" \
    --bucket-replica "${BUCKET_REPLICAS:-0}" \
    --enable-index-replica "$([ "${BUCKET_INDEX_REPLICAS-}" = true ] && echo 1 || echo 0)" \
    --enable-flush "$([ "${BUCKET_ENABLE_FLUSH-}" = true ] && echo 1 || echo 0)" \
    --bucket-eviction-policy "${BUCKET_EJECTION_METHOD:-valueOnly}"

  couchbase-cli user-manage -clocalhost:"$port" -u"$username" -p"$password" --set \
    --auth-domain local \
    --rbac-username "$BUCKET" \
    --rbac-password "${BUCKET_PASSWORD:-$password}" \
    --roles admin

  [ "${BUCKET_ENABLE_PRIMARY_INDEX-${ENABLE_INDEX-}}" = false ] || {
    if [ "${ENABLE_QUERY-}" = false ] || [ "${ENABLE_INDEX-}" = false ]; then
      echo >&2 Query and index service are required to create a primary index.
      false
    fi

    while :; do
      if
        message=$(
          cbq -exit-on-error -q -e localhost:"$port" -u "$username" -p "$password" \
            -s 'CREATE PRIMARY INDEX ON `'"$BUCKET"'`'
        )
      then
        echo "$message"
        break
      else
        echo .
        sleep 1
      fi
    done
  }
}
rest_port=${REST_PORT:-8091}

[ "$rest_port" -eq "$port" ] || {
  socat tcp-listen:"$rest_port",reuseaddr,fork tcp:localhost:"$port" &
  echo Proxy started at "$rest_port".
}
pid2=$!
echo Initialization completed.

[ "${ENABLE_STDOUT_LOG_FORWARDING-}" != true ] || tail -Fn+0 /opt/couchbase/var/lib/couchbase/logs/* &
wait "$pid2" && wait "$pid1" && wait $!
