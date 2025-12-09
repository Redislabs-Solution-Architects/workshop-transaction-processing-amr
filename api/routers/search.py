"""
Search Router

Endpoints for semantic transaction search (Vector Search module).
"""

import time
from fastapi import APIRouter, Depends, HTTPException
from api.dependencies import get_redis_client
from processor.modules import vector_search

router = APIRouter(prefix="/api/search", tags=["search"])


@router.post("/index")
def create_search_index(redis=Depends(get_redis_client)):
    """
    Create the vector search index.
    Call this once before searching.
    """
    try:
        created = vector_search.create_index(redis)
        if created:
            return {"status": "created", "index": vector_search.INDEX_NAME}
        return {"status": "exists", "index": vector_search.INDEX_NAME}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("")
def search_transactions(q: str, limit: int = 10, redis=Depends(get_redis_client)):
    """
    Search transactions using semantic similarity.

    Query examples:
    - "coffee shops"
    - "online shopping"
    - "restaurants in Orlando"
    - "travel expenses"
    """
    if not q or len(q.strip()) < 2:
        raise HTTPException(status_code=400, detail="Query must be at least 2 characters")

    try:
        # Time embedding generation (Python/ML)
        t0 = time.perf_counter()
        query_vector = vector_search.embed_query(q.strip())
        embed_ms = round((time.perf_counter() - t0) * 1000, 2)

        # Time vector search (Redis FT.SEARCH)
        t0 = time.perf_counter()
        results = vector_search.search_by_vector(redis, query_vector, limit)
        search_ms = round((time.perf_counter() - t0) * 1000, 2)

        return {
            "query": q,
            "results": results,
            "count": len(results),
            "embed_ms": embed_ms,
            "search_ms": search_ms,
        }
    except Exception as e:
        # Index might not exist yet
        if "no such index" in str(e).lower():
            return {
                "query": q,
                "results": [],
                "count": 0,
                "error": "Search index not ready. Complete the Vector Search module first."
            }
        raise HTTPException(status_code=500, detail=str(e))
