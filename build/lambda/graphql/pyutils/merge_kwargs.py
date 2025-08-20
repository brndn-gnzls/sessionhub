from typing import Any, TypeVar, cast

T = TypeVar("T")


def merge_kwargs(base_dict: T, **kwargs: Any) -> T:
    """Return arbitrary typed dictionary with some keyword args merged in."""
    return cast(T, {**cast(dict, base_dict), **kwargs})
