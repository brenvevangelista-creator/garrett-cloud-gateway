# Force-Directed Layout Tuning

## Parameters by Node Count

| Nodes | Iterations | Repulsion | Radius | Expected Result |
|-------|------------|-----------|--------|-----------------|
| 1–20 | 30 | 200 | 100 | Tight cluster |
| 20–100 | 50 | 500 | 300 | Moderate spread |
| 100–300 | 80–100 | 1500–2000 | 50–80 | Wide spread |
| 300+ | 100+ | 2000+ | 80+ | Consider radial layout |

## Region Radius Scaling

Region radius must scale with node count. A radius that works for 10 nodes will produce a hairball at 100+.

| Node Count | Minimum Radius | Notes |
|------------|----------------|-------|
| 1–20 | 2–3 | Tight cluster OK |
| 20–50 | 4–6 | Moderate spread |
| 50–100 | 8–10 | Needs breathing room |
| 100–200 | 12–15 | Radial layout required |
| 200+ | 15+ | Multiple concentric rings |

When increasing region radius, also:
- Move camera farther back (multiply by 1.5–2×)
- Reduce fog density (divide by 2×)
- Increase far plane (multiply by 2–3×)

## Radial Arc Layout (for high-density groups)

When a single region has 50+ nodes, force-directed produces a hairball. Two approaches:

### Approach A: Full 360° Concentric Rings (recommended for 100+ nodes)

Spread ALL nodes evenly around the full circle across multiple concentric rings. Each ring is offset by `1/ringCount` of the angle to prevent radial alignment.

```js
const totalNodes = nodes.length;
const ringCount = 3;
const ringRadii = [0.3, 0.6, 1.0]; // fraction of region radius

nodes.forEach((n, i) => {
  const ringIdx = i % ringCount;
  const ringStart = (ringIdx / ringCount) * Math.PI * 2;
  const nodesPerRing = Math.ceil(totalNodes / ringCount);
  const posInRing = Math.floor(i / ringCount);
  const r = reg.radius * ringRadii[ringIdx];
  const angle = ringStart + (posInRing / nodesPerRing) * Math.PI * 2;
  const y = (i * 0.618 * reg.radius * 0.15) % (reg.radius * 0.3) - reg.radius * 0.15;

  positions.push(new THREE.Vector3(
    reg.center[0] + Math.cos(angle) * r,
    reg.center[1] + y,
    reg.center[2] + Math.sin(angle) * r
  ));
});
```

Spacing per ring (circumference / nodesPerRing):
- Ring 1 (0.3×radius): smallest circumference, tightest spacing
- Ring 3 (1.0×radius): largest circumference, most breathing room

For 175 nodes at radius 15: ring 1 has ~0.5 units between nodes, ring 3 has ~1.6 units. Both legible.

### Approach B: Radial Arcs Grouped by Type (for <100 nodes with distinct groups)

When groups are small (<30 nodes each) and visual grouping by type matters more than even spacing:

```js
const groups = {};
nodes.forEach(n => { (groups[n.group] ??= []).push(n); });

const groupKeys = Object.keys(groups);
const arcPerGroup = (Math.PI * 2) / groupKeys.length;

groupKeys.forEach((key, gi) => {
  const gNodes = groups[key];
  const angleStart = gi * arcPerGroup;
  const rings = Math.ceil(gNodes.length / 20);
  gNodes.forEach((n, i) => {
    const ring = i % rings;
    const r = reg.radius * (0.2 + ring * 0.25);
    const angle = angleStart + (i / gNodes.length) * arcPerGroup * 0.75;
    const y = (i * 0.618 * reg.radius * 0.15) % (reg.radius * 0.3) - reg.radius * 0.15;
    positions.push(new THREE.Vector3(
      reg.center[0] + Math.cos(angle) * r,
      reg.center[1] + y,
      reg.center[2] + Math.sin(angle) * r
    ));
  });
});
```

**Do NOT use Approach B for 100+ nodes.** Each group gets `360° / numGroups` of arc — with 5+ groups and 30+ nodes per group, nodes pack tighter than force-directed. This was the trap: the code looks like it should spread nodes, but each group only gets a fraction of the circle.

### Common Rules

- Golden ratio (0.618) for Y-spread creates nice vertical distribution without planar clustering
- Set `ITERATIONS = 0` in memory.js when using computed layout — force-directed will fight the initial positions
- Region radius must match node count (see table above)
- When scene grows, adjust camera/fog/far plane (see references/visibility-tuning.md)

## Key Pitfalls

- Normalize direction vectors in repulsion loop or nodes collapse to one corner
- Cap max force (50) to prevent position explosion
- `new THREE.Vector3()` not `THREE.Vector3` (constructor vs class)
- Initial positions must use `Math.random()` for variation, not fixed values
- Memory.js reads `regionMeshes['memory'].positions` by index — if render.js reorders nodes (e.g., by grouping), the indices must match or force-directed applies forces to wrong nodes
- **Region radius too small:** if nodes bunch despite good layout, check radius first — it's the most common cause
- **Camera/fog mismatch:** when scene grows, camera must move back and fog must thin or nodes vanish into fog
