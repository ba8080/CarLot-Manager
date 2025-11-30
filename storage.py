import json
import os
import warnings
from pathlib import Path
from typing import List, Dict, Any


def _data_file() -> Path:
    # Prefer project root if writable, otherwise fall back to a per-user data directory.
    root = Path(__file__).resolve().parent
    project_path = root / "inventory.json"

    # Check for NFS mount path first
    nfs_path = Path("/app/data/inventory.json")
    try:
        if nfs_path.parent.exists():
            return nfs_path
    except Exception:
        pass

    # Try project root first: create a temp file to test writability
    try:
        if project_path.exists():
            return project_path
        # attempt to create and remove a temporary file to test writability
        test_path = root / ".inventory_write_test"
        with test_path.open("w", encoding="utf-8") as fh:
            fh.write("")
        test_path.unlink()
        return project_path
    except Exception:
        # Fall back to user-level data directory
        if os.name == "nt":
            base = Path(os.getenv("LOCALAPPDATA", Path.home() / "AppData" / "Local"))
        else:
            base = Path(os.getenv("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        appdir = base / "CarLot-Manager"
        try:
            appdir.mkdir(parents=True, exist_ok=True)
        except Exception:
            # As a last resort, use home directory
            appdir = Path.home() / ".car_lot_manager"
            appdir.mkdir(parents=True, exist_ok=True)
        warnings.warn(f"Using user data directory for inventory: {appdir}")
        return appdir / "inventory.json"


def _initial_dummy_data() -> List[Dict[str, Any]]:
    return [
        {"id": 1, "brand": "Toyota", "model": "Corolla", "year": 2018, "buy_price": 12000.0, "sell_price": None, "is_sold": False},
        {"id": 2, "brand": "Honda", "model": "Civic", "year": 2019, "buy_price": 14000.0, "sell_price": 15000.0, "is_sold": True},
        {"id": 3, "brand": "Ford", "model": "Focus", "year": 2017, "buy_price": 9000.0, "sell_price": None, "is_sold": False}
    ]


def load_inventory() -> List[Dict[str, Any]]:
    f = _data_file()
    if not f.exists():
        data = _initial_dummy_data()
        try:
            save_inventory(data)
        except Exception:
            # If we cannot write the file (permission, read-only FS), return the data anyway
            pass
        return data
    try:
        with f.open("r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        # If file is corrupted, overwrite with initial data
        data = _initial_dummy_data()
        try:
            save_inventory(data)
        except Exception:
            pass
        return data


def save_inventory(inventory: List[Dict[str, Any]]):
    f = _data_file()
    # ensure parent directory exists
    try:
        f.parent.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass
    with f.open("w", encoding="utf-8") as fh:
        json.dump(inventory, fh, indent=2)
