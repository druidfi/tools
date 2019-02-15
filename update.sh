#!/usr/bin/env bash

GITHUB=https://raw.githubusercontent.com
REPOSITORY=druidfi/tools
BRANCH=master
TARGET=tools/make

declare -a files=(
  "Makefile"
  "include.mk"
  "docker.mk"
  "composer.mk"
  "drupal.mk"
  "amazeeio.mk"
)

main() {
  if which tput >/dev/null 2>&1; then
      ncolors=$(tput colors)
  fi
  if [[ -t 1 ]] && [[ -n "$ncolors" ]] && [[ "$ncolors" -ge 8 ]]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
  fi

  set -e

  printf "${YELLOW}Start updating files from ${REPOSITORY}...${NORMAL}\n"

  if [[ ! -d ${TARGET} ]]; then
    mkdir -p ${TARGET}
  fi

  cd ${TARGET}

  for i in "${!files[@]}"
  do
     file=${files[i]}
     files[${i}]="-O ${GITHUB}/${REPOSITORY}/${BRANCH}/make/${file}"
  done

  #echo ${files[@]}
  curl -LJ --progress-bar ${files[@]}

  printf "${YELLOW}Update complete!${NORMAL}\n"
}

main
