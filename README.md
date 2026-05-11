# Cortex Agent Skills Demo: Cross-Domain Business Summary

A simple, working demo showing how **Snowflake Cortex Agent Skills** and **Code Execution** work together to orchestrate multiple data domains into a single unified report with charts.

## What This Demo Shows

| Feature | How It's Used |
|---------|---------------|
| **Cortex Agent** | Orchestrates queries across 3 data domains |
| **Semantic Views** | Governs how the agent accesses each table |
| **Agent Skill** | Tells the agent *how* to combine data from all 3 domains |
| **Code Execution** | Generates a matplotlib chart inline in the conversation |

## Use Case (Simple)

> A business user asks: "Give me a summary across all customer segments with a chart."
>
> No single data source can answer this. The agent needs Sales data (revenue), Finance data (costs), and Marketing data (campaigns). The **skill** tells the agent exactly how to gather data from all three, combine it, and produce a chart — consistently, every time.

## Architecture

```
User Question
     │
     ▼
┌─────────────┐
│   AGENT     │ ← reads skill instructions
└─────┬───────┘
      │
      ├──→ sales_analyst    → CUSTOMERS table (ARR, segments)
      ├──→ finance_analyst  → COSTS table (COGS, CAC, Support)
      ├──→ marketing_analyst → CAMPAIGNS table (spend, leads)
      │
      ▼
┌─────────────────┐
│ Code Execution  │ ← Python generates chart + summary table
└─────────────────┘
      │
      ▼
  User sees: chart + formatted table + recommendations
```

## Project Structure

```
.
├── demo_simple.sql                     # Main setup script (tables, data, views, agent)
├── skills/
│   └── summary_report/
│       └── SKILL.md                    # The skill definition
├── agent_overview.md                   # How the agent works (reference)
└── README.md                           # This file
```

## Setup Steps

### Prerequisites

- Snowflake account with Cortex Agent access
- A warehouse (the script uses `CORTEX_WH`)
- Code Execution enabled (add `"tool_type": "code_execution"` in agent spec)

### 1. Run the SQL Script

Open Snowsight and run `demo_simple.sql`. This creates:
- Database: `CORTEX_DB`
- Schema: `DEMO`
- 3 tables with sample data (13 customers, 12 cost records, 7 campaigns)
- 3 semantic views
- 1 stage for skills
- 1 Cortex Agent

### 2. Upload the Skill

From SnowSQL or Snowsight:

```sql
PUT file:///path/to/skills/summary_report/SKILL.md 
    @CORTEX_DB.DEMO.SKILL_STAGE/skills/summary_report/;
```

### 3. Verify

```sql
-- Check the skill is on the stage
LS @CORTEX_DB.DEMO.SKILL_STAGE/skills/ PATTERN = '.*SKILL\\.md';

-- Check the agent
DESCRIBE AGENT CORTEX_DB.DEMO.DEMO_AGENT;
```

### 4. Test

Open Snowflake Intelligence or invoke via API.

**Single-domain questions (no skill needed):**
- "What is total ARR by segment?"
- "What are costs by segment and cost type?"
- "Which campaign generated the most leads?"

**Cross-domain question (skill activates):**
- "Give me a business summary across all segments with a chart"

## How Skills Work

A skill is a **SKILL.md** file on a Snowflake stage. It contains:

| Field | Purpose |
|-------|---------|
| `name` | Identifier the agent uses to match queries |
| `description` | Brief text the agent reads to decide if the skill is relevant |
| `instructions` | Step-by-step playbook the agent follows when the skill activates |

The agent **does not copy** the skill — it reads it on demand from the stage. Update the file, and every agent using it picks up the change on the next invocation.

### Skill Lifecycle

```
User asks question
     │
     ▼
Agent reads skill name + description
     │
     ▼
Relevant? ──No──→ Agent answers normally (single analyst)
     │
    Yes
     │
     ▼
Agent reads full SKILL.md instructions
     │
     ▼
Follows steps: query analysts → run code → return result
```

## Key Concepts

### Why a Skill (Not Just a System Prompt)?

| System Prompt | Skill |
|---------------|-------|
| Always loaded, uses tokens every turn | Loaded only when relevant |
| One agent, one set of instructions | Same skill shared across many agents |
| Changes require ALTER AGENT | Update the file on stage, done |
| Not auditable | Visible in monitoring/thinking steps |

### Why Code Execution?

- Agent does math poorly (rounding errors, forgets steps)
- Charts require Python (matplotlib)
- Consistent output format every time
- Sandboxed — no access beyond what's passed in

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Skill doesn't activate | Check `LS @stage` — SKILL.md must be at folder root |
| Agent writes raw SQL | Check semantic view exists: `DESCRIBE SEMANTIC VIEW ...` |
| Charts don't display | Use `plt.show()` not `plt.savefig()` in code execution |
| Agent ignores instructions | Shorten skill instructions — LLMs follow short rules better |
| Permission error | Grant `USAGE` on stage to the role invoking the agent |

## References

- [Cortex Agent Skills Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-skills)
- [Cortex Agents Overview](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-overview)
- [Code Execution Tool](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-code-execution)

## License

MIT
