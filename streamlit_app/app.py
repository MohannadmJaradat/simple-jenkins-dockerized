import streamlit as st
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

st.title("Hello from Jenkins CI/CD")
# ---------- Sidebar ----------
st.sidebar.title("🔧 Dashboard Controls")
start_date = st.sidebar.date_input("Start Date", datetime.now() - timedelta(days=30))
end_date = st.sidebar.date_input("End Date", datetime.now())
category = st.sidebar.selectbox("Category", ["All", "Tech", "Health", "Finance"])

st.sidebar.markdown("---")
st.sidebar.info("Built by **Mohannad Jaradat** 👨‍💻")

# ---------- Page Title ----------
st.title("📊 Interactive Streamlit Dashboard")

# ---------- Dummy Data ----------
np.random.seed(42)
dates = pd.date_range(start_date, end_date, freq='D')
data = pd.DataFrame({
    'Date': dates,
    'Sales': np.random.randint(100, 1000, size=len(dates)),
    'Users': np.random.randint(10, 100, size=len(dates)),
    'Category': np.random.choice(['Tech', 'Health', 'Finance'], size=len(dates))
})

if category != "All":
    data = data[data["Category"] == category]

# ---------- KPI Section ----------
total_sales = data['Sales'].sum()
avg_users = data['Users'].mean()

col1, col2 = st.columns(2)
col1.metric("🛒 Total Sales", f"${total_sales:,}")
col2.metric("👥 Avg. Daily Users", f"{avg_users:.1f}")

# ---------- Tabs ----------
tab1, tab2 = st.tabs(["📈 Sales Trend", "📂 Raw Data"])

with tab1:
    st.subheader("📉 Sales over Time")
    chart_data = data.groupby("Date")["Sales"].sum()
    st.line_chart(chart_data)

with tab2:
    st.subheader("🧾 Raw Data")
    st.dataframe(data.reset_index(drop=True), use_container_width=True)

# ---------- Footer ----------
st.markdown("""
---
📌 _This is a demo dashboard. Data is randomly generated on every load._
""")
