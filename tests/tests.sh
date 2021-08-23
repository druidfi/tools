#!/usr/bin/env bash

TEST_FILES=($(find tests/outputs -type f | sort -n))
TMP_FILE=tests/druidfi-tools-comparison.txt

for item in ${TEST_FILES[*]}
do
    MAKE_TARGET=$(head -n1 "${item}")
    EXPECTED=$(tail -n +3 "${item}")
    OUTPUT=$(make -n --no-print-directory --directory=make ${MAKE_TARGET} | sed 's/^ *//;s/ *$//')

    if [ "${OUTPUT}" == "${EXPECTED}" ]
    then
      printf "\e[0;33m✅ make %s\e[0m\n" "${MAKE_TARGET}"
    else
      printf "\n\e[0;31m❌ make %s\e[0m\n\n" "${MAKE_TARGET}"
      printf "\e[0;33mExpect:\e[0m\n%s\n" "${EXPECTED}"
      printf "\e[0;33mActual:\e[0m\n%s\n" "${OUTPUT}"
      printf "\e[0;33mDiff:\e[0m\n"
      rm -f ${TMP_FILE}
      echo "$(head -n2 "${item}")" > "${TMP_FILE}"
      echo "${OUTPUT}" >> "${TMP_FILE}"
      diff -y --suppress-common-lines "${item}" "${TMP_FILE}" | cat -te
      printf "\n\e[0;31mEnding tests...\e[0m\n"
      exit 1
    fi
done

printf "\n\e[0;33mDone. All tests passed.\e[0m\n"
exit 0
