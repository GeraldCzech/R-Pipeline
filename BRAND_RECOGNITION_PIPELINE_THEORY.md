# Brand Recognition Pipeline & Awareness Hierarchy

## Brand Equity Building Sequence

**Classical brand equity progression (most marketing models):**

1. **AWARENESS** (Entry point)
   - Unaided awareness → Aided awareness → Top-of-mind
   - "Do you know this brand?"
   - Foundation: consumer must know the brand exists

2. **ASSOCIATION/PERCEPTION** (Second stage)
   - Brand image, beliefs, attributes
   - "What do you think of this brand?"
   - Faircloth: Brand Resonance, Distinctiveness
   - Boenigk: Trust, Connection

3. **QUALITY/FUNCTIONALITY** (Third stage)
   - Perceived value, benefits
   - "Does this brand deliver what it promises?"
   - FC: Brand Functionality
   - BO: Brand Functionality

4. **LOYALTY/PREFERENCE** (Final stage)
   - Behavioral: repeated purchase/donation
   - "Would you choose this brand again?"
   - Outcome: actual donation behavior

---

## In Your Data Structure:

### FAIRCLOTH 3-Factor Model (without awareness)
```
1st: FC_BR (Brand Resonance)     → Emotional connection
2nd: FC_BD (Brand Distinctiveness) → Differentiation  
3rd: FC_BF (Brand Functionality)  → Utility/Benefits
     ↓
Higher-order: Brand Equity
     ↓
Donation behavior
```

### BOENIGK 3-Factor Model (without awareness)
```
1st: BO_TR (Trust)           → Reliability
2nd: BO_CO (Connection)      → Relationship
3rd: BO_BF (Functionality)   → Benefits
     ↓
Higher-order: Brand Equity
     ↓
Donation behavior
```

---

## Recognition as SEPARATE Pipeline Entry

Your insight with **RC_Awareness (3-level ordinal)** suggests a **PARALLEL pathway**:

```
AWARENESS PATHWAY          EQUITY PATHWAY
    ↓                          ↓
RC_Awareness (3-level)    Brand Equity (measurement)
    ↓                          ↓
[Direct effect on behavior]    ↓
    ├─────────────────────────┤
           Donation Behavior
```

**Key question:** Does awareness act as a **"gate"** or **"amplifier"**?
- **Gate:** You must be aware (no donation without awareness)
- **Amplifier:** High awareness strengthens BE→Donation relationship

---

## Chathopoulos Network Question

**Chathopoulos et al. (2012)** brand equity network model typically specifies:

```
Awareness → Associations → Perceived Quality → Loyalty
     ↓              ↓              ↓              ↓
  Stage 1       Stage 2        Stage 3       Stage 4
(Foundation)  (Perception)   (Functionality) (Behavior)
```

**For NGOs (your context):**
```
Awareness of Cause   →  Beliefs about NGO    →  Trust in Mission  →  Donation
(Problem awareness)     (NGO reputation)        (Capability)         (Action)
```

---

## Mapping Your Data to Pipeline

### You have:
- **Awareness measure:** RC_Awareness (ordinal 3-level) ✓
- **Association measures:** FC_BR, BO_TR, BO_CO (brand perception) ✓
- **Quality measures:** FC_BF, BO_BF (functionality) ✓
- **Loyalty/Behavior:** OF02_01/02/03, OF_Spender ✓

### Structure possibility:
```
RC_Awareness 
     ↓
   [Awareness Gate - prerequisite]
     ↓
Brand Equity (FC/BO measurement)
     ↓
Donation Behavior (OF outcomes)
```

---

## Recommendation for Chathopoulos-Style Network

**4-Stage Sequential Model:**
```
1. Awareness (RC_Awareness ordinal)
          ↓
2. Association (Brand Resonance / Trust factors)
          ↓
3. Functionality (Brand Function perception)
          ↓
4. Behavior (Donation outcomes)
```

**Test with:**
- Path model: RC → BE_components → Outcome
- Does awareness improve model when added sequentially?
- Is awareness a mediator or independent predictor?

