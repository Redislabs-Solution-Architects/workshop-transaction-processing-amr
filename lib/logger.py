"""
Logging utility for the transaction workshop.

Provides colorized console logging with configurable log levels.
"""

import logging
import os
import sys
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# ANSI color codes
COLORS = {
    "DEBUG": "\033[36m",      # Cyan
    "INFO": "\033[32m",       # Green
    "WARNING": "\033[33m",    # Yellow
    "ERROR": "\033[31m",      # Red
    "CRITICAL": "\033[35m",   # Magenta
    "RESET": "\033[0m",       # Reset
}


class ColoredFormatter(logging.Formatter):
    """
    Custom formatter that adds colors to log levels.
    """

    def format(self, record: logging.LogRecord) -> str:
        """
        Format the log record with colors.

        Args:
            record: The log record to format

        Returns:
            str: Formatted and colorized log message
        """
        # Save original levelname
        levelname = record.levelname

        # Add color to levelname
        if levelname in COLORS:
            record.levelname = (
                f"{COLORS[levelname]}{levelname}{COLORS['RESET']}"
            )

        # Format the message
        formatted = super().format(record)

        # Restore original levelname
        record.levelname = levelname

        return formatted


def setup_logger(name: str, level: Optional[str] = None) -> logging.Logger:
    """
    Set up a logger with colorized console output.

    Creates a logger with the specified name and configures it with
    a colorized formatter. The log level can be specified or will be
    read from the LOG_LEVEL environment variable.

    Args:
        name: The name of the logger (typically __name__)
        level: Optional log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
               If not specified, reads from LOG_LEVEL env var (default: INFO)

    Returns:
        logging.Logger: Configured logger instance

    Example:
        >>> logger = setup_logger(__name__)
        >>> logger.info("Application started")
        >>> logger.error("An error occurred")
    """
    # Get log level from parameter or environment
    if level is None:
        level = os.getenv("LOG_LEVEL", "INFO").upper()

    # Validate log level
    numeric_level = getattr(logging, level, None)
    if not isinstance(numeric_level, int):
        print(
            f"Warning: Invalid log level '{level}', using INFO",
            file=sys.stderr,
        )
        numeric_level = logging.INFO

    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(numeric_level)

    # Remove existing handlers to avoid duplicates
    logger.handlers.clear()

    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(numeric_level)

    # Create formatter
    formatter = ColoredFormatter(
        fmt="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    console_handler.setFormatter(formatter)

    # Add handler to logger
    logger.addHandler(console_handler)

    # Prevent propagation to root logger
    logger.propagate = False

    return logger


def get_log_level() -> str:
    """
    Get the current log level from environment.

    Returns:
        str: The configured log level (default: INFO)
    """
    return os.getenv("LOG_LEVEL", "INFO").upper()


def set_log_level(logger: logging.Logger, level: str) -> None:
    """
    Change the log level of an existing logger.

    Args:
        logger: The logger to modify
        level: New log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    """
    numeric_level = getattr(logging, level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f"Invalid log level: {level}")

    logger.setLevel(numeric_level)
    for handler in logger.handlers:
        handler.setLevel(numeric_level)
