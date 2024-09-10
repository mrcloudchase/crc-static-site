import logging
import azure.functions as func
from azure.cosmos import CosmosClient, exceptions

# Cosmos DB settings
COSMOS_DB_URI = "https://<your-cosmos-db-account>.documents.azure.com:443/"
COSMOS_DB_KEY = "<your-cosmos-db-key>"
DATABASE_NAME = "PageViewsDB"
CONTAINER_NAME = "Counters"

client = CosmosClient(COSMOS_DB_URI, COSMOS_DB_KEY)
database = client.create_database_if_not_exists(DATABASE_NAME)
container = database.create_container_if_not_exists(
    id=CONTAINER_NAME,
    partition_key=func.PartitionKey(path="/id"),
    offer_throughput=400
)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Try to fetch the current counter document
        counter = container.read_item(item="pageview-counter", partition_key="pageview-counter")
        count = counter.get("count", 0) + 1
    except exceptions.CosmosResourceNotFoundError:
        # If it doesn't exist, initialize it
        count = 1
        container.create_item({"id": "pageview-counter", "count": count})

    # Update the counter in the database
    container.upsert_item({"id": "pageview-counter", "count": count})

    return func.HttpResponse(f"Page view count: {count}", status_code=200)
