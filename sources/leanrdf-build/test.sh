#!/bin/sh
set -eu
export PATH=/work/artifacts/bin:$PATH
export LD_LIBRARY_PATH=/work/artifacts/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p /work/evidence/tests
cd /work/rdf-lean
check() {
 name=$1
 expected=$2
 shift 2
 set +e
 "$@" > "/work/evidence/tests/$name.stdout" 2> "/work/evidence/tests/$name.stderr"
 actual=$?
 set -e
 printf '%s\t%s\t%s\n' "$name" "$expected" "$actual" >> /work/evidence/tests/results.tsv
 test "$actual" -eq "$expected"
}
: > /work/evidence/tests/results.tsv
check ableitung 0 leanrdf-demo examples/rdfs-university/university.nt examples/rdfs-university/query-kurt-person.nt --cert /work/evidence/tests/positive.json
check zertifikat 0 leanrdf-check --data examples/rdfs-university/university.nt --query examples/rdfs-university/query-kurt-person.nt --cert /work/evidence/tests/positive.json --json
check manipuliert 2 leanrdf-check --data examples/certificate-check/university.nt --query examples/certificate-check/query-kurt-person.nt --cert examples/certificate-check/kurt-person-tampered.json --json
check andere_daten 2 leanrdf-check --data examples/certificate-check/university-extended.nt --query examples/certificate-check/query-kurt-person.nt --cert examples/certificate-check/kurt-person.json --json
check widerlegt 5 leanrdf-demo examples/countermodels/pets.nt examples/countermodels/query-tom-dog.nt --countermodel /work/evidence/tests/negative.json
check gegenmodell 5 leanrdf-check --data examples/countermodels/pets.nt --query examples/countermodels/query-tom-dog.nt --countermodel /work/evidence/tests/negative.json --json
check widerspruch 4 leanrdf-demo examples/inconsistency/cats.nt examples/inconsistency/query-tom-fish.nt --profile owl --cert /work/evidence/tests/clash.json
check widerspruchszertifikat 4 leanrdf-check --data examples/inconsistency/cats.nt --cert /work/evidence/tests/clash.json --rules owl --json
check shacl_gueltig 0 leanrdf-shacl validate --data examples/shacl-employees/valid.ttl --shapes examples/shacl-employees/shapes.ttl
check shacl_ungueltig 1 leanrdf-shacl validate --data examples/shacl-employees/invalid.ttl --shapes examples/shacl-employees/shapes.ttl
printf 'ERFOLG\n' > /work/evidence/tests/result.txt
cat /work/evidence/tests/results.tsv
