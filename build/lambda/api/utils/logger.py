# This function sets up Python's built-in logging system and
# integrates it with structlog so the logs are output in JSON.
# It is defined for apps like FastAPI or Uvicorn that use standard
# Python logging but with more structured, machine-readable output.

# Built-in logging library. Handles traditional log messages and
# allows configuration of the logs format and where they go.
# Not JSON by default, just text.
import logging

# Here, sys is used to send logs to sys.stdout.
import sys

# Makes logs easier for machines to parse (e.g., JSON).
# It works alongside the logging module, adding structured fields.
# Plays well with log aggregators.
import structlog


def configure_logging(level: str = "INFO") -> None:
    """
    Configure stdlib logging + structlog for JSON output.
    Works with uvicorn/fastapi loggers.
    :param level: Logging level to use.
    :return: None
    """

    # Creates a processor that adds a timestamp to each log entry.
    timestamper = structlog.processors.TimeStamper(fmt="iso")

    logging.basicConfig(
        format="%(message)s",  # print only log message.
        stream=sys.stdout,  # sends logs to standard output.
        level=getattr(
            logging, level.upper(), logging.INFO
        ),  # sets logging level based on the level arg.
    )

    # processors are functions that modify or add to log entries before they are output.
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,  # add context variables to each log (requestID).
            timestamper,  # adds the timestamp, defined on line 28.
            structlog.processors.add_log_level,  # Adds the log level (INFO) to output.
            structlog.processors.StackInfoRenderer(),  # Adds stacktrace info.
            structlog.processors.format_exc_info,  # formats exceptions.
            structlog.processors.JSONRenderer(),  # converts finally log entry to JSON.
        ],
        wrapper_class=structlog.make_filtering_bound_logger(  # output only logs at or above the chosen level.
            getattr(logging, level.upper(), logging.INFO)
        ),
        # Context is persistent metadata attached to a logger.
        context_class=dict,  # stores context as a dictionary.
        logger_factory=structlog.PrintLoggerFactory(),  # prints logs directly (stdout).
        cache_logger_on_first_use=True,  # caches logger after first use.
    )
