---
name: threejs-visualization
description: Use when building 3D data visualizations with three.js.
category: creative
---

# three.js Interactive Visualization

Build three.js applications that visualize structured data as interactive 3D scenes. Use for mind maps, knowledge graphs, network topologies, dashboards, or any dataset that benefits from spatial exploration.

## Stack

- **three.js r0.174+** via CDN import map — no bundler, no build step, no npm install
- **Plain HTML + ES modules** — one `index.html` with import map, separate `.js` modules per concern
- **OrbitControls, CSS3DRenderer** from three.js addons
- **Serving:** Python `http.server` or FastAPI with `StaticFiles` mount

## Procedure

### 1. Scaffold

Create project structure:

```
project/
├── server/
│   └── server.py          # FastAPI + static files + API endpoints
├── static/
│   ├── index.html          # Import map, dark theme, UI overlay
│   └── js/
│       ├── main.js         # Bootstrap, fetch data, wire modules, start loop
│       ├── render.js       # Scene, camera, renderer, OrbitControls, InstancedMesh
│       ├── regions.js      # Spatial region definitions (center, radius, color)
│       ├── core.js         # Central agent anatomy (orb, shell, ring, rings)
│       ├── memory.js       # Force-directed or radial layout for node clusters
│       ├── labels.js       # CSS3D labels, hover/click interaction, raycaster
│       └── effects.js      # Search, glow pulse, ambient drift
│       └── ws.js           # WebSocket client + live pulse ring effects
└── build_graph.py          # Data assembler (reads real data sources → nodes/edges JSON)
```

### 2. Import Map (index.html)

```html
<script type="importmap">
{
  "imports": {
    "three": "https://cdn.jsdelivr.net/npm/three@0.174.0/build/three.module.js",
    "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.174.0/examples/jsm/"
  }
}
</script>
```

### 3. Scene Setup (render.js)

- `WebGLRenderer` with `antialias: true`, `alpha: false`
- `PerspectiveCamera` FOV 60, positioned at `[0, 15, 40]`
- `OrbitControls` with `enableDamping: true`, `dampingFactor: 0.05`
- Dark background: `scene.background = new THREE.Color('#0a0a0f')`
- Ambient light `0x404060` + point light at `[0, 20, 0]` `0xffffff`

### 4. Spatial Regions (regions.js)

Define named regions as `{ center: [x,y,z], radius, color, label }`. Separate regions with at least `radius * 2` gap to prevent overlap. Use distinct colors per region.

### 5. Node Rendering (render.js)

- Use `InstancedMesh` for performance — one mesh per region
- Set per-instance color via `mesh.setColorAt(index, color)`
- Set per-instance position via `dummy.position.set(x,y,z); dummy.updateMatrix(); mesh.setMatrixAt(i, matrix)`
- Register each node in `nodeMap[nodeId] = { mesh, index, region, data, position }` for raycasting
- Node scale: vary by type (core nodes 1.5–3.0, memory nodes 0.3–0.8, rim nodes 0.5)

### 6. Edge Rendering (render.js)

- Use `BufferGeometry` with `position` and `color` attributes
- Use `LineBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.5–0.7 })`
- Two color channels: semantic edges (green `#44ff88`) vs structural edges (teal `#2dd4a8`)
- **Keep vertex colors at FULL BRIGHTNESS** — let material.opacity control visibility. Never multiply vertex color by alpha; it compounds with material opacity and produces near-invisible edges.

### 7. Labels & Interaction (labels.js)

- Use `CSS3DObject` from `three/addons/renderers/CSS3DRenderer.js`
- Labels hidden by default, shown on hover via raycaster
- Raycaster: cast from mouse position, intersect InstancedMesh, look up nodeId from instanceId
- Click to pin a label (toggle pinned state)

### 8. Effects (effects.js)

- **Search:** filter nodes by query string, dim non-matching nodes, highlight matches
- **Glow pulse:** animate emissive intensity on core node with sine wave
- **Ambient drift:** slow rotation of scene or node positions for organic feel

### 8b. Live Pulse via WebSocket (ws.js)

When real-time feedback is needed (heartbeat, data changes, user activity):

**Backend (FastAPI):**
```python
import asyncio, random, time, json

async def _heartbeat_loop(app):
    """Broadcast pulse event every 4-9 seconds on a random node."""
    while True:
        await asyncio.sleep(random.uniform(4, 9))
        node = random.choice(nodes)  # pick from graph data
        event = {
            "type": "pulse",
            "node_id": node["id"],
            "color": REGION_COLORS.get(node["region"], "#2dd4a8"),
            "timestamp": time.time()
        }
        await broadcast_event(event)  # your existing WS broadcast helper

@app.on_event("startup")
async def start_heartbeat():
    app.state._hb_task = asyncio.create_task(_heartbeat_loop(app))
```

