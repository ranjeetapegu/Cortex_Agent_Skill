-- =============================================================================
-- CORTEX AGENT DEMO: Skills + Code Execution + 3 Semantic Views
-- Simple and clean. Shows the feature, not complex finance.
-- =============================================================================

USE DATABASE CORTEX_DB;
CREATE SCHEMA IF NOT EXISTS CORTEX_DB.DEMO;
USE SCHEMA CORTEX_DB.DEMO;
USE WAREHOUSE CORTEX_WH;

-- ============================================================
-- TABLES (3 simple tables, one per domain)
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID     INT,
    NAME            VARCHAR(100),
    SEGMENT         VARCHAR(50),
    REGION          VARCHAR(50),
    ARR             NUMBER(12,2),
    START_DATE      DATE,
    IS_ACTIVE       BOOLEAN
);

CREATE OR REPLACE TABLE COSTS (
    SEGMENT         VARCHAR(50),
    QUARTER         VARCHAR(10),
    COST_TYPE       VARCHAR(50),
    AMOUNT          NUMBER(12,2)
);

CREATE OR REPLACE TABLE CAMPAIGNS (
    CAMPAIGN_NAME   VARCHAR(200),
    CHANNEL         VARCHAR(100),
    TARGET_SEGMENT  VARCHAR(50),
    SPEND           NUMBER(12,2),
    LEADS           INT
);

-- ============================================================
-- DATA (small, realistic)
-- ============================================================

INSERT INTO CUSTOMERS VALUES
(1, 'Acme Corp',       'Enterprise',  'North America', 420000, '2023-03-01', TRUE),
(2, 'Titan Mfg',       'Enterprise',  'EMEA',          310000, '2023-06-15', TRUE),
(3, 'Meridian Health',  'Enterprise',  'North America', 380000, '2024-01-01', TRUE),
(4, 'BrightPath',      'Mid-Market',  'North America', 120000, '2024-01-15', TRUE),
(5, 'ClearView',       'Mid-Market',  'EMEA',           95000, '2024-03-01', TRUE),
(6, 'NovaTech',        'Mid-Market',  'APAC',          110000, '2024-02-01', TRUE),
(7, 'Redwood Co',      'Mid-Market',  'North America',  78000, '2024-05-01', TRUE),
(8, 'PixelForge',      'SMB',         'North America',  36000, '2025-01-01', TRUE),
(9, 'QuickShip',       'SMB',         'North America',  28000, '2025-02-01', TRUE),
(10,'CloudNine',       'SMB',         'APAC',           48000, '2025-01-01', TRUE),
(11,'LaunchPad AI',    'Startup',     'North America',  24000, '2025-06-01', TRUE),
(12,'ZeroDay Sec',     'Startup',     'North America',  18000, '2025-07-01', TRUE),
(13,'NeuralPath',      'Startup',     'EMEA',           30000, '2025-05-01', FALSE);

INSERT INTO COSTS VALUES
('Enterprise',  '2025-Q2', 'COGS',      180000),
('Enterprise',  '2025-Q2', 'CAC',       145000),
('Enterprise',  '2025-Q2', 'Support',    65000),
('Mid-Market',  '2025-Q2', 'COGS',       72000),
('Mid-Market',  '2025-Q2', 'CAC',        85000),
('Mid-Market',  '2025-Q2', 'Support',    35000),
('SMB',         '2025-Q2', 'COGS',       18000),
('SMB',         '2025-Q2', 'CAC',        42000),
('SMB',         '2025-Q2', 'Support',    15000),
('Startup',     '2025-Q2', 'COGS',        8000),
('Startup',     '2025-Q2', 'CAC',        18000),
('Startup',     '2025-Q2', 'Support',     6000);

INSERT INTO CAMPAIGNS VALUES
('LinkedIn ABM',         'LinkedIn',     'Enterprise',  115000, 15),
('Executive Dinners',    'Events',       'Enterprise',   82000,  8),
('Google Ads Mid',       'Paid Search',  'Mid-Market',   78000, 120),
('Webinar Series',       'Webinar',      'Mid-Market',   32000,  45),
('Self-Serve Ads',       'Paid Search',  'SMB',          58000, 200),
('Product Hunt',         'Community',    'Startup',       7500,  60),
('Incubator Program',    'Partnerships', 'Startup',       9500,  25);

-- ============================================================
-- SEMANTIC VIEWS (3 simple views)
-- ============================================================

