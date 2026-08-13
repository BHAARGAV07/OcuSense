<div align="center">

# 👁️ OcuSense

### Personalized Ocular Allergy Management & Trigger Insights

**Track → Understand → Predict → Act**

![Flutter](https://img.shields.io/badge/Flutter-3.44.x-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Hackathon%20Prototype-orange)
![License](https://img.shields.io/badge/License-Add%20Yours-lightgrey)

</div>

---

OcuSense helps patients with allergic conjunctivitis understand their possible environmental and behavioral triggers, monitor symptoms, get a personalized and **explainable** flare-risk score, and stay on top of preventive care routines — without claiming to diagnose or replace clinical care.

<br>

## 📋 Table of Contents

- [The Problem](#-the-problem)
- [The Solution](#-the-solution)
- [Product Boundaries](#️-product-boundaries-important)
- [Tech Stack](#-tech-stack)
- [Architecture](#️-architecture)
- [Core Features](#-core-features)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Security](#-security)
- [Roadmap](#-roadmap)

<br>

## 🩺 The Problem

Some allergic conjunctivitis patients progress to severe **Vernal Keratoconjunctivitis (VKC)**, while others don't. Clinical management today focuses on treating symptoms rather than identifying and quantifying the underlying environmental or behavioral triggers driving that progression. Poor compliance with cold compresses and difficulty preventing eye rubbing remain major, largely unaddressed challenges.

## 💡 The Solution

OcuSense combines:

| | |
|---|---|
| 👆 | One-tap symptom logging |
| 🍽️ | Manual food/habit tracking |
| 🌦️ | Location-based environmental data — pollen, dust, humidity, AQI, weather |
| 🧠 | A rule-based, personalized trigger engine |
| 📊 | Transparent, explainable risk scoring |
| 🔁 | Trial-and-error assistance for testing suspected triggers |
| ⏰ | Preventive care reminders — cold compress, eye drops, eye-rubbing awareness |

The prototype uses a **transparent rule-based and statistical approach** rather than a trained ML model — every result is explainable and traceable back to the factors that produced it.

<br>

## ⚠️ Product Boundaries (Important)

OcuSense is a **monitoring, pattern-analysis, and awareness system** — not a diagnostic tool.

> ❌ It does **not** diagnose VKC or any medical condition
> ❌ It does **not** claim a medically proven cause of an individual patient's disease
> ❌ It does **not** replace an ophthalmologist or any clinical professional
> ❌ It does **not** present prototype risk scores or thresholds as clinically validated
> ❌ It does **not** recommend prescription changes or advise stopping prescribed treatment

Every risk/trigger output is framed as a **potential association** or **relative risk indicator** — never as causation or diagnosis.

<br>

## 🧰 Tech Stack

<div align="center">

| Layer | Technology |
|:---|:---|
| 📱 Mobile frontend | Flutter (3.44.x, Dart 3.12.x) |
| ⚙️ Backend | Python · FastAPI · Pydantic · SQLAlchemy |
| 🗄️ Database | Supabase |
| 🧠 Intelligence layer | Rule-based trigger engine · weighted risk scoring · statistical association (no ML in the prototype) |
| 🌍 Environmental data | [Open-Meteo](https://open-meteo.com/) — weather, humidity, dust, AQI (free, no key) + [Google Pollen API](https://developers.google.com/maps/documentation/pollen) — pollen (free tier, billing enabled) |
| 📍 Location | Device-native GPS via Flutter's `geolocator` package (no API key, no billing) |

</div>

<br>

## 🏗️ Architecture

```
                    ┌──────────────────────┐
                    │    Flutter Mobile    │
                    │        App           │
                    └──────────┬───────────┘
                               │ HTTPS / REST (JWT bearer)
                               ▼
                    ┌──────────────────────┐
                    │      FastAPI         │
                    │     REST API         │
                    └──────────┬───────────┘
          ┌────────────────────┼─────────────────────┐
          ▼                    ▼                     ▼
 ┌────────────────┐   ┌────────────────┐   ┌──────────────────┐
 │  PostgreSQL    │   │ Environmental  │   │ Intelligence     │
 │  Database      │   │ Data Services  │   │ Layer            │
 │                │   │ (server-side   │   │ Rules + Scoring  │
 │ Patient data   │   │  API keys)     │   │ + Correlation    │
 └────────────────┘   └────────────────┘   └────────┬─────────┘
                                                     │
                                                     ▼
                                           ┌──────────────────┐
                                           │ Recommendations  │
                                           │ & Risk Result    │
                                           └────────┬─────────┘
                                                     ▼
                                            Flutter Dashboard
```

> 🔒 **Key design rule:** All external API keys (Google Pollen, etc.) live server-side in FastAPI environment variables. The Flutter client never holds a third-party API key — it talks only to the device's own location service and to this project's own FastAPI backend.

Full architecture, database schema, and API specification live in [`/docs`](./docs).

<br>

## ✨ Core Features

- **Patient Profile** — minimal, non-sensitive profile info for personalization
- **Symptom Logging** — itching, redness, watering, irritation, with severity
- **Habit/Food Tracking** — manual entries the patient can log
- **Environmental Data** — auto-fetched pollen, dust, humidity, AQI, weather for the patient's location
- **Trigger Analysis** — compares symptom history against environmental/behavioral history to surface potential associations, with observation counts and confidence levels shown
- **Personalized Risk Score** — transparent, weighted score (Low / Moderate / High / Very High) with a full breakdown of contributing factors
- **Trial-and-Error Assist** — helps a patient observe whether reducing a suspected exposure changes their symptoms over time
- **Reminders** — cold-compress routine, eye-drop administration, eye-rubbing awareness

<details>
<summary><b>🔧 Hardware roadmap (not required to run this prototype)</b></summary>
<br>

- Cold-compress gel-pad eye mask with digital temperature meter
- Smartwatch-based eye-rubbing motion detection

The database schema and API (`eye_rubbing_events.source`, cold-compress endpoints) already support a `manual` vs. `smartwatch`/`device` source field on the same contract, so hardware can be added later without an API redesign.

</details>

<br>

## 🚀 Getting Started

### Prerequisites
- Flutter 3.44.x / Dart 3.12.x
- Python 3.11+
- PostgreSQL 14+
- Open-Meteo (no key required)
- A Google Cloud project with the Pollen API enabled and billing configured — free tier: **35,000 requests/month** (India pricing). ⚠️ Set a hard daily quota in the Cloud Console before testing.

### Backend setup
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # add DATABASE_URL, JWT_SECRET, GOOGLE_POLLEN_API_KEY
alembic upgrade head    # or your migration tool of choice
uvicorn app.main:app --reload
```

### Frontend setup
```bash
cd mobile
flutter pub get
flutter run
```

Build a release APK:
```bash
flutter build apk --release
```

<br>

## 📁 Project Structure

```
backend/
├── app/
│   ├── main.py
│   ├── api/            # auth, patients, symptoms, habits, environment, analysis
│   ├── models/
│   ├── schemas/
│   ├── services/        # trigger_engine.py, risk_engine.py, correlation_engine.py, recommendation_engine.py
│   └── database/
└── requirements.txt

mobile/
└── lib/
    ├── screens/
    ├── services/         # API client
    └── widgets/

docs/
├── PRD.md
├── technical-requirements.md
├── system-architecture.md
├── database-schema.md
├── api-specification.md
├── ai-decision-engine.md
└── app-flow.md
```

<br>

## 🔐 Security

- ✅ HTTPS enforced in production
- ✅ Passwords hashed, never logged
- ✅ JWT bearer auth — patient ID always derived from the token, never trusted from the request body/query
- ✅ Input validation via Pydantic at the schema layer
- ✅ No third-party API keys ever shipped in the mobile client
- ✅ Secrets managed via environment variables, never committed
- ✅ No internal exceptions or stack traces returned to the client

<br>

## 🗺️ Roadmap

- [ ] ML-based prediction once sufficient validated patient data is available (intelligence layer is built behind a swappable interface for this)
- [ ] Smart cold-compress and smartwatch hardware integration
- [ ] Clinician-facing summaries, subject to clinical validation and privacy review
- [ ] Larger-scale clinical validation of thresholds currently used only as prototype defaults

<br>

## 📄 License

_Add your chosen license here (e.g., MIT)._

## 👤 Team

<div align="center">

Built with 💙 by **[Bhaargav](https://github.com/BHAARGAV07)** — RMK Engineering College

</div>