**Frontend (ws.js):**
- Connect to WebSocket endpoint (e.g., `/ws/mind`)
- On `{type:'pulse'}` event: look up node position from `getNodePositions()` Map
- Create `RingGeometry` at that position, `MeshBasicMaterial({ transparent: true, blending: THREE.AdditiveBlending, depthWrite: false })`
- Animate: ring expands + fades opacity over 1.8s, remove when opacity ≤ 0
- Three staggered rings per pulse (0ms, 400ms, 800ms delay) for depth
- Thick geometry: `RingGeometry(0.15, 0.5)` — thin rings (0.02) are invisible at distance
- Large expansion: `PULSE_MAX_SCALE = 15.0`, `PULSE_DURATION = 3.0s` — slow enough to see
- Glow sphere at origin: `SphereGeometry(0.3)` with opacity 1→0 fade over 1.8s
- Pulse counter badge (`⚡ N pulses`) in top-right corner

**Wire into main.js:**
```js
import { initPulse, updatePulses } from './ws.js';
// After data load:
initPulse();
// In render loop:
onFrame(() => { updatePulses(performance.now()); });
```

Auto-reconnect: on close, `setTimeout(connect, 3000)`.
Manual trigger endpoint: `POST /api/mind-map/pulse/{node_id}` for testing.

### 9. Post-Processing: Bloom (render.js)

Add UnrealBloomPass for the "living organ" glow effect. Requires `EffectComposer` to replace direct `renderer.render()` calls.

```js
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// In setup, after renderer:
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  1.5,    // strength — 1.0–2.0 for subtle-to-strong
  0.4,    // radius — spread of bloom
  0.6     // threshold — brightness cutoff (lower = more blooms)
);
composer.addPass(bloom);
```

In `onResize`: call `composer.setSize(w, h)` alongside `renderer.setSize(w, h)`.
In render loop: replace `renderer.render(scene, camera)` with `composer.render()`.

Export `composer` for external access if needed.

### 10. Auto-Rotate on Idle (render.js)

```js
let lastInteraction = performance.now();
let autoRotate = true;
const POKE_IDLE_MS = 12000; // 12s idle before orbit resumes
const AUTO_ROTATE_SPEED = 0.0005; // radians per frame (~0.03°/frame)

function pokeInteraction() { lastInteraction = performance.now(); }
function setAutoRotate(v) { autoRotate = v; lastInteraction = performance.now(); }
function getAutoRotate() { return autoRotate; }
```

In render loop, after controls.update():
```js
if (autoRotate && performance.now() - lastInteraction > POKE_IDLE_MS) {
  const angle = AUTO_ROTATE_SPEED;
  camera.position.applyAxisAngle(new THREE.Vector3(0, 1, 0), angle);
  camera.lookAt(controls.target);
}
```

Reset timer on `pointermove`, `pointerdown`, `keydown` in main.js via `pokeInteraction()`.

### 11. Hover Scale on InstancedMesh (render.js)

