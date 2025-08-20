from collections.abc import Collection


def print_path_list(path: Collection[str | int]) -> str:
    """Build a string describing the path."""
    return "".join(f"[{key}]" if isinstance(key, int) else f".{key}" for key in path)
