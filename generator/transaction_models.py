"""
Transaction data models
"""

from dataclasses import dataclass, asdict
from enum import Enum
from datetime import datetime
from typing import Dict, List
import random
import uuid


@dataclass
class Transaction:
    """
    Banking transaction data model.

    Represents a single transaction with all relevant fields for
    processing, searching, and analytics.

    Attributes:
        transactionId: Unique transaction identifier
        customerId: Customer identifier (cust_001 to cust_100)
        amount: Transaction amount in USD
        merchant: Merchant/vendor name
        category: Transaction category (dining, shopping, etc.)
        timestamp: Unix timestamp in milliseconds
        location: City and state where transaction occurred
        cardLast4: Last 4 digits of payment card
    """
    transactionId: str
    customerId: str
    amount: float
    merchant: str
    category: str
    timestamp: int
    location: str
    cardLast4: str

    def to_dict(self) -> Dict:
        return asdict(self)


class TransactionCategory(Enum):
    """
    Transaction categories
    Each category has associated merchants and typical amount ranges.
    """
    DINING = "dining"
    SHOPPING = "shopping"
    TRAVEL = "travel"
    BILLS = "bills"
    ENTERTAINMENT = "entertainment"
    GROCERIES = "groceries"
    HEALTHCARE = "healthcare"
    TRANSPORT = "transport"


# Realistic merchant names by category
MERCHANTS: Dict[TransactionCategory, List[str]] = {
    TransactionCategory.DINING: [
        "Starbucks", "Chipotle", "McDonald's", "Subway", "Pizza Hut",
        "Domino's", "Panera Bread", "Chick-fil-A", "Taco Bell", "Olive Garden",
        "Red Lobster", "The Cheesecake Factory", "Buffalo Wild Wings",
        "Five Guys", "Shake Shack", "In-N-Out Burger", "Wendy's"
    ],
    TransactionCategory.SHOPPING: [
        "Amazon", "Target", "Walmart", "Best Buy", "Home Depot",
        "Macy's", "Costco", "Apple Store", "Nike", "IKEA",
        "Nordstrom", "Lowe's", "Kohl's", "Gap", "Zara",
        "H&M", "Sephora", "Ulta Beauty", "REI", "Dick's Sporting Goods"
    ],
    TransactionCategory.TRAVEL: [
        "United Airlines", "Delta", "Marriott", "Hilton", "Airbnb",
        "Uber", "Lyft", "Hertz", "Southwest Airlines", "Expedia",
        "American Airlines", "JetBlue", "Hyatt", "Holiday Inn",
        "Enterprise Rent-A-Car", "Budget", "Hotels.com", "Booking.com"
    ],
    TransactionCategory.BILLS: [
        "AT&T", "Verizon", "Comcast", "Con Edison", "Netflix",
        "Spotify", "Hulu", "AWS", "Adobe", "Google Cloud",
        "T-Mobile", "Sprint", "PG&E", "Duke Energy", "Disney+",
        "HBO Max", "YouTube Premium", "Apple Music", "Dropbox"
    ],
    TransactionCategory.ENTERTAINMENT: [
        "AMC Theaters", "Spotify", "Xbox", "PlayStation", "Steam",
        "Nintendo", "Ticketmaster", "Live Nation", "Regal Cinemas",
        "Cinemark", "Dave & Buster's", "Top Golf", "Six Flags",
        "Universal Studios", "SeaWorld", "MLB.tv", "NFL GamePass"
    ],
    TransactionCategory.GROCERIES: [
        "Whole Foods", "Trader Joe's", "Safeway", "Kroger", "Publix",
        "Wegmans", "Stop & Shop", "Aldi", "ShopRite", "Food Lion",
        "Harris Teeter", "Giant Eagle", "Albertsons", "Sprouts",
        "Fresh Market", "H-E-B", "Winn-Dixie"
    ],
    TransactionCategory.HEALTHCARE: [
        "CVS Pharmacy", "Walgreens", "LabCorp", "Quest Diagnostics",
        "Kaiser Permanente", "Blue Cross", "UnitedHealthcare",
        "Rite Aid", "Duane Reade", "Minute Clinic", "Urgent Care",
        "Dental Associates", "Vision Center", "Physical Therapy"
    ],
    TransactionCategory.TRANSPORT: [
        "Shell", "BP", "Chevron", "Exxon", "Mobil",
        "Metro Transit", "NYC Subway", "MTA", "CalTrain",
        "BART", "Amtrak", "Greyhound", "Megabus", "Gas Station",
        "76", "Arco", "Sunoco", "Speedway", "Wawa"
    ]
}


# US cities and states for transaction locations
LOCATIONS: List[str] = [
    "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX",
    "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA",
    "Dallas, TX", "San Jose, CA", "Austin, TX", "Seattle, WA",
    "Denver, CO", "Boston, MA", "Portland, OR", "Atlanta, GA",
    "Miami, FL", "Las Vegas, NV", "Detroit, MI", "Nashville, TN",
    "Baltimore, MD", "Charlotte, NC", "San Francisco, CA", "Minneapolis, MN",
    "Washington, DC", "Tampa, FL", "Orlando, FL", "Cleveland, OH"
]


# Realistic amount ranges by category (min, max)
AMOUNT_RANGES: Dict[TransactionCategory, tuple] = {
    TransactionCategory.DINING: (5.00, 75.00),
    TransactionCategory.SHOPPING: (10.00, 500.00),
    TransactionCategory.TRAVEL: (50.00, 1200.00),
    TransactionCategory.BILLS: (15.00, 300.00),
    TransactionCategory.ENTERTAINMENT: (10.00, 150.00),
    TransactionCategory.GROCERIES: (20.00, 200.00),
    TransactionCategory.HEALTHCARE: (25.00, 500.00),
    TransactionCategory.TRANSPORT: (15.00, 100.00)
}


def generate_random_transaction(num_customers: int = 100) -> Transaction:
    """
    Creates a banking transaction to simulate a transaction service
    """
    # Select random category
    category = random.choice(list(TransactionCategory))

    # Select random merchant from category
    merchant = random.choice(MERCHANTS[category])

    # Generate amount within realistic range for category
    min_amount, max_amount = AMOUNT_RANGES[category]
    amount = round(random.uniform(min_amount, max_amount), 2)

    # Generate customer ID (simulate specified number of customers)
    customer_num = random.randint(1, num_customers)
    customer_id = f"cust_{customer_num:03d}"

    # Generate card last 4 digits
    card_last4 = f"{random.randint(1000, 9999)}"

    # Select random location
    location = random.choice(LOCATIONS)

    # Generate transaction ID with shorter UUID
    transaction_id = f"tx_{uuid.uuid4().hex[:12]}"

    # Use current timestamp in milliseconds
    timestamp = int(datetime.now().timestamp() * 1000)

    return Transaction(
        transactionId=transaction_id,
        customerId=customer_id,
        amount=amount,
        merchant=merchant,
        category=category.value,
        timestamp=timestamp,
        location=location,
        cardLast4=card_last4
    )