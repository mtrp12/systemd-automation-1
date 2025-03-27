#!/usr/bin/env bash

log(){
  echo -e "\e[95mTEST: $1\e[0m"
}

log "Checking node application health..."
curl http://localhost:3000/health ; echo

log "Fetching user with id 5..."
curl http://localhost:3000/users?id=5 ; echo

log "Fetching users with name Scott..."
curl http://localhost:3000/users?name=Scott ; echo

log "Fetching second page users..."
curl http://localhost:3000/users?page=2 ; echo