
## 2026-08-28 19:00 — BLAVAAN PARAMETER SYNTAX FIX (B-11)

**Issue**: Phase 11-14 Full SEM implementation using blavaan had wrong parameter names

**Root Cause**: blavaan API documentation not consulted; assumed R's usual naming conventions

**Wrong Parameters** (from Phase 11-14 code):
- `n.iter = 6000` ← WRONG
- `n.burnin = 3000` ← WRONG  
- `n.adapt = 1000` ← WRONG

**Correct Parameters** (per `help(blavaan)`):
- `sample = 6000` ← number of post-burnin samples per chain
- `burnin = 3000` ← number of burnin/warmup iterations
- `adapt = 1000` ← adaptive iterations (for JAGS; ignored by Stan target)
- `n.chains = 4` ← number of MCMC chains ✓ (was already correct)

**Solution Applied**:
1. Consulted actual blavaan function signature via `help(blavaan)`
2. Updated all 3 blavaan/bcfa calls in AUDIT_RIGOROUS_PHASE_11_14_FULL_SEM.R
3. Added explicit `target = "stan"` for clarity
4. Commit: 967f4f3

**Status**: Full SEM now executing successfully (started 18:40 UTC, still running at 19:13 UTC)

---

