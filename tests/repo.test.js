import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { statSync } from "node:fs"
import { fileURLToPath } from "node:url"

// `omarchy plugin add` clones every tracked file into the user's plugin
// directory, and coding agents load these files automatically from the
// directory they run in and its parents/children. Tracking one would put the
// contributor rules into ordinary installs (ADR 15); contributors opt in with
// scripts/dev-setup instead.
const root = fileURLToPath(new URL("../", import.meta.url))
const git = (...args) => execFileSync("git", ["-C", root, ...args], { encoding: "utf8" })

const discoveredNames = [
  "agents.md", "agents.override.md", "claude.md", "claude.local.md",
  "gemini.md", ".cursorrules", ".windsurfrules", ".clinerules", ".goosehints",
]
const discoveredDirs = [".claude", ".cursor", ".windsurf", ".clinerules", ".gemini", ".codex"]
const discoveredPaths = [".github/copilot-instructions.md", ".github/instructions/"]

function isAutoDiscovered(path) {
  const parts = path.toLowerCase().split("/")
  if (discoveredNames.includes(parts[parts.length - 1])) return true
  if (parts.slice(0, -1).some(part => discoveredDirs.includes(part))) return true
  return discoveredPaths.some(prefix => path.toLowerCase().startsWith(prefix))
}

assert.equal(isAutoDiscovered("AGENTS.md"), true)
assert.equal(isAutoDiscovered("tests/CLAUDE.md"), true)
assert.equal(isAutoDiscovered(".claude/settings.json"), true)
assert.equal(isAutoDiscovered(".github/copilot-instructions.md"), true)
assert.equal(isAutoDiscovered("docs/contributing/agent-instructions.md"), false)
assert.equal(isAutoDiscovered(".github/workflows/test.yml"), false)

const tracked = git("ls-files", "-z").split("\0").filter(Boolean)
assert.ok(tracked.length > 0, "expected tracked files; run the tests from a git checkout")
assert.deepEqual(tracked.filter(isAutoDiscovered), [], "tracked files that coding agents auto-load; see ADR 15")

for (const file of ["AGENTS.md", "CLAUDE.md"]) {
  assert.doesNotThrow(() => git("check-ignore", "-q", "--no-index", file), `${file} must be gitignored (ADR 15)`)
}

assert.ok(tracked.includes("docs/contributing/agent-instructions.md"), "agent instructions moved or missing")
assert.ok(statSync(`${root}scripts/dev-setup`).mode & 0o111, "scripts/dev-setup must be executable")

console.log(`Repo tests passed (${tracked.length} tracked files, none auto-loaded by agents)`)
