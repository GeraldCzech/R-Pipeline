# Donation Type Segmentation Strategy
## Testing Heterogeneous Brand-Donation Relationships

**Question**: Do different donation types (Einmalig/Regelmäßig/Mengengabe) have different brand factor relationships?

**Answer**: ✅ **YES - This is analytically elegant and highly relevant**

---

## Strategic Rationale

### Why This Matters

Different donor types likely have **different psychological pathways** to giving:

```
Einmalig (One-time):
  └─ Brand awareness → Impulse giving
  └─ Lower commitment required
  └─ Relevance/TOM might dominate

Regelmäßig (Regular):
  └─ Sustained commitment
  └─ Trust/Image more important than TOM
  └─ Relationship-building over time

Mengengabe (Large/Bulk):
  └─ High involvement decision
  └─ Full evaluation of brand (all factors matter)
  └─ Rational deliberation > impulse
```

### Business Relevance

```
For Nonprofit Strategy:
  ✓ Tailor messaging by donor type
  ✓ Understand conversion pathways (One-time → Regular)
  ✓ Identify which brand factors drive high-value donors
  ✓ Design segmented retention/upgrade strategies
```

---

## Implementation Approach

### Option 1: Stratified Analysis (Simplest)

```
Run GLM separately for each donation type:

Global Model:
  Outcome ~ CFA_Factors × SES_z + (1 | Org)

Split by Donation Type:
  ├─ GLM_Einmalig: Outcome ~ ... (subset where donation_type = "Einmalig")
  ├─ GLM_Regelmäßig: Outcome ~ ... (subset where donation_type = "Regelmäßig")
  └─ GLM_Mengengabe: Outcome ~ ... (subset where donation_type = "Mengengabe")

Compare:
  ├─ Coefficient magnitudes
  ├─ Effect sizes
  ├─ Significance patterns
```

**Pros**:
- ✅ Simple to interpret
- ✅ Intuitive comparisons
- ✅ Separate effect sizes per type

**Cons**:
- ✗ No formal test of differences
- ✗ Reduces sample size per group
- ✗ No uncertainty in comparisons

---

### Option 2: Interaction Model (More Sophisticated)

```
Single Model with Interactions:
  Outcome ~ CFA_Factors × donation_type × SES_z + (1 | Org)

Tests:
  ✓ Do CFA factors have different effects for each type?
  ✓ Does SES-Z moderate differently by type?
  ✓ Formal statistical tests of differences
  ✓ Retains full sample power
```

**Specification**:
```
Bayesian (brms):
  Outcome ~ (CFA_factors) * (donation_type) + SES_z + (1 | Org)
  
  Allows:
  • Factor × Type interaction (does brand importance vary?)
  • Differential slopes per type
  • Posterior comparison: Type A effect vs Type B
  
Frequentist (lme4):
  Same model, get:
  • ANOVA F-test for Type × Factor interaction
  • Model comparison (with/without interaction via AIC)
```

**Pros**:
- ✅ Formal statistical test of differences
- ✅ Retains full sample size
- ✅ Clear uncertainty quantification
- ✅ Can test specific contrasts

**Cons**:
- ✗ More complex interpretation
- ✗ More parameters to estimate

---

### Option 3: Multilevel Moderation (Most Elegant)

```
Two-level structure:
  Level 1: Respondents
  Level 2: Donation Type (nested in Organizations)

Model:
  Outcome ~ CFA_Factors + SES_z + (CFA_Factors | donation_type) + (1 | Org)
  
Meaning:
  • Each donation type gets own brand factor slopes
  • Random slopes capture type-specific relationships
  • Full Bayesian posterior for type comparisons
```

**Interpretation**:
```
Random Slopes by Type:
  ├─ Einmalig: Relevance/TOM effect = +0.45 (SD=0.12)
  ├─ Regelmäßig: Relevance/TOM effect = +0.22 (SD=0.08)
  └─ Mengengabe: Relevance/TOM effect = +0.38 (SD=0.10)

Implies: One-time donors most sensitive to awareness!
```

