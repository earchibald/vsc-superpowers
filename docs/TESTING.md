# Testing Guide

## Automated Tests

### Installation Verification

```bash
./scripts/verify-installation.sh
```

Checks:
- Cache exists at `~/.cache/superpowers`
- Instructions file present
- All 14 prompts installed
- Frontmatter format valid

## Manual Tests

### Test Prompt Availability

1. Reload VS Code (Cmd+Shift+P > Developer: Reload Window)
2. Open Copilot Chat
3. Type `/` to see command list
4. Verify all 14 superpowers commands appear:
   - /brainstorm
   - /write-plan
   - /execute-plan
   - /tdd
   - /investigate
   - /verify
   - /worktree
   - /finish-branch
   - /review
   - /receive-review
   - /subagent-dev
   - /dispatch-agents
   - /write-skill
   - /superpowers

### Test Skill Invocation

1. Type `/write-plan`
2. Press Enter
3. Verify skill content loads
4. Check for proper frontmatter and instructions

### Test Update Flow

1. Run `./install-superpowers.sh` again
2. Verify idempotent behavior
3. Check logs show "Updating" not "Installing"
4. Verify no file duplication

## Integration Tests

### End-to-End Workflow

1. Use `/brainstorm` to design a feature
2. Use `/write-plan` to create implementation plan
3. Use `/worktree` to create isolated workspace
4. Use `/tdd` to implement first task
5. Use `/review` to check work
6. Use `/verify` to ensure tests pass
7. Use `/finish-branch` to complete workflow

## Troubleshooting

### Prompts Not Appearing

- Verify reload: Cmd+Shift+P > Developer: Reload Window
- Check file exists: `ls .github/prompts/`
- Verify frontmatter: `head .github/prompts/write-plan.prompt.md`

### Cache Not Updating

- Manual update: `cd ~/.cache/superpowers && git pull`
- Check network: `ping github.com`

### Incorrect Behavior

- Check instructions: `cat .github/copilot-instructions.md`
- Verify SUPERPOWERS-START/END tags present
- Re-run installer: `./install-superpowers.sh`

## Test Coverage

### Files Tested
- ✓ install-superpowers.sh - Installation script
- ✓ scripts/verify-installation.sh - Verification script
- ✓ .github/copilot-instructions.md - System instructions
- ✓ .github/prompts/*.prompt.md - All 14 prompt files

### Scenarios Tested
- ✓ Fresh installation
- ✓ Update existing installation
- ✓ Verification script execution
- ✓ Prompt file structure
- ✓ Command naming conflicts avoided

### Platform Support
- ✓ macOS (tested)
- ✓ Linux (should work - bash script)
- ⚠️  Windows (may need WSL or Git Bash)
