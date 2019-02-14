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
  if [[ ! -d ${TARGET} ]]; then
    mkdir -p ${TARGET}
  fi

  cd ${TARGET}

  for file in "${files[@]}"
  do
     file="${GITHUB}/${REPOSITORY}/${BRANCH}/make/${file}"
     echo ${file}
     curl -LJO ${file}
  done
}

main
