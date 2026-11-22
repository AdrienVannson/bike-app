This is a monorepo of a project to display bike rides from users (uploaded directly or from the garmin api). It has a frontend (react, vite) and a backend (on aws).

Agents shouldn't sign commit. Only the human contributor is responsible for the work.

Don't update AGENTS.md yourself.

As much as possible, CI should just call pnpm commands (it must be easy to reproduce ci locally).

## Testing strategy

This is an AWS-based application. Testing it locally isn't reasonnable. Emulation
has differences with real AWS. Everything is tested against a real AWS instance.
The environments are:

- `dev` for development, tests, experiments, etc. THIS IS THE ONLY ENVIRONMENT
  AGENTS CAN USE.
- `test` for CI tests.
- `prod`
