verify: sh test/run.sh
deploy_test: sh scripts/deploy.sh
acceptance: sh scripts/acceptance.sh
monitor: sh scripts/monitor.sh
window: 1m
rollback: none
done_at: unit
merge: self
branch_protection: main requires checks verify
prod: human
risk:
  data: data/
