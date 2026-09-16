# E-commerce Sales & Customer Intelligence

An end-to-end e-commerce data analysis project using the **Brazilian E-Commerce Public Dataset by Olist**.

The project uses **PostgreSQL, SQL, Python, and Power BI** to explore sales performance, customer behavior, products, sellers, payments, delivery performance, and customer reviews.

---

## Project Overview

E-commerce businesses generate large amounts of transactional and customer data. This project analyzes the Olist e-commerce dataset to uncover meaningful business insights related to:

- Sales and revenue performance
- Customer purchasing behavior
- Product and category performance
- Seller performance
- Payment behavior
- Delivery performance
- Customer satisfaction and reviews
- Customer retention and segmentation

The project follows an end-to-end analytics workflow, starting from raw CSV data and progressing through database design, data validation, SQL analysis, Python exploration, and Power BI visualization.

---

## Dataset

**Brazilian E-Commerce Public Dataset by Olist**

The dataset contains approximately 100,000 orders from the Brazilian e-commerce platform Olist between 2016 and 2018.

It consists of 9 related datasets:

1. Customers
2. Orders
3. Order Items
4. Order Payments
5. Order Reviews
6. Products
7. Sellers
8. Geolocation
9. Product Category Translation

The dataset is available on Kaggle:

[https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## Technology Stack

- **Database:** PostgreSQL
- **Query Language:** SQL
- **Data Analysis:** Python, Pandas
- **Visualization:** Matplotlib
- **Business Intelligence:** Power BI
- **Development:** VS Code
- **Version Control:** Git & GitHub

---

## Project Structure

```text
olist-ecommerce-analysis/
│
├── data/
│   └── raw/
│       └── Olist CSV datasets
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data.sql
│   ├── 03_data_validation.sql
│   ├── 04_sales_analysis.sql
│   ├── 05_customer_analysis.sql
│   ├── 06_product_analysis.sql
│   ├── 07_seller_analysis.sql
│   └── 08_delivery_reviews_analysis.sql
│
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_customer_analysis.ipynb
│   └── 03_eda_visualizations.ipynb
│
├── dashboards/
│   └── olist_ecommerce_dashboard.pbix
│
├── reports/
│   └── project_report.md
│
├── .gitignore
├── README.md
└── requirements.txt
```

---

# Project Progress

## Phase 1 — Project Setup ✅

- Created GitHub repository
- Set up local project structure
- Added `.gitignore`
- Added initial README
- Configured PostgreSQL database
- Connected PostgreSQL with the project

---

## Phase 2 — Database Design & Data Loading ✅

Designed a relational PostgreSQL database containing all 9 Olist datasets.

### Database Tables

| Table                          |      Rows |
| ------------------------------ | --------: |
| customers                      |    99,441 |
| orders                         |    99,441 |
| order\_items                   |   112,650 |
| order\_payments                |   103,886 |
| order\_reviews                 |    99,224 |
| products                       |    32,951 |
| sellers                        |     3,095 |
| geolocation                    | 1,000,163 |
| product\_category\_translation |        71 |

The database schema is defined in:

```text
sql/01_create_tables.sql
```

Data loading is handled through:

```text
sql/02_load_data.sql
```

---

## Phase 3 — Data Preparation & Import ✅

All 9 source datasets were successfully loaded into PostgreSQL.

During the import process, an encoding issue was identified in the original reviews CSV. The source file contained characters that could not be directly converted from its original encoding into PostgreSQL's UTF-8 database encoding.

The reviews file was therefore converted to UTF-8 before loading.

The resulting file is:

```text
olist_order_reviews_utf8.csv
```

The review dataset also contained duplicate `review_id` values. Instead of deleting records, a surrogate `review_record_id` was introduced as the primary key so that all source records could be preserved.

---

# Phase 4 — Data Validation ✅

A comprehensive validation script was created:

```text
sql/03_data_validation.sql
```

The validation covered:

- Row counts
- ID uniqueness
- NULL values
- Referential integrity
- Date consistency
- Negative values
- Payment validity
- Order status distribution
- Orders without order items
- Duplicate review IDs
- Review score distribution

### Key Validation Results

#### Primary-key and ID checks

The following identifiers were found to be unique:

- `customer_id`
- `order_id`
- `(order_id, order_item_id)`
- `product_id`
- `seller_id`
- `(order_id, payment_sequential)`

For reviews, the source `review_id` was not unique.

```text
Total review records: 99,224
Unique review IDs:    98,410
Duplicate records:       814
```

There are 789 review IDs appearing more than once.

A separate `review_record_id` was therefore introduced to uniquely identify each database record while preserving the original `review_id`.

---

### NULL Value Findings

Most core transactional tables contained no NULL values in their important identifier and transaction fields.

The products table contained some missing values:

| Field            | Missing Records |
| ---------------- | --------------: |
| Product category |             610 |
| Product weight   |               2 |
| Product length   |               2 |
| Product height   |               2 |
| Product width    |               2 |

These records were retained and will be handled appropriately during analysis.

---

### Referential Integrity

All tested relationships passed with zero unmatched records:

```text
orders → customers             0 unmatched
order_items → orders           0 unmatched
order_items → products         0 unmatched
order_items → sellers          0 unmatched
order_payments → orders        0 unmatched
order_reviews → orders         0 unmatched
```

This confirms that the core relational structure is internally consistent.

---

### Data Quality Anomalies

Two payment records contain zero installments despite using a credit card payment type.

These records were retained rather than deleted because they are part of the original dataset.

There were also 23 orders where the recorded customer delivery date occurs before the recorded carrier delivery date.

These anomalies will be documented and considered when calculating delivery-related metrics.

---

### Orders Without Items

Some orders do not have corresponding order-item records:

| Order Status | Orders Without Items |
| ------------ | -------------------: |
| unavailable  |                  603 |
| canceled     |                  164 |
| created      |                    5 |
| invoiced     |                    2 |
| shipped      |                    1 |

These records will be considered when performing joins and calculating order-level metrics.

---

# Planned Analysis

## Phase 5 — Sales Analysis ✅

Completed analysis includes:

- Total revenue
- Total orders
- Average order value
- Monthly revenue trends
- Annual revenue trends
- Order status analysis
- Payment method analysis
- Revenue by product category
- Revenue by customer state and city
- Freight cost analysis
- Order status distribution

### Key Findings

- Total product revenue: **R$13.59M**
- Total freight revenue: **R$2.25M**
- Total order value: **R$15.84M**
- Average order value: **R$160.58**
- 2018 generated the highest annual revenue at approximately **R$8.64M**
- Credit card payments represented approximately **75% of orders**
- São Paulo generated the highest state-level revenue at approximately **R$5.92M**
- Freight represented approximately **14.21% of product revenue**

---

## Phase 6 — Customer Analysis ✅

Completed analysis includes:

- Unique customers
- Repeat customers
- Customer purchase frequency
- Customer spending
- Customer lifetime value
- Customer geographic distribution
- Cohort analysis
- Customer retention
- One-time vs repeat customer behavior

### Key Findings

- **96,096 unique customers** were identified.
- **93,099 customers (96.88%)** made only one purchase.
- **2,997 customers (3.12%)** were repeat customers.
- Average orders per customer: **1.03**
- Maximum observed orders for a customer: **17**
- Average customer spending: approximately **R$166.04**
- Median customer spending: approximately **R$107.94**
- Repeat customers had substantially higher average spending than one-time customers.
- Customer spending is right-skewed, with a relatively small number of high-value customers.
- Cohort analysis was used to examine customer retention over time.

---

## Phase 7 — Product Analysis ✅

Completed analysis includes:

- Product catalog analysis
- Top-selling products
- Revenue by product
- Revenue by category
- Product category performance
- Average product price
- Freight costs
- Product weight and dimensions
- Revenue concentration
- High-volume/low-price products
- Low-volume/high-price products

### Key Findings

- The catalog contains **32,951 products**.
- There are **73 named product categories**.
- All **32,951 products (100%)** have at least one recorded sale.
- `beleza_saude` generated the highest category product revenue at approximately **R$1.26M**.
- `relogios_presentes` generated approximately **R$1.21M**.
- `cama_mesa_banho` recorded **11,115 items sold**, making it one of the highest-volume categories.
- Product revenue is distributed across many products rather than being dominated by a small number of individual products.
- The top 50 products accounted for approximately **9.26%** of total product revenue.
- Product weight and dimensions were analyzed in relation to sales and freight costs.
- High-volume/low-price and low-volume/high-price products were identified for further business analysis.

---

## Phase 8 — Seller Analysis 🔄

Planned analysis includes:

- Seller sales performance
- Revenue by seller
- Order volume by seller
- Seller geographic distribution
- Seller revenue concentration
- Seller freight analysis
- High-volume sellers
- High-value sellers
- Seller activity coverage

---

## Phase 9 — Delivery & Review Analysis 🔜

Planned analysis includes:

- Delivery time
- Estimated vs actual delivery
- Late deliveries
- Delivery performance by seller
- Delivery performance by category
- Review score distribution
- Customer satisfaction
- Relationship between delivery performance and review scores

---

## Phase 10 — Python Analysis 🔜

Python will be used for:

- Exploratory Data Analysis
- Data cleaning and preparation where necessary
- Customer segmentation
- Statistical exploration
- Visualizations
- Deeper analysis that complements the SQL work

Planned notebooks:

```text
notebooks/01_data_exploration.ipynb
notebooks/02_customer_analysis.ipynb
notebooks/03_eda_visualizations.ipynb
```

## Phase 11 — Power BI Dashboard 🔜

The final Power BI dashboard will transform the analytical findings into an interactive business intelligence report.

Planned dashboard pages:

1. **Executive Overview**
2. **Sales & Revenue**
3. **Customers**
4. **Products & Sellers**
5. **Delivery & Reviews**

The dashboard will include appropriate KPIs, trends, comparisons, filters, and drill-downs.

---

## Phase 12 — Business Insights & Recommendations 🔜

The final stage will translate analytical findings into business recommendations.

Potential areas include:

- Improving delivery performance
- Increasing customer retention
- Identifying high-value customer segments
- Improving underperforming product categories
- Identifying strong and weak sellers
- Understanding factors affecting customer satisfaction

---

# Key Learning Goals

This project is designed to develop practical skills in:

- Relational database design
- PostgreSQL
- Advanced SQL
- Data validation
- Data cleaning
- Exploratory data analysis
- Customer segmentation
- Cohort analysis
- Business intelligence
- Data visualization
- Business-oriented analytical thinking
- Git and GitHub project management

---

# Project Status

**Current stage: Phase 4 — Data Validation ✅**

Completed:

- [x] Project setup
- [x] PostgreSQL database
- [x] Database schema
- [x] Data loading
- [x] Data validation
- [x] Data-quality investigation
- [x]Sales analysis
- [x]Customer analysis
- [x]Product analysis

Next:

- [ ] Seller analysis
- [ ] Delivery & review analysis
- [ ] Python EDA
- [ ] Power BI dashboard
- [ ] Business recommendations
- [ ] Final project report
