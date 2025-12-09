#!/usr/bin/env python3
"""
Integration Test

Verifies workshop setup is correct.
"""

import sys
from pathlib import Path

# Colors
GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'


def test_files() -> bool:
    """Check required files exist."""
    required = [
        "docker-compose.yml",
        "requirements.txt",
        "lib/redis_client.py",
        "lib/logger.py",
        "generator/generator.py",
        "generator/transaction_models.py",
        "processor/consumer.py",
        "processor/modules/ordered_transactions.py",
        "processor/modules/store_transaction.py",
        "processor/modules/spending_categories.py",
        "processor/modules/spending_over_time.py",
        "processor/solutions/ordered_transactions.py",
        "processor/solutions/store_transaction.py",
        "processor/solutions/spending_categories.py",
        "processor/solutions/spending_over_time.py",
    ]

    missing = [f for f in required if not Path(f).exists()]

    if missing:
        print(f"{RED}✗ Missing files:{RESET}")
        for f in missing:
            print(f"  - {f}")
        return False

    print(f"{GREEN}✓ All required files present{RESET}")
    return True


def test_imports() -> bool:
    """Check modules can be imported."""
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from lib.redis_client import get_redis
        from lib.logger import setup_logger
        from generator.transaction_models import generate_random_transaction
        print(f"{GREEN}✓ All imports work{RESET}")
        return True
    except ImportError as e:
        print(f"{RED}✗ Import failed: {e}{RESET}")
        return False


def test_redis() -> bool:
    """Check Redis connection."""
    try:
        from lib.redis_client import get_redis
        redis = get_redis()

        if not redis.ping():
            print(f"{RED}✗ Redis ping failed{RESET}")
            return False

        modules = redis.module_list()
        module_names = [m['name'].decode() if isinstance(m['name'], bytes) else m['name'] for m in modules]

        required = ['ReJSON', 'search', 'timeseries']
        for mod in required:
            if mod not in module_names:
                print(f"{RED}✗ Redis module '{mod}' not loaded{RESET}")
                return False

        print(f"{GREEN}✓ Redis Stack connected{RESET}")
        return True

    except Exception as e:
        print(f"{RED}✗ Redis connection failed: {e}{RESET}")
        print(f"  Run: docker compose up -d")
        return False


def main() -> int:
    """Run all tests."""
    print("\n" + "=" * 50)
    print("Workshop Integration Test")
    print("=" * 50 + "\n")

    results = {
        "Files": test_files(),
        "Imports": test_imports(),
        "Redis": test_redis(),
    }

    print("\n" + "=" * 50)
    passed = sum(results.values())
    total = len(results)

    if passed == total:
        print(f"{GREEN}✓ ALL TESTS PASSED ({passed}/{total}){RESET}")
        print("\nReady to start:")
        print("  docker compose up -d")
        return 0
    else:
        print(f"{RED}✗ TESTS FAILED ({passed}/{total}){RESET}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
