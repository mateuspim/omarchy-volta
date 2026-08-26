import assert from "node:assert/strict"
import fs from "node:fs"
import vm from "node:vm"

const source = fs.readFileSync(new URL("../Model.js", import.meta.url), "utf8")
  .replace(/^\.pragma library\s*/m, "")
const model = {}
vm.runInNewContext(source + "\nObject.assign(model, { clamp, clampVolume, percent, channelName, parseSinkAvailability, stereoIndices, readStereo, withStereoVolumes, balance, applyBalance, balanceLabel, safeSinkText, sinkLabel });", { model, isFinite })

assert.equal(model.clampVolume(-1), 0)
assert.equal(model.clampVolume(2), 1.5)
assert.equal(model.percent(1.234), "123%")
assert.deepEqual({ ...model.parseSinkAvailability("sink.a\t1\nsink.b\t0\n") }, { "sink.a": true, "sink.b": false })

const fixture = name => JSON.parse(fs.readFileSync(new URL(`fixtures/${name}.json`, import.meta.url), "utf8"))
const stereoFixture = fixture("stereo")
const monoFixture = fixture("mono")
const surroundFixture = fixture("surround")
const channels = stereoFixture.channels
assert.deepEqual({ ...model.stereoIndices(channels) }, { left: 0, right: 1, mono: -1 })
assert.deepEqual({ ...model.stereoIndices(["PwAudioChannel.FrontRight", "PwAudioChannel.FrontLeft"]) }, { left: 1, right: 0, mono: -1 })

const stereo = model.readStereo(channels, stereoFixture.volumes)
assert.equal(stereo.supported, true)
assert.equal(stereo.left, 0.65)
assert.equal(stereo.right, 0.8)
assert.equal(model.readStereo(monoFixture.channels, monoFixture.volumes).mono, true)
assert.equal(model.readStereo(surroundFixture.channels, surroundFixture.volumes).supported, true)
assert.equal(model.readStereo(["RearLeft", "RearRight"], [1, 1]).supported, false)

assert.deepEqual(Array.from(model.withStereoVolumes([0.2, 0.3, 0.4], 0, 2, 2, -1)), [1.5, 0.3, 0])
assert.equal(model.balance(1, 1), 0)
assert.equal(model.balance(0.5, 1), 0.5)
assert.equal(model.balance(1, 0.25), -0.75)
assert.deepEqual({ ...model.applyBalance(0.2, 0.8, 0) }, { left: 0.8, right: 0.8 })
assert.deepEqual({ ...model.applyBalance(1, 1, -0.5) }, { left: 1, right: 0.5 })
assert.deepEqual({ ...model.applyBalance(0, 0, 0.5) }, { left: 0, right: 0 })
assert.equal(model.balanceLabel(0), "Center")
assert.equal(model.balanceLabel(-0.42), "42% left")
assert.equal(model.sinkLabel({ description: "Speakers" }), "Speakers")
assert.equal(model.sinkLabel({ description: "", nickname: "Headphones" }), "Headphones")
assert.equal(model.sinkLabel({ description: '<img src="file:///etc/passwd"> & speakers' }), '&lt;img src="file:///etc/passwd"&gt; &amp; speakers')
assert.equal(model.sinkLabel({ description: '<img src="https://example.com/pixel">' }).includes("<"), false)
assert.equal(model.safeSinkText("x".repeat(200)).length, 160)

console.log("Model tests passed")
