# Fix Merge Conflict

You are resolving a git merge conflict. Given the conflicting sections:

## Steps

1. **Understand both sides** - What does each branch intend?
2. **Determine the correct resolution** - Usually you want to keep both changes integrated, not just pick one side
3. **Produce the merged result** - Clean code with no conflict markers

## Rules

- Never leave `<<<<<<<`, `=======`, or `>>>>>>>` markers in the output
- Preserve the intent of BOTH branches when possible
- If the changes are incompatible, explain the tradeoff and pick the safer option
- Keep the code style consistent with the surrounding context
- If you're unsure which side is correct, say so and present both options

## Output

Provide the resolved code block, then a brief explanation of what you kept from each side and why.
