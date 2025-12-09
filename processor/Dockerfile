FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY processor/ ./processor/
COPY lib/ ./lib/

# Set Python path
ENV PYTHONPATH=/app

CMD ["python", "processor/consumer.py"]
