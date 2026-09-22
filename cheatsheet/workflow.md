# Daily workflow

| Moment | Action |
| --- | --- |
| Start | Open VT-Tasks. Pick the next action for the active software or content outcome. Read the last handoff and `git status`. |
| Concurrent editing | `wt task-name` creates a separate branch/worktree and enters it. `git worktree list` shows active checkouts. Runtime data still needs coordination. |
| Resume | `cr` chooses a Claude session; `cl` resumes the latest. Verify the repository/account before continuing. |
| Files | Ctrl+T searches the current directory. `ffall` explicitly searches the whole machine. |
| Browser work | Select the named Browser Bridge profile and port, then run its `npm run doctor` and `npm run verify`. Verify the account visible in the target site before an authorized write. |
| End | Append the handoff below to the existing task or project note. |
| Maintenance | Batch routine upgrades, backup evidence, CI failures and patch follow-ups in the weekly block. Handle urgent incidents when they occur. |

```text
Outcome:
Changed:
Verified (command/result/evidence/date):
Blocker:
Next action or command:
```

For the 14-28 September experiment, keep one software outcome and one content outcome active. Review incoming tasks at the start and end of the workday. Count completed outcomes, unscheduled maintenance interruptions and context reconstruction episodes in the existing VT-Tasks note. Review the limit after two weeks.

The optional `$HOME/.local/bin/env` loader was removed after review: the loader is absent on this Mac and `.zshrc` already prepends `$HOME/.local/bin` explicitly. The change preserves the user's pending deletion.
