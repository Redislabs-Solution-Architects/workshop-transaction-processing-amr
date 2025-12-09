"""
Banking Workshop API

Serves data from Redis modules to UI.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from api.routers import transactions, categories, timeseries, status, stream, search

app = FastAPI(title="Banking Workshop API", default_response_class=ORJSONResponse)

# CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(status.router)
app.include_router(transactions.router)
app.include_router(categories.router)
app.include_router(timeseries.router)
app.include_router(stream.router)
app.include_router(search.router)


@app.get("/health")
def health():
    """Health check."""
    return {"status": "healthy"}
