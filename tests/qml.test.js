import assert from "node:assert/strict"
import { readdirSync, readFileSync } from "node:fs"

// Qt 6.12's QtQuick exports its own `Color`, which wins an unqualified lookup
// and turns Omarchy theme colours into undefined (ADR 11). Plugin QML must say
// `Commons.Color.x`.
const root = new URL("../", import.meta.url)
const files = readdirSync(root).filter(name => name.endsWith(".qml"))
assert.ok(files.length > 0, "expected QML files at the plugin root")
for (const file of files) {
  const source = readFileSync(new URL(file, root), "utf8")
  const bare = source.split("\n")
    .map((line, index) => ({ line, number: index + 1 }))
    .filter(({ line }) => /(^|[^.\w])Color\.[a-z]/.test(line))
  assert.deepEqual(bare.map(({ number }) => `${file}:${number}`), [], `${file} uses a bare Color.x; write Commons.Color.x`)
}
console.log(`QML tests passed (${files.length} QML files, no bare Color)`)
