import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Set
from prefect import task, get_run_logger, flow

def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]

def load_json(path: Path) -> Any:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_extension_map(extensions: List[Dict]) -> Dict[str, Dict]:
    """Create a map of 'publisher.name' -> extension object."""
    mapping = {}
    for ext in extensions:
        # Construct unique ID. Use publisherName.extensionName
        # Handle case where publisher might be an object or string (though usually object in this data)
        pub_name = ext.get('publisher', {}).get('publisherName')
        ext_name = ext.get('extensionName')
        
        if pub_name and ext_name:
            full_name = f"{pub_name}.{ext_name}".lower()
            mapping[full_name] = ext
    return mapping

@task(name="generate-diff", description="Generate diff between latest and previous extension snapshots")
def generate_diff() -> None:
    logger = get_run_logger()
    repo_root = _repo_root()
    history_dir = repo_root / "data" / "history"
    
    if not history_dir.exists():
        logger.warning(f"History directory not found: {history_dir}")
        return

    # Find all extension snapshots
    snapshots = sorted(history_dir.glob("all_extensions_*.json"), key=lambda p: p.name, reverse=True)
    
    if len(snapshots) < 2:
        logger.info("Not enough snapshots to generate diff (need at least 2).")
        # Create empty report to prevent errors in downstream tasks
        report = {
            "generatedAt": datetime.now().isoformat(),
            "status": "insufficient_history",
            "stats": {"added": 0, "removed": 0, "updated": 0},
            "added": [],
            "removed": [],
            "updated": []
        }
    else:
        new_file = snapshots[0]
        old_file = snapshots[1]
        
        logger.info(f"Comparing {new_file.name} vs {old_file.name}")
        
        new_data = load_json(new_file)
        old_data = load_json(old_file)
        
        new_exts = new_data.get('extensions', [])
        old_exts = old_data.get('extensions', [])
        
        new_map = get_extension_map(new_exts)
        old_map = get_extension_map(old_exts)
        
        new_keys = set(new_map.keys())
        old_keys = set(old_map.keys())
        
        added_keys = new_keys - old_keys
        removed_keys = old_keys - new_keys
        common_keys = new_keys & old_keys
        
        added = [new_map[k] for k in added_keys]
        removed = [old_map[k] for k in removed_keys]
        updated = []
        
        for k in common_keys:
            new_obj = new_map[k]
            old_obj = old_map[k]
            
            # Compare versions
            # Assuming versions is a list and [0] is latest
            new_ver = new_obj.get('versions', [{}])[0].get('version', '0.0.0')
            old_ver = old_obj.get('versions', [{}])[0].get('version', '0.0.0')
            
            if new_ver != old_ver:
                updated.append({
                    "id": k,
                    "extension": new_obj,
                    "previousVersion": old_ver,
                    "newVersion": new_ver
                })
        
        logger.info(f"Diff results: +{len(added)} -{len(removed)} ~{len(updated)}")
        
        report = {
            "generatedAt": datetime.now().isoformat(),
            "compared": {
                "new": new_file.name,
                "old": old_file.name
            },
            "stats": {
                "added": len(added),
                "removed": len(removed),
                "updated": len(updated)
            },
            "added": added,
            "removed": removed,
            "updated": updated
        }

    # Save report
    output_path = repo_root / "data" / "diff_report.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    logger.info(f"Diff report saved to {output_path}")

if __name__ == "__main__":
    # Allow standalone execution
    from prefect import flow
    
    @flow
    def test_flow():
        generate_diff()
        
    test_flow()
