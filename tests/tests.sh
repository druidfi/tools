#!/usr/bin/env bash

TEST_FILES=($(find tests/outputs -type f | sort -n))
TMP_FILE=/tmp/druidfi-tools-comparison.txt

for item in ${TEST_FILES[*]}
do
    MAKE_TARGET=$(head -n1 "${item}")
    EXPECTED=$(tail -n +3 "${item}")
    OUTPUT=$(make -n --no-print-directory --directory=make ${MAKE_TARGET})

    if [ "${OUTPUT}" = "${EXPECTED}" ]
    then
      printf "\e[0;33mOutput was expected for: make %s\e[0m\n" "${MAKE_TARGET}"
    else
      printf "\n\e[0;31mOutput failed for: for: make %s\e[0m\n\n" "${MAKE_TARGET}"
      printf "\e[0;33mExpect:\e[0m\n%s\n" "${EXPECTED}"
      printf "\e[0;33mActual:\e[0m\n%s\n" "${OUTPUT}"
      printf "\n\e[0;31mDiff:\e[0m\n"
      echo "${OUTPUT}" > "${TMP_FILE}"
      diff -y --suppress-common-lines "${item}" "${TMP_FILE}"
      rm "${TMP_FILE}"
      exit 1
    fi
done

printf "\e[0;33mDone\e[0m\n"
exit 0
