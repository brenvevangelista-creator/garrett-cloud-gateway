# Visibility Tuning on Dark Backgrounds

## The Problem

three.js multiplies: `finalColor = vertexColor * materialOpacity * alpha`. Three multiplications compound fast on dark backgrounds (#000–#111).

## Rules

1. **Minimum opacity for visibility:** material opacity ≥ 0.35 on dark backgrounds. Below 0.25, objects disappear.

2. **Minimum emissive for glowing objects:** emissiveIntensity ≥ 0.15. Below 0.10, the glow is invisible against dark.

3. **Edge alpha math:**
   - Semantic edges: `0.25 + weight * 0.4` → range [0.25, 0.65]
   - Structural edges: `0.15` flat
   - Material opacity: 0.6–0.7
   - **NEVER multiply vertex color by alpha** — `col.clone().multiplyScalar(alpha)` + material.opacity 0.65 compounds to near-invisible. Keep vertex colors at full brightness; material.opacity alone controls visibility.

4. **LineBasicMaterial ignores per-vertex alpha on many GPUs.** Set alpha on the material, not per-vertex. Use vertex colors for hue, material opacity for brightness.

5. **Knowledge shell minimums:** opacity 0.35, emissiveIntensity 0.15, vertex count ≥ 4 (IcosahedronGeometry detail 2+). Below these, it's invisible.

6. **Search bar UX:** hidden by default (`opacity: 0; pointer-events: none`), toggled by keypress (e.g., `/`). Place at `top: 60px` to avoid browser chrome overlap. Use `z-index: 1000` to ensure visibility over canvas.

7. **Node scale minimums:**
   - Core: 1.5–3.0
   - Memory: 0.3–0.8
   - Rim: 0.5+ (below 0.3, invisible)
   - Working: 0.4–0.6

8. **Color on dark backgrounds:**
   - Avoid pure white (#ffffff) — too harsh
   - Prefer muted brights: teal #2dd4a8, cyan #00ffcc, amber #ffaa00
   - Use emissive materials, not just color, for glow effect
   - **Structural edge color:** `0x333355` is too dark. Use `0x6666AA` or brighter.

9. **Server dies between sessions:** FastAPI/uvicorn in background may exit when terminal session ends. Restart before each review: `kill $(lsof -ti:PORT) 2>/dev/null; cd project && python -m uvicorn server.server:app --host 127.0.0.1 --port PORT &`

10. **Camera/fog scaling when scene grows:**
   - If region radii increase, camera Z must increase proportionally (1.5–2×)
   - Fog density must decrease (divide by 2×) or distant nodes vanish
   - Far plane must cover the scene (2× max scene extent)
   - Example: radius 5→15 means camera Z 20→35, fog 0.015→0.008, far 200→500