---

## Data Requirements

### Check Admin Data for Donation Type Variables

**Need to Find**:
```
□ Donation type indicator (Einmalig, Regelmäßig, Mengengabe)
□ Or binary: Recurring vs One-time
□ Or flags: HasRecurring, HasOneTime, HasBulk
□ Frequency information (monthly, quarterly, annual?)
□ Amount patterns (one-time amount vs avg monthly?)
```

**If Available**:
- Filter analysis by type
- Or use as predictor in GLM
- Or create stratified sample

**If Not Available**:
- Can infer from donation history in admin data
- Look at pattern of giving (one entry = one-time, multiple = recurring)
- Aggregation periods reveal type

### Sample Size per Type

```
Rough Estimate (typical nonprofit):
  ├─ Einmalig: 40-50% of donors
  ├─ Regelmäßig: 35-45% of donors
  └─ Mengengabe: 5-15% of donors

Example with 2,038 respondents:
  ├─ If 40% one-time: n=815
  ├─ If 40% regular: n=815
  └─ If 20% bulk: n=408

Still adequate for GLM (minimum ~200-300 recommended)
```

---

## Proposed Analysis Plan

### Phase 3.1: Exploratory Stratification

```bash
# Run GLM separately for each type
# Frequentist approach (fast):

GLM_Einmalig <- lmer(
  Outcome ~ CFA_Factors + SES_z + (1 | Org),
  data = glm_data[glm_data$donation_type == "Einmalig", ]
)

GLM_Regelmäßig <- lmer(
  Outcome ~ CFA_Factors + SES_z + (1 | Org),
  data = glm_data[glm_data$donation_type == "Regelmäßig", ]
)

# Compare effects tables
compare_models(list(GLM_Einmalig, GLM_Regelmäßig))
```

**Output**:
- Side-by-side effect tables
- Effect size plots by type
- Interaction patterns

---

### Phase 3.2: Interaction Testing

```bash
# Full model with interaction
GLM_Interactive <- lmer(
  Outcome ~ CFA_Factors * donation_type + SES_z + (1 | Org),
  data = glm_data
)

# Test significance of Type × Factor interaction
anova(GLM_NoInteraction, GLM_Interactive)
# If p < 0.05: Different types have different relationships!
```

---

### Phase 3.3: Bayesian Comparison

```bash
# Bayesian with type-specific random slopes
GLM_Bayesian <- brm(
  Outcome ~ CFA_Factors + SES_z + (CFA_Factors | donation_type) + (1 | Org),
  family = gaussian(),
  chains = 4, iter = 2000
)

# Extract random slopes per type
ranef(GLM_Bayesian)$donation_type

# Compare posterior distributions across types
conditional_effects(GLM_Bayesian, effects = "CFA_Factors:donation_type")
```

---

## Expected Findings & Interpretation

### Scenario 1: Large Differences (Type Matters!)

```
Brand Factor Effects by Type:
  
  Awareness (RELEVANCE_SCALE):
    └─ Einmalig: β = +0.68 (p<0.001) ✓ Strong
    └─ Regelmäßig: β = +0.15 (p=0.24) ✗ Weak
    └─ Mengengabe: β = +0.41 (p=0.01) ✓ Moderate

Interpretation:
  → One-time donors driven by awareness (TOM/SAW)
  → Regular donors driven by other factors (trust/image?)
  → Large donors use balanced evaluation
  
Action:
  → Advertise to one-timers (build awareness)
  → Steward regular donors (build trust)
  → Engage bulk donors with full brand story
```

### Scenario 2: No Differences (Type Doesn't Matter)

```
Brand Factor Effects by Type:
  
  All Factors:
    └─ Einmalig: β ≈ consistent across types
    └─ Regelmäßig: β ≈ same effect sizes
    └─ Mengengabe: β ≈ no type effect

Interpretation:
  → Brand factors work equally for all donor types
  → One fundraising message fits all
  → Segmentation not necessary for brand strategy
```

