"""
Module 5: Vector Search - Semantic Transaction Search

Enable semantic search on transactions using RedisVL.
This allows natural language queries like "coffee shop transactions" or "transactions in Dallas".

RedisVL provides:
- SearchIndex: Create and manage vector indexes
- HFTextVectorizer: Generate embeddings from text
- VectorQuery: Search for similar vectors
"""

from typing import Dict, List

from redisvl.index import SearchIndex
from redisvl.query import VectorQuery
from redisvl.utils.vectorize import HFTextVectorizer

# Generates 384-dimensional embeddings from text
vectorizer = HFTextVectorizer(model="sentence-transformers/all-MiniLM-L6-v2")

index = None

schema = {
    "index": {
        "name": "idx:transactions:vector",
        "prefix": "transaction:",
        "storage_type": "json"
    },
    "fields": [
        {
            "name": "embedding",
            "type": "vector",
            "attrs": {
                # TODO: Configure vector field attributes. Replace the 4 lines below:
                # dims: 384 (must match vectorizer output)
                # distance_metric: "cosine"
                # algorithm: "flat"
                # datatype: "float32"
            }
        }
    ]
}


def create_index(redis_client) -> bool:
    """Create the vector search index. Called once at startup."""
    global index
    index = SearchIndex.from_dict(schema, redis_client=redis_client)
    try:
        index.create(overwrite=False)
        return True
    except:
        return False


def embed_query(query: str) -> List:
    """Convert search query text into an embedding vector."""
    if "transaction" not in query.lower():
        query = f"transactions {query}"
    return vectorizer.embed(query)


def process_transaction(redis_client, tx_data: Dict[str, str]) -> None:
    """Generate embedding for transaction and store it."""
    tx_id = tx_data.get('transactionId')
    merchant = tx_data.get('merchant', '')
    category = tx_data.get('category', '')
    location = tx_data.get('location', '')
    text = f"Transaction at {merchant} which is in the {category} spending category. Transaction in city {location}"

    embedding = vectorizer.embed(text)

    # TODO: Replace the line below with:
    # Store embedding in the JSON document at path "embedding"
    # Key: f"transaction:{tx_id}"
    pass


def search_by_vector(redis_client, query_vector: List, limit: int = 10) -> List[Dict]:
    """Search transactions by vector similarity."""
    global index
    if index is None:
        index = SearchIndex.from_dict(schema, redis_client=redis_client)

    # TODO: Replace the line below with:
    # Create a VectorQuery and execute it
    # VectorQuery params: vector, vector_field_name, num_results, return_fields
    # We want to return all fields
    # Use results = index.query(vec_query) to execute
    results = []

    # Format results
    transactions = []
    for doc in results:
        distance = float(doc.get('vector_distance', 1))
        if (1 - distance) < 0.50:  # Skip low similarity
            continue
        transactions.append({
            "transactionId": doc.get('$.transactionId'),
            "merchant": doc.get('$.merchant'),
            "category": doc.get('$.category'),
            "location": doc.get('$.location'),
            "amount": doc.get('$.amount'),
            "timestamp": doc.get('$.timestamp'),
            "score": distance,
        })
    return transactions
