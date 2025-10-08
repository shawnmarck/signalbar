# Agent Guidelines for signalbar

## Build/Test Commands
- Build: `npm run build` or `yarn build`
- Test: `npm test` or `yarn test`
- Single test: `npm test -- --testNamePattern="testName"` or `yarn test testName`
- Lint: `npm run lint` or `yarn lint`
- Type check: `npm run typecheck` or `yarn typecheck`

## Code Style Guidelines
- Use ES6+ imports/exports, avoid default exports
- Follow existing naming conventions (camelCase for variables, PascalCase for components)
- Use TypeScript for type safety
- Handle errors with try/catch blocks and proper error types
- Format code with Prettier (if configured)
- Keep functions small and focused
- Add meaningful variable names, avoid abbreviations
- Use async/await instead of Promise chains
- Follow existing file structure and patterns in the codebase