#!/usr/bin/env bash

VERSION=2019-08-16-2
DEBUG=0
GITHUB=https://raw.githubusercontent.com
REPOSITORY=druidfi/tools
BRANCH=master
TARGET=tools/make
PROJECT_MAKEFILE=Makefile.project.dist
REPOSITORY_URL=https://github.com/druidfi/tools

declare -a files=(
  "Makefile"
  "include.mk"
  "common.mk"
  "docker.mk"
  "composer.mk"
  "javascript.mk"
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

  printf "${YELLOW}${REPOSITORY} updater (version ${VERSION})${NORMAL}\n"

  if [[ ! -f "Makefile" ]]; then
    printf "\n${BLUE}[Info] ${NORMAL}Makefile does not exist, downloading it...${NORMAL}\n"
    curl -LJs -H 'Cache-Control: no-cache' -o Makefile ${GITHUB}/${REPOSITORY}/${BRANCH}/make/${PROJECT_MAKEFILE}
  fi

  if [[ ! -d ${TARGET} ]]; then
    printf "\n${BLUE}[Info] ${NORMAL}Folder ${TARGET} does not exist, creating it...${NORMAL}\n"
    mkdir -p ${TARGET}
  fi

  cd ${TARGET}

  printf "\n${YELLOW}Download following files from ${REPOSITORY_URL}:${NORMAL}\n"
  printf '%s\n' "${files[@]}"

  for i in "${!files[@]}"
  do
     file=${files[i]}
     timestamp=$(date +%s)
     urls[${i}]="${GITHUB}/${REPOSITORY}/${BRANCH}/make/${file}?t=${timestamp}"
  done

  for i in "${!files[@]}"
  do
    if [[ ${DEBUG} -eq 1 ]]; then
      printf "DEBUG: curl -LJs -o ${files[i]} ${urls[i]}\n"
    else
      curl -LJs -o ${files[i]} ${urls[i]}
    fi
  done

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