CREATE OR REPLACE SEMANTIC VIEW CORTEX_DB.DEMO.SALES_VIEW
  COMMENT = 'Customer and revenue data'
AS
  TABLES (
    CORTEX_DB.DEMO.CUSTOMERS
      WITH SEMANTICS (
        CUSTOMER_ID AS 'Unique customer ID',
        NAME AS 'Customer company name',
        SEGMENT AS 'Customer segment: Enterprise, Mid-Market, SMB, or Startup',
        REGION AS 'Geographic region: North America, EMEA, or APAC',
        ARR AS 'Annual Recurring Revenue in USD',
        START_DATE AS 'Contract start date',
        IS_ACTIVE AS 'Whether customer is currently active'
      )
  );

CREATE OR REPLACE SEMANTIC VIEW CORTEX_DB.DEMO.FINANCE_VIEW
  COMMENT = 'Cost data by segment and quarter'
AS
  TABLES (
    CORTEX_DB.DEMO.COSTS
      WITH SEMANTICS (
        SEGMENT AS 'Customer segment: Enterprise, Mid-Market, SMB, or Startup',
        QUARTER AS 'Fiscal quarter like 2025-Q2',
        COST_TYPE AS 'Type of cost: COGS, CAC, or Support',
        AMOUNT AS 'Cost amount in USD'
      )
  );

CREATE OR REPLACE SEMANTIC VIEW CORTEX_DB.DEMO.MARKETING_VIEW
  COMMENT = 'Marketing campaign performance'
AS
  TABLES (
    CORTEX_DB.DEMO.CAMPAIGNS
      WITH SEMANTICS (
        CAMPAIGN_NAME AS 'Name of the marketing campaign',
        CHANNEL AS 'Marketing channel like LinkedIn, Paid Search, Events',
        TARGET_SEGMENT AS 'Customer segment this campaign targets',
        SPEND AS 'Amount spent on this campaign in USD',
        LEADS AS 'Number of leads generated'
      )
  );

-- ============================================================
-- STAGE FOR SKILL
-- ============================================================

CREATE STAGE IF NOT EXISTS CORTEX_DB.DEMO.SKILL_STAGE
  DIRECTORY = (ENABLE = TRUE);

-- Upload skill files:
-- PUT file:///path/to/skills/summary_report/SKILL.md @CORTEX_DB.DEMO.SKILL_STAGE/skills/summary_report/;

-- ============================================================
-- AGENT
-- ============================================================

CREATE OR REPLACE AGENT CORTEX_DB.DEMO.DEMO_AGENT
  WAREHOUSE = CORTEX_WH
  SPECIFICATION = $$
  {
    "models": {
      "orchestration": "claude-4-sonnet"
    },
    "instructions": {
      "system": "You are a business analyst. Use the analyst tools to answer questions. For cross-domain summary questions, use the summary_report skill. Format all output as clean markdown tables. Be concise."
    },
    "tools": [
      {
        "tool_type": "cortex_analyst_text_to_sql",
        "name": "sales_analyst",
        "description": "Answers questions about customers, ARR, segments, and regions from the CUSTOMERS table.",
        "source": "CORTEX_DB.DEMO.SALES_VIEW"
      },
      {
        "tool_type": "cortex_analyst_text_to_sql",
        "name": "finance_analyst",
        "description": "Answers questions about costs (COGS, CAC, Support) by segment and quarter from the COSTS table.",
        "source": "CORTEX_DB.DEMO.FINANCE_VIEW"
      },
      {
        "tool_type": "cortex_analyst_text_to_sql",
        "name": "marketing_analyst",
        "description": "Answers questions about campaigns, marketing spend, leads, and channels from the CAMPAIGNS table.",
        "source": "CORTEX_DB.DEMO.MARKETING_VIEW"
      },
      {
        "tool_type": "code_execution"
      }
    ],
    "skills": [
      {
        "name": "summary_report",
        "source": {
          "type": "STAGE",
          "path": "@CORTEX_DB.DEMO.SKILL_STAGE/skills/summary_report"
        }
      }
    ]
  }
  $$;

-- ============================================================
-- TEST QUERIES
-- ============================================================

/*
STEP 1 - Test each analyst individually:
  "What is total ARR by segment?"
  "What are costs by segment and cost type?"
  "Which campaign generated the most leads?"

STEP 2 - Test the skill:
  "Give me a business summary across all segments with a chart"
*/
