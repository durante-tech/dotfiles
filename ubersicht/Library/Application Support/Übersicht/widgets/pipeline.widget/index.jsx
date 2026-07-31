// pipeline.widget — DuranteOS SDLC spine panel.
// Data source: data.sh emits one JSON object (work, prs, sync, deploy, release, now).
// Visual language: matches dailybrief.widget. Catppuccin Mocha · blue accent.
// CSS in className uses standard CSS (semicolons + braces) — Übersicht parser
// requires this, NOT Stylus indented syntax.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/pipeline.widget/data.sh"`

export const refreshFrequency = 300 * 1000 // 5 min

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// body 13px · support 11px · label 10px · micro 9px
// Palette: red #f38ba8 · yellow #f9e2af · green #a6e3a1 · blue #89b4fa
//          mauve #cba6f7 · text #cdd6f4 · muted #6c7086

export const className = `
  box-sizing: border-box;
  top: 70px;
  left: 60px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 22px 26px;
  border-radius: 16px;
  border: 1px solid rgba(137, 180, 250, 0.18);
  border-left: 4px solid #89b4fa;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
  font-size: 13px; /* body */
  line-height: 1.55;
  overflow-x: hidden;
  overflow-y: auto;

  .header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    color: #89b4fa;
    font-size: 13px; /* body — panel identity */
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 12px;
  }
  .header .title {
    display: inline-flex;
    align-items: baseline;
    gap: 8px;
  }
  .header .title .glyph {
    font-size: 13px;
    color: #89b4fa;
    opacity: 0.95;
    letter-spacing: 0;
  }
  .header .meta {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: #a6adc8;
    font-size: 10px; /* label */
    letter-spacing: 1px;
    font-weight: 500;
  }
  .header .meta .dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: #a6e3a1;
    box-shadow: 0 0 6px rgba(166, 227, 161, 0.6);
  }
  .header .meta.fresh      .dot { background: #a6e3a1; box-shadow: 0 0 6px rgba(166, 227, 161, 0.6); }
  .header .meta.stale      .dot { background: #f9e2af; box-shadow: 0 0 6px rgba(249, 226, 175, 0.6); }
  .header .meta.very-stale .dot { background: #f38ba8; box-shadow: 0 0 6px rgba(243, 139, 168, 0.6); }
  .header .meta.fresh      { color: #a6e3a1; }
  .header .meta.stale      { color: #f9e2af; }
  .header .meta.very-stale { color: #f38ba8; }

  .band {
    margin-top: 10px;
  }
  .band:first-of-type {
    margin-top: 2px;
  }
  .band-title {
    color: #cba6f7;
    font-size: 10px; /* label */
    letter-spacing: 3px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 4px;
    opacity: 0.9;
  }
  .band-title .state-badge {
    color: #f9e2af;
    letter-spacing: 1px;
    margin-left: 8px;
    font-weight: 700;
  }
  .band-title .state-badge.bad {
    color: #f38ba8;
  }

  .row {
    color: #cdd6f4;
    font-size: 11px; /* support */
    margin: 2px 0 2px 16px;
    opacity: 0.9;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row .phase {
    color: #cba6f7;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    font-size: 10px; /* label */
    margin-right: 6px;
  }
  .row .progress {
    color: #89b4fa;
    font-weight: 600;
    margin-right: 6px;
  }
  .row .age {
    color: #6c7086;
    font-size: 10px; /* label */
    margin-left: 6px;
  }
  .row .repo {
    color: #89b4fa;
    font-weight: 700;
    display: inline-block;
    min-width: 96px;
  }
  .row .num-open    { color: #cdd6f4; font-weight: 600; }
  .row .num-fail    { color: #f38ba8; font-weight: 700; }
  .row .num-green   { color: #a6e3a1; font-weight: 700; }
  .row .num-draft   { color: #6c7086; }
  .row .sep         { color: #6c7086; margin: 0 5px; }
  .row .ok          { color: #a6e3a1; font-weight: 700; }
  .row .warn        { color: #f9e2af; font-weight: 700; }
  .row .bad         { color: #f38ba8; font-weight: 700; }
  .row .muted       { color: #6c7086; }
  .row .label {
    color: #6c7086;
    text-transform: uppercase;
    letter-spacing: 1px;
    font-size: 10px; /* label */
    margin-right: 6px;
  }

  .subline {
    color: #6c7086;
    font-size: 10px; /* label */
    margin: 2px 0 0 16px;
    letter-spacing: 0.5px;
  }

  .empty {
    color: #6c7086;
    font-style: italic;
    font-size: 11px; /* support */
    margin: 2px 0 2px 16px;
  }

  .footer {
    margin-top: 14px;
    font-size: 9px; /* micro */
    color: #6c7086;
    display: flex;
    justify-content: space-between;
    letter-spacing: 1px;
    text-transform: uppercase;
  }
  .footer .brand {
    color: #89b4fa;
    opacity: 0.7;
    font-weight: 600;
  }

  .error {
    color: #f38ba8;
    font-size: 11px; /* support */
    padding: 4px 0;
  }
`

// ── freshness roll-up ───────────────────────────────────────────────────────
const overallFreshness = (data) => {
  const prsState = (data.prs || {}).state || "offline-cached"
  if (prsState === "gh-missing" || prsState === "gh-unauth") return "very-stale"
  const degraded =
    prsState !== "ok" ||
    ((data.sync || {}).state || "absent") !== "ok" ||
    ((data.deploy || {}).state || "unparseable") === "unparseable" ||
    !!(data.work || {}).error ||
    !!(data.prs || {}).error
  return degraded ? "stale" : "fresh"
}

