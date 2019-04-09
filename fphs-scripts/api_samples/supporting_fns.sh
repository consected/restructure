# Supporting functions for API samples
# Sourced from scripts that require them
got_container_res=0

container_exists () {
  local container_res=$1

  if [ "${container_res}" == "No container found" ]
  then
    return 0
  else
    parse_container_res "${container_res}" > /dev/null
    return ${got_container_res}
  fi
}

parse_container_res () {
  local container_res=$1
  export got_container_res=0

  if [ "${container_res}" == "Request failed" ] || [ "${container_res}" == "No container found" ]
  then
    echo "Container request failed: ${container_res}"
    exit 1
  else
    echo "Container details: ${container_res}"
  fi


  IFS=','
  read -ra ADDR <<< "${container_res}"
  export container_id="${ADDR[0]}"
  export activity_log_id="${ADDR[1]}"
  export activity_log_type="${ADDR[2]}"
  export got_container_res=1
}


parse_master () {
  local master_res=$1

  if [ "${master_res}" == "Request failed" ]
  then
    echo "Master lookup request failed"
    exit 1
  else
    master_res=$(echo "${master_res}" | tail -n 1)
  fi

  IFS=','
  read -ra ADDR <<< "${master_res}"
  export master_id="${ADDR[1]}"
  return ${master_id}
}
