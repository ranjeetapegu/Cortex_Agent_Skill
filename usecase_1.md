# Customer Segment Profitability Agent — How It Works

## What This Agent Does

This agent answers profitability questions for a SaaS company by combining data from Sales, Finance, and Marketing.

---

## Components

### Agent: `PROFITABILITY_AGENT`
- Receives the user's question
- Decides: is this a single-domain question or cross-domain?
- Single-domain → calls one analyst directly
- Cross-domain (profitability, ROI, unit economics) → activates the skill

### Tools (3 Analysts + Code Execution)

| Tool | Data Source | Answers Questions About |
|------|-------------|------------------------|
| `sales_analyst` | SALES_VIEW (CUSTOMERS + ORDERS) | ARR, revenue, deal size, retention, customer counts |
| `finance_analyst` | FINANCE_VIEW (COST_ALLOCATIONS) | CAC, COGS, support costs, margins by segment |
| `marketing_analyst` | MARKETING_VIEW (CAMPAIGNS + LEAD_ATTRIBUTION) | Campaign spend, leads, cost per lead, attribution |
| `code_execution` | Python sandbox | Runs profitability_model.py to compute metrics |

### Skill: `customer_profitability`
- A SKILL.md file on a stage
- Contains step-by-step instructions the agent follows
- References profitability_model.py for computation
- Defines: what to query, in what order, what formulas to use, how to classify results

---

## Flow

```
User asks question
       |
       v
Agent checks: does this match the skill?
       |
  +---------+---------+
  |                   |
  v                   v
Single-domain     Cross-domain
(one analyst)     (skill activates)
  |                   |
  v                   v
Returns answer    1. Query sales_analyst → ARR by segment
                  2. Query finance_analyst → costs by segment
                  3. Query marketing_analyst → acquisition costs
                  4. Run profitability_model.py → LTV, CAC payback, margins
                  5. Return table with verdicts
```

---

## Key Formulas (encoded in the Python script)

- **Gross Margin %** = (ARR - COGS) / ARR × 100
- **LTV** = (ARR per customer × Gross Margin %) / Churn Rate
- **LTV:CAC** = LTV / Blended CAC
- **CAC Payback** = Blended CAC / Monthly Gross Profit per Customer

### Churn Rates (assumptions)
| Segment | Annual Churn |
|---------|-------------|
| Enterprise | 5% |
| Mid-Market | 10% |
| SMB | 15% |
| Startup | 30% |

### Classification
| Verdict | Criteria |
|---------|----------|
| INVEST | LTV:CAC > 3x AND Payback < 18 months |
| MAINTAIN | LTV:CAC 1.5–3x OR Payback 18–24 months |
| REVIEW | LTV:CAC 1.0–1.5x OR Payback 24–36 months |
| DIVEST | LTV:CAC < 1x OR Payback > 36 months |

---

## Why Each Piece Exists

| Component | Without it | With it |
|-----------|-----------|---------|
| Agent | No orchestration — user queries tables manually | Natural language access, automatic routing |
| Analysts | Agent guesses SQL or hallucinates columns | Accurate SQL generated from governed semantic views |
| Skill | Agent improvises methodology each time | Locked methodology, consistent every run |
| Code Execution | LLM does math in its head (error-prone) | Precise computation, formatted output |

---

## Example Questions

**Single-domain (no skill needed):**
- "What is total ARR by customer segment?"
- "Which campaign had the lowest cost per lead?"
- "Show me COGS breakdown for Enterprise in Q4"

**Cross-domain (skill activates):**
- "Which customer segments are profitable after all costs?"
- "Should we keep investing in the Startup segment?"
- "Compare unit economics across all segments"
