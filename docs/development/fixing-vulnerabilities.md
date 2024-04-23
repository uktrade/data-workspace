---
title: Fixing vulnerabilities
layout: sub-navigation
---

1. Create a new branch called chore/dependencies-[yyyy-mm-dd], inserting today’s date.
1. Open each Dependabot PR and check that the tests have passed. Re-run any failing tests as the majority of failures are caused by timeouts or flakiness.
1. Once all tests have passed, edit the PR so that the base branch is the chore/dependencies-[yyyy-mm-dd] one. You should now be able to merge the PR without needing to request reviews.
1. Repeat steps 2 and 3 until all PRs are either merged or identified as needing further work
1. Run the vulnerability tool from https://github.com/uktrade/vulnerability-priority-list, ignoring any issues that have already been fixed in the chore/dependencies-[yyyy-mm-dd] branch
1. For every remaining issue, fix this in the chore/dependencies-[yyyy-mm-dd] branch
1. After all the dependabot PRs have been merged and vulnerabilites fixed, checkout the branch locally and carry out some basic smoke tests.
1. If you are satisfied that everything is in order and all the tests have passed, create a new PR to merge chore/dependencies-[yyyy-mm-dd] into the master branch.