# pv-predict-lorawan

Communications-aware predictive protection for PV panels: Direct–Recursive XGBoost forecasting (10-min cadence) + LoRaWAN uplinks/downlinks for panel-level early fault detection and isolation.

---

## Overview
This repository contains the code, notebooks and model artifacts used in the project **LoRa-based Early Fault Detection and Panel Isolation in PV Systems Using Machine Learning** (IEEE ComSoc Student Competition 2025).

Dataset - [PVDAQ time series with soil signal](https://datahub.duramat.org/dataset/pvdaq-time-series-with-soiling-signal/resource/d2c3fcf4-4f5f-47ad-8743-fc29f1356835)

Key ideas:
- Aggregate high-rate sensor readings into 10-minute summaries.
- Train a Direct–Recursive (DirRec) chain of XGBoost models to forecast 4 hours ahead (24 horizons).
- Send compact binary payloads via LoRaWAN from panel nodes to a central server.
- Central server raises probabilistic alarms and queues authenticated LoRaWAN downlinks to isolate panels; nodes also implement local deterministic trip logic for safety.
