"""Main Prefect pipeline flow orchestrating the docs refresh."""
from prefect import flow, get_run_logger

from flows.fetch import fetch_all_extensions, fetch_verified_publishers, fetch_unverified_publishers
from flows.validate import validate_publishers
from flows.render import generate_ms_extensions_markdown, generate_verified_publishers_markdown, generate_unverified_publishers_markdown
from flows.link_check import check_links
from flows.publish import publish_docs


@flow(
    name="marketplace-docs-pipeline",
    description="Fetch VS Code Marketplace data, generate docs, check links, and publish.",
    retries=0,
    log_prints=True,
)
def docs_pipeline() -> dict:
    """
    Full pipeline:
    1. Fetch extension data from Marketplace
    2. Validate publishers
    3. Generate markdown docs
    4. Check links
    5. Publish if changed
    """
    logger = get_run_logger()

    # Step 1: Fetch data
    logger.info("=== Step 1: Fetching data ===")
    fetch_all_extensions()
    fetch_verified_publishers()
    fetch_unverified_publishers()

    # Step 2: Validate
    logger.info("=== Step 2: Validating publishers ===")
    validate_publishers()

    # Step 3: Render markdown
    logger.info("=== Step 3: Generating markdown ===")
    generate_ms_extensions_markdown()
    generate_verified_publishers_markdown()
    generate_unverified_publishers_markdown()

    # Step 4: Link check
    logger.info("=== Step 4: Checking links ===")
    check_links()

    # Step 5: Publish
    logger.info("=== Step 5: Publishing ===")
    result = publish_docs()

    logger.info(f"Pipeline complete. Changed: {result.get('changed', False)}")
    return result


if __name__ == "__main__":
    docs_pipeline()
