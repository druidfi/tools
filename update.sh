#!/usr/bin/env bash

GITHUB=https://raw.githubusercontent.com
REPOSITORY=druidfi/tools
BRANCH=master
TARGET=tools/make
PROJECT_MAKEFILE=Makefile.project.dist

declare -a files=(
  "Makefile"
  "include.mk"
  "common.mk"
  "docker.mk"
  "composer.mk"
  "drupal.mk"
  "amazeeio.mk"
  "qa.mk"
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

  #set -e

  printf "${YELLOW}Start updating files from ${REPOSITORY}...${NORMAL}\n"

  if [[ ! -f "Makefile" ]]; then
    printf "\n${BLUE}[Info] ${NORMAL}Makefile does not exist, downloading it...${NORMAL}\n"
    curl -LJs -H 'Cache-Control: no-cache' -O ${GITHUB}/${REPOSITORY}/${BRANCH}/make/${PROJECT_MAKEFILE}
  fi

  if [[ ! -d ${TARGET} ]]; then
    printf "\n${BLUE}[Info] ${NORMAL}Folder ${TARGET} does not exist, creating it...${NORMAL}\n"
    mkdir -p ${TARGET}
  fi

  cd ${TARGET}

  printf "\n${YELLOW}Download following files:${NORMAL}\n"
  printf '%s\n' "${files[@]}"

  for i in "${!files[@]}"
  do
     file=${files[i]}
     files[${i}]="-O ${GITHUB}/${REPOSITORY}/${BRANCH}/make/${file}"
  done

  curl -LJs -H 'Cache-Control: no-cache' ${files[@]}

  if [[ $? -eq 0 ]]
  then
    printf "\n${GREEN}[OK] ${YELLOW}Update complete!${NORMAL}\n"
    exit 0
  else
    printf "\n${RED}[ERROR] ${YELLOW}Check if update.sh has correct settings.\n"
    exit 1
  fi
}

main