const Header = ({ metaClass, metaText }) => (
  <div className="header">
    <span className="title">
      <span className="glyph">⛓</span>
      <span>Pipeline</span>
    </span>
    {metaText && (
      <span className={`meta ${metaClass || ""}`}>
        <span className="dot" />
        <span>{metaText}</span>
      </span>
    )}
  </div>
)

// ── stage bands ─────────────────────────────────────────────────────────────

const WorkBand = ({ work }) => {
  const items = (work && work.items) || []
  return (
    <div className="band">
      <div className="band-title">
        ► Work
        {work && work.error && <span className="state-badge bad">READ ERROR</span>}
      </div>
      {items.length === 0 && !((work || {}).error) && (
        <div className="empty">no active strategic sessions</div>
      )}
      {items.map((s, i) => (
        <div className="row" key={i}>
          <span className="phase">{s.phase}</span>
          {/* "0/0" is a session that hasn't reported criteria yet — noise, not
              progress. Only render the counter once it means something. */}
          {s.progress && s.progress !== "0/0" && (
            <span className="progress">{s.progress}</span>
          )}
          {s.task}
          <span className="age">{s.age}</span>
        </div>
      ))}
      <div className="subline">
        {(work || {}).total_active || 0} active · {(work || {}).hidden || 0} background
      </div>
    </div>
  )
}

const PRS_BADGES = {
  "gh-missing": { text: "GH MISSING", bad: true },
  "gh-unauth": { text: "GH UNAUTH", bad: true },
  "offline-cached": { text: "OFFLINE · CACHED", bad: false },
}

const PrsBand = ({ prs }) => {
  const state = (prs || {}).state || "offline-cached"
  const badge = state !== "ok" ? PRS_BADGES[state] : null
  const cacheAge = (prs || {}).cache_age
  return (
    <div className="band">
      <div className="band-title">
        ► PRs
        {badge && (
          <span className={`state-badge ${badge.bad ? "bad" : ""}`}>
            {badge.text}
            {state === "offline-cached" && cacheAge ? ` · ${cacheAge} old` : ""}
          </span>
        )}
      </div>
      {(((prs || {}).repos) || []).map((r, i) => (
        <div className="row" key={i}>
          <span className="repo">{r.name}</span>
          <span className="num-open">{r.open} open</span>
          <span className="sep">·</span>
          <span className="num-fail">{r.failing} failing</span>
          <span className="sep">·</span>
          <span className="num-green">{r.green} green</span>
          {r.draft > 0 && (
            <span>
              <span className="sep">·</span>
              <span className="num-draft">{r.draft} draft</span>
            </span>
          )}
        </div>
      ))}
      {(((prs || {}).repos) || []).length === 0 && (
        <div className="empty">no PR data</div>
      )}
    </div>
  )
}

const behindClass = (n) => (n > 0 ? "warn" : "ok")

const SyncDeployBand = ({ sync, deploy }) => {
  const s = sync || {}
  const parent = s.parent || {}
  const sub = s.submodule || {}
  const d = deploy || {}
  const deployCls =
    d.state === "manned" ? "ok" : d.state === "unmanned" ? "warn" : "muted"
  const deployText =
    d.state === "manned" ? "MANNED" : d.state === "unmanned" ? "UNMANNED" : "UNPARSEABLE"
  return (
    <div className="band">
      <div className="band-title">
        ► Sync / Deploy
        {s.state !== "ok" && <span className="state-badge">HOLD FILE ABSENT</span>}
      </div>
      {s.state === "ok" && (
        <div className="row">
          <span className="label">sync</span>
          <span className={behindClass(parent.behind)}>parent −{parent.behind}</span>
          <span className="muted"> ({parent.status})</span>
          <span className="sep">·</span>
          <span className={behindClass(sub.behind)}>sub −{sub.behind}</span>
          <span className="muted"> ({sub.status})</span>
          <span className="sep">·</span>
          <span className={sub.colliders > 0 ? "bad" : "ok"}>
            {sub.colliders} colliders
          </span>
          <span className="age">{s.age}</span>
        </div>
      )}
      <div className="row">
        <span className="label">deploy</span>
        <span className={deployCls}>{deployText}</span>
        {d.age && <span className="age">{d.age} ago</span>}
      </div>
    </div>
  )
}

const ReleaseBand = ({ release }) => (
  <div className="band">
    <div className="band-title">► Release</div>
    <div className="row">
      <span className="label">dos</span>
      <span className="ok">v{(release || {}).dos || "?"}</span>
      <span className="sep">·</span>
      <span className="label">alg</span>
      <span className="ok">v{(release || {}).algorithm || "?"}</span>
    </div>
  </div>
)

// ── render ──────────────────────────────────────────────────────────────────

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <Header metaText="loading…" />
        <div className="empty">Reading pipeline state</div>
      </div>
    )
  }

  let data
  try {
    data = JSON.parse(output)
  } catch (e) {
    return (
      <div>
        <Header metaClass="very-stale" metaText="parse error" />
        <div className="error">parse: {String(e).slice(0, 80)}</div>
      </div>
    )
  }

  const freshness = overallFreshness(data)

  return (
    <div>
      <Header metaClass={freshness} metaText={freshness} />
      <WorkBand work={data.work} />
      <PrsBand prs={data.prs} />
      <SyncDeployBand sync={data.sync} deploy={data.deploy} />
      <ReleaseBand release={data.release} />
      <div className="footer">
        <span className="brand">DOS · SDLC</span>
        <span>refreshed {data.now}</span>
      </div>
    </div>
  )
}
