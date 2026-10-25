# Superstore Profitability Analysis

**Tools:** Excel (Power Query, PivotTables, what-if model) · MySQL · Power BI
**Data:** Sample Superstore, 9,994 order lines, January 2014 to December 2017 (public dataset, credit: Kaggle)

## Business problem
Sales grew about 51% from 2014 to 2017, but profit margin stalled near 12.5%. **Where is the business losing money, and why?**

## Key findings
1. **Discounts above 20% lose money.** The 1,393 order lines discounted above 20% lost **135,376** in total, equal to 47% of today's total profit (286,397). Margin falls from 29.5% with no discount to -48.2% above a 30% discount.
2. **Furniture is the weak category.** It earns a 2.5% margin on 742K of sales, against about 17% for Office Supplies and Technology. Tables (-17.7K) and Bookcases (-3.5K) lose money overall.
3. **Central is the weakest region.** Its margin is 7.9% and it loses 52.4K on orders discounted above 20%, the most of any region.

## Recommendation
Cap discounts at 20%, with manager approval for anything higher.

| Assumption | Profit change |
|---|---|
| Every affected order is lost (worst case) | **+135K** |
| Every affected order is kept at the higher price (best case) | **+219K** |

The model keeps each order's cost the same and reprices capped orders at list price minus the cap.

## What I did, by tool

**Excel** (`excel/Superstore_Analysis.xlsx`)
- Cleaned the data in Power Query: fixed mixed date formats (month-day-year), set data types, checked for blanks and duplicates (none).
- Built PivotTables for discount bands, categories, sub-categories, regions and years.
- Built a discount-cap what-if model with adjustable cap and customer-retention inputs.

**SQL** (`sql/01_setup.sql`, `sql/02_queries.sql`)
- Loaded the raw CSV into MySQL, then built a clean table with real dates.
- Wrote 10 queries using CTEs, window functions (`LAG`, `RANK`) and joins, each with its business question. Examples: month-over-month sales growth, top 3 products per category, repeat-customer rate, unprofitable customers.

**Power BI** (`powerbi/superstore_powerbi.pbix`)
- Two-page dashboard: Executive Summary and Discount Impact.
- DAX measures for total sales, profit, margin, deep-discount profit, and an interactive discount-cap scenario (`Profit at Cap`).

## Numbers reconcile across all three tools

| Measure | Excel | SQL | Power BI |
|---|---|---|---|
| Total sales | 2,297,201 | 2,297,201 | 2.30M |
| Total profit | 286,397 | 286,397 | 286.40K |
| Profit margin | 12.5% | 12.5% | 12.5% |
| Profit on orders discounted above 20% | -135,376 | -135,376 | -135.38K |
| Orders (distinct) | 5,009 | 5,009 | 5,009 |

## Screenshots
![Executive Summary](screenshots/powerbi_executive_summary.png)
![Discount Impact](screenshots/powerbi_discount_impact.png)

## Repository structure
```
README.md
data/        Sample_Superstore.csv
excel/       Superstore_Analysis.xlsx
sql/         01_setup.sql, 02_queries.sql
powerbi/     superstore_powerbi.pbix
screenshots/
```

## How to reproduce the SQL part
1. Install MySQL 8.0 and MySQL Workbench.
2. Edit the CSV path in `sql/01_setup.sql`, then run it one statement at a time. Loading from a local file needs `local_infile` enabled.
3. Check that the totals match the table above, then run `sql/02_queries.sql`.

## Limits
- The what-if model is a pricing simulation, not a forecast. It does not model how demand reacts beyond the retention input.
- Discount is the only driver tested. Product mix, shipping cost and returns are not in the data.
- Findings cover 2014 to 2017 only.
