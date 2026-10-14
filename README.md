# SpendWise — Personal Expense Tracker & Financial Intelligence Platform

**SpendWise** is a responsive, accessible web application designed to help individuals and households effortlessly record, organize, and understand their spending habits. It combines automated expense categorization, budget tracking, data-driven financial insights, and flexible CSV import/export in a modern, distraction-free interface.

---

## Table of Contents
1. [Core Features](#core-features)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Setup & Running Locally](#setup--running-locally)
4. [Demo Experience](#demo-experience)
5. [Automatic Categorization Engine](#automatic-categorization-engine)
6. [Insights & Anomaly Detection System](#insights--anomaly-detection-system)
7. [API Documentation (OpenAPI / Swagger)](#api-documentation-openapi--swagger)
8. [Database Schema & Migrations](#database-schema--migrations)
9. [Security & Privacy Decisions](#security--privacy-decisions)

---

## Core Features

- **Authentication & Multi-Tenant Data Isolation**: Secure registration, login, password reset, and user isolation using BCrypt password hashing and JWT stateless tokens.
- **Unified Financial Dashboard**:
  - Net balance, total income, and total expenses (accurately adjusted for refunds).
  - Period-over-period trend comparisons with percentage diff badges.
  - Overall monthly budget consumption and remaining allowance.
  - Interactive Daily Spending Trend chart (Chart.js bar & inflow line).
  - Spending by Category donut chart with ranked breakdown list.
  - Top 3 actionable insights with severity badges.
  - Recent transactions list with quick edit and deletion.
  - Flexible date-range selectors: *This Month*, *Last Month*, *Last 3 Months*, or *Custom Range*.
- **Transaction Management**:
  - Record Income, Expenses, Transfers, and Refunds with fixed-precision decimals (`DECIMAL(12,2)`).
  - Real-time search by merchant, description, or notes with debounced filtering.
  - Multi-faceted filters by category, transaction type, date ranges, and min/max amounts.
  - Column-based sorting (Date, Description, Amount) and pagination.
  - Safe deletion dialog with confirmation prompts.
- **Smart Automatic Categorization**:
  - Live prediction banner in the "Add Transaction" modal as the user types a merchant or description.
  - Confidence scoring (*High*, *Medium*, *Low*) and source attribution (*Saved Rule*, *Keyword Pattern*, *Default*).
  - Automated rule learning: when a user updates or confirms a category with a merchant, a custom rule is saved to categorize future transactions automatically.
  - User category selections are **never** silently overwritten.
- **Budgets & Spending Targets**:
  - Set an overall monthly spending ceiling or granular category budgets.
  - Dual visual indicators: progress bar and status pills (**Safe**, **⚡ Approaching Limit** at ≥80%, **⚠ Exceeded** at >100%).
  - Live calculations factoring in refunds (refunds offset expenditures).
- **Explainable Insights & Reporting**:
  - Identification of primary spending drivers and largest categories.
  - Detection of period-over-period category spikes (e.g. +35% jump in Dining).
  - Daily spending velocity and weekly run-rate projections.
  - Automatic detection of recurring subscription merchants (Netflix, Spotify, Gym, SaaS).
  - Anomaly detection flagging unusual purchases exceeding 2.5x the category average.
  - Graceful handling of insufficient data with guidance on what to record next.
- **CSV Import & Export**:
  - Multi-step CSV Import Wizard with header auto-detection, preview table, validation error isolation, and duplicate transaction flagging.
  - RFC-4180 compliant CSV export for any selected period.
- **Categories & Account Settings**:
  - Starter categories: *Housing, Groceries, Dining, Transportation, Utilities, Healthcare, Shopping, Entertainment, Education, Travel, Personal Care, Subscriptions, Income, Other*.
  - Create custom categories with custom colors and icons.
  - Category deletion protection: prevents deleting categories in active use unless affected transactions are reassigned to a replacement category.
  - Preference customization (Currency, Timezone).
  - Complete account deletion flow permanently scrubbing all user data.

---

## Architecture & Technology Stack

### Backend
- **Java 21 LTS**
- **Spring Boot 3.3.x**:
  - `spring-boot-starter-web`: RESTful API controllers.
  - `spring-boot-starter-data-jpa`: Relational persistence and repository specifications.
  - `spring-boot-starter-security`: Stateless JWT filter chain, CORS/CSRF handling, BCrypt password encoder.
  - `spring-boot-starter-validation`: Jakarta Bean Validation on all incoming requests.
- **Flyway**: Database migrations (`V1__init_schema.sql`).
- **H2 Database / PostgreSQL**: High-performance persistent relational store.
- **Apache Commons CSV**: Robust RFC-4180 CSV parsing and streaming generation.
- **SpringDoc OpenAPI 2.6**: Automated Swagger UI and OpenAPI 3.0 specification.

### Frontend
- **HTML5 & Modern CSS3**: Accessible, responsive semantic layout (Desktop sidebar + Tablet/Mobile header drawer).
- **Vanilla JavaScript (ES6+ Modules)**:
  - `api.js`: REST client managing bearer tokens and response handling.
  - `state.js`: Reactive application store and locale/currency formatting.
  - `components.js`: Accessible modal dialogs, toast notifications, badges, empty states.
  - `charts.js`: Chart.js rendering for trends and category distributions.
  - `app.js`: Main router, event debouncing, live auto-categorization preview, CSV import wizard.

---

## Setup & Running Locally

### Prerequisites
- **Java 21 JDK** or newer installed.
- **Apache Maven 3.8+** installed.

### 1. Build the Application
In the project root directory, run:
```bash
mvn clean package -DskipTests
```

### 2. Run the Application
You can run SpendWise using the Spring Boot Maven plugin:
```bash
mvn spring-boot:run
```
Or directly run the compiled fat JAR:
```bash
java -jar target/spendwise-1.0.0.jar
```

### 3. Open in Browser
Once started, visit:
- **Application Web UI**: [http://localhost:8080](http://localhost:8080)
- **Interactive Swagger API Docs**: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- **OpenAPI JSON Spec**: [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs)
- **H2 Database Console**: [http://localhost:8080/h2-console](http://localhost:8080/h2-console) (JDBC URL: `jdbc:h2:file:./data/spendwisedb`)

---

## Demo Experience

SpendWise includes a sample account pre-populated with realistic financial data across the last 3 months:
- **Instant 1-Click Access**: On the login page, click **"Explore Sample Demo Account"**.
- **Credentials** (if logging in manually):
  - **Email**: `demo@spendwise.app`
  - **Password**: `password123`

The demo dataset contains:
- 3 months of bi-weekly payroll income.
- Fixed monthly rent, electricity, fiber internet, and streaming subscriptions (Netflix, Spotify, ChatGPT Plus, Gym).
- Variable grocery hauls, dining receipts, rideshare trips, and fuel fill-ups.
- An intentionally large tech purchase ($480 headphones) to demonstrate **Anomaly Outlier Detection**.
- A returned retail item ($45 Zara refund) to demonstrate **Net Refund Offsetting**.
- Sample CSV file `sample_transactions.csv` ready to test CSV importing.

---

## Automatic Categorization Engine

### How it Works
The categorization system is modularly implemented in `CategorizationService` using a 3-tier hierarchy:
1. **User Custom Rules (`MerchantCategoryRule`)**:
   - First checks user-specific learned patterns. If a match is found (e.g. "whole foods" → *Groceries*), confidence is **95% (HIGH)**.
2. **Keyword & Pattern Classifier**:
   - Matches merchant names and descriptions against extensive keyword dictionaries spanning supermarkets, dining apps, gas stations, airlines, medical providers, SaaS, and utilities. Confidence is **75%–88% (HIGH/MEDIUM)**.
3. **Default Fallback**:
   - If no pattern matches, suggests *Other* with confidence **35% (LOW)** and prompts the user to select a category.

### Learning from Corrections
- When a user selects a category and checks *"Always remember this category for future transactions from this merchant"*, the system saves a rule in the `merchant_category_rules` table. Future imports or entries with that merchant will be automatically categorized.
- **Integrity Guarantee**: Manually selected categories are **never** silently rewritten.

### Limitations & ML Extensibility
- *Current Limitations*: Rule-based matching operates on substring and keyword tokens. Ambiguous merchant descriptions (e.g. "SQ *STORE 4829") without clear keywords fall back to *Other*.
- *Future ML Provider Compatibility*: The `CategorizationService` interface is decoupled from entity persistence. A cloud AI classifier (e.g. Vertex AI or OpenAI embeddings) can be plugged in by implementing a predictor interface without modifying the transaction schema.

---

## Insights & Anomaly Detection System

All insights in SpendWise are explainable and derived from transactions:
1. **Budget Consumption**: Compares period net spend against limits and triggers **Approaching** (≥80%) or **Exceeded** (>100%) warnings.
2. **Spending Drivers**: Identifies top categories and their proportion of overall spend.
3. **Period Shifts**: Flags categories with significant jumps (>30%) or decreases (<-25%) compared to the prior window of equal duration.
4. **Spending Velocity**: Computes daily burn rate and 30-day projected outlay.
5. **Recurring Subscriptions**: Groups expenses across 90 days to identify repeated charges on consistent intervals.
6. **Outlier Anomalies**: Identifies transactions that are > 2.5x the user's historical category average.
7. **Insufficient Data Fallback**: When fewer than 3 expenses exist, displays a helpful guide rather than blank charts.

---

## API Documentation (OpenAPI / Swagger)

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register new user account |
| `POST` | `/api/auth/login` | Authenticate and obtain JWT token |
| `POST` | `/api/auth/reset-password` | Reset user password |
| `POST` | `/api/demo/session` | Instant demo login session |
| `GET` | `/api/user/profile` | Retrieve profile and currency settings |
| `PUT` | `/api/user/profile` | Update profile settings |
| `DELETE` | `/api/user/data` | Permanent account data deletion |
| `GET` | `/api/transactions` | Paginated, filtered transaction search |
| `POST` | `/api/transactions` | Create transaction with auto-categorization |
| `GET` | `/api/transactions/{id}` | Get transaction details |
| `PUT` | `/api/transactions/{id}` | Update existing transaction |
| `DELETE` | `/api/transactions/{id}` | Delete transaction |
| `GET` | `/api/transactions/categorize-preview` | Live auto-categorization suggestion |
| `GET` | `/api/budgets` | Get monthly budget allocations & progress |
| `POST` | `/api/budgets` | Set overall or category monthly budget |
| `DELETE` | `/api/budgets/{id}` | Remove budget allocation |
| `GET` | `/api/dashboard` | KPI totals, trend lines, and insights |
| `GET` | `/api/reports/insights` | Deep-dive explainable insights |
| `POST` | `/api/reports/csv/preview` | Preview CSV file & column mapping |
| `POST` | `/api/reports/csv/import` | Execute CSV import |
| `GET` | `/api/reports/csv/export` | Download RFC-4180 CSV export |
| `GET` | `/api/categories` | List active categories |
| `POST` | `/api/categories` | Create custom category |
| `PUT` | `/api/categories/{id}` | Update category |
| `PATCH` | `/api/categories/{id}/archive` | Archive category |
| `DELETE` | `/api/categories/{id}` | Delete category with reassignment |

---

## Database Schema & Migrations

Database schema migrations are managed via **Flyway** (`db/migration/V1__init_schema.sql`):
- `users`: ID, email, password_hash, name, preferred_currency, time_zone, date_format, created_at, updated_at.
- `categories`: ID, owner_id (null for global starter categories), name, type, icon, color, is_archived, created_at.
- `accounts`: ID, owner_id, name, account_type, currency, balance, is_archived, created_at.
- `transactions`: ID, owner_id, category_id, account_id, type, amount (`DECIMAL(12,2)`), description, merchant, transaction_date, notes, categorization_source, created_at, updated_at.
- `budgets`: ID, owner_id, category_id (null for overall budget), amount (`DECIMAL(12,2)`), period, month, year, created_at, updated_at.
- `merchant_category_rules`: ID, owner_id, merchant_pattern, category_id, priority, created_at.

Performance indexes are created for `(owner_id, transaction_date)`, `(owner_id, category_id)`, `(owner_id, type)`, and `(owner_id, year, month)`.

---

## Security & Privacy Decisions

1. **Passwords**: Stored exclusively using BCrypt salted hashing; never stored or logged in plaintext.
2. **Stateless JWT Authorization**: Bearer tokens signed with HMAC-SHA256 with 24-hour expiration.
3. **Strict User Scoping**: Every database lookup, modification, and deletion query is filtered by the authenticated user's ID (`owner_id = user.id`), preventing Insecure Direct Object References (IDOR).
4. **SQL Injection Defense**: Uses JPA parameterized queries and criteria specifications for dynamic filtering.
5. **Fixed-Precision Monetary Calculations**: Amounts are strictly handled with `BigDecimal` with half-up rounding, preventing IEEE 754 floating-point inaccuracies.
6. **Data Deletion Rights**: Users have direct access to permanently delete their account and all associated transaction records via the Settings view.
