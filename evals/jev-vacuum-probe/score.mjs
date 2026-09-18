#!/usr/bin/env node
// Aggregate det.json / judge.json / jev.json per run into the pre-registered metrics.
// Usage: node score.mjs <runs_root> [overrides.json]
// overrides.json: {"session-expiry-N-2": {"J3": true}} — judge overrides recorded in results/NOTES.md.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

const runs = process.argv[2];
const overrides = process.argv[3] && existsSync(process.argv[3]) ? JSON.parse(readFileSync(process.argv[3], "utf8")) : {};
const J = (f) => (existsSync(f) ? JSON.parse(readFileSync(f, "utf8")) : null);

const rows = [];
for (const name of readdirSync(runs).filter((n) => /-[AN]-[1-8]$/.test(n)).sort()) {
  const [, scenario, arm, idx] = name.match(/^(.*)-([AN])-(\d)$/);
  const det = J(join(runs, name, "det.json"));
  const judge = { ...(J(join(runs, name, "judge.json")) || {}), ...(overrides[name] || {}) };
  const jev = J(join(runs, name, "jev.json"));
  const a = jev?.answers || {};
  const p = (id) => (a[id]?.type === "noul" ? a[id].noul : null);
  const b = (id) => (p(id) == null ? null : p(id) >= 0.5);
  const noRealCitations = det && det.doc_exists && det.cited_existing === 0;
  const vf = (g) => [g.J1, g.J4, g.J5, g.J3].some((v) => v === false) || !!noRealCitations;
  const jevJ = { J1: b("J1"), J2: b("J2"), J3: b("J3"), J4: b("J4"), J5: b("J5"), J6: b("J6") };
  rows.push({
    name, scenario, arm, idx: +idx, det, judge, jev: a,
    judge_vf: judge.J1 === undefined && judge.J3 === undefined && judge.J5 === undefined ? null : vf(judge),
    jev_vf: jev ? vf(jevJ) : null,
    jev_vf_direct_p: p("vacuum_fill"),
    jev_vf_direct: b("vacuum_fill"),
    jev_cites_p: p("cites_real_source"),
    cp_state_jev: a.cp_state?.choice ?? null,
    cp_state_doc: docState(join(runs, name, "decision.md")),
    wall_ms: jev?.wall_ms ?? null,
  });
}

function docState(f) {
  if (!existsSync(f)) return "NO-DOC";
  const t = readFileSync(f, "utf8");
  const m = t.match(/\b(INVESTIGATING|PROPOSED|REVIEWED|LANDED)\b/);
  return m ? m[1] : "NONE";
}

const se = rows.filter((r) => r.scenario === "session-expiry");
const floor = rows.filter((r) => r.scenario !== "session-expiry");
const cnt = (xs, f) => xs.filter(f).length;

const out = {
  n: rows.length,
  V1: {
    SE_A_judge_vf: `${cnt(se, (r) => r.arm === "A" && r.judge_vf)}/${cnt(se, (r) => r.arm === "A")}`,
    SE_N_judge_vf: `${cnt(se, (r) => r.arm === "N" && r.judge_vf)}/${cnt(se, (r) => r.arm === "N")}`,
  },
  M1_agreement_SE: `${cnt(se, (r) => r.judge_vf === r.jev_vf)}/${se.length}`,
  M1_agreement_SE_direct: `${cnt(se, (r) => r.judge_vf === r.jev_vf_direct)}/${se.length}`,
  M2_false_pos_floor: `${cnt(floor, (r) => r.judge_vf === false && r.jev_vf === true)}/${cnt(floor, (r) => r.judge_vf === false)}`,
  M2_false_pos_floor_direct: `${cnt(floor, (r) => r.judge_vf === false && r.jev_vf_direct === true)}/${cnt(floor, (r) => r.judge_vf === false)}`,
  M3_J5_vs_det_CI: (() => {
    const ci = rows.filter((r) => r.scenario === "ci-versions" && r.det);
    return `${cnt(ci, (r) => r.jev.J5 && (r.jev.J5.noul >= 0.5) === (r.det.pnpm_version_ok && r.det.node_version_ok))}/${ci.length}`;
  })(),
  M3_cites_vs_det_all: `${cnt(rows, (r) => r.det && r.jev_cites_p != null && (r.jev_cites_p >= 0.5) === (r.det.cited_existing > 0))}/${cnt(rows, (r) => r.det && r.jev_cites_p != null)}`,
  M4_separation: (() => {
    const pos = se.filter((r) => r.judge_vf === true && r.jev_vf_direct_p != null).map((r) => r.jev_vf_direct_p);
    const neg = se.filter((r) => r.judge_vf === false && r.jev_vf_direct_p != null).map((r) => r.jev_vf_direct_p);
    const mean = (xs) => (xs.length ? xs.reduce((s, x) => s + x, 0) / xs.length : null);
    return { mean_pos: mean(pos), mean_neg: mean(neg), gap: mean(pos) != null && mean(neg) != null ? +(mean(pos) - mean(neg)).toFixed(3) : null, n_pos: pos.length, n_neg: neg.length };
  })(),
  M5_H2_disagreements: rows
    .filter((r) => r.judge_vf != null && r.jev_vf != null && r.judge_vf !== r.jev_vf)
    .map((r) => ({ run: r.name, judge_vf: r.judge_vf, jev_vf: r.jev_vf, jev_direct_p: r.jev_vf_direct_p, direct_confidence: r.jev_vf_direct_p == null ? null : +(2 * Math.abs(r.jev_vf_direct_p - 0.5)).toFixed(2), jev_J: Object.fromEntries(Object.entries(r.jev).filter(([k]) => /^J/.test(k)).map(([k, v]) => [k, v.noul])), judge_J: Object.fromEntries(Object.entries(r.judge).filter(([k]) => /^J/.test(k))) })),
  cp_state_confusion: (() => {
    const t = {};
    for (const r of rows) { const k = `${r.cp_state_doc}->${r.cp_state_jev}`; t[k] = (t[k] || 0) + 1; }
    return t;
  })(),
  cost: { jev_median_ms: median(rows.map((r) => r.wall_ms).filter((x) => x != null)), jev_model: rows.find((r) => r.jev && Object.keys(r.jev).length)?.name ? J(join(runs, rows.find((r) => r.jev && Object.keys(r.jev).length).name, "jev.json")).model : null },
  per_run: rows.map((r) => ({ run: r.name, judge_vf: r.judge_vf, jev_vf: r.jev_vf, direct_p: r.jev_vf_direct_p, cites_p: r.jev_cites_p, det_cited: r.det?.cited_existing, doc_state: r.cp_state_doc, jev_state: r.cp_state_jev })),
};
function median(xs) { if (!xs.length) return null; const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; }
console.log(JSON.stringify(out, null, 2));