### Scenario 3: Complex Patterns (Moderation)

```
SES-Z Effect by Type:
  
  Brand effect depends on BOTH type AND SES:
    └─ High SES Einmalig: Strong brand effect
    └─ Low SES Regelmäßig: Weak brand effect
    
  (Three-way interaction: Brand × Type × SES)

Interpretation:
  → Segmentation should be Type × SES
  → Different wealth groups respond to different messages
```

---

## Implementation Timeline

### Current (SEM Running)

```
Now - 56 hours from now:
  └─ SEM MCMC continues
  └─ GLM parallel setup ready
```

### When GLM Starts

```
56 hours from now:
  └─ Run Option 1 (Stratified) first — fast, exploratory
  └─ Takes: ~15 minutes
  └─ See if type effects exist
  
  If effects found:
    └─ Run Option 2 (Interaction) — formal testing
    └─ Takes: ~30 minutes
    
  If interaction significant:
    └─ Run Option 3 (Bayesian multilevel) — full Bayes
    └─ Takes: ~2 hours (for posterior comparison)
```

### Total Additional Time

```
Stratified: +15 min
Interaction: +30 min
Bayesian: +2 hours

Total: ~2.5 hours additional (easily fits in parallel)
```

---

## Data Preparation Needed

### Before GLM Can Run

Need to Add to GLM Dataset:
```
1. donation_type variable
   └─ Values: "Einmalig", "Regelmäßig", "Mengengabe"
   └─ Or inferred from admin_data patterns

2. Frequency information (if available)
   └─ Number of donations per respondent
   └─ Time span of giving
   
3. Amount patterns
   └─ One-time amount for einmalig
   └─ Average monthly for regelmäßig
```

### Check Admin Data

```bash
# Merging block1 (respondents) with admin_data (organizations)
# Need identifier to link respondent → donations → type
```

---

## Recommendation

### Run All Three Approaches

**Why**:
1. ✅ Stratified is exploratory — quick gut check
2. ✅ Interaction is formal test — definitive answer
3. ✅ Bayesian is rigorous — posterior comparison gives full uncertainty

**Sequence**:
```
1. Stratified GLM (15 min) → "Do types differ?"
   └─ If no: Stop here, unified model sufficient
   └─ If yes: Proceed to interaction

2. Interaction Test (30 min) → "How much does type matter?"
   └─ If p < 0.05: Interaction significant
   └─ Run Bayesian for posterior uncertainty

3. Bayesian Multilevel (2 hours) → "What are the posterior type effects?"
   └─ Full distribution comparison
   └─ Publication-quality results
```

---

## Publication Angle

### Novel Contribution

```
"This study reveals heterogeneous brand-donation relationships 
across donor types: awareness drives one-time gifts, while 
trust and image sustain recurring support. These findings suggest 
segmented fundraising strategies based on donor lifecycle stage."
```

### Tables for Manuscript

```
Table 1: Brand Factor Effects by Donation Type
  ├─ Column A: One-time Donors
  ├─ Column B: Regular Donors
  └─ Column C: High-Value Donors

Figure 1: Conditional Effects Plots
  ├─ One panel per brand factor
  ├─ Lines for each donation type
  └─ Shows interaction patterns

Supplementary: Interaction ANOVA
  └─ Model comparison (with/without Type × Factor)
  └─ Tests if segmentation improves fit
```

---

## Bottom Line

✅ **YES, absolutely do this analysis!**

**Why**:
- Theoretically motivated (different donor psychology)
- Practically relevant (tailor strategy by type)
- Statistically elegant (interaction model)
- Publishable (novel segmentation finding)
- Feasible (easily fits in parallel execution)

**Effort**: ~2-3 additional hours (fits within parallel window)

**Expected Impact**: Could be the most actionable finding of the entire analysis!

---

**Recommendation**: 
1. Check admin_data for donation type variables
2. After GLM Phase 1 completes, add Type × Factor interactions
3. Run all three approaches (stratified → interaction → Bayesian)
4. Report as major finding section in manuscript
