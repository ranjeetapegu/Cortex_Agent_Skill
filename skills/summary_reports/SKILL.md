name: summary_report 

description: >
  Generates a business summary across all segments by combining revenue from Sales,
  costs from Finance, and marketing performance from Marketing. Includes a chart.
  Use when the user asks for a summary, overview, or report across segments.

instructions: |

  Generate a cross-domain business summary. Follow these steps:

  1. Ask sales_analyst: "What is total ARR and customer count by segment?"
  2. Ask finance_analyst: "What is total amount by segment and cost_type?"
  3. Ask marketing_analyst: "What is total spend and total leads by target_segment?"
  4. Use the code execution tool to run this Python code (replace values with actual results):

  ```python
  import matplotlib
  matplotlib.use('Agg')
  import matplotlib.pyplot as plt
  import numpy as np

  # Replace with actual data from analysts
  segments = ['Enterprise', 'Mid-Market', 'SMB', 'Startup']
  arr = [REPLACE, REPLACE, REPLACE, REPLACE]
  costs = [REPLACE, REPLACE, REPLACE, REPLACE]  # sum of COGS+CAC+Support per segment
  leads = [REPLACE, REPLACE, REPLACE, REPLACE]

  # Chart: ARR vs Total Cost by Segment
  x = np.arange(len(segments))
  w = 0.35
  fig, ax = plt.subplots(figsize=(9, 5))
  ax.bar(x - w/2, [a/1000 for a in arr], w, color='#2ecc71', label='ARR ($K)')
  ax.bar(x + w/2, [c/1000 for c in costs], w, color='#e74c3c', label='Total Cost ($K)')
  ax.set_xticks(x)
  ax.set_xticklabels(segments)
  ax.set_ylabel('$K')
  ax.set_title('ARR vs Total Cost by Segment')
  ax.legend()
  ax.spines['top'].set_visible(False)
  ax.spines['right'].set_visible(False)
  plt.tight_layout()
  plt.show()

  # Print summary
  print("| Segment | ARR | Total Cost | Net | Leads | Cost/Lead |")
  print("|---------|-----|-----------|-----|-------|-----------|")
  for i, seg in enumerate(segments):
      net = arr[i] - costs[i]
      cpl = costs[i] / leads[i] if leads[i] > 0 else 0
      print(f"| {seg} | ${arr[i]:,.0f} | ${costs[i]:,.0f} | ${net:,.0f} | {leads[i]} | ${cpl:,.0f} |")
  ```

  5. Show the chart and table to the user. Add one sentence per segment as a recommendation.
