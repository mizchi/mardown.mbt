bench:
  moon bench

bench-accept:
  moon bench > .bench-baseline

test:
  moon test --target js -p mizchi/compat_tests