Scale hovered node up via instance matrix lerp (not uniform — instanced meshes don't support uniform scale per instance).

**Requires O(1) reverse lookup** (see §14). Raycast → intersection.instanceId → lookup Map → nodeId.

```js
let hoveredNodeId = null;
const HOVER_SCALE_MIN = 1.0;
const HOVER_SCALE_MAX = 1.35;
const HOVER_LERP = 0.02; // per frame
const nodeScales = new Map(); // nodeId → current scale

function updateHoverScale(raycastTargets) {
  // Raycast, find hovered node via instanceLookup
  // Set hoveredNodeId
  // For each node: lerp scale toward HOVER_SCALE_MAX (if hovered) or HOVER_SCALE_MIN
  // Apply via dummy.scale.set(s, s, s); dummy.updateMatrix(); mesh.setMatrixAt(i, matrix)
  // mesh.instanceMatrix.needsUpdate = true;
}
```

### 12. Camera Fly-To on Click (render.js)

Smooth camera LERP to a target position. Do NOT use TWEEN or external libs — plain Vector3.lerp in the render loop.

```js
const FLY_SPEED = 0.08; // alpha per frame — higher = faster
let flyTarget = { pos: null, lookAt: null }; // null = no active fly

function flyToPosition(pos, lookAtOffsetY = 2) {
  flyTarget.pos = pos.clone().add(new THREE.Vector3(5, 3, 5)); // offset so node isn't centered
  flyTarget.lookAt = pos.clone().add(new THREE.Vector3(0, lookAtOffsetY, 0));
}

// In render loop:
if (flyTarget.pos) {
  camera.position.lerp(flyTarget.pos, FLY_SPEED);
  controls.target.lerp(flyTarget.lookAt, FLY_SPEED);
  // Stop when close enough
  if (camera.position.distanceTo(flyTarget.pos) < 0.1) flyTarget = { pos: null, lookAt: null };
  lastInteraction = performance.now(); // suppress auto-rotate during fly
}
```

Wire click handler in `labels.js`: import `flyToPosition` and `getInstanceLookup`, on click → `flyToPosition(node.position)`.

### 13. Keyboard Shortcuts (main.js)

```js
document.addEventListener('keydown', (e) => {
  if (e.target.tagName === 'INPUT') return; // skip when search focused
  switch (e.key) {
    case '/': e.preventDefault(); showSearch(); break;
    case 'r': case 'R': resetCamera(); break;
    case ' ': e.preventDefault(); toggleAutoRotate(); break;
    case '?': toggleHelpOverlay(); break;
    case 'Escape': closeHelp(); blurSearch(); break;
  }
});
```

### 14. O(1) Reverse Lookup (render.js)

Critical for hover, click, and search on instanced meshes. Build at instance creation time.

```js
const instanceLookup = new Map(); // `mesh.uuid_instanceIndex` → nodeId

// In placeNodes(), after setting matrix at index i:
instanceLookup.set(`${mesh.uuid}_${i}`, nodeId);

function getInstanceLookup() { return instanceLookup; }
```

All consumers (labels.js, effects.js, ws.js) import `getInstanceLookup` and use it for O(1) node finding instead of scanning all nodes per frame.

### 15. Loading Animation (index.html)

Show a CSS-only loading indicator while the API fetches. Hide it after data arrives.

```html
<div id="loading">
  <div class="brain"></div>
  <div class="text">loading mind…</div>
</div>
```

```css
#loading { position: fixed; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #0a0a0a; z-index: 1000; }
#loading .brain {
  width: 64px; height: 64px; border-radius: 50%;
  background: radial-gradient(circle, #2dd4a8, #7B61FF);
  animation: pulse 1.5s ease-in-out infinite;
}
@keyframes pulse { 0%, 100% { transform: scale(1); opacity: 0.8; } 50% { transform: scale(1.2); opacity: 1; } }
```

In `main.js` after data loads: `document.getElementById('loading').style.display = 'none';`

### 16. Core Anatomy (core.js)

Build the central agent visualization:
- **Agent orb:** `SphereGeometry` with emissive material, teal color
- **Knowledge shell:** `IcosahedronGeometry` wireframe around the orb — opacity 0.3+, emissive 0.1+, or it disappears against dark backgrounds
- **Tool ring:** `TorusGeometry` at agent equator, golden color, slowly rotating
- **Prompt rings:** smaller tori at different angles, representing active prompts

### 10. Data Assembly (build_graph.py)

Read from real data sources (databases, config files, session logs). Each node needs:
- `id`, `label`, `region`, `group` (sub-type within region), `type` (visual category)
- Optional: `content` (full text for detail panel), `weight` (importance)

Each edge needs:
- `source`, `target`, `type` (semantic | structural), `weight` (0–1)

## Pitfalls

- **`LineBasicMaterial` ignores per-vertex alpha on many GPUs.** Set alpha on the material, not per-vertex. Use vertex colors for hue, material opacity for brightness.
- **`CSS3DRenderer` and `WebGLRenderer` must share the same camera and be overlaid with CSS.** The CSS3D canvas sits on top with `pointer-events: none`; labels get `pointer-events: auto`.
- **Raycasting InstancedMesh:** use `intersection.instanceId` (not `mesh.geometry.index`) to get the instance index. Then look up the nodeId via the O(1) `instanceLookup` Map (§14). Without the reverse lookup, you'd need to scan all nodes to find which one matches the instanceId.
- **Bloom threshold too low:** threshold < 0.4 makes everything glow (including edges and background). Start at 0.6 and lower only if nodes aren't blooming. Strength > 2.0 washes out colors.
- **Auto-rotate fights user:** if auto-rotate resumes while user is still orbiting, it's because `pokeInteraction()` isn't called on all pointer/keyboard events. Wire it to `pointermove`, `pointerdown`, `wheel`, and `keydown` — not just `click`.
- **Hover scale on instanced meshes requires instance matrix update.** After changing `dummy.scale`, call `dummy.updateMatrix()`, `mesh.setMatrixAt(i, dummy.matrix)`, and `mesh.instanceMatrix.needsUpdate = true`. Missing the `needsUpdate` flag means no visual change.
- **Fly-to without suppressing auto-rotate** causes camera to orbit away mid-flight. Set `lastInteraction = performance.now()` inside the fly-to update to keep idle timer reset.
- **O(1) lookup must be built at instance creation, not lazily.** If you build the Map after `initPulse()` or `initSearch()`, those modules' first calls will find an empty Map. Build in `placeNodes()` and export via getter.
- **Force-directed layout:** use `new THREE.Vector3()` (not `THREE.Vector3`), normalize direction vectors in repulsion loop, cap max force to prevent explosion. For high-density groups (100+ same-type nodes), force-directed produces a hairball — switch to full-360° concentric rings (spread ALL nodes evenly around the circle across multiple rings). Radial arcs grouped by type LOOK correct but fail at 100+ nodes because each group only gets a fraction of the circle, packing tighter than force-directed.
- **Edge color dimming:** NEVER multiply vertex color by alpha before passing to the material. `col.clone().multiplyScalar(alpha)` + `material.opacity: 0.65` compounds to near-invisible edges. Keep vertex colors at full brightness; let material.opacity alone control visibility.
- **Knowledge shell invisible:** opacity < 0.25 and emissive < 0.10 disappear against dark backgrounds. Minimum: opacity 0.35, emissiveIntensity 0.15.
- **Position initialization in render.js** sets initial positions per region. Default is random spherical; for high-density regions (100+ nodes), use full-360° concentric rings with per-ring angle offset. For small groups (<30 per type), radial arcs grouped by `node.group` work. If you reorder nodes (e.g., by grouping), set `ITERATIONS = 0` in memory.js to avoid position-index mismatch with force-directed code.
- **Search bar UX pattern:** use `opacity: 0; pointer-events: none` by default, toggle visible on keypress (e.g., `/`). Place at `top: 60px` to avoid browser chrome overlap.
- **Server dies between sessions:** FastAPI/uvicorn started in background may exit when the terminal session ends. Restart before each review: `lsof -ti:PORT | xargs kill -9 2>/dev/null; cd project && venv_python -m uvicorn server.server:app --host 127.0.0.1 --port PORT`. Verify with `curl -s -m 5 -o /dev/null -w "%{http_code}" http://127.0.0.1:PORT/`.
- **Import map is only for bare specifiers.** Local ES modules (`./ws.js`, `./render.js`) use relative paths — they do NOT need import map entries. Only `three` and `three/addons/` go in the import map.
- **Cross-module data access uses getter functions, not direct exports.** When module A needs data from module B (e.g., `ws.js` needs node positions from `render.js`), export a getter function (`getNodePositions()`) that builds a copy from internal state. Don't export internal Maps directly — they may not be populated at import time.
- **`getNodePositions()` must build from `nodeMap`, not a separate parallel map.** If `render.js` already tracks positions in `nodeMap[id].position`, derive from that rather than maintaining a second Map that drifts out of sync.

## Tier Progression

Build tier-by-tier. Each tier must render correctly before starting the next.

| Tier | What | Verification |
|------|------|-------------|
| 0 | Plan: agent name, accent color, server architecture, embeddings strategy | User approves |
| 1 | Backend: data assembly API → `GET /api/mind-map` returns nodes + edges + regions | curl returns valid JSON |
| 2 | Frontend: scene + InstancedMesh rendering all nodes in correct regions | Nodes visible, orbitable |
| 3 | Core anatomy: agent orb + shell + tool ring + prompt rings | Central structure visible |
| 4 | Labels: CSS3D hover/click labels showing real node data | Hover shows label |
| 5 | Effects: search bar + glow pulse + ambient drift | Search filters nodes |
| 6 | Live: WebSocket pulse — backend heartbeat poller + frontend expanding rings + pulse counter | Auto-pulses visible every 4–9s, counter increments |
| 7 | Polish: bloom, auto-rotate, hover scale, fly-to, keyboard shortcuts, O(1) lookup | Bloom visible, idle orbit works, hover scales nodes, click flies camera, keyboard shortcuts work |

## References

- `references/force-layout.md` — Force-directed and radial layout tuning parameters
- `references/visibility-tuning.md` — Dark-background visibility rules and alpha math